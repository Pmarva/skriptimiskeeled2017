#!/bin/bash
#
#
#  Author: Marvin Martinson
#  Date: 2017.03.18
#
#  Bind 9 must be installed and default zone directory is /etc/bind/zones/ 
#
##########################################################################


bind9WrDir="/etc/bind/"
zoneWrDir="/etc/bind/zones/" #Change me, if needed


function getReverseip {
        ip=$1
        echo reverseip=$(echo $ip | awk 'BEGIN { FS = "." } ; { print $3"."$2"."$1" "$4}')
}

function createForwardZone {
	echo "Domain name for this domain?"
	read domainName
	echo "Primary DNS name for this domin/zone machine, FQDN? 'ns1.local.lan'"
	read DNSServerName
	echo "IP address of previously entered DNS server, A record"
	read IP
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
	$DNSServerName	IN	A	$IP
	
	EOF
}

function incrementSerial {
	line=$(grep -n Serial /etc/bind/zones/db.local.lan)
	value=$(echo $line | awk '{value=$2+1}END{print value}')
	lineNumber=$(echo $line | cut -c1)
	sed -i "${lineNumber}s/[0-9]/${value}/g" /etc/bind/zones/db.local.lan
}

function createReverseZone {
	#IP for zone
	ip="172.16.4.10"
	#DNS server this zone FQDN
	dns="ns1.local.lan."

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
}

function addEntry {
	hostName=$1
	zoneName=$2
	type=$3
	ip=$4
	echo $hostName $zoneName $type $ip

	if [ $type == "A" ]
	then
		tee -a "${zoneWrDir}db.${zoneName}" <<-EOF
		$hostName		IN      A       $ip
		EOF

		if [ $? -eq 0 ]
		then
			echo "Succefully added A record $hostname to $zoneName with ip $ip"
		fi

	elif [ $type == "PTR" ]
	then
		reverseIP=$(echo $ip | awk 'BEGIN { FS = "." } ; { print $3"."$2"."$1}')
		ipEnd=$(echo $ip | cut -d "." -f 4)

		tee -a "${zoneWrDir}db.${reverseIP}" <<-EOF
		$ipEnd		IN      PTR       $hostName.$zoneName.
		EOF
		
		if [ $? -eq 0 ]
		then
			echo "Reverse record added succefully"
		fi
	fi
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
				leitudRidaHostname=$(grep -n $HOSTNAME $file)
				echo $leitudRidaIP
				echo $leitudRidaHostname
 
				if [ "$leitudRidaIP" == "$leitudRidaHostname" ]
				then
					echo "Selline kirje on juba olemas"
				fi
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


if [ $# -eq 1 ]
then
	parseFile #TODO

fi

if [ $# -eq 4 ]
then
	HOSTNAME=$1
	ZONENAME=$2
	TYPE=$3
	IP=$4
	controllInput $HOSTNAME $ZONENAME $TYPE $IP
fi

if [ $# -eq 0 ]
then
	echo "Use script$(basename $0) HOSTNAME ZONENAME TYPE IP or $(basename $0) FILE"
	exit 1
fi
