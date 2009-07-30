require 'test_unit_test_case'
require File.join(File.dirname(__FILE__), '..', 'lib', 'rsolr-ext')

class RSolrExtRequestTest < Test::Unit::TestCase
  
  test 'standard request' do
    std = RSolr::Ext::Request::Standard.new
    solr_params = std.map(
      :page=>2,
      :per_page=>10,
      :phrases=>{:name=>'This is a phrase'},
      :filters=>['test', {:price=>(1..10)}],
      :phrase_filters=>{:manu=>['Apple']},
      :queries=>'ipod',
      :facets=>{:fields=>['cat', 'blah']}
    )
    assert_equal ["test", "price:[1 TO 10]", "manu:\"Apple\""], solr_params[:fq]
    assert_equal 10, solr_params[:start]
    assert_equal 10, solr_params[:rows]
    assert_equal "ipod name:\"This is a phrase\"", solr_params[:q]
    assert_equal ['cat', 'blah'], solr_params['facet.field']
    assert_equal true, solr_params[:facet]
  end
  
  test 'fq param using the phrase_filters mapping' do
    std = RSolr::Ext::Request::Standard.new
    solr_params = std.map(
      :phrase_filters=>{:manu=>['Apple', 'ASG'], :color=>['red', 'blue']}
    )
    expected = {:fq=>["color:\"red\"", "color:\"blue\"", "manu:\"Apple\"", "manu:\"ASG\""]}
    assert expected, solr_params
  end
  
end