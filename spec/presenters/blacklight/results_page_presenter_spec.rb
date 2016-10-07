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

  describe "#search_to_page_title_filter" do
    let(:facet) { 'foo' }
    let(:blacklight_config) { Blacklight::Configuration.new }
    subject { instance.send(:search_to_page_title_filter, facet, values) }

    context "with a single value" do
      let(:values) { ['bar'] }
      it { is_expected.to eq "Foo: bar" }
    end

    context "with two values" do
      let(:values) { ['bar', 'baz'] }
      it { is_expected.to eq "Foo: bar and baz" }
    end
    context "more than two values" do
      let(:values) { ['bar', 'baz', 'foobar'] }
      it { is_expected.to eq "Foo: 3 selected" }
    end
  end

  describe "#search_to_page_title" do
    before do
      allow(instance).to receive(:default_search_field).and_return(Blacklight::Configuration::SearchField.new(:key => 'default_search_field', :display_label => 'Default'))
      allow(view_context).to receive(:label_for_search_field).with(nil).and_return('')
    end

    let(:blacklight_config) { Blacklight::Configuration.new }
    let(:params) { ActionController::Parameters.new(q: 'foobar', f: { format: ["Book"] }) }
    subject { instance.search_to_page_title(params) }

    it { is_expected.to eq "foobar / Format: Book" }
  end
end
