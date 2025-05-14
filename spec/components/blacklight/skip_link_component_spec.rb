# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::SkipLinkComponent, type: :component do
  before do
    allow(vc_test_controller).to receive(:blacklight_config).and_return(blacklight_config)
    render_inline(described_class.new)
  end

  context 'with no search fields' do
    let(:blacklight_config) do
      Blacklight::Configuration.new.configure do |config|
        config.search_fields = {}
      end
    end

    it 'renders skip links with correct link to search' do
      expect(page).to have_link("Skip to main content", href: '#main-container')
      expect(page).to have_link("Skip to search", href: "#q")
    end
  end

  context 'with one search field' do
    let(:blacklight_config) do
      Blacklight::Configuration.new.configure do |config|
        config.search_fields =  { "all_fields" => "" }
      end
    end

    it 'renders skip links with correct link to search' do
      expect(page).to have_link("Skip to main content", href: "#main-container")
      expect(page).to have_link("Skip to search", href: "#q")
    end
  end

  context 'with two search field' do
    let(:blacklight_config) do
      Blacklight::Configuration.new.configure do |config|
        config.search_fields =  { "all_fields" => "", "title_field" => "" }
      end
    end

    it 'renders skip links with correct link to search' do
      expect(page).to have_link("Skip to main content", href: "#main-container")
      expect(page).to have_link("Skip to search", href: "#search_field")
    end
  end
end
