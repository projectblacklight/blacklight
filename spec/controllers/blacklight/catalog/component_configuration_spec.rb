# frozen_string_literal: true

RSpec.describe Blacklight::DefaultComponentConfiguration do
  subject do
    Class.new do
      include Blacklight::Configurable
      include Blacklight::DefaultComponentConfiguration

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

    it "should allow the configuration to opt out of creating a method" do
      subject.add_show_tools_partial :some_missing_action, define_method: false
      expect(subject.new).not_to respond_to :some_missing_action
    end
  end
end
