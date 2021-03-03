package Inventory::Default;

################ Copyright ################

# This program is Copyright 2020 by Ben Hildred.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the Perl Artistic License or the
# GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# If you do not have a copy of the GNU General Public License write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge,
# MA 02139, USA.

################ Module Preamble ################

use 5.004;

use utf8;
use strict;
use warnings;
use Inventory::Carp;
use CGI ();
use Inventory::Get;
use Inventory::Post;
use Apache2::Request ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);
use Data::Dumper;
use Apache2::Cookie ();

###############
#	      #
# Subroutines #
#	      #
###############

sub handler($);

###########################
#			  #
# Data Structure Varables #
#			  #
###########################


##################
#		 #
# Other Varables #
#		 #
##################

our $admin=0;
my $debug=0;
#1 plain
#2 env
#4 cookie

#######################
#		      #
# Lexical Subroutines #
#		      #
#######################


###############
#	      #
# Subroutines #
#	      #
###############

sub handler($){
	my $r = shift;
	my $q = Apache2::Request->new($r);
	if('GET'eq$ENV{REQUEST_METHOD}){
		handler_get $r,$q;
	}elsif('POST'eq$ENV{REQUEST_METHOD}){
		handler_post $r,$q;
	}else{
		$r->content_type('text/plain');
		foreach (sort $q->param) {
			print "$_=",$q->param($_),"\n"
		}
		foreach (sort keys %ENV) {
			print "$_=$ENV{$_}\n"
		}
		return Apache2::Const::OK;
	}
}

1;

################ Documentation ################
__END__
