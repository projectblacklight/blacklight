require 'spec_helper'

describe Blacklight::Base do
  let(:controller) { (Class.new(ApplicationController) { include Blacklight::Base }).new }
  subject { controller}

  describe "#blacklight_path" do
    let(:params) { double }
    before { allow(controller).to receive_messages(params: params) }
    subject { controller.send(:blacklight_path) }

    it "creates a path object" do
      expect(subject).to be_kind_of Blacklight::Path
      expect(subject.params).to be params
    end
  end
end