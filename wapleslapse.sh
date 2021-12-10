#!/bin/bash
DATE=`date`
DATEFILE=`date -d "$DATE" +%Y%m%d-%H`
DATEDIR=`date -d "$DATE" +%Y/%m`
TODAYSMOVIE=`date -d "$DATE" +%Y-%m`
WAPLESHOME=/var/www/html/waples_mining
SOURCEIMAGE=satimg_resized.jpg
TLDIR=$WAPLESHOME/timelapse
mkdir -p $TLDIR/$DATEDIR
cp $WAPLESHOME/$SOURCEIMAGE $TLDIR/$DATEDIR/$DATEFILE.jpg

cd $TLDIR
for f in 2???/??; do
	MOVIEFILE=${f:0:4}-${f:5:2}
	echo $f: $MOVIEFILE
	if [ "$MOVIEFILE" = "$TODAYSMOVIE" -o ! -f movies/$MOVIEFILE.mp4 ]; then
		cat $f/*.jpg | ffmpeg -f mjpeg -i - -qscale 25 -y -vcodec mpeg4 movies/$MOVIEFILE.mp4
	fi
done
