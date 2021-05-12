use v5.14;
use warnings;

use Test::More;

use lib '.';
use t::Util;

is(ansiecho(qw(a b c))->{stdout}, "a b c\n", 'a b c');

is(ansiecho(qw(-c R RED))->{stdout}, "\e[31mRED\e[m\e[K\n", '-c R RED');
is(ansiecho(qw(-cR RED))->{stdout}, "\e[31mRED\e[m\e[K\n", '-cR RED');
is(ansiecho(qw(-c:R:RED))->{stdout}, "\e[31mRED\e[m\e[K\n", '-c:R:RED');

done_testing;
