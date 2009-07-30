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
#include "parser.h"

extern VALUE cXSLT;

xmlDocPtr parse_xml( char* xml, int iXmlType ) {
  xmlDocPtr tXMLDocument = NULL;
  
  /** Act: Parse XML */
  if( iXmlType == RUBY_XSLT_XMLSRC_TYPE_STR ) {
    tXMLDocument = xmlParseMemory( xml, strlen( xml ) );
  } else if( iXmlType == RUBY_XSLT_XMLSRC_TYPE_FILE ) {
    tXMLDocument = xmlParseFile( xml );
  }

  if( tXMLDocument == NULL ) {
    rb_raise( eXSLTParsingError, "XML parsing error" );
    return( NULL );
  }

  return( tXMLDocument );
}

xsltStylesheetPtr parse_xsl( char* xsl, int iXslType ) {
  xsltStylesheetPtr tParsedXslt   = NULL;
  xmlDocPtr         tXSLDocument  = NULL;
  
  /** Rem: For encoding */
  xmlCharEncodingHandlerPtr encoder = NULL;
  const xmlChar *encoding = NULL;
  
  /** Act: Encoding support */
  xmlInitCharEncodingHandlers( );

  /** Act: Parse XSL */
  if( iXslType == RUBY_XSLT_XSLSRC_TYPE_STR ) {
    tXSLDocument = xmlParseMemory( xsl, strlen( xsl ) );
    if( tXSLDocument == NULL ) {
      rb_raise( eXSLTParsingError, "XSL parsing error" );
      return( NULL );
    }

    tParsedXslt = xsltParseStylesheetDoc( tXSLDocument );
  } else if( iXslType == RUBY_XSLT_XSLSRC_TYPE_FILE ) {
    tParsedXslt = xsltParseStylesheetFile( BAD_CAST xsl );
  }

  if( tParsedXslt == NULL ) {
    rb_raise( eXSLTParsingError, "XSL Stylesheet parsing error" );
    return( NULL );
  }
    
  /** Act: Get encoding */
  XSLT_GET_IMPORT_PTR( encoding, tParsedXslt, encoding )
  encoder = xmlFindCharEncodingHandler((char *)encoding);
  
  if( encoding != NULL ) {
    encoder = xmlFindCharEncodingHandler((char *)encoding);
    if( (encoder != NULL) && (xmlStrEqual((const xmlChar *)encoder->name, (const xmlChar *) "UTF-8")) ) {
      encoder = NULL;
    }
  }
  
  return( tParsedXslt );
}

/**
 * xOut = parser( char *xml, int iXmlType, char *xslt, int iXslType, char **pxParams );
 */
char* parse( xsltStylesheetPtr tParsedXslt, xmlDocPtr tXMLDocument, char **pxParams ) {
  xmlDocPtr tXMLDocumentResult  = NULL;
  int iXMLDocumentResult;
  xmlChar *tXMLDocumentResultString;
  int tXMLDocumentResultLenght;

  tXMLDocumentResult = xsltApplyStylesheet( tParsedXslt, tXMLDocument, (const char**) pxParams );
  if( tXMLDocumentResult == NULL ) {
    rb_raise( eXSLTTransformationError, "Stylesheet transformation error" );
    return( NULL );
  }
  
  iXMLDocumentResult = xsltSaveResultToString( &tXMLDocumentResultString, &tXMLDocumentResultLenght, tXMLDocumentResult, tParsedXslt );

  xmlFreeDoc(tXMLDocumentResult);
  
  return((char*)tXMLDocumentResultString);
}

/**
 * vOut = object_to_string( VALUE object );
 */
VALUE object_to_string( VALUE object ) {
  VALUE vOut = Qnil;
    
  switch( TYPE( object ) ) {
    case T_STRING:
      {
        if( isFile( STR2CSTR( object ) ) == 0 ) {
          vOut = object;
        } else {
          long iBufferLength;
          long iCpt;
          char *xBuffer;

          FILE* fStream = fopen( STR2CSTR( object ), "r" );
          if( fStream == NULL ) {
            return( Qnil );
          }

          fseek( fStream, 0L, 2 );
          iBufferLength = ftell( fStream );
          xBuffer = (char *)malloc( (int)iBufferLength + 1 );
          if( !xBuffer )
            rb_raise( rb_eNoMemError, "Memory allocation error" );

          xBuffer[iBufferLength] = 0;
          fseek( fStream, 0L, 0 );
          iCpt = fread( xBuffer, 1, (int)iBufferLength, fStream );
          
          if( iCpt != iBufferLength ) {
            free( (char *)xBuffer );
            rb_raise( rb_eSystemCallError, "Read file error" );
          }

          vOut = rb_str_new2( xBuffer );
          free( xBuffer );

          fclose( fStream );
        }
      }
      break;
    
    case T_DATA:
    case T_OBJECT: 
      {
        if( strcmp( getRubyObjectName( object ), "XML::Smart::Dom" ) == 0 || 
            strcmp( getRubyObjectName( object ), "XML::Simple::Dom" ) == 0 ) {
          vOut = rb_funcall( object, rb_intern( "to_s" ), 0 );
        } else if ( strcmp( getRubyObjectName( object ), "REXML::Document" ) == 0 ) {  
          vOut = rb_funcall( object, rb_intern( "to_s" ), 0 );
        } else {
          rb_raise( rb_eSystemCallError, "Can't read XML from object %s", getRubyObjectName( object ) );
        }
      }
      break;
    
    default:
      rb_raise( rb_eArgError, "XML object #0x%x not supported", TYPE( object ) );
  }

  return( vOut );
}

/**
 * bOut = objectIsFile( VALUE object );
 */
int objectIsFile( VALUE object ) {
  int bOut = 0;
    
  switch( TYPE( object ) ) {
    case T_STRING:
      {
        if( isFile( STR2CSTR( object ) ) == 0 )
          bOut = 0;
        else
          bOut = 1;
      }
      break;
    
    case T_DATA:
    case T_OBJECT: 
    default:
      bOut = 0;
  }

  return( bOut );
}
