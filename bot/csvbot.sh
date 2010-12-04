#!/bin/bash
IFS="
"
### ToDo ###
#
# fix help()
# more BBoX/Area-Support
# test if "Frankurt/M" is still open
# escape special characters
# Remove Duppletags instead of ignoreing
# way-Support
# much more

curlsilent=""	# '-s' for making curl silent
wgetsilent=""	# '-nv' for making curl silent
dry=0		# if 1: Don't write anything to the server, use 666 as changset-nr.
download=1	# if 0: Don't download the nodelist, but instead use exising one
clean=1		# if 0: Din't remove file at fin
comment=""	# Editing-Comment
file="allnodes" # The filename used for the nodefile
yes=0

bbox=""			# BBox-Koordinates
#dont[0]=""		# For use of '*' as value: If this is in the oldvalue, don't edit. (regex)

# Load the aktual bot
source loadbot.sh
# Load the password
readuserpw


help()	# Print out help-Text
 {
 echo -e "csvbot [-dcsh]  [-f file]"
 echo -e "\t-y t\t\talways answer yes"
 echo -e "\t-c text\t\tset editingcomment manual"
 echo -e "\t-a area\t\tedit only in given area"
 echo -e "\t-s\t\tMake curl to be silent"
 echo -e "\t-d\t\tdry run - don't change anything, just simulate"
 echo -e "\t-f file\t\tDon't download nodelist, but use file instead"
 echo -e "\t-e\t\tDon't erase the nodelist"
 echo -e "\t-h\t\tDisplay this help"
 exit
 }

### Check script-arguments ###
while getopts "df:ec:a:shy" optionName; do
 case "$optionName" in
  d) dry=1;;
  f) download=0;file="$OPTARG";;
  s) curlsilent="-s";wgetsilent="-nv";;
  e) clean=0;;
  c) comment="$OPTARG";;
  a) usearea $OPTARG;;
  y) yes=1;;
  h) help;;
  [?]) help;;
 esac
done
shift `expr $OPTIND - 1`


######### Start of script ##########
### Scan CSV-File and apply rule ###
####################################
lines=$(less filter.csv | grep -v '#' | grep -v '^\W*$' | sort | uniq | wc -l)
for (( n=1; n<$lines; n++ )) ; do
	startlog
	# CSV auslesen
	line=$( less filter.csv | grep -v '#' | grep -v '^\W*$' | sort | uniq | tr -s '\t' | sed -ne "${n}p" )
	key=$(echo $line | cut -f1)
	searchvalue=$(echo $line | cut -f2)
	newkey=$(echo $line | cut -f3)
	newvalue=$(echo $line | cut -f4)

	simpelbot "$key" "$searchvalue" "$newkey" "$newvalue"
	succes=$?
	
	if [ $succes -gt 2 ] ; then exit ; fi
comment=""
done

## Upload Log
lftp -e "put logfile.csv; by" ftp://$ftpuser:$ftppw@$ftpserver/osm
