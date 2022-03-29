# jgi-api
These scripts allow users to download sets of files defined in the Joint Genome Institute (JGI) database heirarchy. The scripts parse the xml heirarchy, isolate urls for user-defined file types, and download those files to the current directory. Files with an md5sum hash are prioritized, but files lacking an associated hash are permitted. Filtering strategy begins with the full file heirarchy, then reduces the full list based on the user-defined search string, then splits into two forks: 1) files with md5sum hashes > files with unique md5sum hash/filename pairs, 2) remaining files without hashes and with unique filenames, both internally and when compared to the set from fork 1. When filenames in the xml heirarchy are repeated, but the associated files have unique md5sum hashes, only the first file is downloaded. The script is interactive and prompts the user for required input. 

Prequisites: 
  - JGI account. 
  - POSIX shell. Only bash has been tested. 
  - Either python 2 or 3 should be in your PATH and accessible from the terminal. 

Syntax: 
bash invoke.sh 
