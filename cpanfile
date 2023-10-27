requires 'Encode';
requires 'Term::ANSIColor::Concise', '2.05';
requires 'Getopt::EX', '2.1.1';
requires 'Getopt::EX::Hashed', '1.05';
requires 'List::Util';
requires 'Pod::Usage';
requires 'Text::ANSI::Printf', '2.05';
requires 'perl', 'v5.14.0';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Command::Runner';
};
