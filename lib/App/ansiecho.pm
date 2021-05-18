package App::ansiecho;

our $VERSION = "0.01";

use v5.14;
use warnings;

use utf8;
use Encode;
use charnames ':full';
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
}
use open IO => 'utf8', ':std';
use Pod::Usage;

use Moo;

has debug      => ( is => 'ro' );
has verbose    => ( is => 'ro', default => 1 );
has no_newline => ( is => 'ro' );
has join       => ( is => 'ro' );
has escape     => ( is => 'ro' );
has rgb24      => ( is => 'ro' );
has separator  => ( is => 'rw', default => " " );

has terminator => ( is => 'rw', default => "\n" );

no Moo;

use App::ansiecho::Util;
use Getopt::EX v1.23.2;
use Text::ANSI::Printf 2.01 qw(ansi_sprintf);

use List::Util qw(sum);

sub run {
    my $app = shift;
    local @ARGV = map { utf8::is_utf8($_) ? $_ : decode('utf8', $_) } @_;

    use Getopt::EX::Long qw(GetOptions Configure ExConfigure);
    ExConfigure BASECLASS => [ __PACKAGE__, "Getopt::EX" ];
    Configure qw(bundling no_getopt_compat pass_through);
    GetOptions($app, make_options "
	debug
	verbose    | v !
	no_newline | n !
	join       | j !
	escape     | e !
	rgb24          !
	separator      =s
	") || pod2usage();
    $app->initialize();
    print join $app->separator, $app->param(@ARGV);
    print $app->terminator;
}

sub initialize {
    my $app = shift;
    $app->terminator('') if $app->no_newline;
    $app->separator('') if $app->join;
    if (defined $app->rgb24) {
	$Getopt::EX::Colormap::RGB24 = !!$app->rgb24;
    }
}

use Getopt::EX::Colormap qw(colorize ansi_code);

sub param {
    my $app = shift;
    my @in = @_;
    my @out;
    my @pending;
    my @stack;

    my $push = sub {
	push @stack, [ [ splice @pending ], [ splice @out ], @_ ];
    };
    my $pop = sub {
	(my($pending, $out), @in) = @{pop @stack};
	@pending = @{$pending};
	push @in, splice @out, 0, 0+@out, @{$out};
    };
    my $append = sub {
	push @out, join '', splice(@pending), @_;
    };

    while (@in) {
	my $arg = shift @in;
	#
	# -r     : raw data
	# -s, -z : ansi sequence
	#
	if ($arg =~ /^-([szr])(.+)?$/) {
	    my $opt = $1;
	    my $text = $2 || shift @in;
	    my $data = $opt eq 'r' ? safe_backslash($text) : ansi_code($text);
	    if (@out == 0 or $opt eq 's') {
		push @pending, $data;
	    } else {
		$out[-1] .= $data;
	    }
	    next;
	}
	#
	# -c : color
	#
	if ($arg =~ /^-c((?![\/\^~;#])\pP)?+(.+)?$/) {
	    my($delim, $param) = ($1, $2);
	    my($color, $string);
	    if ($delim and $param and $param =~ $delim) {
		($color, $string) = split $delim, $param, 2;
	    }
	    else {
		$color = defined $param ? $param : do {
		    $in[0] =~ /^-f/ and do { $push->($arg); redo };
		    shift @in;
		};
		$in[0] =~ /^-f/ and do { $push->('-c', $color); redo };
		$string = shift @in;
	    }
	    $string = safe_backslash($string) if $app->escape;
	    $append->(colorize($color, $string));
	}
	#
	# -f : format
	#
	elsif ($arg =~ /^-f(.+)?$/) {
	    my $format = defined $1 ? $1 : shift @in;
	    $format = safe_backslash($format);
	    my $n = sum map {
		{ '%' => 0, '*' => 2, '*.*' => 3 }->{$_} // 1
	    } $format =~ /(?| %(%) | %[-+ #0]*+(\*(?:\.\*)?|.) )/xg;
	    @in >= $n or die "$arg : not enough arguments.\n";
	    if (grep { /^-[cf]/ } @in[0..$n-1]) {
		do { $push->('-f', $format); redo };
	    }
	    $append->(ansi_sprintf($format, splice @in, 0, $n));
	}
	#
	# string argument
	#
	else {
	    $append->($app->escape ? safe_backslash($arg) : $arg);
	}
    } continue {
	if (@in == 0) {
	    @pending and $append->();
	    # return from recursion
	    @stack and $pop->();
	}
    }
    return @out;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::ansiecho - Command to produce ANSI terminal code

=head1 SYNOPSIS

    ansiecho [ options ] color-spec

=head1 DESCRIPTION

B<ansiecho> is a small command interface to produce ANSI terminal
code using L<Getopt::EX::Colormap> module.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2021 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

