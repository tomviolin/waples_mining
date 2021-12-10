#!/usr/bin/perl -w
use strict;
use LWP::Simple;   # for the mirror() function that retrieves web pages
use Time::Local;   # for converting UTC to local time.
use Math::Trig ':radial';    # for rotating stuff
use Math::Trig;

my %STNinfo;

my $station;  # working variable

chdir "/var/www/html/waples_mining";

# **** NOAA Weather Station KGRB ****

# obtain HTML

sub get_noaa_weather {
	my ($stnid,$xcoord, $ycoord,$xoffset) = split(/,/,$_[0]);

	my $STNtempC = 0;
	my $STNwspdMPH = 0;
	my $STNwspdMS = 0;
	my $STNwindD = 0;
	my $STNtempMode = 0;
	my $STNpressHPA = 0;
	my $STNtimeCT = "";

	mirror("http://weather.noaa.gov/weather/current/$stnid.html","$stnid.html");
	open STN, "$stnid.html";


	while (<STN>) {

		# Wind Direction and Speed
		if ($_ =~ /from the [A-Z]+ \(([0-9]+) degrees\) at ([0-9]+) MPH \(([0-9]+) KT\)/ ) {
			$STNwindD = $1;
			$STNwspdMPH = $2;
		# temperature
		} elsif ($_ =~ /Temperature/) {
			$STNtempMode = 1;
		} elsif ($_ =~ /Dew Point/) {
			$STNtempMode = 0;
		} elsif ($_ =~ /-?[0-9]*\.[0-9]* F \((-?[0-9]*\.[0-9]*) C\)/) {
			if ($STNtempMode) {
				$STNtempC = $1;
			}
		# pressure
		} elsif ($_ =~ /[0-9]*\.[0-9]* in\. Hg \(([0-9]*) hPa\)/) {
			$STNpressHPA = $1;
	
		# time of record
		} elsif ($_ =~ /<OPTION> (.* C[SD]T) <OPTION>/) {
			$STNtimeCT = $1;
	
		}
	}

	close STN;

	$STNwspdMS = $STNwspdMPH * 0.44704;

	return {
		"StationID" => $stnid,
		"WindDir" => $STNwindD,
		"WindSpeed" => int($STNwspdMS*100 + .5) / 100,
		"Pressure" => $STNpressHPA,
		"Time" => $STNtimeCT,
		"x" => $xcoord,
		"y" => $ycoord,
		"xoffset" => $xoffset
	};
}


# **** BUOYS ***

sub get_noaa_buoy {
	my ($station,$xcoord,$ycoord, $xoffset) = split(/,/,$_[0]);
	my ($year,$month,$day,$hour,$min,$lyear,$lmonth,$lday,$lhour,$lmin,$lsec,$edate,$ap);

	mirror("http://www.ndbc.noaa.gov/data/5day2/$station"."_5day.txt", "$station.txt");
	open STNTXT, "$station.txt";
	while (<STNTXT>) {
		if ($_ =~ /^(2[0-9][0-9][0-9]) ([0-9][0-9]) ([0-9][0-9]) ([0-9][0-9]) ([0-9][0-9]) ([^ ]+) +([^ ]+) +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +([^ ]+) +/) {
			$year = $1;
			$month = $2 - 1;
			$day = $3;
			$hour = $4;
			$min = $5;
			# print "$station: time=$hour:$min, date=$month/$day/$year\n";
			$edate = timegm(0,$min,$hour,$day,$month,$year);
			$lsec="";
			$lmin="";
			($lsec,$lmin,$lhour,$lday,$lmonth,$lyear) = localtime($edate);
			$lmonth += 1;
			$lyear += 1900;
			$ap = "AM";
			if ($lhour > 12) {
				$lhour -= 12;
				$ap = "PM";
			}
			if ($lhour == 12) {
				$ap = "PM";
			}
			if ($lhour == 0) {
				$lhour = 12;
			}
			return {
				"StationID" => $station,
				"WindDir" => $6,
				"WindSpeed" => $7,
				"Pressure" => $8,
				"Time" => "$lmonth-$lday-$lyear $lhour:$lmin $ap CT",
				"x" => $xcoord,
				"y" => $ycoord,
				"xoffset" => $xoffset
			};
		}
	}
	close STNTXT;
	return {
		"StationID" => $station,
		"WindDir" => "NA",
		"WindSpeed" => "NA",
		"Pressure" => "NA",
		"Time" => "NA",
		"x" => $xcoord,
		"y" => $ycoord,
		"xoffset" => $xoffset
	};
}

# ** LOCAL WEATHER STATION **
sub get_glwi_data {
	my ($year,$month,$day,$hour,$min,$sec,$wspd,$wgspd,$windir,$inhum,$outhum,$intemp,$outtemp,$baro,$rain1,$rain2,$rain3);
	# retrieve parameters
	my ($station,$xcoord,$ycoord,$xoffset) = split(/,/,$_[0]);
	# total cheat -- open local file directly
	open STNCSV, "/home/tomh/weather/weather_2002_04_18/current.csv";
	while (<STNCSV>) {
		($year,$month,$day,$hour,$min,$sec,$wspd,$wgspd,$windir,$inhum,$outhum,$intemp,$outtemp,$baro,$rain1,$rain2,$rain3) =
			split( /,/ );
	}

	close STNCSV;

	my $edate = timegm($sec,$min,$hour,$day,($month-1),$year);
	my ($lsec,$lmin,$lhour,$lday,$lmonth,$lyear) = localtime($edate);
	$lmonth += 1;
	$lyear += 1900;
	my $ap = "AM";
	if ($lhour > 12) {
		$lhour -= 12;
		$ap = "PM";
	}
	if ($lhour == 12) {
		$ap = "PM";
	}
	if ($lhour == 0) {
		$lhour = 12;
	}

	$wspd = $wspd * 0.44704;  # convert mph to m/s
	$baro = $baro * 33.8639;  # mm Hg to hPa

	$wspd = int($wspd * 100 + .5) / 100;
	$baro = int($baro * 10 + .5) / 10;

	return {
		"StationID" => $station,
		"WindDir" => $windir,
		"WindSpeed" => $wspd,
		"Pressure" => $baro,
		"Time" => "$lmonth-$lday-$lyear $lhour:$lmin $ap CT",
		"x" => $xcoord,
		"y" => $ycoord,
		"xoffset" => $xoffset
	};
}

sub get_noaa_data {
	#if ($_[0] =~ /^GLWI,/) {
	#	return get_glwi_data($_[0]);
	if ($_[0] =~ /^[0-9]+,/) {
		return get_noaa_buoy($_[0]);
	} else {
		return get_noaa_weather($_[0]);
	}
}

sub transform_coords {
	my $org_x = shift;
	my $org_y = shift;
	my $rot = shift;
	my $xoffset = shift;
	my $yoffset = shift;

	$rot = deg2rad($rot - 90);

	my ($rho, $theta, $z) = cartesian_to_cylindrical($org_x, $org_y, 0);
	my ($x, $y, $zx) = cylindrical_to_cartesian($rho, $theta + $rot, $z);

	return ($x+$xoffset, $y+$yoffset);
}


sub plot_station_info {
	# returns plot commands to be used by convert -draw option.
	my $plotcmds = "";
	# extract data from arguments
	my $stationID = $_[0]{"StationID"};
	my $xcoord = $_[0]{"x"};
	my $ycoord = $_[0]{"y"};
	my $xoffset = $_[0]{"xoffset"};
	my $windD = $_[0]{"WindDir"};
	my $wspdMS = $_[0]{"WindSpeed"};
	my $pressHPA = $_[0]{"Pressure"};
	my $time = $_[0]{"Time"};
	shift;
	my $offset = shift;
	my $color = shift;

	my $knots;
	$xcoord += $offset;
	$ycoord += $offset;

	if ($wspdMS ne "NA") {
		$knots = $wspdMS * 1.94384449; # convert windspeed from m/s to knots
	} else {
		$knots = 0;
	}

	# plot it
	
	$plotcmds .= "-stroke none -fill $color -font Helvetica -pointsize 10 ";
	
	# mark station location itself
	$plotcmds .= "-draw 'circle " . ($xcoord-1).",".($ycoord-1)." ".($xcoord+1).",".($ycoord+1)."' ";

	# station ID
	my $ofsdown = 0;
	if ($windD ne "NA" and $windD > 100 and $windD < 260) {
		$ofsdown = -30 * cos(deg2rad($windD+10));
	}
	$plotcmds .= "-draw 'text ".($xcoord-22+$xoffset).",".($ycoord+20+$ofsdown)." \"$stationID\"' ";

	if ($time eq "NA") {
		$plotcmds .= "-draw 'text ".($xcoord-22+$xoffset).",".($ycoord+32+$ofsdown)." \"not reporting\"' ";
		return $plotcmds;
	}


	$plotcmds .= "-draw 'text ".($xcoord-22+$xoffset).",".($ycoord+32+$ofsdown)." \"$pressHPA hPa\"' ";
	$plotcmds .= "-draw 'text ".($xcoord-22+$xoffset).",".($ycoord+44+$ofsdown)." \"$wspdMS m/s (".(int($knots*10+.5)/10)."kts) @ $windD°\"' ";
	$plotcmds .= "-draw 'text ".($xcoord-22+$xoffset).",".($ycoord+56+$ofsdown)." \"$time\"' ";

	$knots += 2;  # effectively round to nearest 5 knots

	# wind line
	my (@draw);                       # array to hold graphic primitives
	my $num50s = int($knots / 50);    # calculate number of 50-knot triangles to plot
	$knots = $knots - ($num50s * 50); # place remainder back in $knots
	my $num10s = int($knots / 10);    # calculate number of 10-knot feathers to plot
	$knots = $knots - ($num10s * 10); # place remainder back in $knots
	my $num5s = int($knots / 5);      # calculate number of 5-knot mini-feathers to plot
	$knots = $knots - ($num5s * 5);   # remainder back in $knots
	my $offs;			  # working variable
	my $i;
	my $lref;
	my @drel;
	if (($num50s == 0) and ($num10s == 0) and ($num5s == 0) and ($knots == 0)) {
		# do nothing!
	} else {
		# ok, we have to do something
		# base line
		push @draw, [("line", 0,0,30,0)];
		$offs = 30;
		for $i (1 .. $num50s) {
			push @draw, [("triangle", $offs,0, $offs-4,10, $offs-8,0)];
			$offs -= 9;
		}
		if ($num50s > 0) {
			$offs -= 4;
		}
		for $i (1 .. $num10s) {
			push @draw, [("line", $offs,0, $offs+4, 10)];
			$offs -= 5;
		}
		if ($offs == 30) {
			$offs -= 5;
		}
		for $i (1 .. $num5s) {
			push @draw, [("line", $offs,0, $offs+2, 5)];
			$offs -= 5;
		}

		# apply transformation
		for $i ( 0 .. $#draw ) {
			if ($draw[$i][0] eq "line") {
				($draw[$i][1], $draw[$i][2]) = transform_coords($draw[$i][1], $draw[$i][2], $windD, $xcoord,$ycoord);
				($draw[$i][3], $draw[$i][4]) = transform_coords($draw[$i][3], $draw[$i][4], $windD, $xcoord,$ycoord);
			} elsif ($draw[$i][0] eq "triangle") {
				($draw[$i][1], $draw[$i][2]) = transform_coords($draw[$i][1], $draw[$i][2], $windD, $xcoord,$ycoord);
				($draw[$i][3], $draw[$i][4]) = transform_coords($draw[$i][3], $draw[$i][4], $windD, $xcoord,$ycoord);
				($draw[$i][5], $draw[$i][6]) = transform_coords($draw[$i][5], $draw[$i][6], $windD, $xcoord,$ycoord);
			}
		}
		
		# create the commands
		for $i ( 0 .. $#draw ) {
			if ($draw[$i][0] eq "line") {
				$plotcmds .= "-draw 'line ".$draw[$i][1].",".$draw[$i][2]." ".$draw[$i][3].",".$draw[$i][4]."' ";
			} elsif ($draw[$i][0] eq "triangle") {
				$plotcmds .= "-draw 'polygon ".$draw[$i][1].",".$draw[$i][2]." ".$draw[$i][3].",".$draw[$i][4]." "
						.$draw[$i][5].",".$draw[$i][6]." ".$draw[$i][1].",".$draw[$i][2]."' ";
			}
		}
	}

	return $plotcmds;
}


# obtain the satellite image
mirror("http://satir.wunderground.com/cgi-bin/satBanner?satellite=1&lat=47.911530&lon=-88.147949&width=600&height=600&zoom=4&imagename=finalIR.pnm","satimg.jpg");

# collect data

open STNS, "stations.dat";
while (<STNS>) {
	$station = (split (/,/, $_))[0];
	$STNinfo{$station} = get_noaa_data ($_);
	# print "Set STNinfo{$station}\n";
}
close STNS;

# construct commands to plot info for each station

my $plotcmds;
my %temp;
my $tempr;
$plotcmds = " ";
foreach $station (keys %STNinfo) {
	# print "Accessing STNinfo{$station} 1 black\n";
	$plotcmds .= plot_station_info($STNinfo{$station},1, "black");
	# print "Accessing STNinfo{$station} 0 white\n";
	$plotcmds .= plot_station_info($STNinfo{$station},0, "white");
}

# print $plotcmds . "\n";

# print "convert satimg.jpg -sample 462x621\! -crop +28 $plotcmds satimg_resized.jpg\n";
system("convert satimg.jpg -sample 462x621\! -crop 434x621+28+0  $plotcmds satimg_resized.jpg");

open STNLOG, ">>stationdata.log";
foreach $station (sort(keys %STNinfo)) {
	# print "logging data for $station.\n";
	print STNLOG "$station,".$STNinfo{$station}{"Time"} . ",";
	print STNLOG $STNinfo{$station}{"WindSpeed"}.",";
	print STNLOG $STNinfo{$station}{"WindDir"}.",";
	print STNLOG $STNinfo{$station}{"Pressure"};
	print STNLOG "\n";

}

system "/root/uniqit.sh"
