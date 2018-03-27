# frozen_string_literal: true

RSpec.describe Blacklight::ConstraintsPresenter do
  let(:config) do
    Blacklight::Configuration.new do |config|
      config.add_facet_field 'type'
    end
  end

  let(:search_state) { Blacklight::SearchState.new(params, config) }
  let(:type_config) { double(facet_field_label: "Item Type", date: nil, query: nil, helper_method: nil) }
  let(:controller) { CatalogController.new }
  let(:view_context) { controller.view_context }

  before do
    allow(view_context).to receive(:params).and_return(params)

    allow(search_state).to receive(:remove_facet_params).and_return('/stuff')
    allow(view_context).to receive(:search_action_path).and_return('/foo')
    allow(view_context).to receive(:search_state).and_return(search_state)
    allow(view_context).to receive(:facet_configuration_for_field).with('type').and_return(type_config)
  end

  let(:presenter) { described_class.new(params, view_context) }

  describe '#render' do
    subject { Capybara::Node::Simple.new(value) }

    let(:my_engine) { double("Engine") }
    let(:params) { ActionController::Parameters.new(q: 'foobar', f: { type: 'journal' }) }
    let(:value) { presenter.render }

    context "dood" do
      before do
        expect(view_context).to receive(:url_for).and_return('/?f%5Btype%5D=journal').exactly(3).times
      end
      it "has a link relative to the current url" do
        expect(subject).to have_selector "a[href='/?f%5Btype%5D=journal']"
      end
    end

    context "with a route_set" do
      let(:presenter) { described_class.new(params, view_context, my_engine) }

      it "accepts an optional route set" do
        expect(my_engine).to receive(:url_for).and_return('/?f%5Btype%5D=journal')
        expect(subject).to have_selector "a[href='/?f%5Btype%5D=journal']"
      end
    end
  end

  describe '#render_filter_element' do
    subject { presenter.send(:render_filter_element, 'type', ['journal'], path) }
    let(:params) { ActionController::Parameters.new q: 'biz' }
    let(:path) { Blacklight::SearchState.new(params, config) }

    it "has a link relative to the current url" do
      expect(view_context).to receive(:render).with("catalog/constraints_element",
                                                    label: "Item Type",
                                                    value: "journal",
                                                    options: { remove: "/foo", classes: ["filter", "filter-type"] })
      subject
    end

    context 'with string values' do
      subject { presenter.send(:render_filter_element, 'type', 'journal', path) }

      it "handles string values gracefully" do
        expect(view_context).to receive(:render).with("catalog/constraints_element",
                                                      label: "Item Type",
                                                      value: "journal",
                                                      options: { remove: "/foo", classes: ["filter", "filter-type"] })
        subject
      end
    end
  end

  describe "#render_constraints_filters" do
    let(:params) { ActionController::Parameters.new f: { 'type' => [''] } }
    subject { presenter.send(:render_constraints_filters) }

    it "renders nothing for empty facet limit param" do
      expect(subject).to be_blank
    end
  end
end
