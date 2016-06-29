# frozen_string_literal: true
require 'spec_helper'

describe HashAsHiddenFieldsHelper do
  include HashAsHiddenFieldsHelper
  before(:each) do
    @hash = {:q => "query", :search_field => "search_field", :per_page=>10, :page=>5, :extra_arbitrary_key=>"arbitrary_value", :f=> {:field1 => ["a", "b"], :field2=> ["z"]}}
  end

  it "converts a hash with nested complex data to Rails-style hidden form fields" do

    generated = render_hash_as_hidden_fields(@hash)

    expect(generated).to have_selector("input[type='hidden'][name='q'][value='query']")
    expect(generated).to have_selector("input[type='hidden'][name='per_page'][value='10']")
    expect(generated).to have_selector("input[type='hidden'][name='page'][value='5']")
    expect(generated).to have_selector("input[type='hidden'][name='extra_arbitrary_key'][value='arbitrary_value']")
    expect(generated).to have_selector("input[type='hidden'][name='f[field2][]'][value='z']")
    expect(generated).to have_selector("input[type='hidden'][name='f[field1][]'][value='a']")
    expect(generated).to have_selector("input[type='hidden'][name='f[field1][]'][value='b']")
    
  end

end
