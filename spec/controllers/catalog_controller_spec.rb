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
        controller.should_receive(:get_search_results) 
        session[:history] = []
        get :index
        session[:history].length.should == 0
      end

      # check each user manipulated parameter
      it "should have docs and facets for query with results", :integration => true do
        get :index, :q => @user_query
        assigns_response.docs.size.should > 1
        assert_facets_have_values(assigns_response.facets)
      end
      it "should have docs and facets for existing facet value", :integration => true do
        get :index, :f => @facet_query
        assigns_response.docs.size.should > 1
        assert_facets_have_values(assigns_response.facets)
      end
      it "should have docs and facets for non-default results per page", :integration => true do
        num_per_page = 7
        get :index, :per_page => num_per_page
        assigns_response.docs.size.should == num_per_page
        assert_facets_have_values(assigns_response.facets)
      end

      it "should have docs and facets for second page", :integration => true do
        page = 2
        get :index, :page => page
        assigns_response.docs.size.should > 1
        assigns_response.params[:start].to_i.should == (page-1) * @controller.blacklight_config[:default_solr_params][:rows]
        assert_facets_have_values(assigns_response.facets)
      end

      it "should have no docs or facet values for query without results", :integration => true do
        get :index, :q => @no_docs_query

        assigns_response.docs.size.should == 0
        assigns_response.facets.each do |facet|
          facet.items.size.should == 0
        end
      end

      it "should have a spelling suggestion for an appropriately poor query", :integration => true do
        get :index, :q => 'boo'
        assigns_response.spelling.words.should_not be_nil
      end

      describe "session" do
        before do
          controller.stub(:get_search_results) 
        end
        it "should include :search key with hash" do
          get :index
          session[:search].should_not be_nil
          session[:search].should be_kind_of(Hash)
        end
        it "should include search hash with key :q" do
          get :index, :q => @user_query
          session[:search].should_not be_nil
          session[:search].keys.should include(:id)
          
          search = Search.find(session[:search][:id])
          expect(search.query_params[:q]).to eq @user_query
        end
      end

      # check with no user manipulation
      describe "for default query" do
        it "should get documents when no query", :integration => true do
          get :index
          assigns_response.docs.size.should > 1
        end
        it "should get facets when no query", :integration => true do
          get :index
          assert_facets_have_values(assigns_response.facets)
        end
      end

      it "should render index.html.erb" do
        controller.stub(:get_search_results)
        get :index
        response.should render_template(:index)
      end

      # NOTE: status code is always 200 in isolation mode ...
      it "HTTP status code for GET should be 200", :integration => true do
        get :index
        response.should be_success
      end
    end

    describe "with format :rss" do
      it "should get the feed", :integration => true do
        get :index, :format => 'rss'
        response.should be_success
      end
    end

    describe "with format :json" do
      before do
        get :index, :format => 'json'
        response.should be_success
      end
      let(:json) { JSON.parse(response.body)['response'] }
      let(:pages) { json["pages"] }
      let(:docs) { json["docs"] }
      let(:facets) { json["facets"] }

      it "should get the pages" do
        pages["total_count"].should == 30 
        pages["current_page"].should == 1
        pages["total_pages"].should == 3
      end

      it "should get the documents" do
        docs.size.should == 10
        docs.first.keys.should == ["published_display", "author_display", "lc_callnum_display", "pub_date", "subtitle_display", "format", "material_type_display", "title_display", "id", "subject_topic_facet", "language_facet", "score"]
      end

      it "should get the facets" do
        facets.length.should == 9
        facets.first.should == {"name"=>"format", "label" => "Format", "items"=>[{"value"=>"Book", "hits"=>30, "label"=>"Book"}]}
      end

      describe "facets" do
        let(:query_facet_items) { facets.last['items'] }
        let(:regular_facet_items) { facets.first['items'] }
        it "should have items with labels and values" do
          query_facet_items.first['label'].should == 'within 5 Years'
          query_facet_items.first['value'].should == 'years_5'
          regular_facet_items.first['label'].should == "Book"
          regular_facet_items.first['value'].should == "Book"
        end
      end
    end

  end # describe index action

  describe "update action" do
    doc_id = '2007020969'

    it "should set counter value into session[:search]" do
      put :update, :id => doc_id, :counter => 3
      session[:search][:counter].should == "3"
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
        assigns[:document].should_not be_nil
      end
    end

    describe "with format :json" do
      it "should get the feed" do
        get :show, id: doc_id, format: 'json'
        response.should be_success
        json = JSON.parse response.body
        json["response"]["document"].keys.should == ["author_t", "opensearch_display", "marc_display", "published_display", "author_display", "lc_callnum_display", "title_t", "pub_date", "pub_date_sort", "subtitle_display", "format", "url_suppl_display", "material_type_display", "title_display", "subject_addl_t", "subject_t", "isbn_t", "id", "title_addl_t", "subject_geo_facet", "subject_topic_facet", "author_addl_t", "language_facet", "subtitle_t", "timestamp"]
      end
    end
    
    describe "previous/next documents" do
      before do
        @mock_response = double()
        @mock_document = double()
        @mock_document.stub(:export_formats => {})
        controller.stub(:get_solr_response_for_doc_id => [@mock_response, @mock_document], 
                        :get_single_doc_via_search => @mock_document)

        current_search = Search.create(:query_params => { :q => ""})
        controller.stub(:current_search_session => current_search)

        @search_session = { :id => current_search.id }
      end
    it "should set previous document if counter present in session" do
      session[:search] = @search_session.merge(:counter => 2)
      get :show, :id => doc_id
      assigns[:previous_document].should_not be_nil
    end
    it "should not set previous document if counter is 1" do

      session[:search] = @search_session.merge(:counter => 1)
      get :show, :id => doc_id
      assigns[:previous_document].should be_nil
    end
    it "should not set previous or next document if session is blank" do
      get :show, :id => doc_id
      assigns[:previous_document].should be_nil
      assigns[:next_document].should be_nil
    end
    it "should not set previous or next document if session[:search][:counter] is nil" do
      session[:search] = {}
      get :show, :id => doc_id
      assigns[:previous_document].should be_nil
      assigns[:next_document].should be_nil
    end
    it "should set next document if counter present in session" do
      session[:search] = @search_session.merge(:counter => 2)
      get :show, :id => doc_id
      assigns[:next_document].should_not be_nil
    end
    it "should not set next document if counter is >= number of docs" do
      controller.stub(:get_single_doc_via_search => nil)
      session[:search] = @search_session.merge(:counter => 66666666)
      get :show, :id => doc_id
      assigns[:next_document].should be_nil
    end
    end

    # NOTE: status code is always 200 in isolation mode ...
    it "HTTP status code for GET should be 200", :integration => true do
      get :show, :id => doc_id
      response.should be_success
    end
    it "should render show.html.erb" do
      @mock_response = double()
      @mock_document = double()
      @mock_document.stub(:export_formats => {})
      controller.stub(:get_solr_response_for_doc_id => [@mock_response, @mock_document], 
                      :get_single_doc_via_search => @mock_document)
      get :show, :id => doc_id
      response.should render_template(:show)
    end

    describe "@document" do
      before do
        @mock_response = double()
        @mock_response.stub(:docs => [{ :id => 'my_fake_doc' }])
        @mock_document = double()
        controller.stub(:find => @mock_response, 
                        :get_single_doc_via_search => @mock_document)
      end
      before(:each) do
        get :show, :id => doc_id
        @document = assigns[:document]
      end
      it "should be a SolrDocument" do
        @document.should be_instance_of(SolrDocument)
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
        @mock_response.stub(:docs => [{ :id => 'my_fake_doc' }])
        @mock_document = double()
        controller.stub(:find => @mock_response, 
                        :get_single_doc_via_search => @mock_document)

        controller.stub(:find => @mock_response, 
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
        response.should be_success
        response.body.should =~ /mock_export/
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
      @mock_response.stub(:docs => [{ :id => 'my_fake_doc' }, { :id => 'my_other_doc'}])
      @mock_document = double()
      controller.stub(:find => @mock_response, 
                      :get_single_doc_via_search => @mock_document)
    end
    it "should return an opensearch description" do
      get :opensearch, :format => 'xml'
      response.should be_success
    end
    it "should return valid JSON" do
      get :opensearch,:format => 'json', :q => "a"
      response.should be_success
    end
  end
#=end
  describe "email/sms" do
    doc_id = '2007020969'
      before do
        @mock_response = double()
        @mock_document = double()
        @mock_response.stub(:docs => [{ :id => 'my_fake_doc' }, { :id => 'my_other_doc'}])
        @mock_document = double()
        controller.stub(:find => @mock_response, 
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
        request.flash[:error].should == "You must enter a recipient in order to send this message"
      end
      it "should give an error if the email address is not valid" do
        post :email, :id => doc_id, :to => 'test_bad_email'
        request.flash[:error].should == "You must enter a valid email address"
      end
      it "should not give error if no Message paramater is set" do
        post :email, :id => doc_id, :to => 'test_email@projectblacklight.org'
        request.flash[:error].should be_nil
      end
      it "should redirect back to the record upon success" do
        mock_mailer = double
        mock_mailer.should_receive(:deliver)
        RecordMailer.should_receive(:email_record).with(anything, { :to => 'test_email@projectblacklight.org', :message => 'xyz' }, hash_including(:host => 'test.host')).and_return mock_mailer

        post :email, :id => doc_id, :to => 'test_email@projectblacklight.org', :message => 'xyz'
        request.flash[:error].should be_nil
        request.should redirect_to(catalog_path(doc_id))
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
        request.flash[:error].should == "You must enter a recipient's phone number in order to send this message"
      end
      it "should give an error when a carrier is not provided" do
        post :sms, :id => doc_id, :to => '5555555555', :carrier => ''
        request.flash[:error].should == "You must select a carrier"
      end
      it "should give an error when the phone number is not 10 digits" do
        post :sms, :id => doc_id, :to => '555555555', :carrier => 'txt.att.net'
        request.flash[:error].should == "You must enter a valid 10 digit phone number"
      end
      it "should give an error when the carrier is not in our list of carriers" do
        post :sms, :id => doc_id, :to => '5555555555', :carrier => 'no-such-carrier'
        request.flash[:error].should == "You must enter a valid carrier"
      end
      it "should allow punctuation in phone number" do
        post :sms, :id => doc_id, :to => '(555) 555-5555', :carrier => 'txt.att.net'
        request.flash[:error].should be_nil
        request.should redirect_to(catalog_path(doc_id))
      end
      it "should redirect back to the record upon success" do
        post :sms, :id => doc_id, :to => '5555555555', :carrier => 'txt.att.net'
        request.flash[:error].should be_nil
        request.should redirect_to(catalog_path(doc_id))
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
        @mock_response.stub(:docs => [])
        @mock_document = double()
        controller.stub(:find => @mock_response, 
                        :get_single_doc_via_search => @mock_document)
      get :show, :id=>"987654321"
      request.flash[:notice].should == "Sorry, you have requested a record that doesn't exist."
      response.should render_template('index')
      response.status.should == 404
    end
    it "should redirect the user to the root url for a bad search" do
      req = {}
      res = {}
      fake_error = RSolr::Error::Http.new(req, res) 
      controller.stub(:get_search_results) { |*args| raise fake_error }
      controller.logger.should_receive(:error).with(fake_error)
      get :index, :q=>"+"

      response.redirect_url.should == root_url
      request.flash[:notice].should == "Sorry, I don't understand your search."
      response.should_not be_success
      response.status.should == 302
    end
    it "should return status 500 if the catalog path is raising an exception" do

      req = {}
      res = {}
      fake_error = RSolr::Error::Http.new(req, res) 
      controller.stub(:get_search_results) { |*args| raise fake_error }
      controller.flash.stub(:sweep)
      controller.stub(:flash).and_return(:notice => I18n.t('blacklight.search.errors.request_error'))
      expect {
      get :index, :q=>"+"
      }.to raise_error 
    end

  end

  context "without a user authentication provider" do
    render_views

    before do
      controller.stub(:has_user_authentication_provider?) { false }
        @mock_response = double()
        @mock_document = double()
        @mock_response.stub(:docs => [], :total => 1, :facets => [], :facet_queries => {}, :facet_by_field_name => nil)
        @mock_document = double()
        controller.stub(:find => @mock_response, 
                        :get_single_doc_via_search => @mock_document)
    end

    it "should not show user util links" do
      get :index
      response.body.should_not =~ /Login/
    end
  end

  describe "facet" do
    describe "requesting js" do
      it "should be successful" do
        xhr :get, :facet, id: 'format'
        response.should be_successful
      end
    end
    describe "requesting html" do
      it "should be successful" do
        get :facet, id: 'format'
        response.should be_successful
        assigns[:pagination].should be_kind_of Blacklight::Solr::FacetPaginator
      end
    end
    describe "requesting json" do
      it "should be successful" do
        get :facet, id: 'format', format: 'json'
        response.should be_successful
        json = JSON.parse(response.body)
        json["response"]["facets"]["items"].first["value"].should == 'Book'
      end
    end
  end

  describe 'render_search_results_as_json' do
    before do
      controller.instance_variable_set :@document_list, [{id: '123', title_t: 'Book1'}, {id: '456', title_t: 'Book2'}]
      controller.stub(:pagination_info).and_return({current_page: 1, next_page: 2, prev_page: nil})
      controller.stub(:search_facets_as_json).and_return(
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
end


# there must be at least one facet, and each facet must have at least one value
def assert_facets_have_values(facets)
  facets.size.should > 1
  # should have at least one value for each facet
  facets.each do |facet|
    facet.items.size.should >= 1
  end
end

