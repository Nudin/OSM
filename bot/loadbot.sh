#!/bin/bash

startlog()
 {
 echo -en "\n" >> logfile.csv
 }
 
 ## Write message to log
 # $1: size of space
 # $2: status (0 normal=normal, 1 error=red, 2 info=blue, 3 success=green)
 # $3: text
 ### OR
 # $2: -q --> don't print out, only log
 # $3: text
log()
 {
 if [ "$1" = "-q" ] ; then
	shift
 else
        color='\e[0m'
 	if [ ${#} -eq 1 ] ; then : 
 	elif [ $1 -eq 0 ] ; then shift
 	elif [ $1 -eq 1 ] ; then color='\e[31m'; shift
 	elif [ $1 -eq 2 ] ; then color='\e[34m'; shift
 	elif [ $1 -eq 3 ] ; then color='\e[32m'; shift
 	fi
	echo -en "${color}"
	echo -en "$@" | tail -c +3
	echo -e "\e[0m"
 fi
 for ((t=0; t<$1; t++)) ; do
	echo -en "\t" >> logfile.csv
 done
 shift
 for i ; do
	echo -en "$i\t" >> logfile.csv
 done
 }

readuserpw()
 {
	user=$(less user | sed '1!d' )
	pw=$(less user | sed '2!d')
	ftpserver=$(less user | sed '3!d')
	ftpuser=$(less user | sed '4!d')
	ftppw=$(less user | sed '5!d')
 }


# Download from XAPI 
XAPIdownload()	# $1: query $2:filename
 {
 api_url=("http://jxapi.openstreetmap.org/xapi/api/0.6/" "http://open.mapquestapi.com/xapi/api/0.6/" "http://www.informationfreeway.org/api/0.6/" "http://xapi.openstreetmap.org/api/0.6/" "http://osmxapi.hypercube.telascience.org/api/0.6/" "http://osm.bearstech.com/osmxapi/api/0.6/")

 for (( i=0; i<${#api_url[*]}; i++ )) ; do
	wget $wgetsilent "${api_url[$i]}$1" -O $2
	if [ $? -eq 0 ]; then break; else echo "Trying next Server" ; fi
	if [ $i -eq $(expr ${#api_url[*]} "-" 1) ]; then log 2 1 "No xapi-Server working" ; return 1; fi
 done

 }

put()	# $1: url $2 file
{
curl $curlsilent --basic -u $user:$pw -i -X PUT -H "Content-Type: application/xml; charset=utf-8" -d @"$2" $1
}
get()	# $1: url $2 file
{
curl $curlsilent -X GET $1 > $2
}

# Use a predefined bbox-area
usearea()
 {
 case $1 in
  muc) bbox="11.47453,48.09138,11.66748,48.18257";;
  Muc) bbox="11.45187,48.06982,11.69357,48.20180";;
  MUC) bbox="11.19781,48.03035,11.81717,48.26126";;
  gern) bbox="11.51916,48.15755,11.53187,48.16694";;
  altstadt) bbox="11.56599,48.13385,11.58440,48.14158";;
  bayern) warn; bbox="9.42627,47.28668,13.75488,50.54834";;
  bawü) warn; bbox="7.4597168,47.3983492,10.7116699,50.4575040";;
  berlin) bbox="13.1451416,52.3168743,13.6944580,52.6730514";;
  ostd) bbox="10.8984375,50.3314363,14.7106934,54.2395505";;
  ger) warn; bbox="6.15234,47.45781,13.79883,54.26522";;
  vorarlberg) warn; bbox="9.6405029,46.7962990,10.6539917,47.6468870";; # guessed
  tirol) warn; bbox="10.5139160,46.7662059,12.7880859,47.6320819";; # guessed
  wien) bbox="16.2130737,48.0881707,16.5701294,48.3115146";; # groß
  [?]) help;;
 esac
 }


# This is the actual bot.
simpelbot()
{
	key=$1
	searchvalue=$2
	newkey=$3
	newvalue=$4

	#API-Adress
	api="http://api.openstreetmap.org/api/0.6"

	# Generate value - we have to use this, because xapi expects '*' while sed expects regex
	if [ "$searchvalue" = '*' ] ; then
		value=".*"
	else
		value=$searchvalue
	fi
	searchvalue=$(echo $searchvalue | sed 's/\//\\\//g')

	# Generate BBox-code, if bbox is given
	if [ "$bbox" != "" ] ; then
		bboxcode="[bbox=$bbox]"
	fi
	# Generate Comment, if not given.
	if [ "$comment" = "" ] ; then
		comment="Bot: changing $key=$value to $newkey=$newvalue"
	fi

	# Write Log-File
	log -q 0 "$(date '+%Y-%m-%d %T')"
	log -q 0 "$key" "$value" "$newkey" "$newvalue"

	# Asking if realy to start
	if [ $yes -eq 0 ] ; then
		echo -en '\e[1m'
		echo -e "\nGoing to change $key=$value to $newkey=$newvalue"
		echo -en '\e[0m'
		echo -e "Do you realy want to do this? (\e[1my\e[0mes/\e[1mn\e[0mext/\e[1ma\e[0mbort)"
		read rly
		if [ "$( echo $rly | grep n)" != "" ]  ; then log 2 2 "skipping.." ; return 1 ; fi
		if [ "$( echo $rly | grep a)" != "" ]  ; then log 2 2 "aborting, by" ; exit ; fi
		if [ "$( echo $rly | tr 'j' 'y' | grep y)" = "" ]  ; then echo "Wrong input, interpreting as abort" ; exit ; fi
	fi

	# Write comment to Changesetfile
	less changset.bot | rx=$comment perl -pe 's/@@@/$ENV{rx}/' > mychangset	#Use Perl instead of sed, because perl dosn't interpret the text
	if [ $? -ne 0 ] ; then log 2 1 "Error setting comment; aborting"; return 7 ; fi

	# Download Node-list
	if [ $download -eq 1 ] ; then
		XAPIdownload "node[${key}=${searchvalue}]$bboxcode" "$file"
	fi
	number=$(less $file | grep "<node id=" | wc -l )
	if [ $number -eq 0 ] ; then # If there ist nothing to edit, exit
	 log 2 1 "Suchausdruck nicht gefunden. Nichts weiter zu tun"
	 rm $file
	 return 2
	else
	 echo -e "\e[34m### Starting editing" $number "nodes ### \e[0m\n"
	 log -q 0 "$number"
	fi

	# Create Changset
	if [ $dry -eq 0 ] ; then
		changeset=$(put "$api/changeset/create" "mychangset" | tail -c 7)
		if [ $? -ne 0 ] ; then log 1 1 "Error creating changset."; return 3 ; fi
	else
		changeset="666"
	fi
	echo -en "#changeset: "; log 0 2 "$changeset"


	#####		 Start Loop: 		#####
	##### Edit and upload every single node	#####
	for id in $(less $file | grep "<node id=\"" | cut -d\" -f 2); do
		echo -e "ID: $id"

		#Download node
		get "$api/node/$id" "node$id"

		#Get oldvalue, prepare newvalue, etc
		oldvalue=$(less node$id | grep "<tag k=\"$key\"" | cut -d\" -f 4)
		if [ "$newvalue" = "*" ] ; then
			newvaluefixed=$(echo $oldvalue | sed 's/\//\\\//g')
		else
			newvaluefixed=$(echo "$newvalue" | sed 's/\//\\\//g')
		fi

		#Filter unwanted Tags
		for (( i=0; i<${#dont[*]}; i++ )) ; do
		 if [ "$( echo $oldvalue | grep "${dont[$i]}" )" != "" ] ; then
			echo "Don't modify"
			rm node$id
			continue
		 fi
		done

		#Filter dupple-taged elements.
		if [ "$key" != "$newkey" ] ; then
		 if [ $(less node$id | grep -c "<tag k=\"$newkey\" v=\"$newvaluefixed\"/>") -gt 0 ] ; then
			echo "Skipping Dupple entry."
			rm node$id
			continue
		 elif [ $(less node$id | grep -c "<tag k=\"$newkey\" v=\"") -gt 0 ] ; then
			echo "Skipping rival tags"
			rm node$id
			continue
		fi fi

		#Write changeset to file 
		less node$id | sed "s/changeset=\"[0-9]*\"/changeset=\"$changeset\"/g" > node2
		if [ $? -ne 0 ] ; then log 0 1 "Error setting changesetnumber; aborting"; return 4 ; fi
		mv node2 node$id

		#Edit
		cat node$id | grep -v "<tag k=\"$key\" v=\"$value\"\/>" > node2	# Remove old key
		diff --brief node$id node2 > /dev/null
		if [ $? -ne 1 ] ; then log 0 1 "Error editing node; aborting"; continue ; fi
		cat node2 | head -n -2 > node3
		echo "    <tag k=\"$newkey\" v=\"$newvaluefixed\"/>" >> node3	# Add new key
		echo -e "  </node>\n</osm>" >> node3
		
		diff --brief node3 node$id > /dev/null
		if [ $? -eq 0 ] ; then
			log 0 3 "Nothig to change/changing didn't worked out."
			rm node2 node3 node$id
			continue
		elif [ $? -eq 1 ] ; then
			rm node2
			mv node3 node$id
		else
			log 0 1 "Something strage occured. Exiting"
			return 6
		fi

		#Upload Node
		if [ $dry -eq 0 ] ; then
			put "$api/node/$id" "node$id" | if [ "$curlsilent" = "-s" ] ; then grep "Status:"; else grep '' ; fi
		else
			echo -e "\nDon't Upload\n"
		fi

		rm node$id
	done

	#Close Chngeset
	echo -e "\nClean Up\n"
	if [ $dry -eq 0 ] ; then
		put "$api/changeset/$changeset/close" "mychangset" | if [ "$curlsilent" = "-s" ] ; then grep "Status:"; else grep '' ; fi
	fi
	if [ $dry -eq 1 ] ; then
	log 0 2 "Dry-Mode. Don't upload anything"
	fi
	#Remove files
	if [ $clean -eq 1 ] ; then
		rm $file
		rm mychangset
	fi
}

