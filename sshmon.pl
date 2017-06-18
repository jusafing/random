#!/usr/bin/perl -w
###############################################################################
# Name        :  webhook.pl
# Version     :  v0.1
# Date        :  June 2017
# Description :  It sends a POST data to an endpoint (webhook)
# Author      :  Javier Santillan  [jusafing@gmail.com]
###############################################################################
use strict;
use LWP::UserAgent;
use Log::Log4perl qw(:easy);
use File::ReadBackwards;

###############################################################################
# Global Variables
my $endpoint  = "URL"
my $authfile  = "/var/log/auth.log";
my $logfile   = "/tmp/testx.log";
my $server    = "morrislap.local";
my $readbuffer= 20;
my $maxpost   = 10;
my %readlogs  ;

###############################################################################
# Modules configuration
# Initialize Logger
Log::Log4perl->easy_init( { level    => $DEBUG,
                            file     => ">>$logfile",
                            layout   => '%d %F{1}-%L-%M: [%p] %m%n' },
                          { level    => $DEBUG,
                            file     => "STDOUT",
                            layout   => '%d %F{1}-%L-%M: [%p] %m%n' },
                        );
my $logger = Log::Log4perl->get_logger();


###############################################################################
# Send POST request
# http://xmodulo.com/how-to-send-http-get-or-post-request-in-perl.html
sub send_post {
    my $endpoint = shift;
    my $data     = shift;
    my $ua       = LWP::UserAgent->new;
    my $req      = HTTP::Request->new(POST => $endpoint);
    $req->header('content-type' => 'application/json');
    my $post_data = $data;
    $req->content($post_data);
    my $resp = $ua->request($req);
    $logger->info("Sending POST data: ($data)");
    if ($resp->is_success) {
        my $message = $resp->decoded_content;
        $logger->info("Received reply: ($message)");
    }
    else {
        $logger->error("HTTP POST error code: ($resp->code)");
        $logger->error("HTTP POST error message: ($resp->message)");
    }
}
###############################################################################
# Send POST request
sub sshmon {
    my $file     = shift;
    my $buffer   = shift;
    my $line_cnt ;
    my $line     ;
    my $fh       ;
    $logger->info(" >>>>>>>>>>>>>>>>>> Reading file $file");
    if ($fh = File::ReadBackwards->new($file)) {
        while ( defined($line = $fh->readline) ) {
            my $flag_send = 0;
            my $data      = "";
            $line_cnt ++;
            chomp($line);
            if ($line =~ m/accepted/i) {
                my $prefix = "### ALERT: SSH ACCEPTED on $server\n";
                $data = "{\"text\": \"$prefix`$line`\"}";
                $logger->warn("Accepted connection detected: Sending ($data)");
                $flag_send ++;
            }
            elsif ($line =~ m/failed/i) {
                my $prefix = "##### WARNING: SSH TRY FAILED on $server\n";
                $data = "{\"text\": \"$prefix`$line`\"}";
                $logger->warn("Failed connection detected: Sending ($data)");
                $flag_send ++;
            }
            elsif ($line =~ m/[^CRON].*session opened/i) {
                my $prefix = "### ALERT: SSH SESSION Opened $server\n";
                $data = "{\"text\": \"$prefix`$line`\"}";
                $logger->warn("Session opened detected: Sending ($data)");
                $flag_send ++;
            }
            elsif ($line =~ m/Successful su/i) {
                my $prefix = "### ALERT: ROOT session Opened $server\n";
                $data = "{\"text\": \"$prefix`$line`\"}";
                $logger->warn("ROOT session opened: Sending ($data)");
                $flag_send ++;
            }

            if ( $flag_send > 0) {
                if ( exists $readlogs{$line} ) {
                    $logger->debug("LOG LINE Already reported");
                }
                else {
                    $readlogs{$line}++;
                    send_post($endpoint, $data);
                }
            }
            last if ($line_cnt > $buffer);
        }
    }
    else {
        $logger->error("Unable to read auth file $file");
    }
}

###############################################################################
# 

while(1) {
    sshmon($authfile, $readbuffer);
    sleep 3
}
