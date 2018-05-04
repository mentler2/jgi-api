# jgi-api
These scripts allow users to download sets of files defined in the JGI database heirarchy. The scripts parse the xml heirarchy, isolate urls for user-defined file types, and download those files to the current directory. When multiple copies of the same file exist in the xml heirarchy only the first file is downloaded. The script is interactive and prompts the user for required input. 

Prequisites: 
  - POSIX shell. Only bash has been tested. 
  - Either python 2 or 3 should be in your PATH and accessible from the terminal. 

Syntax: 
bash invoke.sh 
