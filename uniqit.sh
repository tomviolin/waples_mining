#!/bin/bash

cd /var/www/html/waples_mining
grep ^KGRB stationdata.log | uniq  >stnlogs/KGRB.csv
grep ^GLWI stationdata.log | uniq  >stnlogs/GLWI.csv
grep ^45002 stationdata.log | uniq >stnlogs/45002.csv
grep ^45004 stationdata.log | uniq >stnlogs/45004.csv
grep ^45007 stationdata.log | uniq >stnlogs/45007.csv

