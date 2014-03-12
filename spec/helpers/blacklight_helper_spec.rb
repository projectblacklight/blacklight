require 'spec_helper'

describe BlacklightHelper do
  include ERB::Util
  include BlacklightHelper
  include Devise::TestHelpers
  def blacklight_config
    @config ||= Blacklight::Configuration.new.configure do |config|
      config.index.title_field = 'title_display'
      config.index.display_type_field = 'format'
    end
  end

  before(:each) do
    helper.stub(:search_action_path) do |*args|
      catalog_index_url *args
    end
  end

  def current_search_session

  end

  describe "#application_name", :test => true do
    it "should use the Rails application config application_name if available" do
      Rails.application.config.stub(:application_name => 'asdf')
      Rails.application.config.should_receive(:respond_to?).with(:application_name).and_return(true)
      expect(application_name).to eq 'asdf'
    end
    it "should default to 'Blacklight'" do
      expect(application_name).to eq "Blacklight"
    end
  end

  describe "#render_page_title" do
    it "should look in content_for(:page_title)" do
      helper.content_for(:page_title) { "xyz" }
      expect(helper.render_page_title).to eq "xyz"
    end

    it "should look in the @page_title ivar" do
      assign(:page_title, "xyz")
      expect(helper.render_page_title).to eq "xyz"
    end

    it "should default to the application name" do
      expect(helper.render_page_title).to eq helper.application_name
    end
  end

  describe "render_link_rel_alternates" do
      class MockDocumentAppHelper
        include Blacklight::Solr::Document
      end
      module MockExtension
         def self.extended(document)
           document.will_export_as(:weird, "application/weird")
           document.will_export_as(:weirder, "application/weirder")
           document.will_export_as(:weird_dup, "application/weird")
         end
         def export_as_weird ; "weird" ; end
         def export_as_weirder ; "weirder" ; end
         def export_as_weird_dup ; "weird_dup" ; end
      end
      MockDocumentAppHelper.use_extension(MockExtension)
      def mock_document_app_helper_url *args
        solr_document_url(*args)
      end
    before(:each) do
      @doc_id = "MOCK_ID1"
      @document = MockDocumentAppHelper.new(:id => @doc_id)
      render_params = {:controller => "controller", :action => "action"}
      helper.stub(:params).and_return(render_params)
    end
    it "generates <link rel=alternate> tags" do

      response = render_link_rel_alternates(@document)

      tmp_value = Capybara.ignore_hidden_elements
      Capybara.ignore_hidden_elements = false
      @document.export_formats.each_pair do |format, spec|
        response.should have_selector("link[href$='.#{ format  }']") do |matches|
          expect(matches).to have(1).match
          tag = matches[0]
          expect(tag.attributes["rel"].value).to eq "alternate"
          expect(tag.attributes["title"].value).to eq format.to_s
          expect(tag.attributes["href"].value).to eq mock_document_app_helper_url(@document, :format =>format)
        end
      end
      Capybara.ignore_hidden_elements = tmp_value
    end
    it "respects :unique=>true" do
      response = render_link_rel_alternates(@document, :unique => true)
      tmp_value = Capybara.ignore_hidden_elements
      Capybara.ignore_hidden_elements = false
      expect(response).to have_selector("link[type='application/weird']", :count => 1)
      Capybara.ignore_hidden_elements = tmp_value
    end
    it "excludes formats from :exclude" do
      response = render_link_rel_alternates(@document, :exclude => [:weird_dup])

      tmp_value = Capybara.ignore_hidden_elements
      Capybara.ignore_hidden_elements = false
      expect(response).to_not have_selector("link[href$='.weird_dup']")
      Capybara.ignore_hidden_elements = tmp_value
    end

    it "should be html safe" do
      response = render_link_rel_alternates(@document)
      expect(response).to be_html_safe
    end
  end

  describe "with a config" do
    before do
      @config = Blacklight::Configuration.new.configure do |config|
        config.index.title_field = 'title_display'
        config.index.display_type_field = 'format'
      end

      @document = SolrDocument.new('title_display' => "A Fake Document", 'id'=>'8')
      helper.stub(:blacklight_config).and_return(@config)
      helper.stub(:has_user_authentication_provider?).and_return(true)
      helper.stub(:current_or_guest_user).and_return(User.new)
    end
    describe "render_index_doc_actions" do
      it "should render partials" do
        response = helper.render_index_doc_actions(@document)
        expect(response).to have_selector(".bookmark_toggle")
      end
    end
    describe "render_show_doc_actions" do
      it "should render partials" do
        response = helper.render_show_doc_actions(@document)
        expect(response).to have_selector(".bookmark_toggle")
      end
    end
  end

  describe "render_index_field_value" do
    before do
      @config = Blacklight::Configuration.new.configure do |config|
        config.add_index_field 'qwer'
        config.add_index_field 'asdf', :helper_method => :render_asdf_index_field
        config.add_index_field 'link_to_search_true', :link_to_search => true
        config.add_index_field 'link_to_search_named', :link_to_search => :some_field
        config.add_index_field 'highlight', :highlight => true
        config.add_index_field 'solr_doc_accessor', :accessor => true
        config.add_index_field 'explicit_accessor', :accessor => :solr_doc_accessor
        config.add_index_field 'explicit_accessor_with_arg', :accessor => :solr_doc_accessor_with_arg
      end
      helper.stub(:blacklight_config).and_return(@config)
    end

    it "should check for an explicit value" do
      doc = double()
      doc.should_not_receive(:get).with('asdf', :sep => nil)
      value = helper.render_index_field_value :value => 'asdf', :document => doc, :field => 'asdf'
      expect(value).to eq 'asdf'
    end

    it "should check for a helper method to call" do
      doc = double()
      doc.should_receive(:get).with('asdf', :sep => nil)
      helper.stub(:render_asdf_index_field).and_return('custom asdf value')
      value = helper.render_index_field_value :document => doc, :field => 'asdf'
      expect(value).to eq 'custom asdf value'
    end

    it "should check for a link_to_search" do
      doc = double()
      doc.should_receive(:get).with('link_to_search_true', :sep => nil).and_return('x')
      value = helper.render_index_field_value :document => doc, :field => 'link_to_search_true'
      expect(value).to eq helper.link_to("x", helper.search_action_path(:f => { :link_to_search_true => ['x'] }))
    end

    it "should check for a link_to_search with a field name" do
      doc = double()
      doc.should_receive(:get).with('link_to_search_named', :sep => nil).and_return('x')
      value = helper.render_index_field_value :document => doc, :field => 'link_to_search_named'
      expect(value).to eq helper.link_to("x", helper.search_action_path(:f => { :some_field => ['x'] }))
    end

    it "should gracefully handle when no highlight field is available" do
      doc = double()
      doc.should_not_receive(:get)
      doc.should_receive(:has_highlight_field?).and_return(false)
      value = helper.render_index_field_value :document => doc, :field => 'highlight'
      expect(value).to be_blank
    end

    it "should check for a highlighted field" do
      doc = double()
      doc.should_not_receive(:get)
      doc.should_receive(:has_highlight_field?).and_return(true)
      doc.should_receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
      value = helper.render_index_field_value :document => doc, :field => 'highlight'
      expect(value).to eq '<em>highlight</em>'
    end

    it "should check the document field value" do
      doc = double()
      doc.should_receive(:get).with('qwer', :sep => nil).and_return('document qwer value')
      value = helper.render_index_field_value :document => doc, :field => 'qwer'
      expect(value).to eq 'document qwer value'
    end

    it "should work with index fields that aren't explicitly defined" do
      doc = double()
      doc.should_receive(:get).with('mnbv', :sep => nil).and_return('document mnbv value')
      value = helper.render_index_field_value :document => doc, :field => 'mnbv'
      expect(value).to eq 'document mnbv value'
    end

    it "should call an accessor on the solr document" do
      doc = double(:solr_doc_accessor => "123")
      value = helper.render_index_field_value :document => doc, :field => 'solr_doc_accessor'
      expect(value).to eq "123"
    end

    it "should call an explicit accessor on the solr document" do
      doc = double(:solr_doc_accessor => "123")
      value = helper.render_index_field_value :document => doc, :field => 'explicit_accessor'
      expect(value).to eq "123"
    end

    it "should call an implicit accessor on the solr document" do
      doc = double()
      expect(doc).to receive(:solr_doc_accessor_with_arg).with('explicit_accessor_with_arg').and_return("123")
      value = helper.render_index_field_value :document => doc, :field => 'explicit_accessor_with_arg'
      expect(value).to eq "123"
    end
  end

  describe "render_document_show_field_value" do
    before do
      @config = Blacklight::Configuration.new.configure do |config|
        config.add_show_field 'qwer'
        config.add_show_field 'asdf', :helper_method => :render_asdf_document_show_field
        config.add_show_field 'link_to_search_true', :link_to_search => true
        config.add_show_field 'link_to_search_named', :link_to_search => :some_field
        config.add_show_field 'highlight', :highlight => true
        config.add_show_field 'solr_doc_accessor', :accessor => true
        config.add_show_field 'explicit_accessor', :accessor => :solr_doc_accessor
        config.add_show_field 'explicit_array_accessor', :accessor => [:solr_doc_accessor, :some_method]
        config.add_show_field 'explicit_accessor_with_arg', :accessor => :solr_doc_accessor_with_arg
      end

      helper.stub(:blacklight_config).and_return(@config)
    end

    it "should check for an explicit value" do
      doc = double()
      doc.should_not_receive(:get).with('asdf', :sep => nil)
      helper.should_not_receive(:render_asdf_document_show_field)
      value = helper.render_document_show_field_value :value => 'asdf', :document => doc, :field => 'asdf'
      expect(value).to eq 'asdf'
    end

    it "should check for a helper method to call" do
      doc = double()
      doc.should_receive(:get).with('asdf', :sep => nil)
      helper.stub(:render_asdf_document_show_field).and_return('custom asdf value')
      value = helper.render_document_show_field_value :document => doc, :field => 'asdf'
      expect(value).to eq 'custom asdf value'
    end

    it "should check for a link_to_search" do
      doc = double()
      doc.should_receive(:get).with('link_to_search_true', :sep => nil).and_return('x')
      value = helper.render_document_show_field_value :document => doc, :field => 'link_to_search_true'
      expect(value).to eq helper.link_to("x", helper.search_action_path(:f => { :link_to_search_true => ['x'] }))
    end

    it "should check for a link_to_search with a field name" do
      doc = double()
      doc.should_receive(:get).with('link_to_search_named', :sep => nil).and_return('x')
      value = helper.render_document_show_field_value :document => doc, :field => 'link_to_search_named'
      expect(value).to eq helper.link_to("x", helper.search_action_path(:f => { :some_field => ['x'] }))
    end

    it "should gracefully handle when no highlight field is available" do
      doc = double()
      doc.should_not_receive(:get)
      doc.should_receive(:has_highlight_field?).and_return(false)
      value = helper.render_document_show_field_value :document => doc, :field => 'highlight'
      expect(value).to be_blank
    end

    it "should check for a highlighted field" do
      doc = double()
      doc.should_not_receive(:get)
      doc.should_receive(:has_highlight_field?).and_return(true)
      doc.should_receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
      value = helper.render_document_show_field_value :document => doc, :field => 'highlight'
      expect(value).to eq '<em>highlight</em>'
    end


    it "should check the document field value" do
      doc = double()
      doc.should_receive(:get).with('qwer', :sep => nil).and_return('document qwer value')
      value = helper.render_document_show_field_value :document => doc, :field => 'qwer'
      expect(value).to eq 'document qwer value'
    end

    it "should work with show fields that aren't explicitly defined" do
      doc = double()
      doc.should_receive(:get).with('mnbv', :sep => nil).and_return('document mnbv value')
      value = helper.render_document_show_field_value :document => doc, :field => 'mnbv'
      expect(value).to eq 'document mnbv value'
    end

    it "should call an accessor on the solr document" do
      doc = double(:solr_doc_accessor => "123")
      value = helper.render_document_show_field_value :document => doc, :field => 'solr_doc_accessor'
      expect(value).to eq "123"
    end

    it "should call an explicit accessor on the solr document" do
      doc = double(:solr_doc_accessor => "123")
      value = helper.render_document_show_field_value :document => doc, :field => 'explicit_accessor'
      expect(value).to eq "123"
    end

    it "should call an explicit array-style accessor on the solr document" do
      doc = double(:solr_doc_accessor => double(:some_method => "123"))
      value = helper.render_document_show_field_value :document => doc, :field => 'explicit_array_accessor'
      expect(value).to eq "123"
    end

    it "should call an accessor on the solr document with the field as an argument" do
      doc = double()
      expect(doc).to receive(:solr_doc_accessor_with_arg).with('explicit_accessor_with_arg').and_return("123")
      value = helper.render_document_show_field_value :document => doc, :field => 'explicit_accessor_with_arg'
      expect(value).to eq "123"
    end
  end

  describe "#should_render_index_field?" do
    it "should if the document has the field value" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf')
      helper.should_render_index_field?(doc, field_config).should == true
    end

    it "should if the document has a highlight field value" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(false)
      doc.stub(:has_highlight_field?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf', :highlight => true)
      helper.should_render_index_field?(doc, field_config).should == true
    end

    it "should if the field has a model accessor" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(false)
      doc.stub(:has_highlight_field?).with('asdf').and_return(false)
      field_config = double(:field => 'asdf', :highlight => true, :accessor => true)
      helper.should_render_index_field?(doc, field_config).should == true
    end
  end

  describe "#should_render_show_field?" do
    it "should if the document has the field value" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf')
      expect(helper.should_render_show_field?(doc, field_config)).to be_true
    end

    it "should if the document has a highlight field value" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(false)
      doc.stub(:has_highlight_field?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf', :highlight => true)
      expect(helper.should_render_show_field?(doc, field_config)).to be_true
    end

    it "should if the field has a model accessor" do
      doc = double()
      doc.stub(:has?).with('asdf').and_return(false)
      doc.stub(:has_highlight_field?).with('asdf').and_return(false)
      field_config = double(:field => 'asdf', :highlight => true, :accessor => true)
      helper.should_render_show_field?(doc, field_config).should == true
    end
  end

  describe "render_grouped_response?" do
    it "should check if the response ivar contains grouped data" do
      assign(:response, double("SolrResponse", :grouped? => true))
      expect(helper.render_grouped_response?).to be_true
    end


    it "should check if the response param contains grouped data" do
      response = double("SolrResponse", :grouped? => true)
      expect(helper.render_grouped_response?(response)).to be_true
    end
  end

  describe "render_grouped_document_index" do

  end

  describe "render_field_value" do
    before do
      Deprecation.stub(:warn)
    end
    it "should join and html-safe values" do
      expect(helper.render_field_value(['a', 'b'])).to eq "a, b"
    end

    it "should join values using the field_value_separator" do
      helper.stub(:field_value_separator).and_return(" -- ")
      expect(helper.render_field_value(['a', 'b'])).to eq "a -- b"
    end

    it "should use the separator from the Blacklight field configuration by default" do
      expect(helper.render_field_value(['c', 'd'], double(:separator => '; ', :itemprop => nil))).to eq "c; d"
    end

    it "should include schema.org itemprop attributes" do
      expect(helper.render_field_value('a', double(:separator => nil, :itemprop => 'some-prop'))).to have_selector("span[@itemprop='some-prop']", :text => "a") 
    end
  end

  describe "should_show_spellcheck_suggestions?" do
    before :each do
      helper.stub spell_check_max: 5
    end
    it "should not show suggestions if there are enough results" do
      response = double(total: 10)
      expect(helper.should_show_spellcheck_suggestions? response).to be_false
    end

    it "should only show suggestions if there are very few results" do
      response = double(total: 4, spelling: double(words: [1]))
      expect(helper.should_show_spellcheck_suggestions? response).to be_true
    end

    it "should show suggestions only if there are spelling suggestions available" do
      response = double(total: 4, spelling: double(words: []))
      expect(helper.should_show_spellcheck_suggestions? response).to be_false
    end
  end
  
  describe "#render_document_partials" do
    let(:doc) { double }
    before do
      helper.stub(document_partial_path_templates: [])
    end
    
    it "should get the document format from document_partial_name" do
      helper.should_receive(:document_partial_name).with(doc, :xyz)
      helper.render_document_partial(doc, :xyz)    
    end
    
    context "with a 1-arg form of document_partial_name" do
      it "should only call the 1-arg form of the document_partial_name" do
        helper.should_receive(:method).with(:document_partial_name).and_return(double(arity: 1))
        helper.should_receive(:document_partial_name).with(doc)
        Deprecation.should_receive(:warn)
        helper.render_document_partial(doc, nil)
      end
    end
  end

  describe "#document_partial_name" do
    let(:blacklight_config) { Blacklight::Configuration.new }

    before do
      helper.stub(blacklight_config: blacklight_config)
    end

    context "with a solr document with empty fields" do
      let(:document) { SolrDocument.new }
      it "should be the default value" do
        expect(helper.document_partial_name(document)).to eq 'default'
      end
    end

    context "with a solr document with the display type field set" do
      let(:document) { SolrDocument.new 'my_field' => 'xyz'}

      before do
        blacklight_config.show.display_type_field = 'my_field'
      end

      it "should use the value in the configured display type field" do
        expect(helper.document_partial_name(document)).to eq 'xyz'
      end

      it "should use the value in the configured display type field if the action-specific field is empty" do
        expect(helper.document_partial_name(document, :some_action)).to eq 'xyz'
      end
    end

    context "with a solr doucment with an action-specific field set" do

      let(:document) { SolrDocument.new 'my_field' => 'xyz', 'other_field' => 'abc' }

      before do
        blacklight_config.show.media_display_type_field = 'my_field'
        blacklight_config.show.metadata_display_type_field = 'other_field'
      end

      it "should use the value in the action-specific fields" do
        expect(helper.document_partial_name(document, :media)).to eq 'xyz'
        expect(helper.document_partial_name(document, :metadata)).to eq 'abc'
      end

    end
  end
end
