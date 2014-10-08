#!/usr/bin/perl
#  $Id: blackHole.pm 41 2014-06-12 14:20:42Z zhecho $
#
#  $LastChangedRevision: 12 $
# blackHole plugin for NfSen
# Name of the plugin
package blackHole;
use strict;
use NfProfile;
use NfConf;
#
# The plugin may send any messages to syslog
# Do not initialize syslog, as this is done by 
# the main process nfsen-run
use Sys::Syslog;
  

our %cmd_lookup = (
	#'try'	=> \&RunProc,
	#'manipulate_prefixes'	=> \&RunProc_man_bhp,
	'list_black_hole_prefixes'	=> \&RunProc_list_bhp,
	#'set_black_hole_prefixes'	=> \&RunProc_set_bhp,
	#'del_black_hole_prefixes'	=> \&RunProc_del_bhp,
);

# This string identifies the plugin as a version 1.0.0 plugin. 
our $VERSION = 100;
my $EODATA 	= ".\n";
my ( $nfdump, $PROFILEDIR );
#
# Define a nice filter: 
# We like to see flows containing more than 500000 packets
my $nf_filter = 'packets > 500000';

sub RunProc_list_bhp {
	my $epoc = time();
	my $logtime = localtime();
	my $bh_file = "/usr/local/var/nfsen/blackhole-pref.td2";
   	my $log_file = "/usr/local/var/nfsen/blackHole.plugin.log";	
	open LOG , ">>", "$log_file", or die $!;

	my $socket  = shift;	# scalar
	my $opts    = shift;	# reference to a hash
	# error checking example
	my $action = $$opts{'action'};
	my $prefix = $$opts{'prefix'};
	print LOG "[$logtime] [blackHole] frontend args: prefix $prefix action: $action  \r\n";
	if ( !exists($$opts{'prefix'}) and !exists($$opts{'action'})) {
		Nfcomm::socket_send_error($socket, "Missing or invalid values");
		return ;
	}
	# retrieve values passed by frontend

	# Prepare answer
	my %args;
	my $row = "0";
	if ( $action eq "add") {
		open IN, '>>', $bh_file or die;
	                # roll TABLE_DUMP2|1398256659|B|10.113.0.6||5.5.5.5/31||IGP|10.113.0.5|100||65535:9999|0|0|
			print IN "TABLE_DUMP2|$epoc|B|10.113.0.6||$$opts{'prefix'}\/32||IGP|10.113.0.5|100||65535:9999|0|0|\n";
		close IN;
		print LOG "[$logtime] [blackHole]  adding prefix: $prefix to file: $bh_file\r\n";

	} elsif ( $action eq "list") {
		print LOG "[$logtime] [blackHole] list table: $bh_file\r\n";
	
	} elsif ($action eq "del") {
		open IN, '<', $bh_file or die;
		my @contents = <IN>;
		close IN;
		
		open OUT, '>', $bh_file or die;
		foreach my $LINE (@contents) { 
	                chomp $_;
	                # roll TABLE_DUMP2|1398256659|B|10.113.0.6||5.5.5.5/31||IGP|10.113.0.5|100||65535:9999|0|0|
	                my ($tf,$ut,$proto,$neighbor,$neznam,$prefix,$neznam1,$origin,$next_hop,$localpref,$neznam2,$community,$n3,$n4) = split (/\|/, $_);
		        print OUT $LINE unless ( $LINE =~ m/$$opts{'prefix'}/ );
	                push(@{$args{$row}}, "$ut,$prefix,$community,$next_hop,$localpref")  unless ( $LINE =~ m/$$opts{'prefix'}/ ) ;
		}   
		close OUT;
		print LOG "[$logtime] [blackHole] delete prefix: $prefix from file: $bh_file\r\n";
	
	} else {
		print LOG "[$logtime] [blackHole] ERROR 12\r\n";
	}



	open BHF, "<", "$bh_file", or die $!;
        while (<BHF>) {
                chomp $_;
	            # roll TABLE_DUMP2|1398256659|B|10.113.0.6||5.5.5.5/31||IGP|10.113.0.5|100||65535:9999|0|0|
                my ($tf,$ut,$proto,$neighbor,$neznam,$prefix,$neznam1,$origin,$next_hop,$localpref,$neznam2,$community,$n3,$n4) = split (/\|/, $_);
                # $args{'tf'} = $tf;
                # $args{'prefix'} = $prefix;
                # $args{'community'} = $community;

                push(@{$args{$row}}, "$ut,$prefix,$community,$next_hop,$localpref");
                #print "Roll: $row --  @{$args{$row}} \n";
                $row++;
        }
	close(BHF);
	
	Nfcomm::socket_send_ok($socket, \%args);
	close(LOG);
}
#
#
# Periodic data processing function
#	input:	hash reference including the items:
#			'profile'		profile name
#			'profilegroup'	profile group
#			'timeslot' 		time of slot to process: Format yyyymmddHHMM e.g. 200503031200
sub run {
	my $argref 		 = shift;
	my $profile 	 = $$argref{'profile'};
	my $profilegroup = $$argref{'profilegroup'};
	my $timeslot 	 = $$argref{'timeslot'};

	syslog('debug', "blackHole run: Profilegroup: $profilegroup, Profile: $profile, Time: $timeslot");

	my %profileinfo     = NfProfile::ReadProfile($profile, $profilegroup);
	my $profilepath 	= NfProfile::ProfilePath($profile, $profilegroup);
	my $all_sources		= join ':', keys %{$profileinfo{'channel'}};
	my $netflow_sources = "$PROFILEDIR/$profilepath/$all_sources";

	syslog('debug', "blackHole args: '$netflow_sources'");

} # End of run

#
# Alert condition function.
# if defined it will be automatically listed as available plugin, when defining an alert.
# Called after flow filter is applied. Resulting flows stored in $alertflows file
# Should return 0 or 1 if condition is met or not
sub alert_condition {
	my $argref 		 = shift;

	my $alert 	   = $$argref{'alert'};
	my $alertflows = $$argref{'alertfile'};
	my $timeslot   = $$argref{'timeslot'};

	syslog('info', "Alert condition function called: alert: $alert, alertfile: $alertflows, timeslot: $timeslot");

	# add your code here

	return 1;
}

#
# Alert action function.
# if defined it will be automatically listed as available plugin, when defining an alert.
# Called when the trigger of an alert fires.
# Return value ignored
sub alert_action {
	my $argref 	 = shift;

	my $alert 	   = $$argref{'alert'};
	my $timeslot   = $$argref{'timeslot'};

	syslog('info', "Alert action function called: alert: $alert, timeslot: $timeslot");

	return 1;
}

#
# The Init function is called when the plugin is loaded. It's purpose is to give the plugin 
# the possibility to initialize itself. The plugin should return 1 for success or 0 for 
# failure. If the plugin fails to initialize, it's disabled and not used. Therefore, if
# you want to temporarily disable your plugin return 0 when Init is called.
#
sub Init {
	syslog("info", "blackHole: Init");

	# Init some vars
	$nfdump  = "$NfConf::PREFIX/nfdump";
	$PROFILEDIR = "$NfConf::PROFILEDATADIR";

	return 1;
}

#
# The Cleanup function is called, when nfsend terminates. It's purpose is to give the
# plugin the possibility to cleanup itself. It's return value is discard.
sub Cleanup {
	syslog("info", "blackHole Cleanup");
	# not used here
}

1;
