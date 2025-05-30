# frozen_string_literal: true

require 'rexml/document'

RSpec.describe "catalog/index" do
  let(:document_list) do
    10.times.map do |i|
      SolrDocument.new(id: i, title_tsim: "Title #{i}").tap do |doc|
        allow(doc).to receive(:export_as_some_format).and_return("")
        allow(doc).to receive(:to_semantic_values).and_return(author: ['xyz']) if i.zero?
        doc.will_export_as(:some_format, "application/some-format") if i == 1
      end
    end
  end

  let(:blacklight_config) { CatalogController.blacklight_config.deep_copy }
  let(:search_builder) { Blacklight::SearchBuilder.new(view) }
  let(:response) { blacklight_config.response_model.new({ response: { numFound: 30 } }, search_builder) }

  before do
    allow(view).to receive_messages(action_name: 'index', blacklight_config: blacklight_config)
    @response = response
    allow(controller).to receive(:search_state_class).and_return(Blacklight::SearchState)
    allow(search_builder).to receive_messages(start: 10, rows: 10)
    allow(response).to receive(:documents).and_return(document_list)
    params['content_format'] = 'some_format'
  end

  # We need to use rexml to test certain things that have_tag wont' test
  let(:response_xml) { REXML::Document.new(rendered) }

  it "has contextual information" do
    render template: 'catalog/index', formats: [:atom]

    expect(rendered).to have_css("link[rel=self]")
    expect(rendered).to have_css("link[rel=next]")
    expect(rendered).to have_css("link[rel=previous]")
    expect(rendered).to have_css("link[rel=first]")
    expect(rendered).to have_css("link[rel=last]")
    expect(rendered).to have_css("link[rel='alternate'][type='text/html']")
    expect(rendered).to have_css("link[rel=search][type='application/opensearchdescription+xml']")
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

    expect(rendered).to have_css("entry", count: 10)
  end

  describe "entries" do
    it "has a title" do
      render template: 'catalog/index', formats: [:atom]
      expect(rendered).to have_css("entry > title")
    end

    it "has an updated" do
      render template: 'catalog/index', formats: [:atom]
      expect(rendered).to have_css("entry > updated")
    end

    it "has html link" do
      render template: 'catalog/index', formats: [:atom]
      expect(rendered).to have_css("entry > link[rel=alternate][type='text/html']")
    end

    it "has an id" do
      render template: 'catalog/index', formats: [:atom]
      expect(rendered).to have_css("entry > id")
    end

    it "has a summary" do
      render template: 'catalog/index', formats: [:atom]
      expect(rendered).to have_css("entry > summary", text: 'Title 0')
    end

    context 'with a custom template' do
      before do
        my_template = Class.new(ViewComponent::Base) do
          def initialize(**); end

          def call
            'whatever content'.html_safe
          end

          def self.name
            'TestComponent'
          end
        end
        blacklight_config.view.atom.summary_component = my_template
      end

      it "has the customized summary" do
        render template: 'catalog/index', formats: [:atom]
        expect(rendered).to have_css("entry > summary", text: 'whatever content')
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
        expect(entry).to have_css("link[rel=alternate][type='application/some-format']")
      end

      it "has content embedded" do
        render template: 'catalog/index', formats: [:atom]
        expect(entry).to have_css("content")
      end
    end

    describe "for an entry with NO content available" do
      let(:entry) { response_xml.elements.to_a("/feed/entry")[5].to_s }

      it "does not have content embedded" do
        render template: 'catalog/index', formats: [:atom]
        expect(entry).to have_no_css("content[type='application/some-format']")
      end
    end
  end
end
