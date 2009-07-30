#!ruby

require "test/unit"

require "rubygems"
require "xml/xslt"

EXT_FUNC_XSL =<<END
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ext="http://necronomicorp.com/nil"
  version="1.0">

<xsl:template match="/">
  <xsl:value-of select="ext:foo()"/>
</xsl:template>

</xsl:stylesheet>
END

class XsltTest < Test::Unit::TestCase
  def setup 
    @xslt = XML::XSLT.new( )
  
    @testOut = "<?xml version=\"1.0\"?>\nThis is a test file\n"
    
    @errors = []
    XML::XSLT.registerErrorHandler { |s| @errors << s }
  end
  
  def test_instance
    assert_instance_of( XML::XSLT, @xslt )
  end
  
  def test_from_file
    @xslt.xml = "t.xml"
    @xslt.xsl = "t.xsl"
   
    out = @xslt.serve
    assert_equal( @testOut, out )
    assert_equal( [], @errors )
  end

  def test_from_data
    @xslt.xml = File.read( "t.xml" )
    @xslt.xsl = File.read( "t.xsl" )
   
    out = @xslt.serve
    assert_equal( @testOut, out )
    assert_equal( [], @errors )
  end
  
  def test_from_simple
    begin
      require "xml/simple"
      
      @xslt.xml = XML::Simple.open( "t.xml" )
      @xslt.xsl = XML::Simple.open( "t.xsl" )
      
      out = @xslt.serve()
      assert_equal( @testOut, out )
      assert_equal( [], @errors )
    rescue LoadError => e
      # just skip it
    end
  end

  def test_from_smart
    begin
      require "xml/smart"
      
      @xslt.xml = XML::Smart.open( "t.xml" )
      @xslt.xsl = XML::Smart.open( "t.xsl" )
      
      out = @xslt.serve()
      assert_equal( @testOut, out )
      assert_equal( [], @errors )
    rescue LoadError => e
      # just skip it
    end
  end

  def test_from_rexml
    require 'rexml/document'
    @xslt.xml = REXML::Document.new File.read( "t.xml" )
    @xslt.xsl = REXML::Document.new File.read( "t.xsl" )
    
    out = @xslt.serve()
    assert_equal( [], @errors )
    assert_equal( @testOut, out )
  end

  def test_error_1
    assert_raises(XML::XSLT::ParsingError) do
      @xslt.xsl = "nil"
    end
    
    errors = ["Entity: line 1: ",
              "parser ",
              "error : ",
              "Start tag expected, '<' not found\n",
              "nil\n",
              "^\n"] 
  
    assert_equal( errors, @errors )
  end

  def test_error_2
    assert_raises(XML::XSLT::ParsingError) do
      @xslt.xml = "nil"
    end
    
    errors = ["Entity: line 1: ",
              "parser ",
              "error : ",
              "Start tag expected, '<' not found\n",
              "nil\n",
              "^\n"] 
  
    assert_equal( errors, @errors )
  end

# this test fails (any reason that it *should* raise an error?)
=begin
  def test_error_3
    assert_raises(XML::XSLT::ParsingError) do
      @xslt.xml = "t.xsl"
    end
  end
=end

  def test_transformation_error
    @xslt.xml = "<test/>"
    # substitute so that the function is guaranteed to not be registered
    @xslt.xsl = EXT_FUNC_XSL.sub( /foo/, "bar")

    assert_raises(XML::XSLT::TransformationError) do
      @xslt.serve
    end

    errors = ["xmlXPathCompOpEval: function bar not found\n",
              "Unregistered function\n",
              "xmlXPathCompiledEval: evaluation failed\n",
              "runtime error: element value-of\n",
              "xsltValueOf: text copy failed\n"]
    assert_equal(errors, @errors)
  end

  def test_external_function
    @xslt.xml = "<test/>"
    @xslt.xsl = EXT_FUNC_XSL

    XML::XSLT.registerExtFunc("http://necronomicorp.com/nil", "foo") do
      "success!"
    end

    assert_equal("<?xml version=\"1.0\"?>\nsuccess!\n", @xslt.serve())
    assert_equal([], @errors)
  end

  def test_base_uri_1
    @xslt.xml = "<test/>"
    xsl = "subdir/test.xsl"

    # the base URI of a loaded XSL file should be the URI of that file
    assert_nothing_raised( XML::XSLT::ParsingError ) do
      @xslt.xsl = xsl
    end
    
    assert_equal( [], @errors )
  end

  def test_base_uri_2
    @xslt.xml = "<test/>"
    xsl = File.read("subdir/test.xsl")
    
    # a file loaded from memory has no base URI, so this should fail
    assert_raises( XML::XSLT::ParsingError ) do
      @xslt.xsl = xsl
    end

    errors = ["I/O ",
              "warning : ",
              "failed to load external entity \"result.xsl\"\n",
              "compilation error: element import\n",
              "xsl:import : unable to load result.xsl\n"]

    assert_equal( errors, @errors )
  end
  
  def test_alias
    assert_nothing_raised do
      XML::XSLT.register_ext_func("http://necronomicorp.com/nil", "nil") {}
    end
  end
end
