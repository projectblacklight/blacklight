# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Response::ViewTypeComponent, type: :component do
  subject(:render) do
    render_inline(described_class.new(response: response, views: views, search_state: search_state))
  end

  let(:response) { instance_double(Blacklight::Solr::Response, empty?: false) }
  let(:search_state) { instance_double(Blacklight::SearchState, to_h: { controller: 'catalog', action: 'index' }) }
  let(:view_config) { Blacklight::Configuration::ViewConfig.new }

  let(:custom_component_class) do
    Class.new(Blacklight::Icons::IconComponent) do
      # Override component rendering with our own value
      def call
        'blah'.html_safe
      end
    end
  end

  before do
    stub_const('Blacklight::Icons::DefComponent', custom_component_class)
  end

  describe "when some views exist" do
    before do
      stub_const('Blacklight::Icons::AbcComponent', custom_component_class)
    end

    let(:views) do
      {
        abc: view_config,
        def: view_config
      }
    end

    it "draws the group" do
      expect(render.css('.view-type-group')).to be_present
    end
  end

  context 'with a icon component class' do
    let(:views) do
      { abc: Blacklight::Configuration::ViewConfig.new(icon: Blacklight::Icons::ListComponent), def: view_config }
    end

    it 'draws the icon' do
      expect(render.css('.view-type-abc svg')).to be_present
    end
  end

  context 'with a icon component instance' do
    let(:views) do
      { abc: Blacklight::Configuration::ViewConfig.new(icon: Blacklight::Icons::ListComponent.new), def: view_config }
    end

    it 'draws the icon' do
      expect(render.css('.view-type-abc svg')).to be_present
    end
  end

  context 'with a icon with the svg given in-line' do
    let(:views) do
      { abc: Blacklight::Configuration::ViewConfig.new(icon: Blacklight::Icons::IconComponent.new(svg: 'blah')), def: view_config }
    end

    it 'draws the icon' do
      expect(render.css('.view-type-abc').text).to include 'blah'
    end
  end

  describe "when no views exist" do
    let(:views) do
      {}
    end

    it "draws nothing" do
      expect(render.to_html).to be_blank
    end
  end
end
