# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HashAsHiddenFields do
  include HashAsHiddenFields
  before(:each) do
    @hash = {:q => "query", :search_field => "search_field", :per_page=>10, :page=>5, :extra_arbitrary_key=>"arbitrary_value", :f=> {:field1 => ["a", "b"], :field2=> ["z"]}}
  end

  it "should convert a hash with nested complex data to Rails-style hidden form fields" do

    generated = hash_as_hidden_fields(@hash)

    generated.should have_selector("input[type='hidden'][name='q'][value='query']")
    generated.should have_selector("input[type='hidden'][name='per_page'][value='10']")
    generated.should have_selector("input[type='hidden'][name='page'][value='5']")
    generated.should have_selector("input[type='hidden'][name='extra_arbitrary_key'][value='arbitrary_value']")
    generated.should have_selector("input[type='hidden'][name='f[field2][]'][value='z']")
    generated.should have_selector("input[type='hidden'][name='f[field1][]'][value='a']")
    generated.should have_selector("input[type='hidden'][name='f[field1][]'][value='b']")
    
  end

end
