/**
 * Copyright (C) 2005, 2006, 2007, 2008 Gregoire Lejeune <gregoire.lejeune@free.fr>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
 */

#include "rb_utils.h"

char * getRubyObjectName( VALUE rb_Object ) {
  VALUE klass = rb_funcall( rb_Object, rb_intern( "class" ), 0 );
  return( STR2CSTR( rb_funcall( klass, rb_intern( "to_s" ), 0 ) ) );
}

int isFile( const char *filename ) {
  struct stat stbuf;

  if( stat( filename, &stbuf ) ) return 0;
  return( ( (stbuf.st_mode & S_IFMT) == S_IFREG ) ? 1 : 0 );
}
