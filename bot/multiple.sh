#!/bin/bash
IFS="
"
### ToDo ###
#
# fix help()
# get keys&values by option ?
# Name for Skript/bot
# more BBoX/Area-Support
# escape special characters !
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


key="biergarten"
searchvalue="yes"
newkey="beer_garden"
newvalue="yes"	# Put a '*' in here to leave the old value
bbox=""			# BBox-Koordinates
#dont[0]=""		# For use of '*' as value: If this is in the oldvalue, don't edit. (regex)

# Load the aktual bot
source loadbot.sh
# Load the password
readuserpw

help()	# Print out help-Text
{
echo -e "multiple [-dcsh]  [-f file]"
echo -e "\t-y t\t\talways answer yes"
echo -e "\t-c text\t\tset editingcomment"
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


### Start ###
	startlog
	simpelbot "$key" "$searchvalue" "$newkey" "$newvalue"

## Upload Log
	lftp -e "put logfile.csv; by" ftp://$ftpuser:$ftppw@$ftpserver/osm
