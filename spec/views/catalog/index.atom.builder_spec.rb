require 'spec_helper'
require 'rexml/document'

describe "catalog/index" do  

  before(:all) do
    @response = Blacklight::Solr::Response.new({ response: { numFound: 30 }}, { start: 10, rows: 10})
    
    @config = CatalogController.blacklight_config
  end

  let(:document_list) do
    10.times.map { |i| SolrDocument.new(id: i) }
  end

  before(:each) do
    # Not sure what Assigns was doing here ... dhf
    #    assigns[:response] = @rsolr_response
    #    assigns[:document_list] = @document_list
    # not sure why we can't use assigns for 'params', instead this weird way,
    # but okay. 
    
    params.merge!( 'content_format' => 'some_format' )
    @document_list = document_list
    allow_any_instance_of(SolrDocument).to receive(:export_as_some_format).and_return("")
    allow(document_list[0]).to receive(:to_semantic_values).and_return(author: ['xyz'])
    @document_list[1].will_export_as(:some_format, "application/some-format")

    allow(view).to receive(:blacklight_config).and_return(@config)
    allow(view).to receive(:search_field_options_for_select).and_return([])

    render :template => 'catalog/index', :formats => [:atom] 
  end

  let(:response_xml) do
    # We need to use rexml to test certain things that have_tag wont' test    
    # note that response is depricated rails 3, use "redered" instead. 
    REXML::Document.new(rendered)   
  end

  it "should have contextual information" do
    expect(rendered).to have_selector("link[rel=self]")
    expect(rendered).to have_selector("link[rel=next]")
    expect(rendered).to have_selector("link[rel=previous]")
    expect(rendered).to have_selector("link[rel=first]")
    expect(rendered).to have_selector("link[rel=last]")
    expect(rendered).to have_selector("link[rel='alternate'][type='text/html']")
    expect(rendered).to have_selector("link[rel=search][type='application/opensearchdescription+xml']") 
  end
  
  it "should get paging data correctly from response" do
    # Can't use have_tag for namespaced elements, sorry.    
    expect(response_xml.elements["/feed/opensearch:totalResults"].text).to eq "30"
    expect(response_xml.elements["/feed/opensearch:startIndex"].text).to eq "10"
    expect(response_xml.elements["/feed/opensearch:itemsPerPage"].text).to eq "10"        
  end
  
  it "should include an opensearch Query role=request" do
        
    expect(response_xml.elements.to_a("/feed/opensearch:itemsPerPage")).to have(1).item
    query_el = response_xml.elements["/feed/opensearch:Query"]
    expect(query_el).to_not be_nil
    expect(query_el.attributes["role"]).to eq "request"
    expect(query_el.attributes["searchTerms"]).to eq ""
    expect(query_el.attributes["startPage"]).to eq "2"    
  end
  
  it "should have ten entries" do
    expect(rendered).to have_selector("entry", :count => 10)
  end
  
  describe "entries" do
    it "should have a title" do
      expect(rendered).to have_selector("entry > title")
    end
    it "should have an updated" do
      expect(rendered).to have_selector("entry > updated")
    end
    it "should have html link" do
      expect(rendered).to have_selector("entry > link[rel=alternate][type='text/html']")
    end
    it "should have an id" do
      expect(rendered).to have_selector("entry > id")
    end
    it "should have a summary" do
      expect(rendered).to have_selector("entry > summary") 
    end
    
    describe "with an author" do
      before do
        @entry = response_xml.elements.to_a("/feed/entry")[0]
      end
      it "should have author tag" do
        expect(@entry.elements["author/name"].text).to eq 'xyz'
      end
    end
    
    describe "without an author" do
      before do
        @entry = response_xml.elements.to_a("/feed/entry")[1]
      end
      it "should not have an author tag" do
        expect(@entry.elements["author/name"]).to be_nil
      end
    end
  end
  
  describe "when content_format is specified" do
    describe "for an entry with content available" do
      let(:entry) do
        response_xml.elements.to_a("/feed/entry")[1].to_s
      end
      it "should include a link rel tag" do
        expect(entry).to have_selector("link[rel=alternate][type='application/some-format']")
      end
      it "should have content embedded" do
        expect(entry).to have_selector("content")
      end
    end
    describe "for an entry with NO content available" do
      before do
        @entry = response_xml.elements.to_a("/feed/entry")[5]
      end
      it "should include content" do
        expect(@entry.to_s).to_not have_selector("content[type='application/some-format']")
      end
    end
  end
end
