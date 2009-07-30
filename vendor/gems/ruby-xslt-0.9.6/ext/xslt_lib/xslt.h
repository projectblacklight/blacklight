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

#ifndef __RUBY_XSLT_H__
#define __RUBY_XSLT_H__

#include <ruby.h>
#include <rubyio.h>

#include <string.h>

#include <libxml/xmlmemory.h>
#include <libxml/debugXML.h>
#include <libxml/HTMLtree.h>
#include <libxml/xmlIO.h>
#include <libxml/xinclude.h>
#include <libxml/catalog.h>

#include <libxslt/extra.h>
#include <libxslt/xslt.h>
#include <libxslt/xsltInternals.h>
#include <libxslt/transform.h>
#include <libxslt/xsltutils.h>
#include <libxslt/imports.h>

#ifdef USE_EXSLT
  #include <libexslt/exslt.h>
#endif

#ifdef MEMWATCH
  #include "memwatch.h"
#endif

#include "rb_utils.h"
#include "parser.h"
#include "parameters.h"
#include "extfunc.h"

#define RUBY_XSLT_VERSION  "0.9.6"
#define RUBY_XSLT_VERNUM   096

#define RUBY_XSLT_XSLSRC_TYPE_NULL     0
#define RUBY_XSLT_XSLSRC_TYPE_STR      1
#define RUBY_XSLT_XSLSRC_TYPE_FILE     2
#define RUBY_XSLT_XSLSRC_TYPE_REXML    4
#define RUBY_XSLT_XSLSRC_TYPE_SMART    8
#define RUBY_XSLT_XSLSRC_TYPE_PARSED  16

#define RUBY_XSLT_XMLSRC_TYPE_NULL     0
#define RUBY_XSLT_XMLSRC_TYPE_STR      1
#define RUBY_XSLT_XMLSRC_TYPE_FILE     2
#define RUBY_XSLT_XMLSRC_TYPE_REXML    4
#define RUBY_XSLT_XMLSRC_TYPE_SMART    8
#define RUBY_XSLT_XMLSRC_TYPE_PARSED  16

RUBY_EXTERN VALUE eXSLTError;
RUBY_EXTERN VALUE eXSLTParsingError;
RUBY_EXTERN VALUE eXSLTTransformationError;

typedef struct RbTxslt {
  int       iXmlType;
  VALUE     xXmlData;
  VALUE     oXmlObject;
  VALUE     xXmlString;
  xmlDocPtr tXMLDocument;
  
  int               iXslType;
  VALUE             xXslData;
  VALUE             oXslObject;
  VALUE             xXslString;
  xsltStylesheetPtr tParsedXslt;

  int   iXmlResultType;
  VALUE xXmlResultCache;

  VALUE pxParams;
  int   iNbParams;

} RbTxslt;

#endif
