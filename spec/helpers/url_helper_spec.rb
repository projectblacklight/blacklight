require 'spec_helper'

describe BlacklightUrlHelper do

  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.index.title_field = 'title_display'
      config.index.display_type_field = 'format'
    end
  end

  before do
    allow(helper).to receive(:search_action_path) do |*args|
      catalog_index_url *args
    end

    allow(helper).to receive_messages(blacklight_config: blacklight_config)
    allow(helper).to receive_messages(current_search_session: nil)
    allow(helper).to receive(:search_session).and_return({})
  end

  describe "url_for_document" do
    let(:controller_class) { ::CatalogController.new }
    let(:doc) { SolrDocument.new }

    before do
      allow(helper).to receive_messages(controller: controller_class)
      allow(helper).to receive_messages(controller_name: controller_class.controller_name)
      allow(helper).to receive_messages(params: {})
    end

    it "should be a polymorphic routing-ready object" do
      expect(helper.url_for_document(doc)).to eq doc
    end

    it "should allow for custom show routes" do
      helper.blacklight_config.show.route = { controller: 'catalog' }
      expect(helper.url_for_document(doc)).to eq({controller: 'catalog', action: :show, id: doc})
    end

    context "within bookmarks" do
      let(:controller_class) { ::BookmarksController.new }

      it "should use polymorphic routing" do
        expect(helper.url_for_document(doc)).to eq doc
      end
    end

    context "within an alternative catalog controller" do
      let(:controller_class) { ::AlternateController.new }
      before do
        helper.blacklight_config.show.route = { controller: :current }
        allow(helper).to receive(:params).and_return(controller: 'alternate')
      end
      it "should support the :current controller configuration" do
        expect(helper.url_for_document(doc)).to eq({controller: 'alternate', action: :show, id: doc})
      end
    end

    it "should be a polymorphic route if the solr document responds to #to_model with a non-SolrDocument" do
      some_model = double
      doc = SolrDocument.new
      allow(doc).to receive_messages(to_model: some_model)
      expect(helper.url_for_document(doc)).to eq doc
    end
  end

  describe "link_back_to_catalog" do
    let(:query_params)  {{:q => "query", :f => "facets", :controller=>'catalog'}}
    let(:bookmarks_query_params) {{ :controller=>'bookmarks'}}

    it "should build a link tag to catalog using session[:search] for query params" do
      allow(helper).to receive(:current_search_session).and_return double(:query_params => query_params)
      tag = helper.link_back_to_catalog
      expect(tag).to match /q=query/
      expect(tag).to match /f=facets/
      expect(tag).to_not match /page=/
      expect(tag).to_not match /per_page=/
    end

    it "should build a link tag to bookmarks using session[:search] for query params" do
      allow(helper).to receive(:current_search_session).and_return double(:query_params => bookmarks_query_params)
      tag = helper.link_back_to_catalog
      expect(tag).to match /Back to Bookmarks/
      expect(tag).to match /\/bookmarks/
    end

    context "with a search context" do

      it "should use the current search session counter and per page information to construct the appropriate pagination context" do
        allow(helper).to receive_messages(current_search_session: double(query_params: query_params))
        allow(helper).to receive_messages(search_session: { 'per_page' => 15, 'counter' => 31 })
        tag = helper.link_back_to_catalog
        expect(tag).to match /page=3/
        expect(tag).to match /per_page=15/
      end
      
      it "should omit per_page if the value is the same as the default" do
        allow(helper).to receive_messages(current_search_session: double(query_params: query_params))
        allow(helper).to receive_messages(search_session: { 'per_page' => 10, 'counter' => 31 })
        tag = helper.link_back_to_catalog
        expect(tag).to match /page=4/
        expect(tag).to_not match /per_page=/
      end
    end

    context "without current search context" do
      before do
        controller.request.assign_parameters(Rails.application.routes, 'catalog', 'show', id: '123')
        allow(helper).to receive_messages(current_search_session: nil)
      end

      subject { helper.link_back_to_catalog }

      it "should link to the catalog" do
        expect(subject).to eq '<a href="/catalog">Back to Search</a>'
      end
    end

    context "when an alternate scope is passed in" do
      let(:my_engine) { double("Engine") }

      it "should call url_for on the engine scope" do
        allow(helper).to receive(:current_search_session).and_return double(:query_params => query_params)
        expect(my_engine).to receive(:url_for).and_return(url_for(query_params))
        tag = helper.link_back_to_catalog(route_set: my_engine)
        expect(tag).to match /Back to Search/
        expect(tag).to match /q=query/
        expect(tag).to match /f=facets/
      end
    end
  end

  describe "link_to_query" do
    it "should build a link tag to catalog using query string (no other params)" do
      query = "brilliant"
      allow(helper).to receive_messages(params: {})
      tag = helper.link_to_query(query)
      expect(tag).to match /q=#{query}/
      expect(tag).to match />#{query}<\/a>/
    end
    it "should build a link tag to catalog using query string and other existing params" do
      query = "wonderful"
      allow(helper).to receive_messages(params: {:qt => "title_search", :per_page => "50"})
      tag = helper.link_to_query(query)
      expect(tag).to match /qt=title_search/
      expect(tag).to match /per_page=50/
    end
    it "should ignore existing :page param" do
      query = "yes"
      allow(helper).to receive_messages(params: {:page => "2", :qt => "author_search"})
      tag = helper.link_to_query(query)
      expect(tag).to match /qt=author_search/
      expect(tag).to_not match /page/
    end
    it "should be html_safe" do
      query = "brilliant"
      allow(helper).to receive_messages(params: {:page => "2", :qt => "author_search"})
      tag = helper.link_to_query(query)
      expect(tag).to be_html_safe
    end
  end

  describe "start_over_path" do
    it 'should be the catalog path with the current view type' do
      allow(blacklight_config).to receive(:view) { { list: nil, abc: nil} }
      allow(helper).to receive_messages(:blacklight_config => blacklight_config)
      expect(helper.start_over_path(:view => 'abc')).to eq catalog_index_url(:view => 'abc')
    end

    it 'should not include the current view type if it is the default' do
      allow(blacklight_config).to receive(:view) { { list: nil, asdf: nil} }
      allow(helper).to receive_messages(:blacklight_config => blacklight_config)
      expect(helper.start_over_path(:view => 'list')).to eq catalog_index_url
    end
  end

  describe "link_to_document" do
    it "should consist of the document title wrapped in a <a>" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document, :title_display)).to have_selector("a", :text => '654321', :count => 1)
    end

    it "should have the old deprecated behavior (second argument is a hash)" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      expect(Deprecation).to receive(:warn)
      expect(helper.link_to_document(@document, { :label => "title_display" })).to have_selector("a", :text => 'title_display', :count => 1)
    end

    it "should accept and return a string label" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document, "title_display")).to have_selector("a", :text => 'title_display', :count => 1)
    end

    it "should accept and return a Proc" do
      data = {'id'=>'123456','title_display'=>['654321'] }
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document, Proc.new { |doc, opts| doc[:id] + ": " + doc.first(:title_display) })).to have_selector("a", :text => '123456: 654321', :count => 1)
    end

    it "should return id when label is missing" do
      data = {'id'=>'123456'}
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document, :title_display)).to have_selector("a", :text => '123456', :count => 1)
    end

    it "should be html safe" do
      data = {'id'=>'123456'}
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document, :title_display)).to be_html_safe
    end

    it "should convert the counter parameter into a data- attribute" do
      data = {'id'=>'123456','title_display'=>['654321']}
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document, :title_display, counter: 5)).to match /\/catalog\/123456\/track\?counter=5/
    end

    it "should merge the data- attributes from the options with the counter params" do
      data = {'id'=>'123456','title_display'=>['654321']}
      @document = SolrDocument.new(data)
      link = helper.link_to_document @document, { data: { x: 1 }  }
      expect(link).to have_selector '[data-x]'
      expect(link).to have_selector '[data-context-href]'
    end

    it "passes on the title attribute to the link_to_with_data method" do
      @document = SolrDocument.new('id'=>'123456')
      expect(helper.link_to_document(@document, "Some crazy long label...", title: "Some crazy longer label")).to match(/title=\"Some crazy longer label\"/)
    end

    it "doesn't add an erroneous title attribute if one isn't provided" do
      @document = SolrDocument.new('id'=>'123456')
      expect(helper.link_to_document(@document, "Some crazy long label...")).to_not match(/title=/)
    end

    it "should  work with integer ids" do
      data = {'id'=> 123456 }
      @document = SolrDocument.new(data)
      expect(helper.link_to_document(@document)).to have_selector("a")
    end

  end

  describe "link_to_previous_search" do
    it "should link to the given search parameters" do
      params = {}
      allow(helper).to receive(:render_search_to_s).with(params).and_return "link text"
      expect(helper.link_to_previous_search({})).to eq helper.link_to("link text", helper.search_action_path)
    end
  end

  describe "#bookmarks_export_url" do
    it "should be the bookmark url with an encrypted user token" do
      allow(helper).to receive_messages(encrypt_user_id: 'xyz', current_or_guest_user: double(id: 123))
      url = helper.bookmarks_export_url(:html)
      expect(url).to eq helper.bookmarks_url(format: :html, encrypted_user_id: 'xyz')
    end
  end

  describe "#session_tracking_path" do
    let(:document) { SolrDocument.new(id: 1) }
    it "should determine the correct route for the document class" do
      expect(helper.session_tracking_path(document)).to eq helper.track_solr_document_path(document)
    end

    it "should pass through tracking parameters" do
      expect(helper.session_tracking_path(document, x: 1)).to eq helper.track_solr_document_path(document, x: 1)
    end
  end
end
