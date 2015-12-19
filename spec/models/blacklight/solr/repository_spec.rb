require 'spec_helper'

describe Blacklight::Solr::Repository do

  let :blacklight_config do
    CatalogController.blacklight_config.deep_copy
  end

  subject do
    Blacklight::Solr::Repository.new blacklight_config
  end

  let :mock_response do
    { response: { docs: [document]}}
  end

  let :document do
    {}
  end

  describe "#find" do
    it "should use the document-specific solr path" do
      blacklight_config.document_solr_path = 'abc'
      blacklight_config.solr_path = 'xyz'
      allow(subject.connection).to receive(:send_and_receive).with('abc', anything).and_return(mock_response)
      expect(subject.find("123")).to be_a_kind_of Blacklight::Solr::Response
    end

    it "should use the default solr path" do
      blacklight_config.solr_path = 'xyz'
      allow(subject.connection).to receive(:send_and_receive).with('xyz', anything).and_return(mock_response)
      expect(subject.find("123")).to be_a_kind_of Blacklight::Solr::Response
    end

    it "should use a default :qt param" do
      allow(subject.connection).to receive(:send_and_receive).with('select', hash_including(params: { id: '123', qt: 'document'})).and_return(mock_response)
      expect(subject.find("123", {})).to be_a_kind_of Blacklight::Solr::Response
    end

    it "should use the provided :qt param" do
      blacklight_config.document_solr_request_handler = 'xyz'
      allow(subject.connection).to receive(:send_and_receive).with('select', hash_including(params: { id: '123', qt: 'abc'})).and_return(mock_response)
      expect(subject.find("123", {qt: 'abc'})).to be_a_kind_of Blacklight::Solr::Response
    end
    
    it "should use the :qt parameter from the default_document_solr_params" do
      blacklight_config.default_document_solr_params[:qt] = 'abc'
      blacklight_config.document_solr_request_handler = 'xyz'
      allow(subject.connection).to receive(:send_and_receive).with('select', hash_including(params: { id: '123', qt: 'abc'})).and_return(mock_response)
      expect(subject.find("123")).to be_a_kind_of Blacklight::Solr::Response
    end

    it "should preserve the class of the incoming params" do
      doc_params = ActiveSupport::HashWithIndifferentAccess.new
      allow(subject.connection).to receive(:send_and_receive).with('select', anything).and_return(mock_response)
      response = subject.find("123", doc_params)
      expect(response).to be_a_kind_of Blacklight::Solr::Response
      expect(response.params).to be_a_kind_of ActiveSupport::HashWithIndifferentAccess
    end
  end

  describe "#search" do
    it "should use the search-specific solr path" do
      blacklight_config.solr_path = 'xyz'
      allow(subject.connection).to receive(:send_and_receive).with('xyz', anything).and_return(mock_response)
      expect(subject.search({})).to be_a_kind_of Blacklight::Solr::Response
    end

    it "should use the default solr path" do
      allow(subject.connection).to receive(:send_and_receive).with('select', anything).and_return(mock_response)
      expect(subject.search({})).to be_a_kind_of Blacklight::Solr::Response
    end

    it "should use a default :qt param" do
      blacklight_config.qt = 'xyz'
      allow(subject.connection).to receive(:send_and_receive).with('select', hash_including(params: { qt: 'xyz'})).and_return(mock_response)
      expect(subject.search({})).to be_a_kind_of Blacklight::Solr::Response
    end

    it "should use the provided :qt param" do
      blacklight_config.qt = 'xyz'
      allow(subject.connection).to receive(:send_and_receive).with('select', hash_including(params: { qt: 'abc'})).and_return(mock_response)
      expect(subject.search({qt: 'abc'})).to be_a_kind_of Blacklight::Solr::Response
    end
    
    it "should preserve the class of the incoming params" do
      search_params = ActiveSupport::HashWithIndifferentAccess.new
      search_params[:q] = "query"
      allow(subject.connection).to receive(:send_and_receive).with('select', anything).and_return(mock_response)
      
      response = subject.search(search_params)
      expect(response).to be_a_kind_of Blacklight::Solr::Response
      expect(response.params).to be_a_kind_of ActiveSupport::HashWithIndifferentAccess
    end
  end

  describe "#send_and_receive" do
    describe "http_method configuration" do
      describe "using default" do

        it "defaults to get" do
          expect(blacklight_config.http_method).to eq :get
          allow(subject.connection).to receive(:send_and_receive) do |path, params|
            expect(path).to eq 'select'
            expect(params[:method]).to eq :get
            expect(params[:params]).to include(:q)
          end.and_return({'response'=>{'docs'=>[]}})
          subject.search(:q => @all_docs_query)
        end
      end

      describe "setting to post" do
        let (:blacklight_config) {config = Blacklight::Configuration.new; config.http_method=:post; config}

        it "keep value set to post" do
          expect(blacklight_config.http_method).to eq :post
          allow(subject.connection).to receive(:send_and_receive) do |path, params|
            expect(path).to eq 'select'
            expect(params[:method]).to eq :post
            expect(params[:data]).to include(:q)
          end.and_return({'response'=>{'docs'=>[]}})
          subject.search(:q => @all_docs_query)
        end
      end
    end
  end

  describe "http_method configuration", integration: true do
    let (:blacklight_config) {config = Blacklight::Configuration.new; config.http_method=:post; config}

    it "should send a post request to solr and get a response back" do
      response = subject.search(:q => @all_docs_query)
      expect(response.docs.length).to be >= 1
    end
  end


end
