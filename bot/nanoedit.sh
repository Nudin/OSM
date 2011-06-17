#!/bin/bash

silent="-S"

readuserpw()
 {
        user=$(less user | sed '1!d' )
        pw=$(less user | sed '2!d')
        ftpserver=$(less user | sed '3!d')
        ftpuser=$(less user | sed '4!d')
        ftppw=$(less user | sed '5!d')
 }

readuserpw

#Download node
curl -X GET http://api.openstreetmap.org/api/0.6/node/$1 > node

#Create Changset
changeset=$(curl $silent --basic -u ${user}:${pw} -i -X PUT -H "Content-Type: application/xml; charset=utf-8" -d @"changset.nano" http://api.openstreetmap.org/api/0.6/changeset/create | tail -c 7)

echo -e "\n#changeset: $changeset\n"

#Write changeset to file
less node | sed "s/changeset=\"[0-9]*\"/changeset=\"$changeset\"/g" > node2
mv node2 node

#Edit
nano node

#Upload Node
echo -e "\n#Upload\n"
curl $silent --basic -u ${user}:${pw} -i -X PUT -H "Content-Type: application/xml; charset=utf-8" -d @"node" http://api.openstreetmap.org/api/0.6/node/$1

#clean up
echo -e "\n#Clean Up\n"
changeset=$(curl $silent --basic -u ${user}:${pw} -i -X PUT -H "Content-Type: application/xml; charset=utf-8" -d @"changset.nano" http://api.openstreetmap.org/api/0.6/changeset/$changeset/close)
rm node
