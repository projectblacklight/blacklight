require 'spec_helper'

RSpec.describe Blacklight::FacetValuePresenter do
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

  describe "#display" do
    subject { instance.display }
    context "with an ordinary facet" do
      let(:facet_field) { 'simple_field'}
      let(:item) { 'asdf'}
      before do
        allow(view_context).to receive(:facet_configuration_for_field).with('simple_field').and_return(double(:query => nil, :date => nil, :helper_method => nil, :url_method => nil))
      end
      it "is the facet value" do
        expect(subject).to eq 'asdf'
      end
    end

    context "with a helper_method argument in the configuration" do
      let(:facet_field) { 'helper_field'}
      let(:item) { 'qwerty'}
      before do
        allow(view_context).to receive(:facet_configuration_for_field).with('helper_field').and_return(double(:query => nil, :date => nil, :url_method => nil, :helper_method => :my_facet_value_renderer))
        allow(view_context).to receive(:my_facet_value_renderer).with('qwerty').and_return('abc')
      end
      it "calls the :helper_method argument" do
        expect(subject).to eq 'abc'
      end
    end

    context "for a query facet with a label" do
      let(:facet_field) { 'query_facet'}
      let(:item) { 'query_key'}
      before do
        allow(view_context).to receive(:facet_configuration_for_field).with('query_facet').and_return(double(:query => { 'query_key' => { :label => 'XYZ'}}, :date => nil, :helper_method => nil, :url_method => nil))
      end
      it "extracts the configuration label for a query facet" do
        expect(subject).to eq 'XYZ'
      end
    end

    context "when the facet is a date-type" do
      let(:facet_field) { 'date_facet'}
      let(:item) { '2012-01-01'}
      before do
        allow(view_context).to receive(:facet_configuration_for_field).with('date_facet').and_return(double('date' => true, :query => nil, :helper_method => nil, :url_method => nil))
      end

      it "localizes the label" do
        expect(subject).to eq 'Sun, 01 Jan 2012 00:00:00 +0000'
      end
    end

    context "when the facet has date-type localization options" do
      let(:facet_field) { 'date_facet'}
      let(:item) { '2012-01-01'}
      before do
        allow(view_context).to receive(:facet_configuration_for_field).with('date_facet').and_return(double('date' => { :format => :short }, :query => nil, :helper_method => nil, :url_method => nil))
      end

      it "localizes the label" do
        expect(subject).to eq '01 Jan 00:00'
      end
    end
  end
end

