#!/bin/bash

read -p "JGI Username: " username
read -s -p "JGI Password: " password
echo ''
read -p "Name of new directory to store process and overview files: " new_directory
mkdir "$new_directory"
echo ''
curl -s 'https://signon-old.jgi.doe.gov/signon/create' --data-urlencode "login=$username" --data-urlencode "password=$password" -c "$new_directory/cookies"
lines_cookies=($(wc -l "$new_directory/cookies"))
if [ "${lines_cookies[0]}" -eq "6" ]; then
	echo ''
	echo "Successful login."
	echo ''
else
	echo ''	
	echo "Unsuccessful login. Terminating script."
	rm -r "$new_directory"
	exit 1
fi
read -p "Node name (e.g., 'fungi,' or 'pucciniomycotina'): " node_name
curl --cookie "$new_directory/cookies" --output "$new_directory/files.xml" "https://genome.jgi.doe.gov/portal/ext-api/downloads/get-directory?organism=$node_name&organizedByFileType=false"
lines_file_heirarchy=($(wc -l "$new_directory/files.xml")) #output goes into an array
echo ''
if [ "${lines_file_heirarchy[0]}" -gt 2 ]; then #if more lines exist than the number required for default error statements
	echo "File heirarchy downloaded to "$new_directory/files.xml"."
else
	echo 'Problem obtaining file heirarchy. Please ensure you are attempting to interrogate a valid node. This can be done by checking the JGI genome database for the presence of a download option. If you are working within a restricted network your shell settings may need to be adjusted to permit downloads.'
	echo ''
	rm -r "$new_directory"
	echo 'Script terminated.'
	exit 1
fi
echo ''

#grab md5sums based on search string
echo 'Enter search string to interrogate file heirarchy. For example, "AssemblyScaffolds_Repeatmasked". If necessary you can peruse the downloaded file heirarchy to see available file types.'
echo ''
read -p "Search string: " search_string
grep -E "$search_string" "$new_directory/files.xml" > "$new_directory/all_lines_containing_search_string.txt"
grep -E "$search_string" "$new_directory/files.xml" | grep -E 'md5=".+"' > "$new_directory/lines_with_search_and_md5.xml"
grep -E "$search_string" "$new_directory/files.xml" | grep -Eo 'md5=".+"' > "$new_directory/unformatted_md5s.txt"
num_all=($(wc -l "$new_directory/all_lines_containing_search_string.txt"))
num_w_md5s=($(wc -l "$new_directory/lines_with_search_and_md5.xml"))
difference=$((num_all[0]-num_w_md5s[0]))
echo "$num_all files contain search string. $num_w_md5s are tagged with md5sum hashes and $difference lack md5sum hashes."

while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "$line" | sed -e 's/md5="//' | sed -e 's/"//' >> "$new_directory/md5s.txt"
done < "$new_directory/unformatted_md5s.txt"
if [ -s "$new_directory/md5s.txt" ]; then
	echo "md5sum hashes prepared."
else
	echo "Problem obtaining md5s."
	rm -r "$new_directory"
	echo "Script terminated."
	exit 1
fi

#grab urls based on unique md5sums
sort "$new_directory/md5s.txt" | uniq > "$new_directory/unique_md5s.txt"

while IFS='' read -r line || [[ -n "$line" ]]; do 
	grep -m 1 "$line" "$new_directory/files.xml" >> "$new_directory/unique_lines.txt"
done < "$new_directory/unique_md5s.txt"

grep -Eo "url=\".*$search_string[^\"]*\"" "$new_directory/unique_lines.txt" | sed -e 's/url="//' | sed -e 's/^"//' -e 's/"$//' > "$new_directory/urls.txt"
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "https://genome.jgi.doe.gov$line" | sed -e 's/amp;//' >> "$new_directory/formatted_urls.txt"
done < "$new_directory/urls.txt"
if [ -s "$new_directory/formatted_urls.txt" ]; then
	echo 'File urls grabbed and formatted.'
else
	echo 'Problem obtaining file urls.'
	rm -r "$new_directory"
	echo 'Script terminated.'
	exit 1
fi

#grab urls of files without an md5sum
diff --suppress-common-lines "$new_directory/all_lines_containing_search_string.txt" "$new_directory/lines_with_search_and_md5.xml" > "$new_directory/lines_without_md5.xml"

grep -Eo "url=\".*$search_string[^\"]*\"" "$new_directory/lines_without_md5.xml" | sed -e 's/url="//' | sed -e 's/^"//' -e 's/"$//' > "$new_directory/urls_without_md5.txt"
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "https://genome.jgi.doe.gov$line" | sed -e 's/amp;//' >> "$new_directory/formatted_urls_without_md5.txt"
done < "$new_directory/urls_without_md5.txt"
if [ -s "$new_directory/formatted_urls_without_md5.txt" ]; then
	echo "Urls for files lacking md5sum hash grabbed and formatted."
elif [ -e "$new_directory/formatted_urls_without_md5.txt" ]; then
	echo "File containing urls of filenames lacking a hash is empty."
else
	echo "No file exists for urls of filenames without a hash. This will result in an error in python script execution. Creating empty file."
	touch "$new_directory/formatted_urls_without_md5.txt"
fi

# write executable files
python make_files.py "$new_directory/formatted_urls.txt" "$new_directory/unique_lines.txt" "$new_directory/curls.sh" "$new_directory/unique_md5s.txt" "$new_directory/md5s_and_filenames.txt" "$new_directory" "$new_directory/formatted_urls_without_md5.txt" "$new_directory/lines_without_md5.xml" "$new_directory/curls_without_md5.sh"
echo 'Command files written.'

#download files with an md5sum
num_downloads=$(wc -l < "$new_directory/curls.sh")
echo ''
echo 'Beginning curls execution of files tagged with md5sum hash.'

counter="0"
while IFS='' read -r line || [[ -n "$line" ]]; do 
	echo $line
	$line
	counter=$((counter+1))
	echo "$counter of $num_downloads files downloaded."
done < "$new_directory/curls.sh"
echo "Curl executions complete."

#check md5
echo ''
md5sum *$search_string* > "$new_directory/local_md5s.txt"
sort "$new_directory/md5s_and_filenames.txt" > "$new_directory/md5s_from_database_sorted.txt"
sort "$new_directory/local_md5s.txt" > "$new_directory/local_md5s_sorted.txt"
echo ''
echo "Calculating md5sums..."
diff -q "$new_directory/md5s_from_database_sorted.txt" "$new_directory/local_md5s_sorted.txt" > md5_check.txt
if [ -s md5_check.txt ]
then
	cat md5_check.txt
else
	echo "All files passed md5sum check."
fi
#download files without an md5sum hash
num_downloads_nomd5=$(wc -l < "$new_directory/curls_without_md5.sh")
echo ''
echo 'Beginning curls execution of files lacking md5sum hash.'

counter="0"
while IFS='' read -r line || [[ -n "$line" ]]; do 
	echo $line
	$line
	counter=$((counter+1))
	echo "$counter of $num_downloads_nomd5 files downloaded."
done < "$new_directory/curls_without_md5.sh"
echo "Curl executions complete."

#cleanup
rm "$new_directory/curls.sh" "$new_directory/cookies" "$new_directory/formatted_urls.txt" "$new_directory/local_md5s.txt" "$new_directory/md5s_and_filenames.txt" "$new_directory/md5s.txt" "$new_directory/unformatted_md5s.txt" "$new_directory/unique_lines.txt" "$new_directory/unique_md5s.txt" "$new_directory/urls.txt" "$new_directory/all_lines_containing_search_string.txt" "$new_directory/curls_without_md5.sh" "$new_directory/formatted_urls_without_md5.txt" "$new_directory/lines_without_md5.xml" "$new_directory/lines_with_search_and_md5.xml" "$new_directory/urls_without_md5.txt"
rm "md5_check.txt"
mv "$new_directory/local_md5s_sorted.txt" "$new_directory/local.md5"
mv "$new_directory/md5s_from_database_sorted.txt" "$new_directory/JGI.md5"
echo ''
echo "Script complete."
