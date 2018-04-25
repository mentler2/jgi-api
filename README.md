# jgi-api
These files allow users to download genome sequences for whole phylogenies defined in the JGI database heirarchy. The scripts parse the xml heirarchy, isolate urls for unqiue masked genome assembly files, and download those files to the current directory. When multiple copies of the same file exist in the xml heirarchy only the first file is downloaded. 

Syntax: 
sudo bash commands_w_unique_md5.sh [phylogeny] 

where [phylogeny] is supplied by the user, and corresponds to any node in the JGI database heirarchy. 
