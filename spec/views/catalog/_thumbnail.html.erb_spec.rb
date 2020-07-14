# frozen_string_literal: true

RSpec.describe "catalog/_thumbnail" do
  let :blacklight_config do
    Blacklight::Configuration.new do |config|
      config.index.thumbnail_field = :thumbnail_url
    end
  end

  before do
    allow(controller).to receive(:action_name).and_return('index')
    assign :response, instance_double(Blacklight::Solr::Response, start: 0)
    allow(view).to receive(:render_grouped_response?).and_return false
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:session_tracking_params).and_return({})
  end

  context 'when the document has a thumbnail' do
    let :document_with_thumbnail_field do
      SolrDocument.new id: 'xyz', format: 'a', thumbnail_url: 'http://localhost/logo.png'
    end

    let(:presenter) do
      Blacklight::IndexPresenter.new(document_with_thumbnail_field, view, counter: 1)
    end

    it "renders the thumbnail" do
      render partial: "catalog/thumbnail", locals: { document: document_with_thumbnail_field,
                                                     document_counter: 1,
                                                     presenter: presenter }
      expect(rendered).to match /document-thumbnail/
      expect(rendered).to match %r{src="http://localhost/logo.png"}
    end
  end

  context 'when the document does not have a thumbnail' do
    let :document_without_thumbnail_field do
      SolrDocument.new id: 'xyz', format: 'a'
    end
    let(:presenter) do
      Blacklight::IndexPresenter.new(document_without_thumbnail_field, view, counter: 1)
    end

    it "does not render anything" do
      render partial: "catalog/thumbnail", locals: { document: document_without_thumbnail_field,
                                                     document_counter: 1,
                                                     presenter: presenter }
      expect(rendered).to eq ""
    end
  end

  context 'when in the "show" context' do
    let :document_with_thumbnail_field do
      SolrDocument.new id: 'xyz', format: 'a', thumbnail_url: 'http://localhost/logo.png'
    end

    let(:presenter) do
      Blacklight::ShowPresenter.new(document_with_thumbnail_field, view)
    end

    it "renders the thumbnail" do
      render partial: "catalog/thumbnail", locals: { document: document_with_thumbnail_field,
                                                     document_counter: 1,
                                                     presenter: presenter }
      expect(rendered).to match /document-thumbnail/
      expect(rendered).to match %r{src="http://localhost/logo.png"}
    end
  end
end
