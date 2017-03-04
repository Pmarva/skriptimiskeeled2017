#!/bin/bash

echo "Sisestage kasutaja kelle m2lukasutust tahate j2lgida";
read kasutaja
 
memory=($(ps aux | grep $kasutaja | awk '{sumVSZ+=$5; sumRSS+=$6}END{print sumVSZ" "sumRSS;}'));
vsz=$(numfmt --from-unit=1024 --to=iec ${memory[0]});
rss=$(numfmt --from-unit=1024 --to=iec ${memory[1]});  

echo "Kasutaja " $kasutaja "vsz " $vsz " ja rss on " $rss;
