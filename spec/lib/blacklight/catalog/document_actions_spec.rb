require 'spec_helper'

describe Blacklight::Catalog::DocumentActions do
  describe Blacklight::Catalog::DocumentActions::InheritableHash do
    subject { Blacklight::Catalog::DocumentActions::InheritableHash.new }
    it "should dup the values of the hash" do
      subject[:a] = 1
      subject[:b] = Blacklight::Configuration::ToolConfig.new v: 1

      copy = subject.inheritable_copy
      copy[:a] = 2
      copy[:b].v = 2

      expect(subject[:a]).to eq 1
      expect(subject[:b].v).to eq 1

      expect(copy[:a]).to eq 2
      expect(copy[:b].v).to eq 2
      
    end
  end
end