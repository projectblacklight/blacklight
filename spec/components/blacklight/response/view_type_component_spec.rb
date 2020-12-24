# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Response::ViewTypeComponent, type: :component do
  subject(:render) { render_inline(instance) }

  let(:instance) { described_class.new(response: response, search_state: search_state) }
  let(:response) { double(Blacklight::Solr::Response, empty?: false) }
  let(:search_state) { instance_double(Blacklight::SearchState, to_h: { controller: 'catalog', action: 'index' }) }
  let(:icon) { instance_double(Blacklight::Icon, svg: '<svg></svg>', options: {}) }

  before do
    allow(controller).to receive(:blacklight_config).and_return(config)
    allow(Blacklight::Icon).to receive(:new).and_return(icon)
  end

  context "when some views exist" do
    let(:config) do
      Blacklight::Configuration.new do |config|
        config.view.a
        config.view.b
        config.view.c
      end
    end
    let(:instance) do
      described_class.new(response: response, search_state: search_state, views: %w[a b c], selected: 'a')
    end

    it "draws the group" do
      expect(render.css('.btn-group.view-type-group')).to be_present
      expect(render.css('.btn.view-type-a.active').to_html).to include '<span class="caption">A</span>'
      expect(render.css('.btn.view-type-b').to_html).to include '<span class="caption">B</span>'
      expect(render.css('.btn.view-type-c').to_html).to include '<span class="caption">C</span>'
    end
  end

  context "when no views exist" do
    let(:config) do
      Blacklight::Configuration.new
    end

    it "draws nothing" do
      expect(render.to_html).to be_blank
    end
  end

  context "when the response is empty" do
    let(:response) { instance_double(Blacklight::Solr::Response, empty?: true) }

    let(:config) do
      Blacklight::Configuration.new
    end

    it "draws nothing" do
      expect(render.to_html).to be_blank
    end
  end
end
