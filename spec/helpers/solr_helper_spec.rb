require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'marc'

# Because SolrHelper is a controller layer mixin,
# it depends on the methods provided by AtionController::Base
# currently, the only method that is used is #params
class MockSolrHelperContainer
  
  include Blacklight::SolrHelper
  attr_accessor :params
  
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



# SPECS FOR SEARCH RESULTS FOR QUERY
  describe 'Search Results' do

    describe 'for All Docs Query, No Facets' do
      it 'should have non-nil values for required doc fields set in initializer' do
        solr_response = @solr_helper.get_search_results(:q => @all_docs_query)
        result_docs = solr_response.docs
        document = result_docs.first
        document.get(Blacklight.config[:index][:show_link]).should_not == nil
        document.get(Blacklight.config[:index][:record_display_type]).should_not == nil
      end
    end
    
    describe "Single Word Query with no Facets" do
      it 'should have results' do
        solr_response = @solr_helper.get_search_results(:q => @single_word_query)
        solr_response.docs.size.should > 0
      end
    end

    describe "Multiple Words Query with No Facets" do
      it 'should have results' do
        solr_response = @solr_helper.get_search_results(:q => @mult_word_query)
        solr_response.docs.size.should > 0
      end
    end

    describe "One Facet, No Query" do
      it 'should have results' do
        solr_response = @solr_helper.get_search_results(:f => @single_facet)
        solr_response.docs.size.should > 0
      end
    end

    describe "Mult Facets, No Query" do
      it 'should have results' do
        solr_response = @solr_helper.get_search_results(:f => @multi_facets)
        solr_response.docs.size.should > 0
      end
    end

    describe "Single Word Query with One Facet" do
      it 'should have results' do
        solr_response = @solr_helper.get_search_results(:q => @single_word_query, :f => @single_facet)
        solr_response.docs.size.should > 0
      end
    end

    describe "Multiple Words Query with Multiple Facets" do
      it 'should have results' do
        solr_response = @solr_helper.get_search_results(:q => @mult_word_query, :f => @multi_facets)
        solr_response.docs.size.should > 0
      end
    end

    describe "for All Docs Query and One Facet" do
      it 'should have results' do
        solr_response = @solr_helper.get_search_results(:q => @all_docs_query, :f => @single_facet)
        solr_response.docs.size.should > 0
      end
      # TODO: check that number of these results < number of results for all docs query 
      #   BUT can't: num docs isn't total, it's the num docs in the single SOLR response (e.g. 10)
    end

    describe "for Query Without Results and No Facet" do
      it 'should have no results and not raise error' do
        solr_response = @solr_helper.get_search_results(:q => @no_docs_query)
        solr_response.docs.size.should == 0
      end
    end

    describe "for Query Without Results and One Facet" do
      it 'should have no results and not raise error' do
        solr_response = @solr_helper.get_search_results(:q => @no_docs_query, :f => @single_facet)
        solr_response.docs.size.should == 0
      end
    end

    describe "for All Docs Query and Bad Facet" do
      it 'should have no results and not raise error' do
        solr_response = @solr_helper.get_search_results(:q => @all_docs_query, :f => @bad_facet)
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
      solr_response = @solr_helper.get_search_results(:q => @all_docs_query)
      @facets = solr_response.facets      
    end
    
    it 'should have more than one facet' do
      @facets.size.should > 1
    end
    it 'should have all facets specified in initializer' do
      @facets.each do |facet|
        Blacklight.config[:facet][:field_names].should include(facet.name)
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
      solr_response = @solr_helper.get_search_results(:q => @all_docs_query)
      solr_response.params[:start].to_i.should == 0
    end
    it 'should have number of results (per page) set in initializer, by default' do
      solr_response = @solr_helper.get_search_results(:q => @all_docs_query)
      solr_response.docs.size.should == Blacklight.config[:index][:num_per_page]
    end

    it 'should get number of results per page requested' do
      num_results = 3  # non-default value
      solr_response1 = @solr_helper.get_search_results(:q => @all_docs_query, :per_page => num_results)
      solr_response1.docs.size.should == num_results
    end
    
    it 'should skip appropriate number of results when requested - default per page' do
      page = 3
      solr_response2 = @solr_helper.get_search_results(:q => @all_docs_query, :page => page)
      solr_response2.params[:start].to_i.should ==  Blacklight.config[:index][:num_per_page] * (page-1)
    end
    it 'should skip appropriate number of results when requested - non-default per page' do
      page = 3
      num_results = 3
      solr_response2a = @solr_helper.get_search_results(:q => @all_docs_query, :per_page => num_results, :page => page)
      solr_response2a.params[:start].to_i.should == num_results * (page-1)
    end

    it 'should have no results when prompted for page after last result' do
      big = 5000
      solr_response3 = @solr_helper.get_search_results(:q => @all_docs_query, :per_page => big, :page => big)
      solr_response3.docs.size.should == 0
    end

    it 'should show first results when prompted for page before first result' do
      # FIXME: should it show first results, or should it throw an error for view to deal w?
      #   Solr throws an error for a negative start value
      solr_response4 = @solr_helper.get_search_results(:q => @all_docs_query, :page => '-1')
      solr_response4.params[:start].to_i.should == 0
    end
    it 'should have results available when asked for more than are in response' do
      big = 5000
      solr_response5 = @solr_helper.get_search_results(:q => @all_docs_query, :per_page => big, :page => 1)
      solr_response5.docs.size.should > 0
    end
    
  end # page specs

  # SPECS FOR SINGLE DOCUMENT REQUESTS
  describe 'Get Document By Id' do
    before(:all) do
      @doc_id = '2007020969'
      @bad_id = "redrum"
      @response2 = @solr_helper.get_solr_response_for_doc_id(@doc_id)
      @document = @response2.docs.first
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

    # test whether stored marc is behaving properly
    describe "raw record marc" do
      
      it "should have initializer values for raw marc" do
        Blacklight.config[:raw_storage_field].should_not == nil
      end
    
      it "should have a non-nil value for raw_storage_field" do
        # grab the marc value for this record
        marc = @document.get(Blacklight.config[:raw_storage_field])
        marc.should_not == nil
      end
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
      solr_response = @solr_helper.get_search_results({:q => 'boo'})
      solr_response.spelling.words.should include('bon')
#      solr_response.spelling.words.should include('bod')  for multiple suggestions
    end

    it 'search results for just-poor-enough-query term should have multiple spelling suggestions' do
      solr_response = @solr_helper.get_search_results({:q => 'politica'})
      solr_response.spelling.words.should include('policy') # less freq
=begin
      #  when we can have multiple suggestions
      solr_response.spelling.words.should_not include('policy') # less freq
      solr_response.spelling.words.should include('politics') # more freq
      solr_response.spelling.words.should include('political') # more freq
=end
    end

    it "title search results for just-poor-enough query term should have spelling suggestions" do
      solr_response = @solr_helper.get_search_results({:q => 'yehudiyam', :qt => 'title_search'})
      solr_response.spelling.words.should include('yehudiyim') 
    end

    it "author search results for just-poor-enough-query term should have spelling suggestions" do
      solr_response = @solr_helper.get_search_results({:q => 'shirma', :qt => 'author_search'})
      solr_response.spelling.words.should include('sharma') 
    end

    it "subject search results for just-poor-enough-query term should have spelling suggestions" do
      solr_response = @solr_helper.get_search_results({:q => 'wome', :qt => 'subject_search'})
      solr_response.spelling.words.should include('women') 
    end

    it 'search results for multiple terms query with just-poor-enough-terms should have spelling suggestions for each term' do
#     get_spelling_suggestion("histo politica").should_not be_nil
    end

  end
  
# TODO:  more complex queries!  phrases, offset into search results, non-latin, boosting(?)
#  search within query building (?)
#  search + facets (search done first; facet selected first, both selected)

# TODO: maybe eventually check other types of solr requests
#  more like this
#  nearby on shelf 
 
end 
