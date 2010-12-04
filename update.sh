#!/bin/bash

rm josm-tested.jar
wget http://josm.openstreetmap.de/josm-tested.jar
if [ $? -ne 0 ] ; then
 zenity --error
fi
rm josm-latest.jar
wget http://josm.openstreetmap.de/josm-latest.jar
if [ $?	-ne 0 ] ; then
 zenity --error
fi

