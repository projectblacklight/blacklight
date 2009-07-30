require 'helper'

class SolrTest < RSolrBaseTest
  
  def setup
    if defined?(JRUBY_VERSION)
      @solr = RSolr.connect(:adapter=>:direct)
    else
      @solr = RSolr.connect
    end
  end
  
  def test_escape
    expected = %q(http\:\/\/lucene\.apache\.org\/solr)
    source = "http://lucene.apache.org/solr"
    assert_equal expected, RSolr.escape(source)
    assert @solr.respond_to?(:escape)
    assert_equal expected, @solr.escape(source)
  end
  
end