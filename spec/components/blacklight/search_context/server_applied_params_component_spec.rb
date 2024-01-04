# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::SearchContext::ServerAppliedParamsComponent, type: :component do
  subject(:render) { instance.render_in(view_context) }

  let(:instance) { described_class.new }
  let(:current_search_session) { nil }
  let(:view_context) { controller.view_context }

  before do
    # Not sure why we need to re-implement rspec's stub_template, but
    # we already were, and need a Rails 7.1+ safe alternate too
    # https://github.com/rspec/rspec-rails/commit/4d65bea0619955acb15023b9c3f57a3a53183da8
    # https://github.com/rspec/rspec-rails/issues/2696
    replace_hash = { 'application/_start_over.html.erb' => 'start over' }
    if ::Rails.version.to_f >= 7.1
      controller.prepend_view_path(RSpec::Rails::ViewExampleGroup::StubResolverCache.resolver_for(replace_hash))
    else
      view_context.view_paths.unshift(RSpec::Rails::ViewExampleGroup::StubResolverCache.resolver_for(replace_hash))
    end

    allow(view_context).to receive(:current_search_session).and_return current_search_session
    allow(view_context).to receive(:link_back_to_catalog).with(any_args)
  end

  it 'is blank without current session' do
    expect(render).to be_blank
  end

  context 'with current session' do
    let(:current_search_session) { double(query_params: { q: 'abc' }) }

    it 'is not blank' do
      expect(render).not_to be_blank
    end
  end
end
