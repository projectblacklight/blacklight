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

/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RUBY_RB_UTILS_H__
#define __RUBY_RB_UTILS_H__

#include <ruby.h>
#include <rubyio.h>

#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

char * getRubyObjectName( VALUE );
int isFile( const char *filename );

#endif
