#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

genopt="" # Generation-options. At the moment only -d.
force=-1

#### Help-Massage ###
help()
{
echo -e "Aufruf: ./onlineupdate.sh [-d] [-f] ftp-server ftp-user ftp-passwort"
echo -e "\e[1mOnline-Update-Skript für machKarte.rb\e[0m\n"
echo -e "Optionen für machKarte.rb:"
echo -e "\t-d\tDeaktiviert herunterladen der aktuellen Daten."
echo -e "\nOptionen für onlineupdate.sh:"
printf "%10s\t%b\n%10s\t%b\n" "-f" "Erzwinge Upload der neuen Daten, auch wenn" "" "sich die Anzahl der gefundenen Objekte nicht geändert hat."

exit
}

### Check script-arguments ###
while getopts "dfh" optionName; do
 case "$optionName" in
  d) genopt="$genopt -d";;
  f) force="0";;
  h) help;;
  [?]) help;;
 esac
done
shift `expr $OPTIND - 1`

if [ $# -ne 3 ] ; then
help
fi

cd `dirname $0`

### Run generation-skript ###
./machKarte.rb $genopt
num=$?
echo 

### Upload ###
if [ $num -gt 0 ] ; then
oldcount=$(less count)
  # Test if the number of objekts found has been increasing or upload has been forced.
  if [ $num -gt $oldcount -o $force -eq 0 ] ; then
	#Generate compressed package of the Code
	tar -cz machKarte.rb augustkarte.html.in icon_augustiner_30x30.png microbrewery.png README.txt onlineupdate.sh import  > Code.tar.gz
	#Upload the files
	echo "Übertragen per FTP..."
	# Attention: importfolder will not bu uploaded!
	lftp -e "put augustiner.txt; put mikro.kml; put augustiner.xml; put augustkarte.html; put Code.tar.gz; by" ftp://$2:$3@$1/augustkarte
	echo $num > count
  else
	echo "Anzahl der gefundenen Objekte nicht gewachsen. Kein Upload"
	echo "Um Upload zu erzwingen, verwenden sie bitte die Option -f"
  fi
else
	echo "Fehler."
fi
