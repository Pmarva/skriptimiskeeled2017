#!/bin/bash

failid=$(sudo find /etc -name "*.conf");

for file in $failid
do
	md5=($(md5sum $failid))
	echo -e $file"\t"${md5[0]} >> "/tmp/md5.log" 
done


