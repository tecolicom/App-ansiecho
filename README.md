[![Actions Status](https://github.com/kaz-utashiro/App-ansiecho/workflows/test/badge.svg)](https://github.com/kaz-utashiro/App-ansiecho/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-ansiecho.svg)](https://metacpan.org/release/App-ansiecho)
# NAME

ansiecho - Echo command with ANSI terminal code

# VERSION

Version 0.01

# SYNOPSIS

ansiecho -c R Red -c /G GreenBack -c BS BlueReverse

# DESCRIPTION

## ECHO

**ansiecho** print arguments with ANSI terminal escape sequence
according to the given color specification.

In a simple case, **ansiecho** behave exactly same as [echo](https://metacpan.org/pod/echo) command.

    ansiecho a b c

Like [echo](https://metacpan.org/pod/echo) command, option **-n** disables to print newline at the
end.  Option **-j** (or **--join**) removes white space between
arguments.

## COLOR

You can specify color of each argument by preceding with **-c** option:

    ansiecho -c R a -c GI b -c BD c

This command print strings `a`, `b` and `c` according to the color
spec of `R` (Red), `GI` (_Green Italic_) and `BD` (**Blue Bold**)
respectively. This can be written as below too.

    ansiecho -cR a -cGI b -cBD c

    ansiecho -c:R:a -c:GI:b -c:BD:c

Foreground/Background color can be specified by 8+8 standard colors,
24 gray scales, 6x6x6 216 colors, RGB values or color names, with
special effects such as I (Italic), D (Double-struck; Bold), S
(Stand-out; Reverse Video) and more.

    RGB  6x6x6    12bit      24bit           color name
    ===  =======  =========  =============  ==================
    B    005      #00F       (0,0,255)      <blue>
     /M     /505      /#F0F   /(255,0,255)  /<magenta>
    K/W  000/555  #000/#FFF  000000/FFFFFF  <black>/<white>
    R/G  500/050  #F00/#0F0  FF0000/00FF00  <red>/<green>
    W/w  L03/L20  #333/#ccc  303030/c6c6c6  <dimgrey>/<lightgrey>

More information is described in ["COLOR SPEC"](#color-spec) section.

## FORMAT

Format string can be specified with **-f** option, and it behaves like
a [printf](https://metacpan.org/pod/printf) command.

    ansiecho -f '[ %5s : %5s : %5s ]' -c R RED -c G GREEN -c B BLUE

You can use backslash escape characters in the format string.
See ["STRING LITERAL"](#string-literal) section.

Formatted result becomes a single argument, and can be a subject of
other operation.  In next example, numbers are formatted, colored, and
gave to other format.

    ansiecho -f '\N{ALARM CLOCK} %s' -c KF/544 -f ' %02d:%02d:%02d ' 1 2 3

Formatting is done by Perl `sprintf` function.  See
["sprintf" in perlfunc](https://metacpan.org/pod/perlfunc#sprintf) for detail.

## ANSI SEQUENCE

With normal usage, **ansiecho** print given argument with introducer
and reset sequences.

To get just a desired sequence, use **-s** option.  Next example
produce ANSI terminal sequence to indicate `deeppink` color with
`lightyellow` background.

    ansiecho -n -s '<deeppink>/<lightyellow>'

You will get the next result with 256-color terminal:

    ^[[38;5;198;48;5;230m

and the next with full-color terminal:

    ^[[38;2;255;20;147;48;2;255;255;224m

Option **-z** does almost same thing, but it append a sequence to the
final argument.  Next two commands are equivalent.

    ansiecho -c R Red
    ansiecho -s R Red -z ZE

Color spec `ZE` produces RESET and ERASE LINE sequence.

Because **-s** and **-z** does not produce RESET sequence, you can use
them to accumulate the effects.

    ansiecho -s R R -s U RU -s I RUI -s S RUIS -s F RUISF -z Z

# OPTIONS

- **-n**

    Do not print newline at the end.

- **-e**

    Enable interpretation of backslash escapes in the normal string
    argument.  See ["STRING LITERAL"](#string-literal) section.

- **-j**, **--join**

    Do not print space between arguments.

- **-c** _spec_ _string_
- **-c**:_spec_:_string_

    Print _string_ in the color given by _spec_.

    If the **-c** is followed by an punctuation character other than
    ` / ^ ~ ; # `, it is used as a delimiter character.

- **-s** _spec_
- **-z** _spec_

    Add raw ANSI sequence given by _spec_.  Option **-s** add the sequence
    to the new argument, while **-z** add to the final argument.  There are
    no difference when used with **-j** option or with single-or-less
    argument.

- **-r** _string_ (raw)

    Append next string to the final argument with backslash escape
    interpretation.

- **-f** _format_ _args_ ...

    Print _args_ in the given _format_.

    In the format string, backslash escaped character can be used.  For
    example, `\n` stands for new line character.  This is done by Perl
    `printf` function.  See ["sprintf" in perlfunc](https://metacpan.org/pod/perlfunc#sprintf) and ["Quote and
    Quote-like Operators" in perlop](https://metacpan.org/pod/perlop#Quote-and-Quote-like-Operators) for detail.

    The result of **-f** sequence ends up to a single argument, and can be
    a subject of other **-c** or **-f** option.

    Number of arguments are calculated from the number of `%` characters
    in the format string except `%%`.

- **--separator** _string_

    Set separator string between each arguments.  Option **-j** is a
    short-cut for **--separator ''**.

# STRING LITERAL

This is a backslash escape samples described in ["Quote and
Quote-like Operators" in perlop](https://metacpan.org/pod/perlop#Quote-and-Quote-like-Operators).

    Sequence     Description
    \t           tab               (HT, TAB)
    \n           newline           (NL)
    \r           return            (CR)
    \f           form feed         (FF)
    \b           backspace         (BS)
    \a           alarm (bell)      (BEL)
    \e           escape            (ESC)
    \x{263A}     hex char          (example: SMILEY)
    \x1b         restricted range hex char (example: ESC)
    \N{name}     named Unicode character or character sequence
    \N{U+263D}   Unicode character (example: FIRST QUARTER MOON)
    \c[          control char      (example: chr(27))
    \o{23072}    octal char        (example: SMILEY)
    \033         restricted range octal char  (example: ESC)

# COLOR SPEC

This is a brief summary.  Read ["COLOR SPEC" in Getopt::EX::Colormap](https://metacpan.org/pod/Getopt::EX::Colormap#COLOR-SPEC) for
complete description.

Color specification is a combination of single uppercase character
representing 8 colors, and alternative (usually brighter) colors in
lowercase :

    R  r  Red
    G  g  Green
    B  b  Blue
    C  c  Cyan
    M  m  Magenta
    Y  y  Yellow
    K  k  Black
    W  w  White

or RGB values and 24 grey levels if using ANSI 256 or full color
terminal :

    (255,255,255)      : 24bit decimal RGB colors
    #000000 .. #FFFFFF : 24bit hex RGB colors
    #000    .. #FFF    : 12bit hex RGB 4096 colors
    000 .. 555         : 6x6x6 RGB 216 colors
    L00 .. L25         : Black (L00), 24 grey levels, White (L25)

or color names enclosed by angle bracket :

    <red> <blue> <green> <cyan> <magenta> <yellow>
    <aliceblue> <honeydue> <hotpink> <mooccasin>
    <medium_aqua_marine>

with other special effects :

    N    None
    Z  0 Zero (reset)
    D  1 Double-struck (boldface)
    P  2 Pale (dark)
    I  3 Italic
    U  4 Underline
    F  5 Flash (blink: slow)
    Q  6 Quick (blink: rapid)
    S  7 Stand-out (reverse video)
    V  8 Vanish (concealed)
    X  9 Crossed out

    E    Erase Line

    ;    No effect
    /    Toggle foreground/background
    ^    Reset to foreground
    ~    Cancel following effect

Samples:

    RGB  6x6x6    12bit      24bit           color name
    ===  =======  =========  =============  ==================
    B    005      #00F       (0,0,255)      <blue>
     /M     /505      /#F0F   /(255,0,255)  /<magenta>
    K/W  000/555  #000/#FFF  000000/FFFFFF  <black>/<white>
    R/G  500/050  #F00/#0F0  FF0000/00FF00  <red>/<green>
    W/w  L03/L20  #333/#ccc  303030/c6c6c6  <dimgrey>/<lightgrey>

# INSTALL

## CPANMINUS

From CPAN archive:

    $ cpanm App::ansiecho
    or
    $ curl -sL http://cpanmin.us | perl - App::ansiecho

From GIT repository:

    cpanm https://github.com/kaz-utashiro/App-ansiecho.git

# BUGS

Format string can not made by **-f** option.  Next command does not
work as you may expect.

    ansiecho -f -f '%%%ds' 16 hello

Next one works, though.

    ansiecho -f '%*s' 16 hello

# SEE ALSO

["Quote and Quote-like Operators" in perlop](https://metacpan.org/pod/perlop#Quote-and-Quote-like-Operators)

[Getopt::EX::Colormap](https://metacpan.org/pod/Getopt::EX::Colormap)

[https://en.wikipedia.org/wiki/ANSI\_escape\_code](https://en.wikipedia.org/wiki/ANSI_escape_code)

[Graphics::ColorNames::X](https://metacpan.org/pod/Graphics::ColorNames::X)

[https://en.wikipedia.org/wiki/X11\_color\_names](https://en.wikipedia.org/wiki/X11_color_names)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2021 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
