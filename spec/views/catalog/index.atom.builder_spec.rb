require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Atom feed view" do  

  before(:all) do
    # Load sample responses from Solr to a sample request, to test against
    @data = YAML.load(File.open(File.dirname(__FILE__) + 
                               "/../../data/sample_docs.yml"))
    @rsolr_response = RSolr::Ext::Response::Base.new(@data["solr_response"], nil, @data["params"])
    @params = @data["params"]
    @document_list = @data["document_list_mash"].collect do |d|   
      SolrDocument.new(d)
    end
  end
  before(:each) do

                               
    assigns[:response] = @rsolr_response
    # not sure why we can't use assigns for 'params', instead this weird way,
    # but okay. 
    params.merge!( @params )
    
    assigns[:document_list] = @document_list

    render "catalog/index.atom.builder"

    # We need to use rexml to test certain things that have_tag wont' test    
    @response_xml = REXML::Document.new(response.body.to_s)   
  end

  it "should have contextual information" do
    response.should have_tag("link[rel=self]")
    response.should have_tag("link[rel=next]")
    response.should have_tag("link[rel=previous]")
    response.should have_tag("link[rel=first]")
    response.should have_tag("link[rel=last]")
    response.should have_tag("link[rel=alternate][type=text/html]")
    response.should have_tag( "link[rel=search][type=application/opensearchdescription+xml]")    
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
    response.should have_tag("entry", :count => 10)
  end

  describe "entries" do
    it "should have a title" do
      response.should have_tag("entry") { with_tag("title") }
    end
    it "should have an updated" do
      response.should have_tag("entry") { with_tag("updated") }
    end
    it "should have html link" do
      response.should have_tag("entry") do
        with_tag("link[rel=alternate][type=text/html]")
      end
    end
    it "should have an id" do
      response.should have_tag("entry") { with_tag("id") }
    end
    it "should have a summary" do
      response.should have_tag("entry") { with_tag("summary") }
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
        @entry.to_s.should have_tag("link[rel=alternate][type=application/marc]")
      end
      it "should have content embedded" do
        @entry.to_s.should have_tag("content")
      end
    end
    describe "for an entry with NO content available" do
      before do
        @entry = @response_xml.elements.to_a("/feed/entry")[5]
      end
      it "should include content" do
        @entry.to_s.should_not have_tag("content[type=application/marc]")
      end
    end
  end

  
end


