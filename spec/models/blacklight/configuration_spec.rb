# frozen_string_literal: true

RSpec.describe Blacklight::Configuration, :api do
  let(:config) do
    described_class.new
  end

  describe "#repository" do
    context 'when the class is configured in blacklight.yml' do
      it "uses the default repository class" do
        expect(config.repository).to be_a(Blacklight::Solr::Repository)
      end
    end

    context 'when the class is set in the configuration' do
      let(:custom_repository_class) { Class.new(Blacklight::Solr::Repository) }

      before do
        config.repository_class = custom_repository_class
      end

      it "uses the custom repository class" do
        expect(config.repository).to be_a(custom_repository_class)
      end
    end
  end

  it "supports arbitrary configuration values" do
    config.a = 1

    expect(config.a).to eq 1
    expect(config[:a]).to eq 1
  end

  describe "initialization" do
    it "is an OpenStructWithHashAccess" do
      expect(config).to be_a Blacklight::OpenStructWithHashAccess
    end

    context 'when passed a block' do
      let(:config) do
        described_class.new(a: 1) { |c| c.a = 2 }
      end

      it "accepts a block for configuration" do
        expect(config.a).to eq 2

        config.configure { |c| c.a = 3 }

        expect(config.a).to eq 3
      end
    end
  end

  describe "defaults" do
    it "has a hash of default rsolr query parameters" do
      expect(config.default_solr_params).to be_a Hash
    end

    it "has openstruct values for show and index parameters" do
      expect(config.show).to be_a OpenStruct
      expect(config.index).to be_a OpenStruct
    end

    it "has ordered hashes for field configuration" do
      expect(config.facet_fields).to be_a Hash
      expect(config.index_fields).to be_a Hash
      expect(config.show_fields).to be_a Hash
      expect(config.search_fields).to be_a Hash
      expect(config.show_fields).to be_a Hash
      expect(config.search_fields).to be_a Hash
      expect(config.sort_fields).to be_a Hash
    end
  end

  describe "#connection_config" do
    let(:custom_config) { double }

    it "has the global blacklight configuration" do
      expect(config.connection_config).to eq Blacklight.connection_config
    end

    it "is overridable with custom configuration" do
      config.connection_config = custom_config
      expect(config.connection_config).to eq custom_config
    end
  end

  describe 'config.index.document_actions' do
    it 'allows you to use the << operator' do
      config.index.document_actions << :blah
      expect(config.index.document_actions.blah).to have_attributes key: :blah
      expect(config.index.document_actions.blah.name).to eq :blah
    end
  end

  describe "config.index.respond_to" do
    it "has a list of additional formats for index requests to respond to" do
      config.index.respond_to.xml = true

      config.index.respond_to.csv = { layout: false }

      config.index.respond_to.yaml = -> { render plain: "" }

      expect(config.index.respond_to.keys).to eq [:xml, :csv, :yaml]
    end
  end

  describe "spell_max" do
    it "defaults to 5" do
      expect(config.spell_max).to eq 5
    end

    it "accepts config'd value" do
      expect(described_class.new(spell_max: 10).spell_max).to eq 10
    end
  end

  describe "for_display_type" do
    let(:image) { SolrDocument.new(format: 'Image') }
    let(:sound) { SolrDocument.new(format: 'Sound') }

    it "adds index fields just for a certain type" do
      config.for_display_type "Image" do |c|
        c.add_index_field :dimensions
      end
      config.add_index_field :title

      expect(config.index_fields_for(['Image'])).to have_key 'dimensions'
      expect(config.index_fields_for(['Image'])).to have_key 'title'
      expect(config.index_fields_for(['Sound'])).not_to have_key 'dimensions'
      expect(config.index_fields_for(['Image'])).to have_key 'title'
      expect(config.index_fields).not_to have_key 'dimensions'
    end

    it "adds show fields just for a certain type" do
      config.for_display_type "Image" do |c|
        c.add_show_field :dimensions
      end
      config.add_show_field :title

      expect(config.show_fields_for(['Image'])).to have_key 'dimensions'
      expect(config.show_fields_for(['Image'])).to have_key 'title'
      expect(config.show_fields_for(['Sound'])).not_to have_key 'dimensions'
      expect(config.show_fields_for(['Image'])).to have_key 'title'
      expect(config.show_fields).not_to have_key 'dimensions'
    end

    it 'calls the block on subsequent invocations' do
      config.for_display_type "Image" do |c|
        c.add_show_field :dimensions
      end
      config.for_display_type "Image" do |c|
        c.add_show_field :photographer
      end

      expect(config.show_fields_for(['Image'])).to have_key 'dimensions'
      expect(config.show_fields_for(['Image'])).to have_key 'photographer'
    end
  end

  describe "inheritable_copy" do
    let(:klass) { Class.new }
    let(:config_copy) { config.inheritable_copy(klass) }

    it "provides a deep copy of the configuration" do
      config_copy.a = 1

      @mock_facet = Blacklight::Configuration::FacetField.new
      config_copy.add_facet_field "dummy_field", @mock_facet

      expect(config.a).to be_nil
      expect(config.facet_fields).not_to include(@mock_facet)
    end

    context "when model classes are customised" do
      before do
        config.response_model = Hash
        config.document_model = Array
      end

      it "does not dup response_model or document_model" do
        expect(config_copy.response_model).to eq Hash
        expect(config_copy.document_model).to eq Array
      end
    end

    it "provides cloned copies of mutable data structures" do
      config.a = { value: 1 }
      config.b = [1, 2, 3]
      config.c = Blacklight::Configuration::Field.new(key: 'c', value: %w[a b])

      config_copy.a[:value] = 2
      config_copy.b << 5
      config_copy.c.value << 'c'

      expect(config.a[:value]).to eq 1
      expect(config_copy.a[:value]).to eq 2
      expect(config.b).to contain_exactly(1, 2, 3)
      expect(config_copy.b).to contain_exactly(1, 2, 3, 5)
      expect(config.c.value).to match_array %w[a b]
      expect(config_copy.c.value).to match_array %w[a b c]
    end
  end

  describe "add alternative solr fields" do
    it "lets you define any arbitrary solr field" do
      described_class.define_field_access :my_custom_field

      config = described_class.new do |config|
        config.add_my_custom_field 'qwerty', label: "asdf"
      end

      expect(config.my_custom_fields.keys).to include('qwerty')
    end

    it "lets you define a field accessor that uses an existing field-type" do
      described_class.define_field_access :my_custom_facet_field, class: Blacklight::Configuration::FacetField

      config = described_class.new do |config|
        config.add_my_custom_facet_field 'qwerty', label: "asdf"
      end

      expect(config.my_custom_facet_fields['qwerty']).to be_a(Blacklight::Configuration::FacetField)
    end
  end

  describe "add_facet_field" do
    it "accepts field name and hash form arg" do
      config.add_facet_field('format', label: "Format", limit: true)

      expect(config.facet_fields["format"]).not_to be_nil
      expect(config.facet_fields["format"]["label"]).to eq "Format"
      expect(config.facet_fields["format"]["limit"]).to be true
    end

    it "accepts FacetField obj arg" do
      config.add_facet_field("format", Blacklight::Configuration::FacetField.new(label: "Format"))

      expect(config.facet_fields["format"]).not_to be_nil
      expect(config.facet_fields["format"]["label"]).to eq "Format"
    end

    it "accepts field name and block form" do
      config.add_facet_field("format") do |facet|
        facet.label = "Format"
        facet.limit = true
      end

      expect(config.facet_fields["format"]).not_to be_nil
      expect(config.facet_fields["format"].limit).to be true
    end

    it "accepts block form" do
      config.add_facet_field do |facet|
        facet.field = "format"
        facet.label = "Format"
      end

      expect(config.facet_fields['format']).not_to be_nil
    end

    it "accepts a configuration hash" do
      config.add_facet_field field: 'format', label: 'Format'
      expect(config.facet_fields['format']).not_to be_nil
    end

    it "accepts array form" do
      config.add_facet_field([{ field: 'format', label: 'Format' }, { field: 'publication_date', label: 'Publication Date' }])

      expect(config.facet_fields).to have(2).fields
    end

    it "accepts array form with a block" do
      expect do |b|
        config.add_facet_field([{ field: 'format', label: 'Format' }, { field: 'publication_date', label: 'Publication Date' }], &b)
      end.to yield_control.twice
    end

    it "creates default label from titleized solr field" do
      config.add_facet_field("publication_date")

      expect(config.facet_fields["publication_date"].label).to eq "Publication Date"
    end

    it "allows you to not show the facet in the facet bar" do
      config.add_facet_field("publication_date", show: false)

      expect(config.facet_fields["publication_date"]['show']).to be false
    end

    it "raises on nil solr field name" do
      expect { config.add_facet_field(nil) }.to raise_error ArgumentError
    end

    it "looks up and match field names" do
      allow(config).to receive(:reflected_fields).and_return(
        "some_field_facet" => {},
        "another_field_facet" => {},
        "a_facet_field" => {}
      )
      expect { |b| config.add_facet_field match: /_facet$/, &b }.to yield_control.twice

      expect(config.facet_fields.keys).to eq %w[some_field_facet another_field_facet]
    end

    it "takes wild-carded field names and dereference them to solr fields" do
      allow(config).to receive(:reflected_fields).and_return(
        "some_field_facet" => {},
        "another_field_facet" => {},
        "a_facet_field" => {}
      )
      expect { |b| config.add_facet_field "*_facet", &b }.to yield_control.twice

      expect(config.facet_fields.keys).to eq %w[some_field_facet another_field_facet]
    end

    describe "if/unless conditions with legacy show parameter" do
      it "is hidden if the if condition is false" do
        expect(config.add_facet_field("hidden", if: false).if).to be false
        expect(config.add_facet_field("hidden_with_legacy", if: false, show: true).if).to be false
      end

      it "is true if the if condition is true" do
        expect(config.add_facet_field("hidden", if: true).if).to be true
        expect(config.add_facet_field("hidden_with_legacy", if: true, show: false).if).to be true
      end

      it "is true if the if condition is missing" do
        expect(config.add_facet_field("hidden", show: true).if).to be true
      end
    end
  end

  describe "add_index_field" do
    it "takes hash form" do
      config.add_index_field("title_tsim", label: "Title")

      expect(config.index_fields["title_tsim"]).not_to be_nil
      expect(config.index_fields["title_tsim"].label).to eq "Title"
    end

    it "takes IndexField param" do
      config.add_index_field("title_tsim", Blacklight::Configuration::IndexField.new(field: "title_display", label: "Title"))

      expect(config.index_fields["title_tsim"]).not_to be_nil
      expect(config.index_fields["title_tsim"].label).to eq "Title"
    end

    it "takes block form" do
      config.add_index_field("title_tsim") do |field|
        field.label = "Title"
      end
      expect(config.index_fields["title_tsim"]).not_to be_nil
      expect(config.index_fields["title_tsim"].label).to eq "Title"
    end

    it "creates default label from titleized field" do
      config.add_index_field("title_tsim")

      expect(config.index_fields["title_tsim"].label).to eq "Title Tsim"
    end

    it "raises on nil solr field name" do
      expect { config.add_index_field(nil) }.to raise_error ArgumentError
    end

    it "takes wild-carded field names and dereference them to solr fields" do
      allow(config).to receive(:reflected_fields).and_return(
        "some_field_display" => {},
        "another_field_display" => {},
        "a_facet_field" => {}
      )
      config.add_index_field "*_display"

      expect(config.index_fields.keys).to eq %w[some_field_display another_field_display]
    end

    it "queries solr and get live values for match fields", :integration do
      config.add_index_field match: /title.+sim/
      expect(config.index_fields.keys).to include "subtitle_tsim", "subtitle_vern_ssim", "title_tsim", "title_vern_ssim"
    end
  end

  describe "add_show_field" do
    it "takes hash form" do
      config.add_show_field("title_tsim", label: "Title")

      expect(config.show_fields["title_tsim"]).not_to be_nil
      expect(config.show_fields["title_tsim"].label).to eq "Title"
    end

    it "takes ShowField argument" do
      config.add_show_field("title_tsim", Blacklight::Configuration::ShowField.new(field: "title_display", label: "Title"))

      expect(config.show_fields["title_tsim"]).not_to be_nil
      expect(config.show_fields["title_tsim"].label).to eq "Title"
    end

    it "takes block form" do
      config.add_show_field("title_tsim") do |f|
        f.label = "Title"
      end

      expect(config.show_fields["title_tsim"]).not_to be_nil
      expect(config.show_fields["title_tsim"].label).to eq "Title"
    end

    it "creates default label humanized from field" do
      config.add_show_field("my_custom_field")

      expect(config.show_fields["my_custom_field"].label).to eq "My Custom Field"
    end

    it "raises on nil solr field name" do
      expect { config.add_show_field(nil) }.to raise_error ArgumentError
    end

    it "takes wild-carded field names and dereference them to solr fields" do
      allow(config).to receive(:reflected_fields).and_return(
        "some_field_display" => {},
        "another_field_display" => {},
        "a_facet_field" => {}
      )
      config.add_show_field "*_display"

      expect(config.show_fields.keys).to eq %w[some_field_display another_field_display]
    end
  end

  describe "add_search_field" do
    it "accepts hash form" do
      c = described_class.new
      c.add_search_field(key: "my_search_key")
      expect(c.search_fields["my_search_key"]).not_to be_nil
    end

    it "accepts two-arg hash form" do
      c = described_class.new

      c.add_search_field("my_search_type",
                         key: "my_search_type",
                         solr_parameters: { qf: "my_field_qf^10" },
                         solr_local_parameters: { pf: "$my_field_pf" })

      field = c.search_fields["my_search_type"]

      expect(field).not_to be_nil

      expect(field.solr_parameters).not_to be_nil
      expect(field.solr_local_parameters).not_to be_nil
    end

    it "accepts block form" do
      c = described_class.new

      c.add_search_field("some_field") do |field|
        field.solr_parameters = { qf: "solr_field^10" }
        field.solr_local_parameters = { pf: "$some_field_pf" }
      end

      f = c.search_fields["some_field"]

      expect(f).not_to be_nil
      expect(f.solr_parameters).not_to be_nil
      expect(f.solr_local_parameters).not_to be_nil
    end

    it "accepts SearchField object" do
      c = described_class.new

      f = Blacklight::Configuration::SearchField.new(foo: "bar")

      c.add_search_field("foo", f)

      expect(c.search_fields["foo"]).not_to be_nil
    end

    it "raises on nil key" do
      expect { config.add_search_field(nil, foo: "bar") }.to raise_error ArgumentError
    end

    it "creates default label from titleized field key" do
      config.add_search_field("author_name")

      expect(config.search_fields["author_name"].label).to eq "Author Name"
    end

    describe "if/unless conditions with legacy include_in_simple_search" do
      it "is hidden if the if condition is false" do
        expect(config.add_search_field("hidden", if: false).if).to be false
        expect(config.add_search_field("hidden_with_legacy", if: false, include_in_simple_search: true).if).to be false
      end

      it "is true if the if condition is true" do
        expect(config.add_search_field("hidden", if: true).if).to be true
        expect(config.add_search_field("hidden_with_legacy", if: true, include_in_simple_search: false).if).to be true
      end

      it "is true if the if condition is missing" do
        expect(config.add_search_field("hidden", include_in_simple_search: true).if).to be true
      end
    end
  end

  describe "add_sort_field" do
    it "takes a hash" do
      c = described_class.new
      c.add_sort_field(key: "my_sort_key", sort: "score desc")
      expect(c.sort_fields["my_sort_key"]).not_to be_nil
    end

    it "takes a two-arg form with a hash" do
      config.add_sort_field("score desc, pub_date_si desc, title_si asc", label: "relevance")
      expect(config.sort_fields.values.find { |f| f.label == "relevance" }).not_to be_nil
    end

    it "takes a SortField object" do
      config.add_sort_field(
        Blacklight::Configuration::SortField.new(label: "relevance",
                                                 sort: "score desc, pub_date_sort desc, title_sort asc")
      )
      expect(config.sort_fields.values.find { |f| f.label == "relevance" }).not_to be_nil
    end

    it "takes block form" do
      config.add_sort_field do |field|
        field.label = "relevance"
        field.sort = "score desc, pub_date_si desc, title_si asc"
      end

      expect(config.sort_fields.values.find { |f| f.label == "relevance" }).not_to be_nil
    end
  end

  describe "add_sms_field" do
    it "takes hash form" do
      config.add_sms_field("title_tsim", label: "Title")

      expect(config.sms_fields["title_tsim"]).not_to be_nil
      expect(config.sms_fields["title_tsim"].label).to eq "Title"
    end

    it "takes ShowField argument" do
      config.add_sms_field("title_tsim", Blacklight::Configuration::DisplayField.new(field: "title_display", label: "Title"))

      expect(config.sms_fields["title_tsim"]).not_to be_nil
      expect(config.sms_fields["title_tsim"].label).to eq "Title"
    end

    it "takes block form" do
      config.add_sms_field("title_tsim") do |f|
        f.label = "Title"
      end

      expect(config.sms_fields["title_tsim"]).not_to be_nil
      expect(config.sms_fields["title_tsim"].label).to eq "Title"
    end

    it "creates default label humanized from field" do
      config.add_sms_field("my_custom_field")

      expect(config.sms_fields["my_custom_field"].label).to eq "My Custom Field"
    end

    it "raises on nil solr field name" do
      expect { config.add_sms_field(nil) }.to raise_error ArgumentError
    end

    it "takes wild-carded field names and dereference them to solr fields" do
      allow(config).to receive(:reflected_fields).and_return(
        "some_field_display" => {},
        "another_field_display" => {},
        "a_facet_field" => {}
      )
      config.add_sms_field "*_display"

      expect(config.sms_fields.keys).to eq %w[some_field_display another_field_display]
    end
  end

  describe "add_email_field" do
    it "takes hash form" do
      config.add_email_field("title_tsim", label: "Title")

      expect(config.email_fields["title_tsim"]).not_to be_nil
      expect(config.email_fields["title_tsim"].label).to eq "Title"
    end

    it "takes ShowField argument" do
      config.add_email_field("title_tsim", Blacklight::Configuration::DisplayField.new(field: "title_display", label: "Title"))

      expect(config.email_fields["title_tsim"]).not_to be_nil
      expect(config.email_fields["title_tsim"].label).to eq "Title"
    end

    it "takes block form" do
      config.add_email_field("title_tsim") do |f|
        f.label = "Title"
      end

      expect(config.email_fields["title_tsim"]).not_to be_nil
      expect(config.email_fields["title_tsim"].label).to eq "Title"
    end

    it "creates default label humanized from field" do
      config.add_email_field("my_custom_field")

      expect(config.email_fields["my_custom_field"].label).to eq "My Custom Field"
    end

    it "raises on nil solr field name" do
      expect { config.add_email_field(nil) }.to raise_error ArgumentError
    end

    it "takes wild-carded field names and dereference them to solr fields" do
      allow(config).to receive(:reflected_fields).and_return(
        "some_field_display" => {},
        "another_field_display" => {},
        "a_facet_field" => {}
      )
      config.add_email_field "*_display"

      expect(config.email_fields.keys).to eq %w[some_field_display another_field_display]
    end
  end

  describe "#default_search_field" do
    it "uses the field with a :default key" do
      config.add_search_field('search_field_1')
      config.add_search_field('search_field_2', default: true)

      expect(config.default_search_field.key).to eq 'search_field_2'
    end
  end

  describe "#facet_paginator_class" do
    it "defaults to Blacklight::Solr::FacetPaginator" do
      expect(config.facet_paginator_class).to eq Blacklight::Solr::FacetPaginator
    end
  end

  describe '#view_config' do
    before do
      config.index.title_field = 'title_tsim'
    end

    context 'with a view that does not exist' do
      it 'defaults to the index config' do
        expect(config.view_config('this-doesnt-exist')).to have_attributes config.index.to_h
      end
    end

    context 'with the :show view' do
      it 'includes the show config' do
        expect(config.view_config(:show)).to have_attributes config.show.to_h
      end

      it 'uses the show document presenter' do
        expect(config.view_config(:show)).to have_attributes document_presenter_class: Blacklight::ShowPresenter
      end

      it 'includes index config defaults' do
        expect(config.view_config(:show)).to have_attributes title_field: 'title_tsim'
      end
    end

    context 'with just an action name' do
      it 'includes the action config' do
        expect(config.view_config(action_name: :show)).to have_attributes config.show.to_h
      end

      it 'includes the default action mapping configuration' do
        config.action_mapping.default.whatever = :some_value

        expect(config.view_config(action_name: :show)).to have_attributes whatever: :some_value
      end

      it 'includes the action-specific mappings' do
        config.action_mapping.foo.document_presenter_class = Blacklight::DocumentPresenter

        expect(config.view_config(action_name: :foo)).to have_attributes config.action_mapping.foo.to_h
      end

      it 'allows the action mapping to specific a parent configuration with some more defaults' do
        config.action_mapping.foo.parent_config = :bar
        config.action_mapping.bar.whatever = :bar_value

        expect(config.view_config(action_name: :foo)).to have_attributes whatever: :bar_value
      end

      context 'with the :citation action' do
        it 'also includes the show config' do
          expect(config.view_config(action_name: :citation)).to have_attributes config.show.to_h
        end
      end
    end

    context 'with a view' do
      it 'includes the configuration-level view parameters' do
        expect(config.view_config(:atom)).to have_attributes config.index.to_h.except(:partials)
        expect(config.view_config(:atom)).to have_attributes partials: [:document]
      end
    end
  end

  describe '#freeze' do
    it 'freezes the configuration' do
      config.freeze

      expect(config.a).to be_nil
      expect { config.a = '123' }.to raise_error(FrozenError)
      expect { config.view.a = '123' }.to raise_error(FrozenError)
    end
  end

  describe '.default_configuration' do
    it 'adds additional default configuration properties' do
      described_class.default_configuration do
        described_class.default_values[:a] = '123'
      end

      described_class.default_configuration do
        described_class.default_values[:b] = 'abc'
      end

      expect(described_class.default_values[:a]).to eq '123'
      expect(described_class.default_values[:b]).to eq 'abc'
    ensure
      # reset the default configuration
      described_class.default_values.delete(:a)
      described_class.default_values.delete(:b)

      described_class.default_configuration.delete_at(1)
      described_class.default_configuration.delete_at(2)
    end
  end
end
