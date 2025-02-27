requires 'Encode';
requires 'Term::ANSIColor::Concise', '2.08';
requires 'Getopt::EX', '2.1.4';
requires 'Getopt::EX::Hashed', '1.06';
requires 'List::Util';
requires 'Pod::Usage';
requires 'Text::ANSI::Printf', '2.07';
requires 'perl', 'v5.16.0';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Command::Runner';
};
