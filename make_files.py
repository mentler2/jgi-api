import sys
import re

file_in = open(sys.argv[1], "r") #formatted_urls.txt
file_in2 = open(sys.argv[2], "r") #unique_lines.txt
file_in3 = open(sys.argv[4], "r") #unique_md5s.txt
file_out = open(sys.argv[3], "w") #curls.sh
file_out2 = open(sys.argv[5], "w") #md5s_and_filenames.txt
file_in4 = open(sys.argv[7], "r") #formatted_urls_without_md5s.txt
file_in5 = open(sys.argv[8], "r") #lines_without_md5.xml
file_out3 = open(sys.argv[9], "w") #curls_without.md5.sh

# version notes: This string matching logic was previously implemented on the urls.
# That strategy was limited because it wasn't able to grab the existing file suffixes.
# Also, it precluded the possibility of detecting repeated filenames with different md5sums,
# which this strategy handles.
filenames = []
filenames_no_md5 = []
lines_xml = file_in2.read().splitlines()
sums = file_in3.read().splitlines()
lines_xml_no_md5 = file_in5.read().splitlines()

##############################################################
# regional expression will match two instances (called groups in python) within a 
# single line of the xml file, once within the "filename" tag and once within the 
# "url" tag. This code grabs only the filename. 
for line in lines_xml:
	if re.search("filename=", line):
		substring = re.findall('filename=".+?"', line) # returns a list, even if only one match
		split_temp = []
		split_temp = re.split("=", str(substring[0]))
		filenames.append(split_temp[1].strip("\""))
# find and print repeated filenames with unique md5sums########
unique_filenames = set(filenames)
seen = {}
repeats = []
for name in filenames:
	if name not in seen:
		seen[name] = 1
	else:
		if seen[name] == 1:
			repeats.append(name)
		seen[name] +- 1
if len(repeats) > 0:
	print('Warning: Repeated filenames with unique md5sums exist. Please manually verify.')
	print('Printing nonunique filenames.')
	print(repeats)
for line in lines_xml_no_md5:
	if re.search("filename=", line):
		substring = re.findall('filename=".+?"', line) # returns a list, even if only one match
		split_temp = []
		split_temp = re.split("=", str(substring[0]))
		filenames_no_md5.append(split_temp[1].strip("\""))

repeats_no_md5 = []
i=0
filenames_no_md5_unique = {}
for name in filenames_no_md5:
	if name not in seen:
		seen[name] = 1
		filenames_no_md5_unique[name] = i
		i = i + 1
	else:
		if seen[name] == 1:
			repeats_no_md5.append(name)
		seen[name] +- 1
		i = i + 1
if len(repeats_no_md5) > 0:
	print('Excluding files without an md5sum hash that share a filename with files associated with an md5sum hash.')
	print(repeats_no_md5)
###############################################################

#### write files ##############################################
lines = file_in.read().splitlines()
for i in range(len(lines)):
	file_out.write('curl ' + ' -b ' + sys.argv[6] + '/cookies --output ' + filenames[i] + ' ' + lines[i] + '\n')
for i in range(len(sums)):
	file_out2.write(sums[i] + '  ' + filenames[i] + '\n')

lines_no_md5 = file_in4.read().splitlines()

keys = filenames_no_md5_unique.keys()
for i in range(len(keys)):
	file_out3.write('curl ' + ' -b ' + sys.argv[6] + '/cookies --output ' + keys[i] + ' ' + lines_no_md5[filenames_no_md5_unique[keys[i]]] + '\n')
################################################################
