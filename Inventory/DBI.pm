package Inventory::DBI;

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
use Carp;
use CGI ();
use Exporter qw(import);
use DBI;

our (@ISA, @EXPORT);

@ISA	= qw(Exporter);
@EXPORT = qw(
	add_suplemental
	dbconnect
	describe_suplemental
	get_all
	get_search
	get_search_bool
	get_search_expand
	get_search_natural
	get_contents
	get_object
	get_suplemental
	get_type_suplemental
	new_object
	set_description
	set_location
	set_suplemental
);

###############
#	      #
# Subroutines #
#	      #
###############

sub add_suplemental($$;%);
sub dbconnect(;$);
sub describe_suplemental(;$);
sub get_all();
sub get_search($$$$);
sub get_search_bool($$$);
sub get_search_expand($$$);
sub get_search_natural($$$);
sub get_contents(;$);
sub get_object(;$);
sub get_suplemental($;$);
sub get_type_suplemental();
sub new_object($$$);
sub set_description($$);
sub set_location($$);
sub set_suplemental($$);

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

our $dbh=0;
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

{my $sth; sub get_type_suplemental(){
	$sth = $dbh->prepare(q(describe object suplemental)) unless $sth;
	$sth->execute() or croak $sth->errstr;
	local $_=$sth->fetchall_arrayref({});
	die scalar(@{$_}) if(scalar(@{$_})>1);
	return undef if(scalar(@{$_})==0);
	$_=$_->[0];
	$_=$_->{Type};
	s/^enum\((.*)\)$/$1/;
	my @r = split /,/;
	s/^'(.*)'$/$1/ foreach @r;
	@r;
}}

{my %sth; sub get_suplemental($;$){
	my $id=shift;
	@_=$_ unless @_;
	$sth{$_[0]} = $dbh->prepare(q(select * from ).$_[0].q( where id = ?)) unless $sth{$_[0]};
	$sth{$_[0]}->execute($id) or croak $sth{$_[0]}->errstr;
	my $r=$sth{$_[0]}->fetchall_hashref('id');
	$r=$r->{$id};
}}

{my %sth; sub describe_suplemental(;$){
	@_=$_ unless @_;
	$sth{$_[0]} = $dbh->prepare(q(describe ).$_[0]) unless $sth{$_[0]};
	$sth{$_[0]}->execute() or croak $sth{$_[0]}->errstr;
	my $r=$sth{$_[0]}->fetchall_arrayref({});
	$r;
}}

{sub add_suplemental($$;%){my %sth; ### debug persistant statement handles
	my $id=shift;
	my $table=shift;

	my @fields;
	unless($sth{$table}){
		my $r=describe_suplemental($table);
		foreach my $i (@$r){
			next if 'PRI'eq$i->{Key};
			push @fields, $i->{Field};
		}
		my $str=q(insert into ).$table." (id, ".(join ', ', map {qq(`$_`)} @fields).') values ('.(join ',',(qw(?)x (1+scalar(@fields)))).')';
		$sth{$table} = $dbh->prepare($str);
	}
	my %p=@_;
	$sth{$table}->execute($id,@p{@fields}) or croak $sth{$table}->errstr;
}}

{my $sth; sub get_object(;$){
	$sth = $dbh->prepare(q(select location, type, description, secondaryid, suplemental from object where id = ?)) unless $sth;
	@_=$_ unless @_;
	$sth->execute($_[0]) or croak $sth->errstr;
	my $r=$sth->fetchall_arrayref;
	die scalar(@{$r}) if(scalar(@{$r})>1);
	return () if(scalar(@{$r})==0);
	$r=$r->[0];
	@$r;
}}

{my $sth; sub get_all(){
	$sth = $dbh->prepare(q(select id, location, type, description, secondaryid, suplemental from object where description is not null or secondaryid is not null or suplemental is not null order by rand() limit 25)) unless $sth;
	$sth->execute() or croak $sth->errstr;
	$sth->fetchall_arrayref;
}}

{my $sth; sub get_search_natural($$$){
	$sth = $dbh->prepare(q(select id, location, type, description, secondaryid, suplemental, MATCH(description) AGAINST(?) AS relavance from object where MATCH(description) AGAINST(?) order by relavance limit ?, ?)) unless $sth;
	$sth->execute(@_[0,0,1,2]) or croak $sth->errstr;
	$sth->fetchall_arrayref;
}}

{my $sth; sub get_search_bool($$$){
	$sth = $dbh->prepare(q(select id, location, type, description, secondaryid, suplemental, MATCH(description) AGAINST(? IN BOOLEAN MODE) AS relavance from object where MATCH(description) AGAINST(? IN BOOLEAN MODE) order by relavance limit ?, ?)) unless $sth;
	$sth->execute(@_[0,0,1,2]) or croak $sth->errstr;
	$sth->fetchall_arrayref;
}}

{my $sth; sub get_search_expand($$$){
	$sth = $dbh->prepare(q(select id, location, type, description, secondaryid, suplemental, MATCH(description) AGAINST(? WITH QUERY EXPANSION) AS relavance from object where MATCH(description) AGAINST(? WITH QUERY EXPANSION) order by relavance limit ?, ?)) unless $sth;
	$sth->execute(@_[0,0,1,2]) or croak $sth->errstr;
	$sth->fetchall_arrayref;
}}

sub get_search($$$$){
	my $type=shift;
	my $query=shift;
	my $start=shift;
	my $count=shift;

	return get_search_natural($query, $start, $count);
	return get_search_bool($query, $start, $count);
	return get_search_expand($query, $start, $count);
}

{my $sth; sub get_contents(;$){
	$sth = $dbh->prepare(q(select id, type, description, secondaryid, suplemental from object where location = ?)) unless $sth;
	@_=$_ unless @_;
	$sth->execute($_[0]) or croak $sth->errstr;
	$sth->fetchall_arrayref;
}}

{my $sth; sub new_object($$$){
	$sth = $dbh->prepare(q(insert into object (id, location, type) values (?,?,?))) unless $sth;
	$sth->execute(@_) or croak $sth->errstr;
}}

{my $sth; sub set_location($$){
	$sth = $dbh->prepare(q(update object set location=? where id=?)) unless $sth;
	$sth->execute(@_[1,0]) or croak $sth->errstr;
}}

{my $sth; sub set_description($$){
	$sth = $dbh->prepare(q(update object set description=? where id=?)) unless $sth;
	$sth->execute(@_[1,0]) or croak $sth->errstr;
}}

{my $sth; sub set_suplemental($$){
	$sth = $dbh->prepare(q(update object set suplemental=? where id=? and suplemental is null)) unless $sth;
	$sth->execute(@_[1,0]) or croak $sth->errstr;
}}

sub dbconnect(;$){
	if($dbh){
		warn $dbh;
	}else{
		my $user=shift;
		#Note: if you do not specify a user at all the corrent user is used. Would be nice if this was documented somewhere.
		#if you are not using unix socket authentication change next lines as needed.
		#$user='www-data' unless($user);
		$dbh=DBI->connect(
			'DBI:mysql:database=inventory',
			$user,
			'',
			{
				RaiseError => 1,
				PrintError => 1,
				AutoCommit => 1,
				mariadb_server_prepare=>1,
				mariadb_conn_attrs => {
					program_name => $0,
					line => __LINE__,
					file => __FILE__
				},
			}
		)||carp $DBI::errstr;
	}
}

1;

################ Documentation ################
__END__
