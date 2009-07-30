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

extern VALUE mXML;
extern VALUE cXSLT;

/**
 * external function support, patch from :
 *
 * Brendan Taylor 
 * whateley@gmail.com
 *
 */


/*  converts an xmlXPathObjectPtr to a Ruby VALUE 
 * number -> float
 * boolean -> boolean
 * string -> string
 * nodeset -> an array of REXML::Elements
 */
VALUE xpathObj2value(xmlXPathObjectPtr obj, xmlDocPtr doc)
{
  VALUE ret = Qnil;

  if (obj == NULL) {
    return ret;
  }

  switch (obj->type) {
    case XPATH_NODESET:
      rb_require("rexml/document");
      ret = rb_ary_new();
      
      if ((obj->nodesetval != NULL) && (obj->nodesetval->nodeNr != 0)) {
        xmlBufferPtr buff = xmlBufferCreate();
        xmlNodePtr node;
        int i;

        // this assumes all the nodes are elements, which is a bad idea
        for (i = 0; i < obj->nodesetval->nodeNr; i++) {
          node = obj->nodesetval->nodeTab[i];

          if( node->type == XML_ELEMENT_NODE ) {
            xmlNodeDump(buff, doc, node, 0, 0);

            VALUE cREXML = rb_const_get(rb_cObject, rb_intern("REXML"));
            VALUE cDocument = rb_const_get(cREXML, rb_intern("Document"));
            VALUE rDocument = rb_funcall(cDocument, rb_intern("new"), 1,rb_str_new2((char *)buff->content));
            VALUE rElement = rb_funcall(rDocument, rb_intern("root"), 0);

            rb_ary_push(ret, rElement);
          
            // empty the buffer (xmlNodeDump appends rather than replaces)
            xmlBufferEmpty(buff);
          } else if ( node->type == XML_TEXT_NODE ) {
            rb_ary_push(ret, rb_str_new2((char *)node->content));
          } else if ( node->type == XML_ATTRIBUTE_NODE ) {
						// BUG: should ensure children is not null (shouldn't)
						rb_ary_push(ret, rb_str_new2((char *)node->children->content));
					} else {
						rb_warning( "Unsupported node type in node set: %d", node->type );
					}
        }
        xmlBufferFree(buff);
      }
      break;
    case XPATH_BOOLEAN:
      ret = obj->boolval ? Qtrue : Qfalse;
      break;
    case XPATH_NUMBER:
      ret = rb_float_new(obj->floatval);
      break;
    case XPATH_STRING:
      ret = rb_str_new2((char *) obj->stringval);
      break;
    /* these cases were in libxslt's python bindings, but i don't know what they are, so i'll leave them alone */
    case XPATH_XSLT_TREE:
    case XPATH_POINT:
    case XPATH_RANGE:
    case XPATH_LOCATIONSET:
    default:    
      rb_warning("xpathObj2value: can't convert XPath object type %d to Ruby object\n", obj->type );
  }
  xmlXPathFreeObject(obj);
  return ret;
}

/* 
 *  converts a Ruby VALUE to an xmlXPathObjectPtr
 * boolean -> boolean
 * number -> number
 * string -> escaped string
 * array -> array of parsed nodes
 */
xmlXPathObjectPtr value2xpathObj (VALUE val) {
  xmlXPathObjectPtr ret = NULL;
 
  switch (TYPE(val)) {
    case T_TRUE:
    case T_FALSE:
      ret = xmlXPathNewBoolean(RTEST(val));
      break;
    case T_FIXNUM:
    case T_FLOAT:
      ret = xmlXPathNewFloat(NUM2DBL(val));
      break;
    case T_STRING:
    {
      xmlChar *str;

    // we need the Strdup (this is the major bugfix for 0.8.1)
      str = xmlStrdup((const xmlChar *) STR2CSTR(val));
      ret = xmlXPathWrapString(str);
    }
      break;
    case T_NIL:
      ret = xmlXPathNewNodeSet(NULL);
      break;
    case T_ARRAY: {
      int i,j;
      ret = xmlXPathNewNodeSet(NULL);

      for(i = RARRAY(val)->len; i > 0; i--) {
        xmlXPathObjectPtr obj = value2xpathObj( rb_ary_shift( val ) );
        if ((obj->nodesetval != NULL) && (obj->nodesetval->nodeNr != 0)) {
          for(j = 0; j < obj->nodesetval->nodeNr; j++) {
            xmlXPathNodeSetAdd( ret->nodesetval, obj->nodesetval->nodeTab[j] );
          }
        }
      }
      break;  }
    case T_DATA:
    case T_OBJECT: {
      if( strcmp( getRubyObjectName( val ), "REXML::Document" ) == 0 || strcmp(getRubyObjectName( val ),  "REXML::Element") == 0 ) {

        VALUE to_s = rb_funcall( val, rb_intern( "to_s" ), 0 );
        xmlDocPtr doc = xmlParseDoc((xmlChar *) STR2CSTR(to_s));

        ret = xmlXPathNewNodeSet((xmlNode *)doc->children);
        break;
      } else if( strcmp( getRubyObjectName( val ), "REXML::Text" ) == 0 ) {
        VALUE to_s = rb_funcall( val, rb_intern( "to_s" ), 0 );

        xmlChar *str;

        str = xmlStrdup((const xmlChar *) STR2CSTR(to_s));
        ret = xmlXPathWrapString(str);
        break;
      }
      // this drops through so i can reuse the error message
    }
    default:
      rb_warning( "value2xpathObj: can't convert class %s to XPath object\n", getRubyObjectName(val));
      return NULL;
  }

  return ret;
}

/*
 *  chooses what registered function to call and calls it
 */
void xmlXPathFuncCallback( xmlXPathParserContextPtr ctxt, int nargs) {
  VALUE result, arguments[nargs];
  VALUE ns_hash, func_hash, block;
  const xmlChar *namespace, *name;
  xmlXPathObjectPtr obj;
  int i;

  if (ctxt == NULL || ctxt->context == NULL)
    return;

  name = ctxt->context->function;
  namespace = ctxt->context->functionURI;

  ns_hash = rb_cvar_get(cXSLT, rb_intern("@@extFunctions"));
  
  func_hash = rb_hash_aref(ns_hash, rb_str_new2((char *)namespace));

  if(func_hash == Qnil) {
    rb_warning( "xmlXPathFuncCallback: namespace %s not registered!\n", namespace );
  }

  block = rb_hash_aref(func_hash, rb_str_new2((char *)name));

  for (i = nargs - 1; i >= 0; i--) {
    obj = valuePop(ctxt);
    arguments[i] = xpathObj2value(obj, ctxt->context->doc);
  }
  
  result = rb_funcall2( block, rb_intern("call"), nargs, arguments);
  
  obj = value2xpathObj(result);
  valuePush(ctxt, obj);
}
