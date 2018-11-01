# frozen_string_literal: true

RSpec.describe Blacklight::HashAsHiddenFieldsHelperBehavior do
  let(:params) do
    { q: "query",
      search_field: "search_field",
      per_page: 10,
      page: 5,
      extra_arbitrary_key: "arbitrary_value",
      f: { field1: %w[a b], field2: ["z"] } }
  end
  let(:generated) { helper.render_hash_as_hidden_fields(params) }

  it "converts a hash with nested complex data to Rails-style hidden form fields" do
    expect(generated).to have_selector("input[type='hidden'][name='q'][value='query']", visible: false)
    expect(generated).to have_selector("input[type='hidden'][name='per_page'][value='10']", visible: false)
    expect(generated).to have_selector("input[type='hidden'][name='page'][value='5']", visible: false)
    expect(generated).to have_selector("input[type='hidden'][name='extra_arbitrary_key'][value='arbitrary_value']", visible: false)
    expect(generated).to have_selector("input[type='hidden'][name='f[field2][]'][value='z']", visible: false)
    expect(generated).to have_selector("input[type='hidden'][name='f[field1][]'][value='a']", visible: false)
    expect(generated).to have_selector("input[type='hidden'][name='f[field1][]'][value='b']", visible: false)
  end
end
