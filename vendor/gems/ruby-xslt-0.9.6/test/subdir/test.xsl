<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:import href="result.xsl"/>
  <xsl:output omit-xml-declaration="yes"/>
  
  <xsl:template match="/">
    <xsl:call-template name="result"/>
  </xsl:template>
</xsl:stylesheet>
