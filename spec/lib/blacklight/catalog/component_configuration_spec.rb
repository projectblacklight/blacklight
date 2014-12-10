require 'spec_helper'

describe Blacklight::Catalog::ComponentConfiguration do
  subject do
    Class.new do
      include Blacklight::Configurable
      include Blacklight::Catalog::ComponentConfiguration

      def some_existing_action
        1
      end
    end
  end

  describe ".add_show_tools_partial" do
    it "should define an action method" do
      subject.add_show_tools_partial :xyz
      expect(subject.new).to respond_to :xyz
    end

    it "should not replace an existing method" do
      subject.add_show_tools_partial :some_existing_action
      expect(subject.new.some_existing_action).to eq 1
    end
  end

  

end