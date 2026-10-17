# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::System::DropdownComponent, type: :component do
  it 'includes a link for each choice' do
    search_state = instance_double(Blacklight::SearchState, params_for_search: "http://example.com")
    rendered = render_inline(described_class.new(
                               param: :per_page,
                               choices: [
                                 ['10 per page', 10],
                                 ['20 per page', 20]
                               ],
                               search_state: search_state,
                               selected: 20,
                               interpolation: :count
                             ))

    expect(rendered.css('a').length).to eq 2
    expect(rendered.css('a')[0].text).to eq '10 per page'
    expect(rendered.css('a')[0].attributes).not_to have_key 'aria-current'
    expect(rendered.css('a')[1].text).to eq '20 per page'
    expect(rendered.css('a')[1].attributes).to have_key 'aria-current'
  end
end
