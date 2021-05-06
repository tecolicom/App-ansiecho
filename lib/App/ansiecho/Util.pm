package App::ansiecho;
use v5.14;
use warnings;

sub make_options {
    map {
	# "foo_bar" -> "foo_bar|foo-bar|foobar"
	s{^(?=\w+_)(\w+)\K}{
	    "|" . $1 =~ tr[_][-]r . "|" . $1 =~ tr[_][]dr
	}er;
    }
    grep {
	s/#.*//;
	s/\s+//g;
	/\S/;
    }
    map { split /\n+/ }
    @_;
}

1;
