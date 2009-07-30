#!/usr/bin/ruby -w
# See the LICENSE file for copyright and distribution information

require "mkmf"

def help
  print <<HELP
"extconf.rb" configures this package to adapt to many kinds of systems.

Usage: ruby extconf.rb [OPTION]...

Configuration:
  --help                   display this help and exit
  
  --with-xslt-lib=PATH
  --with-xslt-include=PATH
  --with-xslt-dir=PATH     specify the directory name for the libxslt include 
                           files and/or library 
  
  --disable-error-handler  disables the new error handler
  
  --disable-exslt          disables libexslt support <http://exslt.org/>
HELP
end

if ARGV.include?( "--help" ) or ARGV.include?( "-h" )
  help()
  exit 0
end

if enable_config("error-handler", true)
  $CFLAGS += " -DUSE_ERROR_HANDLER"
end

#$LIBPATH.push(Config::CONFIG['libdir'])

def crash(str)
  printf(" extconf failure: %s\n", str)
  exit 1
end

dir_config( 'xml2' ) 
dir_config( 'xslt' ) 

have_library "xml2", "xmlParseDoc" || crash("need libxml2")
have_library "xslt", "xsltParseStylesheetFile" || crash("need libxslt")

if enable_config("exslt", true)
  have_library "exslt", "exsltRegisterAll"
  $CFLAGS += " -DUSE_EXSLT"
end

$CFLAGS = '-g -Wall ' + `xml2-config --cflags`.chomp + " " + `xslt-config --cflags`.chomp + " " + $CFLAGS

create_header()
create_makefile("xml/xslt_lib")

