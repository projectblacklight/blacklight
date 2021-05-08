# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Response::ViewTypeComponent, type: :component do
  subject(:render) do
    render_inline(described_class.new(response: response, views: views, search_state: search_state))
  end

  let(:response) { instance_double(Blacklight::Response) }
  let(:search_state) { instance_double(Blacklight::SearchState, to_h: { controller: 'catalog', action: 'index' }) }
  let(:view_config) { Blacklight::Configuration::ViewConfig.new(icon: 'list') }

  describe "when some views exist" do
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

  describe "when no views exist" do
    let(:views) do
      {}
    end

    it "draws nothing" do
      expect(render.to_html).to be_blank
    end
  end
end
