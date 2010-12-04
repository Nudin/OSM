#!/bin/bash
neu_de="Neues_Profil"
dup_de="Profil_duplizieren"
tested_de="tested"
latest_de="latest"
name_de="Bitte Namen angeben:"
version_de="Welche JOSM ersion soll verwendet werden?"
choose_de="Bitte Profil auswählen"
title_de="JOSM-Profile-Manager"
open()
 {
 unlink ~/.josm
 ln -s ~/.josm_profiles/$1 ~/.josm
  }
create()
 {
 mkdir ~/.josm_profiles/$1
 echo -e "$1\t$2" >> ~/.josm_profiles/list
 }
clone()
 {
 cp -r ~/.josm_profiles/$1 ~/.josm_profiles/$2
 echo -e "$2\t$3" >> ~/.josm_profiles/list
 }
getlist()
 {
 cat ~/.josm_profiles/list
 }
showmenue()
 {
 if [ $1 -eq 1 ] ; then #Show edit entrys?
	edit="$neu_de -  $dup_de -"
 fi
 zenity --height=250 --title "$title_de" --text "$choose_de" --list --column=Name --column=Version $(getlist | sed "s/0/$tested_de/g" | sed "s/1/$latest_de/g") $edit
 if [ $? -ne 0 ] ; then return 1; fi
 }
startjosm()
 {
 cd ~/OSM
 if [ "$(cat ~/.josm_profiles/list | grep ^$1 | cut -f2)" -eq 0 ] ; then
	java -jar josm-tested.jar
 else
 	java -jar josm-latest.jar
 fi
 }

chose=$(showmenue 1)
if [ $? -ne 0 ] ; then exit 1; fi
if [ "$chose" = "$neu_de" ] ; then
	name=$(zenity --entry --title "$title_de" --text "$name_de")
	if [ $? -ne 0 ] ; then exit 1 ; fi
	version=$(zenity --title "$title_de" --text "$version_de" --list --column=nr --column=version --hide-column=1 0 $tested_de 1 $latest_de)
	if [ $? -ne 0 ] ; then exit 1 ; fi
	create "$name" "$version"
	open "$name"
	startjosm "$name"
elif [ "$chose" = "$dup_de" ] ; then
	old=$(showmenue 0)
	new=$(zenity --title "$title_de" --entry --text "$name_de")
	if [ $? -ne 0 ] ; then exit 1 ; fi
	version=$(zenity --title "$title_de" --text "$version_de" --list --column=nr --column=version --hide-column=1 0 $tested_de 1 $latest_de)
	if [ $? -ne 0 ] ; then exit 1 ; fi
	clone "$old" "$new" "$version"
else
	open "$chose"
	startjosm "$chose"
fi
