# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::SearchBarComponent, type: :component do
  let(:instance) { described_class.new(url: search_action_url, params: params_for_search) }

  let(:search_action_url) { '/catalog' }
  let(:params_for_search) { { q: 'testParamValue' } }
  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.view = { list: nil, abc: nil }
    end
  end

  before do
    allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
  end

  context 'with the default button' do
    subject(:render) { render_inline(instance) }

    it 'renders the search field and a button' do
      expect(render.css("input[aria-label='#{I18n.t('blacklight.search.form.search.label')}']")).to be_present
      expect(render.css("button#search")).to be_present
    end
  end

  context 'when a button is passed in' do
    subject(:render) do
      render_inline(instance) do |c|
        c.search_button do
          controller.view_context.tag.button "hello", id: 'custom_search'
        end
      end
    end

    it 'renders the search field and a button' do
      expect(render.css("input[aria-label='#{I18n.t('blacklight.search.form.search.label')}']")).to be_present
      expect(render.css("button#search")).not_to be_present
      expect(render.css("button#custom_search")).to be_present
    end
  end
end
