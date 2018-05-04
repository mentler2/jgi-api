#!bin/bash

read -p "JGI Username: " username
read -s -p "JGI Password: " password

mkdir temp_files
echo ''
echo ''
curl -s 'https://signon-old.jgi.doe.gov/signon/create' --data-urlencode "login=$username" --data-urlencode "password=$password" -c temp_files/cookies 
lines_cookies=($(wc -l temp_files/cookies))
if [ "${lines_cookies[0]}" -eq "6" ]; then
	echo ''
	echo "Successful login."
	echo ''
else
	echo "Unsuccessful login. Terminating script."
	exit 1
fi
read -p "Node name (e.g., 'fungi,' or 'pucciniomycotina'): " node_name
curl --cookie temp_files/cookies --output temp_files/files.xml "https://genome.jgi.doe.gov/portal/ext-api/downloads/get-directory?organism=$node_name&organizedByFileType=false"
lines_file_heirarchy=($(wc -l temp_files/files.xml)) #output goes into an array
echo ''
if [ "${lines_file_heirarchy[0]}" -gt 2 ]; then #if more lines exist than the number required for default error statements
	echo 'File heirarchy downloaded to temp_files/files.xml.'
else
	echo 'Problem obtaining file heirarchy. Please ensure you are attempting to interrogate a valid node. This can be done by checking the JGI genome database for the presence of a download option. If you are working within a restricted network your shell settings may need to be adjusted to permit downloads.'
	echo ''
	rm -r temp_files
	echo 'Script terminated.'
	exit 1
fi
echo ''

echo 'Enter search string to interrogate file heirarchy. For example, "AssemblyScaffolds_Repeatmasked". If necessary you can peruse the downloaded file heirarchy to see available file types.'
echo ''
read -p "Search string: " search_string
grep -E "$search_string" "temp_files/files.xml" | grep -Eo 'md5=".+"' > temp_files/unformatted_md5s.txt

while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "$line" | sed -e 's/md5="//' | sed -e 's/"//' >> temp_files/md5s.txt
done < "temp_files/unformatted_md5s.txt"
size_md5s=($(ls -s temp_files/md5s.txt))
if [ "${size_md5s[0]}" -gt "0" ]; then
	echo 'md5sum hashes prepared.'
else
	echo 'Problem obtaining md5s.'
	rm -r temp_files
	rm cookies
	echo 'Script terminated.'
fi

#grab urls based on unique md5sums
sort temp_files/md5s.txt | uniq > temp_files/unique_md5s.txt

while IFS='' read -r line || [[ -n "$line" ]]; do 
	grep -m 1 "$line" "temp_files/files.xml" >> temp_files/unique_lines.txt
done < "temp_files/unique_md5s.txt"

grep -Eo "url=\".*$search_string[^\"]*\"" temp_files/unique_lines.txt | sed -e 's/url="//' | sed -e 's/^"//' -e 's/"$//' > temp_files/urls.txt
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "https://genome.jgi.doe.gov$line" | sed -e 's/amp;//' >> temp_files/formatted_urls.txt
done < "temp_files/urls.txt"
size_urls=($(ls -s temp_files/formatted_urls.txt))
if [ "${size_urls[0]}" -gt "0" ]; then
	echo 'File urls grabbed and formatted.'
else
	echo 'Problem obtaining file urls.'
	rm -r temp_files
	rm cookies
	echo 'Script terminated.'
fi
python make_files.py temp_files/formatted_urls.txt temp_files/unique_lines.txt temp_files/curls.sh temp_files/unique_md5s.txt temp_files/md5s_and_filenames.txt "$search_string"
echo 'Commmand files written.'
num_downloads=$(wc -l < "temp_files/curls.sh")
echo "$num_downloads files awaiting download."
echo ''
echo 'Beginning curls execution.'
bash temp_files/curls.sh
echo "Curl executions complete."

#check md5
md5sum *$search_string* > temp_files/local_md5s.txt
sort temp_files/md5s_and_filenames.txt > temp_files/md5s_from_database_sorted.txt
sort temp_files/local_md5s.txt > temp_files/local_md5s_sorted.txt
echo ''
echo "Calculating md5sums..."
diff -y temp_files/md5s_from_database_sorted.txt temp_files/local_md5s_sorted.txt
echo ''
echo "Script complete."
