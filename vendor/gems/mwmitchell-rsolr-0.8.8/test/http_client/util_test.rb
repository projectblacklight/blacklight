require 'helper'

class HTTPUtilTest < RSolrBaseTest
  
  class DummyClass
    include RSolr::HTTPClient::Util
  end
  
  def setup
    @c = DummyClass.new
  end
  
  def test_build_url
    m = @c.method(:build_url)
    assert_equal '/something', m.call('/something')
    assert_equal '/something?q=Testing', m.call('/something', :q=>'Testing')
    assert_equal '/something?array=1&array=2&array=3', m.call('/something', :array=>[1, 2, 3])
    assert_equal '/something?array=1&array=2&array=3&q=A', m.call('/something', :q=>'A', :array=>[1, 2, 3])
  end
  
  def test_escape
    assert_equal '%2B', @c.escape('+')
    assert_equal 'This+is+a+test', @c.escape('This is a test')
    assert_equal '%3C%3E%2F%5C', @c.escape('<>/\\')
    assert_equal '%22', @c.escape('"')
    assert_equal '%3A', @c.escape(':')
  end
  
  def test_hash_to_params
    my_params = {
      :z=>'should be last',
      :q=>'test',
      :d=>[1, 2, 3, 4],
      :b=>:zxcv,
      :x=>['!', '*', nil]
    }
    assert_equal 'b=zxcv&d=1&d=2&d=3&d=4&q=test&x=%21&x=%2A&z=should+be+last', @c.hash_to_params(my_params)
  end
  
end