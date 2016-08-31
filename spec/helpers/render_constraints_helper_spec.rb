# frozen_string_literal: true

describe RenderConstraintsHelper do

  let(:config) do
    Blacklight::Configuration.new do |config|
      config.add_facet_field 'type'
    end
  end

  before do
    # the helper methods below infer paths from the current route
    controller.request.path_parameters[:controller] = 'catalog'
    allow(helper).to receive(:search_action_path) do |*args|
      search_catalog_path *args
    end
  end

  describe '#render_constraints_query' do
    let(:my_engine) { double("Engine") }
    let(:params) { ActionController::Parameters.new(q: 'foobar', f: { type: 'journal' }) }
    subject { helper.render_constraints_query(params) }

    it "has a link relative to the current url" do
      expect(subject).to have_selector "a[href='/?f%5Btype%5D=journal']"
    end

    context 'with an ordinary hash' do
      let(:params) { { q: 'foobar', f: { type: 'journal' } } }

      it "has a link relative to the current url" do
        expect(subject).to have_selector "a[href='/?f%5Btype%5D=journal']"
      end
    end

    context "with a route_set" do
      let(:params) { ActionController::Parameters.new(q: 'foobar', f: { type: 'journal' }, route_set: my_engine) }
      it "accepts an optional route set" do
        expect(my_engine).to receive(:url_for).and_return('/?f%5Btype%5D=journal')
        expect(subject).to have_selector "a[href='/?f%5Btype%5D=journal']"
      end
    end
  end

  describe '#render_filter_element' do
    before do
      allow(helper).to receive(:blacklight_config).and_return(config)
      expect(helper).to receive(:facet_field_label).with('type').and_return("Item Type")
    end
    subject { helper.render_filter_element('type', ['journal'], path) }

    let(:params) { ActionController::Parameters.new q: 'biz' }
    let(:path) { Blacklight::SearchState.new(params, config) }

    it "has a link relative to the current url" do
      expect(subject).to have_link "Remove constraint Item Type: journal", href: "/catalog?q=biz"
      expect(subject).to have_selector ".filterName", text: 'Item Type'
    end

    context 'with string values' do
      subject { helper.render_filter_element('type', 'journal', path) }

      it "handles string values gracefully" do
        expect(subject).to have_link "Remove constraint Item Type: journal", href: "/catalog?q=biz"
      end
    end
  end

  describe "#render_constraints_filters" do
    let(:params) { ActionController::Parameters.new f: { 'type' => [''] } }
    before do
      allow(helper).to receive(:blacklight_config).and_return(config)
    end
    subject { helper.render_constraints_filters(params) }

    it "renders nothing for empty facet limit param" do
      expect(subject).to be_blank
    end
  end
end
