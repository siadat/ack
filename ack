#!/usr/bin/env perl
#
# This file, ack, is generated code.
# Please DO NOT EDIT or send patches for it.
#
# Please take a look at the source from
# http://code.google.com/p/ack/source
# and submit patches against the individual files
# that build ack.
#

use warnings;
use strict;

our $VERSION = '1.90';
# Check http://betterthangrep.com/ for updates

# These are all our globals.


MAIN: {
    if ( $App::Ack::VERSION ne $main::VERSION ) {
        App::Ack::die( "Program/library version mismatch\n\t$0 is $main::VERSION\n\t$INC{'App/Ack.pm'} is $App::Ack::VERSION" );
    }

    # Do preliminary arg checking;
    my $env_is_usable = 1;
    for ( @ARGV ) {
        last if ( $_ eq '--' );

        # Priorities! Get the --thpppt checking out of the way.
        /^--th[pt]+t+$/ && App::Ack::_thpppt($_);

        # See if we want to ignore the environment. (Don't tell Al Gore.)
        if ( $_ eq '--noenv' ) {
            my @keys = ( 'ACKRC', grep { /^ACK_/ } keys %ENV );
            delete @ENV{@keys};
            $env_is_usable = 0;
        }
    }
    unshift( @ARGV, App::Ack::read_ackrc() ) if $env_is_usable;
    App::Ack::load_colors();

    if ( exists $ENV{ACK_SWITCHES} ) {
        App::Ack::warn( 'ACK_SWITCHES is no longer supported.  Use ACK_OPTIONS.' );
    }

    if ( !@ARGV ) {
        App::Ack::show_help();
        exit 1;
    }

    main();
}

sub main {
    my $opt = App::Ack::get_command_line_options();

    $| = 1 if $opt->{flush}; # Unbuffer the output if flush mode

    if ( App::Ack::input_from_pipe() ) {
        # We're going into filter mode
        for ( qw( f g l ) ) {
            $opt->{$_} and App::Ack::die( "Can't use -$_ when acting as a filter." );
        }
        $opt->{show_filename} = 0;
        $opt->{regex} = App::Ack::build_regex( defined $opt->{regex} ? $opt->{regex} : shift @ARGV, $opt );
        if ( my $nargs = @ARGV ) {
            my $s = $nargs == 1 ? '' : 's';
            App::Ack::warn( "Ignoring $nargs argument$s on the command-line while acting as a filter." );
        }
        my $res = App::Ack::Resource::Basic->new( '-' );
        App::Ack::search_resource( $res, $opt );
        $res->close();
        exit 0;
    }

    my $file_matching = $opt->{f} || $opt->{lines};
    if ( !$file_matching ) {
        @ARGV or App::Ack::die( 'No regular expression found.' );
        $opt->{regex} = App::Ack::build_regex( defined $opt->{regex} ? $opt->{regex} : shift @ARGV, $opt );
    }

    # check that all regexes do compile fine
    App::Ack::check_regex( $_ ) for ( $opt->{regex}, $opt->{G} );

    my $what = App::Ack::get_starting_points( \@ARGV, $opt );
    my $iter = App::Ack::get_iterator( $what, $opt );
    App::Ack::filetype_setup();

    my $nmatches = 0;

    App::Ack::set_up_pager( $opt->{pager} ) if defined $opt->{pager};
    if ( $opt->{f} ) {
        $nmatches = App::Ack::print_files( $iter, $opt );
    }
    elsif ( $opt->{l} || $opt->{count} ) {
        $nmatches = App::Ack::print_files_with_matches( $iter, $opt );
    }
    else {
        $nmatches = App::Ack::print_matches( $iter, $opt );
    }
    close $App::Ack::fh;
    exit ($nmatches ? 0 : 1);
}

=head1 NAME

ack - grep-like text finder

=head1 SYNOPSIS

    ack [options] PATTERN [FILE...]
    ack -f [options] [DIRECTORY...]

=head1 DESCRIPTION

Ack is designed as a replacement for 99% of the uses of F<grep>.

Ack searches the named input FILEs (or standard input if no files are
named, or the file name - is given) for lines containing a match to the
given PATTERN.  By default, ack prints the matching lines.

Ack can also list files that would be searched, without actually searching
them, to let you take advantage of ack's file-type filtering capabilities.

=head1 FILE SELECTION

I<ack> is intelligent about the files it searches.  It knows about
certain file types, based on both the extension on the file and,
in some cases, the contents of the file.  These selections can be
made with the B<--type> option.

With no file selections, I<ack> only searches files of types that
it recognizes.  If you have a file called F<foo.wango>, and I<ack>
doesn't know what a .wango file is, I<ack> won't search it.

The B<-a> option tells I<ack> to select all files, regardless of
type.

Some files will never be selected by I<ack>, even with B<-a>,
including:

=over 4

=item * Backup files: Files ending with F<~>, or F<#*#>

=item * Coredumps: Files matching F<core.\d+>

=back

However, I<ack> always searches the files given on the command line,
no matter what type. Furthermore, by specifying the B<-u> option all
files will be searched.

=head1 DIRECTORY SELECTION

I<ack> descends through the directory tree of the starting directories
specified.  However, it will ignore the shadow directories used by
many version control systems, and the build directories used by the
Perl MakeMaker system.  You may add or remove a directory from this
list with the B<--[no]ignore-dir> option. The option may be repeated
to add/remove multiple directories from the ignore list.

For a complete list of directories that do not get searched, run
F<ack --help>.

=head1 WHEN TO USE GREP

I<ack> trumps I<grep> as an everyday tool 99% of the time, but don't
throw I<grep> away, because there are times you'll still need it.

E.g., searching through huge files looking for regexes that can be
expressed with I<grep> syntax should be quicker with I<grep>.

If your script or parent program uses I<grep> C<--quiet> or
C<--silent> or needs exit 2 on IO error, use I<grep>.

=head1 OPTIONS

=over 4

=item B<-a>, B<--all>

Operate on all files, regardless of type (but still skip directories
like F<blib>, F<CVS>, etc.)

=item B<-A I<NUM>>, B<--after-context=I<NUM>>

Print I<NUM> lines of trailing context after matching lines.

=item B<-B I<NUM>>, B<--before-context=I<NUM>>

Print I<NUM> lines of leading context before matching lines.

=item B<-C [I<NUM>]>, B<--context[=I<NUM>]>

Print I<NUM> lines (default 2) of context around matching lines.

=item B<-c>, B<--count>

Suppress normal output; instead print a count of matching lines for
each input file.  If B<-l> is in effect, it will only show the
number of lines for each file that has lines matching.  Without
B<-l>, some line counts may be zeroes.

=item B<--color>, B<--nocolor>

B<--color> highlights the matching text.  B<--nocolor> supresses
the color.  This is on by default unless the output is redirected.

On Windows, this option is off by default unless the
L<Win32::Console::ANSI> module is installed or the C<ACK_PAGER_COLOR>
environment variable is used.

=item B<--color-filename=I<color>>

Sets the color to be used for filenames.

=item B<--color-match=I<color>>

Sets the color to be used for matches.

=item B<--column>

Show the column number of the first match.  This is helpful for editors
that can place your cursor at a given position.

=item B<--env>, B<--noenv>

B<--noenv> disables all environment processing. No F<.ackrc> is read
and all environment variables are ignored. By default, F<ack> considers
F<.ackrc> and settings in the environment.

=item B<--flush>

B<--flush> flushes output immediately.  This is off by default
unless ack is running interactively (when output goes to a pipe
or file).

=item B<-f>

Only print the files that would be searched, without actually doing
any searching.  PATTERN must not be specified, or it will be taken as
a path to search.

=item B<--follow>, B<--nofollow>

Follow or don't follow symlinks, other than whatever starting files
or directories were specified on the command line.

This is off by default.

=item B<-G I<REGEX>>

Only paths matching I<REGEX> are included in the search.  The entire
path and filename are matched against I<REGEX>, and I<REGEX> is a
Perl regular expression, not a shell glob.

The options B<-i>, B<-w>, B<-v>, and B<-Q> do not apply to this I<REGEX>.

=item B<-g I<REGEX>>

Print files where the relative path + filename matches I<REGEX>. This option is
a convenience shortcut for B<-f> B<-G I<REGEX>>.

The options B<-i>, B<-w>, B<-v>, and B<-Q> do not apply to this I<REGEX>.

=item B<--group>, B<--nogroup>

B<--group> groups matches by file name with.  This is the default when
used interactively.

B<--nogroup> prints one result per line, like grep.  This is the default
when output is redirected.

=item B<-H>, B<--with-filename>

Print the filename for each match.

=item B<-h>, B<--no-filename>

Suppress the prefixing of filenames on output when multiple files are
searched.

=item B<--help>

Print a short help statement.

=item B<-i>, B<--ignore-case>

Ignore case in the search strings.

This applies only to the PATTERN, not to the regexes given for the B<-g>
and B<-G> options.

=item B<--[no]ignore-dir=DIRNAME>

Ignore directory (as CVS, .svn, etc are ignored). May be used multiple times
to ignore multiple directories. For example, mason users may wish to include
B<--ignore-dir=data>. The B<--noignore-dir> option allows users to search
directories which would normally be ignored (perhaps to research the contents
of F<.svn/props> directories).

=item B<--line=I<NUM>>

Only print line I<NUM> of each file. Multiple lines can be given with multiple
B<--line> options or as a comma separated list (B<--line=3,5,7>). B<--line=4-7>
also works. The lines are always output in ascending order, no matter the
order given on the command line.

=item B<-l>, B<--files-with-matches>

Only print the filenames of matching files, instead of the matching text.

=item B<-L>, B<--files-without-matches>

Only print the filenames of files that do I<NOT> match. This is equivalent
to specifying B<-l> and B<-v>.

=item B<--match I<REGEX>>

Specify the I<REGEX> explicitly. This is helpful if you don't want to put the
regex as your first argument, e.g. when executing multiple searches over the
same set of files.

    # search for foo and bar in given files
    ack file1 t/file* --match foo
    ack file1 t/file* --match bar

=item B<-m=I<NUM>>, B<--max-count=I<NUM>>

Stop reading a file after I<NUM> matches.

=item B<--man>

Print this manual page.

=item B<-n>

No descending into subdirectories.

=item B<-o>

Show only the part of each line matching PATTERN (turns off text
highlighting)

=item B<--output=I<expr>>

Output the evaluation of I<expr> for each line (turns off text
highlighting)

=item B<--pager=I<program>>

Direct ack's output through I<program>.  This can also be specified
via the C<ACK_PAGER> and C<ACK_PAGER_COLOR> environment variables.

Using --pager does not suppress grouping and coloring like piping
output on the command-line does.

=item B<--passthru>

Prints all lines, whether or not they match the expression.  Highlighting
will still work, though, so it can be used to highlight matches while
still seeing the entire file, as in:

    # Watch a log file, and highlight a certain IP address
    $ tail -f ~/access.log | ack --passthru 123.45.67.89

=item B<--print0>

Only works in conjunction with -f, -g, -l or -c (filename output). The filenames
are output separated with a null byte instead of the usual newline. This is
helpful when dealing with filenames that contain whitespace, e.g.

    # remove all files of type html
    ack -f --html --print0 | xargs -0 rm -f

=item B<-Q>, B<--literal>

Quote all metacharacters in PATTERN, it is treated as a literal.

This applies only to the PATTERN, not to the regexes given for the B<-g>
and B<-G> options.

=item B<--smart-case>, B<--no-smart-case>

Ignore case in the search strings if PATTERN contains no uppercase
characters. This is similar to C<smartcase> in vim. This option is
off by default.

B<-i> always overrides this option.

This applies only to the PATTERN, not to the regexes given for the
B<-g> and B<-G> options.

=item B<--sort-files>

Sorts the found files lexically.  Use this if you want your file
listings to be deterministic between runs of I<ack>.

=item B<--thpppt>

Display the all-important Bill The Cat logo.  Note that the exact
spelling of B<--thpppppt> is not important.  It's checked against
a regular expression.

=item B<--type=TYPE>, B<--type=noTYPE>

Specify the types of files to include or exclude from a search.
TYPE is a filetype, like I<perl> or I<xml>.  B<--type=perl> can
also be specified as B<--perl>, and B<--type=noperl> can be done
as B<--noperl>.

If a file is of both type "foo" and "bar", specifying --foo and
--nobar will exclude the file, because an exclusion takes precedence
over an inclusion.

Type specifications can be repeated and are ORed together.

See I<ack --help=types> for a list of valid types.

=item B<--type-add I<TYPE>=I<.EXTENSION>[,I<.EXT2>[,...]]>

Files with the given EXTENSION(s) are recognized as being of (the
existing) type TYPE. See also L</"Defining your own types">.


=item B<--type-set I<TYPE>=I<.EXTENSION>[,I<.EXT2>[,...]]>

Files with the given EXTENSION(s) are recognized as being of type
TYPE. This replaces an existing definition for type TYPE.  See also
L</"Defining your own types">.

=item B<-u>, B<--unrestricted>

All files and directories (including blib/, core.*, ...) are searched,
nothing is skipped. When both B<-u> and B<--ignore-dir> are used, the
B<--ignore-dir> option has no effect.

=item B<-v>, B<--invert-match>

Invert match: select non-matching lines

This applies only to the PATTERN, not to the regexes given for the B<-g>
and B<-G> options.

=item B<--version>

Display version and copyright information.

=item B<-w>, B<--word-regexp>

Force PATTERN to match only whole words.  The PATTERN is wrapped with
C<\b> metacharacters.

This applies only to the PATTERN, not to the regexes given for the B<-g>
and B<-G> options.

=item B<-1>

Stops after reporting first match of any kind.  This is different
from B<--max-count=1> or B<-m1>, where only one match per file is
shown.  Also, B<-1> works with B<-f> and B<-g>, where B<-m> does
not.

=back

=head1 THE .ackrc FILE

The F<.ackrc> file contains command-line options that are prepended
to the command line before processing.  Multiple options may live
on multiple lines.  Lines beginning with a # are ignored.  A F<.ackrc>
might look like this:

    # Always sort the files
    --sort-files

    # Always color, even if piping to a another program
    --color

    # Use "less -r" as my pager
    --pager=less -r

Note that arguments with spaces in them do not need to be quoted,
as they are not interpreted by the shell. Basically, each I<line>
in the F<.ackrc> file is interpreted as one element of C<@ARGV>.

F<ack> looks in your home directory for the F<.ackrc>.  You can
specify another location with the F<ACKRC> variable, below.

If B<--noenv> is specified on the command line, the F<.ackrc> file
is ignored.

=head1 Defining your own types

ack allows you to define your own types in addition to the predefined
types. This is done with command line options that are best put into
an F<.ackrc> file - then you do not have to define your types over and
over again. In the following examples the options will always be shown
on one command line so that they can be easily copy & pasted.

I<ack --perl foo> searches for foo in all perl files. I<ack --help=types>
tells you, that perl files are files ending
in .pl, .pm, .pod or .t. So what if you would like to include .xs
files as well when searching for --perl files? I<ack --type-add perl=.xs --perl foo>
does this for you. B<--type-add> appends
additional extensions to an existing type.

If you want to define a new type, or completely redefine an existing
type, then use B<--type-set>. I<ack --type-set
eiffel=.e,.eiffel> defines the type I<eiffel> to include files with
the extensions .e or .eiffel. So to search for all eiffel files
containing the word Bertrand use I<ack --type-set eiffel=.e,.eiffel --eiffel Bertrand>.
As usual, you can also write B<--type=eiffel>
instead of B<--eiffel>. Negation also works, so B<--noeiffel> excludes
all eiffel files from a search. Redefining also works: I<ack --type-set cc=.c,.h>
and I<.xs> files no longer belong to the type I<cc>.

When defining your own types in the F<.ackrc> file you have to use
the following:

  --type-set=eiffel=.e,.eiffel

or writing on separate lines

  --type-set
  eiffel=.e,.eiffel

The following does B<NOT> work in the F<.ackrc> file:

  --type-set eiffel=.e,.eiffel


In order to see all currently defined types, use I<--help types>, e.g.
I<ack --type-set backup=.bak --type-add perl=.perl --help types>

Restrictions:

=over 4

=item

The types 'skipped', 'make', 'binary' and 'text' are considered "builtin" and
cannot be altered.

=item

The shebang line recognition of the types 'perl', 'ruby', 'php', 'python',
'shell' and 'xml' cannot be redefined by I<--type-set>, it is always
active. However, the shebang line is only examined for files where the
extension is not recognised. Therefore it is possible to say
I<ack --type-set perl=.perl --type-set foo=.pl,.pm,.pod,.t --perl --nofoo> and
only find your shiny new I<.perl> files (and all files with unrecognized extension
and perl on the shebang line).

=back

=head1 ENVIRONMENT VARIABLES

For commonly-used ack options, environment variables can make life much easier.
These variables are ignored if B<--noenv> is specified on the command line.

=over 4

=item ACKRC

Specifies the location of the F<.ackrc> file.  If this file doesn't
exist, F<ack> looks in the default location.

=item ACK_OPTIONS

This variable specifies default options to be placed in front of
any explicit options on the command line.

=item ACK_COLOR_FILENAME

Specifies the color of the filename when it's printed in B<--group>
mode.  By default, it's "bold green".

The recognized attributes are clear, reset, dark, bold, underline,
underscore, blink, reverse, concealed black, red, green, yellow,
blue, magenta, on_black, on_red, on_green, on_yellow, on_blue,
on_magenta, on_cyan, and on_white.  Case is not significant.
Underline and underscore are equivalent, as are clear and reset.
The color alone sets the foreground color, and on_color sets the
background color.

This option can also be set with B<--color-filename>.

=item ACK_COLOR_MATCH

Specifies the color of the matching text when printed in B<--color>
mode.  By default, it's "black on_yellow".

This option can also be set with B<--color-match>.

See B<ACK_COLOR_FILENAME> for the color specifications.

=item ACK_PAGER

Specifies a pager program, such as C<more>, C<less> or C<most>, to which
ack will send its output.

Using C<ACK_PAGER> does not suppress grouping and coloring like
piping output on the command-line does, except that on Windows
ack will assume that C<ACK_PAGER> does not support color.

C<ACK_PAGER_COLOR> overrides C<ACK_PAGER> if both are specified.

=item ACK_PAGER_COLOR

Specifies a pager program that understands ANSI color sequences.
Using C<ACK_PAGER_COLOR> does not suppress grouping and coloring
like piping output on the command-line does.

If you are not on Windows, you never need to use C<ACK_PAGER_COLOR>.

=back

=head1 ACK & OTHER TOOLS

=head2 Vim integration

F<ack> integrates easily with the Vim text editor. Set this in your
F<.vimrc> to use F<ack> instead of F<grep>:

    set grepprg=ack\ -a

That examples uses C<-a> to search through all files, but you may
use other default flags. Now you can search with F<ack> and easily
step through the results in Vim:

  :grep Dumper perllib

=head2 Emacs integration

Phil Jackson put together an F<ack.el> extension that "provides a
simple compilation mode ... has the ability to guess what files you
want to search for based on the major-mode."

L<http://www.shellarchive.co.uk/content/emacs.html>

=head2 TextMate integration

Pedro Melo is a TextMate user who writes "I spend my day mostly
inside TextMate, and the built-in find-in-project sucks with large
projects.  So I hacked a TextMate command that was using find +
grep to use ack.  The result is the Search in Project with ack, and
you can find it here:
L<http://www.simplicidade.org/notes/archives/2008/03/search_in_proje.html>"

=head2 Shell and Return Code

For greater compatibility with I<grep>, I<ack> in normal use returns
shell return or exit code of 0 only if something is found and 1 if
no match is found.

(Shell exit code 1 is C<$?=256> in perl with C<system> or backticks.)

The I<grep> code 2 for errors is not used.

If C<-f> or C<-g> are specified, then 0 is returned if at least one
file is found.  If no files are found, then 1 is returned.

=cut

=head1 DEBUGGING ACK PROBLEMS

If ack gives you output you're not expecting, start with a few simple steps.

=head2 Use B<--noenv>

Your environment variables and F<.ackrc> may be doing things you're
not expecting, or forgotten you specified.  Use B<--noenv> to ignore
your environment and F<.ackrc>.

=head2 Use B<-f> to see what files you're scanning

The reason I created B<-f> in the first place was as a debugging
tool.  If ack is not finding matches you think it should find, run
F<ack -f> to see what files are being checked.

=head1 TIPS

=head2 Use the F<.ackrc> file.

The F<.ackrc> is the place to put all your options you use most of
the time but don't want to remember.  Put all your --type-add and
--type-set definitions in it.  If you like --smart-case, set it
there, too.  I also set --sort-files there.

=head2 Use F<-f> for working with big codesets

Ack does more than search files.  C<ack -f --perl> will create a
list of all the Perl files in a tree, ideal for sending into F<xargs>.
For example:

    # Change all "this" to "that" in all Perl files in a tree.
    ack -f --perl | xargs perl -p -i -e's/this/that/g'

or if you prefer:

    perl -p -i -e's/this/thatg/' $(ack -f --perl)

=head2 Use F<-Q> when in doubt about metacharacters

If you're searching for something with a regular expression
metacharacter, most often a period in a filename or IP address, add
the -Q to avoid false positives without all the backslashing.  See
the following example for more...

=head2 Use ack to watch log files

Here's one I used the other day to find trouble spots for a website
visitor.  The user had a problem loading F<troublesome.gif>, so I
took the access log and scanned it with ack twice.

    ack -Q aa.bb.cc.dd /path/to/access.log | ack -Q -B5 troublesome.gif

The first ack finds only the lines in the Apache log for the given
IP.  The second finds the match on my troublesome GIF, and shows
the previous five lines from the log in each case.

=head2 Share your knowledge

Join the ack-users mailing list.  Send me your tips and I may add
them here.

=head1 FAQ

=head2 Why isn't ack finding a match in (some file)?

Probably because it's of a type that ack doesn't recognize.

ack's searching behavior is driven by filetype.  If ack doesn't
know what kind of file it is, ack ignores it.

If you want ack to search files that it doesn't recognize, use the
C<-a> switch.

If you want ack to search every file, even ones that it always
ignores like coredumps and backup files, use the C<-u> switch.

=head2 Why does ack ignore unknown files by default?

Because most codebases have a lot files in them which aren't source
files (like compiled object files, source control metadata, etc),
and grep wastes a lot of time searching through all of those as
well and returning matches from those files.  In my personal
experience (and everyone's experience varies) files without extensions
tend not to be source/program metadata files, and THAT'S why ack's
behaviour of not searching things it doesn't recognize is one of
its greatest strengths: the speed you get from only searching the
things that you want to be looking at.

Since making it search everything by default out of the box would
remove one of the best differentiators from grep that ack has, and
since turning on "search everything" is a mere two characters in
an .ackrc file away from being someone's PERSONAL default behaviour,
I can understand Andy's adamance that ack's search behaviour remain
the way it is.

=head2 Wouldn't it be great if F<ack> did search & replace?

No, ack will always be read-only.  Perl has a perfectly good way
to do search & replace in files, using the C<-i>, C<-p> and C<-n>
switches.

You can certainly use ack to select your files to update.  For
example, to change all "foo" to "bar" in all PHP files, you can do
this form the Unix shell:

    $ perl -i -p -e's/foo/bar/g' $(ack -f --php)



=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to the issues list at
Google Code: L<http://code.google.com/p/ack/issues/list>

=head1 ENHANCEMENTS

All enhancement requests MUST first be posted to the ack-users
mailing list at L<http://groups.google.com/group/ack-users>.  I
will not consider a request without it first getting seen by other
ack users.

There is a list of enhancements I want to make to F<ack> in the ack
issues list at Google Code: L<http://code.google.com/p/ack/issues/list>

Patches are always welcome, but patches with tests get the most
attention.

=head1 SUPPORT

Support for and information about F<ack> can be found at:

=over 4

=item * The ack homepage

L<http://betterthangrep.com/>

=item * The ack issues list at Google Code

L<http://code.google.com/p/ack/issues/list>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ack>

=item * Search CPAN

L<http://search.cpan.org/dist/ack>

=item * Git source repository

L<http://github.com/petdance/ack>

=back

=head1 ACKNOWLEDGEMENTS

How appropriate to have I<ack>nowledgements!

Thanks to everyone who has contributed to ack in any way, including
JR Boyens,
Dan Sully,
Ryan Niebur,
Kent Fredric,
Mike Morearty,
Ingmar Vanhassel,
Eric Van Dewoestine,
Sitaram Chamarty,
Adam James,
Richard Carlsson,
Pedro Melo,
AJ Schuster,
Phil Jackson,
Michael Schwern,
Jan Dubois,
Christopher J. Madsen,
Matthew Wickline,
David Dyck,
Jason Porritt,
Jjgod Jiang,
Thomas Klausner,
Uri Guttman,
Peter Lewis,
Kevin Riggle,
Ori Avtalion,
Torsten Blix,
Nigel Metheringham,
GE<aacute>bor SzabE<oacute>,
Tod Hagan,
Michael Hendricks,
E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason,
Piers Cawley,
Stephen Steneker,
Elias Lutfallah,
Mark Leighton Fisher,
Matt Diephouse,
Christian Jaeger,
Bill Sully,
Bill Ricker,
David Golden,
Nilson Santos F. Jr,
Elliot Shank,
Merijn Broeren,
Uwe Voelker,
Rick Scott,
Ask BjE<oslash>rn Hansen,
Jerry Gay,
Will Coleda,
Mike O'Regan,
Slaven ReziE<0x107>,
Mark Stosberg,
David Alan Pisoni,
Adriano Ferreira,
James Keenan,
Leland Johnson,
Ricardo Signes
and Pete Krawczyk.

=head1 COPYRIGHT & LICENSE

Copyright 2005-2009 Andy Lester.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any later
version, or

=item * the Artistic License version 2.0.

=back

=cut
package File::Next;

use strict;
use warnings;


our $VERSION = '1.06';



use File::Spec ();


our $name; # name of the current file
our $dir;  # dir of the current file

our %files_defaults;
our %skip_dirs;

BEGIN {
    %files_defaults = (
        file_filter     => undef,
        descend_filter  => undef,
        error_handler   => sub { CORE::die @_ },
        sort_files      => undef,
        follow_symlinks => 1,
    );
    %skip_dirs = map {($_,1)} (File::Spec->curdir, File::Spec->updir);
}


sub files {
    ($_[0] eq __PACKAGE__) && die 'File::Next::files must not be invoked as File::Next->files';

    my ($parms,@queue) = _setup( \%files_defaults, @_ );
    my $filter = $parms->{file_filter};

    return sub {
        while (@queue) {
            my ($dir,$file,$fullpath) = splice( @queue, 0, 3 );
            if ( -f $fullpath ) {
                if ( $filter ) {
                    local $_ = $file;
                    local $File::Next::dir = $dir;
                    local $File::Next::name = $fullpath;
                    next if not $filter->();
                }
                return wantarray ? ($dir,$file,$fullpath) : $fullpath;
            }
            elsif ( -d _ ) {
                unshift( @queue, _candidate_files( $parms, $fullpath ) );
            }
        } # while

        return;
    }; # iterator
}







sub sort_standard($$)   { return $_[0]->[1] cmp $_[1]->[1] }
sub sort_reverse($$)    { return $_[1]->[1] cmp $_[0]->[1] }

sub reslash {
    my $path = shift;

    my @parts = split( /\//, $path );

    return $path if @parts < 2;

    return File::Spec->catfile( @parts );
}



sub _setup {
    my $defaults = shift;
    my $passed_parms = ref $_[0] eq 'HASH' ? {%{+shift}} : {}; # copy parm hash

    my %passed_parms = %{$passed_parms};

    my $parms = {};
    for my $key ( keys %{$defaults} ) {
        $parms->{$key} =
            exists $passed_parms{$key}
                ? delete $passed_parms{$key}
                : $defaults->{$key};
    }

    # Any leftover keys are bogus
    for my $badkey ( keys %passed_parms ) {
        my $sub = (caller(1))[3];
        $parms->{error_handler}->( "Invalid option passed to $sub(): $badkey" );
    }

    # If it's not a code ref, assume standard sort
    if ( $parms->{sort_files} && ( ref($parms->{sort_files}) ne 'CODE' ) ) {
        $parms->{sort_files} = \&sort_standard;
    }
    my @queue;

    for ( @_ ) {
        my $start = reslash( $_ );
        if (-d $start) {
            push @queue, ($start,undef,$start);
        }
        else {
            push @queue, (undef,$start,$start);
        }
    }

    return ($parms,@queue);
}


sub _candidate_files {
    my $parms = shift;
    my $dir = shift;

    my $dh;
    if ( !opendir $dh, $dir ) {
        $parms->{error_handler}->( "$dir: $!" );
        return;
    }

    my @newfiles;
    my $descend_filter = $parms->{descend_filter};
    my $follow_symlinks = $parms->{follow_symlinks};
    my $sort_sub = $parms->{sort_files};

    for my $file ( grep { !exists $skip_dirs{$_} } readdir $dh ) {
        my $has_stat;

        # Only do directory checking if we have a descend_filter
        my $fullpath = File::Spec->catdir( $dir, $file );
        if ( !$follow_symlinks ) {
            next if -l $fullpath;
            $has_stat = 1;
        }

        if ( $descend_filter ) {
            if ( $has_stat ? (-d _) : (-d $fullpath) ) {
                local $File::Next::dir = $fullpath;
                local $_ = $file;
                next if not $descend_filter->();
            }
        }
        if ( $sort_sub ) {
            push( @newfiles, [ $dir, $file, $fullpath ] );
        }
        else {
            push( @newfiles, $dir, $file, $fullpath );
        }
    }
    closedir $dh;

    if ( $sort_sub ) {
        return map { @{$_} } sort $sort_sub @newfiles;
    }

    return @newfiles;
}


1; # End of File::Next
package App::Ack;

use warnings;
use strict;




our $VERSION;
our $COPYRIGHT;
BEGIN {
    $VERSION = '1.90';
    $COPYRIGHT = 'Copyright 2005-2009 Andy Lester.';
}

our $fh;

BEGIN {
    $fh = *STDOUT;
}


our %types;
our %type_wanted;
our %mappings;
our %ignore_dirs;

our $input_from_pipe;
our $output_to_pipe;

our $dir_sep_chars;
our $is_cygwin;
our $is_windows;

use File::Spec ();
use File::Glob ':glob';
use Getopt::Long ();

BEGIN {
    %ignore_dirs = (
        '.bzr'              => 'Bazaar',
        '.cdv'              => 'Codeville',
        '~.dep'             => 'Interface Builder',
        '~.dot'             => 'Interface Builder',
        '~.nib'             => 'Interface Builder',
        '~.plst'            => 'Interface Builder',
        '.git'              => 'Git',
        '.hg'               => 'Mercurial',
        '.pc'               => 'quilt',
        '.svn'              => 'Subversion',
        blib                => 'Perl module building',
        CVS                 => 'CVS',
        RCS                 => 'RCS',
        SCCS                => 'SCCS',
        _darcs              => 'darcs',
        _sgbak              => 'Vault/Fortress',
        'autom4te.cache'    => 'autoconf',
        'cover_db'          => 'Devel::Cover',
        _build              => 'Module::Build',
    );

    %mappings = (
        actionscript => [qw( as mxml )],
        ada         => [qw( ada adb ads )],
        asm         => [qw( asm s )],
        batch       => [qw( bat cmd )],
        binary      => q{Binary files, as defined by Perl's -B op (default: off)},
        cc          => [qw( c h xs )],
        cfmx        => [qw( cfc cfm cfml )],
        cpp         => [qw( cpp cc cxx m hpp hh h hxx )],
        csharp      => [qw( cs )],
        css         => [qw( css )],
        elisp       => [qw( el )],
        erlang      => [qw( erl hrl )],
        fortran     => [qw( f f77 f90 f95 f03 for ftn fpp )],
        haskell     => [qw( hs lhs )],
        hh          => [qw( h )],
        html        => [qw( htm html shtml xhtml )],
        java        => [qw( java properties )],
        js          => [qw( js )],
        jsp         => [qw( jsp jspx jhtm jhtml )],
        lisp        => [qw( lisp lsp )],
        lua         => [qw( lua )],
        make        => q{Makefiles},
        mason       => [qw( mas mhtml mpl mtxt )],
        objc        => [qw( m h )],
        objcpp      => [qw( mm h )],
        ocaml       => [qw( ml mli )],
        parrot      => [qw( pir pasm pmc ops pod pg tg )],
        perl        => [qw( pl pm pod t )],
        php         => [qw( php phpt php3 php4 php5 )],
        plone       => [qw( pt cpt metadata cpy py )],
        python      => [qw( py )],
        rake        => q{Rakefiles},
        ruby        => [qw( rb rhtml rjs rxml erb rake )],
        scala       => [qw( scala )],
        scheme      => [qw( scm ss )],
        shell       => [qw( sh bash csh tcsh ksh zsh )],
        skipped     => q{Files, but not directories, normally skipped by ack (default: off)},
        smalltalk   => [qw( st )],
        sql         => [qw( sql ctl )],
        tcl         => [qw( tcl itcl itk )],
        tex         => [qw( tex cls sty )],
        text        => q{Text files, as defined by Perl's -T op (default: off)},
        tt          => [qw( tt tt2 ttml )],
        vb          => [qw( bas cls frm ctl vb resx )],
        vim         => [qw( vim )],
        yaml        => [qw( yaml yml )],
        xml         => [qw( xml dtd xslt ent )],
    );

    while ( my ($type,$exts) = each %mappings ) {
        if ( ref $exts ) {
            for my $ext ( @{$exts} ) {
                push( @{$types{$ext}}, $type );
            }
        }
    }

    # These have to be checked before any filehandle diddling.
    $output_to_pipe  = not -t *STDOUT;
    $input_from_pipe = -p STDIN;

    $is_cygwin       = ($^O eq 'cygwin');
    $is_windows      = ($^O =~ /MSWin32/);
    $dir_sep_chars   = $is_windows ? quotemeta( '\\/' ) : quotemeta( File::Spec->catfile( '', '' ) );
}


sub read_ackrc {
    my @files = ( $ENV{ACKRC} );
    my @dirs =
        $is_windows
            ? ( $ENV{HOME}, $ENV{USERPROFILE} )
            : ( '~', $ENV{HOME} );
    for my $dir ( grep { defined } @dirs ) {
        for my $file ( '.ackrc', '_ackrc' ) {
            push( @files, bsd_glob( "$dir/$file", GLOB_TILDE ) );
        }
    }
    for my $filename ( @files ) {
        if ( defined $filename && -e $filename ) {
            open( my $fh, '<', $filename ) or App::Ack::die( "$filename: $!\n" );
            my @lines = grep { /./ && !/^\s*#/ } <$fh>;
            chomp @lines;
            close $fh or App::Ack::die( "$filename: $!\n" );

            return @lines;
        }
    }

    return;
}


sub get_command_line_options {
    my %opt = (
        pager => $ENV{ACK_PAGER_COLOR} || $ENV{ACK_PAGER},
    );

    my $getopt_specs = {
        1                       => sub { $opt{1} = $opt{m} = 1 },
        'A|after-context=i'     => \$opt{after_context},
        'B|before-context=i'    => \$opt{before_context},
        'C|context:i'           => sub { shift; my $val = shift; $opt{before_context} = $opt{after_context} = ($val || 2) },
        'a|all-types'           => \$opt{all},
        'break!'                => \$opt{break},
        c                       => \$opt{count},
        'color|colour!'         => \$opt{color},
        'color-match=s'         => \$ENV{ACK_COLOR_MATCH},
        'color-filename=s'      => \$ENV{ACK_COLOR_FILENAME},
        'column!'               => \$opt{column},
        count                   => \$opt{count},
        'env!'                  => sub { }, # ignore this option, it is handled beforehand
        f                       => \$opt{f},
        flush                   => \$opt{flush},
        'follow!'               => \$opt{follow},
        'g=s'                   => sub { shift; $opt{G} = shift; $opt{f} = 1 },
        'G=s'                   => \$opt{G},
        'group!'                => sub { shift; $opt{heading} = $opt{break} = shift },
        'heading!'              => \$opt{heading},
        'h|no-filename'         => \$opt{h},
        'H|with-filename'       => \$opt{H},
        'i|ignore-case'         => \$opt{i},
        'lines=s'               => sub { shift; my $val = shift; push @{$opt{lines}}, $val },
        'l|files-with-matches'  => \$opt{l},
        'L|files-without-matches' => sub { $opt{l} = $opt{v} = 1 },
        'm|max-count=i'         => \$opt{m},
        'match=s'               => \$opt{regex},
        'n|no-recurse'          => \$opt{n},
        o                       => sub { $opt{output} = '$&' },
        'output=s'              => \$opt{output},
        'pager=s'               => \$opt{pager},
        'nopager'               => sub { $opt{pager} = undef },
        'passthru'              => \$opt{passthru},
        'print0'                => \$opt{print0},
        'Q|literal'             => \$opt{Q},
        'r|R|recurse'           => sub {},
        'smart-case!'           => \$opt{smart_case},
        'sort-files'            => \$opt{sort_files},
        'u|unrestricted'        => \$opt{u},
        'v|invert-match'        => \$opt{v},
        'w|word-regexp'         => \$opt{w},

        'ignore-dirs=s'         => sub { shift; my $dir = remove_dir_sep( shift ); $ignore_dirs{$dir} = '--ignore-dirs' },
        'noignore-dirs=s'       => sub { shift; my $dir = remove_dir_sep( shift ); delete $ignore_dirs{$dir} },

        'version'   => sub { print_version_statement(); exit 1; },
        'help|?:s'  => sub { shift; show_help(@_); exit; },
        'help-types'=> sub { show_help_types(); exit; },
        'man'       => sub { require Pod::Usage; Pod::Usage::pod2usage({-verbose => 2}); exit; },

        'type=s'    => sub {
            # Whatever --type=xxx they specify, set it manually in the hash
            my $dummy = shift;
            my $type = shift;
            my $wanted = ($type =~ s/^no//) ? 0 : 1; # must not be undef later

            if ( exists $type_wanted{ $type } ) {
                $type_wanted{ $type } = $wanted;
            }
            else {
                App::Ack::die( qq{Unknown --type "$type"} );
            }
        }, # type sub
    };

    # Stick any default switches at the beginning, so they can be overridden
    # by the command line switches.
    unshift @ARGV, split( ' ', $ENV{ACK_OPTIONS} ) if defined $ENV{ACK_OPTIONS};

    # first pass through options, looking for type definitions
    def_types_from_ARGV();

    for my $i ( filetypes_supported() ) {
        $getopt_specs->{ "$i!" } = \$type_wanted{ $i };
    }


    my $parser = Getopt::Long::Parser->new();
    $parser->configure( 'bundling', 'no_ignore_case', );
    $parser->getoptions( %{$getopt_specs} ) or
        App::Ack::die( 'See ack --help or ack --man for options.' );

    my $to_screen = not output_to_pipe();
    my %defaults = (
        all            => 0,
        color          => $to_screen,
        follow         => 0,
        break          => $to_screen,
        heading        => $to_screen,
        before_context => 0,
        after_context  => 0,
    );
    if ( $is_windows && $defaults{color} && not $ENV{ACK_PAGER_COLOR} ) {
        if ( $ENV{ACK_PAGER} || not eval { require Win32::Console::ANSI } ) {
            $defaults{color} = 0;
        }
    }
    if ( $to_screen && $ENV{ACK_PAGER_COLOR} ) {
        $defaults{color} = 1;
    }

    while ( my ($key,$value) = each %defaults ) {
        if ( not defined $opt{$key} ) {
            $opt{$key} = $value;
        }
    }

    if ( defined $opt{m} && $opt{m} <= 0 ) {
        App::Ack::die( '-m must be greater than zero' );
    }

    for ( qw( before_context after_context ) ) {
        if ( defined $opt{$_} && $opt{$_} < 0 ) {
            App::Ack::die( "--$_ may not be negative" );
        }
    }

    if ( defined( my $val = $opt{output} ) ) {
        $opt{output} = eval qq[ sub { "$val" } ];
    }
    if ( defined( my $l = $opt{lines} ) ) {
        # --line=1 --line=5 is equivalent to --line=1,5
        my @lines = split( /,/, join( ',', @{$l} ) );

        # --line=1-3 is equivalent to --line=1,2,3
        @lines = map {
            my @ret;
            if ( /-/ ) {
                my ($from, $to) = split /-/, $_;
                if ( $from > $to ) {
                    App::Ack::warn( "ignoring --line=$from-$to" );
                    @ret = ();
                }
                else {
                    @ret = ( $from .. $to );
                }
            }
            else {
                @ret = ( $_ );
            };
            @ret
        } @lines;

        if ( @lines ) {
            my %uniq;
            @uniq{ @lines } = ();
            $opt{lines} = [ sort { $a <=> $b } keys %uniq ];   # numerical sort and each line occurs only once!
        }
        else {
            # happens if there are only ignored --line directives
            App::Ack::die( 'All --line options are invalid.' );
        }
    }

    return \%opt;
}


sub def_types_from_ARGV {
    my @typedef;

    my $parser = Getopt::Long::Parser->new();
        # pass_through   => leave unrecognized command line arguments alone
        # no_auto_abbrev => otherwise -c is expanded and not left alone
    $parser->configure( 'no_ignore_case', 'pass_through', 'no_auto_abbrev' );
    $parser->getoptions(
        'type-set=s' => sub { shift; push @typedef, ['c', shift] },
        'type-add=s' => sub { shift; push @typedef, ['a', shift] },
    ) or App::Ack::die( 'See ack --help or ack --man for options.' );

    for my $td (@typedef) {
        my ($type, $ext) = split /=/, $td->[1];

        if ( $td->[0] eq 'c' ) {
            # type-set
            if ( exists $mappings{$type} ) {
                # can't redefine types 'make', 'skipped', 'text' and 'binary'
                App::Ack::die( qq{--type-set: Builtin type "$type" cannot be changed.} )
                    if ref $mappings{$type} ne 'ARRAY';

                delete_type($type);
            }
        }
        else {
            # type-add

            # can't append to types 'make', 'skipped', 'text' and 'binary'
            App::Ack::die( qq{--type-add: Builtin type "$type" cannot be changed.} )
                if exists $mappings{$type} && ref $mappings{$type} ne 'ARRAY';

            App::Ack::warn( qq{--type-add: Type "$type" does not exist, creating with "$ext" ...} )
                unless exists $mappings{$type};
        }

        my @exts = split /,/, $ext;
        s/^\.// for @exts;

        if ( !exists $mappings{$type} || ref($mappings{$type}) eq 'ARRAY' ) {
            push @{$mappings{$type}}, @exts;
            for my $e ( @exts ) {
                push @{$types{$e}}, $type;
            }
        }
        else {
            App::Ack::die( qq{Cannot append to type "$type".} );
        }
    }

    return;
}


sub delete_type {
    my $type = shift;

    App::Ack::die( qq{Internal error: Cannot delete builtin type "$type".} )
        unless ref $mappings{$type} eq 'ARRAY';

    delete $mappings{$type};
    delete $type_wanted{$type};
    for my $ext ( keys %types ) {
        $types{$ext} = [ grep { $_ ne $type } @{$types{$ext}} ];
    }
}


sub ignoredir_filter {
    return !exists $ignore_dirs{$_};
}


sub remove_dir_sep {
    my $path = shift;
    $path =~ s/[$dir_sep_chars]$//;

    return $path;
}


use constant TEXT => 'text';

sub filetypes {
    my $filename = shift;

    return 'skipped' unless is_searchable( $filename );

    my $basename = $filename;
    $basename =~ s{.*[$dir_sep_chars]}{};

    my $lc_basename = lc $basename;
    return ('make',TEXT)        if $lc_basename eq 'makefile';
    return ('rake','ruby',TEXT) if $lc_basename eq 'rakefile';

    # If there's an extension, look it up
    if ( $filename =~ m{\.([^\.$dir_sep_chars]+)$}o ) {
        my $ref = $types{lc $1};
        return (@{$ref},TEXT) if $ref;
    }

    # At this point, we can't tell from just the name.  Now we have to
    # open it and look inside.

    return unless -e $filename;
    # From Elliot Shank:
    #     I can't see any reason that -r would fail on these-- the ACLs look
    #     fine, and no program has any of them open, so the busted Windows
    #     file locking model isn't getting in there.  If I comment the if
    #     statement out, everything works fine
    # So, for cygwin, don't bother trying to check for readability.
    if ( !$is_cygwin ) {
        if ( !-r $filename ) {
            App::Ack::warn( "$filename: Permission denied" );
            return;
        }
    }

    return 'binary' if -B $filename;

    # If there's no extension, or we don't recognize it, check the shebang line
    my $fh;
    if ( !open( $fh, '<', $filename ) ) {
        App::Ack::warn( "$filename: $!" );
        return;
    }
    my $header = <$fh>;
    close $fh;

    if ( $header =~ /^#!/ ) {
        return ($1,TEXT)       if $header =~ /\b(ruby|p(?:erl|hp|ython))\b/;
        return ('shell',TEXT)  if $header =~ /\b(?:ba|t?c|k|z)?sh\b/;
    }
    else {
        return ('xml',TEXT)    if $header =~ /\Q<?xml /i;
    }

    return (TEXT);
}


sub is_searchable {
    my $filename = shift;

    # If these are updated, update the --help message
    return if $filename =~ /[.]bak$/;
    return if $filename =~ /~$/;
    return if $filename =~ m{[$dir_sep_chars]?(?:#.+#|core\.\d+|[._].*\.swp)$}o;

    return 1;
}


sub build_regex {
    my $str = shift;
    my $opt = shift;

    $str = quotemeta( $str ) if $opt->{Q};
    if ( $opt->{w} ) {
        $str = "\\b$str" if $str =~ /^\w/;
        $str = "$str\\b" if $str =~ /\w$/;
    }

    my $regex_is_lc = $str eq lc $str;
    if ( $opt->{i} || ($opt->{smart_case} && $regex_is_lc) ) {
        $str = "(?i)$str";
    }

    return $str;
}


sub check_regex {
    my $regex = shift;

    return unless defined $regex;

    eval { qr/$regex/ };
    if ($@) {
        (my $error = $@) =~ s/ at \S+ line \d+.*//;
        chomp($error);
        App::Ack::die( "Invalid regex '$regex':\n  $error" );
    }

    return;
}




sub warn {
    return CORE::warn( _my_program(), ': ', @_, "\n" );
}


sub die {
    return CORE::die( _my_program(), ': ', @_, "\n" );
}

sub _my_program {
    require File::Basename;
    return File::Basename::basename( $0 );
}



sub filetypes_supported {
    return keys %mappings;
}

sub _get_thpppt {
    my $y = q{_   /|,\\'!.x',=(www)=,   U   };
    $y =~ tr/,x!w/\nOo_/;
    return $y;
}

sub _thpppt {
    my $y = _get_thpppt();
    App::Ack::print( "$y ack $_[0]!\n" );
    exit 0;
}

sub _key {
    my $str = lc shift;
    $str =~ s/[^a-z]//g;

    return $str;
}


sub show_help {
    my $help_arg = shift || 0;

    return show_help_types() if $help_arg =~ /^types?/;

    my $ignore_dirs = _listify( sort { _key($a) cmp _key($b) } keys %ignore_dirs );

    App::Ack::print( <<"END_OF_HELP" );
Usage: ack [OPTION]... PATTERN [FILE]

Search for PATTERN in each source file in the tree from cwd on down.
If [FILES] is specified, then only those files/directories are checked.
ack may also search STDIN, but only if no FILE are specified, or if
one of FILES is "-".

Default switches may be specified in ACK_OPTIONS environment variable or
an .ackrc file. If you want no dependency on the environment, turn it
off with --noenv.

Example: ack -i select

Searching:
  -i, --ignore-case     Ignore case distinctions in PATTERN
  --[no]smart-case      Ignore case distinctions in PATTERN,
                        only if PATTERN contains no upper case
                        Ignored if -i is specified
  -v, --invert-match    Invert match: select non-matching lines
  -w, --word-regexp     Force PATTERN to match only whole words
  -Q, --literal         Quote all metacharacters; PATTERN is literal

Search output:
  --line=NUM            Only print line(s) NUM of each file
  -l, --files-with-matches
                        Only print filenames containing matches
  -L, --files-without-matches
                        Only print filenames with no matches
  -o                    Show only the part of a line matching PATTERN
                        (turns off text highlighting)
  --passthru            Print all lines, whether matching or not
  --output=expr         Output the evaluation of expr for each line
                        (turns off text highlighting)
  --match PATTERN       Specify PATTERN explicitly.
  -m, --max-count=NUM   Stop searching in each file after NUM matches
  -1                    Stop searching after one match of any kind
  -H, --with-filename   Print the filename for each match
  -h, --no-filename     Suppress the prefixing filename on output
  -c, --count           Show number of lines matching per file
  --column              Show the column number of the first match

  -A NUM, --after-context=NUM
                        Print NUM lines of trailing context after matching
                        lines.
  -B NUM, --before-context=NUM
                        Print NUM lines of leading context before matching
                        lines.
  -C [NUM], --context[=NUM]
                        Print NUM lines (default 2) of output context.

  --print0              Print null byte as separator between filenames,
                        only works with -f, -g, -l, -L or -c.

File presentation:
  --pager=COMMAND       Pipes all ack output through COMMAND.  For example,
                        --pager="less -R".  Ignored if output is redirected.
  --nopager             Do not send output through a pager.  Cancels any
                        setting in ~/.ackrc, ACK_PAGER or ACK_PAGER_COLOR.
  --[no]heading         Print a filename heading above each file's results.
                        (default: on when used interactively)
  --[no]break           Print a break between results from different files.
                        (default: on when used interactively)
  --group               Same as --heading --break
  --nogroup             Same as --noheading --nobreak
  --[no]color           Highlight the matching text (default: on unless
                        output is redirected, or on Windows)
  --[no]colour          Same as --[no]color
  --color-filename=COLOR
  --color-match=COLOR   Set the color for matches and filenames.
  --flush               Flush output immediately, even when ack is used
                        non-interactively (when output goes to a pipe or
                        file).

File finding:
  -f                    Only print the files found, without searching.
                        The PATTERN must not be specified.
  -g REGEX              Same as -f, but only print files matching REGEX.
  --sort-files          Sort the found files lexically.

File inclusion/exclusion:
  -a, --all-types       All file types searched;
                        Ignores CVS, .svn and other ignored directories
  -u, --unrestricted    All files and directories searched
  --[no]ignore-dir=name Add/Remove directory from the list of ignored dirs
  -r, -R, --recurse     Recurse into subdirectories (ack's default behavior)
  -n, --no-recurse      No descending into subdirectories
  -G REGEX              Only search files that match REGEX

  --perl                Include only Perl files.
  --type=perl           Include only Perl files.
  --noperl              Exclude Perl files.
  --type=noperl         Exclude Perl files.
                        See "ack --help type" for supported filetypes.

  --type-set TYPE=.EXTENSION[,.EXT2[,...]]
                        Files with the given EXTENSION(s) are recognized as
                        being of type TYPE. This replaces an existing
                        definition for type TYPE.
  --type-add TYPE=.EXTENSION[,.EXT2[,...]]
                        Files with the given EXTENSION(s) are recognized as
                        being of (the existing) type TYPE

  --[no]follow          Follow symlinks.  Default is off.

  Directories ignored by default:
    $ignore_dirs

  Files not checked for type:
    /~\$/           - Unix backup files
    /#.+#\$/        - Emacs swap files
    /[._].*\\.swp\$/ - Vi(m) swap files
    /core\\.\\d+\$/   - core dumps

Miscellaneous:
  --noenv               Ignore environment variables and ~/.ackrc
  --help                This help
  --man                 Man page
  --version             Display version & copyright
  --thpppt              Bill the Cat

Exit status is 0 if match, 1 if no match.

This is version $VERSION of ack.
END_OF_HELP

    return;
 }



sub show_help_types {
    App::Ack::print( <<'END_OF_HELP' );
Usage: ack [OPTION]... PATTERN [FILES]

The following is the list of filetypes supported by ack.  You can
specify a file type with the --type=TYPE format, or the --TYPE
format.  For example, both --type=perl and --perl work.

Note that some extensions may appear in multiple types.  For example,
.pod files are both Perl and Parrot.

END_OF_HELP

    my @types = filetypes_supported();
    my $maxlen = 0;
    for ( @types ) {
        $maxlen = length if $maxlen < length;
    }
    for my $type ( sort @types ) {
        next if $type =~ /^-/; # Stuff to not show
        my $ext_list = $mappings{$type};

        if ( ref $ext_list ) {
            $ext_list = join( ' ', map { ".$_" } @{$ext_list} );
        }
        App::Ack::print( sprintf( "    --[no]%-*.*s %s\n", $maxlen, $maxlen, $type, $ext_list ) );
    }

    return;
}

sub _listify {
    my @whats = @_;

    return '' if !@whats;

    my $end = pop @whats;
    my $str = @whats ? join( ', ', @whats ) . " and $end" : $end;

    no warnings 'once';
    require Text::Wrap;
    $Text::Wrap::columns = 75;
    return Text::Wrap::wrap( '', '    ', $str );
}


sub get_version_statement {
    require Config;

    my $copyright = get_copyright();
    my $this_perl = $Config::Config{perlpath};
    if ($^O ne 'VMS') {
        my $ext = $Config::Config{_exe};
        $this_perl .= $ext unless $this_perl =~ m/$ext$/i;
    }
    my $ver = sprintf( '%vd', $^V );

    return <<"END_OF_VERSION";
ack $VERSION
Running under Perl $ver at $this_perl

$copyright

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.
END_OF_VERSION
}


sub print_version_statement {
    App::Ack::print( get_version_statement() );

    return;
}


sub get_copyright {
    return $COPYRIGHT;
}


sub load_colors {
    eval 'use Term::ANSIColor ()';

    $ENV{ACK_COLOR_MATCH}    ||= 'black on_yellow';
    $ENV{ACK_COLOR_FILENAME} ||= 'bold green';

    return;
}


sub is_interesting {
    return if /^\./;

    my $include;

    for my $type ( filetypes( $File::Next::name ) ) {
        if ( defined $type_wanted{$type} ) {
            if ( $type_wanted{$type} ) {
                $include = 1;
            }
            else {
                return;
            }
        }
    }

    return $include;
}



# print subs added in order to make it easy for a third party
# module (such as App::Wack) to redefine the display methods
# and show the results in a different way.
sub print                   { print {$fh} @_ }
sub print_first_filename    { App::Ack::print( $_[0], "\n" ) }
sub print_blank_line        { App::Ack::print( "\n" ) }
sub print_separator         { App::Ack::print( "--\n" ) }
sub print_filename          { App::Ack::print( $_[0], $_[1] ) }
sub print_line_no           { App::Ack::print( $_[0], $_[1] ) }
sub print_column_no         { App::Ack::print( $_[0], $_[1] ) }
sub print_count {
    my $filename = shift;
    my $nmatches = shift;
    my $ors = shift;
    my $count = shift;

    App::Ack::print( $filename );
    App::Ack::print( ':', $nmatches ) if $count;
    App::Ack::print( $ors );
}

sub print_count0 {
    my $filename = shift;
    my $ors = shift;

    App::Ack::print( $filename, ':0', $ors );
}



{
    my $filename;
    my $regex;
    my $display_filename;

    my $keep_context;

    my $last_output_line;             # number of the last line that has been output
    my $any_output;                   # has there been any output for the current file yet
    my $context_overall_output_count; # has there been any output at all

sub search_resource {
    my $res = shift;
    my $opt = shift;

    $filename = $res->name();

    my $v = $opt->{v};
    my $passthru = $opt->{passthru};
    my $max = $opt->{m};
    my $nmatches = 0;

    $display_filename = undef;

    # for --line processing
    my $has_lines = 0;
    my @lines;
    if ( defined $opt->{lines} ) {
        $has_lines = 1;
        @lines = ( @{$opt->{lines}}, -1 );
        undef $regex; # Don't match when printing matching line
    }
    else {
        $regex = qr/$opt->{regex}/;
    }

    # for context processing
    $last_output_line = -1;
    $any_output = 0;
    my $before_context = $opt->{before_context};
    my $after_context  = $opt->{after_context};

    $keep_context = ($before_context || $after_context) && !$passthru;

    my @before;
    my $before_starts_at_line;
    my $after = 0; # number of lines still to print after a match

    while ( $res->next_text ) {
        # XXX Optimize away the case when there are no more @lines to find.
        # XXX $has_lines, $passthru and $v never change.  Optimize.
        if ( $has_lines
               ? $. != $lines[0]  # $lines[0] should be a scalar
               : $v ? m/$regex/ : !m/$regex/ ) {
            if ( $passthru ) {
                App::Ack::print( $_ );
                next;
            }

            if ( $keep_context ) {
                if ( $after ) {
                    print_match_or_context( $opt, 0, $., $-[0], $+[0], $_ );
                    $after--;
                }
                elsif ( $before_context ) {
                    if ( @before ) {
                        if ( @before >= $before_context ) {
                            shift @before;
                            ++$before_starts_at_line;
                        }
                    }
                    else {
                        $before_starts_at_line = $.;
                    }
                    push @before, $_;
                }
                last if $max && ( $nmatches >= $max ) && !$after;
            }
            next;
        } # not a match

        ++$nmatches;

        # print an empty line as a divider before first line in each file (not before the first file)
        if ( !$any_output && $opt->{show_filename} && $opt->{break} && defined( $context_overall_output_count ) ) {
            App::Ack::print_blank_line();
        }

        shift @lines if $has_lines;

        if ( $res->is_binary ) {
            App::Ack::print( "Binary file $filename matches\n" );
            last;
        }
        if ( $keep_context ) {
            if ( @before ) {
                print_match_or_context( $opt, 0, $before_starts_at_line, $-[0], $+[0], @before );
                @before = ();
                $before_starts_at_line = 0;
            }
            if ( $max && $nmatches > $max ) {
                --$after;
            }
            else {
                $after = $after_context;
            }
        }
        print_match_or_context( $opt, 1, $., $-[0], $+[0], $_ );

        last if $max && ( $nmatches >= $max ) && !$after;
    } # while

    return $nmatches;
}   # search_resource()



sub print_match_or_context {
    my $opt         = shift; # opts array
    my $is_match    = shift; # is there a match on the line?
    my $line_no     = shift;
    my $match_start = shift;
    my $match_end   = shift;

    my $color         = $opt->{color};
    my $heading       = $opt->{heading};
    my $show_filename = $opt->{show_filename};
    my $show_column   = $opt->{column};

    if ( $show_filename ) {
        if ( not defined $display_filename ) {
            $display_filename =
                $color
                    ? Term::ANSIColor::colored( $filename, $ENV{ACK_COLOR_FILENAME} )
                    : $filename;
            if ( $heading && !$any_output ) {
                App::Ack::print_first_filename($display_filename);
            }
        }
    }

    my $sep = $is_match ? ':' : '-';
    my $output_func = $opt->{output};
    for ( @_ ) {
        if ( $keep_context && !$output_func ) {
            if ( ( $last_output_line != $line_no - 1 ) &&
                ( $any_output || ( !$heading && defined( $context_overall_output_count ) ) ) ) {
                App::Ack::print_separator();
            }
            # to ensure separators between different files when --noheading

            $last_output_line = $line_no;
        }

        if ( $show_filename ) {
            App::Ack::print_filename($display_filename, $sep) if not $heading;
            App::Ack::print_line_no($line_no, $sep);
        }

        if ( $output_func ) {
            while ( /$regex/go ) {
                App::Ack::print( $output_func->() . "\n" );
            }
        }
        else {
            if ( $color && $is_match && $regex &&
                 s/$regex/Term::ANSIColor::colored( substr($_, $-[0], $+[0] - $-[0]), $ENV{ACK_COLOR_MATCH} )/eg ) {
                # At the end of the line reset the color and remove newline
                s/[\r\n]*\z/\e[0m\e[K/;
            }
            else {
                # remove any kind of newline at the end of the line
                s/[\r\n]*\z//;
            }
            if ( $show_column ) {
                App::Ack::print_column_no( $match_start+1, $sep );
            }
            App::Ack::print($_ . "\n");
        }
        $any_output = 1;
        ++$context_overall_output_count;
        ++$line_no;
    }

    return;
} # print_match_or_context()

} # scope around search_resource() and print_match_or_context()



sub search_and_list {
    my $res = shift;
    my $opt = shift;

    my $nmatches = 0;
    my $count = $opt->{count};
    my $ors = $opt->{print0} ? "\0" : "\n"; # output record separator

    my $regex = qr/$opt->{regex}/;

    if ( $opt->{v} ) {
        while ( $res->next_text ) {
            if ( /$regex/ ) {
                return 0 unless $count;
            }
            else {
                ++$nmatches;
            }
        }
    }
    else {
        while ( $res->next_text ) {
            if ( /$regex/ ) {
                ++$nmatches;
                last unless $count;
            }
        }
    }

    if ( $nmatches ) {
        App::Ack::print_count( $res->name, $nmatches, $ors, $count );
    }
    elsif ( $count && !$opt->{l} ) {
        App::Ack::print_count0( $res->name, $ors );
    }

    return $nmatches ? 1 : 0;
}   # search_and_list()



sub filetypes_supported_set {
    return grep { defined $type_wanted{$_} && ($type_wanted{$_} == 1) } filetypes_supported();
}



sub print_files {
    my $iter = shift;
    my $opt = shift;

    my $ors = $opt->{print0} ? "\0" : "\n";

    my $nmatches = 0;
    while ( defined ( my $file = $iter->() ) ) {
        App::Ack::print $file, $ors;
        $nmatches++;
        last if $opt->{1};
    }

    return $nmatches;
}


sub print_files_with_matches {
    my $iter = shift;
    my $opt = shift;

    my $nmatches = 0;
    while ( defined ( my $filename = $iter->() ) ) {
        my $repo = App::Ack::Repository::Basic->new( $filename );
        my $res;
        while ( $res = $repo->next_resource() ) {
            $nmatches += search_and_list( $res, $opt );
            $res->close();
            last if $nmatches && $opt->{1};
        }
        $repo->close();
    }

    return $nmatches;
}


sub print_matches {
    my $iter = shift;
    my $opt = shift;

    $opt->{show_filename} = 0 if $opt->{h};
    $opt->{show_filename} = 1 if $opt->{H};

    my $nmatches = 0;
    while ( defined ( my $filename = $iter->() ) ) {
        my $repo;
        my $tarballs_work = 0;
        if ( $tarballs_work && $filename =~ /\.tar\.gz$/ ) {
            App::Ack::die( 'Not working here yet' );
            require App::Ack::Repository::Tar; # XXX Error checking
            $repo = App::Ack::Repository::Tar->new( $filename );
        }
        else {
            $repo = App::Ack::Repository::Basic->new( $filename );
        }
        $repo or next;

        while ( my $res = $repo->next_resource() ) {
            my $needs_line_scan;
            if ( $opt->{regex} && !$opt->{passthru} ) {
                $needs_line_scan = $res->needs_line_scan( $opt );
                if ( $needs_line_scan ) {
                    $res->reset();
                }
            }
            else {
                $needs_line_scan = 1;
            }
            if ( $needs_line_scan ) {
                $nmatches += search_resource( $res, $opt );
            }
            $res->close();
        }
        last if $nmatches && $opt->{1};
        $repo->close();
    }
    return  $nmatches;
}


sub filetype_setup {
    my $filetypes_supported_set = filetypes_supported_set();
    # If anyone says --no-whatever, we assume all other types must be on.
    if ( !$filetypes_supported_set ) {
        for my $i ( keys %type_wanted ) {
            $type_wanted{$i} = 1 unless ( defined( $type_wanted{$i} ) || $i eq 'binary' || $i eq 'text' || $i eq 'skipped' );
        }
    }
    return;
}


EXPAND_FILENAMES_SCOPE: {
    my $filter;

    sub expand_filenames {
        my $argv = shift;

        my $attr;
        my @files;

        foreach my $pattern ( @{$argv} ) {
            my @results = bsd_glob( $pattern );

            if (@results == 0) {
                @results = $pattern; # Glob didn't match, pass it thru unchanged
            }
            elsif ( (@results > 1) or ($results[0] ne $pattern) ) {
                if (not defined $filter) {
                    eval 'require Win32::File;';
                    if ($@) {
                        $filter = 0;
                    }
                    else {
                        $filter = Win32::File::HIDDEN()|Win32::File::SYSTEM();
                    }
                } # end unless we've tried to load Win32::File
                if ( $filter ) {
                    # Filter out hidden and system files:
                    @results = grep { not(Win32::File::GetAttributes($_, $attr) and $attr & $filter) } @results;
                    App::Ack::warn( "$pattern: Matched only hidden files" ) unless @results;
                } # end if we can filter by file attributes
            } # end elsif this pattern got expanded

            push @files, @results;
        } # end foreach pattern

        return \@files;
    } # end expand_filenames
} # EXPAND_FILENAMES_SCOPE



sub get_starting_points {
    my $argv = shift;
    my $opt = shift;

    my @what;

    if ( @{$argv} ) {
        @what = @{ $is_windows ? expand_filenames($argv) : $argv };
        $_ = File::Next::reslash( $_ ) for @what;

        # Show filenames unless we've specified one single file
        $opt->{show_filename} = (@what > 1) || (!-f $what[0]);
    }
    else {
        @what = '.'; # Assume current directory
        $opt->{show_filename} = 1;
    }

    for my $start_point (@what) {
        App::Ack::warn( "$start_point: No such file or directory" ) unless -e $start_point;
    }
    return \@what;
}



sub get_iterator {
    my $what = shift;
    my $opt  = shift;

    # Starting points are always searched, no matter what
    my %starting_point = map { ($_ => 1) } @{$what};

    my $g_regex = defined $opt->{G} ? qr/$opt->{G}/ : undef;
    my $file_filter;

    if ( $g_regex ) {
        $file_filter
            = $opt->{u}   ? sub { $File::Next::name =~ /$g_regex/ } # XXX Maybe this should be a 1, no?
            : $opt->{all} ? sub { $starting_point{ $File::Next::name } || ( $File::Next::name =~ /$g_regex/ && is_searchable( $File::Next::name ) ) }
            :               sub { $starting_point{ $File::Next::name } || ( $File::Next::name =~ /$g_regex/ && is_interesting( @_ ) ) }
            ;
    }
    else {
        $file_filter
            = $opt->{u}   ? sub {1}
            : $opt->{all} ? sub { $starting_point{ $File::Next::name } || is_searchable( $File::Next::name ) }
            :               sub { $starting_point{ $File::Next::name } || is_interesting( @_ ) }
            ;
    }

    my $descend_filter
        = $opt->{n} ? sub {0}
        : $opt->{u} ? sub {1}
        : \&ignoredir_filter;

    my $iter =
        File::Next::files( {
            file_filter     => $file_filter,
            descend_filter  => $descend_filter,
            error_handler   => sub { my $msg = shift; App::Ack::warn( $msg ) },
            sort_files      => $opt->{sort_files},
            follow_symlinks => $opt->{follow},
        }, @{$what} );
    return $iter;
}


sub set_up_pager {
    my $command = shift;

    return if App::Ack::output_to_pipe();

    my $pager;
    if ( not open( $pager, '|-', $command ) ) {
        App::Ack::die( qq{Unable to pipe to pager "$command": $!} );
    }
    $fh = $pager;

    return;
}


sub input_from_pipe {
    return $input_from_pipe;
}



sub output_to_pipe {
    return $output_to_pipe;
}



1; # End of App::Ack
package App::Ack::Repository;


use warnings;
use strict;

sub FAIL {
    require Carp;
    Carp::confess( 'Must be overloaded' );
}


sub new {
    FAIL();
}


sub next_resource {
    FAIL();
}


sub close {
    FAIL();
}

1;
package App::Ack::Resource;


use warnings;
use strict;

sub FAIL {
    require Carp;
    Carp::confess( 'Must be overloaded' );
}


sub new {
    FAIL();
}


sub name {
    FAIL();
}


sub is_binary {
    FAIL();
}



sub needs_line_scan {
    FAIL();
}


sub reset {
    FAIL();
}


sub next_text {
    FAIL();
}


sub close {
    FAIL();
}

1;
package App::Ack::Plugin::Basic;



package App::Ack::Resource::Basic;


use warnings;
use strict;


our @ISA = qw( App::Ack::Resource );


sub new {
    my $class    = shift;
    my $filename = shift;

    my $self = bless {
        filename        => $filename,
        fh              => undef,
        could_be_binary => undef,
        opened          => undef,
        id              => undef,
    }, $class;

    if ( $self->{filename} eq '-' ) {
        $self->{fh} = *STDIN;
        $self->{could_be_binary} = 0;
    }
    else {
        if ( !open( $self->{fh}, '<', $self->{filename} ) ) {
            App::Ack::warn( "$self->{filename}: $!" );
            return;
        }
        $self->{could_be_binary} = 1;
    }

    return $self;
}


sub name {
    my $self = shift;

    return $self->{filename};
}


sub is_binary {
    my $self = shift;

    if ( $self->{could_be_binary} ) {
        return -B $self->{filename};
    }

    return 0;
}



sub needs_line_scan {
    my $self  = shift;
    my $opt   = shift;

    return 1 if $opt->{v};

    my $size = -s $self->{fh};
    if ( $size == 0 ) {
        return 0;
    }
    elsif ( $size > 100_000 ) {
        return 1;
    }

    my $buffer;
    my $rc = sysread( $self->{fh}, $buffer, $size );
    if ( not defined $rc ) {
        App::Ack::warn( "$self->{filename}: $!" );
        return 1;
    }
    return 0 unless $rc && ( $rc == $size );

    my $regex = $opt->{regex};
    return $buffer =~ /$regex/m;
}


sub reset {
    my $self = shift;

    seek( $self->{fh}, 0, 0 )
        or App::Ack::warn( "$self->{filename}: $!" );

    return;
}


sub next_text {
    if ( defined ($_ = readline $_[0]->{fh}) ) {
        $. = ++$_[0]->{line};
        return 1;
    }

    return;
}


sub close {
    my $self = shift;

    if ( not close $self->{fh} ) {
        App::Ack::warn( $self->name() . ": $!" );
    }

    return;
}

package App::Ack::Repository::Basic;


our @ISA = qw( App::Ack::Repository );


use warnings;
use strict;

sub new {
    my $class    = shift;
    my $filename = shift;

    my $self = bless {
        filename => $filename,
        nexted   => 0,
    }, $class;

    return $self;
}


sub next_resource {
    my $self = shift;

    return if $self->{nexted};
    $self->{nexted} = 1;

    return App::Ack::Resource::Basic->new( $self->{filename} );
}


sub close {
}



1;
