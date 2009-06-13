module HTTPClientTestMethods
  
  URL = 'http://localhost:8983/solr/'
  
  def test_raise_unknown_adapter
    assert_raise RSolr::HTTPClient::UnkownAdapterError do
      c = RSolr::HTTPClient::Connector.new(:blah).connect(URL)
    end
  end
  
  # the responses from the HTTPClient adapter should return the same hash structure
  def test_get_response
    headers = {}
    data = nil
    response = @c.get('select', :q=>'*:*')
    assert_equal data, response[:data]
    assert_equal 200, response[:status_code]
    expected_params = {:q=>'*:*'}
    assert_equal expected_params, response[:params]
    assert_equal 'select', response[:path]
    assert response[:body] =~ /name="responseHeader"/
    assert_equal 'http://localhost:8983/solr/select?q=%2A%3A%2A', response[:url]
    assert_equal headers, response[:headers]
  end
  
  def test_post_response
    headers = {"Content-Type" => 'text/xml; charset=utf-8'}
    data = '<add><doc><field name="id">1</field></doc></add>'
    response = @c.post('update', data, {}, headers)
    assert_equal data, response[:data]
    assert_equal 200, response[:status_code]
    expected_params = {}
    assert_equal expected_params, response[:params]
    assert_equal 'update', response[:path]
    assert response[:body] =~ /name="responseHeader"/
    assert_equal 'http://localhost:8983/solr/update', response[:url]
    assert_equal headers, response[:headers]
  end
  
end