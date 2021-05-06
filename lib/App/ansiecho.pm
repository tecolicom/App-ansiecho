package App::ansiecho;

our $VERSION = "0.01";

use v5.14;
use warnings;

use utf8;
use Encode;
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
has separator  => ( is => 'rw', default => " " );

has terminator => ( is => 'rw', default => "\n" );

no Moo;

use App::ansiecho::Util;
use Text::ANSI::Printf qw(ansi_sprintf);

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
}

use Getopt::EX::Colormap qw(ansi_pair ansi_code);

sub param {
    my $app = shift;
    my @in = @_;
    my @out;
    my @seq;
    while (@in) {
	my $arg = shift @in;
	#
	# -s, -e : raw sequence
	#
	if ($arg =~ /^-([se])(.+)?$/) {
	    my $position = $1;
	    my $spec = $2 || shift @in;
	    my $code = ansi_code($spec);
	    if ($position eq 's' or @out == 0) {
		push @seq, $code;
	    } else {
		$out[-1] .= $code;
	    }
	    next;
	}

	push @out, join '', splice @seq, 0;

	#
	# -c : color
	#
	if ($arg =~ /^-c((?![\/\^~;#])\pP)?+(.+)?$/) {
	    my($delim, $param) = ($1, $2);
	    my($color, $string) = sub {
		if ($delim and $param and $param =~ $delim) {
		    return split $delim, $param, 2;
		}
		my $color = $param || shift @in;
		@in = $app->param(@in);
		($color, shift @in);
	    }->();
	    my($s, $e) = ansi_pair($color);
	    $out[-1] .= $s . $string . $e;
	}
	#
	# -f : format
	#
	elsif ($arg =~ /^-f(.+)?$/) {
	    my $format = defined $1 ? $1 : shift @in;
	    $format = safe_backslash($format);
	    @in = $app->param(@in);
	    my $n = $format =~ tr[%][%];
	    @in >= $n or die "$arg : not enough arguments.\n";
	    $out[-1] .= ansi_sprintf($format, splice @in, 0, $n);
	}
	#
	# string
	#
	else {
	    $out[-1] .= $arg;
	}
    }
    if (@seq) {
	push @out, '' if @out == 0;
	$out[-1] .= join '', splice @seq, 0;
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

