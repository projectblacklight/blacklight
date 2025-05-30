# frozen_string_literal: true

RSpec.describe Blacklight::Solr::Repository, :api do
  subject(:repository) do
    described_class.new blacklight_config
  end

  let :blacklight_config do
    CatalogController.blacklight_config.deep_copy
  end

  let(:all_docs_query) { '' }

  let :mock_response do
    { response: { docs: [document] } }
  end

  let :document do
    {}
  end

  describe "#find" do
    it "uses the document-specific solr path" do
      blacklight_config.document_solr_path = 'abc'
      blacklight_config.solr_path = 'xyz'
      allow(subject.connection).to receive(:send_and_receive).with('abc', anything).and_return(mock_response)
      expect(subject.find("123")).to be_a Blacklight::Solr::Response
    end

    it "uses a default :qt param" do
      allow(subject.connection).to receive(:send_and_receive).with('get', hash_including(params: hash_including(ids: '123'))).and_return(mock_response)
      expect(subject.find("123", {})).to be_a Blacklight::Solr::Response
    end

    context "without a document solr path configured" do
      before do
        blacklight_config.document_solr_path = nil
      end

      it "uses the default solr path" do
        blacklight_config.solr_path = 'xyz'
        allow(subject.connection).to receive(:send_and_receive).with('xyz', anything).and_return(mock_response)
        expect(subject.find("123")).to be_a Blacklight::Solr::Response
      end
    end

    context "with legacy request handler-based configuration" do
      before do
        blacklight_config.document_solr_path = 'select'
        blacklight_config.document_unique_id_param = :id
      end

      it "uses the provided :qt param" do
        blacklight_config.document_solr_request_handler = 'xyz'
        allow(subject.connection).to receive(:send_and_receive).with('select', hash_including(params: { 'id' => '123', 'qt' => 'abc' })).and_return(mock_response)
        expect(subject.find("123", qt: 'abc')).to be_a Blacklight::Solr::Response
      end

      it "uses the :qt parameter from the default_document_solr_params" do
        blacklight_config.default_document_solr_params[:qt] = 'abc'
        blacklight_config.document_solr_request_handler = 'xyz'
        allow(subject.connection).to receive(:send_and_receive).with('select', hash_including(params: { 'id' => '123', 'qt' => 'abc' })).and_return(mock_response)
        expect(subject.find("123")).to be_a Blacklight::Solr::Response
      end
    end

    it "preserves the class of the incoming params" do
      doc_params = ActiveSupport::HashWithIndifferentAccess.new
      allow(subject.connection).to receive(:send_and_receive).with('get', anything).and_return(mock_response)
      response = subject.find("123", doc_params)
      expect(response).to be_a Blacklight::Solr::Response
      expect(response.params).to be_a ActiveSupport::HashWithIndifferentAccess
    end
  end

  describe '#find_many' do
    context 'with a configured fetch_many_documents_path' do
      it 'uses the path' do
        blacklight_config.fetch_many_documents_path = 'documents'
        allow(subject.connection).to receive(:send_and_receive).with('documents', anything).and_return(mock_response)
        expect(subject.find_many({})).to be_a Blacklight::Solr::Response
      end
    end

    context 'without a configured fetch_many_documents_path' do
      it 'falls back to the search path' do
        blacklight_config.solr_path = 'xyz'
        allow(subject.connection).to receive(:send_and_receive).with('xyz', anything).and_return(mock_response)
        expect(subject.find_many({})).to be_a Blacklight::Solr::Response
      end
    end
  end

  describe "#search" do
    context 'with positional params' do
      it "uses the search-specific solr path" do
        blacklight_config.solr_path = 'xyz'
        allow(subject.connection).to receive(:send_and_receive).with('xyz', anything).and_return(mock_response)
        allow(Blacklight.deprecation).to receive(:warn)
        expect(subject.search({})).to be_a Blacklight::Solr::Response
      end
    end

    it "uses the search-specific solr path" do
      blacklight_config.solr_path = 'xyz'
      allow(subject.connection).to receive(:send_and_receive).with('xyz', anything).and_return(mock_response)
      expect(subject.search(params: {})).to be_a Blacklight::Solr::Response
    end

    it "uses the default solr path" do
      allow(subject.connection).to receive(:send_and_receive).with('select', anything).and_return(mock_response)
      expect(subject.search(params: {})).to be_a Blacklight::Solr::Response
    end

    it "uses a default :qt param" do
      blacklight_config.qt = 'xyz'
      allow(subject.connection).to receive(:send_and_receive).with('select', hash_including(params: { qt: 'xyz' })).and_return(mock_response)
      expect(subject.search(params: {})).to be_a Blacklight::Solr::Response
    end

    it "uses the provided :qt param" do
      blacklight_config.qt = 'xyz'
      allow(subject.connection).to receive(:send_and_receive).with('select', hash_including(params: { qt: 'abc' })).and_return(mock_response)
      expect(subject.search(params: { qt: 'abc' })).to be_a Blacklight::Solr::Response
    end

    it "preserves the class of the incoming params" do
      search_params = ActiveSupport::HashWithIndifferentAccess.new
      search_params[:q] = "query"
      allow(subject.connection).to receive(:send_and_receive).with('select', anything).and_return(mock_response)

      response = subject.search(params: search_params)
      expect(response).to be_a Blacklight::Solr::Response
      expect(response.params).to be_a ActiveSupport::HashWithIndifferentAccess
    end

    it "calls send_and_receive with params returned from request factory method" do
      expect(blacklight_config.http_method).to eq :get
      input_params = { q: all_docs_query }
      allow(subject.connection).to receive(:send_and_receive) do |path, params|
        expect(path).to eq 'select'
        expect(params[:method]).to eq :get
        expect(params[:params]).to include input_params
      end.and_return('response' => { 'docs' => [] })
      subject.search(params: input_params)
    end

    it "raises a Blacklight exception if RSolr can't connect to the Solr instance" do
      allow(repository.connection).to receive(:send_and_receive).and_raise(Errno::ECONNREFUSED)
      expect { subject.search(params: {}) }.to raise_exception(/Unable to connect to Solr instance/)
    end

    it "raises a Blacklight exception if RSolr raises a timeout error connecting to Solr instance" do
      rsolr_timeout = RSolr::Error::Timeout.new(nil, nil)
      allow(rsolr_timeout).to receive(:to_s).and_return("mocked RSolr timeout")

      allow(repository.connection).to receive(:send_and_receive).and_raise(rsolr_timeout)
      expect { subject.search(params: {}) }.to raise_exception(Blacklight::Exceptions::RepositoryTimeout, /Timeout connecting to Solr instance/)
    end
  end

  describe "#build_solr_request" do
    let(:input_params) { { q: all_docs_query } }
    let(:actual_params) { subject.build_solr_request(input_params) }

    describe "http_method configuration" do
      describe "using default" do
        it "defaults to get" do
          expect(blacklight_config.http_method).to eq :get
          expect(actual_params[:method]).to eq :get
          expect(actual_params[:params]).to include input_params
          expect(actual_params).not_to have_key :data
        end
      end

      describe "setting to post" do
        let (:blacklight_config) { config = Blacklight::Configuration.new; config.http_method = :post; config }

        it "keep value set to post" do
          expect(blacklight_config.http_method).to eq :post
          expect(actual_params[:method]).to eq :post
          expect(actual_params[:data]).to include input_params
          expect(actual_params).not_to have_key :params
        end
      end
    end

    context 'with json parameters' do
      let(:input_params) { { json: { query: { bool: {} } } } }

      it 'sends a post request with some json' do
        expect(actual_params[:method]).to eq :post
        expect(JSON.parse(actual_params[:data]).with_indifferent_access).to include(query: { bool: {} })
        expect(actual_params[:headers]).to include({ 'Content-Type' => 'application/json' })
      end

      context "without a json solr path configured" do
        before do
          blacklight_config.json_solr_path = nil
        end

        it "uses the default solr path" do
          blacklight_config.solr_path = 'xyz'
          allow(subject.connection).to receive(:send_and_receive) do |path|
            expect(path).to eq 'xyz'
          end
          subject.search(params: input_params)
        end
      end

      context "with a json solr path configured" do
        before do
          blacklight_config.json_solr_path = 'my-great-json'
        end

        it "uses the configured json_solr_path" do
          allow(subject.connection).to receive(:send_and_receive) do |path|
            expect(path).to eq 'my-great-json'
          end
          subject.search(params: input_params)
        end
      end
    end
  end

  describe "http_method configuration", :integration do
    let (:blacklight_config) { config = Blacklight::Configuration.new; config.http_method = :post; config }

    it "sends a post request to solr and get a response back" do
      response = subject.search(params: { q: all_docs_query })
      expect(response.docs.length).to be >= 1
    end
  end

  describe '#ping' do
    subject { repository.ping }

    it { is_expected.to be true }
  end
end
