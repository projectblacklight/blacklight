# frozen_string_literal: true
require 'spec_helper'

describe "catalog/_document_list", type: :view do  

  before do
    allow(view).to receive_messages(document_index_view_type: "some-view", documents: [])
  end

  it "includes a class for the current view" do
    render
    expect(rendered).to have_selector(".documents-some-view")
  end
end
