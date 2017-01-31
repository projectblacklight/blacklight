# frozen_string_literal: true

# check the methods that do solr requests. Note that we are not testing if
#  solr gives "correct" responses, as that's out of scope (it's a part of
#  testing the solr code itself).  We *are* testing if blacklight code sends
#  queries to solr such that it gets appropriate results. When a user does a search,
#  do we get data back from solr (i.e. did we properly configure blacklight code
#  to talk with solr and get results)? when we do a document request, does
#  blacklight code get a single document returned?)
#
describe Blacklight::SearchService do

  let(:service) { described_class.new(blacklight_config) }
  subject { service }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:copy_of_catalog_config) { ::CatalogController.blacklight_config.deep_copy }
  let(:blacklight_solr) { RSolr.connect(Blacklight.connection_config.except(:adapter)) }

  let(:all_docs_query) { '' }
  let(:no_docs_query) { 'zzzzzzzzzzzz' }
  #  f[format][]=Book&f[language_facet][]=English
  let(:single_facet) { { format: 'Book' } }

  before do
    allow(service).to receive(:repository).and_return(Blacklight::Solr::Repository.new(blacklight_config))
    service.repository.connection = blacklight_solr
  end

  # SPECS FOR SEARCH RESULTS FOR QUERY
  describe 'Search Results', :integration => true do

    let(:blacklight_config) { copy_of_catalog_config }
    describe 'for a sample query returning results' do

      before do
        (@solr_response, @document_list) = service.search_results(q: all_docs_query)
      end

      it "uses the configured request handler" do
        allow(blacklight_config).to receive(:default_solr_params).and_return({:qt => 'custom_request_handler'})
        allow(blacklight_solr).to receive(:send_and_receive) do |path, params|
          expect(path).to eq 'select'
          expect(params[:params]['facet.field']).to eq ["format", "{!ex=pub_date_single}pub_date", "subject_topic_facet", "language_facet", "lc_1letter_facet", "subject_geo_facet", "subject_era_facet"]
          expect(params[:params]["facet.query"]).to eq ["pub_date:[#{5.years.ago.year} TO *]", "pub_date:[#{10.years.ago.year} TO *]", "pub_date:[#{25.years.ago.year} TO *]"]
          expect(params[:params]).to include('rows' => 10, 'qt'=>"custom_request_handler", 'q'=>"", "f.subject_topic_facet.facet.limit"=>21, 'sort'=>"score desc, pub_date_sort desc, title_sort asc")
        end.and_return({'response'=>{'docs'=>[]}})
        service.search_results(q: all_docs_query)
      end

      it 'has a @response.docs list of the same size as @document_list' do
        expect(@solr_response.docs).to have(@document_list.length).docs
      end

      it 'has @response.docs list representing same documents as SolrDocuments in @document_list' do
        @solr_response.docs.each_index do |index|
          mash = @solr_response.docs[index]
          solr_document = @document_list[index]

          expect(Set.new(mash.keys)).to eq Set.new(solr_document.keys)

          mash.keys.each do |key|
            expect(mash[key]).to eq solr_document[key]
          end
        end
      end
    end

    describe "for a query returning a grouped response" do
      let(:blacklight_config) { copy_of_catalog_config }
      before do
        blacklight_config.default_solr_params[:group] = true
        blacklight_config.default_solr_params[:'group.field'] = 'pub_date_sort'
        (@solr_response, @document_list) = service.search_results(q: all_docs_query)
      end

      it "has an empty document list" do
        expect(@document_list).to be_empty
      end

      it "returns a grouped response" do
        expect(@solr_response).to be_a_kind_of Blacklight::Solr::Response::GroupResponse

      end
    end

    describe "for a query returning multiple groups", integration: true do
      let(:blacklight_config) { copy_of_catalog_config }

      before do
        allow(subject).to receive_messages grouped_key_for_results: 'title_sort'
        blacklight_config.default_solr_params[:group] = true
        blacklight_config.default_solr_params[:'group.field'] = ['pub_date_sort', 'title_sort']
        (@solr_response, @document_list) = service.search_results(q: all_docs_query)
      end

      it "has an empty document list" do
        expect(@document_list).to be_empty
      end

      it "returns a grouped response" do
        expect(@solr_response).to be_a_kind_of Blacklight::Solr::Response::GroupResponse
        expect(@solr_response.group_field).to eq "title_sort"
      end
    end


    describe "for All Docs Query and One Facet" do
      it 'has results' do
        (solr_response, document_list) = service.search_results(q: all_docs_query, f: single_facet)
        expect(solr_response.docs).to have(document_list.size).results
        expect(solr_response.docs).to have_at_least(1).result
      end
      # TODO: check that number of these results < number of results for all docs query
      #   BUT can't: num docs isn't total, it's the num docs in the single SOLR response (e.g. 10)
    end

    describe "for Query Without Results and No Facet" do
      it 'has no results and not raise error' do
        (solr_response, document_list) = service.search_results(q: no_docs_query)
        expect(document_list).to have(0).results
        expect(solr_response.docs).to have(0).results
      end
    end

    describe "for Query Without Results and One Facet" do
      it 'has no results and not raise error' do
        (solr_response, document_list) = service.search_results(q: no_docs_query, f: single_facet)
        expect(document_list).to have(0).results
        expect(solr_response.docs).to have(0).results
      end
    end

    describe "for All Docs Query and Bad Facet" do
      let(:bad_facet) { { format: '666' } }

      it 'has no results and not raise error' do
        (solr_response, document_list) = service.search_results(q: all_docs_query, f: bad_facet)
        expect(document_list).to have(0).results
        expect(solr_response.docs).to have(0).results
      end
    end
  end  # Search Results


  # SPECS FOR SEARCH RESULTS FOR FACETS
  describe 'Facets in Search Results for All Docs Query', :integration => true do

    let(:blacklight_config) { copy_of_catalog_config }

    before do
      (solr_response, document_list) = service.search_results(q: all_docs_query)
      @facets = solr_response.aggregations
    end

    it 'has more than one facet' do
      expect(@facets).to have_at_least(1).facet
    end
    it 'has all facets specified in initializer' do
      expect(@facets.keys).to include *blacklight_config.facet_fields.keys
      expect(@facets.none? { |k, v| v.nil? }).to eq true
    end

    it 'has at least one value for each facet' do
      @facets.each do |key, facet|
        expect(facet.items).to have_at_least(1).hit
      end
    end
    it 'has multiple values for at least one facet' do
      has_mult_values = false
      @facets.each do |key, facet|
        if facet.items.size > 1
          has_mult_values = true
          break
        end
      end
      expect(has_mult_values).to eq true
    end
    it 'has all value counts > 0' do
      @facets.each do |key, facet|
        facet.items.each do |facet_vals|
          expect(facet_vals.hits).to be > 0
        end
      end
    end
  end # facet specs


  # SPECS FOR SEARCH RESULTS FOR PAGING
  describe 'Paging', :integration => true do
    let(:blacklight_config) { copy_of_catalog_config }

    it 'starts with first results by default' do
      (solr_response, document_list) = service.search_results(q: all_docs_query)
      expect(solr_response.params[:start].to_i).to eq 0
    end
    it 'has number of results (per page) set in initializer, by default' do
      (solr_response, document_list) = service.search_results(q: all_docs_query)
      expect(solr_response.docs).to have(blacklight_config[:default_solr_params][:rows]).items
      expect(document_list).to have(blacklight_config[:default_solr_params][:rows]).items
    end

    it 'gets number of results per page requested' do
      num_results = 3  # non-default value
      (solr_response1, document_list1) = service.search_results(q: all_docs_query, per_page: num_results)
      expect(document_list1).to have(num_results).docs
      expect(solr_response1.docs).to have(num_results).docs
    end

    it 'gets number of rows requested' do
      num_results = 4  # non-default value
      (solr_response1, document_list1) = service.search_results(q: all_docs_query, rows: num_results)
      expect(document_list1).to have(num_results).docs
      expect(solr_response1.docs).to have(num_results).docs
    end

    it 'skips appropriate number of results when requested - default per page' do
      page = 3
      (solr_response2, document_list2) = service.search_results(q: all_docs_query, page: page)
      expect(solr_response2.params[:start].to_i).to eq  blacklight_config[:default_solr_params][:rows] * (page-1)
    end
    it 'skips appropriate number of results when requested - non-default per page' do
      page = 3
      num_results = 3
      (solr_response2a, document_list2a) = service.search_results(q: all_docs_query, per_page: num_results, page: page)
      expect(solr_response2a.params[:start].to_i).to eq num_results * (page-1)
    end

    it 'has no results when prompted for page after last result' do
      big = 5000
      (solr_response3, document_list3) = service.search_results(q: all_docs_query, rows: big, page: big)
      expect(document_list3).to have(0).docs
      expect(solr_response3.docs).to have(0).docs
    end

    it 'shows first results when prompted for page before first result' do
      # FIXME: should it show first results, or should it throw an error for view to deal w?
      #   Solr throws an error for a negative start value
      (solr_response4, document_list4) = service.search_results(q: all_docs_query, page: '-1')
      expect(solr_response4.params[:start].to_i).to eq 0
    end
    it 'has results available when asked for more than are in response' do
      big = 5000
      (solr_response5, document_list5) = service.search_results(q: all_docs_query, rows: big, page: 1)
      expect(solr_response5.docs).to have(document_list5.length).docs
      expect(solr_response5.docs).to have_at_least(1).doc
    end

  end # page specs

  # SPECS FOR SINGLE DOCUMENT REQUESTS
  describe 'Get Document By Id', :integration => true do
    let(:doc_id) { '2007020969' }
    let(:bad_id) { 'redrum' }

    before do
      @response2, @document = service.fetch(doc_id)
    end

    it "raises Blacklight::RecordNotFound for an unknown id" do
      expect {
        service.fetch(bad_id)
      }.to raise_error(Blacklight::Exceptions::RecordNotFound)
    end

    it "uses a provided document solr path" do
      allow(blacklight_config).to receive_messages(document_solr_path: 'get')
      allow(blacklight_solr).to receive(:send_and_receive).with('get', kind_of(Hash)).and_return({'response'=>{'docs'=>[]}})
      expect { service.fetch(doc_id)}.to raise_error Blacklight::Exceptions::RecordNotFound
    end

    it "has a non-nil result for a known id" do
      expect(@document).not_to be_nil
    end
    it "has a single document in the response for a known id" do
      expect(@response2.docs.size).to eq 1
    end
    it 'has the expected value in the id field' do
      expect(@document.id).to eq doc_id
    end
    it 'has non-nil values for required fields set in initializer' do
      expect(@document.fetch(blacklight_config.view_config(:show).display_type_field)).not_to be_nil
    end
  end

# SPECS FOR SPELLING SUGGESTIONS VIA SEARCH
  describe "Searches should return spelling suggestions", :integration => true do
    it 'search results for just-poor-enough-query term should have (multiple) spelling suggestions' do
      (solr_response, document_list) = service.search_results(q: 'boo')
      expect(solr_response.spelling.words).to include('bon')
      expect(solr_response.spelling.words).to include('bod')  #for multiple suggestions
    end

    it 'search results for just-poor-enough-query term should have multiple spelling suggestions' do
      (solr_response, document_list) = service.search_results(q: 'politica')
      expect(solr_response.spelling.words).to include('policy') # less freq
      expect(solr_response.spelling.words).to include('politics') # more freq
      expect(solr_response.spelling.words).to include('political') # more freq
=begin
      #  when we can have multiple suggestions
      expect(solr_response.spelling.words).to_not include('policy') # less freq
      solr_response.spelling.words).to include('politics') # more freq
      solr_response.spelling.words).to include('political') # more freq
=end
    end

    it "title search results for just-poor-enough query term should have spelling suggestions" do
      (solr_response, document_list) = service.search_results(q: 'yehudiyam', qt: 'search', :"spellcheck.dictionary" => "title")
      expect(solr_response.spelling.words).to include('yehudiyim')
    end

    it "author search results for just-poor-enough-query term should have spelling suggestions" do
      (solr_response, document_list) = service.search_results(q: 'shirma', qt: 'search', :"spellcheck.dictionary" => "author")
      expect(solr_response.spelling.words).to include('sharma')
    end

    it "subject search results for just-poor-enough-query term should have spelling suggestions" do
      (solr_response, document_list) = service.search_results(q: 'wome', qt: 'search', :"spellcheck.dictionary" => "subject")
      expect(solr_response.spelling.words).to include('women')
    end

    it 'search results for multiple terms query with just-poor-enough-terms should have spelling suggestions for each term' do
     skip
#     get_spelling_suggestion("histo politica").should_not be_nil
    end

  end


# TODO:  more complex queries!  phrases, offset into search results, non-latin, boosting(?)
#  search within query building (?)
#  search + facets (search done first; facet selected first, both selected)

# TODO: maybe eventually check other types of solr requests
#  more like this
#  nearby on shelf
  it "raises a Blacklight exception if RSolr can't connect to the Solr instance" do
    allow(blacklight_solr).to receive(:send_and_receive).and_raise(Errno::ECONNREFUSED)
    expect { service.repository.search }.to raise_exception(/Unable to connect to Solr instance/)
  end

  describe "grouped_key_for_results" do
    it "pulls the grouped key out of the config" do
      blacklight_config.index.group = 'xyz'
      expect(service.grouped_key_for_results).to eq('xyz')
    end
  end

  describe "#previous_and_next_documents_for_search" do
    before do
      @full_response, @all_docs = service.search_results(q: '', per_page: '100')
    end

    it "returns the previous and next documents for a search" do
      response, docs = service.previous_and_next_documents_for_search(4, :q => '')

      expect(docs.first.id).to eq @all_docs[3].id
      expect(docs.last.id).to eq @all_docs[5].id
    end

    it "returns only the next document if the counter is 0" do
      response, docs = service.previous_and_next_documents_for_search(0, :q => '')

      expect(docs.first).to be_nil
      expect(docs.last.id).to eq @all_docs[1].id
    end

    it "returns only the previous document if the counter is the total number of documents" do
      response, docs = service.previous_and_next_documents_for_search(@full_response.total - 1, :q => '')
      expect(docs.first.id).to eq @all_docs.slice(-2).id
      expect(docs.last).to be_nil
    end

    it "returns an array of nil values if there is only one result" do
      response, docs = service.previous_and_next_documents_for_search(0, :q => 'id:2007020969')
      expect(docs.last).to be_nil
      expect(docs.first).to be_nil
    end
  end
end
