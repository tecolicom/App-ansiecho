use v5.14;
use warnings;

use App::ansiecho;
use Command::Runner;

sub ansiecho {
    local @ARGV = @_;
    my $sub = sub { App::ansiecho->new->run(@ARGV) };
    Command::Runner->new(command => $sub)->run;
}

1;
