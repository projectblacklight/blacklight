# frozen_string_literal: true

RSpec.describe CatalogController, api: true do
  around { |test| Deprecation.silence(Blacklight::Catalog) { test.call } }

  let(:doc_id) { '2007020969' }
  let(:mock_response) { instance_double(Blacklight::Solr::Response) }
  let(:mock_document) { instance_double(SolrDocument, export_formats: {}) }
  let(:search_service) { instance_double(Blacklight::SearchService) }

  describe "index action" do
    context "with format :html" do
      let(:user_query) { 'history' } # query that will get results

      it "has no search history if no search criteria" do
        allow(controller).to receive(:search_results)
        session[:history] = []
        get :index
        expect(session[:history]).to be_empty
      end

      describe "preferred view" do
        it "saves the view choice" do
          get :index, params: { q: 'foo', view: 'gallery' }
          expect(session[:preferred_view]).to eq 'gallery'
        end
      end

      # check each user manipulated parameter
      it "has docs and facets for query with results", integration: true do
        get :index, params: { q: user_query }
        expect(assigns(:response).docs).not_to be_empty
        assert_facets_have_values(assigns(:response).aggregations)
      end

      it "has docs and facets for existing facet value", integration: true do
        get :index, params: { f: { "format" => 'Book' } }
        expect(assigns(:response).docs).not_to be_empty
        assert_facets_have_values(assigns(:response).aggregations)
      end

      it "has docs and facets for non-default results per page", integration: true do
        num_per_page = 7
        get :index, params: { per_page: num_per_page }
        expect(assigns(:response).docs).to have(num_per_page).items
        assert_facets_have_values(assigns(:response).aggregations)
      end

      it "has docs and facets for second page", integration: true do
        page = 2
        get :index, params: { page: page }
        expect(assigns(:response).docs).not_to be_empty
        expect(assigns(:response).params[:start].to_i).to eq (page - 1) * controller.blacklight_config[:default_solr_params][:rows]
        assert_facets_have_values(assigns(:response).aggregations)
      end

      it "has no docs or facet values for query without results", integration: true do
        get :index, params: { q: 'sadfdsafasdfsadfsadfsadf' } # query for no results
        expect(assigns(:response).docs).to be_empty
        assigns(:response).aggregations.each do |_key, facet|
          expect(facet.items).to be_empty
        end
      end

      it "shows 0 results when the user asks for an invalid value to a custom facet query", integration: true do
        get :index, params: { f: { example_query_facet_field: 'bogus' } } # bogus custom facet value
        expect(assigns(:response).docs).to be_empty
      end

      it "returns results (possibly 0) when the user asks for a valid value to a custom facet query", integration: true do
        get :index, params: { f: { example_query_facet_field: 'years_25' } } # valid custom facet value with some results
        expect(assigns(:response).docs).not_to be_empty
      end

      it "returns no results when the users asks for a value that doesn't match any" do
        get :index, params: { f: { example_query_facet_field: 'years_5' } } # valid custom facet value with NO results
        expect(assigns(:response).docs).to be_empty
      end

      it "has a spelling suggestion for an appropriately poor query", integration: true do
        get :index, params: { q: 'boo' }
        expect(assigns(:response).spelling.words).not_to be_nil
      end

      describe "session" do
        before do
          allow(controller).to receive(:search_results)
        end

        it "includes search hash with key :q" do
          get :index, params: { q: user_query }
          expect(session[:search]).not_to be_nil
          expect(session[:search].keys).to include 'id'
          search = Search.find(session[:search]['id'])
          expect(search.query_params['q']).to eq user_query
        end
      end

      # check with no user manipulation
      describe "for default query" do
        it "gets documents when no query", integration: true do
          get :index
          expect(assigns(:response).docs).not_to be_empty
        end

        it "gets facets when no query", integration: true do
          get :index
          assert_facets_have_values(assigns(:response).aggregations)
        end
      end

      it "renders index.html.erb" do
        allow(controller).to receive(:search_results)
        get :index
        expect(response).to render_template(:index)
      end

      # NOTE: status code is always 200 in isolation mode ...
      it "HTTP status code for GET should be 200", integration: true do
        get :index
        expect(response).to be_successful
      end
    end

    describe "with format :rss" do
      it "gets the feed", integration: true do
        get :index, params: { format: 'rss' }
        expect(response).to be_successful
      end
    end

    describe "with format :json" do
      render_views
      before do
        get :index, params: { format: 'json' }
        expect(response).to be_successful
      end

      let(:json) { JSON.parse(response.body) }
      let(:pages)  { json['meta']['pages'] }
      let(:docs)   { json['data'] }
      let(:facets) { json['included'].select { |x| x['type'] == 'facet' } }
      let(:search_fields) { json['included'].select { |x| x['type'] == 'search_field' } }

      it "gets the pages" do
        expect(pages["total_count"]).to eq 30
        expect(pages["current_page"]).to eq 1
        expect(pages["total_pages"]).to eq 3
      end

      it "gets the documents" do
        expect(docs).to have(10).documents
        expect(docs.first['attributes'].keys).to match_array(
          %w[author_tsim format language_ssim lc_callnum_ssim published_ssim title_tsim]
        )
        expect(docs.first['links']['self']).to eq solr_document_url(id: docs.first['id'])
      end

      it "gets the facets" do
        expect(facets).to have(9).facets

        format = facets.find { |x| x['id'] == 'format' }

        expect(format['attributes']['items'].map { |x| x['attributes'] }).to match_array([{ "value" => "Book", "hits" => 30, "label" => "Book" }])
        expect(format['links']['self']).to eq facet_catalog_url(format: :json, id: 'format')
        expect(format['attributes']['items'].first['links']['self']).to eq search_catalog_url(format: :json, f: { format: ['Book'] })
      end

      it "gets the search fields" do
        expect(search_fields).to have(4).fields
        expect(search_fields.map { |x| x['id'] }).to match_array %w[all_fields author subject title]
        expect(search_fields.first['links']['self']).to eq search_catalog_url(format: :json, search_field: 'all_fields')
      end

      describe "facets" do
        let(:query_facet) { facets.find { |x| x['id'] == 'example_query_facet_field' } }
        let(:query_facet_items) { query_facet['attributes']['items'].map { |x| x['attributes'] } }

        it "has items with labels and values" do
          expect(query_facet_items.first['label']).to eq 'within 25 Years'
          expect(query_facet_items.first['value']).to eq 'years_25'
        end
      end
    end

    describe "with additional formats from configuration" do
      let(:blacklight_config) { Blacklight::Configuration.new }

      before do
        allow(controller).to receive_messages blacklight_config: blacklight_config
        allow(controller).to receive_messages search_results: [double, double]
      end

      it "does not render when the config is false" do
        blacklight_config.index.respond_to.yaml = false
        expect { get :index, params: { format: 'yaml' } }.to raise_error ActionController::RoutingError
      end

      it "renders the default when the config is true" do
        # TODO: this should really stub a template and see if it gets rendered,
        # but how to do that is non-obvious..
        blacklight_config.index.respond_to.yaml = true
        expect { get :index, params: { format: 'yaml' } }.to raise_error ActionView::MissingTemplate
      end

      it "passes a hash to the render call" do
        blacklight_config.index.respond_to.yaml = { inline: '', layout: false }
        get :index, params: { format: 'yaml' }
        expect(response.body).to be_blank
      end

      it "evaluates a proc" do
        blacklight_config.index.respond_to.yaml = -> { render plain: "" }
        get :index, params: { format: 'yaml' }
        expect(response.body).to be_empty
      end

      it "with a symbol, it should call a controller method" do
        expect(subject).to receive(:render_some_yaml) do
          subject.head :ok, layout: false
        end
        blacklight_config.index.respond_to.yaml = :render_some_yaml
        get :index, params: { format: 'yaml' }
        expect(response.body).to be_blank
      end
    end
  end # describe index action

  describe "track action" do
    it "persists the search session id value into session[:search]" do
      put :track, params: { id: doc_id, counter: 3, search_id: "123" }
      expect(session[:search]['id']).to eq "123"
    end

    it "sets counter value into session[:search]" do
      put :track, params: { id: doc_id, counter: 3 }
      expect(session[:search]['counter']).to eq "3"
    end

    it "records the current per_page setting" do
      put :track, params: { id: doc_id, counter: 3, per_page: 15 }
      expect(session[:search]['per_page']).to eq "15"
    end

    it "records the document id being viewed" do
      put :track, params: { id: doc_id, counter: 3, document_id: 1234 }
      expect(session[:search]['document_id']).to eq "1234"
    end

    it "redirects to show action for doc id" do
      put :track, params: { id: doc_id, counter: 3 }
      assert_redirected_to(solr_document_path(doc_id))
    end

    it "HTTP status code for redirect should be 303" do
      put :track, params: { id: doc_id, counter: 3 }
      expect(response.status).to eq 303
    end

    it "redirects to the path given in the redirect param" do
      put :track, params: { id: doc_id, counter: 3, redirect: '/xyz' }
      assert_redirected_to("/xyz")
    end

    it "redirects to the path of the uri given in the redirect param" do
      put :track, params: { id: doc_id, counter: 3, redirect: 'http://localhost:3000/xyz' }
      assert_redirected_to("/xyz")
    end

    it "keeps querystring on redirect" do
      put :track, params: { id: doc_id, counter: 3, redirect: 'http://localhost:3000/xyz?locale=pt-BR' }
      assert_redirected_to("/xyz?locale=pt-BR")
    end
  end

  describe '#raw' do
    context 'when disabled' do
      it "returns 404" do
        expect { get :raw, params: { id: doc_id, format: 'json' } }.to raise_error ActionController::RoutingError
      end
    end

    context 'when enabled' do
      before do
        allow(controller.blacklight_config.raw_endpoint).to receive(:enabled).and_return(true)
      end

      it "gets the raw solr document" do
        get :raw, params: { id: doc_id, format: 'json' }
        expect(response).to be_successful
        json = JSON.parse response.body
        expect(json.keys).to match_array(
          %w[id _version_ author_addl_tsim author_tsim format isbn_ssim
             language_ssim lc_1letter_ssim lc_alpha_ssim lc_b4cutter_ssim
             lc_callnum_ssim marc_ss material_type_ssim pub_date_ssim
             published_ssim subject_addl_ssim subject_geo_ssim subject_ssim
             subject_tsim subtitle_tsim timestamp title_addl_tsim title_tsim
             url_suppl_ssim]
        )
      end
    end
  end

  describe 'GET advanced_search' do
    it 'renders an advanced search form' do
      get :advanced_search
      expect(response).to be_successful

      assert_facets_have_values(assigns(:response).aggregations)
    end
  end

  # SHOW ACTION
  describe "show action" do
    describe "with format :html" do
      it "gets document", integration: true do
        get :show, params: { id: doc_id }
        expect(assigns[:document]).not_to be_nil
      end
    end

    describe "with format :json" do
      render_views
      it "gets the feed" do
        get :show, params: { id: doc_id, format: 'json' }
        expect(response).to be_successful
        json = JSON.parse response.body
        expect(json["data"]["attributes"].keys).to match_array(
          %w[author_tsim format isbn_ssim language_ssim lc_callnum_ssim
             published_ssim subtitle_tsim title_tsim url_suppl_ssim]
        )
      end
    end

    describe "previous/next documents" do
      let(:search_session) { { id: current_search.id } }
      let(:current_search) { Search.create(query_params: { q: "" }) }

      before do
        allow(mock_document).to receive_messages(export_formats: {})
        allow(controller).to receive(:search_service).and_return(search_service)
        expect(search_service).to receive(:fetch).and_return([mock_response, mock_document])
        allow(controller).to receive(:current_search_session).and_return(current_search)
      end

      context 'if counter is present in session' do
        before do
          session[:search] = search_session.merge('counter' => 2)
        end

        context 'and no exception is raised' do
          before do
            expect(search_service).to receive(:previous_and_next_documents_for_search)
              .and_return([double(total: 5), [double("a"), mock_document, double("b")]])
          end

          it "sets previous document" do
            get :show, params: { id: doc_id }
            expect(assigns[:search_context][:prev]).not_to be_nil
          end

          it "sets next document" do
            get :show, params: { id: doc_id }
            expect(assigns[:search_context][:next]).not_to be_nil
          end
        end

        context 'and an exception is raised' do
          before do
            expect(search_service).to receive(:previous_and_next_documents_for_search) {
              raise Blacklight::Exceptions::InvalidRequest, "Error"
            }
          end

          it "does not break" do
            get :show, params: { id: doc_id }
            expect(assigns[:search_context]).to be_nil
          end
        end
      end

      it "does not set previous or next document if session is blank" do
        get :show, params: { id: doc_id }
        expect(assigns[:search_context]).to be_nil
      end

      it "does not set previous or next document if session[:search]['counter'] is nil" do
        session[:search] = {}
        get :show, params: { id: doc_id }
        expect(assigns[:search_context]).to be_nil
      end
    end

    # NOTE: status code is always 200 in isolation mode ...
    it "HTTP status code for GET should be 200", integration: true do
      get :show, params: { id: doc_id }
      expect(response).to be_successful
    end

    it "renders show.html.erb" do
      allow(controller).to receive(:search_service).and_return(search_service)
      expect(search_service).to receive(:fetch).and_return([mock_response, mock_document])

      get :show, params: { id: doc_id }
      expect(response).to render_template(:show)
    end

    describe '@document' do
      before do
        allow(controller).to receive(:search_service).and_return(search_service)
        expect(search_service).to receive(:fetch).and_return([mock_response, mock_document])

        get :show, params: { id: doc_id }
      end

      it 'is a SolrDocument' do
        expect(assigns[:document]).to eq mock_document
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
        Mime::Type.register "application/mock", :mock
        SolrDocument.use_extension(FakeExtension)
        allow(controller).to receive(:search_service).and_return(search_service)
        expect(search_service).to receive(:fetch).and_return([nil, SolrDocument.new(id: 'my_fake_doc')])
      end

      after do
        SolrDocument.registered_extensions.pop # remove the fake extension
      end

      it "responds to an extension-registered format properly" do
        get :show, params: { id: doc_id, format: 'mock' }
        expect(response).to be_successful
        expect(response.body).to match /mock_export/
      end
    end # dynamic export formats
  end # describe show action

  describe "opensearch" do
    it "returns an opensearch description" do
      get :opensearch, params: { format: 'xml' }
      expect(response).to be_successful
    end

    context 'when searching for something' do
      before do
        allow(controller).to receive(:search_service).and_return(search_service)
        expect(search_service).to receive(:opensearch_response)
          .and_return(['a', [SolrDocument.new(id: 'my_fake_doc'),
                             SolrDocument.new(id: 'my_other_doc')]])
      end

      it "returns valid JSON" do
        get :opensearch, params: { format: 'json', q: 'a' }
        expect(response).to be_successful
      end
    end
  end

  describe 'GET suggest' do
    it 'returns JSON' do
      get :suggest, params: { format: 'json' }
      expect(response.body).to eq [].to_json
    end

    it 'returns suggestions' do
      get :suggest, params: { format: 'json', q: 'new' }
      json = JSON.parse(response.body)
      expect(json.count).to eq 5
      expect(json.first['term']).to eq 'new jersey'
    end
  end

  describe "email/sms" do
    let(:mock_response) { instance_double(Blacklight::Solr::Response, documents: [SolrDocument.new(id: 'my_fake_doc'), SolrDocument.new(id: 'my_other_doc')]) }

    before do
      mock_document.extend(Blacklight::Document::Sms)
      mock_document.extend(Blacklight::Document::Email)
      allow(mock_document).to receive(:to_semantic_values).and_return({})
      allow(mock_document).to receive(:to_model).and_return(SolrDocument.new(id: 'my_fake_doc'))

      allow(controller).to receive(:search_service).and_return(search_service)
      expect(search_service).to receive(:fetch).and_return([mock_response, [mock_document]])
      request.env["HTTP_REFERER"] = "/catalog/#{doc_id}"
      SolrDocument.use_extension(Blacklight::Document::Email)
      SolrDocument.use_extension(Blacklight::Document::Sms)
    end

    describe "email", api: false do
      let(:config) { Blacklight::Configuration.new }

      before do
        allow(controller).to receive(:blacklight_config).and_return(config)
      end

      it "gives error if no TO parameter" do
        post :email, params: { id: doc_id }
        expect(request.flash[:error]).to eq "You must enter a recipient in order to send this message"
      end

      it "gives an error if the email address is not valid" do
        post :email, params: { id: doc_id, to: 'test_bad_email' }
        expect(request.flash[:error]).to eq "You must enter a valid email address"
      end

      it "does not give error if no Message parameter is set" do
        post :email, params: { id: doc_id, to: 'test_email@projectblacklight.org' }
        expect(request.flash[:error]).to be_nil
      end

      it "redirects back to the record upon success" do
        allow(RecordMailer).to receive(:email_record)
          .with(anything, { to: 'test_email@projectblacklight.org', message: 'xyz', config: config }, hash_including(host: 'test.host'))
          .and_return double(deliver: nil)
        post :email, params: { id: doc_id, to: 'test_email@projectblacklight.org', message: 'xyz' }
        expect(request.flash[:error]).to be_nil
        expect(request).to redirect_to(solr_document_path(doc_id))
      end

      it "renders email_success for XHR requests" do
        post :email, xhr: true, params: { id: doc_id, to: 'test_email@projectblacklight.org' }
        expect(request).to render_template 'email_success'
        expect(request.flash[:success]).to eq "Email Sent"
      end
    end

    describe "sms", api: false do
      let(:config) { Blacklight::Configuration.new }

      before do
        allow(controller).to receive(:blacklight_config).and_return(config)
      end

      it "gives error if no phone number is given" do
        post :sms, params: { id: doc_id, carrier: 'att' }
        expect(request.flash[:error]).to eq "You must enter a recipient's phone number in order to send this message"
      end

      it "gives an error when a carrier is not provided" do
        post :sms, params: { id: doc_id, to: '5555555555', carrier: '' }
        expect(request.flash[:error]).to eq "You must select a carrier"
      end

      it "gives an error when the phone number is not 10 digits" do
        post :sms, params: { id: doc_id, to: '555555555', carrier: 'txt.att.net' }
        expect(request.flash[:error]).to eq "You must enter a valid 10 digit phone number"
      end

      it "gives an error when the carrier is not in our list of carriers" do
        post :sms, params: { id: doc_id, to: '5555555555', carrier: 'no-such-carrier' }
        expect(request.flash[:error]).to eq "You must enter a valid carrier"
      end

      it "allows punctuation in phone number" do
        post :sms, params: { id: doc_id, to: '(555) 555-5555', carrier: 'txt.att.net' }
        expect(request.flash[:error]).to be_nil
        expect(request).to redirect_to(solr_document_path(doc_id))
      end

      it "sends to the appropriate carrier email address" do
        expect(RecordMailer)
          .to receive(:sms_record)
          .with(anything, { to: '5555555555@txt.att.net', config: config }, hash_including(host: 'test.host'))
          .and_return double(deliver: nil)
        post :sms, params: { id: doc_id, to: '5555555555', carrier: 'txt.att.net' }
      end

      it "redirects back to the record upon success" do
        post :sms, params: { id: doc_id, to: '5555555555', carrier: 'txt.att.net' }
        expect(request.flash[:error]).to eq nil
        expect(request).to redirect_to(solr_document_path(doc_id))
      end

      it "renders sms_success template for XHR requests" do
        post :sms, xhr: true, params: { id: doc_id, to: '5555555555', carrier: 'txt.att.net' }
        expect(request).to render_template 'sms_success'
        expect(request.flash[:success]).to eq "SMS Sent"
      end
    end
  end

  describe "errors" do
    it "returns status 404 for a record that doesn't exist" do
      allow(controller).to receive_messages(find: double(documents: []))
      expect do
        get :show, params: { id: "987654321" }
      end.to raise_error Blacklight::Exceptions::RecordNotFound
    end

    it "returns status 404 for exportable actions on records that do not exist" do
      allow(controller).to receive_messages(find: double(documents: []))
      expect do
        get :citation, params: { id: "bad-record-identifer" }
      end.to raise_error Blacklight::Exceptions::RecordNotFound
    end

    context "when there is an invalid search", api: false do
      let(:service) { instance_double(Blacklight::SearchService) }
      let(:fake_error) { Blacklight::Exceptions::InvalidRequest.new }

      before do
        allow(controller).to receive(:search_service).and_return(service)
        allow(service).to receive(:search_results) { |*_args| raise fake_error }
        allow(Rails.env).to receive_messages(test?: false)
      end

      it "redirects the user to the root url for a bad search" do
        expect(controller.logger).to receive(:error).with(fake_error)
        get :index, params: { q: '+' }
        expect(response.redirect_url).to eq root_url
        expect(request.flash[:notice]).to eq "Sorry, I don't understand your search."
        expect(response).not_to be_successful
        expect(response.status).to eq 302
      end

      it "returns status 500 if the catalog path is raising an exception" do
        allow(controller).to receive(:flash).and_return(notice: I18n.t('blacklight.search.errors.request_error'))
        expect { get :index, params: { q: '+' } }.to raise_error Blacklight::Exceptions::InvalidRequest
      end
    end
  end

  context "without a user authentication provider" do
    render_views

    before do
      allow(controller).to receive(:has_user_authentication_provider?).and_return(false)
    end

    it "does not show user util links" do
      get :index
      expect(response.body).not_to match /Login/
    end
  end

  describe "facet" do
    describe "requesting js" do
      it "is successful" do
        get :facet, xhr: true, params: { id: 'format' }
        expect(response).to be_successful
      end
    end

    describe "requesting html" do
      it "is successful" do
        get :facet, params: { id: 'format' }
        expect(response).to be_successful
        expect(assigns[:response]).to be_kind_of Blacklight::Solr::Response
        expect(assigns[:facet]).to be_kind_of Blacklight::Configuration::FacetField
        expect(assigns[:display_facet]).to be_kind_of Blacklight::Solr::Response::Facets::FacetField
        expect(assigns[:pagination]).to be_kind_of Blacklight::Solr::FacetPaginator
      end
    end

    describe "requesting json" do
      render_views
      it "is successful" do
        get :facet, params: { id: 'format', format: 'json' }
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["response"]["facets"]["items"].first["value"]).to eq 'Book'
      end
    end

    context 'for a facet field with a key different from the underlying field name' do
      before do
        controller.blacklight_config.add_facet_field 'params_key', field: 'format'
      end

      it 'is successful' do
        get :facet, params: { id: 'params_key' }

        expect(response).to be_successful

        expect(assigns[:facet]).to be_kind_of Blacklight::Configuration::FacetField
        expect(assigns[:facet].key).to eq 'params_key'
        expect(assigns[:facet].field).to eq 'format'

        expect(assigns[:pagination].items.first['value']).to eq 'Book'
      end
    end

    context 'when the requested facet is not in the configuration' do
      it 'raises a routing error' do
        expect do
          get :facet, params: { id: 'fake' }
        end.to raise_error ActionController::RoutingError, 'Not Found'
      end
    end
  end

  describe "#add_to_search_history" do
    it "prepends the current search to the list" do
      session[:history] = []
      controller.send(:add_to_search_history, double(id: 1))
      expect(session[:history]).to have(1).item
      controller.send(:add_to_search_history, double(id: 2))
      expect(session[:history]).to have(2).items
      expect(session[:history].first).to eq 2
    end

    it "removes searches from the list when the list gets too big" do
      allow(controller).to receive(:blacklight_config).and_return(double(search_history_window: 5))
      session[:history] = (0..4).to_a.reverse
      expect(session[:history]).to have(5).items
      controller.send(:add_to_search_history, double(id: 5))
      controller.send(:add_to_search_history, double(id: 6))
      controller.send(:add_to_search_history, double(id: 7))
      expect(session[:history]).to include(*(3..7).to_a)
    end
  end

  describe "current_search_session" do
    let(:parameter_class) { ActionController::Parameters }

    it "creates a session if we're on an search action" do
      allow(controller).to receive_messages(action_name: "index")
      allow(controller).to receive_messages(params: parameter_class.new(q: "x", page: 5))
      session = controller.send(:current_search_session)
      expect(session.query_params).to include(q: "x")
      expect(session.query_params).not_to include(page: 5)
    end

    it "creates a session if a search context was provided" do
      allow(controller).to receive_messages(params: parameter_class.new(search_context: JSON.dump(q: "x")))
      session = controller.send(:current_search_session)
      expect(session.query_params).to include("q" => "x")
    end

    it "uses an existing session if a search id was provided" do
      s = Search.create(query_params: { q: "x" })
      session[:history] ||= []
      session[:history] << s.id
      allow(controller).to receive_messages(params: parameter_class.new(search_id: s.id))
      session = controller.send(:current_search_session)
      expect(session.query_params).to include(q: "x")
      expect(session).to eq(s)
    end

    it "uses an existing search session if the search is in the uri" do
      s = Search.create(query_params: { q: "x" })
      session[:search] ||= {}
      session[:search]['id'] = s.id
      session[:history] ||= []
      session[:history] << s.id
      session = controller.send(:current_search_session)
      expect(session.query_params).to include(q: "x")
      expect(session).to eq(s)
    end
  end

  describe "#has_search_parameters?" do
    subject { controller.has_search_parameters? }

    describe "none" do
      before { allow(controller).to receive_messages(params: {}) }

      it { is_expected.to be false }
    end

    describe "with a query" do
      before { allow(controller).to receive_messages(params: { q: 'hello' }) }

      it { is_expected.to be true }
    end

    describe "with a facet" do
      before { allow(controller).to receive_messages(params: { f: { "field" => ["value"] } }) }

      it { is_expected.to be true }
    end
  end

  describe "#add_show_tools_partial", api: false do
    before do
      described_class.blacklight_config.add_show_tools_partial(:like, callback: :perform_like, validator: :validate_like_params)
      allow(controller).to receive(:solr_document_url).and_return('catalog/1')
      allow(controller).to receive(:action_documents).and_return(1)
      Rails.application.routes.draw do
        get 'catalog/like', as: :catalog_like
      end
    end

    after do
      described_class.blacklight_config.show.document_actions.delete(:like)
      Rails.application.reload_routes!
    end

    it "adds the action to a list" do
      expect(described_class.blacklight_config.show.document_actions).to have_key(:like)
    end

    it "defines the action method" do
      expect(controller).to respond_to(:like)
    end

    describe "when posting to the action" do
      context 'with valid params' do
        it "calls the supplied method on post" do
          expect(controller).to receive(:validate_like_params).and_return(true)
          expect(controller).to receive(:perform_like)
          post :like
        end
      end

      context "with failure on invalid params" do
        it "does not call the supplied method" do
          expect(controller).to receive(:validate_like_params).and_return(false)
          expect(controller).not_to receive(:perform_like)
          skip 'Clarify expectations on validator failure: 400? 500? Set a specific error key/msg? Render the same template anyway?'
          post :like
        end
      end
    end
  end

  describe "search_action_url" do
    it "is the same as the catalog url" do
      get :index, params: { page: 1 }
      expect(controller.send(:search_action_url, q: "xyz")).to eq root_url(q: "xyz")
    end
  end

  describe "search_facet_path" do
    it "is the same as the catalog path" do
      get :index, params: { page: 1 }
      expect(controller.send(:search_facet_path, id: "some_facet", page: 5)).to eq facet_catalog_path(id: "some_facet")
    end
  end

  describe "facet_limit_for" do
    let(:blacklight_config) { controller.blacklight_config }

    it "returns specified value for facet_field specified" do
      expect(controller.facet_limit_for("subject_ssim")).to eq blacklight_config.facet_fields["subject_ssim"].limit
    end

    it "facet_limit_hash should return hash with key being facet_field and value being configured limit" do
      # facet_limit_hash has been removed from solrhelper in refactor. should it go back?
      skip "facet_limit_hash has been removed from solrhelper in refactor. should it go back?"
      expect(controller.facet_limit_hash).to eq blacklight_config[:facet][:limits]
    end

    it "handles no facet_limits in config" do
      blacklight_config.facet_fields = {}
      expect(controller.facet_limit_for("subject_ssim")).to be_nil
    end

    describe "for 'true' configured values" do
      before do
        allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
      end

      let(:blacklight_config) do
        Blacklight::Configuration.new do |config|
          config.add_facet_field "language_facet", limit: true
        end
      end

      it "returns nil if no @response available" do
        expect(controller.facet_limit_for("some_unknown_field")).to be_nil
      end

      it "gets from @response facet.limit if available" do
        response = instance_double(Blacklight::Solr::Response, aggregations: { "language_facet" => double(limit: nil) })
        controller.instance_variable_set(:@response, response)
        blacklight_config.facet_fields['language_facet'].limit = 10
        expect(controller.facet_limit_for("language_facet")).to eq 10
      end

      it "gets the limit from the facet field in @response" do
        response = instance_double(Blacklight::Solr::Response, aggregations: { "language_facet" => double(limit: 16) })
        controller.instance_variable_set(:@response, response)
        expect(controller.facet_limit_for("language_facet")).to eq 15
      end

      it "defaults to 10" do
        expect(controller.facet_limit_for("language_facet")).to eq 10
      end
    end

    context 'for facet fields with a key that is different from the field name' do
      before do
        allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
      end

      let(:blacklight_config) do
        Blacklight::Configuration.new do |config|
          config.add_facet_field 'some_key', field: 'x', limit: true
        end
      end

      it 'gets the limit from the facet field in the @response' do
        response = instance_double(Blacklight::Solr::Response, aggregations: { 'x' => double(limit: 16) })
        controller.instance_variable_set(:@response, response)
        expect(controller.facet_limit_for('some_key')).to eq 15
      end
    end
  end
end

# there must be at least one facet, and each facet must have at least one value
def assert_facets_have_values(aggregations)
  expect(aggregations).not_to be_empty
  # should have at least one value for each facet
  aggregations.each do |_key, facet|
    expect(facet.items).to have_at_least(1).item
  end
end
