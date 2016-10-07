# frozen_string_literal: true

# spec for default partial to display solr document fields in catalog INDEX view
# TODO: this test should move to render_partials_helper_spec.rb
RSpec.describe "/catalog/_index" do
  include BlacklightHelper
  include CatalogHelper

  let(:presenter) { Blacklight::IndexPresenter.new(document, view) }
  let(:document) { SolrDocument.new(id: 1, fname_1 => "val_1", fname_2 => "val2", fname_4 => "val_4") }
  let(:fname_1) { "one_field" }
  let(:fname_2) { "solr_field_not_in_config" }
  let(:fname_3) { "empty_field" }
  let(:fname_4) { "four_field" }

  let(:config) do
    Blacklight::Configuration.new do |config|
      config.show.display_type_field = 'asdf'
      config.add_index_field fname_1, :label => flabel_1
      config.add_index_field fname_3, :label => 'Three:'
      config.add_index_field fname_4, :label => flabel_4
    end
  end

  let(:flabel_1) { "One:" }
  let(:flabel_4) { "Four:" }

  before do
    allow(view).to receive(:action_name).and_return('index')

    allow(view).to receive(:blacklight_config).and_return(config)
    assigns[:document] = document
  end
  subject { view.render_document_partial document, :index, presenter: presenter }

  it "only displays fields listed in the initializer" do
    expect(subject).to_not include("val_2")
    expect(subject).to_not include(fname_2)
  end

  it "skips over fields listed in initializer that are not in solr response" do
    expect(subject).to_not include(fname_3)
  end

  it "displays field labels from initializer and raw solr field names in the class" do
    # labels
    expect(subject).to include(flabel_1)
    expect(subject).to include(flabel_4)
    # classes
    expect(subject).to include("blacklight-#{fname_1}")
    expect(subject).to include("blacklight-#{fname_4}")
  end

# this test probably belongs in a Cucumber feature
#  it "should display fields in the order listed in the initializer" do
#    pending
#  end

  it "has values for displayed fields" do
    expect(subject).to include("val_1")
    expect(subject).to include("val_4")
    expect(subject).to_not include("val_2")
  end

end
