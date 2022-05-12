#!/usr/bin/perl
use v5.20;
use strict;

use Device::SerialPort;

my ($device_port, $addr) = @ARGV;
my @output;
my $port_speed  = 9600;

#
#Чтение накопленной АКТИВНОЙ И РЕАКТИВНОЙ ЭНЕРГИИ
#
sub getW {				#Чтение накопленной энергии
	my ($crc, $cmd, $response, @energy);
	
	# Функция 18 - по первому тарифу 
	# Функция 19 - по второму тарифу 
	# Функция 1A - по третьему тарифу 
	# Функция 1B - по четвертому тарифу 
	
	$cmd = "#";			#marker
	$cmd .= $_[0];		#address
	$cmd .="00000";		#password	
	$cmd .= $_[2];		#function
	$cmd .= &crc($cmd);		#CRC

	#ay "CMD: $cmd";
	$_[1]->write("$cmd\r");
	$response = $_[1]->read(255);
	
	$crc = &crc(substr($response, 0, 22));

	if($crc eq substr($response, 22, 2)){
		push(@energy, (substr ($response, 6, 8))/1000);  #active
		push(@energy, substr ($response, 14, 8)/1000); 	#reactive
		
		return @energy;
	} else{
		say "CRC ERROR";
		exit(0);
	}
}

#
#Чтение текущих АКТИВНЫХ И РЕАКТИВНЫХ МОЩНОСТЕЙ
#

sub getPQ{

	my ($crc, $cmd, $response, @power);
	
	$cmd = "#";			#marker
	$cmd .= $_[0];		#address
	$cmd .="00000";		#password	
	$cmd .= "36";		#function
	$cmd .= &crc($cmd);		#CRC

	#say "CMD: $cmd";
	$_[1]->write("$cmd\r");
	$response = $_[1]->read(255);
	
	$crc = &crc(substr($response, 0, 52));
	
	if($crc eq substr($response, 52, 2)){
		push(@power, substr ($response, 6, 5)/1000);  	#active sum
		push(@power, substr ($response, 29, 5)/1000); 	#reactive sum
		
		push(@power, substr ($response, 12, 5)/1000);	#active a
		push(@power, substr ($response, 35, 5)/1000); 	#reactive a
		
		push(@power, substr ($response, 18, 5)/1000);  	#active b
		push(@power, substr ($response, 41, 5)/1000); 	#reactive b
		
		push(@power, substr ($response, 24, 5)/1000);   #active c
		push(@power, substr ($response, 47, 5)/1000);  	#reactive c
		
		return @power;
	} else{
		say "CRC ERROR";
		exit(0);
	}
}

#
#Чтение текущих значений ТОКА И НАПРЯЖЕНИЯ
#
sub getIU{

	my ($crc, $cmd, $response, @iu);
	
	$cmd = "#";			#marker
	$cmd .= $_[0];		#address
	$cmd .="00000";		#password	
	$cmd .= "37";		#function
	$cmd .= &crc($cmd);		#CRC

	#say "CMD: $cmd";
	$_[1]->write("$cmd\r");
	$response = $_[1]->read(255);
	
	$crc = &crc(substr($response, 0, 42));
	
	if($crc eq substr($response, 42, 2)){
		push(@iu, substr ($response, 6, 6)/1000);		#I a
		push(@iu, substr ($response, 24, 6)/1000); 		#U a
		
		push(@iu, substr ($response, 12, 6)/1000);  	#I b
		push(@iu, substr ($response, 30, 6)/1000); 		#U b
		
		push(@iu, substr ($response, 18, 6)/1000);   	#I c
		push(@iu, substr ($response, 36, 6)/1000);  	#U c
		
		return @iu;
	} else{
		say "CRC ERROR";
		exit(0);
	}
}

sub crc{
	my @string_as_array = split( '', $_[0] );
	my ($arg, $sum, $binvalue, $binvalue_cut, $low_bin, $high_bin, $high_hex, $low_hex);
	
	foreach $arg (@string_as_array){
		$sum += ord($arg);
    }
	
	$binvalue = sprintf("%b", $sum);
	$binvalue_cut = substr($binvalue, -8);
	
	$low_bin = substr($binvalue_cut, -4);
	$high_bin = substr($binvalue_cut, 0, 4);
	
	$high_hex = uc(sprintf("%x", oct( "0b$high_bin" ) ));
	$low_hex = uc(sprintf("%x", oct( "0b$low_bin" ) ));

	return "$high_hex$low_hex";
}

if (not defined $addr){
	die "Need address\n";
}

my $port = Device::SerialPort->new($device_port);

$port->baudrate($port_speed); 
$port->read_char_time(1);
#$port->read_const_time(10);
$port->handshake("none"); 

$port->databits(8);
$port->parity("none");
$port->stopbits(1);
$port->lookclear;

push (@output, &getW($addr, $port, "18"));		#Тариф 1
push (@output, &getW($addr, $port, "19"));		#Тариф 2
push (@output, &getW($addr, $port, "1A"));		#Тариф 3
push (@output, &getW($addr, $port, "1B"));		#Тариф 4

my $sum_p = @output[0]+@output[2]+@output[4]+@output[6];
my $sum_s = @output[1]+@output[3]+@output[5]+@output[7];

push (@output, getPQ($addr, $port));
push (@output, getIU($addr, $port));

say "{\"U\":{\"p1\":@output[17],\"p2\":@output[19],\"p3\":@output[21]},\"I\":{\"p1\":@output[16],\"p2\":@output[18],\"p3\":@output[20]},\"P\":{\"p1\":@output[0],\"p2\":@output[2],\"p3\":@output[4],\"p4\":@output[6],\"sum\":$sum_p},\"S\":{\"p1\":@output[1],\"p2\":@output[3],\"p3\":@output[5],\"p4\":@output[7],\"sum\":$sum_s}}";

#print join(" ", @output);

$port->close;
#say "Response: $response";
