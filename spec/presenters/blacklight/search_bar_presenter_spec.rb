# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Blacklight::SearchBarPresenter do
  let(:controller) { CatalogController.new }
  let(:presenter) { described_class.new(controller, blacklight_config) }
  let(:blacklight_config) { Blacklight::Configuration.new }

  describe '#autocomplete_enabled?' do
    subject { presenter.autocomplete_enabled? }

    describe 'with autocomplete config' do
      let(:blacklight_config) do
        Blacklight::Configuration.new.configure do |config|
          config.autocomplete_enabled = true
          config.autocomplete_path = 'suggest'
        end
      end

      it { is_expected.to be true }
    end

    describe 'without disabled config' do
      let(:blacklight_config) do
        Blacklight::Configuration.new.configure do |config|
          config.autocomplete_enabled = false
          config.autocomplete_path = 'suggest'
        end
      end

      it { is_expected.to be false }
    end

    describe 'without path config' do
      let(:blacklight_config) do
        Blacklight::Configuration.new.configure do |config|
          config.autocomplete_enabled = true
        end
      end

      it { is_expected.to be false }
    end
  end

  describe "#autofocus?" do
    subject { presenter.autofocus? }

    context "on a catalog-like index page without query or facet parameters" do
      before do
        allow(controller).to receive(:action_name).and_return('index')
        allow(controller).to receive(:has_search_parameters?).and_return(false)
      end

      it { is_expected.to be true }
    end

    context "when not the catalog controller" do
      let(:controller) { ApplicationController.new }

      it { is_expected.to be false }
    end

    context "when on the catalog controller show page" do
      before do
        allow(controller).to receive(:action_name).and_return('show')
      end

      it { is_expected.to be false }
    end

    context "when search parameters are provided" do
      before do
        allow(controller).to receive(:has_search_parameters?).and_return(true)
      end

      it { is_expected.to be false }
    end
  end
end
