# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "catalog/index" do  

  before(:all) do
    @config = Blacklight::Configuration.new.configure do |config|
      config.default_solr_params = {
        :fl => '*',
        :rows => 10
      }
    end
    
    @params = { 'content_format' => 'marc', :f => { :format => ['Book'] }, :page => 2 }

    # run a solr query to get our data
    c = CatalogController.new
    c.blacklight_config = @config
    @response, @document_list = c.get_search_results(@params)

    # munge the solr response to match test expectations
    @document_list[1] = SolrDocument.new(@document_list[1].to_mash.reject! { |k,v| k == "author_display" })
    @document_list[5] = SolrDocument.new(@document_list[1].to_mash.reject! { |k,v| k == "marc_display" })
  end
  before(:each) do
    # Not sure what Assigns was doing here ... dhf
    #    assigns[:response] = @rsolr_response
    #    assigns[:document_list] = @document_list
    # not sure why we can't use assigns for 'params', instead this weird way,
    # but okay. 

    params.merge!( @params )
    view.stub!(:blacklight_config).and_return(@config)
    view.stub!(:search_field_options_for_select).and_return([])

    if Rails.version >= "3.2.0"
      render :template => 'catalog/index', :formats => [:atom] 
    else
      render :template => 'catalog/index.atom'
    end

    # We need to use rexml to test certain things that have_tag wont' test    
    # note that response is depricated rails 3, use "redered" instead. 
    @response_xml = REXML::Document.new(rendered)   
  end

  it "should have contextual information" do
    rendered.should have_selector("link[rel=self]")
    rendered.should have_selector("link[rel=next]")
    rendered.should have_selector("link[rel=previous]")
    rendered.should have_selector("link[rel=first]")
    rendered.should have_selector("link[rel=last]")
    rendered.should have_selector("link[rel='alternate'][type='text/html']")
    rendered.should have_selector("link[rel=search][type='application/opensearchdescription+xml']") 
  end
  
  it "should get paging data correctly from response" do
    # Can't use have_tag for namespaced elements, sorry.    
    @response_xml.elements["/feed/opensearch:totalResults"].text.should == "30"
    @response_xml.elements["/feed/opensearch:startIndex"].text.should == "10"
    @response_xml.elements["/feed/opensearch:itemsPerPage"].text.should == "10"        
  end
  
  it "should include an opensearch Query role=request" do
        
    @response_xml.elements.to_a("/feed/opensearch:itemsPerPage").length.should == 1
    query_el = @response_xml.elements["/feed/opensearch:Query"]
    query_el.should_not be_nil
    query_el.attributes["role"].should == "request"
    query_el.attributes["searchTerms"].should == ""
    query_el.attributes["startPage"].should == "2"    
  end
  
  it "should have ten entries" do
    rendered.should have_selector("entry", :count => 10)
  end
  
  describe "entries" do
    it "should have a title" do
      rendered.should have_selector("entry > title")
    end
    it "should have an updated" do
      rendered.should have_selector("entry > updated")
    end
    it "should have html link" do
      rendered.should have_selector("entry > link[rel=alternate][type='text/html']")
    end
    it "should have an id" do
      rendered.should have_selector("entry > id")
    end
    it "should have a summary" do
      rendered.should have_selector("entry > summary") 
    end
    
    describe "with an author" do
      before do
        @entry = @response_xml.elements.to_a("/feed/entry")[0]
      end
      it "should have author tag" do
        @entry.elements["author/name"].should_not be_nil              
      end
    end
    
    describe "without an author" do
      before do
        @entry = @response_xml.elements.to_a("/feed/entry")[1]
      end
      it "should not have an author tag" do
        @entry.elements["author/name"].should be_nil
      end
    end
  end
  
  describe "when content_format is specified" do
    describe "for an entry with content available" do
      before do
        @entry = @response_xml.elements.to_a("/feed/entry")[0]
      end
      it "should include a link rel tag" do
        @entry.to_s.should have_selector("link[rel=alternate][type='application/marc']")
      end
      it "should have content embedded" do
        @entry.to_s.should have_selector("content")
      end
    end
    describe "for an entry with NO content available" do
      before do
        @entry = @response_xml.elements.to_a("/feed/entry")[5]
      end
      it "should include content" do
        @entry.to_s.should_not have_selector("content[type='application/marc']")
      end
    end
  end
end


