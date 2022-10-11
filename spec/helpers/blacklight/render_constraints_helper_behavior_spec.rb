# frozen_string_literal: true

RSpec.describe Blacklight::RenderConstraintsHelperBehavior do
  around { |test| Deprecation.silence(described_class) { test.call } }

  let(:config) do
    Blacklight::Configuration.new do |config|
      config.add_facet_field 'type'
      config.add_search_field 'title'
    end
  end

  before do
    # the helper methods below infer paths from the current route
    controller.request.path_parameters[:controller] = 'catalog'
    allow(helper).to receive(:search_action_path) do |*args|
      search_catalog_path *args
    end

    allow(helper).to receive(:blacklight_config).and_return(config)
    allow(controller).to receive(:search_state_class).and_return(Blacklight::SearchState)
  end

  describe '#render_constraints_query' do
    subject { helper.render_constraints_query(params) }

    let(:my_engine) { double("Engine") }
    let(:params) { ActionController::Parameters.new(q: 'foobar', f: { type: 'journal' }) }

    it "has a link relative to the current url" do
      expect(subject).to have_link 'Remove constraint', href: '/catalog?f%5Btype%5D%5B%5D=journal'
    end
  end

  describe '#render_constraints_clauses' do
    subject { helper.render_constraints_clauses(params) }

    let(:my_engine) { double("Engine") }
    let(:params) { ActionController::Parameters.new(clause: { '0': { field: 'title', query: 'nature' } }, f: { type: 'journal' }) }

    it 'renders the clause constraint' do
      expect(subject).to have_selector '.constraint-value', text: /Title\s+nature/
    end

    it "has a link relative to the current url" do
      expect(subject).to have_link 'Remove constraint Title: nature', href: '/catalog?f%5Btype%5D%5B%5D=journal'
    end
  end

  describe '#render_filter_element' do
    subject { helper.render_filter_element('type', ['journal'], path) }

    before do
      allow(helper).to receive(:blacklight_config).and_return(config)
      expect(helper).to receive(:facet_field_label).with('type').and_return("Item Type")
    end

    let(:params) { ActionController::Parameters.new q: 'biz' }
    let(:path) { Blacklight::SearchState.new(params, config, controller) }

    it "has a link relative to the current url" do
      expect(subject).to have_link "Remove constraint Item Type: journal", href: "/catalog?q=biz"
      expect(subject).to have_selector ".filter-name", text: 'Item Type'
    end

    context 'with string values' do
      subject { helper.render_filter_element('type', 'journal', path) }

      it "handles string values gracefully" do
        expect(subject).to have_link "Remove constraint Item Type: journal", href: "/catalog?q=biz"
      end
    end

    context 'with multivalued facets' do
      subject { helper.render_filter_element('type', [%w[journal book]], path) }

      it "handles such values gracefully" do
        expect(subject).to have_link "Remove constraint Item Type: journal OR book", href: "/catalog?q=biz"
      end
    end
  end

  describe "#render_constraints_filters" do
    subject { helper.render_constraints_filters(params) }

    let(:params) { ActionController::Parameters.new f: { 'type' => [''] } }

    it "renders nothing for empty facet limit param" do
      expect(subject).to be_blank
    end
  end
end
