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
    allow(helper).to receive(:search_action_path) do |*args|
      catalog_index_url *args
    end
  end

  def current_search_session

  end

  describe "#application_name", :test => true do
    it "should use the Rails application config application_name if available" do
      allow(Rails.application).to receive(:config).and_return(double(application_name: "asdf"))
      expect(application_name).to eq "asdf"
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
      allow(helper).to receive(:params).and_return(render_params)
    end
    it "generates <link rel=alternate> tags" do

      response = render_link_rel_alternates(@document)

      tmp_value = Capybara.ignore_hidden_elements
      Capybara.ignore_hidden_elements = false
      @document.export_formats.each_pair do |format, spec|
        expect(response).to have_selector("link[href$='.#{ format  }']") do |matches|
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
    let(:config) do
      Blacklight::Configuration.new.configure do |config|
        config.index.title_field = 'title_display'
        config.index.display_type_field = 'format'
      end
    end

    let(:document) { SolrDocument.new('title_display' => "A Fake Document", 'id'=>'8') }

    before do
      config.add_show_tools_partial(:bookmark, partial: 'catalog/bookmark_control', if: :render_bookmarks_control?)
      config.add_results_document_tool(:bookmark, partial: 'catalog/bookmark_control', if: :render_bookmarks_control?)
      config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
      allow(helper).to receive(:blacklight_config).and_return(config)
      allow(helper).to receive(:has_user_authentication_provider?).and_return(true)
      allow(helper).to receive(:current_or_guest_user).and_return(User.new)
      allow(helper).to receive_messages(current_bookmarks: [])
    end

    describe "render_nav_actions" do
      it "should render partials" do
        buff = ''
        helper.render_nav_actions { |config, item| buff << "<foo>#{item}</foo>" }
        expect(buff).to have_selector "foo a#bookmarks_nav[href=\"/bookmarks\"]"
        expect(buff).to have_selector "foo a span[data-role='bookmark-counter']", text: '0'
      end
    end

    describe "render_index_doc_actions" do
      it "should render partials" do
        response = helper.render_index_doc_actions(document)
        expect(response).to have_selector(".bookmark_toggle")
      end

      it "should be nil if no partials are renderable" do
        allow(helper).to receive(:render_bookmarks_control?).and_return(false)
        expect(helper.render_index_doc_actions(document)).to be_blank
      end
    end

    describe "render_show_doc_actions" do
      it "should render partials" do
        response = helper.render_show_doc_actions(document)
        expect(response).to have_selector(".bookmark_toggle")
      end
    end
  end

  describe "#should_render_index_field?" do
    before do
      allow(helper).to receive_messages(should_render_field?: true, document_has_value?: true)
    end

    it "should be true" do
      expect(helper.should_render_index_field?(double, double)).to be true
    end
    
    it "should be false if the document doesn't have a value for the field" do
      allow(helper).to receive_messages(document_has_value?: false)
      expect(helper.should_render_index_field?(double, double)).to be false
      
    end
    
    it "should be false if the configuration has the field disabled" do
      allow(helper).to receive_messages(should_render_field?: false)
      expect(helper.should_render_index_field?(double, double)).to be false
    end
  end

  describe "#should_render_show_field?" do
    before do
      allow(helper).to receive_messages(should_render_field?: true, document_has_value?: true)
    end
    
    it "should be true" do
      expect(helper.should_render_show_field?(double, double)).to be true
    end
    
    it "should be false if the document doesn't have a value for the field" do
      allow(helper).to receive_messages(document_has_value?: false)
      expect(helper.should_render_show_field?(double, double)).to be false
      
    end
    
    it "should be false if the configuration has the field disabled" do
      allow(helper).to receive_messages(should_render_field?: false)
      expect(helper.should_render_show_field?(double, double)).to be false
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
      allow(helper).to receive(:blacklight_config).and_return(@config)
    end

    it "should check for an explicit value" do
      doc = double()
      expect(doc).to_not receive(:get).with('asdf', :sep => nil)
      value = helper.render_index_field_value :value => 'asdf', :document => doc, :field => 'asdf'
      expect(value).to eq 'asdf'
    end

    it "should check for a helper method to call" do
      doc = double()
      allow(doc).to receive(:get).with('asdf', :sep => nil)
      allow(helper).to receive(:render_asdf_index_field).and_return('custom asdf value')
      value = helper.render_index_field_value :document => doc, :field => 'asdf'
      expect(value).to eq 'custom asdf value'
    end

    it "should check for a link_to_search" do
      doc = double()
      allow(doc).to receive(:get).with('link_to_search_true', :sep => nil).and_return('x')
      value = helper.render_index_field_value :document => doc, :field => 'link_to_search_true'
      expect(value).to eq helper.link_to("x", helper.search_action_path(:f => { :link_to_search_true => ['x'] }))
    end

    it "should check for a link_to_search with a field name" do
      doc = double()
      allow(doc).to receive(:get).with('link_to_search_named', :sep => nil).and_return('x')
      value = helper.render_index_field_value :document => doc, :field => 'link_to_search_named'
      expect(value).to eq helper.link_to("x", helper.search_action_path(:f => { :some_field => ['x'] }))
    end

    it "should gracefully handle when no highlight field is available" do
      doc = double()
      expect(doc).to_not receive(:get)
      allow(doc).to receive(:has_highlight_field?).and_return(false)
      value = helper.render_index_field_value :document => doc, :field => 'highlight'
      expect(value).to be_blank
    end

    it "should check for a highlighted field" do
      doc = double()
      expect(doc).to_not receive(:get)
      allow(doc).to receive(:has_highlight_field?).and_return(true)
      allow(doc).to receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
      value = helper.render_index_field_value :document => doc, :field => 'highlight'
      expect(value).to eq '<em>highlight</em>'
    end

    it "should check the document field value" do
      doc = double()
      allow(doc).to receive(:get).with('qwer', :sep => nil).and_return('document qwer value')
      value = helper.render_index_field_value :document => doc, :field => 'qwer'
      expect(value).to eq 'document qwer value'
    end

    it "should work with index fields that aren't explicitly defined" do
      doc = double()
      allow(doc).to receive(:get).with('mnbv', :sep => nil).and_return('document mnbv value')
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

      allow(helper).to receive(:blacklight_config).and_return(@config)
    end

    it "should check for an explicit value" do
      doc = double()
      expect(doc).to_not receive(:get).with('asdf', :sep => nil)
      expect(helper).to_not receive(:render_asdf_document_show_field)
      value = helper.render_document_show_field_value :value => 'asdf', :document => doc, :field => 'asdf'
      expect(value).to eq 'asdf'
    end

    it "should check for a helper method to call" do
      doc = double()
      allow(doc).to receive(:get).with('asdf', :sep => nil)
      allow(helper).to receive(:render_asdf_document_show_field).and_return('custom asdf value')
      value = helper.render_document_show_field_value :document => doc, :field => 'asdf'
      expect(value).to eq 'custom asdf value'
    end

    it "should check for a link_to_search" do
      doc = double()
      allow(doc).to receive(:get).with('link_to_search_true', :sep => nil).and_return('x')
      value = helper.render_document_show_field_value :document => doc, :field => 'link_to_search_true'
      expect(value).to eq helper.link_to("x", helper.search_action_path(:f => { :link_to_search_true => ['x'] }))
    end

    it "should check for a link_to_search with a field name" do
      doc = double()
      allow(doc).to receive(:get).with('link_to_search_named', :sep => nil).and_return('x')
      value = helper.render_document_show_field_value :document => doc, :field => 'link_to_search_named'
      expect(value).to eq helper.link_to("x", helper.search_action_path(:f => { :some_field => ['x'] }))
    end

    it "should gracefully handle when no highlight field is available" do
      doc = double()
      expect(doc).to_not receive(:get)
      allow(doc).to receive(:has_highlight_field?).and_return(false)
      value = helper.render_document_show_field_value :document => doc, :field => 'highlight'
      expect(value).to be_blank
    end

    it "should check for a highlighted field" do
      doc = double()
      expect(doc).to_not receive(:get)
      allow(doc).to receive(:has_highlight_field?).and_return(true)
      allow(doc).to receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
      value = helper.render_document_show_field_value :document => doc, :field => 'highlight'
      expect(value).to eq '<em>highlight</em>'
    end


    it "should check the document field value" do
      doc = double()
      allow(doc).to receive(:get).with('qwer', :sep => nil).and_return('document qwer value')
      value = helper.render_document_show_field_value :document => doc, :field => 'qwer'
      expect(value).to eq 'document qwer value'
    end

    it "should work with show fields that aren't explicitly defined" do
      doc = double()
      allow(doc).to receive(:get).with('mnbv', :sep => nil).and_return('document mnbv value')
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
  
  describe "#document_has_value?" do
    it "should if the document has the field value" do
      doc = double()
      allow(doc).to receive(:has?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf')
      expect(helper.document_has_value?(doc, field_config)).to eq true
    end

    it "should if the document has a highlight field value" do
      doc = double()
      allow(doc).to receive(:has?).with('asdf').and_return(false)
      allow(doc).to receive(:has_highlight_field?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf', :highlight => true)
      expect(helper.document_has_value?(doc, field_config)).to eq true
    end

    it "should if the field has a model accessor" do
      doc = double()
      allow(doc).to receive(:has?).with('asdf').and_return(false)
      allow(doc).to receive(:has_highlight_field?).with('asdf').and_return(false)
      field_config = double(:field => 'asdf', :highlight => true, :accessor => true)
      expect(helper.document_has_value?(doc, field_config)).to eq true
    end
  end

  describe "render_grouped_response?" do
    it "should check if the response ivar contains grouped data" do
      assign(:response, double("SolrResponse", :grouped? => true))
      expect(helper.render_grouped_response?).to be true
    end


    it "should check if the response param contains grouped data" do
      response = double("SolrResponse", :grouped? => true)
      expect(helper.render_grouped_response?(response)).to be true
    end
  end

  describe "render_grouped_document_index" do

  end

  describe "render_field_value" do
    before do
      allow(Deprecation).to receive(:warn)
    end
    it "should join and html-safe values" do
      expect(helper.render_field_value(['a', 'b'])).to eq "a, b"
    end

    it "should join values using the field_value_separator" do
      allow(helper).to receive(:field_value_separator).and_return(" -- ")
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
      allow(helper).to receive_messages spell_check_max: 5
    end
    it "should not show suggestions if there are enough results" do
      response = double(total: 10)
      expect(helper.should_show_spellcheck_suggestions? response).to be false
    end

    it "should only show suggestions if there are very few results" do
      response = double(total: 4, spelling: double(words: [1]))
      expect(helper.should_show_spellcheck_suggestions? response).to be true
    end

    it "should show suggestions only if there are spelling suggestions available" do
      response = double(total: 4, spelling: double(words: []))
      expect(helper.should_show_spellcheck_suggestions? response).to be false
    end
  end
  
  describe "#render_document_partials" do
    let(:doc) { double }
    before do
      allow(helper).to receive_messages(document_partial_path_templates: [])
      allow(helper).to receive_messages(document_index_view_type: 'index_header')
    end
    
    it "should get the document format from document_partial_name" do
      allow(helper).to receive(:document_partial_name).with(doc, :xyz)
      helper.render_document_partial(doc, :xyz)    
    end
    
    context "with a 1-arg form of document_partial_name" do
      it "should only call the 1-arg form of the document_partial_name" do
        allow(helper).to receive(:method).with(:document_partial_name).and_return(double(arity: 1))
        allow(helper).to receive(:document_partial_name).with(doc)
        allow(Deprecation).to receive(:warn)
        helper.render_document_partial(doc, nil)
      end
    end
  end

  describe "#document_partial_name" do
    let(:blacklight_config) { Blacklight::Configuration.new }

    before do
      allow(helper).to receive_messages(blacklight_config: blacklight_config)
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
  describe "#type_field_to_partial_name" do
    let(:document) { double }
    context "with default value" do
      subject { helper.type_field_to_partial_name(document, 'default') }
      it { should eq 'default' } 
    end
    context "with spaces" do
      subject { helper.type_field_to_partial_name(document, 'one two three') }
      it { should eq 'one_two_three' } 
    end
    context "with hyphens" do
      subject { helper.type_field_to_partial_name(document, 'one-two-three') }
      it { should eq 'one_two_three' } 
    end
    context "an array" do
      subject { helper.type_field_to_partial_name(document, ['one', 'two', 'three']) }
      it { should eq 'one_two_three' } 
    end
  end
  
  describe "#opensearch_description_tag" do
    subject { helper.opensearch_description_tag 'title', 'href' }
    
    it "should have a search rel" do
      expect(subject).to have_selector "link[rel='search']", visible: false
    end
    
    it "should have the correct mime type" do
      expect(subject).to have_selector "link[type='application/opensearchdescription+xml']", visible: false
    end
    
    it "should have a title attribute" do
      expect(subject).to have_selector "link[title='title']", visible: false
    end
    
    it "should have an href attribute" do
      expect(subject).to have_selector "link[href='href']", visible: false
    end
  end
  
  describe "#render_document_index" do
    it "should render the document index with the current view type" do
      allow(helper).to receive_messages(document_index_view_type: :current_view)
      allow(helper).to receive(:render_document_index_with_view).with(:current_view, [], a: 1, b: 2)
      helper.render_document_index [], a: 1, b: 2
    end
  end
  
  describe "#render_document_index_with_view" do
    let(:obj1) { SolrDocument.new }

    before do
      allow(helper).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
      assign(:response, double("SolrResponse", grouped?: false, params: {}))
      allow(helper).to receive(:link_to_document).and_return('<a/>')
      allow(helper).to receive(:render_index_doc_actions).and_return('<div/>')
    end

    it "should ignore missing templates" do
      response = helper.render_document_index_with_view :view_type, [obj1, obj1]
      expect(response).to match /<div id="documents">/
    end
  end

  describe "#document_index_view_type" do
    it "should default to the default view" do
      allow(helper).to receive(:document_index_views).and_return(a: 1, b: 2)
      allow(helper).to receive(:default_document_index_view_type).and_return(:xyz)
      expect(helper.document_index_view_type).to eq :xyz
    end

    it "should use the query parameter" do
      allow(helper).to receive(:document_index_views).and_return(a: 1, b: 2)
      expect(helper.document_index_view_type(view: :a)).to eq :a
    end

    it "should use the default view if the requested view is not available" do
      allow(helper).to receive(:default_document_index_view_type).and_return(:xyz)
      allow(helper).to receive(:document_index_views).and_return(a: 1, b: 2)
      expect(helper.document_index_view_type(view: :c)).to eq :xyz
    end
    
    context "when they have a preferred view" do
      before do
        session[:preferred_view] = :b
      end

      context "and no view is specified" do
        it "should use the saved preference" do
          allow(helper).to receive(:document_index_views).and_return(a: 1, b: 2, c: 3)
          expect(helper.document_index_view_type).to eq :b
        end

        it "should use the default view if the preference is not available" do
          allow(helper).to receive(:document_index_views).and_return(a: 1)
          expect(helper.document_index_view_type).to eq :a
        end
      end

      context "and a view is specified" do
        it "should use the query parameter" do
          allow(helper).to receive(:document_index_views).and_return(a: 1, b: 2, c: 3)
          expect(helper.document_index_view_type(view: :c)).to eq :c
        end
      end
    end
  end

  describe "#presenter_class" do
    before do
      allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
    end

    let :blacklight_config do
      Blacklight::Configuration.new
    end

    let :presenter_class do
      double
    end

    it "should use the value defined in the blacklight configuration" do
      blacklight_config.document_presenter_class = presenter_class
      expect(helper.presenter_class).to eq presenter_class
    end

    it "should default to Blacklight::DocumentPresenter" do
      expect(helper.presenter_class).to eq Blacklight::DocumentPresenter
    end
  end
end
