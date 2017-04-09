#!/bin/bash


#Esimese numbri kysimine kasutajalt
echo "Sisestage esimene number"
read  NUMBER1


#Kas tegemis on numbriga, kashjuks ei tuvasta komaga arve.
if ! [ "$NUMBER1" -eq "$NUMBER1" ] 2> /dev/null
then
	echo "Numbers only"
	exit -1
fi

#Tehte valiku kysimine kasutajalt
echo "Valige tehe mida soovite teha 1.liitmine 2.lahutamine 3.korutamine 4.jagamine"
read TEHE


#Teise numbri kysimine kasutajalt
echo "Sisestage teine number"
read NUMBER2


#Kas tegemist on numbriga, kahjuks ei tuvasta komaga arve.
if ! [ "$NUMBER2" -eq "$NUMBER2" ] 2> /dev/null
then
	echo "Numbers only"
	exit -1
fi


#Tehte tegemine
case "$TEHE" in
	1)
		expr $NUMBER1 + $NUMBER2;;
	2)
		expr $NUMBER1 - $NUMBER2;;
	3)
		expr $NUMBER1 \* $NUMBER2;;
	4)
		expr $NUMBER1 \/ $NUMBER2;;
	*)
		echo "Tundmatu tehte valik"
		exit -1 ;;
esac

