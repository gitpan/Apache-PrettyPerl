package Apache::PrettyPerl;

use strict;
use Apache;
use Apache::Constants qw/:common/;
use Apache::File;
use CGI qw/:all/;
use vars qw/$VERSION/;
require DynaLoader;
require 'sys/syscall.ph';

$VERSION='1.00';

my @Loops = qw/while until for foreach unless if elsif else do/;
my @Packages = qw/package use no require import/;
my @Function = qw/abs accept alarm atan2 bind binmode bless
   caller chdir chmod chomp chop chown chr
   chroot close closedir connect continue cos
   crypt dbmclose dbmopen defined delete die
   dump each endgrent endhostent endnetent
   endprotoent endpwent endservent eof eval 
   exec exists exit exp fcntl fileno flock
   fork format formline getc getgrent getgrgid
   getgrnam gethostbyaddr gethostbyname gethostent
   getlogin getnetbyaddr getnetbyname getnetent
   getpeername getpgrp getppid getpriority
   getprotobyname getprotobynumber getprotoent
   getpwent getpwnam getpwuid getservbyname
   getservbyport getservent getsockname
   getsockopt glob gmtime goto grep hex index
   int ioctl join keys kill last lc lcfirst
   length link listen local localtime log
   lstat map map mkdir msgctl msgget msgrcv
   msgsnd my next oct open opendir ord pack
   pipe pop pos print printf prototype push
   quotemeta rand read readdir readline
   readlink readpipe recv redo ref rename
   reset return reverse rewinddir rindex
   rmdir scalar seek seekdir select semctl
   semget semop send setgrent sethostent
   setnetent setpgrp setpriority setprotoent
   setpwent setservent setsockopt shift shmctl 
   shmget shmread shmwrite shutdown sin sleep
   socket socketpair sort splice split sprintf
   sqrt srand stat study sub substr symlink
   syscall sysopen sysread sysread sysseek
   system syswrite tell telldir tie tied
   time times truncate uc ucfirst umask undef
   unlink unpack unshift untie utime values
   vec wait waitpid wantarray wantarray
   warn write/;
                                                             
my $str_clr = 'C80FC8';
my $var_clr = '008000'; my $var_clr_1 = '008080';
my $pkg_clr = 'blue';
my $fh_clr = 'red';
my $cmnt_clr = 'brown';
my $loop_clr = '5A1EB4';
my $func_clr = '808000';


sub handler
{ my $r = shift;
  eval "do '/usr/perl/lib/Apache/parse_perl.pl'";
  $r->log_error("parse_perl error: $@") if $@;
  $r->content_type("text/perl-script") if $r->args and lc($r->dir_config('AllowDownload')) eq 'on';
  $r->send_http_header;
  return OK if $r->header_only;
  $r->print(parse_perl($r));
  return OK;
}  

sub is_ok($$)
{ my ($s, $p) = @_;
  my @o = split /$p/, $s;
  my $o = scalar(@o)-1; 
  return ($o/2 == int($o/2) ? 1 : 0);
}

sub parse_perl
{ my $r = shift;
  my $fh = new Apache::File($r->filename);
  my $TAB = $r->dir_config('TabSize'); $TAB = 8 unless $TAB;
  my ($data,$i,$tmp,@str,$b,$e);
  local $/;
  $_ = $data = <$fh>;
  $b = $e = pack("LL", ());
  syscall(&SYS_gettimeofday, $b, 0);
  s:(&):&amp;:g;
  s:>:&gt;:g; s:<:&lt;:g; 
  # Spaces and newlines
  s:(\n|\r):<BR>$&:gm;
  s:\t:"&nbsp;" x $TAB:egm; 
  s:^\s+|\s{2,}:("&nbsp;" x (length($&) - 1))." ":egm;
  # Comments
  push(@str,"<B><I><Font Color=$cmnt_clr>$&</Font></I></B>") while s:^#!.*$:"@!~STR".$i++:em;
  push(@str,"<I><Font Color=$cmnt_clr>$&</Font></I>") while s:\n=head.+?(\n=cut|$):"@!~STR".$i++:es;
  my (@cmnt, @com, $j);
  @cmnt = split /#/;
  $_ = $cmnt[0];
  for ($j=1; $j<=$#cmnt; $j++)
  { $tmp = join('',@cmnt[0..$j-1]);
    $cmnt[$j] = "#$cmnt[$j]";
    if ((split //,$cmnt[$j-1])[-1] ne '$' and is_ok($tmp, '\'|"|`')
        and $tmp !~ /\Wq[qxw]([:\/~\?!|\$%#'`"])([^\/]*?)$/m)
    { $cmnt[$j] =~ s:(.*?)(<BR>|$):@!~COM$j$2:;
      $com[$j] = "<I><Font Color=$cmnt_clr>$1</Font></I>";
    }
    $_ .= $cmnt[$j];
  }
  # Strings
  push(@str,"<Font Color=$func_clr>$2</Font>[<Font Color=$str_clr>$3</Font>]") while s:(\W)(q[qxw]?)\[(.*?)\]:"$1@!~STR".$i++:eso;
  push(@str,"<Font Color=$func_clr>$2</Font>{<Font Color=$str_clr>$3</Font>}") while s:(\W)(q[qxw]?){(.*?)}:"$1@!~STR".$i++:eso;
  push(@str,"<Font Color=$func_clr>$2</Font>(<Font Color=$str_clr>$3</Font>)") while s:(\W)(q[qxw]?)\((.*?)\):"$1@!~STR".$i++:eso;
  push(@str,"<Font Color=$func_clr>$2</Font>&lt;<Font Color=$str_clr>$3</Font>&gt;") while s:(\W)(q[qxw]?)<(.*?)>:"$1@!~STR".$i++:eso;
  push(@str,"<Font Color=$func_clr>$2</Font>$3<Font Color=$str_clr>$4</Font>$3") while s:(\W)(q[qxw]?)([\:/~\?!|\$%#'`"])(.*?)\3:"$1@!~STR".$i++:eso;
  push(@str,"<Font Color=$str_clr>$&</Font>") while s#""|''|``|(["'`]).*?[^\\]\1#"@!~STR".$i++#eso;
  # File handlers
  s:&lt;\w+?&gt;:<Font Color=$fh_clr>$&</Font>:gm;
  # Variables
  s:(\$[_\./,\\;?!@<>()\$#[\]]|\@_)(\W):<Font Color=$var_clr_1>$1</Font>$2:g;
  s:(\$)(\^\w|&gt;|&lt;):<Font Color=$var_clr_1>$1$2</Font>:g;
  s:(\W)(_)(\W):$1<Font Color=$var_clr_1>$2</Font>$3:g;
  s:(\$|@|%)+(\#|(?!_))[a-zA-Z0-9_\:]+:<Font Color=$var_clr>$&</Font>:gx;
  s:(__[A-Z]+__):<B>$1</B>:g;
  # Packages
  $tmp = join '|', @Packages;
  s:(\s*)($tmp)(\s+.+?;):$1<Font Color=$pkg_clr>$2</Font>$3:g;
  # Loops
  $tmp = join '|', @Loops;
  s:(\W)($tmp)([ ({]):$1<Font Color=$loop_clr>$2</Font>$3:gs;
  # Functions
  $tmp = join '|', @Function;
  s#([ \n=+/*([{.,~`'"|!;&\-])($tmp)([ ({;])#$1<Font Color=$func_clr>$2</Font>$3#gs;
  s:(\W)(-[rwxoRWXOezsfdlpSbctugkTBMAC])(\W):$1<Font Color=$func_clr>$2</Font>$3:gs;
    
  s:@!~STR(\d+):$str[$1]:g; s:@!~COM(\d+):$com[$1]:g;
  syscall(&SYS_gettimeofday, $e, 0);
  my @b = unpack("LL", $b); my @e = unpack("LL", $e);
  for $tmp ($b[1], $e[1]) {$tmp /= 1_000_000}
#  $_ .= sprintf '<br>Parsing took <B>%.4f</B> seconds', ($e[0]+$e[1]) - ($b[0]+$b[1]);
  return $data if lc($r->dir_config('AllowDownload')) eq 'on' and $r->args;
  return start_html( -title => $r->uri,
    -author => 'ra@amk.lg.ua',
    -bgcolor => 'white',
    -meta => {'copyright' => 'Copyright (c) 2000 Roman Kosenko'},
    -style => {-code => 'BODY {font-family: Helvetica,Arial,Verdana,sans-serif; font-size: 12pt}'}
    ), p($_),
    (lc($r->dir_config('AllowDownload')) eq 'on' 
     ? hr.a({ -href => $r->uri."?download",
           -onMouseOut => qw/window.status=''/,
           -onMouseOver => qw/window.status='Download'/
          }, "Download file") 
     : ''), end_html;
}



1;

__END__

=head1 NAME

B<Apache::PrettyPerl> - Apache mod_perl PerlHandler for nicer output perl files in the client's browser.

=head1 SYNOPSIS

You must be using mod_perl. See http://perl.apache.org for details.
For the correct work your apache configuration would contain 
apache directives look like these:

  # in httpd.conf (or any other apache configuration file)
  
  AddType	text/html	.pl	.pm
  
  <Files ~ "\.p[lm]$">
    SetHandler		perl-script
    PerlHandler		Apache::PerttyPerl
    PerlSetVar		TabSize 	8	# optional
    PerlSetVar		AllowDownload	On	# optional
  </Files>

There is only example of apache configuration. Most probably you
should like place <Files> directive inside <Directory> directive.
Otherwise will be handled all perl files, including CGI and mod_perl
scripts.

=head1 DESCRIPTION

This is apache handler that converts perl files on the fly into 
syntax highlighted HTML. So your perl scripts/modules
will be look nicer. Also possibly download original perl file
(without syntax highlight). 

=head1 CONFIGURATION DIRECTIVES

All features of the this PerlHandler, will be setting in the
apache confihuration files. For this you can use PerlSetVar
apache directive. For example:

    PerlSetVar	TabSize	8   # inside <Files>, <Location>, ...
			    # apache directives

=over 4

=item TabSize

Setting size of the tab (\t) symbol. Default is 8.

=item AllowDownload

If it setting to On at the end of the page will be displayed 
Download link, which allow download original file. Default is Off.

=back

=head1 SEE ALSO

perl(1), mod_perl(3), Apache(3)

=head1 AUTHOR

Roman Kosenko

=head2 Contact info

E-mail:	ra@amk.lg.ua

Home page: http://amk.lg.ua/~ra/PrettyPerl

=head2 Copyright

Copyright (c) 2000 Roman Kosenko.
All rights reserved.  This package is free software; 
you can redistribute it and/or modify it under the same 
terms as Perl itself.
