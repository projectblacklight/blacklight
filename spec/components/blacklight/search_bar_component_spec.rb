# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::SearchBarComponent, type: :component do
  subject(:render) { render_inline(instance) }

  let(:search_action_url) { '/catalog' }
  let(:params_for_search) { { q: 'testParamValue' } }
  let(:instance) { described_class.new(url: search_action_url, params: params_for_search) }
  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.view = { list: nil, abc: nil }
    end
  end

  before do
    allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
  end

  it 'renders the field aria-label' do
    expect(render.css("[aria-label='#{I18n.t('blacklight.search.form.search.label')}']")).to be_present
  end
end
