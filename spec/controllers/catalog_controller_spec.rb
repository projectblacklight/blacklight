# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'marc'

describe CatalogController do
  include Devise::TestHelpers
  # INDEX ACTION
  describe "index action" do
    before(:each) do
      @user_query = 'history'  # query that will get results
      @no_docs_query = 'sadfdsafasdfsadfsadfsadf' # query for no results
      @facet_query = {"format" => 'Book'}
    end
    
    # in rails3, the assigns method within ActionDispathc::TestProcess 
    # kindly converts anything that desends from hash to a hash_With_indifferent_access
    # which means that our solr resposne object gets replaced if we call
    # assigns(:response) - so we can't do that anymore.
    def assigns_response
      @controller.instance_variable_get("@response")
    end
    
    describe "with format :html" do
      it "should have no search history if no search criteria" do
        expect(controller).to receive(:get_search_results) 
        session[:history] = []
        get :index
        expect(session[:history].length).to eq(0)
      end

      # check each user manipulated parameter
      it "should have docs and facets for query with results", :integration => true do
        get :index, :q => @user_query
        expect(assigns_response.docs.size).to be > 1
        assert_facets_have_values(assigns_response.facets)
      end
      it "should have docs and facets for existing facet value", :integration => true do
        get :index, :f => @facet_query
        expect(assigns_response.docs.size).to be > 1
        assert_facets_have_values(assigns_response.facets)
      end
      it "should have docs and facets for non-default results per page", :integration => true do
        num_per_page = 7
        get :index, :per_page => num_per_page
        expect(assigns_response.docs.size).to eq(num_per_page)
        assert_facets_have_values(assigns_response.facets)
      end

      it "should have docs and facets for second page", :integration => true do
        page = 2
        get :index, :page => page
        expect(assigns_response.docs.size).to be > 1
        expect(assigns_response.params[:start].to_i).to eq((page-1) * @controller.blacklight_config[:default_solr_params][:rows])
        assert_facets_have_values(assigns_response.facets)
      end

      it "should have no docs or facet values for query without results", :integration => true do
        get :index, :q => @no_docs_query

        expect(assigns_response.docs.size).to eq(0)
        assigns_response.facets.each do |facet|
          expect(facet.items.size).to eq(0)
        end
      end

      it "should have a spelling suggestion for an appropriately poor query", :integration => true do
        get :index, :q => 'boo'
        expect(assigns_response.spelling.words).not_to be_nil
      end

      describe "session" do
        before do
          allow(controller).to receive(:get_search_results) 
        end
        it "should include :search key with hash" do
          get :index
          expect(session[:search]).not_to be_nil
          expect(session[:search]).to be_kind_of(Hash)
        end
        it "should include search hash with key :q" do
          get :index, :q => @user_query
          expect(session[:search]).not_to be_nil
          expect(session[:search].keys).to include('id')
          
          search = Search.find(session[:search]['id'])
          expect(search.query_params['q']).to eq @user_query
        end
      end

      # check with no user manipulation
      describe "for default query" do
        it "should get documents when no query", :integration => true do
          get :index
          expect(assigns_response.docs.size).to be > 1
        end
        it "should get facets when no query", :integration => true do
          get :index
          assert_facets_have_values(assigns_response.facets)
        end
      end

      it "should render index.html.erb" do
        allow(controller).to receive(:get_search_results)
        get :index
        expect(response).to render_template(:index)
      end

      # NOTE: status code is always 200 in isolation mode ...
      it "HTTP status code for GET should be 200", :integration => true do
        get :index
        expect(response).to be_success
      end
    end

    describe "with format :rss" do
      it "should get the feed", :integration => true do
        get :index, :format => 'rss'
        expect(response).to be_success
      end
    end

    describe "with format :json" do
      before do
        get :index, :format => 'json'
        expect(response).to be_success
      end
      let(:json) { JSON.parse(response.body)['response'] }
      let(:pages) { json["pages"] }
      let(:docs) { json["docs"] }
      let(:facets) { json["facets"] }

      it "should get the pages" do
        expect(pages["total_count"]).to eq(30) 
        expect(pages["current_page"]).to eq(1)
        expect(pages["total_pages"]).to eq(3)
      end

      it "should get the documents" do
        expect(docs.size).to eq(10)
        expect(docs.first.keys).to match_array(["published_display", "author_display", "lc_callnum_display", "pub_date", "subtitle_display", "format", "material_type_display", "title_display", "id", "subject_topic_facet", "language_facet", "score"])
      end

      it "should get the facets" do
        expect(facets.length).to eq(9)
        expect(facets.first).to eq({"name"=>"format", "label" => "Format", "items"=>[{"value"=>"Book", "hits"=>30, "label"=>"Book"}]})
      end

      describe "facets" do
        let(:query_facet_items) { facets.last['items'] }
        let(:regular_facet_items) { facets.first['items'] }
        it "should have items with labels and values" do
          expect(query_facet_items.first['label']).to eq('within 10 Years')
          expect(query_facet_items.first['value']).to eq('years_10')
          expect(regular_facet_items.first['label']).to eq("Book")
          expect(regular_facet_items.first['value']).to eq("Book")
        end
      end
    end

  end # describe index action

  describe "update action" do
    doc_id = '2007020969'

    it "should set counter value into session[:search]" do
      put :update, :id => doc_id, :counter => 3
      expect(session[:search]['counter']).to eq("3")
    end

    it "should redirect to show action for doc id" do
      put :update, :id => doc_id, :counter => 3
      assert_redirected_to(catalog_path(doc_id))
    end
  end

  # SHOW ACTION
  describe "show action" do

    doc_id = '2007020969'

    describe "with format :html" do
      it "should get document", :integration => true do
        get :show, :id => doc_id
        expect(assigns[:document]).not_to be_nil
      end
    end

    describe "with format :json" do
      it "should get the feed" do
        get :show, id: doc_id, format: 'json'
        expect(response).to be_success
        json = JSON.parse response.body
        expect(json["response"]["document"].keys).to match_array(["author_t", "opensearch_display", "marc_display", "published_display", "author_display", "lc_callnum_display", "title_t", "pub_date", "pub_date_sort", "subtitle_display", "format", "url_suppl_display", "material_type_display", "title_display", "subject_addl_t", "subject_t", "isbn_t", "id", "title_addl_t", "subject_geo_facet", "subject_topic_facet", "author_addl_t", "language_facet", "subtitle_t", "timestamp"])
      end
    end
    
    describe "previous/next documents" do
      before do
        @mock_response = double()
        @mock_document = double()
        allow(@mock_document).to receive_messages(:export_formats => {})
        allow(controller).to receive_messages(:get_solr_response_for_doc_id => [@mock_response, @mock_document], 
                        :get_previous_and_next_documents_for_search => [double(:total => 5), [double("a"), @mock_document, double("b")]])

        current_search = Search.create(:query_params => { :q => ""})
        allow(controller).to receive_messages(:current_search_session => current_search)

        @search_session = { :id => current_search.id }
      end
    it "should set previous document if counter present in session" do
      session[:search] = @search_session.merge('counter' => 2)
      get :show, :id => doc_id
      expect(assigns[:previous_document]).not_to be_nil
    end
    it "should not set previous or next document if session is blank" do
      get :show, :id => doc_id
      expect(assigns[:previous_document]).to be_nil
      expect(assigns[:next_document]).to be_nil
    end
    it "should not set previous or next document if session[:search]['counter'] is nil" do
      session[:search] = {}
      get :show, :id => doc_id
      expect(assigns[:previous_document]).to be_nil
      expect(assigns[:next_document]).to be_nil
    end
    it "should set next document if counter present in session" do
      session[:search] = @search_session.merge('counter' => 2)
      get :show, :id => doc_id
      expect(assigns[:next_document]).not_to be_nil
    end
    end

    # NOTE: status code is always 200 in isolation mode ...
    it "HTTP status code for GET should be 200", :integration => true do
      get :show, :id => doc_id
      expect(response).to be_success
    end
    it "should render show.html.erb" do
      @mock_response = double()
      @mock_document = double()
      allow(@mock_document).to receive_messages(:export_formats => {})
      allow(controller).to receive_messages(:get_solr_response_for_doc_id => [@mock_response, @mock_document], 
                      :get_single_doc_via_search => @mock_document)
      get :show, :id => doc_id
      expect(response).to render_template(:show)
    end

    describe "@document" do
      before do
        @mock_response = double()
        allow(@mock_response).to receive_messages(:docs => [{ :id => 'my_fake_doc' }])
        @mock_document = double()
        allow(controller).to receive_messages(:find => @mock_response, 
                        :get_single_doc_via_search => @mock_document)
      end
      before(:each) do
        get :show, :id => doc_id
        @document = assigns[:document]
      end
      it "should be a SolrDocument" do
        expect(@document).to be_instance_of(SolrDocument)
      end
    end
    
    describe "with dynamic export formats" do
      render_views
      module FakeExtension
        def self.extended(document)
          document.will_export_as(:mock, "application/mock")
        end
        
        def export_as_mock
          "mock_export"
        end
      end
      before do
        @mock_response = double()
        allow(@mock_response).to receive_messages(:docs => [{ :id => 'my_fake_doc' }])
        @mock_document = double()
        allow(controller).to receive_messages(:find => @mock_response, 
                        :get_single_doc_via_search => @mock_document)

        allow(controller).to receive_messages(:find => @mock_response, 
                        :get_single_doc_via_search => @mock_document)
      end

       before(:each) do

        # Rails3 needs this to propertly setup a new mime type and
        # render the results. 
        ActionController.add_renderer :double do |template, options|
          send_data "mock_export", :type => Mime::MOCK
        end
        Mime::Type.register "application/mock", :mock
        
        SolrDocument.use_extension(FakeExtension)
      end
      
      it "should respond to an extension-registered format properly" do
        get :show, :id => doc_id, :format => "mock" # This no longer works: :format => "mock"
        expect(response).to be_success
        expect(response.body).to match(/mock_export/)
      end
      

      after(:each) do
        # remove the fake extension
        SolrDocument.registered_extensions.pop
      end
    end # dynamic export formats

  end # describe show action

  describe "opensearch" do
    before do
      @mock_response = double()
      @mock_document = double()
      allow(@mock_response).to receive_messages(:docs => [{ :id => 'my_fake_doc' }, { :id => 'my_other_doc'}])
      @mock_document = double()
      allow(controller).to receive_messages(:find => @mock_response, 
                      :get_single_doc_via_search => @mock_document)
    end
    it "should return an opensearch description" do
      get :opensearch, :format => 'xml'
      expect(response).to be_success
    end
    it "should return valid JSON" do
      get :opensearch,:format => 'json', :q => "a"
      expect(response).to be_success
    end
  end
#=end
  describe "email/sms" do
    doc_id = '2007020969'
      before do
        @mock_response = double()
        @mock_document = double()
        allow(@mock_response).to receive_messages(:docs => [{ :id => 'my_fake_doc' }, { :id => 'my_other_doc'}])
        @mock_document = double()
        allow(controller).to receive_messages(:find => @mock_response, 
                        :get_single_doc_via_search => @mock_document)
      end
    before(:each) do
      request.env["HTTP_REFERER"] = "/catalog/#{doc_id}"
      SolrDocument.use_extension( Blacklight::Solr::Document::Email )
      SolrDocument.use_extension( Blacklight::Solr::Document::Sms )
    end
    describe "email" do
      it "should give error if no TO paramater" do
        post :email, :id => doc_id
        expect(request.flash[:error]).to eq("You must enter a recipient in order to send this message")
      end
      it "should give an error if the email address is not valid" do
        post :email, :id => doc_id, :to => 'test_bad_email'
        expect(request.flash[:error]).to eq("You must enter a valid email address")
      end
      it "should not give error if no Message paramater is set" do
        post :email, :id => doc_id, :to => 'test_email@projectblacklight.org'
        expect(request.flash[:error]).to be_nil
      end
      it "should redirect back to the record upon success" do
        mock_mailer = double
        expect(mock_mailer).to receive(:deliver)
        expect(RecordMailer).to receive(:email_record).with(anything, { :to => 'test_email@projectblacklight.org', :message => 'xyz' }, hash_including(:host => 'test.host')).and_return mock_mailer

        post :email, :id => doc_id, :to => 'test_email@projectblacklight.org', :message => 'xyz'
        expect(request.flash[:error]).to be_nil
        expect(request).to redirect_to(catalog_path(doc_id))
      end

      it "should render email_sent for XHR requests" do
        xhr :post, :email, :id => doc_id, :to => 'test_email@projectblacklight.org'
        expect(request).to render_template 'email_sent'
        expect(request.flash[:success]).to eq "Email Sent"
      end
    end
    describe "sms" do
      it "should give error if no phone number is given" do
        post :sms, :id => doc_id, :carrier => 'att'
        expect(request.flash[:error]).to eq("You must enter a recipient's phone number in order to send this message")
      end
      it "should give an error when a carrier is not provided" do
        post :sms, :id => doc_id, :to => '5555555555', :carrier => ''
        expect(request.flash[:error]).to eq("You must select a carrier")
      end
      it "should give an error when the phone number is not 10 digits" do
        post :sms, :id => doc_id, :to => '555555555', :carrier => 'txt.att.net'
        expect(request.flash[:error]).to eq("You must enter a valid 10 digit phone number")
      end
      it "should give an error when the carrier is not in our list of carriers" do
        post :sms, :id => doc_id, :to => '5555555555', :carrier => 'no-such-carrier'
        expect(request.flash[:error]).to eq("You must enter a valid carrier")
      end
      it "should allow punctuation in phone number" do
        post :sms, :id => doc_id, :to => '(555) 555-5555', :carrier => 'txt.att.net'
        expect(request.flash[:error]).to be_nil
        expect(request).to redirect_to(catalog_path(doc_id))
      end
      it "should redirect back to the record upon success" do
        post :sms, :id => doc_id, :to => '5555555555', :carrier => 'txt.att.net'
        expect(request.flash[:error]).to be_nil
        expect(request).to redirect_to(catalog_path(doc_id))
      end

      it "should render sms_sent template for XHR requests" do
        xhr :post, :sms, :id => doc_id, :to => '5555555555', :carrier => 'txt.att.net'
        expect(request).to render_template 'sms_sent'
        expect(request.flash[:success]).to eq "SMS Sent"
      end
    end
  end

  describe "errors" do
    it "should return status 404 for a record that doesn't exist" do
        @mock_response = double()
        allow(@mock_response).to receive_messages(:docs => [])
        @mock_document = double()
        allow(controller).to receive_messages(:find => @mock_response, 
                        :get_single_doc_via_search => @mock_document)
      get :show, :id=>"987654321"
      expect(request.flash[:notice]).to eq("Sorry, you have requested a record that doesn't exist.")
      expect(response).to render_template('index')
      expect(response.status).to eq(404)
    end
    it "should redirect the user to the root url for a bad search" do
      req = {}
      res = {}
      fake_error = RSolr::Error::Http.new(req, res) 
      allow(controller).to receive(:get_search_results) { |*args| raise fake_error }
      expect(controller.logger).to receive(:error).with(fake_error)
      get :index, :q=>"+"

      expect(response.redirect_url).to eq(root_url)
      expect(request.flash[:notice]).to eq("Sorry, I don't understand your search.")
      expect(response).not_to be_success
      expect(response.status).to eq(302)
    end
    it "should return status 500 if the catalog path is raising an exception" do

      req = {}
      res = {}
      fake_error = RSolr::Error::Http.new(req, res) 
      allow(controller).to receive(:get_search_results) { |*args| raise fake_error }
      allow(controller.flash).to receive(:sweep)
      allow(controller).to receive(:flash).and_return(:notice => I18n.t('blacklight.search.errors.request_error'))
      expect {
      get :index, :q=>"+"
      }.to raise_error 
    end

  end

  context "without a user authentication provider" do
    render_views

    before do
      allow(controller).to receive(:has_user_authentication_provider?) { false }
        @mock_response = double()
        @mock_document = double()
        allow(@mock_response).to receive_messages(:docs => [], :total => 1, :facets => [], :facet_queries => {}, :facet_by_field_name => nil)
        @mock_document = double()
        allow(controller).to receive_messages(:find => @mock_response, 
                        :get_single_doc_via_search => @mock_document)
    end

    it "should not show user util links" do
      get :index
      expect(response.body).not_to match(/Login/)
    end
  end

  describe "facet" do
    describe "requesting js" do
      it "should be successful" do
        xhr :get, :facet, id: 'format'
        expect(response).to be_successful
      end
    end
    describe "requesting html" do
      it "should be successful" do
        get :facet, id: 'format'
        expect(response).to be_successful
        expect(assigns[:pagination]).to be_kind_of Blacklight::Solr::FacetPaginator
      end
    end
    describe "requesting json" do
      it "should be successful" do
        get :facet, id: 'format', format: 'json'
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["response"]["facets"]["items"].first["value"]).to eq('Book')
      end
    end
  end

  describe 'render_search_results_as_json' do
    before do
      controller.instance_variable_set :@document_list, [{id: '123', title_t: 'Book1'}, {id: '456', title_t: 'Book2'}]
      allow(controller).to receive(:pagination_info).and_return({current_page: 1, next_page: 2, prev_page: nil})
      allow(controller).to receive(:search_facets_as_json).and_return(
          [{name: "format", label: "Format", items: [{value: 'Book', hits: 30, label: 'Book'}]}])
    end

    it "should be a hash" do
       expect(controller.send(:render_search_results_as_json)).to eq (
         {response: {docs: [{id: '123', title_t: 'Book1'}, {id: '456', title_t: 'Book2'}],
                     facets: [{name: "format", label: "Format", items: [{value: 'Book', hits: 30, label: 'Book'}]}],
                     pages: {current_page: 1, next_page: 2, prev_page: nil}}}
       )
    end
  end

  describe 'render_facet_list_as_json' do
    before do
      controller.instance_variable_set :@pagination, {items: [{value: 'Book'}]}
    end

    it "should be a hash" do
       expect(controller.send(:render_facet_list_as_json)).to eq (
         {response: {facets: {items: [{value: 'Book'}]}}}
       )
    end
  end

  describe "#add_to_search_history" do
    it "should prepend the current search to the list" do
      session[:history] = []
      controller.send(:add_to_search_history, double(:id => 1))
      expect(session[:history].size).to eq(1)

      controller.send(:add_to_search_history, double(:id => 2))
      expect(session[:history].size).to eq(2)
      expect(session[:history].first).to eq 2
    end

    it "should remove searches from the list when the list gets too big" do
      allow(controller).to receive(:blacklight_config).and_return(double(:search_history_window => 5))
      session[:history] = (0..4).to_a.reverse

      expect(session[:history].size).to eq(5)
      controller.send(:add_to_search_history, double(:id => 5))
      controller.send(:add_to_search_history, double(:id => 6))
      controller.send(:add_to_search_history, double(:id => 7))
      expect(session[:history]).to include(*(3..7).to_a)

    end
  end

  describe "current_search_session" do
    it "should create a session if we're on an search action" do
      allow(controller).to receive_messages(:action_name => "index")
      allow(controller).to receive_messages(:params => { :q => "x", :page => 5})
      session = controller.send(:current_search_session)
      expect(session.query_params).to include(:q => "x")
      expect(session.query_params).to_not include(:page => 5)
    end

    it "should create a session if a search context was provided" do
      allow(controller).to receive_messages(:params => { :search_context => JSON.dump(:q => "x")})
      session = controller.send(:current_search_session)
      expect(session.query_params).to include("q" => "x")
    end

    it "should use an existing session if a search id was provided" do
      s = Search.create(:query_params => { :q => "x" })
      session[:history] ||= []
      session[:history] << s.id
      allow(controller).to receive_messages(:params => { :search_id => s.id})
      session = controller.send(:current_search_session)
      expect(session.query_params).to include(:q => "x")
      expect(session).to eq(s)
    end

    it "should use an existing search session if the search is in the uri" do
      s = Search.create(:query_params => { :q => "x" })
      session[:search] ||= {}
      session[:search]['id'] = s.id
      session[:history] ||= []
      session[:history] << s.id
      session = controller.send(:current_search_session)
      expect(session.query_params).to include(:q => "x")
      expect(session).to eq(s)
    end
  end
end


# there must be at least one facet, and each facet must have at least one value
def assert_facets_have_values(facets)
  expect(facets.size).to be > 1
  # should have at least one value for each facet
  facets.each do |facet|
    expect(facet.items.size).to be >= 1
  end
end

