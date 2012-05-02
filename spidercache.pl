#!/usr/bin/perl
#
# spidercache.pl
#
# TBD
#
# http://github.com/djinns/SpiderCache
#
# Copyright (C) 2011 djinns@chninkel.net
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#------------------------------------------------
# LIBS
use warnings;
use strict;
use LWP::UserAgent;
use HTML::Parse;
use Getopt::Long;
use URI;
 
#------------------------------------------------
# options
my $o_url;
my $o_matchurl;

#------------------------------------------------
# parameters
my $version="0.1";
my $useragent="SpiderCache - version ". $version ." - https://github.com/djinns/SpiderCache";
my $timeout=60;
my $validcode="(200|304)";
my $hit=0;
my $miss=0;
my $total=0;

#------------------------------------------------
# functions
sub check_options {
	Getopt::Long::Configure ("bundling");
	GetOptions(
	   'u:s'   => \$o_url,          'url:s'             => \$o_url,
    );

    if (!defined($o_url)) {
		die('invalid options !');
    }
}

#------------------------------------------------
# Main
check_options();

my $ua = new LWP::UserAgent;

my $uri = URI->new($o_url);

print "\nSpider Cache - version $version\n\n";

print "\tMiss URL:\n\n";

$ua->agent($useragent);
$ua->timeout($timeout);
 
my $request = HTTP::Request->new('GET');

$request->url($o_url);
 
my $response = $ua->request($request);

$total++; 
 
if($response->code =~ /$validcode/) {

	if(defined($response->header('X-Cache'))) { 

		if($response->header('X-Cache') =~ /HIT/) {
			$hit++;
		}
	} else {
		$miss++;
		print "\t\t$o_url (".$response->code.")\n";
	}
 
	my $body =  $response->content;
 
	my $parsed_html = HTML::Parse::parse_html($body);

	for (@{ $parsed_html->extract_links(qw(head body img script style)) }) {
 
	    my ($link) = @$_;

		$total++;

		my $ua2 = new LWP::UserAgent;

		$ua2->agent('Mozilla/5.5 (compatible; MSIE 5.5; Windows NT 5.1)');
		$ua2->timeout(15);

		my $request2 = HTTP::Request->new('GET');

		my $url2;

		if($link =~ /^\//) {
			$url2="http://".$uri->host."".$link;
		} elsif ($link =~ /^http/) {
			$url2=$link;
		} elsif ($link !~ /^\//) {
			$url2="$o_url/$link";
		} else {
			die('link ?!');
		}

		if($debug) { print "-> url2: $url2 [$link]\n"; }

		$request2->url($url2);
	
		my $response2 = $ua2->request($request2);

		if(defined($response2->header('X-Cache'))) {
			if($response2->header('X-Cache') =~ /HIT/) {
				$hit++;
			}
		} else {
			$miss++;
			print "\t\t$url2 (".$response2->code.")\n";
		}
	}

	print "\n\tCache stats:\n";
	print "\t\tRequests : ". $total ."\n";
	print "\t\tHit      : ". $hit ."\n";
	print "\t\tMiss     : ". $miss ."\n\n";

	printf("\t\tHit rate : %.2f%%\n\n", ($hit*100)/$total);

	} else {

		print "bad response code: $o_url : ". $response->code ."\n\n";
}
