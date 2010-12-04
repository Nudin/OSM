#!/bin/bash

silent="-S"

#Download node
curl -X GET http://api.openstreetmap.org/api/0.6/node/$1 > node

#Create Changset
changeset=$(curl $silent --basic -u Pirat\ Michi:Bluthund -i -X PUT -H "Content-Type: application/xml; charset=utf-8" -d @"changset.nano" http://api.openstreetmap.org/api/0.6/changeset/create | tail -c 7)

echo -e "\n#changeset: $changeset\n"

#Write changeset to file 
less node | sed "s/changeset=\"[0-9]*\"/changeset=\"$changeset\"/g" > node2
mv node2 node

#Edit
nano node

#Upload Node
echo -e "\n#Upload\n"
curl $silent --basic -u Pirat\ Michi:Bluthund -i -X PUT -H "Content-Type: application/xml; charset=utf-8" -d @"node" http://api.openstreetmap.org/api/0.6/node/$1

#clean up
echo -e "\n#Clean Up\n"
changeset=$(curl $silent --basic -u Pirat\ Michi:Bluthund -i -X PUT -H "Content-Type: application/xml; charset=utf-8" -d @"changset.nano" http://api.openstreetmap.org/api/0.6/changeset/$changeset/close)
rm node
