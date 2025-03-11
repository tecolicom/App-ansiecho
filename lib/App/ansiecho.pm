package App::ansiecho;

our $VERSION = "1.10";

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

use App::ansiecho::Util qw(decode_argv unescape);
use Getopt::EX v1.24.1;
use Text::ANSI::Printf 2.03 qw(ansi_sprintf);
$Text::ANSI::Printf::REORDER = 1;
use List::Util qw(max);

use Getopt::EX::Hashed; {
    Getopt::EX::Hashed->configure(DEFAULT => [ is => 'rw' ]);
    has debug    => "      " ;
    has n        => "      " , action => sub { $_->terminate = '' };
    has join     => " j    " , action => sub { $_->separate = '' };
    has escape   => " e !  " , default => 1;
    has rgb24    => "   !  " ;
    has separate => "   =s " , default => " ";
    has help     => " h    " ;
    has version  => " v    " ;

    has '+separate' => sub {
	my($name, $arg) = map "$_", @_;
	$_->$name = unescape($arg);
    };

    has '+rgb24' => sub {
	$Term::ANSIColor::Concise::RGB24 = !!$_[1];
    };

    has '+help' => sub {
	pod2usage
	    -verbose  => 99,
	    -sections => [ qw(SYNOPSIS VERSION) ];
    };

    has '+version' => sub {
	say "Version: $VERSION";
	exit;
    };

    has terminate  => default => "\n";
    has params     => default => [];

} no Getopt::EX::Hashed;

sub run {
    my $app = shift;
    $app->options(@_);
    print $app->retrieve, $app->terminate;
    return 0;
}

sub options {
    my $app = shift;
    my @argv = decode_argv @_;
    use Getopt::EX::Long qw(GetOptionsFromArray Configure ExConfigure);
    ExConfigure BASECLASS => [ __PACKAGE__, "Getopt::EX" ];
    Configure qw(bundling no_getopt_compat pass_through);
    $app->getopt(\@argv) || pod2usage();
    $app->params(\@argv);
    $app;
}

use Term::ANSIColor::Concise qw(ansi_color ansi_code);

sub uniname {
    local $_ = @_ ? shift : $_;
    my @names = map { /^[\da-f]{1,6}$/i ? "\\N{U+$_}" : "\\N{$_}" } /[-+_\w ]+/g;
    unescape join '', @names;
}

sub retrieve {
    my $app = shift;
    my $count = shift // 0;
    my $in = $app->params;
    my(@style, @effect);

    my @out;
    my @pending;
    my $submit = sub { push @pending, @_ };
    my $commit = sub {
	return if @pending == 0 and @_ == 0;
	if ($count == 0 and @out > 0 and $app->separate ne '') {
	    push @out, $app->separate;
	}
	push @out, join '', splice(@pending), @_;
    };

    while (@$in) {
	my $arg = shift @$in;

	# -x : set separator
	if ($arg =~ /^-x(?<uni>u)?$/) {
	    my $uni = %+;
	    my $sep = $app->retrieve(1) // die "Not enough argument.\n";
	    $app->separate = $uni ? uniname($sep) : $sep;
	    next;
	}
	# -S
	if ($arg =~ /^-S$/) {
	    unshift @style, [ \&ansi_code ];
	    next;
	}
	# -c, -C
	if ($arg =~ /^-([cC])(.+)?$/) {
	    my $target = $1 eq 'c' ? \@effect : \@style;
	    my $color = defined $2 ? unescape($2) : $app->retrieve(1);
	    unshift @$target, [ \&ansi_color, $color ];
	    next;
	}
	# -F
	if ($arg =~ /^-(F)(.+)?$/) {
	    my $format = defined $2 ? unescape($2) : $app->retrieve(1);
	    unshift @style, [ \&ansi_sprintf, $format ];
	    next;
	}
	# -U
	if ($arg =~ /^-(U)$/) {
	    unshift @style, [ \&uniname ];
	    next;
	}
	# -E
	if ($arg =~ /^-E$/) {
	    @style = ();
	    next;
	}

	#
	# -s, -i, -a : ANSI sequence
	#
	if ($arg =~ /^-([sia])(.+)?$/) {
	    my $opt = $1;
	    my $text = $2 // shift(@$in) // die "Not enough argument.\n";
	    my $code = ansi_code($text);
	    if ($opt eq 's') {
		$arg = $code;
	    } else {
		if (@out == 0 or $opt eq 'i') {
		    $submit->($code);
		} else {
		    $out[-1] .= $code;
		}
		next;
	    }
	}
	#
	# -f : format
	#
	elsif ($arg =~ /^-f(.+)?$/) {
	    my($format) = defined $1 ? unescape($1) : $app->retrieve(1);
	    state $param_re = do {
		my $P = qr/\d+\$/;
		my $W = qr/\d+|\*$P?/;
		qr{ %% |
		    (?<I> % $P?) [-+#0\ ]*+
		    (?: (?<V> \* $P?+ )? v )?+
		    (?: (?<A>$W) (?:\.(?<B>$W))?+ | \.(?<C>$W) )?+
		    (?:[hjlqLltz]|[csduoxefgXEGbBpnaAiDUOF])
		}x;
	    };
	    my($pos, $n) = (0, 0);
	    while ($format =~ /$param_re/g) {
		$+{I} // next;
		for ($+{I}, grep { defined and /\*/ } @+{qw(I V A B C)}) {
		    if (/(\d+)\$/) {
			$pos = max($pos, $1);
		    } else {
			$n++;
		    }
		}
	    }
	    $n = max($pos, $n);
	    $arg = ansi_sprintf($format, $app->retrieve($n));
	}
	#
	# -u : Unicode Name
	#
	if ($arg =~ /^-u(.+)?$/) {
	    my $opt = $1;
	    my $name = $2 // shift(@$in) // die "Not enough argument.\n";
	    $arg = uniname($name);
	}
	#
	# normal string argument
	#
	else {
	    if ($app->escape) {
		$arg = unescape($arg);
	    }
	}

	#
	# apply @effect and @style
	#
	for (splice(@effect), @style) {
	    my($func, @opts) = @$_;
	    $arg = $func->(@opts, $arg);
	}

	$commit->($arg);

	if ($count) {
	    die "Unexpected behavior.\n" if @out > $count;
	    last if @out == $count;
	}
    }
    $commit->();
    die "Not enough argument.\n" if $count and @out < $count;
    wantarray ? @out : $out[0];
}

1;

__END__

=encoding utf-8

=head1 NAME

ansiecho - Colored echo command using ANSI terminal sequence

=head1 SYNOPSIS

    ansiecho [ options ] color-spec

=head1 DESCRIPTION

Document is included in the executable script.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2021-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
