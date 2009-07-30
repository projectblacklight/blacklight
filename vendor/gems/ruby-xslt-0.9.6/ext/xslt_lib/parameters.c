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

#include "xslt.h"

/**
 * parameters support, patch from :
 * 
 * Eustáquio "TaQ" Rangel
 * eustaquiorangel@yahoo.com
 * http://beam.to/taq
 * 
 */
VALUE each_pair( VALUE obj ) {
  return rb_funcall( obj, rb_intern("each"), 0, 0 );
}
    
VALUE process_pair( VALUE pair, VALUE rbparams ) {
  VALUE key, value;
  // Thx to alex__
  int count = FIX2INT( rb_funcall( rbparams, rb_intern("size"), 0, 0 ) );
  // static int count = 0;
  char *xValue = NULL;
  
  Check_Type( pair, T_ARRAY );

  key   = RARRAY(pair)->ptr[0];
  value = RARRAY(pair)->ptr[1];
  
  Check_Type( key, T_STRING );
  Check_Type( value, T_STRING );

  xValue = STR2CSTR( value );
  if( xValue[0] != '\'' && xValue[strlen( xValue ) - 1] != '\'' ) {
    value = rb_str_concat( value, rb_str_new2( "'" ) );
    value = rb_str_concat( rb_str_new2( "'" ), value );
  }
  
  rb_ary_store( rbparams, count, key );
  rb_ary_store( rbparams, count + 1, value );
  
  count += 2;
  return Qnil;
}
