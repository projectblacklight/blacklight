# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::SearchBarComponent, type: :component do
  let(:instance) { described_class.new(url: search_action_url, params: params_for_search) }

  let(:search_action_url) { '/catalog' }
  let(:params_for_search) { { q: 'testParamValue' } }
  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.view = { list: nil, abc: nil }
      config.add_search_field('test_field', label: 'Test Field')
    end
  end

  before do
    allow(vc_test_controller).to receive(:blacklight_config).and_return(blacklight_config)
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
        c.with_search_button do
          vc_test_controller.view_context.tag.button "hello", id: 'custom_search'
        end
      end
    end

    it 'renders the search field and a button' do
      expect(render.css("input[aria-label='#{I18n.t('blacklight.search.form.search.label')}']")).to be_present
      expect(render.css("button#search")).not_to be_present
      expect(render.css("button#custom_search")).to be_present
    end
  end

  context 'with prepend' do
    subject(:render) do
      render_inline(instance) do |c|
        c.with_prepend { 'stuff before' }
      end
    end

    it 'renders the prepended value' do
      expect(render.to_html).to include 'stuff before'
    end
  end

  context 'with append' do
    subject(:render) do
      render_inline(instance) do |c|
        c.with_append { 'stuff after' }
      end
    end

    it 'renders the appended value' do
      expect(render.to_html).to include 'stuff after'
    end
  end

  context 'with extra inputs' do
    subject(:render) do
      render_inline(instance) do |c|
        c.with_before_input_group { vc_test_controller.view_context.tag.input name: 'foo' }
        c.with_before_input_group { vc_test_controller.view_context.tag.input name: 'bar' }
      end
    end

    it 'renders the extra inputs' do
      expect(render.css("input[name='foo']")).to be_present
      expect(render.css("input[name='bar']")).to be_present
    end
  end

  context 'with one search field' do
    subject(:render) { render_inline(instance) }

    it 'sets the rounded border class' do
      expect(render.css('.rounded-start')).to be_present
    end
  end

  context 'with multiple search fields' do
    subject(:render) { render_inline(instance) }

    let(:blacklight_config) do
      Blacklight::Configuration.new.configure do |config|
        config.view = { list: nil, abc: nil }
        config.add_search_field('test_field', label: 'Test Field')
        config.add_search_field('another_field', label: 'Another Field')
      end
    end

    it 'sets the rounded border class' do
      expect(render.css('.rounded-0')).to be_present
    end
  end
end
