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
  
  extend Blacklight::SolrHelper

  @@FLAVOR = 'DEMO'
#  @@FLAVOR = 'LOCAL'
  puts "\n\t solr FLAVOR is  *** #@@FLAVOR ***" 
  @solr_url = Blacklight.solr_config[:url]
  puts "\t SOLR url is ** #@solr_url **"

  all_docs_query = ''
  no_docs_query = 'zzzzzzzzzzzz'
  single_word_query = 'book'
  mult_word_query = 'tibetan history'
#  f[format_facet][]=Book&f[language_facet][]=English
  single_facet = {:format_facet=>'Book'}
  mult_facets = {:format_facet=>'Book', :language_facet=>'Tibetan'}
  bad_facet = {:format_facet=>'666'}

# SPECS FOR blacklight.rb contents
describe "blacklight.rb" do
  describe "solr.yml config" do
    
    it "should contain a solr_url" do
      Blacklight.solr_config[:url].should_not == nil      
    end
    
    it "should contain some display fields" do
      DisplayFields.show_view.should_not == nil
    end
    
  end
end



# SPECS FOR SEARCH RESULTS FOR QUERY
  describe 'Search Results' do

    describe 'for All Docs Query, No Facets' do
      solr_response = get_search_results(all_docs_query)
      result_docs = solr_response.docs
      it 'should have non-nil values for required doc fields set in solr.yml' do
        document = result_docs.first
        document.get(DisplayFields.index_view[:show_link]).should_not == nil
        document.get(DisplayFields.index_view[:record_display_type]).should_not == nil
      end
    end
    
    describe "for Single Word Query " + single_word_query + ", No Facets" do
      solr_response = get_search_results(single_word_query)
      it 'should have results' do
        solr_response.docs.size.should > 0
      end
    end

    describe "for Multiple Words Query " + mult_word_query + ", No Facets" do
      solr_response = get_search_results(mult_word_query)
      it 'should have results' do
        solr_response.docs.size.should > 0
      end
    end

    describe "for One Facet, No Query " + single_facet.to_s do
      solr_response = get_search_results(nil, single_facet)
      it 'should have results' do
        solr_response.docs.size.should > 0
      end
    end

    describe "for Mult Facets, No Query " + mult_facets.to_s do
      solr_response = get_search_results(nil, mult_facets)
      it 'should have results' do
        solr_response.docs.size.should > 0
      end
    end

    describe "for Single Word Query " + single_word_query + ", One Facet " + single_facet.to_s do
      solr_response = get_search_results(single_word_query, single_facet)
      it 'should have results' do
        solr_response.docs.size.should > 0
      end
    end

    describe "for Multiple Words Query " + mult_word_query + ", Mult Facets " + mult_facets.to_s do
      solr_response = get_search_results(mult_word_query, mult_facets)
      it 'should have results' do
        solr_response.docs.size.should > 0
      end
    end

    describe "for All Docs Query and One Facet" do
      solr_response = get_search_results(all_docs_query, single_facet)
      it 'should have results' do
        solr_response.docs.size.should > 0
      end
# TODO: check that number of these results < number of results for all docs query 
#   BUT can't: num docs isn't total, it's the num docs in the single SOLR response (e.g. 10)
    end

    describe "for Query Without Results and No Facet" do
      solr_response = get_search_results(no_docs_query)
      it 'should have no results and not raise error' do
        solr_response.docs.size.should == 0
      end
    end

    describe "for Query Without Results and One Facet" do
      solr_response = get_search_results(no_docs_query, single_facet)
      it 'should have no results and not raise error' do
        solr_response.docs.size.should == 0
      end
    end

    describe "for All Docs Query and Bad Facet" do
      solr_response = get_search_results(all_docs_query, bad_facet)
      it 'should have no results and not raise error' do
        solr_response.docs.size.should == 0
      end
    end
    
    describe "for default display fields" do
      it "should have a list of field names for index_view_fields" do
        DisplayFields.index_view_fields.should_not be_nil
        DisplayFields.index_view_fields[:field_names].should be_instance_of(Array)
        DisplayFields.index_view_fields[:field_names].length.should == 5
        DisplayFields.index_view_fields[:field_names][0].should == "title_t"
      end
    end


  end  # Search Results
  
  
# SPECS FOR SEARCH RESULTS FOR FACETS 
  describe 'Facets in Search Results for All Docs Query' do
    solr_response = get_search_results(all_docs_query)
    facets = solr_response.facets      
    
    it 'should have more than one facet' do
      facets.size.should > 1
    end
    it 'should have all facets specified in solr.yml' do
      facets.each do |facet|
        DisplayFields.facet[:field_names].should include(facet.name)
      end
    end
    it 'should have at least one value for each facet' do
      facets.each do |facet|
        facet.items.size.should > 0
      end
    end
    it 'should have multiple values for at least one facet' do
      has_mult_values = false
      facets.each do |facet|
        if facet.items.size > 1
          has_mult_values = true
          break
        end
      end
      has_mult_values.should == true
    end
    it 'should have all value counts > 0' do
      facets.each do |facet|
        facet.items.each do |facet_vals|
          facet_vals.hits > 0
        end
      end
    end
  end # facet specs


# SPECS FOR SEARCH RESULTS FOR PAGING
  describe 'Paging' do

    solr_response = get_search_results(all_docs_query)
    it 'should start with first results by default' do
      solr_response.params[:start].to_i.should == 0
    end
    it 'should have number of results (per page) set in solr.yml, by default' do
      solr_response.docs.size.should == DisplayFields.index_view[:num_per_page]
    end

    num_results = 3  # non-default value
    solr_response1 = get_search_results(all_docs_query, nil, num_results)
    it 'should get number of results requested' do
      solr_response1.docs.size.should == num_results
    end
    
    page = 3
    solr_response2 = get_search_results(all_docs_query, nil, nil, page)
    it 'should skip appropriate number of results when requested - default per page' do
      solr_response2.params[:start].to_i.should ==  DisplayFields.index_view[:num_per_page] * (page-1)
    end
    solr_response2a = get_search_results(all_docs_query, nil, num_results, page)
    it 'should skip appropriate number of results when requested - non-default per page' do
      solr_response2a.params[:start].to_i.should == num_results * (page-1)
    end

    big = 5000
    solr_response3 = get_search_results(all_docs_query, nil, big, big)
    it 'should have no results when prompted for page after last result' do
      solr_response3.docs.size.should == 0
    end
    solr_response4 = get_search_results(all_docs_query, nil, nil, -1)
    it 'should show first results when prompted for page before first result' do
# FIXME: should it show first results, or should it throw an error for view to deal w?
#   Solr throws an error for a negative start value
      solr_response4.params[:start].to_i.should == 0
    end
    solr_response5 = get_search_results(all_docs_query, nil, big, 1)
    it 'should have results available when asked for more than are in response' do
      solr_response5.docs.size.should > 0
    end
    
  end # page specs

# SPECS FOR SINGLE DOCUMENT REQUESTS
  describe 'Get Document By Id' do
    doc_id = case @@FLAVOR
      when 'DEMO' then '2007020969'
      when 'LOCAL' then '5666387'
    end
    bad_id = "redrum"

    response1 = get_solr_response_for_doc_id(bad_id)
    it "should have no documents in the response for an unknown id " + bad_id do
      response1.docs.size.should == 0
    end
    
    response2 = get_solr_response_for_doc_id(doc_id)
    document = response2.docs.first
    
    it "should have a non-nil result for a known id " + doc_id do
      document.should_not == nil
    end
    it "should have a single document in the response for a known id " + doc_id do
      response2.docs.size.should == 1
    end
    it 'should have the expected value in the id field' do
      document.get(:id).should == doc_id
    end
    it 'should have non-nil values for required fields set in solr.yml' do
      document.get(DisplayFields.show_view[:html_title]).should_not == nil
      document.get(DisplayFields.show_view[:heading]).should_not == nil
      document.get(DisplayFields.show_view[:display_type]).should_not == nil
    end
    it "should have a list of field names for show_view_fields" do
      DisplayFields.show_view_fields.should_not be_nil
      DisplayFields.show_view_fields[:field_names].should be_instance_of(Array)
      DisplayFields.show_view_fields[:field_names].length.should == 5
      DisplayFields.show_view_fields[:field_names][0].should == "title_t"
    end
    require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

    # test whether stored marc is behaving properly
    describe "marc record storage" do
      
      it "should have solr.yml values for marc storage" do
        DisplayFields.marc_storage_field.should == 'marc_display'
      end
    
      # grab the marc value for this record
      marc = document[DisplayFields.marc_storage_field]

      it "should have a non-nil value for marc_storage_field" do
        marc.should_not == nil
      end
    end
    
  end

# NOTE: some of these repeated fields could be in a shared behavior, but the
#  flow of control is such that the variables can't be instance variables
#  (or at least not for me - Naomi)

# SPECS FOR SINGLE DOCUMENT VIA SEARCH
  describe "Get Document Via Search" do

    doc_row = 3
    doc = get_single_doc_via_search(all_docs_query, doc_row)
=begin
# can't test these here, because the method only returns the document
    it "should get a single document" do
      response.docs.size.should == 1
    end

    doc2 = get_single_doc_via_search(all_docs_query, doc_row, mult_facets)
    it "should limit search result by facets when supplied" do
      response2.docs.numFound.should_be < response.docs.numFound
    end
    
    it "should not have facets in the response" do
      response.facets.size.should == 0
    end
=end

    it 'should have a doc id field' do
      doc.get(:id).should_not == nil
    end
    
    it 'should have non-nil values for required fields set in solr.yml' do
      doc.get(DisplayFields.show_view[:html_title]).should_not == nil
      doc.get(DisplayFields.show_view[:heading]).should_not == nil
      doc.get(DisplayFields.show_view[:display_type]).should_not == nil
    end

    doc2 = get_single_doc_via_search(all_docs_query, doc_row, mult_facets)
    it "should limit search result by facets when supplied" do
      doc2.get(:id).should_not == nil
    end

  end


# TODO:  more complex queries!  phrases, offset into search results, non-latin, boosting(?)
#  search within query building (?)
#  search + facets (search done first; facet selected first, both selected)

# TODO: maybe eventually check other types of solr requests
#  spell checker
#  more like this
#  nearby on shelf 
 
end 
