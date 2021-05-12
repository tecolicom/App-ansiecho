use v5.14;
use warnings;

use Test::More;

use lib '.';
use t::Util;

is(ansiecho(qw(a b c))->{stdout}, "a b c\n", 'a b c');

sub X { sprintf "\e[%dm%s\e[m\e[K", @_ }
sub R { X 31, @_ }
sub G { X 32, @_ }
sub B { X 34, @_ }

is(ansiecho(qw(-c R RED))->{stdout}, R("RED")."\n", '-c R RED');
is(ansiecho(qw(-cR RED))->{stdout},  R("RED")."\n", '-cR RED');
is(ansiecho(qw(-c:R:RED))->{stdout}, R("RED")."\n", '-c:R:RED');

is(ansiecho(qw(-c:R:R -c:G:G -c:B:B))->{stdout}, join(" ",R("R"),G("G"),B("B"))."\n", '-c:R:R -c:G:G -c:B:B-c:R:R');

# -n
is(ansiecho(qw(-n -c R RED))->{stdout}, R("RED"), '-n');

# -j
is(ansiecho(qw(-j -c:R:R -c:G:G -c:B:B))->{stdout}, join("",R("R"),G("G"),B("B"))."\n", '-j -c:R:R -c:G:G -c:B:B-c:R:R');

done_testing;
