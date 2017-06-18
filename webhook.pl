#!/usr/bin/perl -w
###############################################################################
# Name        :  jusa-webhook.pl
# Version     :  v0.1
# Date        :  June 2017
# Description :  It sends a POST data to an endpoint (webhook)
# Author      :  Javier Santillan  [jusafing@gmail.com]
###############################################################################
use strict;
use LWP::UserAgent;
use Log::Log4perl qw(:easy);

###############################################################################
# Modules configuration
Log::Log4perl->easy_init($INFO);

###############################################################################
# Global Variables
package CFG;

our $logger = Log::Log4perl->get_logger();

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
    $logger->info("Sending POST data: ($data)\n");
    if ($resp->is_success) {
        my $message = $resp->decoded_content;
        $logger->info("Received reply: ($message)\n");
    }
    else {
        $logger->error("HTTP POST error code: ($resp->code)\n");
        $logger->error("HTTP POST error message: ($resp->message)\n");
    }
}

# add POST data to HTTP request body
my $data     = '{"text": "# Hello morris"}';
my $endpoint = "https://......";
send_post($endpoint, $data);
