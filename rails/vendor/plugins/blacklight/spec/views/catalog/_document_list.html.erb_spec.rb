require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/catalog/_document_list.html.erb" do  
  
  include Blacklight::SolrHelper
  
  before(:each) do
    # get actual solr response
    all_docs_query = ''
    @solr_resp = get_search_results(all_docs_query)
    @doc = @solr_resp.docs.first
    assigns[:response] = @solr_resp
    render :partial => 'catalog/document_list'
  end

# TODO: re-write this test --bess
#  it "should contain div tags with id 'documents' and 'document'" do
#    @solr_resp.should have_tag('div[id=documents]') do
#      with_tag('div[class=document]')
#    end
#  end 

# TODO: re-write this test --bess
#  it "should have document links that aren't empty strings" do
#    @solr_resp.should have_tag('div[class=document]') do
#      with_tag('a[href]', {:text => /\S+/})
#    end
#  end
  
  describe "individual document" do
    show_link_field = DisplayFields.index_view[:show_link]
    it "should have show_link field indicated in solr.yml: " + show_link_field do
      @doc.get(show_link_field).should_not be_nil
    end
    
    rec_disp_type_field = DisplayFields.index_view[:record_display_type]
    it "should have record_display_type field indicated in solr.yml: " + rec_disp_type_field do
      @doc.get(rec_disp_type_field).should_not be_nil      
    end
  end

end