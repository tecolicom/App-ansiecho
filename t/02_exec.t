use v5.14;
use warnings;

use Test::More;

use lib '.';
use t::Util;

use Getopt::EX::Colormap ':all';

is(ansiecho(qw(a b c))->{stdout}, "a b c\n", 'a b c');

for my $fg ('RGBCMYKW' =~ /./g) {
    no strict 'refs';
    *{$fg} = sub { colorize($fg, @_) };
    for my $bg ('RGBCMYKW' =~ /./g) {
	*{"${fg}on${bg}"} = sub { colorize("${fg}/${bg}", @_) };
    }
}

is(ansiecho(qw(-c R RED))->{stdout}, R("RED")."\n", '-c R RED');
is(ansiecho(qw(-cR RED))->{stdout},  R("RED")."\n", '-cR RED');
is(ansiecho(qw(-c:R:RED))->{stdout}, R("RED")."\n", '-c:R:RED');

is(ansiecho(qw(-c:R:R -c:G:G -c:B:B))->{stdout},
   join(" ",R("R"),G("G"),B("B"))."\n",
   '-c:R:R -c:G:G -c:B:B -c:R:R');

# -n
is(ansiecho(qw(-n -c R RED))->{stdout}, R("RED"), '-n');

# -j
is(ansiecho(qw(-j -c:R:R -c:G:G -c:B:B))->{stdout},
   join("",R("R"),G("G"),B("B"))."\n",
   '-j -c:R:R -c:G:G -c:B:B -c:R:R');

# -f
is(ansiecho(qw(-f %s abc))->{stdout}, "abc\n", "-f %s abc");
is(ansiecho(qw(-f %%))->{stdout}, "%\n", "-f %%");
is(ansiecho(qw(-f %%%s%% abc))->{stdout}, "%abc%\n", "-f %%%s%% abc");
is(ansiecho(qw(-f %5s abc))->{stdout}, "  abc\n", "-f %5s abc");
is(ansiecho(qw(-f %5s -c R abc))->{stdout},
   sprintf("  %s\n", R("abc")),
   "-f %5s -c R abc");
is(ansiecho(qw(-f %-5s -c R abc))->{stdout},
   sprintf("%s  \n", R("abc")),
   "-f %-5s -c R abc");

is(ansiecho(qw(-f %d 123))->{stdout}, "123\n", "-f %d 123");
is(ansiecho(qw(-f %d -123))->{stdout}, "-123\n", "-f %d -123");
is(ansiecho(qw(-f %5d 123))->{stdout}, "  123\n", "-f %5d 123");
is(ansiecho(qw(-f %05d 123))->{stdout}, "00123\n", "-f %05d 123");
is(ansiecho(qw(-f %-5d 123))->{stdout}, "123  \n", "-f %-5d 123");
is(ansiecho(qw(-f %+5d  123))->{stdout}, " +123\n", "-f %+5d 123");
is(ansiecho(qw(-f %+5d -123))->{stdout}, " -123\n", "-f %+5d -123");
is(ansiecho('-f', '% 5d',  '123')->{stdout}, "  123\n", "-f '% 5d' 123");
is(ansiecho('-f', '% 5d', '-123')->{stdout}, " -123\n", "-f '% 5d' -123");
is(ansiecho(qw(-f %o  123))->{stdout},  "173\n", "-f %o 123");
is(ansiecho(qw(-f %#o 123))->{stdout}, "0173\n", "-f %#o 123");

# width parameter: *
is(ansiecho(qw(-f %*s 5 abc))->{stdout},
   "  abc\n", "-f %*s 5 abc");
is(ansiecho(qw(-f %*.*s 5 5 abc))->{stdout},
   "  abc\n", "-f %*.*s 5 5 abc");
is(ansiecho(qw(-f %*.*s 5 5 abcdefg))->{stdout},
   "abcde\n", "-f %*.*s 5 5 abcdefg");

is(ansiecho(qw(-f %%%*s%% 5 abc))->{stdout},
   "%  abc%\n", "-f %%%*s%% 5 abc");
is(ansiecho(qw(-f %0*d 5 123))->{stdout},
   "00123\n", "-f %0*d 5 123");
is(ansiecho(qw(-f %-*d 5 123))->{stdout},
   "123  \n", "-f %-*d 5 123");
is(ansiecho(qw(-f %-*d 5 -123))->{stdout},
   "-123 \n", "-f %-*d 5 -123");
is(ansiecho(qw(-f %0*.*d 5 5 123))->{stdout},
   "00123\n", "-f %0*.*d 5 5 123");
is(ansiecho(qw(-f %-*.*d 5 5 123))->{stdout},
   "00123\n", "-f %-*.*d 5 5 123");
is(ansiecho(qw(-f %-*.*d 5 5 -123))->{stdout},
   "-00123\n", "-f %-*.*d 5 5 -123");

# recurtion
is(ansiecho(qw(-f %5s -c -f %s/%s W R abc))->{stdout},
   sprintf("  %s\n", WonR("abc")),
   "-f %5s -c -f %s/%s W R abc");
is(ansiecho(qw(-f %5s -c -f %s/%s -f %s W -f %s R abc))->{stdout},
   sprintf("  %s\n", WonR("abc")),
   "-f %5s -c -f %s/%s -f %s W -f %s R abc");

TODO: {

local $TODO = "format string recursion";

# recursion
is(ansiecho(qw(-f -f %%%ds 5 -c R abc))->{stdout},
   sprintf("  %s\n", R("abc")), "-f -f %%%ds 5 -c R abc");

}

# -s, -z, -r

is(ansiecho(qw(-s R RED -z ZE))->{stdout}, R("RED")."\n", '-c R RED');

is(ansiecho(qw(-s R RED -r \e[m\e[K))->{stdout}, R("RED")."\n", '-c R RED');

is(ansiecho(qw(-s R RED -z ZE -s G GREEN -z ZE))->{stdout},
   sprintf("%s %s\n",
	   R("RED"),
	   G("GREEN"),
   ),
   '-s R RED -z ZE -s G GREEN -z ZE');

is(ansiecho(qw(-s R RED -s G GREEN -z ZE))->{stdout},
   sprintf("%s %s\n",
	   ansi_code("R")."RED",
	   G("GREEN"),
   ),
   '-s R RED -s G GREEN -z ZE');

is(ansiecho(qw(-s R RED -s G GREEN -z ZE))->{stdout},
   sprintf("%s %s\n",
	   ansi_code("R")."RED",
	   G("GREEN"),
   ),
   '-s R RED -s G GREEN -z ZE');

is(ansiecho(qw(-s R R -s U RU -s I RUI -s S RUIS -s F RUISF -z Z))->{stdout},
   join(' ',
	ansi_code("R")."R",
	ansi_code("U")."RU",
	ansi_code("I")."RUI",
	ansi_code("S")."RUIS",
	ansi_code("F")."RUISF".ansi_code("Z")."\n",
   ),
   '-s R R -s U RU -s I RUI -s S RUIS -s F RUISF -z Z');

done_testing;
