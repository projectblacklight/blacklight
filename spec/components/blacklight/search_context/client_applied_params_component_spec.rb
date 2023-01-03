# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::SearchContext::ClientAppliedParamsComponent, type: :component do
  subject(:render) { instance.render_in(view_context) }

  let(:instance) { described_class.new }
  let(:view_context) { controller.view_context }

  before do
    view_context.view_paths.unshift(RSpec::Rails::ViewExampleGroup::StubResolverCache.resolver_for('application/_start_over.html.erb' => 'start over'))
    allow(view_context).to receive(:link_back_to_catalog).with(any_args)
  end

  it 'is blank without counter param' do
    expect(render).to be_blank
  end

  context 'with counter param' do
    before do
      controller.params[:counter] = 1
    end

    it 'is not blank' do
      expect(render).not_to be_blank
    end
  end
end
