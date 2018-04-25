#!bash/bin/
# pass group name as first variable

curl 'https://signon-old.jgi.doe.gov/signon/create' --data-urlencode 'login=mentler@vols.utk.edu' --data-urlencode 'password=Ee3coba69@' -c cookies 
curl --cookie cookies --output files.xml "https://genome.jgi.doe.gov/portal/ext-api/downloads/get-directory?organism=$1&organizedByFileType=false"

#grab md5s
grep -E 'AssemblyScaffolds_Repeatmasked.fasta.gz' "files.xml" | grep -Eo 'md5=".+"' > unformatted_md5s.txt
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "$line" | sed -e 's/md5="//' | sed -e 's/"//' >> md5s.txt
done < "unformatted_md5s.txt"
size_md5s=$(ls -s md5s.txt)
size_md5s=${size_md5s:0:1}
if [ "$size_md5s" -gt "0" ]; then
	echo 'md5s prepared'
else
	echo 'problem obtaining md5s'
fi

#grab urls based on unique md5sums
sort md5s.txt | uniq > unique_md5s.txt

while IFS='' read -r line || [[ -n "$line" ]]; do 
	grep -m 1 "$line" "files.xml" >> unique_lines.txt
done < "unique_md5s.txt"

grep -Eo '/portal/.+AssemblyScaffolds_Repeatmasked.fasta.gz' unique_lines.txt > urls.txt
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "https://genome.jgi.doe.gov$line" | sed -e 's/amp;//' >> formatted_urls.txt
done < "urls.txt"
echo 'urls grabbed and formatted'
python make_files.py formatted_urls.txt unique_lines.txt curls.sh unique_md5s.txt md5s_and_filenames.txt
echo 'md5 and curl commmand files written'
num_downloads=$(wc -l < "curls.sh")
echo "$num_downloads files to download"
echo 'beginning curls execution'
bash curls.sh
echo "sequences of $1 downloaded"

#check md5
md5sum * > local_md5s.txt
sort md5s_and_filenames.txt > md5s_from_database_sorted.txt
sort local_md5s.txt > local_md5s_sorted.txt
diff md5s_from_database_sorted.txt local_md5s_sorted.txt