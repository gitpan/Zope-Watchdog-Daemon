#!/usr/bin/perl

# ZWatchdog.pl -- A perl-script/-daemon at looks at Zope's Memory usage and restarts it if too big.
# Copyright (c) Oliver Pitzeier, January 2002
#                 o.pitzeier@uptime.at
# Licese: Free Distributable
#
# This script was written for our customers.
#
# Changes are welcome, but please inform me about those changes!

# Thing we use int this script.
use strict;
use warnings;
use POSIX qw(setsid);
use Getopt::Long;

# Define some values... Those variables are use in the script as well!
my $PROGNAME = "Zope Watchdog Daemon";
my $VERSION  = 2.0;
my $AUTHOR   = "Oliver Pitzeier";

# Define the default options
my $zope = "/usr/local/zope";
my $limit = 450000;
my $daemon;
my $help;
my $interval = 60;
my $restartcommand = "/etc/rc.d/init.d/zope restart";

# Get the options using Getopt::Long. More information see: "perldoc Getopt::Long"
my $result = GetOptions("zope|z=s"           => \$zope,
                        "limit|l=i"          => \$limit,
                        "interval|n=i"       => \$interval,
                        "restartcommand|c=s" => \$restartcommand,
                        "help|?|h"           => \$help,
                        "daemon|D|d"         => \$daemon);

# This is the main program loop. Here are the system-calls the script uses
# to find out the current memory usage of zope
sub do_watch {
    my $watch_limit=shift;
    my $watch_zopedir=shift;
    my $commandline="ps auxw | grep python | awk -v limit=$watch_limit -v zopedir=$watch_zopedir '{ if (\$5 > limit) { print \$2; exit 0; } }'";
    open(my $pid, "$commandline |");
    if(<$pid>) {
        system("logger Zope restart because of too much memory: greater than $limit");
        system("$restartcommand");
    };
    close($pid);
}

if($help) {
    print "$PROGNAME - Version $VERSION - by $AUTHOR\n";
    print "\nusage: watchdog [--zope|-z <path/to/zope>] [--limit|-l <memory-limit-KB>]\n";
    print "         [--interval|-n <seconds>] [--restartcommand <command-line-for-restart>]\n";
    print "         [--daemon|-d|-D] [--help|-h|-?]\n\n";
    print "--zope|-z:           This option defaults to: $zope\n";
    print "--limit|-l:          This option defaults to: $limit KB\n";
    print "--interval|-l:       This option defaults to: $interval seconds\n";
    print "--restartcommand|-c: This option defaults to: $restartcommand\n";
    print "--daemon|-d|-D:      This options switch the programm to deamon mode: Default: off\n";
    print "--help|-h|-?:        I guess you already know it, if you read this here! :o)\n";
    exit 0
}

if($daemon) {
    defined(my $pid = fork)    or die "Can't fork: $!";
    exit if $pid;
    setsid                     or die "Can't start a new session: $!";

    system("touch /var/run/watchdog.run");
    while(1) {
        sleep $interval;
        &do_watch($limit, $zope);
    }
} else {
    &do_watch($limit, $zope);
}

=head1 NAME

ZWatchdog.pl - Memory-Watchdog for Zope

=head1 SYNOPSYS

See ./ZWatchdog.pl --help

=head1 Example

    ./ZWatchdog.pl --zope /opt/zope --limit 200000 -n 1 -D

=head1 DESCRIPTION

A perl-script/-daemon at looks at Zope's Memory usage and restarts it if too big.
Zope can be obtained at http://www.zope.org/
This script can be obtained at http://vivi.uptime.at/~oliver/PAUSE/ or at CPAN.

=head1 LICENSE

Free Distributable

=head1 AUTHOR

Oliver Pitzeier, o.pitzeier@uptime.at

=cut
