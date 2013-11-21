# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

# spec for sidebar partial in catalog show view

describe "/catalog/_search_header.html.erb" do

  it "should render the default search header partials" do
    stub_template "_did_you_mean.html.erb" => "did_you_mean"
    stub_template "_constraints.html.erb" => "constraints"
    stub_template "_sort_and_per_page.html.erb" => "sort_and_per_page"
    render
    expect(rendered).to match /did_you_mean/
    expect(rendered).to match /constraints/
    expect(rendered).to match /sort_and_per_page/
  end
end
