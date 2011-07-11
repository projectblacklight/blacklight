# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'marc'

describe CatalogController do
#=begin
  # ROUTES and MAPPING
  describe "Paths Generated by Custom Routes:" do
    # paths generated by custom routes
    it "should map {:controller => 'catalog', :action => 'email'} to /catalog/email" do
      # RSpec <1.2.9: route_for(:controller => 'catalog', :action => 'email').should == '/catalog/email'
      { :get => "/catalog/email" }.should route_to(:controller => 'catalog', :action => 'email')

    end
    it "should map {:controller => 'catalog', :action => 'sms'} to /catalog/sms" do
      # RSpec <1.2.9: route_for(:controller => 'catalog', :action => 'sms').should == '/catalog/sms'      
      { :get => "/catalog/sms" }.should route_to(:controller => 'catalog', :action => 'sms')
    end
    it "should map { :controller => 'catalog', :action => 'show', :id => 666 } to /catalog/666" do
      # RSpec <1.2.9: route_for(:controller => 'catalog', :action => 'show', :id => '666').should == '/catalog/666'
      { :get => "/catalog/666" }.should route_to(:controller => 'catalog', :action => 'show', :id => "666")
    end
    it "should map {:controller => 'catalog', :id => '111', :action => 'librarian_view'} to /catalog/111/librarian_view" do
      # RSpec <1.2.9: route_for(:controller => 'catalog', :action => 'librarian_view', :id => '111').should == '/catalog/111/librarian_view'
      { :get => "/catalog/111/librarian_view" }.should route_to(:controller => 'catalog', :action => 'librarian_view', :id => "111")
    end
  end

  # parameters generated from routes
  describe "Parameters Generated from Routes:" do
    it "should map /catalog/email to {:controller => 'catalog', :action => 'email'}" do
      # RSpec <1.2.9: params_from(:get, '/catalog/email').should == {:controller => 'catalog', :action => 'email'}
      { :get => "/catalog/email" }.should route_to(:controller => 'catalog', :action => 'email')
    end
    it "should map /catalog/sms to {:controller => 'catalog', :action => 'sms'}" do
      #RSpec <1.2.9 :params_from(:get, '/catalog/sms').should == {:controller => 'catalog', :action => 'sms'}
      { :get => "/catalog/sms" }.should route_to(:controller => 'catalog', :action => 'sms')
    end
    it "should map /catalog/666 to {:controller => 'catalog', :action => 'show', :id => 666}" do
      #RSPEC <1.2.9  params_from(:get, '/catalog/666').should == {:controller => 'catalog', :action => 'show', :id => '666'}
      { :get => "/catalog/666" }.should route_to(:controller => 'catalog', :action => 'show', :id => "666")
    end
    it "should map /catalog/111/librarian_view to {:controller => 'catalog', :action => 'librarian_view', :id => 111}" do
#      params_from(:get, '/catalog/111/librarian_view').should == {:controller => 'catalog', :action => 'librarian_view', :id => '111'}
      { :get => "/catalog/111/librarian_view" }.should route_to(:controller => 'catalog', :action => 'librarian_view', :id => "111")
    end
  end



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
    
    it "should respect @extra_controller_params" do
      # This can be removed once HYDRA-564 is closed
      expected_params = {:q=>"sample query"}
      controller.instance_variable_set(:@extra_controller_params, expected_params)
      controller.stub(:params).and_return({:action=>:index})
      controller.stub(:enforce_access_controls)
      controller.should_receive(:get_search_results).with(controller.params, expected_params)
      get :index
    end
    
    it "should have no search history if no search criteria" do
      session[:history] = []
      get :index
      session[:history].length.should == 0
    end

    # check each user manipulated parameter
    it "should have docs and facets for query with results" do
      get :index, :q => @user_query
      assigns_response.docs.size.should > 1
      assert_facets_have_values(assigns_response.facets)
    end
    it "should have docs and facets for existing facet value" do
      get :index, :f => @facet_query
      assigns_response.docs.size.should > 1
      assert_facets_have_values(assigns_response.facets)
    end
    it "should have docs and facets for non-default results per page" do
      num_per_page = 7
      get :index, :per_page => num_per_page
      assigns_response.docs.size.should == num_per_page
      assert_facets_have_values(assigns_response.facets)
    end

    it "should have docs and facets for second page" do
      page = 2
      get :index, :page => page
      assigns_response.docs.size.should > 1
      assigns_response.params[:start].to_i.should == (page-1) * Blacklight.config[:default_solr_params][:per_page]
      assert_facets_have_values(assigns_response.facets)
    end

    it "should have no docs or facet values for query without results" do
      get :index, :q => @no_docs_query

      assigns_response.docs.size.should == 0
      assigns_response.facets.each do |facet|
        facet.items.size.should == 0
      end
    end

    it "should have a spelling suggestion for an appropriately poor query" do
      get :index, :q => 'boo'
      assigns_response.spelling.words.should_not be_nil
    end

    describe "session" do
      it "should include :search key with hash" do
        get :index
        session[:search].should_not be_nil
        session[:search].should be_kind_of(Hash)
      end
      it "should include search hash with key :q" do
        get :index, :q => @user_query
        session[:search].should_not be_nil
        session[:search].keys.should include(:q)
        session[:search][:q].should == @user_query
      end
      it "should include search hash with key :f" do
        get :index, :f => @facet_query
        session[:search].should_not be_nil
        session[:search].keys.should include(:f)
        session[:search][:f].should == @facet_query
      end
      it "should include search hash with key :per_page" do
        get :index, :per_page => 10
        session[:search].should_not be_nil
        session[:search].keys.should include(:per_page)
        session[:search][:per_page].should == "10"
      end
      it "should include search hash with key :page" do
        get :index, :page => 2
        session[:search].should_not be_nil
        session[:search].keys.should include(:page)
        session[:search][:page].should == "2"
      end
      it "should include search hash with random key" do
        # cause a plugin might add an unpredictable one, we want to preserve it.
        get :index, :some_weird_key => "value"
        session[:search].should_not be_nil
        session[:search].keys.should include(:some_weird_key)
        session[:search][:some_weird_key].should == "value"
      end
    end

    describe "with index action with arbitrary key" do
      before(:each) do
         session[:history] = []
         get :index, :arbitrary_key_from_plugin => "value"
      end
      it "should save search history" do
        session[:history].length.should_not == 0
      end
    end

    # check with no user manipulation
    describe "for default query" do
      it "should get documents when no query" do
        get :index
        assigns_response.docs.size.should > 1
      end
      it "should get facets when no query" do
        get :index
        assert_facets_have_values(assigns_response.facets)
      end
    end

    it "should get rss feed" do
      get :index, :format => 'rss'
      response.should be_success
    end

    it "should render index.html.erb" do
      get :index
      response.should render_template(:index)
    end
    # NOTE: status code is always 200 in isolation mode ...
    it "HTTP status code for GET should be 200" do
      get :index
      response.should be_success
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

    it "should get document" do
      get :show, :id => doc_id
      assigns[:document].should_not be_nil
    end
    it "should set previous document if counter present in session" do
      session[:search] = {:q => "", :counter => 2}
      get :show, :id => doc_id
      assigns[:previous_document].should_not be_nil
    end
    it "should not set previous document if counter is 1" do
      session[:search] = {:counter => 1}
      get :show, :id => doc_id
      assigns[:previous_document].should be_nil
    end
    it "should not set previous or next document if session is blank" do
      get :show, :id => doc_id
      assigns[:previous_document].should be_nil
      assigns[:next_document].should be_nil
    end
    it "should not set previous or next document if session[:search][:counter] is nil" do
      session[:search] = {:q => ""}
      get :show, :id => doc_id
      assigns[:previous_document].should be_nil
      assigns[:next_document].should be_nil
    end
    it "should set next document if counter present in session" do
      session[:search] = {:q => "", :counter => 2}
      get :show, :id => doc_id
      assigns[:next_document].should_not be_nil
    end
    it "should not set next document if counter is >= number of docs" do
      session[:search] = {:counter => 66666666}
      get :show, :id => doc_id
      assigns[:next_document].should be_nil
    end

    # NOTE: status code is always 200 in isolation mode ...
    it "HTTP status code for GET should be 200" do
      get :show, :id => doc_id
      response.should be_success
    end
    it "should render show.html.erb" do
      get :show, :id => doc_id
      response.should render_template(:show)
    end

    describe "@document" do
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

       before(:each) do

        # Rails3 needs this to propertly setup a new mime type and
        # render the results. 
        ActionController.add_renderer :mock do |template, options|
          send_data "mock_export", :type => Mime::MOCK
        end
        Mime::Type.register "application/mock", :mock
        
        SolrDocument.use_extension(FakeExtension)
      end
      
      it "should respond to an extension-registered format properly" do
        get :show, :id => doc_id, :format => "mock" # This no longer works: :format => "mock"
        response.should be_success
        response.should contain("mock_export")
      end
      

      after(:each) do
        SolrDocument.registered_extensions = nil
      end
    end # dynamic export formats

  end # describe show action

  describe "unapi" do
      doc_id = '2007020969'
        module FakeExtension
          def self.extended(document)
            document.will_export_as(:mock, "application/mock")
            document.will_export_as(:mockxml, "text/xml")
          end

          def export_as_mock
            "mock_export"
          end

          def export_as_mockxml
            "<a><mock xml='document' /></a>"
          end
        end
      before(:each) do
        SolrDocument.registered_extensions = nil
        SolrDocument.use_extension(FakeExtension)
      end

    it "should return an unapi formats list from config[:unapi]" do
      Blacklight.config[:unapi] = { :mock => { :content_type => "application/mock" } }
      get :unapi
      response.should be_success
      assigns[:export_formats][:mock][:content_type].should == "application/mock"
    end


    it "should return an unapi formats list for document" do
      get :unapi, :id => doc_id
      response.should be_success
      assigns[:document].should be_kind_of(SolrDocument)
      assigns[:export_formats].should_not be_nil
      assigns[:export_formats].should be_kind_of(Hash) 
      assigns[:export_formats][:mock] == { :content_type => "application/mock" }
      assigns[:export_formats][:mockxml] = { :content_type => 'text/xml' }
    end

    it "should return an unapi format export for document" do
      get :unapi, :id => doc_id, :format => 'mock'
      response.should be_success
      response.should contain("mock_export")
    end
  end

  describe "opensearch" do
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
        post :email, :id => doc_id, :to => 'test_email@projectblacklight.org'
        request.flash[:error].should be_nil
        request.should redirect_to(catalog_path(doc_id))
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
        post :sms, :id => doc_id, :to => '555555555', :carrier => 'att'
        request.flash[:error].should == "You must enter a valid 10 digit phone number"
      end
      it "should allow punctuation in phone number" do
        post :sms, :id => doc_id, :to => '(555) 555-5555', :carrier => 'att'
        request.flash[:error].should be_nil
        request.should redirect_to(catalog_path(doc_id))
      end
      it "should redirect back to the record upon success" do
        post :sms, :id => doc_id, :to => '5555555555', :carrier => 'att'
        request.flash[:error].should be_nil
        request.should redirect_to(catalog_path(doc_id))
      end
    end
    describe "backwards compatbile send_record_email" do
      it "should redirect to the sms action when the sms style param is passed" do
        post :send_email_record, :style=>"sms"
        request.should redirect_to(sms_catalog_path)
      end
      it "should redirect to the email action when the email style param is passed" do
        post :send_email_record, :style=>"email"
        request.should redirect_to(email_catalog_path)
      end
      it "should not do anything if a bad style is sent" do
        post :send_email_record, :style=>"bad-style"
        response.status.should == 404
      end
    end
  end

  describe "errors" do
    it "should return status 404 for a record that doesn't exist" do
      get :show, :id=>"987654321"
      response.redirect_url.should == root_url
      request.flash[:notice].should == "Sorry, you have requested a record that doesn't exist."
      response.should_not be_success
      response.status.should == 404
    end
    it "should return a status 500 for a bad search" do
      get :index, :q=>"+"
      response.redirect_url.should == root_url
      request.flash[:notice].should == "Sorry, I don't understand your search."
      response.should_not be_success
      response.status.should == 500
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

