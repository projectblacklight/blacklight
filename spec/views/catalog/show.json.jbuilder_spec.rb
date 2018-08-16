# frozen_string_literal: true

RSpec.describe "catalog/show.json" do
  let(:document) do
    SolrDocument.new(id: '123', title_tsim: 'Book1', author_tsim: 'Julie', format: 'Book')
  end
  let(:config) do
    Blacklight::Configuration.new do |config|
      config.add_show_field 'title_tsim', label: 'Title:'
    end
  end

  let(:hash) do
    render template: "catalog/show.json", format: :json
    JSON.parse(rendered).with_indifferent_access
  end

  before do
    allow(view).to receive(:blacklight_config).and_return(config)
    assign :document, document
  end

  it "includes document attributes" do
    expect(hash).to include(data:
      {
        id: '123',
        type: 'Book',
        attributes: { 'title_tsim' => 'Book1' }
      })
  end
end
