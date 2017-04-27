# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Blacklight::LinkAlternatePresenter do
  let(:view_context) { double }
  let(:document) { SolrDocument.new(id: 9999) }
  let(:options) { {} }
  let(:config) { Blacklight::Configuration.new }
  let(:parameter_class) { ActionController::Parameters }
  let(:params) { parameter_class.new }
  let(:controller) { double }
  let(:search_state) { Blacklight::SearchState.new(params, config, controller) }

  let(:presenter) { described_class.new(view_context, document, options) }
  before do
    allow(view_context).to receive(:search_state).and_return(search_state)
    allow(view_context).to receive(:polymorphic_url) do |doc, opts|
      "http://test.host/catalog/#{doc.to_param}.#{opts[:format]}"
    end
  end

  describe "#render" do
    subject { presenter.render }
    let(:expected_html) do
      '<link rel="alternate" title="xml" type="application/xml" href="http://test.host/catalog/9999.xml" />' \
      '<link rel="alternate" title="dc_xml" type="text/xml" href="http://test.host/catalog/9999.dc_xml" />' \
      '<link rel="alternate" title="oai_dc_xml" type="text/xml" href="http://test.host/catalog/9999.oai_dc_xml" />'
    end
    it { is_expected.to be_equivalent_to expected_html }
  end
end
