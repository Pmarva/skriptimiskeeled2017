#!/bin/bash

SHARE=""

#Juurkasutaja ja atribuutide sisendid v6tsin wiki n2itest, sealt 6ppisin saama faili nime millega hetkel t66datakse ja kuidas sisendied kontrollida.
#Kontrollib, kas skript on käivitatud juurkasutajana
if [ $UID -ne 0 ]
then
  echo "k2ivita skript $(basename $0) juurkasutaja6igustes"
  exit 1
fi


if [ $# -eq 2 ]
then
  KAUST=$1
  GRUPP=$2

else
  if [ $# -eq 3 ]
  then
    KAUST=$1
    GRUPP=$2
    SHARE=$3
  else
    echo "kasuta skripti$(basename $0) KAUST GRUPP [SHARE]"
    exit 1
  fi
fi

#Kas samba on installitud v6i mitte.
hash samba

if [ $? -ne 0 ]
then
    echo "Samba installi ei leitud"
    echo "Teeme uuenduse ja installime samba"
    apt update
    apt install samba -yf 

    if [$? -ne 0]
    then
        echo "Samba install eba6nnestus"
        exit 1
    fi
fi



#Kontrollib kas kaust on olemas

if [ ! -d $KAUST ]; then
    echo "Kausta ei ole olemas, kaust luuakse"
    mkdir -p $KAUST
fi

#Kontrollib, kas grupp on olemas (vajadusel loob)
getent group $GRUPP > /dev/null

if [ $? -ne 0 ]
then
    groupadd $GRUPP
    if [ $? -ne 0 ]
    then
        echo "G5ruppi lisamine eba6nnestus"
	exit 1
    fi
fi


#Teeme koopia originaal confi failist
cp /etc/samba/smb.conf /etc/samba/smb.conf.backup

if [ $? -ne 0 ]
then
    echo "confi backup eba6nnestus"
    exit 1
fi

# kas kolmas atribuut oli olemas v6i mitte, kui ei olnud pannakse kolmanda v22rtuseks teise atribuudi v22rtus.
if [ -z $SHARE ]
then
    SHARE=$GRUPP
fi

#Otsime olemasolevast samba confi failist olemasolevat konfi.
grep -Fxn [$SHARE] /etc/samba/smb.conf

if [ $? -ne 0 ]
then
	echo "Sellist sharet ei leitud, t2iustame konfi faili."
	tee -a /etc/samba/smb.conf <<-EOF
	[$SHARE]
	  comment=Jagatud kaust $GRUPP
	  path=$KAUST
	  writable=yes
	  valid users=@$GRUPP
	  browsable=yes
	  create mask=0664
	  directory mask=0775

	EOF
else
	RIDA=$(grep -Fxn [$SHARE] /etc/samba/smb.conf | cut -d : -f 1) 	
	echo "Sellise konfiga share on juba olemas"
	filename="/etc/samba/smb.conf"

	while read -r line
	do
    		name="$line"
    		echo "$name"
	done < <(tail -n "+$RIDA" "$filename")
fi

