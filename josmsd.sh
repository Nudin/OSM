#!/bin/bash
## Usage
# josmsd.sh [-b minlat,minlon,maxlat,maxlon] [-a Name] key value

bbox=0
open=1

help()
{
echo -e "josmsd.sh [-b minlat,minlon,maxlat,maxlon] [-a Name] [-o] key value"
exit
}
warn()
{
echo -e "ACHTUNG: Bereich sehr groß!"
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

### Check script-arguments ###
while getopts "a:b:oh" optionName; do
 case "$optionName" in
  b) bbox=$OPTARG;;
  a) usearea $OPTARG;;
  o) open=0;;
  h) help;;
  [?]) help;;
 esac
done
shift `expr $OPTIND - 1`

if [ $# -ne 2 ] ; then
	help
else
	key=$1
	searchvalue=$2
fi

echo "kex: $key"
echo "value: $searchvalue"
echo "bbox: $bbox"


wget "http://osmxapi.hypercube.telascience.org/api/0.6/node[${key}=${searchvalue}][bbox=$bbox]" -O josmfile.osm

if [ $open -eq 0 ] ; then
 exit
fi

java -jar josm-tested.jar --download=josmfile.osm
rm josmfile.osm

