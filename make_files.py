import sys
import re

print sys.argv
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
for line in lines_xml:
	if re.search("filename=", line):
		match_start = re.search("filename=",line) #returns one match object
		start_index = match_start.start()
		matches_end = re.search("(AssemblyScaffolds_Repeatmasked.fasta.gz)", line) #returns one match object with two groups
		end_index = matches_end.end(1) # ending index of the first matching group
		substring = line[start_index:end_index+1] #slice the string
		split_temp = []
		split_temp = re.split("=", str(substring))
		filenames.append(split_temp[1].strip("\""))
################################################################

unique_filenames = set(filenames)
print 'length of filenames is: ' + str(len(filenames))
print 'length of unique_filenames is: ' + str(len(unique_filenames))
print 'length of md5sums is: ' + str(len(sums))
if len(unique_filenames) != len(filenames):
	print 'Warning: Repeated filenames with unique md5sums exist. Appending md5sum to filename prefix to differentiate.'
	for i in range(len(filenames)):
		filenames[i]=str(sums[i])+str(filenames[i])

lines = file_in.read().splitlines()
print 'length of lines is: ' + str(len(lines))
for i in range(len(lines)):
	file_out.write('curl ' + '\'' + lines[i] + '\'' + ' -b cookies --output ' + filenames[i] + '\n')
 
print 'length of md5sums is: ' + str(len(sums))
for i in range(len(sums)):
	file_out2.write(sums[i] + '  ' + filenames[i] + '\n')
