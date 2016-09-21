require 'spec_helper'

RSpec.describe Blacklight::FacetListPresenter do
  let(:response) { instance_double(Blacklight::Solr::Response) }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:controller) { CatalogController.new }
  let(:view_context) { controller.view_context }
  let(:instance) { described_class.new(response, view_context) }


  describe "#values?" do
    subject { instance.values?(fields) }
    let(:empty) { double(:items => [], :name => 'empty') }

    context "if there are any facets to display" do
      let(:a) { double(:items => [1, 2], :name => 'a') }
      let(:b) { double(:items => ['b', 'c'], :name => 'b') }
      let(:fields) { [a, b, empty] }

      it { is_expected.to be true }
    end

    context "if all facets are empty" do
      let(:fields) { [empty] }
      it { is_expected.to be false }
    end

    context "if no facets are displayable" do
      let(:blacklight_config) do
        Blacklight::Configuration.new { |config| config.add_facet_field 'basic_field', if: false }
      end

      before do
        allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
      end

      let(:fields) { [double(:items => [1, 2], :name => 'basic_field')] }
      it { is_expected.to be false }
    end
  end

  describe "render_partials" do
    let(:a) { double(:items => [1, 2]) }
    let(:b) { double(:items => ['b', 'c']) }
    let(:presenter_a) { instance_double(Blacklight::FacetFieldPresenter) }
    let(:presenter_b) { instance_double(Blacklight::FacetFieldPresenter) }
    before do
      allow(Blacklight::FacetFieldPresenter).to receive(:new).with(a, view_context).and_return(presenter_a)
      allow(Blacklight::FacetFieldPresenter).to receive(:new).with(b, view_context).and_return(presenter_b)
    end

    context "when facets are provided as an argument" do
      let(:empty) { double(items: []) }
      let(:presenter_empty) { instance_double(Blacklight::FacetFieldPresenter) }
      before do
        allow(Blacklight::FacetFieldPresenter).to receive(:new).with(empty, view_context).and_return(presenter_empty)
      end
      it "tries to render all provided facets" do
        expect(presenter_a).to receive(:render_facet_limit)
        expect(presenter_b).to receive(:render_facet_limit)
        expect(presenter_empty).to receive(:render_facet_limit)
        instance.render_partials [a, b, empty]
      end
    end

    it "defaults to the configured facets" do
      expect(instance).to receive(:facet_field_names) { [a, b] }
      expect(presenter_a).to receive(:render_facet_limit)
      expect(presenter_b).to receive(:render_facet_limit)
      instance.render_partials
    end
  end
end
