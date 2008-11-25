package File::Pairtree;

use 5.000000;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION;
$VERSION = sprintf "%d.%02d", q$Name: Release-0-01 $ =~ /Release-(\d+)-(\d+)/;
our @EXPORT = qw(
	id2ppath ppath2id id2pairpath pairpath2id
	ptaddnode ptdelnode ptscantree
);
our @EXPORT_OK = qw( VERSION );
#	errmsg logmsg note sample validate

# Pairtree - Pairtree support software (Perl module)
# 
# Author:  John A. Kunze, jak@ucop.edu, California Digital Library, 2008
#          based on three lines of code originally from Sebastien Korner:
# $pt_objid =~ s/(\"|\*|\+|,|<|=|>|\?|\^|\|)/sprintf("^%x", ord($1))/eg;
# $pt_objid =~ tr/\/:./=+,/;
# my $pt_prefix = $namespace."/pairtree_root/".join('/', $pt_objid =~ /..|.$/g);

# ---------
# Copyright 2008 Regents of the University of California
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain a
# copy of the License at
# 
#         http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License. 
# ---------

my $default_pathcomp_sep = '/';
my $root = 'pairtree_root';

# id2ppath - return /-terminated ppath corresponding to id
# 
# For Perl, the platform's path component separator ('/' or '\') is
# automagically converted when needed to do filesystem things; in fact,
# trying to use the correct separator can get you into trouble.  So we
# make it possible to specify the path component separator, but we won't
# do it for you.  Instead we assume '/'.
#
# We use the symbol 'pathcomp_sep' because 'path_sep' is already taken
# by the Config module to designate the character that separates one path
# from another, eg, ':' in the PATH environment variable.
#
sub id2ppath{ my( $id, $pathcomp_sep )=@_;	# single arg form, second
						# arg not advertized

	$pathcomp_sep ||= $default_pathcomp_sep;
	$id =~ s{
		(["*+,<=>?\\^|]			# some visible ASCII and
		 |[^\x21-\x7e])			# all non-visible ASCII
	}{
		sprintf("^%02x", ord($1))	# replacement hex code
	}xeg;

	# Now do the single-char to single-char mapping.
	# The / translated next is not to be confused with $pathcomp_sep.
	#
	$id =~ tr /\/:./=+,/;			# per spec, /:. become =+,

	return $root
		. $pathcomp_sep
		. join($pathcomp_sep, $id =~ /..|.$/g)
		. $pathcomp_sep;
}

# This 2-arg form exists for parallelism with other language interfaces
# (that don't may not have optional arguments).  Perl users would
# normally prefer the id2ppath form for full functionality and speed.
# 
sub id2pairpath{ my( $id, $pathcomp_sep )=@_;	# two-argument form

	return id2ppath($id, $pathcomp_sep);
}

# ppath2id - return id corresponding to ppath, or string of the form
#		"error: <msg>"
# There is more error checking required for ppath2id than id2ppath,
# as the domain is more constrained.
#
sub ppath2id{ my( $path, $pathcomp_sep )=@_;	# single arg form, second
						# arg not advertized
	my $id = $path;			# initialize $id with $path
	my $p = $pathcomp_sep || $default_pathcomp_sep;

	my $expect_hexenc;		# chars expected to be hex encoded
	if ($p eq '\\') {		# \ is a common, problemmatic case
		$expect_hexenc = '"*<>?|';	# don't need to encode \ 
		$p = '\\\\';		# and double escape for use in regex
	} else {
		$expect_hexenc = '"*<>?|\\\\';	# do need to encode \ 
	}

	# Trim everything from the beginning up to the last instance of
	# $root (via a greedy match).  If there's a pairpath preceding
	# a given pairpath, assume that the most fine grained path is
	# the one the user's interested in.
	#
	$id =~ s/^.*$root//;

	# Normalize so there's no initial or final whitespace, no
	# repeated $pathcomp_sep chars, and exactly one $pathcomp_sep
	# at the beginning and end.
	#
	$id =~ s/^\s*/$p/;
	$id =~ s/\s*$/$p/;
	$id =~ s/$p+/$p/g;

	# Reject if there's any internal whitespace.
	# XXX
	#return "error: internal whitespace in $path" if
	#	$id =~ /\s/;

	# Also trim any final junk, eg, an path extension that is really
	# internal to an object directory.
	#
	$id =~ s/[^$p]{3,}.*$//;	# trim final junk

	# Finally, trim anything that follows a one-char path component,
	# a one-char component another signal of the end of a ppath.
	#
	$id =~ s/($p[^$p]$p).*$/$1/;	# trim anything after 1-char comp.

	# Reject if there are any non-visible chars.
	#
	return "error: non-visible chars in $path" if
		$id =~ /[^\x21-\x7e]/;

	# Reject if there are any other chars that should be hex-encoded.
	#
	return "error: found chars expected to be hex-encoded in $path" if
		$id =~ /[$expect_hexenc]/;

	# Now remove the path component separators.
	#
	$id =~ s/$p//g;

	# Reverse the single-char to single-char mapping.
	# This might add formerly hex-encoded chars back in.
	#
	$id =~ tr /=+,/\/:./;		# per spec, =+, become /:.

	# Reject if there are any ^'s not followed by two hex digits.
	#
	return "error: impossible hex-encoding in $path" if
		$id =~ /\^($|.$|[^0-9a-fA-F].|.[^0-9a-fA-F])/;

	# Now reverse the hex conversion.
	#
	$id =~ s{
		\^([0-9a-fA-F]{2})
	}{
		chr(hex("0x"."$1"))
	}xeg;

	return $id;
}

# use File::Path;
# 
# sub ptaddnode { my( $base, $id )=@_;
# 
# 	return "" if
# 		(! defined($id) || $id eq "");
# 	my ($root, $prefix) = base_init($base);
# 	return "" if
# 		(! defined($root));
# 	my $ppath = id2ppath($id);
# 	my $wholepath = $base . $ppath;
# 
# 	eval { mkpath($wholepath) };
# 
# 	return "" if
# 		($@);
# 	return $ppath;
# }
# 
# sub ptdelnode { my( $base, $id )=@_;
# 
# 	return "" if
# 		(! defined($id) || $id eq "");
# 	my ($root, $prefix) = base_init($base);
# 	return "" if
# 		(! defined($root));
# 	my $ppath = id2ppath($id);
# 	my $wholepath = $base . $ppath;
# 
# 	eval { rmtree($wholepath) };
# 
# 	return "" if
# 		($@);
# 	return $ppath;
# }
# 

#use File::Find;
# $File::Find::prune = 1

# Set $create = 1 to create
sub base_init { my( $base, $create )=@_;

	my ($root, $prefix) = (undef, undef);
	$create ||= 0;

	$root = $base . '/pairtree_root';
	if ($create) {
		eval { mkpath($root) };
		return undef if
			($@);
	}
	my $prefile = "$base/pairtree_prefix";
	if (-e $prefile) {
		local $/;
		# XXX check stat for ridiculous size
		open(IN, "r", $prefile) || return undef;
		$prefix = <IN>;
		close(IN);
	}
	return ($root, $prefix);
}

1;

__END__

=head1 NAME

Pairtree - routines to manage pairtrees

=head1 SYNOPSIS

 use Pairtree;                 # imports routines into a Perl script

 id2ppath($id);                # returns pairpath corresponding to $id
 id2ppath($id, $separator);    # if you want an alternate separator char

 ppath2id($path);              # returns id corresponding to $path
 ppath2id($path, $separator);  # if you want an alternate separator char

=head1 DESCRIPTION

This is very brief documentation for the B<Pairtree> Perl module.

=head1 COPYRIGHT AND LICENSE

Copyright 2008 UC Regents.  Open source Apache License, Version 2.

=cut
