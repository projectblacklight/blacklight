require 'spec_helper'

describe Blacklight::SolrHelper do
  it "should raise a deprecation error" do
    expect(Deprecation).to receive(:warn)
    class TestClass
      include Blacklight::SolrHelper
    end
  end

  after { Object.send(:remove_const, :TestClass) }
end
