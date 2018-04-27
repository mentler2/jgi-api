#!bin/bash

username=$(read -p "JGI Username: ")
password=$(read -s -p "JGI Password: ")

echo ''
echo ''
curl 'https://signon-old.jgi.doe.gov/signon/create' --data-urlencode "login=$username" --data-urlencode "password=$password" -c cookies 
echo ''
echo ''
node_name=$(read -p "Node name (e.g., 'fungi,' or 'pucciniomycotina'): ")
mkdir temp_files
curl --cookie cookies --output temp_files/files.xml "https://genome.jgi.doe.gov/portal/ext-api/downloads/get-directory?organism=$node_name&organizedByFileType=false"
size_file_heirarchy=$(ls -s temp_files/files.xml)
size_file_heirarchy=${size_file_heirarchy:0:1}
echo ''
if [ "$size_file_heirarchy" -gt "50" ]; then #if file file is larger than the size required for the default error statement
	echo 'File heirarchy downloaded as files.xml.'
else
	echo 'Problem obtaining file heirarchy. Please ensure you are attempting to interrogate a valid node. This can be done by checking the JGI genome database for the presence of a download option. If you are working within a restricted network your shell settings may need to be adjusted to permit downloads.'
fi
echo ''

printf 'Enter search string to interrogate file heirarchy. Suffices are useful for grabbing particular types of files. For example, "AssemblyScaffolds_Repeatmasked.fasta.gz"'
echo ''
search_string=$(read -p "search string: ")
grep -E "$search_string" "temp_files/files.xml" | grep -Eo 'md5=".+"' > temp_files/unformatted_md5s.txt

while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "$line" | sed -e 's/md5="//' | sed -e 's/"//' >> temp_files/md5s.txt
done < "temp_files/unformatted_md5s.txt"
size_md5s=$(ls -s temp_files/md5s.txt)
size_md5s=${size_md5s:0:1}
if [ "$size_md5s" -gt "0" ]; then
	echo 'md5s prepared'
else
	echo 'Problem obtaining md5s.'
fi

#grab urls based on unique md5sums
sort temp_files/md5s.txt | uniq > temp_files/unique_md5s.txt

while IFS='' read -r line || [[ -n "$line" ]]; do 
	grep -m 1 "$line" "files.xml" >> temp_files/unique_lines.txt
done < "temp_files/unique_md5s.txt"

grep -Eo '/portal/.+AssemblyScaffolds_Repeatmasked.fasta.gz' temp_files/unique_lines.txt > temp_files/urls.txt
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "https://genome.jgi.doe.gov$line" | sed -e 's/amp;//' >> temp_files/formatted_urls.txt
done < "temp_files/urls.txt"
echo 'File urls grabbed and formatted.'
python make_files.py temp_files/formatted_urls.txt temp_files/unique_lines.txt temp_files/curls.sh temp_files/unique_md5s.txt temp_files/md5s_and_filenames.txt
printf 'Commmand files written.'
num_downloads=$(wc -l < "curls.sh")
printf "$num_downloads files awaiting download."
printf 'Beginning curls execution.'
bash curls.sh
printf "Curl executions complete."

#check md5
md5sum * > temp_files/local_md5s.txt
sort temp_files/md5s_and_filenames.txt > temp_files/md5s_from_database_sorted.txt
sort temp_files/local_md5s.txt > temp_files/local_md5s_sorted.txt
diff temp_files/md5s_from_database_sorted.txt temp_files/local_md5s_sorted.txt
