# These are all of the test methods used by the various connection + adapter tests
# Currently: Direct and HTTP
# By sharing these tests, we can make sure the adapters are doing what they're suppossed to
# while staying "dry"

module ConnectionTestMethods
  
  
  def teardown
    @solr.delete_by_query('id:[* TO *]')
    @solr.commit
    assert_equal 0, @solr.select(:q=>'*:*')['response']['docs'].size
  end
  
  # If :wt is NOT :ruby, the format doesn't get converted into a Mash (special Hash; see lib/mash.rb)
  # Raw ruby can be returned by using :wt=>'ruby', not :ruby
  def test_raw_response_formats
    ruby_response = @solr.select(:q=>'*:*', :wt=>'ruby')
    assert ruby_response.is_a?(String)
    assert ruby_response =~ %r('wt'=>'ruby')
    # xml?
    xml_response = @solr.select(:q=>'*:*', :wt=>'xml')
    assert xml_response.is_a?(String)
    assert xml_response =~ %r(<str name="wt">xml</str>)
    # json?
    json_response = @solr.select(:q=>'*:*', :wt=>'json')
    assert json_response.is_a?(String)
    assert json_response =~ %r("wt":"json")
  end
  
  def test_raise_on_invalid_query
    assert_raise RSolr::RequestError do
      @solr.select(:q=>'!')
    end
  end
  
  def test_select_response_docs
    @solr.add(:id=>1, :price=>1.00, :cat=>['electronics', 'something else'])
    @solr.commit
    r = @solr.select(:q=>'*:*')
    assert r.is_a?(Hash)
    
    docs = r['response']['docs']
    assert_equal Array, docs.class
    first = docs.first
    
    # test the has? method
    assert_equal 1.00, first['price']
    
    assert_equal Array, first['cat'].class
    assert first['cat'].include?('electronics')
    assert first['cat'].include?('something else')
    assert first['cat'].include?('something else')
    
  end
  
  def test_add
    assert_equal 0, @solr.select(:q=>'*:*')['response']['numFound']
    update_response = @solr.add({:id=>100})
    assert update_response.is_a?(Hash)
    #
    @solr.commit
    assert_equal 1, @solr.select(:q=>'*:*')['response']['numFound']
  end
  
  def test_delete_by_id
    @solr.add(:id=>100)
    @solr.commit
    total = @solr.select(:q=>'*:*')['response']['numFound']
    assert_equal 1, total
    delete_response = @solr.delete_by_id(100)
    @solr.commit
    assert delete_response.is_a?(Hash)
    total = @solr.select(:q=>'*:*')['response']['numFound']
    assert_equal 0, total
  end
  
  def test_delete_by_query
    @solr.add(:id=>1, :name=>'BLAH BLAH BLAH')
    @solr.commit
    assert_equal 1, @solr.select(:q=>'*:*')['response']['numFound']
    response = @solr.delete_by_query('name:"BLAH BLAH BLAH"')
    @solr.commit
    assert response.is_a?(Hash)
    assert_equal 0, @solr.select(:q=>'*:*')['response']['numFound']
  end
  
  def test_admin_luke_index_info
    response = @solr.send_request('/admin/luke', :numTerms=>0)
    assert response.is_a?(Hash)
    # make sure the ? methods are true/false
    assert [true, false].include?(response['index']['current'])
    assert [true, false].include?(response['index']['optimized'])
    assert [true, false].include?(response['index']['hasDeletions'])
  end
  
end