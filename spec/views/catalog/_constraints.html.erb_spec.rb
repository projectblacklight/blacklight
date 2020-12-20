# frozen_string_literal: true

RSpec.describe "catalog/constraints" do
  let :blacklight_config do
    Blacklight::Configuration.new do |config|
      config.view.xyz({})
    end
  end

  let(:query_params) { {} }
  let(:search_state) { Blacklight::SearchState.new(query_params, blacklight_config, controller) }

  before do
    allow(view).to receive(:search_state).and_return(search_state)
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
  end

  context 'when no constraints are set' do
    it "renders nothing" do
      render "catalog/constraints"
      expect(rendered.strip).to be_empty
    end
  end

  context 'when there are constraints' do
    before do
      allow(search_state).to receive(:has_constraints?).and_return(true)
    end

    it "renders a start over link" do
      allow(view).to receive(:search_action_path).with({}).and_return('http://xyz')
      render "catalog/constraints"
      expect(rendered).to have_link("Start Over", href: 'http://xyz')
    end

    context 'with the current view type' do
      it "renders a start over link with the current view type" do
        allow(view).to receive(:search_action_path).with(view: :xyz).and_return('http://xyz?view=xyz')
        params[:view] = 'xyz'
        render "catalog/constraints"
        expect(rendered).to have_link("Start Over", href: 'http://xyz?view=xyz')
      end
    end
  end
end
