# frozen_string_literal: true

RSpec.describe Blacklight::ConfigurationHelperBehavior do
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:config_value) { double() }

  before :each do
    allow(helper).to receive_messages(blacklight_config: blacklight_config)
  end

  describe "#index_fields" do
    it "passes through the configuration" do
      allow(blacklight_config).to receive_messages(index_fields: config_value)
      expect(helper.index_fields).to eq config_value
    end
  end

  describe "#sort_fields" do
    it "converts the sort fields to select-ready values" do
      allow(blacklight_config).to receive_messages(sort_fields: { 'a' => double(key: 'a', display_label: 'a'), 'b' => double(key: 'b', display_label: 'b'), c: double(key: 'c', if: false, display_label: nil)  })
      expect(helper.sort_fields).to eq [['a', 'a'], ['b', 'b']]
    end
  end

  describe "#active_sort_fields" do
    it "restricts the configured sort fields to only those that should be displayed" do
      allow(blacklight_config).to receive_messages(sort_fields: { a: double(if: false, unless: false), b: double(if:true, unless: true) })
      expect(helper.active_sort_fields).to be_empty
    end
  end

  describe "#document_show_fields" do
    it "passes through the configuration" do
      allow(blacklight_config).to receive_messages(show_fields: config_value)
      expect(helper.document_show_fields).to eq config_value
    end
  end

  describe "#default_document_index_view_type" do
    it "uses the first view with default set to true" do
      blacklight_config.view.a
      blacklight_config.view.b
      blacklight_config.view.b.default = true
      expect(helper.default_document_index_view_type).to eq :b
    end
    
    it "defaults to the first configured index view" do
      allow(blacklight_config).to receive_messages(view: { a: true, b: true})
      expect(helper.default_document_index_view_type).to eq :a
    end
  end
  
  describe "#document_index_views" do
    before do
      blacklight_config.view.abc = false
      blacklight_config.view.def.if = false
      blacklight_config.view.xyz.unless = true
    end

    it "filters views using :if/:unless configuration" do
      expect(helper.document_index_views).to have_key :list
      expect(helper.document_index_views).to_not have_key :abc
      expect(helper.document_index_views).to_not have_key :def
      expect(helper.document_index_views).to_not have_key :xyz
    end
  end

  describe '#document_index_view_controls' do
    before do
      blacklight_config.view.a
      blacklight_config.view.b.display_control = false
    end

    it "filters index views to those set to display controls" do
      expect(helper.document_index_view_controls).to have_key :a
      expect(helper.document_index_view_controls).not_to have_key :b
    end
  end

  describe "#has_alternative_views?" do
    before do
      blacklight_config.view.clear
    end

    subject { helper.has_alternative_views?}

    describe "with a single view defined" do
      it { should be false }
    end

    describe "with multiple views defined" do
      before do
        blacklight_config.view.abc
        blacklight_config.view.xyz
      end

      it { should be true }
    end
  end

  describe "#spell_check_max" do
    it "passes through the configuration" do
      allow(blacklight_config).to receive_messages(spell_max: config_value)
      expect(helper.spell_check_max).to eq config_value
    end
  end

  describe "#document_show_link_field" do
    let(:document) { SolrDocument.new id: 123, a: 1, b: 2, c: 3 }

    it "allows single values" do
      blacklight_config.index.title_field = :a
      f = helper.document_show_link_field document
      expect(f).to eq :a
    end
    
    it "retrieves the first field with data" do
      blacklight_config.index.title_field = [:zzz, :b]
      f = helper.document_show_link_field document
      expect(f).to eq :b
    end

    it "fallbacks on the id" do
      blacklight_config.index.title_field = [:zzz, :yyy]
      f = helper.document_show_link_field document
      expect(f).to eq 123
    end
  end

  describe "#view_label" do
    it "looks up the label to display for the view" do
      allow(blacklight_config).to receive(:view).and_return({ "my_view" => double(label: "some label", title: nil) })
      allow(helper).to receive(:field_label).with(:"blacklight.search.view_title.my_view", :"blacklight.search.view.my_view", "some label", nil, "My view")

      helper.view_label "my_view"
    end
  end

  describe "#field_label" do
    it "looks up the label as an i18n string" do
      allow(helper).to receive(:t).with(:some_key, default: []).and_return "my label"
      label = helper.field_label :some_key

      expect(label).to eq "my label"
    end

    it "passes the provided i18n keys to I18n.t" do
      allow(helper).to receive(:t).with(:key_a, default: [:key_b, "default text"])

      label = helper.field_label :key_a, :key_b, "default text"
    end

    it "compacts nil keys (fixes rails/rails#19419)" do
      allow(helper).to receive(:t).with(:key_a, default: [:key_b])

      label = helper.field_label :key_a, nil, :key_b

    end
  end
  
  describe "#default_per_page" do
    it "is the configured default per page" do
      allow(helper).to receive_messages(blacklight_config: double(default_per_page: 42))
      expect(helper.default_per_page).to eq 42
    end
    
    it "is the first per-page value if a default isn't set" do
      allow(helper).to receive_messages(blacklight_config: double(default_per_page: nil, per_page: [11, 22]))
      expect(helper.default_per_page).to eq 11
    end
  end
  
  describe "#default_sort_field" do
    it "is the configured default field" do
      allow(helper).to receive_messages(blacklight_config: double(sort_fields: { a: double(default: nil), b: double(key: 'b', default: true) }))
      expect(helper.default_sort_field.key).to eq 'b'
    end
    
    it "is the first per-page value if a default isn't set" do
      allow(helper).to receive_messages(blacklight_config: double(sort_fields: { a: double(key: 'a', default: nil), b: double(key: 'b', default: nil) }))
      expect(helper.default_sort_field.key).to eq 'a'
    end
  end
  
  describe "#per_page_options_for_select" do
    it "is the per-page values formatted as options_for_select" do
      allow(helper).to receive_messages(blacklight_config: double(per_page: [11, 22, 33]))
      expect(helper.per_page_options_for_select).to include ["11<span class=\"sr-only\"> per page</span>", 11]
      expect(helper.per_page_options_for_select).to include ["22<span class=\"sr-only\"> per page</span>", 22]
      expect(helper.per_page_options_for_select).to include ["33<span class=\"sr-only\"> per page</span>", 33]
    end
  end
  
  describe "#should_render_field?" do
    let(:field_config) { double('field config', if: true, unless: false) }
    
    before do
      allow(helper).to receive_messages(document_has_value?: true)
    end

    it "is true" do
      expect(helper.should_render_field?(field_config)).to be true
    end
    
    it "is false if the :if condition is false" do
      allow(field_config).to receive_messages(if: false)
      expect(helper.should_render_field?(field_config)).to be false
    end
    
    it "is false if the :unless condition is true" do
      allow(field_config).to receive_messages(unless: true)
      expect(helper.should_render_field?(field_config)).to be false
    end
  end

  describe "#search_field_options_for_select" do
    
    before do
    
      @config = Blacklight::Configuration.new do |config|
        config.default_solr_params = { :qt => 'search' }
        
        config.add_search_field 'all_fields', :label => 'All Fields'
        config.add_search_field 'title', :qt => 'title_search'
        config.add_search_field 'author', :qt => 'author_search'
        config.add_search_field 'subject', :qt => 'subject_search'
        config.add_search_field 'no_display', :qt => 'something', :include_in_simple_select => false
      end

      allow(helper).to receive_messages(blacklight_config: @config)
    end
    
    it "returns proper options_for_select arguments" do

      select_arguments = helper.search_field_options_for_select

      select_arguments.each do |(label, key)|
         config_hash = @config.search_fields[key]

         expect(label).to eq config_hash.label
         expect(key).to eq config_hash.key
      end    
    end

    it "does not include fields in select if :display_in_simple_search=>false" do
      select_arguments = helper.search_field_options_for_select

      expect(select_arguments).not_to include(["No Display", "no_display"])
    end
  end
end
