# frozen_string_literal: true

RSpec.describe "catalog/constraints" do
  let!(:blacklight_config) do
    Blacklight::Configuration.new do |config|
      config.view.xyz
    end
  end

  before do
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
  end

  it "renders nothing if no constraints are set" do
    allow(view.search_state).to receive_messages(has_constraints?: false)
    render partial: "catalog/constraints"
    expect(rendered).to be_empty
  end

  it "renders a start over link" do
    allow(view).to receive(:search_action_path).with({}).and_return('http://xyz')
    allow(view.search_state).to receive_messages(has_constraints?: true)
    render partial: "catalog/constraints"
    expect(rendered).to have_link("Start Over", :href => 'http://xyz')
  end

  it "renders a start over link with the current view type" do
    allow(view).to receive(:search_action_path).with(view: :xyz).and_return('http://xyz?view=xyz')
    allow(view.search_state).to receive_messages(has_constraints?: true)
    params[:view] = 'xyz'
    render partial: "catalog/constraints"
    expect(rendered).to have_link("Start Over", :href => 'http://xyz?view=xyz')
  end

end
