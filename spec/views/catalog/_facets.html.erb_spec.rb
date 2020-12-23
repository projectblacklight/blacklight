# frozen_string_literal: true

RSpec.describe "catalog/_facets" do
  let(:config) { instance_double(Blacklight::Configuration, facet_group_names: [nil, nil]) }

  before do
    stub_template('catalog/_facet_group.html.erb' => 'text')
    allow(view).to receive(:blacklight_config).and_return(config)
    render
  end

  it "Calls facet_group for each name" do
    expect(rendered).to match(/^  text\n  text\n$/)
  end
end
