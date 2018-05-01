import sys
import re

file_in = open(sys.argv[1], "r") #formatted_urls.txt
file_in2 = open(sys.argv[2], "r") #unique_lines.txt
file_in3 = open(sys.argv[4], "r") #unique_md5s.txt
file_out = open(sys.argv[3], "w") #curls.sh
file_out2 = open(sys.argv[5], "w") #md5s_and_filenames.txt

# version notes: This string matching logic was previously implemented on the urls.
# That strategy was limited because it wasn't able to grab the existing file suffixes.
# Also, it precluded the possibility of detecting repeated filenames with different md5sums,
# which this strategy handles.
filenames = []
lines_xml = file_in2.read().splitlines()
sums = file_in3.read().splitlines()

##############################################################
# regional expression will match two instances (called groups in python) within a 
# single line of the xml file, once within the "filename" tag and once within the 
# "url" tag. This code grabs only the filename. 
for line in lines_xml:
	if re.search("filename=", line):
		match_start = re.search("filename=", line) #returns one match object
		start_index = match_start.start() #starting index of the first matching group
		matches_end = re.search(str(sys.argv[6]), line) #returns one match object with two groups
		end_index = matches_end.end(0) # ending index of the first matching group (index 0 is the whole match, which includes the first group and other groups)
		# possible python version compatibility issue here
		substring = line[start_index:end_index+1] #slice the string
		split_temp = []
		split_temp = re.split("=", str(substring))
		filenames.append(split_temp[1].strip("\""))
################################################################

unique_filenames = set(filenames)
if len(unique_filenames) != len(filenames):
	print('Warning: Repeated filenames with unique md5sums exist. Appending md5sum to filename prefix to differentiate.')
	for i in range(len(filenames)):
		filenames[i]=str(sums[i])+str(filenames[i])

lines = file_in.read().splitlines()
for i in range(len(lines)):
	file_out.write('curl ' + '\'' + lines[i] + '\'' + ' -b cookies --output ' + filenames[i] + '\n')
 
for i in range(len(sums)):
	file_out2.write(sums[i] + '  ' + filenames[i] + '\n')
