require 'spec_helper'

RSpec.describe Blacklight::ResultsPagePresenter do
  let(:response) { instance_double(Blacklight::Solr::Response, empty?: true) }
  let(:controller) { CatalogController.new }
  let(:view_context) { controller.view_context }
  let(:instance) { described_class.new(response, view_context) }

  describe "#facets" do
    subject { instance.facets }
    it { is_expected.to be_instance_of Blacklight::FacetListPresenter }
  end

  describe "#empty?" do
    subject { instance.empty? }
    it { is_expected.to be true }
  end
end
