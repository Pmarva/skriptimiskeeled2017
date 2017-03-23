#!/bin/bash
#
#
#  Author: Marvin Martinson
#  Date: 2017.03.18
#
#  Bind 9 must be installed and default zone directory is /etc/bind/zones/
#
#  File format is space separated.
#  	 
#
##########################################################################


bind9WrDir="/etc/bind/"
zoneWrDir="/etc/bind/zones/" #Change me, if needed
editedFiles=()

function getReverseip {
        ip=$1
        echo $(echo $ip | awk 'BEGIN { FS = "." } ; { print $3"."$2"."$1" "$4;}')
}

function createForwardZone {
	echo "Domain name for this domain?"
	read domainName
	echo "Primary DNS name for this domin/zone machine, FQDN? 'ns1.local.lan'"
	read DNSServerName
	echo "IP address of previously entered DNS server, A record"
	read ip
	echo "administrative contact email address for this domain, example 'user.local.lan'?"
	read email
	
	tee -a /etc/bind/named.conf.local <<-EOF
	zone "$domainName" IN {
	  type master;
	  file "${zoneWrDir}db.${domainName}";
	};

	EOF

	file="${zoneWrDir}db.${domainName}"

	cp /etc/bind/db.local $file;
	sed -i "s/root.localhost./${email}/g" $file
	sed -i "s/localhost./${DNSServerName}/g" $file
	sed -ie '12,14d' $file

	tee -a $file <<-EOF
	; Name server - NS records
	                IN	NS	$DNSServerName
	
	; Name server - A records
	$DNSServerName	IN	A	$ip
	
	EOF

	if [ $? -eq 0 ]
	then
		echo "Successfully created zone file for $domainName $file"

		if [ $(containsFile $file) == "False" ]
		then
			editedFiles+=($file)
		fi

	fi
}

function incrementSerial {
	file=$1
	line=$(grep -n Serial $file)
	value=$(echo $line | awk '{value=$2+1}END{print value}')
	lineNumber=$(echo $line | cut -c1)
	sed -i "${lineNumber}s/[0-9]/${value}/g" $file
}

function createReverseZone {


	if [ $# -eq 2 ]
	then
		#IP for zone
		ip=$1
		#DNS server this zone FQDN
		dns=$2
	fi

	if [ $# -eq 1 ]
	then
		ip=$1
		echo "Sisestan DNS selle domeeni jaoks FQDN ns1.local.lan."
		read dnsFQDN
		dns=$dnsFQDN

	fi

	if [ $# -eq 0 ]
	then
		echo "Ei ole m22ratud piisavalt andemid."
		echo "Sisestage IP selle reverse domeeni jaoks. Reverse tsoon tehakse /24"
		read ipAddress
		echo "sisestage DNS masina FQDN, mis tegeleb selle domeeniga"
		read dnsFQDN
		ip=$ipAddress
		dns=$dnsFQDN
	fi


	reverseIP=$(echo $ip | awk 'BEGIN { FS = "." } ; { print $3"."$2"."$1}')

	tee -a /etc/bind/named.conf.local <<-EOF
	zone "${reverseIP}.in-addr.arpa" IN {
	  type master;
	  file "${zoneWrDir}db.${reverseIP}";
	};
	EOF

	file="${zoneWrDir}db.${reverseIP}"
	cp /etc/bind/db.127 $file;

	sed -ie '12,13d' $file

	tee -a $file <<-EOF
	; Name server - NS records
	                IN      NS      $dns

	EOF

	if [ $? -eq 0 ]
	then
		echo "Successfully created reverse zone for $reverseIP at file:$file"
		if [ $(containsFile $file) == "False" ]
		then
			editedFiles+=($file)
		fi

	fi
}

function addEntry {
	hostName=$1
	zoneName=$2
	type=$3
	ip=$4
	echo $hostName $zoneName $type $ip

	if [ $type == "A" ]
	then
		file="${zoneWrDir}db.${zoneName}"
		tee -a "$file" <<-EOF
		$hostName		IN      A       $ip
		EOF

		if [ $? -eq 0 ]
		then
			echo "Succefully added A record $hostname to $zoneName with ip $ip"
			if [ $(containsFile $file) == "False" ]
			then
				editedFiles+=($file)
			fi
		fi

	elif [ $type == "PTR" ]
	then
		reverseIP=$(echo $ip | awk 'BEGIN { FS = "." } ; { print $3"."$2"."$1}')
		ipEnd=$(echo $ip | cut -d "." -f 4)
		file="${zoneWrDir}db.${reverseIP}"
		tee -a "$file" <<-EOF
		$ipEnd		IN      PTR       $hostName.$zoneName.
		EOF
		
		if [ $? -eq 0 ]
		then
			echo "Reverse record added succefully"
			if [ $(containsFile $file) == "False" ]
			then
				editedFiles+=($file)
			fi
		fi
	fi
}

function userChoice {
	echo $#
	file="${zoneWrDir}db.$6"
	lineNumber=$(echo $1 | cut -d ":" -f 1)
	hostNameFromFile=$(echo $1 | cut -d ":" -f 2 | sed "s/ //g")
	reverseIP=($(getReverseip $4))
	reverseFile="${zoneWrDir}db.${reverseIP[0]}"
	newreverseIP=($(getReverseip $8))

	echo -e "Mida soovite teha? \n 1) asenda IP \n 2) asenda hostname \n  3) 2ra tee midagi."
	read userChoice
	
	case "$userChoice" in
		1)
			sed -i "${lineNumber}s/$4/$8/g" $file
			
			if [ $? -eq 0 ]
			then
				echo "Ip aadress $4 asendati edukalt ip aadressiga $8"
				if [ $(containsFile $file) == "False" ]
				then
					editedFiles+=($file)
				fi
			fi
			echo "Kontrolli PTR kirje olemasolu"
			

			if [ ! -f $reverseFile ]
			then
				"Echo reverse faili ei leitud, loome faili"
				createReverseZone $4
			fi

			if [ -f $reverseFile ]
			then
				$(grep -w ${reverseIP[1]} $reverseFile)
				if [ $? -eq 0 ]
				then
					sed -i "s/\b${reverseIP[1]}\b/${newreverseIP[1]}/g" $reverseFile

					if [ $? -eq 0 ]
					then
						echo "PTR kirje uuendati edukalt"
						if [ $(containsFile $file) == "False" ]
						then
							editedFiles+=($file)
						fi
					fi
				else
					addEntry $hostNameFromFile $6 "PTR" $8
				fi
			fi
		;;
		2)
			sed -i "${lineNumber}s/${hostNameFromFile}/$5/g" $file
			
			if [ $? -eq 0 ]
			then
				echo "Hostname $hostNameFromFile replaced succefully with $5"
			fi


			echo "Kontrollime PTR kirje olemasolu"

			if [ -f $reverseFile ]
			then
				echo $hostNameFromFile
				line=$(grep -n "${hostNameFromFile}." $reverseFile)
				lineNumber=$(echo $line | cut -d ":" -f 1)
				
				if [ $? -eq 0 ]
				then
					sed -i "${lineNumber}s/${hostNameFromFile}./${5}./g" $reverseFile
					if [ $? -eq 0 ]
					then
						echo "PTR kirje uuendati edukalt"
						if [ $(containsFile $file) == "False" ]
						then
							editedFiles+=($file)
						fi
					fi
				fi
			fi
			;;
		3)
			#line="$5	IN	$7	$8;"
			#oldLine=awk "NR==45" $file
			#sed -i "${lineNumber}s/.*/${line}/g" $file
			#if [ $? -eq 0 ]
			#then
			#		echo "Rea asendamine 6nnestus edukalt"
			#fi
			echo "TEST"
			;;
	esac
}


function controllInput {
	HOSTNAME=$1
        ZONENAME=$2
        TYPE=$3
        IP=$4

	case "$TYPE" in
		"A")
			file="${zoneWrDir}db.${ZONENAME}"
			if [ -f $file ]
			then
				leitudRidaIP=$(grep -n $IP $file)
				IPstate=$?
				leitudRidaHostname=$(grep -n $HOSTNAME $file)
				Hostnamestate=$?

				#echo $leitudRidaIP
				#echo $leitudRidaHostname
				local reverseIP=($(getReverseip $IP))
				reverseFile="${zoneWrDir}db.${reverseIP[0]}"

				if [ ! -f $reverseFile ]
				then
					echo "No reverse file for this ip subnet, creating one"
					createReverseZone $IP
				fi

				if [[ ( "$leitudRidaIP" == "$leitudRidaHostname" ) && ( $IPstate -eq 0 && $Hostnamestate -eq 0 ) ]]
				then
					echo "Selline kirje on juba olemas"
					echo $leitudRidaIP

				elif [[ $Hostnamestate -eq 0 && $IPstate -ne 0 ]]
				then
					echo "Sellise hostnamega kirje leiti aga tal on teine IP aadress"
					echo $leitudRidaHostname

					userChoice $leitudRidaHostname "$@"
					#read userChoise
					
				elif [[ $Hostnamestate -ne 0 && $IPstate -eq 0 ]]
				then
					echo "Sellise ip aadressiga kirje leiti, tal on teine hostname"
					echo $leitudRidaIP
					userChoice $leitudRidaIP "$@"
				else
					echo "Selliste andmetega kirjet ei leitud, lisame kirje nii A kui PTR"
					addEntry $HOSTNAME $ZONENAME $TYPE $IP
					addEntry $HOSTNAME $ZONENAME "PTR" $IP
				fi
			else
				echo "Ei leitud vastavat tsooni faili, loome faili"
				createForwardZone
				controllInput "$@"
			fi
			;;
		"PTR")
			echo "test"
			;;
		*)
			echo "Unkown type"
			exit 1
	esac
}




#createForwardZone
#incrementSerial
#createReverseZone
#addEntry mail local.lan PTR 192.168.122.231

function containsFile {
	if [[ ${editedFiles[*]} =~ $1 ]]
	then
		echo "True"
	else
		echo "False"
	fi
}

#result=$(containsFile "testqw")

if [ $UID -ne 0 ]
then
	echo "Start $(basename $0) with root"
	exit 1
fi

if [ ! -d $zoneWrDir ]
then
	echo "zones directory does not exists, creating it at '/etc/bind/zones'? [y/n]"

	read confirm

	if [ $confirm=="y" ]
	then
		mkdir -p $zoneWrDir

	else
		echo "Enter new location for zone locations"
		read newLocation

		if [ ! -d $newLocation ]
		then
			mkdir -p $newLocation
		fi
	fi
fi


#
#  INPUT FROM FILE, FILE FORMAT:"hostname domainz/oneName type ip address" 
#

if [ $# -eq 1 ]
then
	filename=$1
	if [ -f $filename ]
	then
		while read -r line
		do
			entry="$line"
			controllInput $entry
		done < "$filename"
		echo "FAILI TOOTLEMINE SAI LABI"

		echo "Suurendame serial numbreid."
		for i in "${editedFiles[@]}"
		do
		   :
		   incrementSerial $i
		done

		echo "Teeme bind9 teenusele restardi"
		$(service bind9 restart)
	else
		echo "Etteantud faili ei leitud"
	fi

fi

if [ $# -eq 4 ]
then
	HOSTNAME=$1
	ZONENAME=$2
	TYPE=$3
	IP=$4
	controllInput $HOSTNAME $ZONENAME $TYPE $IP


	echo "Suurendame serial numbreid."
	for i in "${editedFiles[@]}"
	do
		:
		incrementSerial $i
		done

	echo "Teeme bind9 teenusele restardi"
	$(service bind9 restart)
fi

if [ $# -eq 0 ]
then
	echo "Use script $(basename $0) HOSTNAME ZONENAME TYPE IP or $(basename $0) FILE"
	exit 1
fi
