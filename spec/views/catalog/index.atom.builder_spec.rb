# frozen_string_literal: true
require 'rexml/document'

RSpec.describe "catalog/index" do
  let(:document_list) do
    10.times.map do |i|
      doc = SolrDocument.new(id: i)
      allow(doc).to receive(:export_as_some_format).and_return("")
      allow(doc).to receive(:to_semantic_values).and_return(author: ['xyz']) if i == 0
      doc.will_export_as(:some_format, "application/some-format") if i == 1
      doc
    end
  end

  let(:blacklight_config) { CatalogController.blacklight_config }

  before do
    @response = Blacklight::Solr::Response.new({ response: { numFound: 30 } }, start: 10, rows: 10)
    allow(@response).to receive(:documents).and_return(document_list)
    params['content_format'] = 'some_format'
    allow(view).to receive(:action_name).and_return('index')
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:search_field_options_for_select).and_return([])
  end

  # We need to use rexml to test certain things that have_tag wont' test
  let(:response_xml) { REXML::Document.new(rendered) }

  it "has contextual information" do
    render template: 'catalog/index', formats: [:atom]

    expect(rendered).to have_selector("link[rel=self]")
    expect(rendered).to have_selector("link[rel=next]")
    expect(rendered).to have_selector("link[rel=previous]")
    expect(rendered).to have_selector("link[rel=first]")
    expect(rendered).to have_selector("link[rel=last]")
    expect(rendered).to have_selector("link[rel='alternate'][type='text/html']")
    expect(rendered).to have_selector("link[rel=search][type='application/opensearchdescription+xml']")
  end

  it "gets paging data correctly from response" do
    render template: 'catalog/index', formats: [:atom]

    # Can't use have_tag for namespaced elements, sorry.
    expect(response_xml.elements["/feed/opensearch:totalResults"].text).to eq "30"
    expect(response_xml.elements["/feed/opensearch:startIndex"].text).to eq "10"
    expect(response_xml.elements["/feed/opensearch:itemsPerPage"].text).to eq "10"
  end

  it "includes an opensearch Query role=request" do
    render template: 'catalog/index', formats: [:atom]

    expect(response_xml.elements.to_a("/feed/opensearch:itemsPerPage")).to have(1).item
    query_el = response_xml.elements["/feed/opensearch:Query"]
    expect(query_el).not_to be_nil
    expect(query_el.attributes["role"]).to eq "request"
    expect(query_el.attributes["searchTerms"]).to eq ""
    expect(query_el.attributes["startPage"]).to eq "2"
  end

  it "has ten entries" do
    render template: 'catalog/index', formats: [:atom]

    expect(rendered).to have_selector("entry", count: 10)
  end

  describe "entries" do
    it "has a title" do
      render template: 'catalog/index', formats: [:atom]
      expect(rendered).to have_selector("entry > title")
    end

    it "has an updated" do
      render template: 'catalog/index', formats: [:atom]
      expect(rendered).to have_selector("entry > updated")
    end

    it "has html link" do
      render template: 'catalog/index', formats: [:atom]
      expect(rendered).to have_selector("entry > link[rel=alternate][type='text/html']")
    end

    it "has an id" do
      render template: 'catalog/index', formats: [:atom]
      expect(rendered).to have_selector("entry > id")
    end

    it "has a summary" do
      stub_template "catalog/_index.html.erb" => "partial content"
      render template: 'catalog/index', formats: [:atom]
      expect(rendered).to have_selector("entry > summary", text: 'partial content')
    end

    context 'with a custom HTML partial' do
      before do
        blacklight_config.view.atom.summary_partials = ['whatever']
        stub_template 'catalog/_whatever_default.html.erb' => 'whatever content'
      end

      it "has the customized summary" do
        render template: 'catalog/index', formats: [:atom]
        expect(rendered).to have_selector("entry > summary", text: 'whatever content')
      end
    end

    describe "with an author" do
      let(:entry) { response_xml.elements.to_a("/feed/entry")[0] }

      it "has author tag" do
        render template: 'catalog/index', formats: [:atom]
        expect(entry.elements["author/name"].text).to eq 'xyz'
      end
    end

    describe "without an author" do
      let(:entry) { response_xml.elements.to_a("/feed/entry")[1] }

      it "does not have an author tag" do
        render template: 'catalog/index', formats: [:atom]
        expect(entry.elements["author/name"]).to be_nil
      end
    end
  end

  describe "when content_format is specified" do
    describe "for an entry with content available" do
      let(:entry) { response_xml.elements.to_a("/feed/entry")[1].to_s }

      it "includes a link rel tag" do
        render template: 'catalog/index', formats: [:atom]
        expect(entry).to have_selector("link[rel=alternate][type='application/some-format']")
      end

      it "has content embedded" do
        render template: 'catalog/index', formats: [:atom]
        expect(entry).to have_selector("content")
      end
    end

    describe "for an entry with NO content available" do
      let(:entry) { response_xml.elements.to_a("/feed/entry")[5].to_s }

      it "does not have content embedded" do
        render template: 'catalog/index', formats: [:atom]
        expect(entry).not_to have_selector("content[type='application/some-format']")
      end
    end
  end
end
