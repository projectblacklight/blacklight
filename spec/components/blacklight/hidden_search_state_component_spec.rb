# frozen_string_literal: true

RSpec.describe Blacklight::HiddenSearchStateComponent, type: :component do
  subject(:render) { render_inline(instance) }

  let(:params) do
    { q: "query",
      search_field: "search_field",
      per_page: 10,
      extra_arbitrary_key: "arbitrary_value",
      f: { field1: %w[a b], field2: ["z"] } }
  end
  let(:instance) { described_class.new(params: params) }
  let(:generated) { Capybara::Node::Simple.new("<div>#{render.to_html}</div>") }

  it "converts a hash with nested complex data to Rails-style hidden form fields" do
    expect(generated).to have_selector("input[type='hidden'][name='q'][value='query']", visible: :hidden)
    expect(generated).to have_selector("input[type='hidden'][name='per_page'][value='10']", visible: :hidden)
    expect(generated).to have_selector("input[type='hidden'][name='extra_arbitrary_key'][value='arbitrary_value']", visible: :hidden)
    expect(generated).to have_selector("input[type='hidden'][name='f[field2][]'][value='z']", visible: :hidden)
    expect(generated).to have_selector("input[type='hidden'][name='f[field1][]'][value='a']", visible: :hidden)
    expect(generated).to have_selector("input[type='hidden'][name='f[field1][]'][value='b']", visible: :hidden)
  end
end
