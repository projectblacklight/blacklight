require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'marc'

# Because SolrHelper is a controller layer mixin,
# it depends on the methods provided by AtionController::Base
# currently, the only method that is used is #params
class MockSolrHelperContainer

  include Blacklight::SolrHelper
  attr_accessor :params
  attr_accessor :response

  # SolrHelper expects a method called #params,
  # within the class that's mixing it in
  def params
    @params ||= {}
  end

end


=begin
# check the methods that do solr requests. Note that we are not testing if
#  solr gives "correct" responses, as that's out of scope (it's a part of
#  testing the solr code itself).  We *are* testing if blacklight code sends
#  queries to solr such that it gets appropriate results. When a user does a search,
#  do we get data back from solr (i.e. did we properly configure blacklight code
#  to talk with solr and get results)? when we do a document request, does
#  blacklight code get a single document returned?)
=end
describe 'Blacklight::SolrHelper' do

  before(:all) do
    @solr_helper = MockSolrHelperContainer.new
    @solr_url = Blacklight.solr_config[:url]
  end

  before(:each) do
    @all_docs_query = ''
    @no_docs_query = 'zzzzzzzzzzzz'
    @single_word_query = 'include'
    @mult_word_query = 'tibetan history'
  #  f[format][]=Book&f[language_facet][]=English
    @single_facet = {:format=>'Book'}
    @multi_facets = {:format=>'Book', :language_facet=>'Tibetan'}
    @bad_facet = {:format=>'666'}
    @subject_search_params = {:commit=>"search", :search_field=>"subject", :action=>"index", :"controller"=>"catalog", :"per_page"=>"10", :"q"=>"wome"}
  end

  # SPECS FOR blacklight.rb contents
  describe "blacklight.rb" do
    describe "solr.yml and/or initializers" do

      it "should contain a solr_url" do
        Blacklight.solr_config[:url].should_not == nil
      end

      it "should contain some display fields" do
        Blacklight.config[:show].should_not == nil
      end

    end
  end

  # SPECS for actual search parameter generation
  describe "solr_search_params" do
    describe 'for an entirely empty search' do
      before do
        @produced_params = @solr_helper.solr_search_params
      end
      it 'should not have a q param' do
        @produced_params[:q].should be_nil
        @produced_params["spellcheck.q"].should be_nil
      end
      it 'should have default per_page' do
        @produced_params[:per_page].should == 10
      end
      it 'should have default facet fields' do
        @produced_params[:"facet.field"].should == Blacklight.config[:default_solr_params][:"facet.field"]
      end
      it 'should not use the exact facet array from config defaults' do
        @produced_params[:"facet.field"].should_not be_equal(Blacklight.config[:facet][:field_names])
      end
      it "should have default qt"  do
        @produced_params[:qt].should == "search"
      end
      it "should have no fq" do
        @produced_params[:phrase_filters].should be_blank
        @produced_params[:fq].should be_blank
      end
    end


    describe "for an empty string search" do
      it "should return empty string q in solr parameters" do
        params = @solr_helper.solr_search_params(:q => "")
        params[:q].should == ""
        params["spellcheck.q"].should == ""
      end
    end

    describe "for request params also passed in as argument" do
      before do
        @req_params = HashWithIndifferentAccess.new({:q => "some query"})
        params = @req_params
      end
      it "should only have one 'q' key, as symbol" do
        solr_params = @solr_helper.solr_search_params( @req_params )
        solr_params.keys.should include(:q)
        solr_params.keys.should_not include("q")
      end
    end


    describe "for one facet, no query" do
      it "should have proper solr parameters" do

        params = @solr_helper.solr_search_params(:f => @single_facet)

        params[:q].should be_blank
        params["spellcheck.q"].should be_blank
        params[:"facet.field"].should == Blacklight.config[:default_solr_params][:"facet.field"]

        @single_facet.each_value do |value|
          params[:fq].should include("{!raw f=#{@single_facet.keys[0]}}#{value}")
        end
      end
    end

    describe "with Multi Facets, No Query" do
      it 'should have fq set properly' do
        params = @solr_helper.solr_search_params(:f => @multi_facets)

        @multi_facets.each_pair do |facet_field, value_list|
          value_list.each do |value|
            params[:fq].should include("{!raw f=#{facet_field}}#{value}"  )
          end
        end

      end
    end

    describe "with Multi Facets, Multi Word Query" do
      it 'should have fq and q set properly' do
        params = @solr_helper.solr_search_params(:q => @mult_word_query, :f => @multi_facets)

        @multi_facets.each_pair do |facet_field, value_list|
          value_list.each do |value|
            params[:fq].should include("{!raw f=#{facet_field}}#{value}"  )
          end
        end
        params[:q].should == @mult_word_query
      end
    end

    describe "solr parameters for a field search from config (subject)" do
      before do
        @solr_params = @solr_helper.solr_search_params( @subject_search_params )
      end
      it "should look up qt from field definition" do
        @solr_params[:qt].should == "search"
      end
      it "should not include weird keys not in field definition" do
        @solr_params[:phrase_filters].should be_nil
        @solr_params[:fq].should be_nil
        @solr_params[:commit].should be_nil
        @solr_params[:action].should be_nil
        @solr_params[:controller].should be_nil
      end
      it "should include proper 'q', possibly with LocalParams" do
        @solr_params[:q].should match(/(\{[^}]+\})?wome/)
      end
      it "should include proper 'q' when LocalParams are used" do
        if @solr_params[:q] =~ /\{[^}]+\}/
          @solr_params[:q].should match(/\{[^}]+\}wome/)
        end
      end
      it "should include spellcheck.q, without LocalParams" do
        @solr_params["spellcheck.q"].should == "wome"
      end
      it "should include facet.field from default_solr_params" do
        @solr_params[:"facet.field"].should == Blacklight.config[:default_solr_params][:"facet.field"]
      end
      it "should include spellcheck.dictionary from field def solr_parameters" do
        @solr_params[:"spellcheck.dictionary"].should == "subject"
      end
      it "should add on :solr_local_parameters using Solr LocalParams style" do
        params = @solr_helper.solr_search_params( @subject_search_params )

        #q == "{!pf=$subject_pf $qf=subject_qf} wome", make sure
        #the LocalParams are really there
        params[:q] =~ /^\{!([^}]+)\}/
        key_value_pairs = $1.split(" ")
        key_value_pairs.should include("pf=$subject_pf")
        key_value_pairs.should include("qf=$subject_qf")
      end
    end

    describe "overriding of qt parameter" do
      it "should return the correct overriden parameter" do
        @solr_helper.params[:qt] = "overriden"
        @solr_helper.solr_search_params[:qt].should == "overriden"
        @solr_helper.params[:qt] = nil
      end
    end

    describe "with a complex parameter environment" do
      before do
        # Add a custom search field def in so we can test it
        Blacklight.config[:search_fields] << {:display_label => "Test", :key=>"test_field", :solr_parameters => {:qf => "fieldOne^2.3 fieldTwo fieldThree^0.4", :pf => "", :spellcheck => 'false', :per_page => "55", :sort => "request_params_sort"}}
        #re-memoize
        Blacklight.search_field_list(:reload)

        # Add some params
        @solr_helper_with_params = MockSolrHelperContainer.new
        @solr_helper_with_params.params = {:search_field => "test_field", :q => "test query", "facet.field" => "extra_facet"}
      end
      after do
        # restore search field list to how it was.
        Blacklight.config[:search_fields].delete_if {|hash| hash[:key] == "test_field"}
        #re-memoize
        Blacklight.search_field_list(:reload)
      end

      it "should merge parameters from search_field definition" do
        params = @solr_helper_with_params.solr_search_params

        params[:qf].should == "fieldOne^2.3 fieldTwo fieldThree^0.4"
        params[:spellcheck].should == 'false'
      end
      it "should merge empty string parameters from search_field definition" do
        params = @solr_helper_with_params.solr_search_params
        params[:pf].should == ""
      end

      describe "should respect proper precedence of settings, " do
        before do
          @produced_params = @solr_helper_with_params.solr_search_params(:sort => "extra_params_sort")
          1+1
        end


        it "should not put :search_field in produced params" do
          @produced_params[:search_field].should be_nil
        end

        it "should fall through to BL general defaults for qt not otherwise specified " do
          @produced_params[:qt].should == Blacklight.config[:default_solr_params][:qt]
        end

        it "should take per_page from search field definition where specified" do
          @produced_params[:per_page].should == "55"
        end

        it "should take q from request params" do
          @produced_params[:q].should == "test query"
        end

        it "should add in extra facet.field from params" do
          @produced_params[:"facet.field"].should include("extra_facet")
        end

        it "should Overwrite request params sort with extra_params sort" do
          @produced_params[:sort].should == "extra_params_sort"
        end

      end
    end

    describe "for :solr_local_parameters config" do
      before do
        # Hack to test with our own custom config specified here
        @orig_blacklight = Blacklight
        Object.instance_eval{ remove_const :Blacklight }
        Blacklight = @orig_blacklight.clone
        Blacklight.unmemoize_all
        Blacklight.instance_variable_set("@config", {}.deep_merge(@orig_blacklight.config))

        Blacklight.config[:search_fields] = [
          { :display_label => "Author",
            :qt => "author_qt",
            :key => "author_key",
            :solr_local_parameters => {
              :qf => "$author_qf",
              :pf => "you'll have \" to escape this"
            },
            :solr_parameters => {
              :qf => "someField^1000",
              :ps => "2"
            }
          }
        ]

        @solr_helper = MockSolrHelperContainer.new
        @solr_helper.params = {:search_field => "author_key", :q => "query"}
        @result = @solr_helper.solr_search_params
      end

      it "should pass through ordinary params" do
        @result[:qt].should == "author_qt"
        @result[:ps].should == "2"
        @result[:qf].should == "someField^1000"
      end

      it "should include include local params with escaping" do
        @result[:q].should include('qf=$author_qf')
        @result[:q].should include('pf=\'you\\\'ll have \\" to escape this\'')
      end

      after do
        Object.instance_eval{ remove_const :Blacklight }
        Blacklight = @orig_blacklight
      end
    end

 end

  describe "solr_facet_params" do
    before do
      @facet_field = 'format'
      @generated_solr_facet_params = @solr_helper.solr_facet_params(@facet_field)

      @sort_key = Blacklight::Solr::FacetPaginator.request_keys[:sort]
      @offset_key = Blacklight::Solr::FacetPaginator.request_keys[:offset]
    end
    it 'sets rows to 0' do
      @generated_solr_facet_params[:rows].should == 0
    end
    it 'sets facets requested to facet_field argument' do
      @generated_solr_facet_params["facet.field".to_sym].should == @facet_field
    end
    it 'defaults offset to 0' do
      @generated_solr_facet_params['facet.offset'].should == 0
    end
    it 'uses offset manually set, and converts it to an integer' do
      solr_params = @solr_helper.solr_facet_params(@facet_field, @offset_key => "100")
      solr_params['facet.offset'].should == 100
    end
    it 'defaults limit to 20' do
      solr_params = @solr_helper.solr_facet_params(@facet_field)
      solr_params[:"f.#{@facet_field}.facet.limit"].should == 21
    end
    describe 'if facet_list_limit is defined in controller' do
      before(:each) do
        @solr_helper.stub!("facet_list_limit").and_return("1000")
      end
      it 'uses controller method for limit' do
        solr_params = @solr_helper.solr_facet_params(@facet_field)
        solr_params[:"f.#{@facet_field}.facet.limit"].should == 1001
      end
    end
    it 'uses sort set manually' do
      solr_params = @solr_helper.solr_facet_params(@facet_field, @sort_key => "index")
      solr_params['facet.sort'].should == 'index'
    end
    it "comes up with the same params as #solr_search_params to constrain context for facet list" do
      search_params = {:q => 'tibetan history', :f=> {:format=>'Book', :language_facet=>'Tibetan'}}
      solr_search_params = @solr_helper.solr_search_params( search_params )
      solr_facet_params = @solr_helper.solr_facet_params('format', search_params)

      solr_search_params.each_pair do |key, value|
        # The specific params used for fetching the facet list we
        # don't care about.
        next if [:facets, "facet.field".to_sym, :rows, 'facet.limit', 'facet.offset', 'facet.sort'].include?(key)
        # Everything else should match
        solr_facet_params[key].should == value
      end

    end
  end
  describe "for facet limit parameters config ed" do
    before(:each) do
      @solr_helper_facet = MockSolrHelperContainer.new
      @solr_helper_facet.params = {:search_field => "test_field", :q => "test query"}
      @solr_helper_facet.stub!("facet_limit_hash").and_return({:some_facet => nil, :subject_facet => 10})
      @generated_params = @solr_helper_facet.solr_search_params
    end
    
    it "should include specifically configged facet limits +1" do
      @generated_params[:"f.subject_facet.facet.limit"].should == 11      
    end
    it "should not include a facet limit for a nil key in hash" do
      @generated_params.should_not have_key(:"f.some_facet.facet.limit")
      @generated_params.should_not have_key(:"facet.limit")
    end
  end
   describe "get_facet_pagination" do
    before(:each) do
      @facet_paginator = @solr_helper.get_facet_pagination(@facet_field)
    end
    it 'should return a facet paginator' do
      @facet_paginator.should be_a_kind_of(Blacklight::Solr::FacetPaginator)
    end
    it 'with a limit set' do
      @facet_paginator.limit.should_not be_nil
    end
   end

# SPECS FOR SEARCH RESULTS FOR QUERY
  describe 'Search Results' do

    describe 'for a sample query returning results' do

      before(:all) do        
        (@solr_response, @document_list) = @solr_helper.get_search_results(:q => @all_docs_query)
      end

      it 'should have a @response.docs list of the same size as @document_list' do
        @solr_response.docs.length.should == @document_list.length
      end

      it 'should have @response.docs list representing same documents as SolrDocuments in @document_list' do
        @solr_response.docs.each_index do |index|
          mash = @solr_response.docs[index]
          solr_document = @document_list[index]

          Set.new(mash.keys).should == Set.new(solr_document.keys)

          mash.each_key do |key|
            mash[key].should == solr_document[key]
          end
        end
      end
    end

    describe 'for All Docs Query, No Facets' do
      it 'should have non-nil values for required doc fields set in initializer' do
        (solr_response, document_list) = @solr_helper.get_search_results(:q => @all_docs_query)
        result_docs = document_list
        document = result_docs.first
        document.get(Blacklight.config[:index][:show_link]).should_not == nil
        document.get(Blacklight.config[:index][:record_display_type]).should_not == nil
      end
    end



    describe "Single Word Query with no Facets" do
      it 'should have results' do
        (solr_response, document_list) = @solr_helper.get_search_results(:q => @single_word_query)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
    end

    describe "Multiple Words Query with No Facets" do
      it 'should have results' do

        (solr_response, document_list) = @solr_helper.get_search_results(:q => @mult_word_query)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
    end

    describe "One Facet, No Query" do
      it 'should have results' do
        (solr_response, document_list) = @solr_helper.get_search_results(:f => @single_facet)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
    end

    describe "Mult Facets, No Query" do
      it 'should have results' do
        (solr_response, document_list) = @solr_helper.get_search_results(:f => @multi_facets)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
    end

    describe "Single Word Query with One Facet" do
      it 'should have results' do
        (solr_response, document_list) = @solr_helper.get_search_results(:q => @single_word_query, :f => @single_facet)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
    end

    describe "Multiple Words Query with Multiple Facets" do
      it 'should have results' do
        (solr_response, document_list) = @solr_helper.get_search_results(:q => @mult_word_query, :f => @multi_facets)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
    end

    describe "for All Docs Query and One Facet" do
      it 'should have results' do
        (solr_response, document_list) = @solr_helper.get_search_results(:q => @all_docs_query, :f => @single_facet)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
      # TODO: check that number of these results < number of results for all docs query
      #   BUT can't: num docs isn't total, it's the num docs in the single SOLR response (e.g. 10)
    end

    describe "for Query Without Results and No Facet" do
      it 'should have no results and not raise error' do
        (solr_response, document_list) = @solr_helper.get_search_results(:q => @no_docs_query)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should == 0
      end
    end

    describe "for Query Without Results and One Facet" do
      it 'should have no results and not raise error' do
        (solr_response, document_list) = @solr_helper.get_search_results(:q => @no_docs_query, :f => @single_facet)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should == 0
      end
    end

    describe "for All Docs Query and Bad Facet" do
      it 'should have no results and not raise error' do
        (solr_response, document_list) = @solr_helper.get_search_results(:q => @all_docs_query, :f => @bad_facet)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should == 0
      end
    end

    describe "for default display fields" do
      it "should have a list of field names for index_view_fields" do
        Blacklight.config[:index_fields].should_not be_nil
        Blacklight.config[:index_fields][:field_names].should be_instance_of(Array)
        Blacklight.config[:index_fields][:field_names].length.should > 0
        Blacklight.config[:index_fields][:field_names][0].should_not == nil
      end
    end


  end  # Search Results


# SPECS FOR SEARCH RESULTS FOR FACETS
  describe 'Facets in Search Results for All Docs Query' do

    before(:all) do
      (solr_response, document_list) = @solr_helper.get_search_results(:q => @all_docs_query)
      @facets = solr_response.facets
    end

    it 'should have more than one facet' do
      @facets.size.should > 1
    end
    it 'should have all facets specified in initializer' do      
      Blacklight.config[:default_solr_params][:"facet.field"].each do |field|
        @facets.find {|f| f.name == field}.should_not be_nil        
      end
    end
    it 'should have at least one value for each facet' do
      @facets.each do |facet|
        facet.items.size.should > 0
      end
    end
    it 'should have multiple values for at least one facet' do
      has_mult_values = false
      @facets.each do |facet|
        if facet.items.size > 1
          has_mult_values = true
          break
        end
      end
      has_mult_values.should == true
    end
    it 'should have all value counts > 0' do
      @facets.each do |facet|
        facet.items.each do |facet_vals|
          facet_vals.hits > 0
        end
      end
    end
  end # facet specs


# SPECS FOR SEARCH RESULTS FOR PAGING
  describe 'Paging' do

    it 'should start with first results by default' do
      (solr_response, document_list) = @solr_helper.get_search_results(:q => @all_docs_query)
      solr_response.params[:start].to_i.should == 0
    end
    it 'should have number of results (per page) set in initializer, by default' do
      (solr_response, document_list) = @solr_helper.get_search_results(:q => @all_docs_query)
      solr_response.docs.size.should == document_list.size
      solr_response.docs.size.should == Blacklight.config[:default_solr_params][:per_page]
    end

    it 'should get number of results per page requested' do
      num_results = 3  # non-default value
      (solr_response1, document_list1) = @solr_helper.get_search_results(:q => @all_docs_query, :per_page => num_results)
      solr_response1.docs.size.should == document_list1.size
      solr_response1.docs.size.should == num_results
    end

    it 'should skip appropriate number of results when requested - default per page' do
      page = 3
      (solr_response2, document_list2) = @solr_helper.get_search_results(:q => @all_docs_query, :page => page)
      solr_response2.params[:start].to_i.should ==  Blacklight.config[:default_solr_params][:per_page] * (page-1)
    end
    it 'should skip appropriate number of results when requested - non-default per page' do
      page = 3
      num_results = 3
      (solr_response2a, document_list2a) = @solr_helper.get_search_results(:q => @all_docs_query, :per_page => num_results, :page => page)
      solr_response2a.params[:start].to_i.should == num_results * (page-1)
    end

    it 'should have no results when prompted for page after last result' do
      big = 5000
      (solr_response3, document_list3) = @solr_helper.get_search_results(:q => @all_docs_query, :per_page => big, :page => big)
      solr_response3.docs.size.should == document_list3.size
      solr_response3.docs.size.should == 0
    end

    it 'should show first results when prompted for page before first result' do
      # FIXME: should it show first results, or should it throw an error for view to deal w?
      #   Solr throws an error for a negative start value
      (solr_response4, document_list4) = @solr_helper.get_search_results(:q => @all_docs_query, :page => '-1')
      solr_response4.params[:start].to_i.should == 0
    end
    it 'should have results available when asked for more than are in response' do
      big = 5000
      (solr_response5, document_list5) = @solr_helper.get_search_results(:q => @all_docs_query, :per_page => big, :page => 1)
      solr_response5.docs.size.should == document_list5.size
      solr_response5.docs.size.should > 0
    end

  end # page specs

  # SPECS FOR SINGLE DOCUMENT REQUESTS
  describe 'Get Document By Id' do
    before(:all) do
      @doc_id = '2007020969'
      @bad_id = "redrum"
      @response2, @document = @solr_helper.get_solr_response_for_doc_id(@doc_id)
    end

    it "should raise Blacklight::SolrHelper::InvalidSolrID for an unknown id" do
      lambda {
        @solr_helper.get_solr_response_for_doc_id(@bad_id)
      }.should raise_error(Blacklight::SolrHelper::InvalidSolrID)
    end

    it "should have a non-nil result for a known id" do
      @document.should_not == nil
    end
    it "should have a single document in the response for a known id" do
      @response2.docs.size.should == 1
    end
    it 'should have the expected value in the id field' do
      @document.get(:id).should == @doc_id
    end
    it 'should have non-nil values for required fields set in initializer' do
      @document.get(Blacklight.config[:show][:html_title]).should_not == nil
      @document.get(Blacklight.config[:show][:heading]).should_not == nil
      @document.get(Blacklight.config[:show][:display_type]).should_not == nil
    end
    it "should have a list of field names for show_view_fields" do
      Blacklight.config[:show_fields].should_not be_nil
      Blacklight.config[:show_fields][:field_names].should be_instance_of(Array)
      Blacklight.config[:show_fields][:field_names].length.should > 0
      Blacklight.config[:show_fields][:field_names][0].should_not == nil
    end



  end

# NOTE: some of these repeated fields could be in a shared behavior, but the
#  flow of control is such that the variables can't be instance variables
#  (or at least not for me - Naomi)

# SPECS FOR SINGLE DOCUMENT VIA SEARCH
  describe "Get Document Via Search" do
    before(:all) do
      @doc_row = 3
      @doc = @solr_helper.get_single_doc_via_search(:q => @all_docs_query, :page => @doc_row)
    end
=begin
# can't test these here, because the method only returns the document
    it "should get a single document" do
      response.docs.size.should == 1
    end

    doc2 = get_single_doc_via_search(@all_docs_query, nil, @doc_row, @multi_facets)
    it "should limit search result by facets when supplied" do
      response2.docs.numFound.should_be < response.docs.numFound
    end

    it "should not have facets in the response" do
      response.facets.size.should == 0
    end
=end

    it 'should have a doc id field' do
      @doc.get(:id).should_not == nil
    end

    it 'should have non-nil values for required fields set in initializer' do
      @doc.get(Blacklight.config[:show][:html_title]).should_not == nil
      @doc.get(Blacklight.config[:show][:heading]).should_not == nil
      @doc.get(Blacklight.config[:show][:display_type]).should_not == nil
    end

    it "should limit search result by facets when supplied" do
      doc2 = @solr_helper.get_single_doc_via_search(:q => @all_docs_query, :page => @doc_row, :f => @multi_facets)
      doc2.get(:id).should_not == nil
    end

  end

# SPECS FOR SPELLING SUGGESTIONS VIA SEARCH
  describe "Searches should return spelling suggestions" do
    it 'search results for just-poor-enough-query term should have (multiple) spelling suggestions' do
      (solr_response, document_list) = @solr_helper.get_search_results({:q => 'boo'})
      solr_response.spelling.words.should include('bon')
      solr_response.spelling.words.should include('bod')  #for multiple suggestions
    end

    it 'search results for just-poor-enough-query term should have multiple spelling suggestions' do
      (solr_response, document_list) = @solr_helper.get_search_results({:q => 'politica'})
      solr_response.spelling.words.should include('policy') # less freq
      solr_response.spelling.words.should include('politics') # more freq
      solr_response.spelling.words.should include('political') # more freq
=begin
      #  when we can have multiple suggestions
      solr_response.spelling.words.should_not include('policy') # less freq
      solr_response.spelling.words.should include('politics') # more freq
      solr_response.spelling.words.should include('political') # more freq
=end
    end

    it "title search results for just-poor-enough query term should have spelling suggestions" do
      (solr_response, document_list) = @solr_helper.get_search_results({:q => 'yehudiyam', :qt => 'search', :"spellcheck.dictionary" => "title"})
      solr_response.spelling.words.should include('yehudiyim')
    end

    it "author search results for just-poor-enough-query term should have spelling suggestions" do
      (solr_response, document_list) = @solr_helper.get_search_results({:q => 'shirma', :qt => 'search', :"spellcheck.dictionary" => "author"})
      solr_response.spelling.words.should include('sharma')
    end

    it "subject search results for just-poor-enough-query term should have spelling suggestions" do
      (solr_response, document_list) = @solr_helper.get_search_results({:q => 'wome', :qt => 'search', :"spellcheck.dictionary" => "subject"})
      solr_response.spelling.words.should include('women')
    end

    it 'search results for multiple terms query with just-poor-enough-terms should have spelling suggestions for each term' do
     pending
#     get_spelling_suggestion("histo politica").should_not be_nil
    end

  end

  describe "facet_limit_for" do

    it "should return specified value for facet_field specified" do
      @solr_helper.facet_limit_for("subject_topic_facet").should == Blacklight.config[:facet][:limits]["subject_topic_facet"]
    end
    it "@solr_helper.facet_limit_hash should return hash with key being facet_field and value being configured limit" do
      @solr_helper.facet_limit_hash.should == Blacklight.config[:facet][:limits]
    end
    it "should handle no facet_limits in config" do
      Blacklight.config[:facet][:field_names].include?("subject_topic_facet").should be_true
      Blacklight.config[:facet][:limits].has_key?("subject_topic_facet").should be_true
      @solr_helper.facet_limit_for("subject_topic_facet").should == 20
      fl = Blacklight.config[:facet][:limits]
      Blacklight.config[:facet][:limits] = nil
      @solr_helper.facet_limit_for("subject_topic_facet").should be_nil
      Blacklight.config[:facet][:limits] = fl
    end
    it "solr_search_params should handle no facet_limits in config" do
      Blacklight.config[:facet][:field_names].include?("subject_topic_facet").should be_true
      Blacklight.config[:facet][:limits].has_key?("subject_topic_facet").should be_true
      @solr_helper.solr_search_params[:"f.subject_topic_facet.facet.limit"].should == 21
      fl = Blacklight.config[:facet][:limits]
      Blacklight.config[:facet][:limits] = nil
      @solr_helper.solr_search_params.has_key?(:"f.subject_topic_facet.facet.limit").should be_false
      Blacklight.config[:facet][:limits] = fl
    end
    describe "for 'true' configured values" do
      it "should return nil if no @response available" do
        @solr_helper.facet_limit_for("some_field").should be_nil
      end
      it "should get from @response facet.limit if available" do
        @solr_helper.response = {"responseHeader" => {"params" => {"facet.limit" => 11}}}
        @solr_helper.facet_limit_for("language_facet").should == 10
      end
      it "should get from specific field in @response if available" do
        @solr_helper.response = {"responseHeader" => {"params" => {"facet.limit" => 11,"f.language_facet.facet.limit" => 16}}}
        @solr_helper.facet_limit_for("language_facet").should == 15
      end
    end
  end

    describe "with max per page enforced" do
      before do
        # Add some params
        @solr_helper_with_params = MockSolrHelperContainer.new
        @solr_helper_with_params.params = {:search_field => "test_field", :per_page => 12345, :q => "test query", "facet.field" => "extra_facet"}
      end
      after do
      end

      describe "should enforce MaxPerPage against user supplied parameters" do
        before do
          @produced_params = @solr_helper_with_params.solr_search_params
          1+1
        end
        it "should take per_page from search field definition where specified" do
          @produced_params[:per_page].should == "100"
        end
      end

      describe "should enforce MaxPerPage against extra controller parameters" do
        before do
          @produced_params = @solr_helper_with_params.solr_search_params(:per_page => 98765)
          1+1
        end
        it "should take per_page from search field definition where specified" do
          @produced_params[:per_page].should == "100"
        end
      end
    end

# TODO:  more complex queries!  phrases, offset into search results, non-latin, boosting(?)
#  search within query building (?)
#  search + facets (search done first; facet selected first, both selected)

# TODO: maybe eventually check other types of solr requests
#  more like this
#  nearby on shelf

end

