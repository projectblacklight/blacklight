# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Response::PaginationComponent, type: :component do
  let(:render) do
    with_request_url '/catalog?q=foo' do
      render_inline(instance)
    end
  end

  let(:instance) { described_class.new(response: response) }

  context 'when there are many results' do
    let(:response) { instance_double(Blacklight::Solr::Response, total: 10, current_page: 5, limit_value: 10_000, total_pages: 100) }

    context 'with default config' do
      before { render }

      it "has links to deep pages" do
        expect(page).not_to have_link '98'
        expect(page).to have_link '99'
        expect(page).to have_link '100'
        expect(page).not_to have_link '101'
      end
    end

    context 'when a different configuration that removes deep links is passed as a parameter' do
      let(:instance) { described_class.new(response: response, left: 5, right: 0, outer_window: nil) }

      before { render }

      it "does not link to deep pages" do
        expect(page).to have_link '1'
        expect(page).not_to have_link '100'
      end
    end

    context 'when a different configuration that removes deep links is configured in the controller' do
      before do
        allow(controller.blacklight_config.index)
          .to receive(:pagination_options)
          .and_return(theme: 'blacklight', left: 5, right: 0)
        render
      end

      it "does not link to deep pages" do
        expect(page).to have_link '1'
        expect(page).not_to have_link '100'
      end
    end
  end
end
