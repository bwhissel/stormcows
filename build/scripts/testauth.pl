#!/usr/bin/perl

use Digest::MD5 qw(md5_hex);
use JSON::XS;

use REST::Client;
use JSON;

use strict;
use warnings;

my $jo = JSON::XS->new->utf8->pretty(1);

my $tokenfile = "/home/bret/.rtmapitoken";
my $authtoken = '';

my $authserver = 'https://www.rememberthemilk.com';
my $apiserver = 'https://api.rememberthemilk.com';
my $timeout = 30;

my $apclient = REST::Client->new({
    host    => $apiserver,
    timeout => $timeout });

my $authclient = REST::Client->new({
    host    => $authserver,
    timeout => $timeout });

my $jsonresp = '';
my $frob = '';

sub makeauthstr {
    my $href = shift;
    my %parms = %$href;

# StormCows keys, for comparison testing
#    my $rtmapikey = 'e26a18535958e43f44f175f3d4a47a50';
#    my $rtmsecret = '0214bd2dffa0218f';

# Bret Whissel API keys
    my $rtmapikey = '32fd51006d3c7903be7106162ed2d1d6';
    my $rtmsecret = '02f2e7b68509f9aa';

    $parms{'perms'} = 'delete';
    $parms{'api_key'} = "$rtmapikey";
    if (length($authtoken) > 0) {
	$parms{'auth_token'} = $authtoken;
    }
    if (exists($parms{'format'}) && ($parms{'format'} ne 'json')) {
	delete $parms{'format'};
    } else {
	$parms{'format'} = 'json';
    }
	
    my $authstr = "$rtmsecret";
    my $parmstr = '';

    foreach my $k ( sort keys %parms ) {
	$authstr .= $k . $parms{$k};
    }
    $parmstr = join('&', map { "$_=" . $parms{$_} } sort keys %parms);
    $parmstr .= "\&api_sig=" . md5_hex($authstr);

    print "authstr=$authstr;\nparmstr=$parmstr\n\n";

    return $parmstr;
}

sub check_return_error {
    my $restc = shift;

    my $resp = '';
    my $code = $restc->responseCode();
    if ($restc->responseContent() =~ m/^\{/) {
	$resp = decode_json($restc->responseContent());
    } else {
	print $restc->responseContent();
	return \{};
    }
    if (($code < 300) && (exists($resp->{'rsp'}) &&
			  exists($resp->{'rsp'}->{'stat'}) &&
			  $resp->{'rsp'}->{'stat'} eq "ok") ) {
	return $resp;
    } else {
	print "Error response code: $code\n";
	if ($code < 500) {
	    if (exists($resp->{'rsp'}) && exists($resp->{'rsp'}->{'stat'})) {
		print "Status: " . $resp->{'rsp'}->{'stat'} . "\n";
		if (exists($resp->{'rsp'}->{'err'})) {
		    if (exists($resp->{'rsp'}->{'err'}->{'code'})) {
			print "Code: " . $resp->{'rsp'}->{'err'}->{'code'} . "\n";
		    }
		    if (exists($resp->{'rsp'}->{'err'}->{'msg'})) {
			print $resp->{'rsp'}->{'err'}->{'msg'} . "\n";
		    }
		}
	    } else {
		print "Response:\n";
		print $restc->responseContent() . "\n";
	    }
	}
    }
    my $retval = sprintf("%.0f", $code / 100);
    exit $retval;
}

sub checktoken {
    if (-f $tokenfile) {
	$authtoken = `cat $tokenfile`;
	chomp $authtoken;
	return;
    }

    $apclient->GET("/services/rest/\?" . makeauthstr({'method' => 'rtm.auth.getFrob'}));
    $jsonresp = check_return_error($apclient);

    if (exists($jsonresp->{'rsp'}->{'frob'})) {
	$frob = $jsonresp->{'rsp'}->{'frob'};
	print "Got frob = $frob\n";
    } else {
	print "No frob response\n";
	exit 1;
    }

    print "Opening browser for login...\n";
    system("xdg-open", "$authserver/services/auth/\?" .
	   makeauthstr({'frob' => $frob,
			'perms' => 'delete',
			'format' => 'xml' }));

    print "\nPress <ENTER> once authorization is complete...\n";
    my $waitent = <STDIN>;
    $apclient->GET("/services/rest/\?" .
		   makeauthstr({'method' => 'rtm.auth.getToken',
				'perms' => 'delete',
				'frob' => $frob}));
    my $perms = '';
    my $userid = '';
    my $username = '';
    my $fullname = '';

    $jsonresp = check_return_error($apclient);
    if (exists($jsonresp->{'rsp'}->{'auth'})) {
	$authtoken = $jsonresp->{'rsp'}->{'auth'}->{'token'};
	$perms = $jsonresp->{'rsp'}->{'auth'}->{'perms'};
	$userid = $jsonresp->{'rsp'}->{'auth'}->{'user'}->{'id'};
	$username = $jsonresp->{'rsp'}->{'auth'}->{'user'}->{'username'};
	$fullname = $jsonresp->{'rsp'}->{'auth'}->{'user'}->{'fullname'};
	print "token=$authtoken, perms=$perms, uid=$userid, uname=$username, fname=$fullname\n";
    } else {
	print "No Auth element returned\n";
	exit 1;
    }

    open(OUTT, ">$tokenfile");
    print OUTT "$authtoken\n";
    close(OUTT);
}

checktoken();

my $output;

#$apclient->GET("/services/rest\?" . makeauthstr({'method' => 'rtm.lists.getList'}));
#$jsonresp = check_return_error($apclient);

#$output = $jo->encode($jsonresp);
#print $output;	       

$apclient->GET("/services/rest\?" . makeauthstr({'method' => 'rtm.tasks.getList',
						 'list_id' => '36622570',
						 'filter' => 'status:incomplete',
						}));
$jsonresp = check_return_error($apclient);

$output = $jo->encode($jsonresp);
print $output;	       

