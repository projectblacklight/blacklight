require 'spec_helper'

describe BlacklightConfigurationHelper do
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:config_value) { double() }

  before :each do
    helper.stub(blacklight_config: blacklight_config)
  end

  describe "#index_fields" do
    it "should pass through the configuration" do
      blacklight_config.stub(index_fields: config_value)
      expect(helper.index_fields).to eq config_value
    end
  end

  describe "#sort_fields" do
    it "should convert the sort fields to select-ready values" do
      blacklight_config.stub(sort_fields: { 'a' => double(key: 'a', label: 'a'), 'b' => double(key: 'b', label: 'b'),  })
      expect(helper.sort_fields).to eq [['a', 'a'], ['b', 'b']]
    end
  end

  describe "#document_show_fields" do
    it "should pass through the configuration" do
      blacklight_config.stub(show_fields: config_value)
      expect(helper.document_show_fields).to eq config_value
    end
  end

  describe "#default_document_index_view_type" do
    it "should use the first view with default set to true" do
      blacklight_config.view.a
      blacklight_config.view.b
      blacklight_config.view.b.default = true
      expect(helper.default_document_index_view_type).to eq :b
    end
    
    it "should default to the first configured index view" do
      blacklight_config.stub(view: { a: true, b: true})
      expect(helper.default_document_index_view_type).to eq :a
    end
  end
  
  describe "#document_index_views" do
    before do
      blacklight_config.view.abc = false
      blacklight_config.view.def.if = false
      blacklight_config.view.xyz.unless = true
    end

    it "should filter views using :if/:unless configuration" do
      helper.document_index_views.should have_key :list
      helper.document_index_views.should_not have_key :abc
      helper.document_index_views.should_not have_key :def
      helper.document_index_views.should_not have_key :xyz
    end
  end

  describe "#has_alternative_views?" do
    subject { helper.has_alternative_views?}
    describe "with a single view defined" do
      it { should be_false }
    end

    describe "with multiple views defined" do
      before do
        blacklight_config.view.abc
        blacklight_config.view.xyz
      end

      it { should be_true }
    end
  end

  describe "#spell_check_max" do
    it "should pass through the configuration" do
      blacklight_config.stub(spell_max: config_value)
      expect(helper.spell_check_max).to eq config_value
    end
  end

  describe "#index_field_label" do
    let(:document) { double }
    it "should look up the label to display for the given document and field" do
      helper.stub(:index_fields).and_return({ "my_field" => double(label: "some label") })
      helper.should_receive(:solr_field_label).with("some label", :"blacklight.search.fields.index.my_field", :"blacklight.search.fields.my_field")
      helper.index_field_label document, "my_field"
    end
  end

  describe "#document_show_field_label" do
    let(:document) { double }
    it "should look up the label to display for the given document and field" do
      helper.stub(:document_show_fields).and_return({ "my_field" => double(label: "some label") })
      helper.should_receive(:solr_field_label).with("some label", :"blacklight.search.fields.show.my_field", :"blacklight.search.fields.my_field")
      helper.document_show_field_label document, "my_field"
    end
  end

  describe "#facet_field_label" do
    let(:document) { double }
    it "should look up the label to display for the given document and field" do
      blacklight_config.stub(:facet_fields).and_return({ "my_field" => double(label: "some label") })
      helper.should_receive(:solr_field_label).with("some label", :"blacklight.search.fields.facet.my_field", :"blacklight.search.fields.my_field")
      helper.facet_field_label "my_field"
    end
  end

  describe "#solr_field_label" do
    it "should look up the label as an i18n string" do
      helper.should_receive(:t).with(:some_key).and_return "my label"
      label = helper.solr_field_label :some_key

      expect(label).to eq "my label"
    end

    it "should pass the provided i18n keys to I18n.t" do
      helper.should_receive(:t).with(:key_a, default: [:key_b, "default text"])

      label = helper.solr_field_label "default text", :key_a, :key_b
    end
  end
  
  describe "#default_per_page" do
    it "should be the configured default per page" do
      helper.stub(blacklight_config: double(default_per_page: 42))
      expect(helper.default_per_page).to eq 42
    end
    
    it "should be the first per-page value if a default isn't set" do
      helper.stub(blacklight_config: double(default_per_page: nil, per_page: [11, 22]))
      expect(helper.default_per_page).to eq 11
    end
  end
  
  describe "#per_page_options_for_select" do
    it "should be the per-page values formatted as options_for_select" do
      helper.stub(blacklight_config: double(per_page: [11, 22, 33]))
      expect(helper.per_page_options_for_select).to include ["11<span class=\"sr-only\"> per page</span>", 11]
      expect(helper.per_page_options_for_select).to include ["22<span class=\"sr-only\"> per page</span>", 22]
      expect(helper.per_page_options_for_select).to include ["33<span class=\"sr-only\"> per page</span>", 33]
    end
  end
  
  describe "#should_render_field?" do
    let(:field_config) { double('field config', if: true, unless: false) }
    
    before do
      helper.stub(document_has_value?: true)
    end

    it "should be true" do
      expect(helper.should_render_field?(field_config)).to be_true
    end
    
    it "should be false if the :if condition is false" do
      field_config.stub(if: false)
      expect(helper.should_render_field?(field_config)).to be_false
    end
    
    it "should be false if the :unless condition is true" do
      field_config.stub(unless: true)
      expect(helper.should_render_field?(field_config)).to be_false
    end
  end
  
  describe "#evaluate_configuration_conditional" do
    it "should pass through regular values" do
      val = double
      expect(helper.evaluate_configuration_conditional(:if, val)).to eq val
    end

    it "should execute a helper method" do
      helper.stub(:my_helper => true)
      expect(helper.evaluate_configuration_conditional(:if, :my_helper)).to be_true
    end

    it "should call a helper to determine if it should render a field" do
      a = double
      helper.should_receive(:my_helper_with_an_arg).with(a).and_return(true)
      expect(helper.evaluate_configuration_conditional(:if, :my_helper_with_an_arg, a)).to be_true
    end

    it "should evaluate a Proc to determine if it should render a field" do
      one_arg_lambda = lambda { |context, a| true }
      two_arg_lambda = lambda { |context, a, b| true }
      expect(helper.evaluate_configuration_conditional(:if, one_arg_lambda, 1)).to be_true
      expect(helper.evaluate_configuration_conditional(:if, two_arg_lambda, 1, 2)).to be_true
    end
    
    context "evaluating an Array for an if statement" do
      it "should be true if all the results must be true" do
        helper.stub(my_helper: true, my_other_helper: true)
        expect(helper.evaluate_configuration_conditional(:if, [:my_helper, :my_other_helper])).to be_true
      end
      
      it "should be false if any of the results are false" do
        helper.stub(my_helper: true, my_other_helper: false)
        expect(helper.evaluate_configuration_conditional(:if, [:my_helper, :my_other_helper])).to be_false
      end  
    end
    
    context "evaluating an Array for an unless statement" do
      it "should be true if any of the results are true" do
        helper.stub(my_helper: true, my_other_helper: false)
        expect(helper.evaluate_configuration_conditional(:unless, [:my_helper, :my_other_helper])).to be_true
      end
      
      it "should be false if all of the results are false" do
        helper.stub(my_helper: false, my_other_helper: false)
        expect(helper.evaluate_configuration_conditional(:unless, [:my_helper, :my_other_helper])).to be_false
      end  
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

      helper.stub(blacklight_config: @config)
    end
    
    it "should return proper options_for_select arguments" do

      select_arguments = helper.search_field_options_for_select

      select_arguments.each do |(label, key)|
         config_hash = @config.search_fields[key]

         expect(label).to eq config_hash.label
         expect(key).to eq config_hash.key
      end    
    end

    it "should not include fields in select if :display_in_simple_search=>false" do
      select_arguments = helper.search_field_options_for_select

      expect(select_arguments).not_to include(["No Display", "no_display"])
    end
  end
end
