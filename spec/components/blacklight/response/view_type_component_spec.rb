# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Response::ViewTypeComponent, type: :component do
  subject(:render) do
    render_inline(described_class.new(response: response, search_state: search_state))
  end

  let(:response) { instance_double(Blacklight::Response) }
  let(:search_state) { instance_double(Blacklight::SearchState) }

  before do
    allow(controller).to receive(:blacklight_config).and_return(config)
  end

  describe "when some views exist" do
    let(:config) do
      Blacklight::Configuration.new do |config|
        config.view.abc
        config.view.xyz
      end
    end

    it "draws the group" do
      expect(render.css('.view-type-group')).to be_present
    end
  end

  describe "when no views exist" do
    let(:config) do
      Blacklight::Configuration.new
    end

    it "draws nothing" do
      expect(render.to_html).to be_blank
    end
  end
end
