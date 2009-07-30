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

VALUE mXML;
VALUE cXSLT;
VALUE eXSLTError;
VALUE eXSLTParsingError;
VALUE eXSLTTransformationError;

void ruby_xslt_free( RbTxslt *pRbTxslt ) {
  if( pRbTxslt != NULL ) {
    if( pRbTxslt->tParsedXslt != NULL )
      xsltFreeStylesheet(pRbTxslt->tParsedXslt);
    
    if( pRbTxslt->tXMLDocument != NULL )
      xmlFreeDoc(pRbTxslt->tXMLDocument);
    
    free( pRbTxslt );
  }
  
  xsltCleanupGlobals();
  xmlCleanupParser();
  xmlMemoryDump();
}

void ruby_xslt_mark( RbTxslt *pRbTxslt ) {
  if( pRbTxslt == NULL ) return;
  if( !NIL_P(pRbTxslt->xXmlData) )        rb_gc_mark( pRbTxslt->xXmlData );
  if( !NIL_P(pRbTxslt->oXmlObject) )      rb_gc_mark( pRbTxslt->oXmlObject );
  if( !NIL_P(pRbTxslt->xXmlString) )      rb_gc_mark( pRbTxslt->xXmlString );
  
  if( !NIL_P(pRbTxslt->xXslData) )        rb_gc_mark( pRbTxslt->xXslData );
  if( !NIL_P(pRbTxslt->oXslObject) )      rb_gc_mark( pRbTxslt->oXslObject );
  if( !NIL_P(pRbTxslt->xXslString) )      rb_gc_mark( pRbTxslt->xXslString );
  
  if( !NIL_P(pRbTxslt->xXmlResultCache) ) rb_gc_mark( pRbTxslt->xXmlResultCache );
  
  if( !NIL_P(pRbTxslt->pxParams) )        rb_gc_mark( pRbTxslt->pxParams );
}

/** 
 * oXSLT = XML::XSLT::new()
 * 
 * Create a new XML::XSLT object
 */
VALUE ruby_xslt_new( VALUE class ) {
  RbTxslt *pRbTxslt;

  pRbTxslt = (RbTxslt *)malloc(sizeof(RbTxslt));
  if( pRbTxslt == NULL )
    rb_raise(rb_eNoMemError, "No memory left for XSLT struct");

  pRbTxslt->iXmlType        = RUBY_XSLT_XMLSRC_TYPE_NULL;
  pRbTxslt->xXmlData        = Qnil;
  pRbTxslt->oXmlObject      = Qnil;
  pRbTxslt->xXmlString      = Qnil;
  pRbTxslt->tXMLDocument    = NULL;
  
  pRbTxslt->iXslType        = RUBY_XSLT_XSLSRC_TYPE_NULL;
  pRbTxslt->xXslData        = Qnil;
  pRbTxslt->oXslObject      = Qnil;
  pRbTxslt->xXslString      = Qnil;
  pRbTxslt->tParsedXslt     = NULL;
  
  pRbTxslt->iXmlResultType  = RUBY_XSLT_XMLSRC_TYPE_NULL;
  pRbTxslt->xXmlResultCache = Qnil;
  
  pRbTxslt->pxParams        = Qnil;
  pRbTxslt->iNbParams       = 0;
  
  xmlInitMemory();
  xmlSubstituteEntitiesDefault( 1 );
  xmlLoadExtDtdDefaultValue = 1;
  
  return( Data_Wrap_Struct( class, ruby_xslt_mark, ruby_xslt_free, pRbTxslt ) );
}

/**
 * ----------------------------------------------------------------------------
 */

/**
 * oXSLT.xml=<data|REXML::Document|XML::Smart|file>
 *
 * Set XML data.
 *
 * Parameter can be type String, REXML::Document, XML::Smart::Dom or Filename
 * 
 * Examples :
 *  # Parameter as String
 *  oXSLT.xml = <<XML
 *  <?xml version="1.0" encoding="UTF-8"?> 
 *  <test>This is a test string</test>
 *  XML
 *
 *  # Parameter as REXML::Document
 *  require 'rexml/document'
 *  oXSLT.xml = REXML::Document.new File.open( "test.xml" )
 *
 *  # Parameter as XML::Smart::Dom
 *  require 'xml/smart'
 *  oXSLT.xml = XML::Smart.open( "test.xml" )
 *
 *  # Parameter as Filename
 *  oXSLT.xml = "test.xml"
 */
VALUE ruby_xslt_xml_obj_set( VALUE self, VALUE xml_doc_obj ) {
  RbTxslt *pRbTxslt;
  Data_Get_Struct( self, RbTxslt, pRbTxslt );

  pRbTxslt->oXmlObject = xml_doc_obj;
  pRbTxslt->xXmlString = object_to_string( xml_doc_obj );
  if( pRbTxslt->xXmlString == Qnil ) {
    rb_raise( eXSLTError, "Can't get XML data" );
  }
  pRbTxslt->iXmlType   = RUBY_XSLT_XMLSRC_TYPE_STR;
  pRbTxslt->xXmlData   = pRbTxslt->xXmlString;
  
  pRbTxslt->iXmlResultType = RUBY_XSLT_XMLSRC_TYPE_NULL;

	if( pRbTxslt->tXMLDocument != NULL ) {
		xmlFreeDoc(pRbTxslt->tXMLDocument);
	}
	
  pRbTxslt->tXMLDocument = parse_xml( STR2CSTR( pRbTxslt->xXmlData ), pRbTxslt->iXmlType );
  if( pRbTxslt->tXMLDocument == NULL ) {
    rb_raise( eXSLTParsingError, "XML parsing error" );
  }
  
  pRbTxslt->iXmlType   = RUBY_XSLT_XMLSRC_TYPE_PARSED;
  
  return( Qnil );
}

/**
 * XML::XSLT#xmlfile=<file> is deprecated. Please use XML::XSLT#xml=<file>
 */
VALUE ruby_xslt_xml_obj_set_d( VALUE self, VALUE xml_doc_obj ) {
  rb_warn( "XML::XSLT#xmlfile=<file> is deprecated. Please use XML::XSLT#xml=<file> !" );
  return( ruby_xslt_xml_obj_set( self, xml_doc_obj ) );
}

/**
 * string = oXSLT.xml
 *
 * Return XML, set by XML::XSLT#xml=, as string
 */
VALUE ruby_xslt_xml_2str_get( VALUE self ) {
  RbTxslt *pRbTxslt;
  Data_Get_Struct( self, RbTxslt, pRbTxslt );

  return( pRbTxslt->xXmlString );
}

/**
 * object = oXSLT.xmlobject
 *
 * Return the XML object set by XML::XSLT#xml=
 */
VALUE ruby_xslt_xml_2obj_get( VALUE self ) {
  RbTxslt *pRbTxslt;
  Data_Get_Struct( self, RbTxslt, pRbTxslt );

  return( pRbTxslt->oXmlObject );
}

/**
 * ----------------------------------------------------------------------------
 */

/**
 * oXSLT.xsl=<data|REXML::Document|XML::Smart|file>
 *
 * Set XSL data.
 *
 * Parameter can be type String, REXML::Document, XML::Smart::Dom or Filename
 * 
 * Examples :
 *  # Parameter as String
 *  oXSLT.xsl = <<XML
 *  <?xml version="1.0" ?>
 *  <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 *   <xsl:template match="/">
 *     <xsl:apply-templates />
 *   </xsl:template>
 *  </xsl:stylesheet>
 *  XML
 *
 *  # Parameter as REXML::Document
 *  require 'rexml/document'
 *  oXSLT.xsl = REXML::Document.new File.open( "test.xsl" )
 *
 *  # Parameter as XML::Smart::Dom
 *  require 'xml/smart'
 *  oXSLT.xsl = XML::Smart.open( "test.xsl" )
 *
 *  # Parameter as Filename
 *  oXSLT.xsl = "test.xsl"
 */
VALUE ruby_xslt_xsl_obj_set( VALUE self, VALUE xsl_doc_obj ) {
  RbTxslt *pRbTxslt;
  Data_Get_Struct( self, RbTxslt, pRbTxslt );

  pRbTxslt->oXslObject = xsl_doc_obj;
  pRbTxslt->xXslString = object_to_string( xsl_doc_obj );
  if( pRbTxslt->xXslString == Qnil ) {
    rb_raise( eXSLTError, "Can't get XSL data" );
  }
  
  if( objectIsFile( xsl_doc_obj ) ) {
    pRbTxslt->iXslType = RUBY_XSLT_XSLSRC_TYPE_FILE;
    pRbTxslt->xXslData = pRbTxslt->oXslObject;
  } else {
    pRbTxslt->iXslType = RUBY_XSLT_XSLSRC_TYPE_STR;
    pRbTxslt->xXslData = pRbTxslt->xXslString;
  }
  
  pRbTxslt->iXmlResultType = RUBY_XSLT_XMLSRC_TYPE_NULL;
  
	if( pRbTxslt->tParsedXslt != NULL ) {
	  xsltFreeStylesheet(pRbTxslt->tParsedXslt);
	}
	
  pRbTxslt->tParsedXslt = parse_xsl( STR2CSTR( pRbTxslt->xXslData ), pRbTxslt->iXslType );
  if( pRbTxslt->tParsedXslt == NULL ) {
    rb_raise( eXSLTParsingError, "XSL Stylesheet parsing error" );
  }
  
  pRbTxslt->iXslType   = RUBY_XSLT_XSLSRC_TYPE_PARSED;

  return( Qnil );
}

/**
 * XML::XSLT#xslfile=<file> is deprecated. Please use XML::XSLT#xsl=<file>
 */
VALUE ruby_xslt_xsl_obj_set_d( VALUE self, VALUE xsl_doc_obj ) {
  rb_warning( "XML::XSLT#xslfile=<file> is deprecated. Please use XML::XSLT#xsl=<file> !" );
  return( ruby_xslt_xsl_obj_set( self, xsl_doc_obj ) );
}

/**
 * string = oXSLT.xsl
 *
 * Return XSL, set by XML::XSLT#xsl=, as string
 */
VALUE ruby_xslt_xsl_2str_get( VALUE self ) {
  RbTxslt *pRbTxslt;
  Data_Get_Struct( self, RbTxslt, pRbTxslt );

  return( pRbTxslt->xXslString );
}

/**
 * object = oXSLT.xslobject
 *
 * Return the XSL object set by XML::XSLT#xsl=
 */
VALUE ruby_xslt_xsl_2obj_get( VALUE self ) {
  RbTxslt *pRbTxslt;
  Data_Get_Struct( self, RbTxslt, pRbTxslt );

  return( pRbTxslt->oXslObject );
}

/**
 * ----------------------------------------------------------------------------
 */

/** 
 * output_string = oXSLT.serve( )
 *
 * Return the stylesheet transformation 
 */
VALUE ruby_xslt_serve( VALUE self ) {
  RbTxslt *pRbTxslt;
  char *xOut;
  char **pxParams = NULL;
  
  Data_Get_Struct( self, RbTxslt, pRbTxslt );

  if( pRbTxslt->iXmlResultType == RUBY_XSLT_XMLSRC_TYPE_NULL ) {

    if( pRbTxslt->pxParams != Qnil ){
      int iCpt;
    
      pxParams = (char **)ALLOCA_N( void *, pRbTxslt->iNbParams );
      MEMZERO( pxParams, void *, pRbTxslt->iNbParams );

      for( iCpt = 0; iCpt <= pRbTxslt->iNbParams - 3; iCpt++ ) {
        pxParams[iCpt] = STR2CSTR( rb_ary_entry( pRbTxslt->pxParams, iCpt ) );
      }
    }
    
    if( pRbTxslt->iXslType != RUBY_XSLT_XSLSRC_TYPE_NULL &&
        pRbTxslt->iXmlType != RUBY_XSLT_XMLSRC_TYPE_NULL ) {
      xOut = parse( pRbTxslt->tParsedXslt, pRbTxslt->tXMLDocument, pxParams );
      if( xOut == NULL ) {
        pRbTxslt->xXmlResultCache = Qnil;
        pRbTxslt->iXmlResultType = RUBY_XSLT_XMLSRC_TYPE_NULL;
      } else {
        pRbTxslt->xXmlResultCache = rb_str_new2( xOut );
        pRbTxslt->iXmlResultType = RUBY_XSLT_XMLSRC_TYPE_STR;
				free( xOut );
      }
    } else {
      pRbTxslt->xXmlResultCache = Qnil;
      pRbTxslt->iXmlResultType = RUBY_XSLT_XMLSRC_TYPE_NULL;
    }
  }

  return( pRbTxslt->xXmlResultCache );
}

/** 
 * oXSLT.save( "result.xml" ) 
 *
 * Save the stylesheet transformation to file
 */
VALUE ruby_xslt_save( VALUE self, VALUE xOutFilename ) {
  char *xOut;
  VALUE rOut;
  FILE *fOutFile;
  
  rOut = ruby_xslt_serve( self );
  
  if( rOut != Qnil ) {
    xOut = STR2CSTR( rOut );
  
    fOutFile = fopen( STR2CSTR( xOutFilename ), "w" );
    if( fOutFile == NULL ) {
      free( xOut );
      rb_raise( rb_eRuntimeError, "Can't create file %s\n", STR2CSTR( xOutFilename ) );
      rOut = Qnil;
    } else {
      fwrite( xOut, 1, strlen( xOut ), fOutFile );
      fclose( fOutFile );
    }
  }

  return( rOut );
}

/**
 * ----------------------------------------------------------------------------
 */

#ifdef USE_ERROR_HANDLER
/**
 * Brendan Taylor 
 * whateley@gmail.com
 */
/*
 * libxml2/libxslt error handling function
 *
 * converts the error to a String and passes it off to a block
 * registered using XML::XSLT.register_error_handler
 */
void ruby_xslt_error_handler(void *ctx, const char *msg, ...) {
  va_list ap;
  char *str;
  char *larger;
  int chars;
  int size = 150;

  VALUE block = rb_cvar_get(cXSLT, rb_intern("@@error_handler"));

  /* the following was cut&pasted from the libxslt python bindings */
  str = (char *) xmlMalloc(150);
  if (str == NULL)
    return;

  while (1) {
    va_start(ap, msg);
    chars = vsnprintf(str, size, msg, ap);
    va_end(ap);
    if ((chars > -1) && (chars < size))
      break;
    if (chars > -1)
      size += chars + 1;
    else
      size += 100;
    if ((larger = (char *) xmlRealloc(str, size)) == NULL) {
      xmlFree(str);
      return;
    }
    str = larger;
  }

  rb_funcall( block, rb_intern("call"), 1, rb_str_new2(str));
}
#endif

/**
 * ----------------------------------------------------------------------------
 */

/**
 * parameters support, patch from :
 * 
 * Eustáquio "TaQ" Rangel
 * eustaquiorangel@yahoo.com
 * http://beam.to/taq
 * 
 * Corrections : Greg
 */
/**
 * oXSLT.parameters={ "key" => "value", "key" => "value", ... } 
 */
VALUE ruby_xslt_parameters_set( VALUE self, VALUE parameters ) {
  RbTxslt *pRbTxslt;
  Check_Type( parameters, T_HASH );
    
  Data_Get_Struct( self, RbTxslt, pRbTxslt );

  if( !NIL_P(parameters) ){
    pRbTxslt->pxParams = rb_ary_new( );
    // each_pair and process_pair defined ind parameters.c
    (void)rb_iterate( each_pair, parameters, process_pair, pRbTxslt->pxParams );
    pRbTxslt->iNbParams = FIX2INT( rb_funcall( parameters, rb_intern("size"), 0, 0 ) ) * 2 + 2;
    pRbTxslt->iXmlResultType = RUBY_XSLT_XMLSRC_TYPE_NULL;
  }
    
  return( Qnil );
}

/**
 * ----------------------------------------------------------------------------
 */

/**
 * media type information, path from :
 *
 * Brendan Taylor 
 * whateley@gmail.com
 *
 */
/**
 * mediaTypeString = oXSLT.mediaType( )
 *
 * Return the XSL output's media type
 */
VALUE ruby_xslt_media_type( VALUE self ) {
  RbTxslt *pRbTxslt;
  xsltStylesheetPtr vXSLTSheet = NULL;
  
  Data_Get_Struct( self, RbTxslt, pRbTxslt );

  vXSLTSheet = pRbTxslt->tParsedXslt;
  
  if ( (vXSLTSheet == NULL) || (vXSLTSheet->mediaType == NULL) ) {
    return Qnil;
  } else {
    return rb_str_new2( (char *)(vXSLTSheet->mediaType) );
  }
}

/**
 * ----------------------------------------------------------------------------
 */

/**
 * internal use only.
 */
 VALUE ruby_xslt_reg_function( VALUE class, VALUE namespace, VALUE name ) {
   xsltRegisterExtModuleFunction( BAD_CAST STR2CSTR(name), BAD_CAST STR2CSTR(namespace), xmlXPathFuncCallback );

   return Qnil;
 }

/** 
 * string = oXSLT.xsl_to_s( ) 
 */
VALUE ruby_xslt_to_s( VALUE self ) {
  VALUE vStrOut;
  RbTxslt *pRbTxslt;
  xsltStylesheetPtr vXSLTSheet = NULL;
  char *xKlassName = rb_class2name( CLASS_OF( self ) );

  Data_Get_Struct( self, RbTxslt, pRbTxslt );

  //vXSLTSheet = xsltParseStylesheetDoc( xmlParseMemory( STR2CSTR( pRbTxslt->xXslData ), strlen( STR2CSTR( pRbTxslt->xXslData ) ) ) );
  vXSLTSheet = pRbTxslt->tParsedXslt;
  if (vXSLTSheet == NULL) return Qnil;

  vStrOut = rb_str_new( 0, strlen(xKlassName)+1024 );
  (void) sprintf( RSTRING(vStrOut)->ptr,
         "#<%s: parent=%p,next=%p,imports=%p,docList=%p,"
         "doc=%p,stripSpaces=%p,stripAll=%d,cdataSection=%p,"
         "variables=%p,templates=%p,templatesHash=%p,"
         "rootMatch=%p,keyMatch=%p,elemMatch=%p,"
         "attrMatch=%p,parentMatch=%p,textMatch=%p,"
         "piMatch=%p,commentMatch=%p,nsAliases=%p,"
         "attributeSets=%p,nsHash=%p,nsDefs=%p,keys=%p,"
         "method=%s,methodURI=%s,version=%s,encoding=%s,"
         "omitXmlDeclaration=%d,decimalFormat=%p,standalone=%d,"
         "doctypePublic=%s,doctypeSystem=%s,indent=%d,"
         "mediaType=%s,preComps=%p,warnings=%d,errors=%d,"
         "exclPrefix=%s,exclPrefixTab=%p,exclPrefixNr=%d,"
         "exclPrefixMax=%d>",
         xKlassName,
         vXSLTSheet->parent, vXSLTSheet->next, vXSLTSheet->imports, vXSLTSheet->docList,
         vXSLTSheet->doc, vXSLTSheet->stripSpaces, vXSLTSheet->stripAll, vXSLTSheet->cdataSection,
         vXSLTSheet->variables, vXSLTSheet->templates, vXSLTSheet->templatesHash,
         vXSLTSheet->rootMatch, vXSLTSheet->keyMatch, vXSLTSheet->elemMatch,
         vXSLTSheet->attrMatch, vXSLTSheet->parentMatch, vXSLTSheet->textMatch,
         vXSLTSheet->piMatch, vXSLTSheet->commentMatch, vXSLTSheet->nsAliases,
         vXSLTSheet->attributeSets, vXSLTSheet->nsHash, vXSLTSheet->nsDefs, vXSLTSheet->keys,
         vXSLTSheet->method, vXSLTSheet->methodURI, vXSLTSheet->version, vXSLTSheet->encoding,
         vXSLTSheet->omitXmlDeclaration, vXSLTSheet->decimalFormat, vXSLTSheet->standalone,
         vXSLTSheet->doctypePublic, vXSLTSheet->doctypeSystem, vXSLTSheet->indent,
         vXSLTSheet->mediaType, vXSLTSheet->preComps, vXSLTSheet->warnings, vXSLTSheet->errors,
         vXSLTSheet->exclPrefix, vXSLTSheet->exclPrefixTab, vXSLTSheet->exclPrefixNr,
         vXSLTSheet->exclPrefixMax );

  RSTRING(vStrOut)->len = strlen( RSTRING(vStrOut)->ptr );
  if( OBJ_TAINTED(self) ) OBJ_TAINT(vStrOut);

  // xsltFreeStylesheet(vXSLTSheet);

  return( vStrOut );
}

/**
 * ----------------------------------------------------------------------------
 */

void Init_xslt_lib( void ) {
  mXML  = rb_define_module( "XML" );
  cXSLT = rb_define_class_under( mXML, "XSLT", rb_cObject );

	eXSLTError = rb_define_class_under( cXSLT, "XSLTError", rb_eRuntimeError );
	eXSLTParsingError = rb_define_class_under( cXSLT, "ParsingError", eXSLTError );
	eXSLTTransformationError = rb_define_class_under( cXSLT, "TransformationError", eXSLTError );

  rb_define_const( cXSLT, "MAX_DEPTH",            INT2NUM(xsltMaxDepth) );
  rb_define_const( cXSLT, "MAX_SORT",             INT2NUM(XSLT_MAX_SORT) );
  rb_define_const( cXSLT, "ENGINE_VERSION",       rb_str_new2(xsltEngineVersion) );
  rb_define_const( cXSLT, "LIBXSLT_VERSION",      INT2NUM(xsltLibxsltVersion) );
  rb_define_const( cXSLT, "LIBXML_VERSION",       INT2NUM(xsltLibxmlVersion) );
  rb_define_const( cXSLT, "XSLT_NAMESPACE",       rb_str_new2((char *)XSLT_NAMESPACE) );
  rb_define_const( cXSLT, "DEFAULT_VENDOR",       rb_str_new2(XSLT_DEFAULT_VENDOR) );
  rb_define_const( cXSLT, "DEFAULT_VERSION",      rb_str_new2(XSLT_DEFAULT_VERSION) );
  rb_define_const( cXSLT, "DEFAULT_URL",          rb_str_new2(XSLT_DEFAULT_URL) );
  rb_define_const( cXSLT, "NAMESPACE_LIBXSLT",    rb_str_new2((char *)XSLT_LIBXSLT_NAMESPACE) );
  rb_define_const( cXSLT, "NAMESPACE_NORM_SAXON", rb_str_new2((char *)XSLT_NORM_SAXON_NAMESPACE) );
  rb_define_const( cXSLT, "NAMESPACE_SAXON",      rb_str_new2((char *)XSLT_SAXON_NAMESPACE) );
  rb_define_const( cXSLT, "NAMESPACE_XT",         rb_str_new2((char *)XSLT_XT_NAMESPACE) );
  rb_define_const( cXSLT, "NAMESPACE_XALAN",      rb_str_new2((char *)XSLT_XALAN_NAMESPACE) );
  
  rb_define_const( cXSLT, "RUBY_XSLT_VERSION",    rb_str_new2(RUBY_XSLT_VERSION) );

  rb_define_singleton_method( cXSLT, "new", ruby_xslt_new, 0 );
  rb_define_singleton_method( cXSLT, "registerFunction", ruby_xslt_reg_function, 2);

  rb_define_method( cXSLT, "serve",       ruby_xslt_serve,          0 );
  rb_define_method( cXSLT, "save",        ruby_xslt_save,           1 );

  rb_define_method( cXSLT, "xml=",        ruby_xslt_xml_obj_set,    1 );
  rb_define_method( cXSLT, "xmlfile=",    ruby_xslt_xml_obj_set_d,  1 ); // DEPRECATED
  rb_define_method( cXSLT, "xml",         ruby_xslt_xml_2str_get,   0 );
  rb_define_method( cXSLT, "xmlobject",   ruby_xslt_xml_2obj_get,   0 );

  rb_define_method( cXSLT, "xsl=",        ruby_xslt_xsl_obj_set,    1 );
  rb_define_method( cXSLT, "xslfile=",    ruby_xslt_xsl_obj_set_d,  1 ); // DEPRECATED
  rb_define_method( cXSLT, "xsl",         ruby_xslt_xsl_2str_get,   0 );
  rb_define_method( cXSLT, "xslobject",   ruby_xslt_xsl_2obj_get,   0 );

  rb_define_method( cXSLT, "parameters=", ruby_xslt_parameters_set, 1 );
  rb_define_method( cXSLT, "xsl_to_s",    ruby_xslt_to_s,           0 );

  rb_define_method( cXSLT, "mediaType",   ruby_xslt_media_type,     0 );

#ifdef USE_ERROR_HANDLER
  xmlSetGenericErrorFunc( NULL, ruby_xslt_error_handler );
  xsltSetGenericErrorFunc( NULL, ruby_xslt_error_handler );
#endif

#ifdef USE_EXSLT
  exsltRegisterAll();
#endif
}
