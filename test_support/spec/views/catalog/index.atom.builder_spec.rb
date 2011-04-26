require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Atom feed view" do  
  

  before(:all) do
    class AtomMockDocument
      include Blacklight::Solr::Document
    end

    AtomMockDocument.field_semantics.merge!(    
      :title => "title_display",
      :author => "author_display"        
    )
    AtomMockDocument.extension_parameters[:marc_format_type] = :marc21
    AtomMockDocument.extension_parameters[:marc_source_field] = :marc_display
    AtomMockDocument.use_extension( Blacklight::Solr::Document::Marc) do |document|
      document.key?( :marc_display  )
    end
  
    # Load sample responses from Solr to a sample request, to test against
    @data = YAML.load(File.open(File.dirname(__FILE__) + 
                               "/../../data/sample_docs.yml"))
    @rsolr_response = RSolr::Ext::Response::Base.new(@data["solr_response"], nil, @data["params"])
    @params = @data["params"]
    @document_list = @data["document_list_mash"].collect do |d|   
      AtomMockDocument.new(d)
    end
  end
  before(:each) do

    # Not sure what Assigns was doing here ... dhf
    #    assigns[:response] = @rsolr_response
    #    assigns[:document_list] = @document_list
    # not sure why we can't use assigns for 'params', instead this weird way,
    # but okay. 

    params.merge!( @params )
    @response = @rsolr_response
 
    #    render "catalog/index.atom.builder"
    # Default behavior in rails 3 is to assume you are rendering a partial,
    # so you need to be a little more explicit with reder calls outside current scope.
    render :file => "catalog/index.atom.builder", :content_type => "application/atom+xml", :object => @response 

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


