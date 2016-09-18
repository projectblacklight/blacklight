require 'spec_helper'
require 'equivalent-xml'

RSpec.describe Blacklight::FacetItemPresenter do
  let(:controller) { CatalogController.new }
  let(:view_context) { controller.view_context }
  let(:instance) { described_class.new(facet_field, item, view_context) }
  let(:search_state) { double(add_facet_params_and_redirect: { controller: 'catalog' }) }

  before do
    allow(view_context).to receive(:search_state).and_return(search_state)
    allow(view_context).to receive(:search_action_path) do |*args|
      '/catalog'
    end
  end

  describe "#facet_value" do
    let(:item) { double(:value => 'A', :hits => 10) }
    before do
      allow(view_context).to receive(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil, :single => false, :url_method => nil))
      allow(instance).to receive(:facet_display_value).and_return('Z')
    end

    describe "simple case" do
      let(:expected_html) { '<span class="facet-label"><a class="facet-select" href="/catalog">Z</a></span><span class="facet-count">10</span>' }
      let(:facet_field) { 'simple_field' }

      it "uses facet_display_value" do
        result = instance.facet_value
        expect(result).to be_equivalent_to(expected_html).respecting_element_order
      end
    end

    describe "when :url_method is set" do
      let(:expected_html) { '<span class="facet-label"><a class="facet-select" href="/blabla">Z</a></span><span class="facet-count">10</span>' }
      let(:facet_field) { 'simple_field' }
      it "uses that method" do
        allow(view_context).to receive(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil, :single => false, :url_method => :test_method))
        allow(view_context).to receive(:test_method).with('simple_field', item).and_return('/blabla')
        result = instance.facet_value
        expect(result).to be_equivalent_to(expected_html).respecting_element_order
      end
    end

    describe "when :suppress_link is set" do
      let(:expected_html) { '<span class="facet-label">Z</span><span class="facet-count">10</span>' }
      let(:facet_field) { 'simple_field' }
      it "suppresses the link" do
        result = instance.facet_value(suppress_link: true)
        expect(result).to be_equivalent_to(expected_html).respecting_element_order
      end
    end
  end
end
