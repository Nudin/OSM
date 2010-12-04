#!/bin/bash
rm namensliste.txt
less augustiner.txt | cut -f 3 | sort > namensliste.txt
echo -e '\e[1m\e[31mMöglicherweiße fehlende Lokale:\e[0m'
echo -e '\e[33mIn München:\e[0m'
diff vergleichsliste.muc.s.txt namensliste.txt -bBi | grep \< | grep -v  -f falsepositive

echo -e '\e[33mAuserhalb:\e[0m'
diff vergleichsliste.nmuc.s.txt namensliste.txt -bBi | grep \< | grep -v  -f falsepositive
