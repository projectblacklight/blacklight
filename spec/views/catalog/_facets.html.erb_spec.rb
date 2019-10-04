# frozen_string_literal: true

RSpec.describe "catalog/_facets" do
  context "with facet groups" do
    before do
      stub_template('catalog/_facet_group.html.erb' => 'text')
      allow(view).to receive_messages(facet_group_names: [nil, nil])
      render
    end

    it "Calls facet_group for each name" do
      expect(rendered).to match(/^  text\n  text\n$/)
    end
  end
end
