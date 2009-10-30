<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:ns2="http://www.w3.org/1999/xlink">
    <!--
        *******************************************************************
        *                                                                 *
        * VERSION:          1.01                                          *
        *                                                                 *
        * AUTHOR:           Winona Salesky                                *
        *                   wsalesky@gmail.com                            *
        *                                                                 *
        *                                                                 *
        * ABOUT:           This file has been created for use with        *
        *                  the Archivists' Toolkit  July 30 2008.         *
        *                  this file calls lookupLists.xsl, which         *
        *                  should be located in the same folder.          *
        *                                                                 *
        * UPDATED          March 23, 2009                                 *
        *                  Added revision description and date,           * 
        *                  and publication information                    *
        *                  March 12, 2009                                 *
        *                  Fixed character encoding issues                *
        *                  March 11, 2009                                 *
        *                  Added repository branding device to header     *
        *                  March 1, 2009                                  *
        *                  Changed bulk date display for unitdates        *
        *                  Feb. 6, 2009                                   *
        *                  Added roles to creator display in summary      * 
        *******************************************************************
    -->
    
    <xsl:strip-space elements="*"/>
    <xsl:output indent="yes" method="xhtml" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" encoding="utf-8"/>

<!--    
<xsl:include href="reports/Resources/eadToPdf/lookupLists.xsl"/>
-->

    <!--<xsl:include href="lookupLists.xsl"/>-->
    <!-- Creates the body of the finding aid.-->
    <xsl:template match="/">
        <xsl:apply-templates select="/c"/>
    </xsl:template>

    <!-- CSS for styling HTML output. Place all CSS styles in this template.-->
    <xsl:template name="css">
        <style type="text/css">
            html {
                margin: 0;
                padding: 0;
                }
                
            body {
                color: #333;
                font-family: Verdana, Arial, Helvetica, sans-serif; 
                font-size: 93%;
                margin: 0px;
                padding: 0px;
                text-align: center;
                }
            
            /*--- Main Div styles ---*/
            div#main{
                margin: 0 auto; 
                width: 95%; 
                text-align:left;
                }
            
            #header {
                margin:10px 0px;
                padding:0;
                display:block;
                width: 100%;
                /*height: 50px;
                overflow:hidden;*/
                background-color: #fff;
                border-top: 5px solid #000;
                border-bottom: 1px solid #000;
                text-align:right;
                }
            #header h3 {
                display:inline;
                font-size: 138.5%; 
                margin: 20px 20px 0px 25px; 
                padding-top:20px; color:#000; 
                font-weight: lighter; 
                text-align:right;
                }
            #header img{display:inline; vertical-align: bottom; padding-top: 2px;}
            #title {
                display: block; 
                margin:0; 
                height: 125px; 
                padding: 16px 8px; 
                background-color:#000; 
                text-align: center; 
                color: #fff;
                }
            
            #title h1 {margin:0; padding:0; font-size: 197%; font-weight: lighter;}
            #title h2 {margin:0; padding:0; font-size:161.6%; font-weight: lighter;}
            
            /*--- Main Content Div ---*/
            #contents {
                display:block; 
                margin: 10px 0px; 
                border-top: 1px solid #000; 
                border-bottom: 1px solid #000;
                }
                
            /*--- Table of Contents styles ---*/
            #toc {
                display:block;
                width: 225px;
                position: relative;
                float:left;
                clear:left;
                margin: 0 16px 0 8px;
                padding-left: 8px;
                border-right: 1px solid #000;
                }
                
            #toc h3 {margin: 16px 8px 16px 0px;}
            #toc dt {margin: 3px; padding: 4px 0px; font-weight: normal;} 
            #toc dd {margin-top: 3px; margin-left: 16px; padding: 4px 0px;}
            #toc dt a:link, #toc dd a:link {color: #333; text-decoration: none;} 
            #toc dt a:visited, #toc dd a:visited {color: #333; text-decoration: none;} 
            #toc dt a:active, #toc dd a:active {color: #FF5721;} 
            #toc dt  a:hover, #toc dd  a:hover {color: #FF5721;} 
            
            /*--- EAD body ---*/
            #content-right {display:block; margin-left:275px; margin-right: 10px;}
            
            /*--- Typography ---*/
            h1, h2, h3, h4 {font-family: Verdana, Arial, Helvetica, sans-serif; } 
            #contents h3 {
                margin: 16px 8px 16px -8px;
                font-size: 116%; 
                font-variant: small-caps; 
                border-bottom: 1px dashed #999;
                }
                
            h4 {
                font-size: 93%; 
                margin: 24px 8px 4px -4px; 
                padding:0; color: #555;
                }
                
            p {margin: 8px;}
            dt {margin: 2px 8px; font-weight:bold; }
            dd {margin: 2px 16px;}
            br {margin:0; padding:0;}
            hr {border:1px solid #000; margin: 24px -8px;}
            .summary dt {margin:16px 8px 0px 8px; color: #555;}
            .summary dd {margin: 2px 24px 2px 24px;}
            .returnTOC {font-size: 85%; margin-top: 24px;}
            .returnTOC  a:link {color: #FF5721; text-decoration: none;} 
            .returnTOC a:visited	{color: #FF5721; text-decoration: none;} 
            .returnTOC  a:active	{color: #EE0000;}             
            .returnTOC  a:hover		{color: #EE0000;} 
            
            /*--- Emph styles -------*/
            .smcaps {font-variant: small-caps;}
            .underline {text-decoration: underline;}
            
            /*--- Styles Index entry elements ---*/
            .indexEntry {display:block}
            
            /*---- Table Styles ---*/
            table { 
                border-top: 1px solid #000; 
                border-bottom: 1px solid #000; 
                margin: 16px; width: 60%; 
                font-size: 93%;
                }
                
            th {background-color:#000; color: #fff;}
            td {vertical-align: top; padding: 5px 8px;}
            
            /*---Container List Styles  --*/           
            table.containerList {border:none; margin: 8px; width: auto;}
            table.containerList h4 {margin: 2px 8px;}
            tr.series{background-color: #bbbbbb;}
            tr.subseries{background-color: #dddddd;}
            .containerHeader {font-variant: small-caps; font-weight:bold; color:#555; text-align: center;}
            .container {text-align:center;}
            
            /*--- Clevel Margins ---*/
            table td.c{padding-left: 0;}
            table td.c01{padding-left: 0;}
            table td.c02{padding-left:  8px;}                
            table td.c03{padding-left: 16px;}
            table td.c04{padding-left: 24px;}
            table td.c05{padding-left: 32px;}
            table td.c06{padding-left: 40px;}
            table td.c07{padding-left: 48px;}
            table td.c08{padding-left: 56px;}
            
            
            .address {display:block; margin: 8px;}
            .odd{background-color:#eee;}
            .citation{
                border: 1px dashed #999; 
                background-color: #eee; 
                margin: 24px 8px; 
                padding: 8px 8px 8px 24px;
                }
            .citation h4 {margin-top: 8px;}
            
            /*---List Styles---*/
            .simple{list-style-type: none;}
            .arabic {list-style-type: decimal}
            .upperalpha{list-style-type: lower-alpha}
            .loweralpha{list-style-type: upper-alpha}
            .upperroman{list-style-type: upper-roman}
            .lowerroman{list-style-type: lower-roman}
        </style>
    </xsl:template>

    <!-- This template creates a customizable header  -->
    <xsl:template name="header">
        <div id="header">
            <div>
            <h3>
                <xsl:value-of select="/ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt/ead:publisher"/>
            </h3>
            <!-- Adds repositry branding device, looks best if this is under 100px high. -->
             <xsl:if test="/ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt/ead:p/ead:extref">
                 <img src="{/ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt/ead:p/ead:extref/@ns2:href}" />
             </xsl:if>
            </div>
        </div>    
    </xsl:template>

    <!-- HTML meta tags for use by web search engines for indexing. -->
    <xsl:template name="metadata">
        <meta http-equiv="Content-Type" name="dc.title"
            content="{concat(/ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper,' ',/ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:subtitle)}"/>
        <meta http-equiv="Content-Type" name="dc.author"
            content="{/ead:ead/ead:archdesc/ead:did/ead:origination}"/>
        <xsl:for-each select="/ead:ead/ead:archdesc/controlaccess/descendant::*">
            <meta http-equiv="Content-Type" name="dc.subject" content="{.}"/>
        </xsl:for-each>
        <meta http-equiv="Content-Type" name="dc.type" content="text"/>
        <meta http-equiv="Content-Type" name="dc.format" content="manuscripts"/>
        <meta http-equiv="Content-Type" name="dc.format" content="finding aids"/>
    </xsl:template>

    <!-- Creates an ordered table of contents that matches the order of the archdesc 
        elements. To change the order rearrange the if/for-each statements. -->  
    <xsl:template name="toc">
        <div id="toc">
            <h3>Table of Contents</h3>
            <dl>
                <xsl:if test="/ead:ead/ead:archdesc/ead:did">
                    <dt><a href="#{generate-id(.)}">Summary Information</a></dt>
                </xsl:if>
                <xsl:for-each select="/ead:ead/ead:archdesc/ead:bioghist">
                        <dt>                                
                            <a><xsl:call-template name="tocLinks"/>
                                <xsl:choose>
                                    <xsl:when test="ead:head">
                                        <xsl:value-of select="ead:head"/></xsl:when>
                                    <xsl:otherwise>Biography/History</xsl:otherwise>
                                </xsl:choose>
                            </a>
                        </dt>   
                </xsl:for-each>
                <xsl:for-each select="/ead:ead/ead:archdesc/ead:scopecontent">
                    <dt>                                
                        <a><xsl:call-template name="tocLinks"/>
                            <xsl:choose>
                                <xsl:when test="ead:head">
                                    <xsl:value-of select="ead:head"/></xsl:when>
                                <xsl:otherwise>Scope and Content</xsl:otherwise>
                            </xsl:choose>
                        </a>
                    </dt>   
                </xsl:for-each>
                <xsl:for-each select="/ead:ead/ead:archdesc/ead:arrangement">
                    <dt>                                
                        <a><xsl:call-template name="tocLinks"/>
                            <xsl:choose>
                                <xsl:when test="ead:head">
                                    <xsl:value-of select="ead:head"/></xsl:when>
                                <xsl:otherwise>Arrangement</xsl:otherwise>
                            </xsl:choose>
                        </a>
                    </dt>   
                </xsl:for-each>
                <xsl:for-each select="/ead:ead/ead:archdesc/ead:fileplan">
                    <dt>                                
                        <a><xsl:call-template name="tocLinks"/>
                            <xsl:choose>
                                <xsl:when test="ead:head">
                                    <xsl:value-of select="ead:head"/></xsl:when>
                                <xsl:otherwise>File Plan</xsl:otherwise>
                            </xsl:choose>
                        </a>
                    </dt>   
               </xsl:for-each>
                
                <!-- Administrative Information  -->
                <xsl:if test="/ead:ead/ead:archdesc/ead:accessrestrict or
                    /ead:ead/ead:archdesc/ead:userestrict or
                    /ead:ead/ead:archdesc/custodhist or
                    /ead:ead/ead:archdesc/ead:accruals or
                    /ead:ead/ead:archdesc/ead:altformavail or
                    /ead:ead/ead:archdesc/ead:acqinfo or
                    /ead:ead/ead:archdesc/ead:processinfo or
                    /ead:ead/ead:archdesc/ead:appraisal or
                    /ead:ead/ead:archdesc/ead:originalsloc">
                    <dt><a href="#adminInfo">Administrative Information</a></dt>
                </xsl:if>
                
                <!-- Related Materials -->
                <xsl:if test="/ead:ead/ead:archdesc/ead:relatedmaterial or /ead:ead/ead:archdesc/ead:separatedmaterial">
                    <dt><a href="#relMat">Related Materials</a></dt>
                </xsl:if>
                <xsl:for-each select="/ead:ead/ead:archdesc/controlaccess">
                    <dt>                                
                        <a><xsl:call-template name="tocLinks"/>
                            <xsl:choose>
                                <xsl:when test="ead:head">
                                    <xsl:value-of select="ead:head"/></xsl:when>
                                <xsl:otherwise>Controlled Access Headings</xsl:otherwise>
                            </xsl:choose>
                        </a>
                    </dt>   
                </xsl:for-each>
                <xsl:for-each select="/ead:ead/ead:archdesc/ead:otherfindaid">
                    <dt>                                
                        <a><xsl:call-template name="tocLinks"/>
                            <xsl:choose>
                                <xsl:when test="ead:head">
                                    <xsl:value-of select="ead:head"/></xsl:when>
                                <xsl:otherwise>Other Finding Aids</xsl:otherwise>
                            </xsl:choose>
                        </a>
                    </dt>   
                </xsl:for-each>
                <xsl:for-each select="/ead:ead/ead:archdesc/ead:phystech">
                    <dt>                                
                        <a><xsl:call-template name="tocLinks"/>
                            <xsl:choose>
                                <xsl:when test="ead:head"><xsl:value-of select="ead:head"/></xsl:when>
                                <xsl:otherwise>Technical Requirements</xsl:otherwise>
                            </xsl:choose>
                        </a>
                    </dt>
                </xsl:for-each>
                <xsl:for-each select="/ead:ead/ead:archdesc/ead:odd">
                    <dt>                                
                        <a><xsl:call-template name="tocLinks"/>
                            <xsl:choose>
                                <xsl:when test="ead:head">
                                    <xsl:value-of select="ead:head"/></xsl:when>
                                <xsl:otherwise>Other Descriptive Data</xsl:otherwise>
                            </xsl:choose>
                        </a>
                    </dt>
                </xsl:for-each>
                <xsl:for-each select="/ead:ead/ead:archdesc/ead:bibliography">
                    <dt>                                
                        <a><xsl:call-template name="tocLinks"/>
                            <xsl:choose>
                                <xsl:when test="ead:head">
                                    <xsl:value-of select="ead:head"/></xsl:when>
                                <xsl:otherwise>Bibliography</xsl:otherwise>
                            </xsl:choose>
                        </a>
                    </dt>
                </xsl:for-each>
                <xsl:for-each select="/ead:ead/ead:archdesc/ead:index">
                    <dt>                                
                        <a><xsl:call-template name="tocLinks"/>
                            <xsl:choose>
                                <xsl:when test="ead:head">
                                    <xsl:value-of select="ead:head"/></xsl:when>
                                <xsl:otherwise>Index</xsl:otherwise>
                            </xsl:choose>
                        </a>
                    </dt>
                </xsl:for-each> 
                <xsl:for-each select="/ead:ead/ead:archdesc/ead:dsc">
                    <xsl:if test="child::*">
                        <dt>                                
                            <a><xsl:call-template name="tocLinks"/>
                                <xsl:choose>
                                    <xsl:when test="ead:head">
                                        <xsl:value-of select="ead:head"/></xsl:when>
                                    <xsl:otherwise>Collection Inventory</xsl:otherwise>
                                </xsl:choose>
                            </a>
                        </dt>                
                    </xsl:if>
                    <!--Creates a submenu for collections, record groups and series and fonds-->
                    <xsl:for-each select="child::*[@level = 'collection'] 
                        | child::*[@level = 'recordgrp']  | child::*[@level = 'series'] | child::*[@level = 'fonds']">
                        <dd><a><xsl:call-template name="tocLinks"/>
                            <xsl:choose>
                                <xsl:when test="ead:head">
                                    <xsl:apply-templates select="child::*/ead:head"/>        
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="child::*/ead:unittitle"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </a></dd>
                    </xsl:for-each>
                </xsl:for-each>
            </dl>
        </div>
    </xsl:template>
 
     <!-- Named template for a generic p element with a link back to the table of contents  -->
    <xsl:template name="returnTOC">                
        <p class="returnTOC"><a href="#toc">Return to Table of Contents »</a></p>
        <hr/>
    </xsl:template>
    <xsl:template match="ead:eadheader">
        <h1 id="{generate-id(ead:filedesc/ead:titlestmt/ead:titleproper)}">
            <xsl:apply-templates select="ead:filedesc/ead:titlestmt/ead:titleproper"/>     
        </h1>
        <xsl:if test="ead:filedesc/ead:titlestmt/ead:subtitle">
            <h2>
                <xsl:apply-templates select="ead:filedesc/ead:titlestmt/ead:subtitle"/>
            </h2>                
        </xsl:if>
    </xsl:template>
    <xsl:template match="ead:filedesc/ead:titlestmt/ead:titleproper">
        <xsl:choose>
            <xsl:when test="@type = 'filing'">
                <xsl:choose>
                    <xsl:when test="count(parent::*/ead:titleproper) &gt; 1"/>
                    <xsl:otherwise>
                        <xsl:value-of select="/ead:ead/ead:archdesc/ead:did/ead:unittitle"/>        
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="ead:filedesc/ead:titlestmt/ead:titleproper/ead:num"><br/><xsl:apply-templates/></xsl:template>
    <xsl:template match="ead:archdesc/ead:did">
        <h3>
            <a name="{generate-id(.)}">
                <xsl:choose>
                    <xsl:when test="ead:head">
                        <xsl:value-of select="ead:head"/>
                    </xsl:when>
                    <xsl:otherwise>
                        Summary Information
                    </xsl:otherwise>
                </xsl:choose>
            </a>
        </h3>
        <!-- Determines the order in wich elements from the archdesc did appear, 
            to change the order of appearance for the children of did
            by changing the order of the following statements.-->
        <dl class="summary">
            <xsl:apply-templates select="ead:repository"/>
            <xsl:apply-templates select="ead:origination"/>
            <xsl:apply-templates select="ead:unittitle"/>    
            <xsl:apply-templates select="ead:unitid"/>
            <xsl:apply-templates select="ead:unitdate"/>
            <xsl:apply-templates select="ead:physdesc"/>        
            <xsl:apply-templates select="ead:physloc"/>        
            <xsl:apply-templates select="ead:langmaterial"/>
            <xsl:apply-templates select="ead:materialspec"/>
            <xsl:apply-templates select="container"/>
            <xsl:apply-templates select="ead:abstract"/> 
            <xsl:apply-templates select="ead:note"/>
        </dl>
            <xsl:apply-templates select="../ead:prefercite"/>
        <xsl:call-template name="returnTOC"/>
    </xsl:template>
    <!-- Template calls and formats the children of archdesc/did -->
    <xsl:template match="ead:archdesc/ead:did/ead:repository | ead:archdesc/ead:did/ead:unittitle | ead:archdesc/ead:did/ead:unitid | ead:archdesc/ead:did/ead:origination 
        | ead:archdesc/ead:did/ead:unitdate | ead:archdesc/ead:did/ead:physdesc | ead:archdesc/ead:did/ead:physloc 
        | ead:archdesc/ead:did/ead:abstract | ead:archdesc/ead:did/ead:langmaterial | ead:archdesc/ead:did/ead:materialspec | ead:archdesc/ead:did/container">
        <dt>
            <xsl:choose>
                <xsl:when test="@label">
                    <xsl:value-of select="concat(translate( substring(@label, 1, 1 ),
                        'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' ), 
                        substring(@label, 2, string-length(@label )))" />
                    <xsl:if test="@type"> [<xsl:value-of select="@type"/>]</xsl:if>
                    <xsl:if test="self::ead:origination">
                        <xsl:choose>
                            <xsl:when test="ead:persname[@role != ''] and contains(ead:persname/@role,' (')">
                                - <xsl:value-of select="substring-before(ead:persname/@role,' (')"/>
                            </xsl:when>
                            <xsl:when test="ead:persname[@role != '']">
                                - <xsl:value-of select="ead:persname/@role"/>  
                            </xsl:when>
                            <xsl:otherwise/>
                        </xsl:choose>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="self::ead:repository">Repository</xsl:when>
                        <xsl:when test="self::ead:unittitle">Title</xsl:when>
                        <xsl:when test="self::ead:unitid">ID</xsl:when>
                        <xsl:when test="self::ead:unitdate">Date<xsl:if test="@type"> [<xsl:value-of select="@type"/>]</xsl:if></xsl:when>
                        <xsl:when test="self::ead:origination">
                            <xsl:choose>
                                <xsl:when test="ead:persname[@role != ''] and contains(ead:persname/@role,' (')">
                                    Creator - <xsl:value-of select="substring-before(ead:persname/@role,' (')"/>
                                </xsl:when>
                                <xsl:when test="ead:persname[@role != '']">
                                    Creator - <xsl:value-of select="ead:persname/@role"/>  
                                </xsl:when>
                                <xsl:otherwise>
                                    Creator        
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="self::ead:physdesc">Extent</xsl:when>
                        <xsl:when test="self::ead:abstract">Abstract</xsl:when>
                        <xsl:when test="self::ead:physloc">Location</xsl:when>
                        <xsl:when test="self::ead:langmaterial">Language</xsl:when>
                        <xsl:when test="self::ead:materialspec">Technical</xsl:when>
                        <xsl:when test="self::container">Container</xsl:when>
                        <xsl:when test="self::ead:note">Note</xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </dt>
        <dd>
            <xsl:apply-templates/>
        </dd>
    </xsl:template>
    <!-- Template calls and formats all other children of archdesc many of 
        these elements are repeatable within the ead:dsc section as well.-->
    <xsl:template match="ead:bibliography | ead:odd | ead:accruals | ead:arrangement  | ead:bioghist 
        | ead:accessrestrict | ead:userestrict  | custodhist | ead:altformavail | ead:originalsloc 
        | ead:fileplan | ead:acqinfo | ead:otherfindaid | ead:phystech | ead:processinfo | ead:relatedmaterial
        | ead:scopecontent  | ead:separatedmaterial | ead:appraisal">        
        <xsl:choose>
            <xsl:when test="ead:head"><xsl:apply-templates/></xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="parent::ead:archdesc">
                            <xsl:choose>
                                <xsl:when test="self::ead:bibliography"><h3><xsl:call-template name="anchor"/>Bibliography</h3></xsl:when>
                                <xsl:when test="self::ead:odd"><h3><xsl:call-template name="anchor"/>Other Descriptive Data</h3></xsl:when>
                                <xsl:when test="self::ead:accruals"><h4><xsl:call-template name="anchor"/>Accruals</h4></xsl:when>
                                <xsl:when test="self::ead:arrangement"><h3><xsl:call-template name="anchor"/>Arrangement</h3></xsl:when>
                                <xsl:when test="self::ead:bioghist"><h3><xsl:call-template name="anchor"/>Biography/History</h3></xsl:when>
                                <xsl:when test="self::ead:accessrestrict"><h4><xsl:call-template name="anchor"/>Restrictions on Access</h4></xsl:when>
                                <xsl:when test="self::ead:userestrict"><h4><xsl:call-template name="anchor"/>Restrictions on Use</h4></xsl:when>
                                <xsl:when test="self::custodhist"><h4><xsl:call-template name="anchor"/>Custodial History</h4></xsl:when>
                                <xsl:when test="self::ead:altformavail"><h4><xsl:call-template name="anchor"/>Alternative Form Available</h4></xsl:when>
                                <xsl:when test="self::ead:originalsloc"><h4><xsl:call-template name="anchor"/>Original Location</h4></xsl:when>
                                <xsl:when test="self::ead:fileplan"><h3><xsl:call-template name="anchor"/>File Plan</h3></xsl:when>
                                <xsl:when test="self::ead:acqinfo"><h4><xsl:call-template name="anchor"/>Acquisition Information</h4></xsl:when>
                                <xsl:when test="self::ead:otherfindaid"><h3><xsl:call-template name="anchor"/>Other Finding Aids</h3></xsl:when>
                                <xsl:when test="self::ead:phystech"><h3><xsl:call-template name="anchor"/>Physical Characteristics and Technical Requirements</h3></xsl:when>
                                <xsl:when test="self::ead:processinfo"><h4><xsl:call-template name="anchor"/>Processing Information</h4></xsl:when>
                                <xsl:when test="self::ead:relatedmaterial"><h4><xsl:call-template name="anchor"/>Related Material</h4></xsl:when>
                                <xsl:when test="self::ead:scopecontent"><h3><xsl:call-template name="anchor"/>Scope and Content</h3></xsl:when>
                                <xsl:when test="self::ead:separatedmaterial"><h4><xsl:call-template name="anchor"/>Separated Material</h4></xsl:when>
                                <xsl:when test="self::ead:appraisal"><h4><xsl:call-template name="anchor"/>Appraisal</h4></xsl:when>                        
                            </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <h4><xsl:call-template name="anchor"/>
                            <xsl:choose>
                                <xsl:when test="self::ead:bibliography">Bibliography</xsl:when>
                                <xsl:when test="self::ead:odd">Other Descriptive Data</xsl:when>
                                <xsl:when test="self::ead:accruals">Accruals</xsl:when>
                                <xsl:when test="self::ead:arrangement">Arrangement</xsl:when>
                                <xsl:when test="self::ead:bioghist">Biography/History</xsl:when>
                                <xsl:when test="self::ead:accessrestrict">Restrictions on Access</xsl:when>
                                <xsl:when test="self::ead:userestrict">Restrictions on Use</xsl:when>
                                <xsl:when test="self::custodhist">Custodial History</xsl:when>
                                <xsl:when test="self::ead:altformavail">Alternative Form Available</xsl:when>
                                <xsl:when test="self::ead:originalsloc">Original Location</xsl:when>
                                <xsl:when test="self::ead:fileplan">File Plan</xsl:when>
                                <xsl:when test="self::ead:acqinfo">Acquisition Information</xsl:when>
                                <xsl:when test="self::ead:otherfindaid">Other Finding Aids</xsl:when>
                                <xsl:when test="self::ead:phystech">Physical Characteristics and Technical Requirements</xsl:when>
                                <xsl:when test="self::ead:processinfo">Processing Information</xsl:when>
                                <xsl:when test="self::ead:relatedmaterial">Related Material</xsl:when>
                                <xsl:when test="self::ead:scopecontent">Scope and Content</xsl:when>
                                <xsl:when test="self::ead:separatedmaterial">Separated Material</xsl:when>
                                <xsl:when test="self::ead:appraisal">Appraisal</xsl:when>                       
                            </xsl:choose>
                        </h4>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        <!-- If the element is a child of arcdesc then a link to the table of contents is included -->
        <xsl:if test="parent::ead:archdesc">
            <xsl:choose>
                <xsl:when test="self::ead:accessrestrict or self::ead:userestrict or
                    self::custodhist or self::ead:accruals or
                    self::ead:altformavail or self::ead:acqinfo or
                    self::ead:processinfo or self::ead:appraisal or
                    self::ead:originalsloc or  
                    self::ead:relatedmaterial or self::ead:separatedmaterial or self::ead:prefercite"/>
                    <xsl:otherwise>
                        <xsl:call-template name="returnTOC"/>
                    </xsl:otherwise>
            </xsl:choose>    
        </xsl:if>
    </xsl:template>

    <!-- Templates for publication information  -->
    <xsl:template match="/ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt">
        <h4>Publication Information</h4>
        <p><xsl:apply-templates select="ead:publisher"/>
            <xsl:if test="ead:date">&#160;<xsl:apply-templates select="ead:date"/></xsl:if>
        </p>
    </xsl:template>
    <!-- Templates for revision description  -->
    <xsl:template match="/ead:ead/ead:eadheader/ead:revisiondesc">
        <h4>Revision Description</h4>
        <p><xsl:if test="change/ead:item"><xsl:apply-templates select="change/ead:item"/></xsl:if><xsl:if test="change/ead:date">&#160;<xsl:apply-templates select="change/ead:date"/></xsl:if></p>        
    </xsl:template>
    
    <!-- Formats controlled access terms -->
    <xsl:template match="controlaccess">
        <xsl:choose>
            <xsl:when test="ead:head"><xsl:apply-templates/></xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="parent::ead:archdesc"><h3><xsl:call-template name="anchor"/>Controlled Access Headings</h3></xsl:when>
                    <xsl:otherwise><h4>Controlled Access Headings</h4></xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="corpname">
            <h4>Corporate Name(s)</h4>
            <ul>
                <xsl:for-each select="corpname">
                    <li><xsl:apply-templates/> </li>
                </xsl:for-each>
            </ul>            
        </xsl:if>
        <xsl:if test="ead:famname">
            <h4>Family Name(s)</h4>
            <ul>
                <xsl:for-each select="ead:famname">
                    <li><xsl:apply-templates/> </li>
                </xsl:for-each>                        
            </ul>
        </xsl:if>
        <xsl:if test="ead:function">
            <h4>Function(s)</h4>
            <ul>
                <xsl:for-each select="ead:function">
                    <li><xsl:apply-templates/> </li>
                </xsl:for-each>                        
            </ul>
        </xsl:if>
        <xsl:if test="ead:genreform">
            <h4>Genre(s)</h4>
            <ul>
                <xsl:for-each select="ead:genreform">
                    <li><xsl:apply-templates/> </li>
                </xsl:for-each>
           </ul>     
        </xsl:if>
        <xsl:if test="ead:geogname">
            <h4>Geographic Name(s)</h4>
            <ul>
                <xsl:for-each select="ead:geogname">
                    <li><xsl:apply-templates/> </li>
                </xsl:for-each>                        
            </ul>
        </xsl:if>
        <xsl:if test="ead:occupation">
            <h4>Occupation(s)</h4>
            <ul>
                <xsl:for-each select="ead:occupation">
                    <li><xsl:apply-templates/> </li>
                </xsl:for-each>                        
            </ul>
        </xsl:if>
        <xsl:if test="ead:persname">
            <h4>Personal Name(s)</h4>
            <ul>
                <xsl:for-each select="ead:persname">
                    <li><xsl:apply-templates/> </li>
                </xsl:for-each>                        
            </ul>
        </xsl:if>
        <xsl:if test="ead:subject">
            <h4>Subject(s)</h4>
            <ul>
                <xsl:for-each select="ead:subject">
                    <li><xsl:apply-templates/> </li>
                </xsl:for-each>                        
            </ul>
        </xsl:if>
        <xsl:if test="parent::ead:archdesc"><xsl:call-template name="returnTOC"/></xsl:if>
    </xsl:template>

    <!-- Formats index and child elements, groups indexentry elements by type (i.e. corpname, subject...)-->
    <xsl:template match="ead:index">
       <xsl:choose>
           <xsl:when test="ead:head"/>
           <xsl:otherwise>
               <xsl:choose>
                   <xsl:when test="parent::ead:archdesc">
                       <h3><xsl:call-template name="anchor"/>Index</h3>
                   </xsl:when>
                   <xsl:otherwise>
                       <h4><xsl:call-template name="anchor"/>Index</h4>
                   </xsl:otherwise>
               </xsl:choose>    
           </xsl:otherwise>
       </xsl:choose>
       <xsl:apply-templates select="child::*[not(self::ead:indexentry)]"/>
                <xsl:if test="ead:indexentry/corpname">
                    <h4>Corporate Name(s)</h4>
                    <ul>
                        <xsl:for-each select="ead:indexentry/corpname">
                            <xsl:sort/>
                            <li><xsl:apply-templates select="."/>: &#160;<xsl:apply-templates select="following-sibling::*"/></li>
                        </xsl:for-each>
                     </ul>   
                </xsl:if>
                <xsl:if test="ead:indexentry/ead:famname">
                    <h4>Family Name(s)</h4>
                    <ul>
                        <xsl:for-each select="ead:indexentry/ead:famname">
                            <xsl:sort/>
                            <li><xsl:apply-templates select="."/>: &#160;<xsl:apply-templates select="following-sibling::*"/></li>
                        </xsl:for-each>
                    </ul>    
                </xsl:if>      
                <xsl:if test="ead:indexentry/ead:function">
                    <h4>Function(s)</h4>
                    <ul>
                        <xsl:for-each select="ead:indexentry/ead:function">
                            <xsl:sort/>
                            <li><xsl:apply-templates select="."/>: &#160;<xsl:apply-templates select="following-sibling::*"/></li>
                        </xsl:for-each>
                    </ul>
                </xsl:if>
                <xsl:if test="ead:indexentry/ead:genreform">
                    <h4>Genre(s)</h4> 
                    <ul>
                        <xsl:for-each select="ead:indexentry/ead:genreform">
                            <xsl:sort/>
                            <li><xsl:apply-templates select="."/>: &#160;<xsl:apply-templates select="following-sibling::*"/></li>
                        </xsl:for-each>           
                    </ul>
                </xsl:if>
                <xsl:if test="ead:indexentry/ead:geogname">
                    <h4>Geographic Name(s)</h4>
                    <ul>
                        <xsl:for-each select="ead:indexentry/ead:geogname">
                            <xsl:sort/>
                            <li><xsl:apply-templates select="."/>: &#160;<xsl:apply-templates select="following-sibling::*"/></li>
                        </xsl:for-each>
                    </ul>                    
                </xsl:if>
                <xsl:if test="ead:indexentry/ead:name">
                    <h4>Name(s)</h4>
                    <ul>
                        <xsl:for-each select="ead:indexentry/ead:name">
                            <xsl:sort/>
                            <li><xsl:apply-templates select="."/>: &#160;<xsl:apply-templates select="following-sibling::*"/></li>
                        </xsl:for-each>
                    </ul>    
                </xsl:if>
                <xsl:if test="ead:indexentry/ead:occupation">
                    <h4>Occupation(s)</h4> 
                    <ul>
                        <xsl:for-each select="ead:indexentry/ead:occupation">
                            <xsl:sort/>
                            <li><xsl:apply-templates select="."/>: &#160;<xsl:apply-templates select="following-sibling::*"/></li>
                        </xsl:for-each>
                    </ul>
                </xsl:if>
                <xsl:if test="ead:indexentry/ead:persname">
                    <h4>Personal Name(s)</h4>
                    <ul>
                        <xsl:for-each select="ead:indexentry/ead:persname">
                            <xsl:sort/>
                            <li><xsl:apply-templates select="."/>: &#160;<xsl:apply-templates select="following-sibling::*"/></li>
                        </xsl:for-each>
                    </ul>
                </xsl:if>
                <xsl:if test="ead:indexentry/ead:subject">
                    <h4>Subject(s)</h4> 
                    <ul>
                        <xsl:for-each select="ead:indexentry/ead:subject">
                            <xsl:sort/>
                            <li><xsl:apply-templates select="."/>: &#160;<xsl:apply-templates select="following-sibling::*"/></li>
                        </xsl:for-each>
                    </ul>
                </xsl:if>
                <xsl:if test="ead:indexentry/ead:title">
                    <h4>Title(s)</h4>
                    <ul>
                        <xsl:for-each select="ead:indexentry/ead:title">
                            <xsl:sort/>
                            <li><xsl:apply-templates select="."/>: &#160;<xsl:apply-templates select="following-sibling::*"/></li>
                        </xsl:for-each>
                    </ul>
                </xsl:if>         
       <xsl:if test="parent::ead:archdesc"><xsl:call-template name="returnTOC"/></xsl:if>
   </xsl:template>
    <xsl:template match="ead:indexentry">
        <dl class="indexEntry">
            <dt><xsl:apply-templates select="child::*[1]"/></dt>
            <dd><xsl:apply-templates select="child::*[2]"/></dd>    
        </dl>
    </xsl:template>
    <xsl:template match="ead:ptrgrp">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- Linking elements. -->
    <xsl:template match="ead:ptr">
        <xsl:choose>
            <xsl:when test="@target">
                <a href="#{@target}"><xsl:value-of select="@target"/></a>
                <xsl:if test="following-sibling::ead:ptr">, </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="ead:ref">
        <xsl:choose>
            <xsl:when test="@target">
                <a href="#{@target}">
                    <xsl:apply-templates/>
                </a>
                <xsl:if test="following-sibling::ead:ref">, </xsl:if>
            </xsl:when>
            <xsl:when test="@ns2:href">
                <a href="#{@ns2:href}">
                    <xsl:apply-templates/>
                </a>
                <xsl:if test="following-sibling::ead:ref">, </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>    
    <xsl:template match="ead:extptr">
        <xsl:choose>
            <xsl:when test="@href">
                <a href="{@href}"><xsl:value-of select="@title"/></a>
            </xsl:when>
            <xsl:when test="@ns2:href"><a href="{@ns2:href}"><xsl:value-of select="@title"/></a></xsl:when>
            <xsl:otherwise><xsl:value-of select="@title"/></xsl:otherwise>
        </xsl:choose> 
    </xsl:template>
    <xsl:template match="ead:extref">
        <xsl:choose>
            <xsl:when test="@href">
                <a href="{@href}"><xsl:value-of select="."/></a>
            </xsl:when>
            <xsl:when test="@ns2:href"><a href="{@ns2:href}"><xsl:value-of select="."/></a></xsl:when>
            <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
        </xsl:choose> 
    </xsl:template>
    
    <!--Creates a hidden anchor tag that allows navigation within the finding aid. 
    In this stylesheet only children of the archdesc and c0* itmes call this template. 
    It can be applied anywhere in the stylesheet as the id attribute is universal. -->
    <xsl:template match="@id">
        <xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>
    <xsl:template name="anchor">
        <xsl:choose>
            <xsl:when test="@id">
                <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="id"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
            </xsl:otherwise>
            </xsl:choose>
    </xsl:template>
    <xsl:template name="tocLinks">
        <xsl:choose>
            <xsl:when test="self::*/@id">
                <xsl:attribute name="href">#<xsl:value-of select="@id"/></xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="href">#<xsl:value-of select="generate-id(.)"/></xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
 
    <!--Bibref, choose statement decides if the citation is inline, if there is a parent element
    or if it is its own line, typically when it is a child of the bibliography element.-->
    <xsl:template match="ead:bibref">
        <xsl:choose>
            <xsl:when test="parent::ead:p">
                <xsl:choose>
                    <xsl:when test="@ns2:href">
                        <a href="{@ns2:href}"><xsl:apply-templates/></a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <p>
                    <xsl:choose>
                        <xsl:when test="@ns2:href">
                            <a href="{@ns2:href}"><xsl:apply-templates/></a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates/>
                        </xsl:otherwise>
                    </xsl:choose>
                </p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
   
    <!-- Formats prefered citiation -->
    <xsl:template match="ead:prefercite">
        <div class="citation">
            <xsl:choose>
                <xsl:when test="ead:head"><xsl:apply-templates/></xsl:when>
                <xsl:otherwise><h4>Preferred Citation</h4><xsl:apply-templates/></xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- Applies a span style to address elements, currently addresses are displayed 
        as a block item, display can be changed to inline, by changing the CSS -->
    <xsl:template match="ead:address">
        <span class="address">
            <xsl:for-each select="child::*">
                <xsl:apply-templates/>
                <xsl:choose>
                    <xsl:when test="ead:lb"/>
                    <xsl:otherwise><br/></xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>            
        </span>    
    </xsl:template>
    
    <!-- Formats headings throughout the finding aid -->
    <xsl:template match="ead:head[parent::*/parent::ead:archdesc]">
        <xsl:choose>
            <xsl:when test="parent::ead:accessrestrict or parent::ead:userestrict or
                parent::custodhist or parent::ead:accruals or
                parent::ead:altformavail or parent::ead:acqinfo or
                parent::ead:processinfo or parent::ead:appraisal or
                parent::ead:originalsloc or  
                parent::ead:relatedmaterial or parent::ead:separatedmaterial or parent::ead:prefercite">
                <h4>
                    <xsl:choose>
                        <xsl:when test="parent::*/@id">
                            <xsl:attribute name="id"><xsl:value-of select="parent::*/@id"/></xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="id"><xsl:value-of select="generate-id(parent::*)"/></xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates/>
                </h4>
            </xsl:when>
            <xsl:otherwise>
                <h3>
                    <xsl:choose>
                        <xsl:when test="parent::*/@id">
                            <xsl:attribute name="id"><xsl:value-of select="parent::*/@id"/></xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="id"><xsl:value-of select="generate-id(parent::*)"/></xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates/>
                </h3>                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="ead:head">
        <h4><xsl:apply-templates/></h4>
    </xsl:template>
    
    <!-- Digital Archival Object -->
    <xsl:template match="ead:daogrp">
        <xsl:choose>
            <xsl:when test="parent::ead:archdesc">
                <h3><xsl:call-template name="anchor"/>
                    <xsl:choose>
                    <xsl:when test="@ns2:title">
                       <xsl:value-of select="@ns2:title"/>
                    </xsl:when>
                    <xsl:otherwise>
                        Digital Archival Object
                    </xsl:otherwise>
                    </xsl:choose>
                </h3>
            </xsl:when>
            <xsl:otherwise>
                <h4><xsl:call-template name="anchor"/>
                    <xsl:choose>
                    <xsl:when test="@ns2:title">
                       <xsl:value-of select="@ns2:title"/>
                    </xsl:when>
                    <xsl:otherwise>
                        Digital Archival Object
                    </xsl:otherwise>
                </xsl:choose>
                </h4>
            </xsl:otherwise>
        </xsl:choose>   
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="ead:dao">
        <xsl:choose>
            <xsl:when test="child::*">
                <xsl:apply-templates/> 
                <a href="{@ns2:href}">
                    [<xsl:value-of select="@ns2:href"/>]
                </a>
            </xsl:when>
            <xsl:otherwise>
                <a href="{@ns2:href}">
                    <xsl:value-of select="@ns2:href"/>
                </a>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="ead:daoloc">
        <a href="{@ns2:href}">
            <xsl:value-of select="@ns2:title"/>
        </a>
    </xsl:template>
    
    <!--Formats a simple table. The width of each column is defined by the colwidth attribute in a colspec element.-->
    <xsl:template match="ead:table">
        <xsl:for-each select="tgroup">
            <table>
                <tr>
                    <xsl:for-each select="colspec">
                        <td width="{@colwidth}"/>
                    </xsl:for-each>
                </tr>
                <xsl:for-each select="ead:thead">
                    <xsl:for-each select="ead:row">
                        <tr>
                            <xsl:for-each select="ead:entry">
                                <td valign="top">
                                    <strong>
                                        <xsl:value-of select="."/>
                                    </strong>
                                </td>
                            </xsl:for-each>
                        </tr>
                    </xsl:for-each>
                </xsl:for-each>
                <xsl:for-each select="ead:tbody">
                    <xsl:for-each select="ead:row">
                        <tr>
                            <xsl:for-each select="ead:entry">
                                <td valign="top">
                                    <xsl:value-of select="."/>
                                </td>
                            </xsl:for-each>
                        </tr>
                    </xsl:for-each>
                </xsl:for-each>
            </table>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="ead:unitdate">
        <xsl:if test="preceding-sibling::*">&#160;</xsl:if>
        <xsl:choose>
            <xsl:when test="@type = 'bulk'">
                (<xsl:apply-templates/>)                            
            </xsl:when>
            <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="ead:date">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="ead:unittitle">
        <xsl:choose>
            <xsl:when test="child::ead:unitdate[@type='bulk']">
                <xsl:apply-templates select="node()[not(self::ead:unitdate[@type='bulk'])]"/>
                <xsl:apply-templates select="ead:date[@type='bulk']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Following five templates output chronlist and children in a table -->
    <xsl:template match="chronlist">
        <table class="chronlist">
            <xsl:apply-templates/>
        </table>
    </xsl:template>
    <xsl:template match="chronlist/ead:listhead">
        <tr>
            <th>
                <xsl:apply-templates select="ead:head01"/>
            </th>
            <th>
                <xsl:apply-templates select="ead:head02"/>
            </th>
        </tr>
    </xsl:template>
    <xsl:template match="chronlist/ead:head">
        <tr>
            <th colspan="2">
                <xsl:apply-templates/>
            </th>
        </tr>
    </xsl:template>
    <xsl:template match="chronitem">
        <tr>
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="(position() mod 2 = 0)">odd</xsl:when>
                    <xsl:otherwise>even</xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <td><xsl:apply-templates select="ead:date"/></td>
            <td><xsl:apply-templates select="descendant::ead:event"/></td>
        </tr>
    </xsl:template>
    <xsl:template match="ead:event">
        <xsl:choose>
            <xsl:when test="following-sibling::*">
                <xsl:apply-templates/><br/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>

    <!-- Output for a variety of list types -->
    <xsl:template match="ead:list">
        <xsl:if test="ead:head"><h4><xsl:value-of select="ead:head"/></h4></xsl:if>
        <xsl:choose>
            <xsl:when test="descendant::ead:defitem">
                <dl>
                    <xsl:apply-templates select="ead:defitem"/>
                </dl>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="@type = 'ordered'">
                        <ol>
                            <xsl:attribute name="class">
                                <xsl:value-of select="@numeration"/>
                            </xsl:attribute>
                            <xsl:apply-templates/>
                        </ol>
                    </xsl:when>
                    <xsl:when test="@numeration">
                        <ol>
                            <xsl:attribute name="class">
                                <xsl:value-of select="@numeration"/>
                            </xsl:attribute>
                            <xsl:apply-templates/>
                        </ol>
                    </xsl:when>
                    <xsl:when test="@type='simple'">
                        <ul>
                            <xsl:attribute name="class">simple</xsl:attribute>
                            <xsl:apply-templates select="child::*[not(ead:head)]"/>
                        </ul>
                    </xsl:when>
                    <xsl:otherwise>
                        <ul>
                            <xsl:apply-templates/>
                        </ul>        
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="ead:list/ead:head"/>
    <xsl:template match="ead:list/ead:item">
        <li><xsl:apply-templates/></li>
    </xsl:template>
    <xsl:template match="ead:defitem">
        <dt><xsl:apply-templates select="ead:label"/></dt>
        <dd><xsl:apply-templates select="ead:item"/></dd>
    </xsl:template>
 
    <!-- Formats list as tabel if list has listhead element  -->         
    <xsl:template match="ead:list[child::ead:listhead]">
        <table>
            <tr>
                <th><xsl:value-of select="ead:listhead/ead:head01"/></th>
                <th><xsl:value-of select="ead:listhead/ead:head02"/></th>
            </tr>
            <xsl:for-each select="ead:defitem">
                <tr>
                    <td><xsl:apply-templates select="ead:label"/></td>
                    <td><xsl:apply-templates select="ead:item"/></td>
                </tr>
            </xsl:for-each>
        </table>
    </xsl:template>

    <!-- Formats notestmt and notes -->
    <xsl:template match="ead:notestmt">
        <h4>Note</h4>
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="ead:note">
         <xsl:choose>
             <xsl:when test="parent::ead:notestmt">
                 <xsl:apply-templates/>
             </xsl:when>
             <xsl:otherwise>
                 <xsl:choose>
                     <xsl:when test="@label"><h4><xsl:value-of select="@label"/></h4><xsl:apply-templates/></xsl:when>
                     <xsl:otherwise><h4>Note</h4><xsl:apply-templates/></xsl:otherwise>
                 </xsl:choose>
             </xsl:otherwise>
         </xsl:choose>
     </xsl:template>
    
    <!-- Child elements that should display as paragraphs-->
    <xsl:template match="ead:legalstatus">
        <p><xsl:apply-templates/></p>
    </xsl:template>
    <!-- Puts a space between sibling elements -->
    <xsl:template match="child::*">
        <xsl:if test="preceding-sibling::*">&#160;</xsl:if>
        <xsl:apply-templates/>
    </xsl:template>
    <!-- Generic text display elements -->
    <xsl:template match="ead:p">
        <p><xsl:apply-templates/></p>
    </xsl:template>
    <xsl:template match="ead:lb"><br/></xsl:template>
    <xsl:template match="ead:blockquote">
        <blockquote><xsl:apply-templates/></blockquote>
    </xsl:template>
    <xsl:template match="ead:emph"><em><xsl:apply-templates/></em></xsl:template>
    
    <!--Render elements -->
    <xsl:template match="*[@render = 'bold'] | *[@altrender = 'bold'] ">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if><strong><xsl:apply-templates/></strong>
    </xsl:template>
    <xsl:template match="*[@render = 'bolddoublequote'] | *[@altrender = 'bolddoublequote']">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if><strong>"<xsl:apply-templates/>"</strong>
    </xsl:template>
    <xsl:template match="*[@render = 'boldsinglequote'] | *[@altrender = 'boldsinglequote']">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if><strong>'<xsl:apply-templates/>'</strong>
    </xsl:template>
    <xsl:template match="*[@render = 'bolditalic'] | *[@altrender = 'bolditalic']">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if><strong><em><xsl:apply-templates/></em></strong>
    </xsl:template>
    <xsl:template match="*[@render = 'boldsmcaps'] | *[@altrender = 'boldsmcaps']">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if><strong><span class="smcaps"><xsl:apply-templates/></span></strong>
    </xsl:template>
    <xsl:template match="*[@render = 'boldunderline'] | *[@altrender = 'boldunderline']">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if><strong><span class="underline"><xsl:apply-templates/></span></strong>
    </xsl:template>
    <xsl:template match="*[@render = 'doublequote'] | *[@altrender = 'doublequote']">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if>"<xsl:apply-templates/>"
    </xsl:template>
    <xsl:template match="*[@render = 'italic'] | *[@altrender = 'italic']">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if><em><xsl:apply-templates/></em>
    </xsl:template>
    <xsl:template match="*[@render = 'singlequote'] | *[@altrender = 'singlequote']">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if>'<xsl:apply-templates/>'
    </xsl:template>
    <xsl:template match="*[@render = 'smcaps'] | *[@altrender = 'smcaps']">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if><span class="smcaps"><xsl:apply-templates/></span>
    </xsl:template>
    <xsl:template match="*[@render = 'sub'] | *[@altrender = 'sub']">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if><sub><xsl:apply-templates/></sub>
    </xsl:template>
    <xsl:template match="*[@render = 'super'] | *[@altrender = 'super']">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if><sup><xsl:apply-templates/></sup>
    </xsl:template>
    <xsl:template match="*[@render = 'underline'] | *[@altrender = 'underline']">
        <xsl:if test="preceding-sibling::*"> &#160;</xsl:if><span class="underline"><xsl:apply-templates/></span>
    </xsl:template>
    <!-- 
        <value>nonproport</value>        
    -->

    <!-- *** Begin templates for Container List *** -->
    <xsl:template match="ead:archdesc/ead:dsc">
        <xsl:choose>
            <xsl:when test="ead:head">
                <xsl:apply-templates select="ead:head"/>
            </xsl:when>
            <xsl:otherwise>
                <h3><xsl:call-template name="anchor"/>Collection Inventory</h3>
            </xsl:otherwise>
        </xsl:choose>
        
        <table class="containerList">
            <xsl:apply-templates select="*[not(self::ead:head)]"/>
            <tr>
                <td/>
                <td style="width: 15%;"/>
                <td style="width: 15%;"/>
                <td style="width: 15%;"/>
            </tr>
            
        </table>
    </xsl:template>
    
    <!--This section of the stylesheet creates a div for each c01 or c 
        It then recursively processes each child component of the c01 by 
        calling the clevel template. -->
    <xsl:template match="c">
        <xsl:call-template name="clevel"/>
        <xsl:for-each select="c">
            <xsl:call-template name="clevel"/> 
            <xsl:for-each select="c">
                <xsl:call-template name="clevel"/>    
                <xsl:for-each select="c">
                    <xsl:call-template name="clevel"/>
                    <xsl:for-each select="c">
                        <xsl:call-template name="clevel"/>
                        <xsl:for-each select="c">
                            <xsl:call-template name="clevel"/> 
                            <xsl:for-each select="c">
                                <xsl:call-template name="clevel"/>
                                <xsl:for-each select="c">
                                    <xsl:call-template name="clevel"/>
                                    <xsl:for-each select="c">
                                        <xsl:call-template name="clevel"/>    
                                    </xsl:for-each>
                                </xsl:for-each>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="c01">
        <xsl:call-template name="clevel"/>
        <xsl:for-each select="c02">
            <xsl:call-template name="clevel"/>
            <xsl:for-each select="c03">
                <xsl:call-template name="clevel"/>
                <xsl:for-each select="c04">
                    <xsl:call-template name="clevel"/>
                    <xsl:for-each select="c05">
                        <xsl:call-template name="clevel"/>
                        <xsl:for-each select="c06">
                            <xsl:call-template name="clevel"/>
                            <xsl:for-each select="c07">
                                <xsl:call-template name="clevel"/>
                                <xsl:for-each select="c08">
                                    <xsl:call-template name="clevel"/>
                                    <xsl:for-each select="c09">
                                        <xsl:call-template name="clevel"/>
                                        <xsl:for-each select="c10">
                                            <xsl:call-template name="clevel"/>
                                            <xsl:for-each select="c11">
                                                <xsl:call-template name="clevel"/>
                                                <xsl:for-each select="c12">
                                                    <xsl:call-template name="clevel"/>
                                                </xsl:for-each>
                                            </xsl:for-each>
                                        </xsl:for-each>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
        <tr>
            <td colspan="4">
                <xsl:call-template name="returnTOC"/>
            </td>
        </tr>
    </xsl:template>
    <!--This is a named template that processes all c0* elements  -->
    <xsl:template name="clevel">
    <!-- Establishes which level is being processed in order to provided indented displays. 
        Indents handled by CSS margins-->
        <xsl:variable name="clevelMargin">
            <xsl:choose>
                <xsl:when test="../c">c</xsl:when>
                <xsl:when test="../c01">c01</xsl:when>
                <xsl:when test="../c02">c02</xsl:when>
                <xsl:when test="../c03">c03</xsl:when>
                <xsl:when test="../c04">c04</xsl:when>
                <xsl:when test="../c05">c05</xsl:when>
                <xsl:when test="../c06">c06</xsl:when>
                <xsl:when test="../c07">c07</xsl:when>
                <xsl:when test="../c08">c08</xsl:when>
                <xsl:when test="../c08">c09</xsl:when>
                <xsl:when test="../c08">c10</xsl:when>
                <xsl:when test="../c08">c11</xsl:when>
                <xsl:when test="../c08">c12</xsl:when>
            </xsl:choose>
        </xsl:variable>
    <!-- Establishes a class for even and odd rows in the table for color coding. 
        Colors are Declared in the CSS. -->
        <xsl:variable name="colorClass">
            <xsl:choose>
                <xsl:when test="ancestor-or-self::*[@level='file' or @level='item']">
                    <xsl:choose>
                        <xsl:when test="(position() mod 2 = 0)">odd</xsl:when>
                        <xsl:otherwise>even</xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <!-- Processes the all child elements of the c or c0* level -->
        <xsl:for-each select=".">
            <xsl:choose>
                <!--Formats Series and Groups  -->
                <xsl:when test="@level='subcollection' or @level='subgrp' or @level='series' 
                    or @level='subseries' or @level='collection'or @level='fonds' or 
                    @level='recordgrp' or @level='subfonds' or @level='class' or (@level='otherlevel' and not(child::ead:did/container))">
                    <tr> 
                        <xsl:attribute name="class">
                            <xsl:choose>
                                <xsl:when test="@level='subcollection' or @level='subgrp' or @level='subseries' or @level='subfonds'">subseries</xsl:when>
                                <xsl:otherwise>series</xsl:otherwise>
                            </xsl:choose>    
                        </xsl:attribute>
                        <xsl:choose>
                            <xsl:when test="ead:did/container">
                            <td class="{$clevelMargin}">
                            <xsl:choose>                                
                                <xsl:when test="count(ead:did/container) &lt; 1">
                                    <xsl:attribute name="colspan">
                                        <xsl:text>4</xsl:text>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:when test="count(ead:did/container) =1">
                                    <xsl:attribute name="colspan">
                                        <xsl:text>3</xsl:text>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:when test="count(ead:did/container) = 2">
                                    <xsl:attribute name="colspan">
                                        <xsl:text>2</xsl:text>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:otherwise/>
                            </xsl:choose>    
                                <xsl:call-template name="anchor"/>
                                <xsl:apply-templates select="ead:did" mode="dsc"/>
                                <xsl:apply-templates select="child::*[not(ead:did) and not(self::ead:did)]"/>
                            </td>
                            <xsl:for-each select="descendant::ead:did[container][1]/container">    
                                <td class="containerHeader">    
                                    <xsl:value-of select="@type"/><br/><xsl:value-of select="."/>       
                                </td>    
                            </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <td colspan="4" class="{$clevelMargin}">
                                    <xsl:call-template name="anchor"/>
                                    <xsl:apply-templates select="ead:did" mode="dsc"/>
                                    <xsl:apply-templates select="child::*[not(ead:did) and not(self::ead:did)]"/>
                                </td>
                            </xsl:otherwise>
                        </xsl:choose>
                    </tr>
                </xsl:when>

                <!-- Items/Files--> 
                <xsl:when test="@level='file' or @level='item' or (@level='otherlevel'and child::ead:did/container)">
                  <!-- Variables to  for Conainer headings, used only if headings are different from preceding heading -->
                   <xsl:variable name="container" select="string(ead:did/container/@type)"/>
                   <xsl:variable name="sibContainer" select="string(preceding-sibling::*[1]/ead:did/container/@type)"/>
                   <xsl:if test="$container != $sibContainer">
                        <xsl:if test="ead:did/container">
                            <tr>
                                <td class="title">
                                    <xsl:choose>                                
                                        <xsl:when test="count(ead:did[container][1]/container) &lt; 1">
                                            <xsl:attribute name="colspan">
                                                <xsl:text>4</xsl:text>
                                            </xsl:attribute>
                                        </xsl:when>
                                        <xsl:when test="count(ead:did[container][1]/container) =1">
                                            <xsl:attribute name="colspan">
                                                <xsl:text>3</xsl:text>
                                            </xsl:attribute>
                                        </xsl:when>
                                        <xsl:when test="count(ead:did[container][1]/container) = 2">
                                            <xsl:attribute name="colspan">
                                                <xsl:text>2</xsl:text>
                                            </xsl:attribute>
                                        </xsl:when>
                                        <xsl:otherwise/>
                                    </xsl:choose>    
                                    <xsl:text/>
                                </td>
                                <xsl:for-each select="ead:did/container">    
                                    <td class="containerHeader">    
                                        <xsl:value-of select="@type"/>
                                    </td>    
                                </xsl:for-each>
                            </tr>
                        </xsl:if> 
                  </xsl:if>
                    <tr class="{$colorClass}"> 
                        <td class="{$clevelMargin}">
                            <xsl:choose>
                                <xsl:when test="count(ead:did/container) &lt; 1">
                                    <xsl:attribute name="colspan">
                                        <xsl:text>4</xsl:text>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:when test="count(ead:did/container) =1">
                                    <xsl:attribute name="colspan">
                                        <xsl:text>3</xsl:text>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:when test="count(ead:did/container) = 2">
                                    <xsl:attribute name="colspan">
                                        <xsl:text>2</xsl:text>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:otherwise/>
                            </xsl:choose>                            
                            <xsl:apply-templates select="ead:did" mode="dsc"/>  
                            <xsl:apply-templates select="*[not(self::ead:did) and 
                                not(self::c) and not(self::c02) and not(self::c03) and
                                not(self::c04) and not(self::c05) and not(self::c06) and not(self::c07)
                                and not(self::c08) and not(self::c09) and not(self::c10) and not(self::c11) and not(self::c12)]"/>  
                        </td>
                        <!-- Containers -->    
                        <xsl:for-each select="ead:did/container">    
                            <td class="container">    
                                <xsl:value-of select="."/>        
                            </td>    
                        </xsl:for-each>
                    </tr>  
                </xsl:when>
                <xsl:otherwise>
                    <tr class="{$colorClass}"> 
                        <td class="{$clevelMargin}" colspan="4">
                            <xsl:apply-templates select="ead:did" mode="dsc"/>
                            <xsl:apply-templates select="*[not(self::ead:did) and 
                                not(self::c) and not(self::c02) and not(self::c03) and
                                not(self::c04) and not(self::c05) and not(self::c06) and not(self::c07)
                                and not(self::c08) and not(self::c09) and not(self::c10) and not(self::c11) and not(self::c12)]"/>  
                        </td>
                    </tr>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="ead:did" mode="dsc">
        <xsl:choose>
            <xsl:when test="../@level='subcollection' or ../@level='subgrp' or ../@level='series' 
                or ../@level='subseries'or ../@level='collection'or ../@level='fonds' or 
                ../@level='recordgrp' or ../@level='subfonds'">    
                <h4>
                    <xsl:call-template name="component-did-core"/>
                </h4>
            </xsl:when>
            <!--Otherwise render the text in its normal font.-->
            <xsl:otherwise>
                <p><xsl:call-template name="component-did-core"/></p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="component-did-core">
        <!--Inserts unitid and a space if it exists in the markup.-->
        <xsl:if test="ead:unitid">
            <xsl:apply-templates select="ead:unitid"/>
            <xsl:text>&#160;</xsl:text>
        </xsl:if>
        <!--Inserts origination and a space if it exists in the markup.-->
        <xsl:if test="ead:origination">
            <xsl:apply-templates select="ead:origination"/>
            <xsl:text>&#160;</xsl:text>
        </xsl:if>
        <!--This choose statement selects between cases where unitdate is a child of unittitle and where it is a separate child of did.-->
        <xsl:choose>
            <!--This code processes the elements when unitdate is a child of unittitle.-->
            <xsl:when test="ead:unittitle/ead:unitdate">
                <xsl:apply-templates select="ead:unittitle"/>
            </xsl:when>
            <!--This code process the elements when unitdate is not a child of untititle-->
            <xsl:otherwise>
                <xsl:apply-templates select="ead:unittitle"/>
                <xsl:text>&#160;</xsl:text>
                <xsl:for-each select="ead:unitdate[not(self::ead:unitdate[@type='bulk'])]">
                    <xsl:apply-templates/>
                    <xsl:text>&#160;</xsl:text>
                </xsl:for-each>
                <xsl:for-each select="ead:unitdate[@type = 'bulk']">
                    (<xsl:apply-templates/>)
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="ead:physdesc">
            <xsl:text>&#160;</xsl:text>
            <xsl:apply-templates select="ead:physdesc"/>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
