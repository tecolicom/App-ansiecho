use v5.14;
use warnings;

use Command::Runner;

sub run {
    my($script, @args) = @_;
    my @command = ($^X, '-Ilib', "./script/$script", @args);
    Command::Runner->new(command => \@command)->run

}

sub ansiecho { run 'ansiecho', @_ }

1;
