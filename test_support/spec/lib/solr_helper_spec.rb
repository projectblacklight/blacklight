# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'marc'




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

  # SolrHelper is a controller layer mixin, which depends
  # on being mixed into a class which has #params (from Rails)
  # and #blacklight_config
  def params
    {}
  end

  def blacklight_config
    @config ||= CatalogController.blacklight_config
  end
  
  def blacklight_config=(config)
    @config = config
  end

  include Blacklight::SolrHelper

  before(:each) do
    @all_docs_query = ''
    @no_docs_query = 'zzzzzzzzzzzz'
    @single_word_query = 'include'
    @mult_word_query = 'tibetan history'
  #  f[format][]=Book&f[language_facet][]=English
    @single_facet = {:format=>'Book'}
    @multi_facets = {:format=>'Book', :language_facet=>'Tibetan'}
    @bad_facet = {:format=>'666'}
    @subject_search_params = {:commit=>"search", :search_field=>"subject", :action=>"index", :"controller"=>"catalog", :"rows"=>"10", :"q"=>"wome"}
  end

  

  # SPECS for actual search parameter generation
  describe "solr_search_params" do
    it "allows customization of solr_search_params_logic" do
        # Normally you'd include a new module into (eg) your CatalogController
        # but a sub-class defininig it directly is simpler for test.             
        def add_foo_to_solr_params(solr_params, user_params)
          solr_params[:foo] = "TESTING"
        end
 
                         
        self.solr_search_params_logic += [:add_foo_to_solr_params]
        
        
        self.solr_search_params[:foo].should == "TESTING"                
    end
    
    
    describe 'for an entirely empty search' do
       def params
          {}
        end
      before do
        @produced_params = self.solr_search_params
      end
      it 'should not have a q param' do
        @produced_params[:q].should be_nil
        @produced_params["spellcheck.q"].should be_nil
      end
      it 'should have default rows' do
        @produced_params[:rows].should == 10
      end
      it 'should have default facet fields' do
        @produced_params[:"facet.field"].should == blacklight_config.facet_fields_to_add_to_solr
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
        solr_params = solr_search_params(:q => "")
        solr_params[:q].should == ""
        solr_params["spellcheck.q"].should == ""
      end
    end

    describe "for request params also passed in as argument" do      
      it "should only have one 'q' key, as symbol" do        
        solr_params = solr_search_params( :q => "some query" )
        solr_params.keys.should include(:q)
        solr_params.keys.should_not include("q")
      end
    end


    describe "for one facet, no query" do
      it "should have proper solr parameters" do

        solr_params = solr_search_params(:f => @single_facet)

        solr_params[:q].should be_blank
        solr_params["spellcheck.q"].should be_blank
        solr_params[:"facet.field"].should == blacklight_config.facet_fields_to_add_to_solr

        @single_facet.each_value do |value|
          solr_params[:fq].should include("{!raw f=#{@single_facet.keys[0]}}#{value}")
        end
      end
    end

    describe "with Multi Facets, No Query" do
      it 'should have fq set properly' do
        solr_params = solr_search_params(:f => @multi_facets)

        @multi_facets.each_pair do |facet_field, value_list|
          value_list ||= []
          value_list = [value_list] unless value_list.respond_to? :each
          value_list.each do |value|
            solr_params[:fq].should include("{!raw f=#{facet_field}}#{value}"  )
          end
        end

      end
    end

    describe "with Multi Facets, Multi Word Query" do
      it 'should have fq and q set properly' do
        solr_params = solr_search_params(:q => @mult_word_query, :f => @multi_facets)

        @multi_facets.each_pair do |facet_field, value_list|
          value_list ||= []
          value_list = [value_list] unless value_list.respond_to? :each
          value_list.each do |value|
            solr_params[:fq].should include("{!raw f=#{facet_field}}#{value}"  )
          end
        end
        solr_params[:q].should == @mult_word_query
      end
    end

    describe "facet_value_to_fq_string", :focus => true do
      it "should use the raw handler for strings" do
        facet_value_to_fq_string("facet_name", "my value").should  == "{!raw f=facet_name}my value" 
      end

      it "should pass booleans through" do
        facet_value_to_fq_string("facet_name", true).should  == "facet_name:true"
      end

      it "should pass boolean-like strings through" do
        facet_value_to_fq_string("facet_name", "true").should  == "facet_name:true"
      end

      it "should pass integers through" do
        facet_value_to_fq_string("facet_name", 1).should  == "facet_name:1"
      end

      it "should pass integer-like strings through" do
        facet_value_to_fq_string("facet_name", "1").should  == "facet_name:1"
      end

      it "should pass floats through" do
        facet_value_to_fq_string("facet_name", 1.11).should  == "facet_name:1.11"
      end

      it "should pass floats through" do
        facet_value_to_fq_string("facet_name", "1.11").should  == "facet_name:1.11"
      end

      it "should handle range requests" do
        facet_value_to_fq_string("facet_name", 1..5).should  == "facet_name:[1 TO 5]"
      end
    end

    describe "solr parameters for a field search from config (subject)" do
      before do
        @solr_params = solr_search_params( @subject_search_params )
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
        @solr_params[:"facet.field"].should == blacklight_config.facet_fields_to_add_to_solr
      end
      it "should include spellcheck.dictionary from field def solr_parameters" do
        @solr_params[:"spellcheck.dictionary"].should == "subject"
      end
      it "should add on :solr_local_parameters using Solr LocalParams style" do
        params = solr_search_params( @subject_search_params )

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
        def params
          super.merge(:qt => "overridden")
        end
        
        solr_search_params[:qt].should == "overridden"        
      end
    end

    describe "with a complex parameter environment" do
      def blacklight_config          
        config = Blacklight::Configuration.new
        config.add_search_field("test_field",
                             :display_label => "Test", 
                             :key=>"test_field", 
                             :solr_parameters => {:qf => "fieldOne^2.3 fieldTwo fieldThree^0.4", :pf => "", :spellcheck => 'false', :rows => "55", :sort => "request_params_sort" }
                            )
        return config
      end
      def params          
        {:search_field => "test_field", :q => "test query", "facet.field" => "extra_facet"}
      end
      
      it "should merge parameters from search_field definition" do
        solr_params = solr_search_params
        
        solr_params[:qf].should == "fieldOne^2.3 fieldTwo fieldThree^0.4"
        solr_params[:spellcheck].should == 'false'
      end
      it "should merge empty string parameters from search_field definition" do
        solr_search_params[:pf].should == ""        
      end

      describe "should respect proper precedence of settings, " do
        before do
          @produced_params = solr_search_params
        end


        it "should not put :search_field in produced params" do
          @produced_params[:search_field].should be_nil
        end

        it "should fall through to BL general defaults for qt not otherwise specified " do
          @produced_params[:qt].should == blacklight_config[:default_solr_params][:qt]
        end

        it "should take rows from search field definition where specified" do
          @produced_params[:rows].should == "55"
        end

        it "should take q from request params" do
          @produced_params[:q].should == "test query"
        end

        it "should add in extra facet.field from params" do
          @produced_params[:"facet.field"].should include("extra_facet")
        end

      end
    end

    describe "sorting" do
      
      it "should send the default sort parameter to solr" do                        
        solr_search_params[:sort].should == 'score desc, pub_date_sort desc, title_sort asc'        
      end

      it "should not send a sort parameter to solr if the sort value is blank" do
        def blacklight_config          
          config = Blacklight::Configuration.new
          config.add_sort_field('', :label => 'test')
          return config
        end

        produced_params = solr_search_params
        produced_params.should_not have_key(:sort)
      end

      it "should pass through user sort parameters" do
        produced_params = solr_search_params( :sort => 'solr_test_field desc' )
        produced_params[:sort].should == 'solr_test_field desc'
      end
    end

    describe "for :solr_local_parameters config" do
      def blacklight_config          
        config = Blacklight::Configuration.new
        config.add_search_field(
          "custom_author_key",
          :display_label => "Author",
          :qt => "author_qt",
          :key => "custom_author_key",
          :solr_local_parameters => {
            :qf => "$author_qf",
            :pf => "you'll have \" to escape this"
          },
          :solr_parameters => {
            :qf => "someField^1000",
            :ps => "2"
          }
        )
        return config
      end
      
      def params        
        {:search_field => "custom_author_key", :q => "query"}
      end
      
      before do
        @result = solr_search_params
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
    end
    
    describe "mapping facet.field" do
      it "should add single additional facet.field from app" do
        solr_params = solr_search_params( "facet.field" => "additional_facet" )
        solr_params[:"facet.field"].should include("additional_facet")
        solr_params[:"facet.field"].length.should > 1
      end
      it "should map multiple facet.field to additional facet.field" do
        solr_params = solr_search_params( "facet.field" => ["add_facet1", "add_facet2"] )
        solr_params[:"facet.field"].should include("add_facet1")
        solr_params[:"facet.field"].should include("add_facet2")
        solr_params[:"facet.field"].length.should > 2
      end
      it "should map facets[fields][] to additional facet.field" do
        solr_params = solr_search_params( "facets" => ["add_facet1", "add_facet2"] )
        solr_params[:"facet.field"].should include("add_facet1")
        solr_params[:"facet.field"].should include("add_facet2")
        solr_params[:"facet.field"].length.should > 2
      end
    end

 end

  describe "solr_facet_params" do
    before do
      @facet_field = 'format'
      @generated_solr_facet_params = solr_facet_params(@facet_field)

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
      solr_params = solr_facet_params(@facet_field, @offset_key => "100")
      solr_params['facet.offset'].should == 100
    end
    it 'defaults limit to 20' do
      solr_params = solr_facet_params(@facet_field)
      solr_params[:"f.#{@facet_field}.facet.limit"].should == 21
    end
    describe 'if facet_list_limit is defined in controller' do
      def facet_list_limit
        1000
      end
      it 'uses controller method for limit' do
        solr_params = solr_facet_params(@facet_field)
        solr_params[:"f.#{@facet_field}.facet.limit"].should == 1001
      end
    end
    it 'uses sort set manually' do
      solr_params = solr_facet_params(@facet_field, @sort_key => "index")
      solr_params['facet.sort'].should == 'index'
    end
    it "comes up with the same params as #solr_search_params to constrain context for facet list" do
      search_params = {:q => 'tibetan history', :f=> {:format=>'Book', :language_facet=>'Tibetan'}}
      solr_search_params = solr_search_params( search_params )
      solr_facet_params = solr_facet_params('format', search_params)

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
    def params
      {:search_field => "test_field", :q => "test query"}
    end
    
    
    before do            
      @generated_params = solr_search_params
    end
    
    it "should include specifically configged facet limits +1" do
      @generated_params[:"f.subject_topic_facet.facet.limit"].should == 21      
    end
    it "should not include a facet limit for a nil key in hash" do
      @generated_params.should_not have_key(:"f.format.facet.limit")
      @generated_params.should_not have_key(:"facet.limit")
    end
  end
  
   describe "get_facet_pagination", :integration => true do
    before(:each) do
      @facet_paginator = get_facet_pagination(@facet_field)
    end
    it 'should return a facet paginator' do
      @facet_paginator.should be_a_kind_of(Blacklight::Solr::FacetPaginator)
    end
    it 'with a limit set' do
      @facet_paginator.limit.should_not be_nil
    end
   end

# SPECS FOR SEARCH RESULTS FOR QUERY
  describe 'Search Results', :integration => true do

    describe 'for a sample query returning results' do

      before(:all) do        
        (@solr_response, @document_list) = get_search_results(:q => @all_docs_query)
      end

      it "should use the configured request handler " do
        require 'ostruct'
        blacklight_config.stub(:solr_request_handler => 'custom_request_handler')
        self.should_receive(:find).with('custom_request_handler', anything).and_return(OpenStruct.new( :docs => [{}] ))
        get_search_results(:q => @all_docs_query)
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
        (solr_response, document_list) = get_search_results(:q => @all_docs_query)
        result_docs = document_list
        document = result_docs.first
        document.get(blacklight_config.index.show_link).should_not == nil
        document.get(blacklight_config.index.record_display_type).should_not == nil
      end
    end



    describe "Single Word Query with no Facets" do
      it 'should have results' do
        (solr_response, document_list) = get_search_results(:q => @single_word_query)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
    end

    describe "Multiple Words Query with No Facets" do
      it 'should have results' do

        (solr_response, document_list) = get_search_results(:q => @mult_word_query)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
    end

    describe "One Facet, No Query" do
      it 'should have results' do
        (solr_response, document_list) = get_search_results(:f => @single_facet)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
    end

    describe "Mult Facets, No Query" do
      it 'should have results' do
        (solr_response, document_list) = get_search_results(:f => @multi_facets)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
    end

    describe "Single Word Query with One Facet" do
      it 'should have results' do
        (solr_response, document_list) = get_search_results(:q => @single_word_query, :f => @single_facet)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
    end

    describe "Multiple Words Query with Multiple Facets" do
      it 'should have results' do
        (solr_response, document_list) = get_search_results(:q => @mult_word_query, :f => @multi_facets)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
    end

    describe "for All Docs Query and One Facet" do
      it 'should have results' do
        (solr_response, document_list) = get_search_results(:q => @all_docs_query, :f => @single_facet)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should > 0
      end
      # TODO: check that number of these results < number of results for all docs query
      #   BUT can't: num docs isn't total, it's the num docs in the single SOLR response (e.g. 10)
    end

    describe "for Query Without Results and No Facet" do
      it 'should have no results and not raise error' do
        (solr_response, document_list) = get_search_results(:q => @no_docs_query)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should == 0
      end
    end

    describe "for Query Without Results and One Facet" do
      it 'should have no results and not raise error' do
        (solr_response, document_list) = get_search_results(:q => @no_docs_query, :f => @single_facet)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should == 0
      end
    end

    describe "for All Docs Query and Bad Facet" do
      it 'should have no results and not raise error' do
        (solr_response, document_list) = get_search_results(:q => @all_docs_query, :f => @bad_facet)
        solr_response.docs.size.should == document_list.size
        solr_response.docs.size.should == 0
      end
    end




  end  # Search Results


# SPECS FOR SEARCH RESULTS FOR FACETS
  describe 'Facets in Search Results for All Docs Query', :integration => true do

    before(:all) do
      (solr_response, document_list) = get_search_results(:q => @all_docs_query)
      @facets = solr_response.facets
    end

    it 'should have more than one facet' do
      @facets.size.should > 1
    end
    it 'should have all facets specified in initializer' do      
      blacklight_config.facet_fields_to_add_to_solr.each do |field|
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
  describe 'Paging', :integration => true do

    it 'should start with first results by default' do
      (solr_response, document_list) = get_search_results(:q => @all_docs_query)
      solr_response.params[:start].to_i.should == 0
    end
    it 'should have number of results (per page) set in initializer, by default' do
      (solr_response, document_list) = get_search_results(:q => @all_docs_query)
      solr_response.docs.size.should == document_list.size
      solr_response.docs.size.should == blacklight_config[:default_solr_params][:rows]
    end

    it 'should get number of results per page requested' do
      num_results = 3  # non-default value
      (solr_response1, document_list1) = get_search_results(:q => @all_docs_query, :per_page => num_results)
      solr_response1.docs.size.should == document_list1.size
      solr_response1.docs.size.should == num_results
    end

    it 'should skip appropriate number of results when requested - default per page' do
      page = 3
      (solr_response2, document_list2) = get_search_results(:q => @all_docs_query, :page => page)
      solr_response2.params[:start].to_i.should ==  blacklight_config[:default_solr_params][:rows] * (page-1)
    end
    it 'should skip appropriate number of results when requested - non-default per page' do
      page = 3
      num_results = 3
      (solr_response2a, document_list2a) = get_search_results(:q => @all_docs_query, :per_page => num_results, :page => page)
      solr_response2a.params[:start].to_i.should == num_results * (page-1)
    end

    it 'should have no results when prompted for page after last result' do
      big = 5000
      (solr_response3, document_list3) = get_search_results(:q => @all_docs_query, :rows => big, :page => big)
      solr_response3.docs.size.should == document_list3.size
      solr_response3.docs.size.should == 0
    end

    it 'should show first results when prompted for page before first result' do
      # FIXME: should it show first results, or should it throw an error for view to deal w?
      #   Solr throws an error for a negative start value
      (solr_response4, document_list4) = get_search_results(:q => @all_docs_query, :page => '-1')
      solr_response4.params[:start].to_i.should == 0
    end
    it 'should have results available when asked for more than are in response' do
      big = 5000
      (solr_response5, document_list5) = get_search_results(:q => @all_docs_query, :rows => big, :page => 1)
      solr_response5.docs.size.should == document_list5.size
      solr_response5.docs.size.should > 0
    end

  end # page specs

  # SPECS FOR SINGLE DOCUMENT REQUESTS
  describe 'Get Document By Id', :integration => true do
    before(:all) do
      @doc_id = '2007020969'
      @bad_id = "redrum"
      @response2, @document = get_solr_response_for_doc_id(@doc_id)
    end

    it "should raise Blacklight::InvalidSolrID for an unknown id" do
      lambda {
        get_solr_response_for_doc_id(@bad_id)
      }.should raise_error(Blacklight::Exceptions::InvalidSolrID)
    end

    it "should use a provided document request handler " do
      require 'ostruct'
      blacklight_config.stub(:document_solr_request_handler => 'document')
      self.should_receive(:find).with('document', anything).and_return(OpenStruct.new( :docs => [{}] ))
      get_solr_response_for_doc_id(@doc_id)
    end

    it "should have a non-nil result for a known id" do
      @document.should_not == nil
    end
    it "should have a single document in the response for a known id" do
      @response2.docs.size.should == 1
    end
    it 'should have the expected value in the id field' do
      @document.id.should == @doc_id
    end
    it 'should have non-nil values for required fields set in initializer' do
      @document.get(blacklight_config[:show][:html_title]).should_not == nil
      @document.get(blacklight_config[:show][:heading]).should_not == nil
      @document.get(blacklight_config[:show][:display_type]).should_not == nil
    end
  end

  describe "solr_doc_params" do
    it "should default to using the 'document' requestHandler" do
      doc_params = solr_doc_params('asdfg')
      doc_params[:qt].should == 'document'
    end


    describe "blacklight config's default_document_solr_parameters" do
      def blacklight_config          
        config = Blacklight::Configuration.new
        config.default_document_solr_params = { :qt => 'my_custom_handler', :asdf => '1234' }
        config
      end

      it "should use parameters from the controller's default_document_solr_parameters" do
        doc_params = solr_doc_params('asdfg')
        doc_params[:qt].should == 'my_custom_handler'
        doc_params[:asdf].should == '1234'
      end
    end

  end

  describe "Get Document by custom unique id" do
=begin    
    # Can't test this properly without updating the "document" request handler in solr
    it "should respect the configuration-supplied unique id" do
      SolrDocument.should_receive(:unique_key).and_return("title_display")
      @response, @document = @solr_helper.get_solr_response_for_doc_id('"Strong Medicine speaks"')
      @document.id.should == '"Strong Medicine speaks"'
      @document.get(:id).should == 2007020969
    end
=end
    it "should respect the configuration-supplied unique id" do
      doc_params = solr_doc_params('"Strong Medicine speaks"')
      doc_params[:id].should == '"Strong Medicine speaks"'
    end
  end



# SPECS FOR SINGLE DOCUMENT VIA SEARCH
  describe "Get Document Via Search", :integration => true do
    before(:all) do
      @doc_row = 3
      @doc = get_single_doc_via_search(@doc_row, :q => @all_docs_query)
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
      @doc[:id].should_not == nil
    end

    it 'should have non-nil values for required fields set in initializer' do
      @doc[blacklight_config.show.html_title].should_not == nil
      @doc[blacklight_config.show.heading].should_not == nil
      @doc[blacklight_config.show.display_type].should_not == nil
    end

    it "should limit search result by facets when supplied" do
      doc2 = get_single_doc_via_search(@doc_row , :q => @all_docs_query, :f => @multi_facets)
      doc2[:id].should_not == nil
    end

  end

# SPECS FOR SPELLING SUGGESTIONS VIA SEARCH
  describe "Searches should return spelling suggestions", :integration => true do
    it 'search results for just-poor-enough-query term should have (multiple) spelling suggestions' do
      (solr_response, document_list) = get_search_results({:q => 'boo'})
      solr_response.spelling.words.should include('bon')
      solr_response.spelling.words.should include('bod')  #for multiple suggestions
    end

    it 'search results for just-poor-enough-query term should have multiple spelling suggestions' do
      (solr_response, document_list) = get_search_results({:q => 'politica'})
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
      (solr_response, document_list) = get_search_results({:q => 'yehudiyam', :qt => 'search', :"spellcheck.dictionary" => "title"})
      solr_response.spelling.words.should include('yehudiyim')
    end

    it "author search results for just-poor-enough-query term should have spelling suggestions" do
      (solr_response, document_list) = get_search_results({:q => 'shirma', :qt => 'search', :"spellcheck.dictionary" => "author"})
      solr_response.spelling.words.should include('sharma')
    end

    it "subject search results for just-poor-enough-query term should have spelling suggestions" do
      (solr_response, document_list) = get_search_results({:q => 'wome', :qt => 'search', :"spellcheck.dictionary" => "subject"})
      solr_response.spelling.words.should include('women')
    end

    it 'search results for multiple terms query with just-poor-enough-terms should have spelling suggestions for each term' do
     pending
#     get_spelling_suggestion("histo politica").should_not be_nil
    end

  end

  describe "facet_limit_for" do

    it "should return specified value for facet_field specified" do
      facet_limit_for("subject_topic_facet").should == blacklight_config.facet_fields["subject_topic_facet"].limit
    end
    it "should generate proper solr param" do
      solr_search_params[:"f.subject_topic_facet.facet.limit"].should == 21
    end
    
    it "facet_limit_hash should return hash with key being facet_field and value being configured limit" do
      # facet_limit_hash has been removed from solrhelper in refactor. should it go back?
      pending "facet_limit_hash has been removed from solrhelper in refactor. should it go back?"
      facet_limit_hash.should == blacklight_config[:facet][:limits]
    end
    it "should handle no facet_limits in config" do
      def blacklight_config
        config = super.inheritable_copy
        config.facet_fields = {}
        return config
      end
            
      facet_limit_for("subject_topic_facet").should be_nil
      
      solr_search_params.should_not have_key(:"f.subject_topic_facet.facet.limit")
      
    end
    
    describe "for 'true' configured values" do
      it "should return nil if no @response available" do
        facet_limit_for("some_unknown_field").should be_nil
      end
      it "should get from @response facet.limit if available" do        
        # Okay, this is cheesy, since we included SolrHelper directly
        # into our example groups, we need to set an iVar here, so it will
        # use it. 
        @response = {"responseHeader" => {"params" => {"facet.limit" => 11}}}        
        facet_limit_for("language_facet").should == 10
      end
      it "should get from specific field in @response if available" do
        @response = {"responseHeader" => {"params" => {"facet.limit" => 11,"f.language_facet.facet.limit" => 16}}}
        facet_limit_for("language_facet").should == 15
      end
    end
  end

    describe "with max per page enforced" do
      def blacklight_config          
        config = Blacklight::Configuration.new
        config.max_per_page = 123
        return config
      end

      it "should enforce max_per_page against all parameters" do
        blacklight_config.max_per_page.should == 123
        solr_search_params(:per_page => 98765)[:rows].should == 123
      end              
    end

    describe "#get_solr_response_for_field_values" do
      before do
        @mock_response = mock()
        @mock_response.stub(:docs => [])
      end
      it "should contruct a solr query based on the field and value pair" do
        self.should_receive(:find).with(an_instance_of(String), hash_including(:q => "field_name:(value)")).and_return(@mock_response)
        get_solr_response_for_field_values('field_name', 'value')
      end

      it "should OR multiple values together" do
        self.should_receive(:find).with(an_instance_of(String), hash_including(:q => "field_name:(a OR b)")).and_return(@mock_response)
        get_solr_response_for_field_values('field_name', ['a', 'b'])
      end

      it "should escape crazy identifiers" do
        self.should_receive(:find).with(an_instance_of(String), hash_including(:q => "field_name:(\"h://\\\"\\\'\")")).and_return(@mock_response)
        get_solr_response_for_field_values('field_name', 'h://"\'')
      end
    end

# TODO:  more complex queries!  phrases, offset into search results, non-latin, boosting(?)
#  search within query building (?)
#  search + facets (search done first; facet selected first, both selected)

# TODO: maybe eventually check other types of solr requests
#  more like this
#  nearby on shelf
  it "should raise a Blacklight exception if RSolr can't connect to the Solr instance" do
    Blacklight.solr.stub!(:find).and_raise(Errno::ECONNREFUSED)
    expect { find(:a => 123) }.to raise_exception(/Unable to connect to Solr instance/)
  end
end

