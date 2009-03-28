require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/catalog/show.html.erb" do
  
  include Blacklight::SolrHelper

  before(:each) do
    # get actual solr response
    all_docs_query = ''
    @solr_resp = get_search_results(all_docs_query)
    @document = @solr_resp.docs.first
# TODO:  should probably not have id field name hardcoded
    @div_doc_id = 'div[id=doc_' + @document[:id] + ']'
    
    assigns[:response] = @solr_resp
    assigns[:document] = @document
    
    @previousDocument = mock("prev_doc")
    @previousDocument.should_receive(:[]).with(:id).and_return("abc")
    @nextDocument = mock("next_doc")
    @nextDocument.should_receive(:[]).with(:id).and_return("xyz")
    assigns[:previous_document] = @previousDocument
    assigns[:next_document] = @nextDocument

    session[:search] = {:q => "query", :f => "facets", :per_page => "10", :page => "2"}
    render 'catalog/show'
  end

  html_title_field = DisplayFields.show_view[:html_title]
  doc_heading_field = DisplayFields.show_view[:heading]
# so far, only default display type in plugin
  display_type_field = DisplayFields.show_view[:display_type]
  
  it "should have text for html title field specified in solr.yml: " + html_title_field do
    @document[html_title_field].should_not be_nil
  end
  
  it "should have a div containing the document id" do
    @solr_resp.should have_tag(@div_doc_id)
  end

# TODO: re-write this. --bess
# TODO:  should NOT have h2 hardcoded for document heading field.  
#  it "should have an h2 matching contents of heading field specified in solr.yml: " + doc_heading_field do
#    @solr_resp.should have_tag(@div_doc_id)
#      with_tag('h2', {:text => @document[doc_heading_field]})
#  end

# TODO: re-write this. --bess
#  it "should have some displayed field values" do
#    @solr_resp.should have_tag('div[class=row]')
#      with_tag('dt', {:text => /\S+/})
#      with_tag('dd', {:text => /\S+/})
#  end


  # Previous and Next Links
  it "should have previousNextDocument div" do
    response.should have_tag("div[id=previousNextDocument]")
  end  

# TODO: tests that need writing?
=begin
  # Previous and Next Links
  it "should have a next link" do
    't'.should == 'f'
  end
  it "should not have a next link if it's the last document" do
    't'.should == 'f'
  end
  it "should have a previous link" do
    't'.should == 'f'
  end
  it "should not have a previous link if it's the first document" do
    't'.should == 'f'
  end
  
  it "should have a back-to-search-results link" do
    't'.should == 'f'
  end
=end  

end