# frozen_string_literal: true

RSpec.describe Blacklight::Base do
  subject { controller }

  let(:controller) { (Class.new(ApplicationController) { include Blacklight::Base }).new }

  describe "#search_state" do
    subject { controller.send(:search_state) }

    let(:raw_params) { HashWithIndifferentAccess.new a: 1 }
    let(:params) { ActionController::Parameters.new raw_params }

    before { allow(controller).to receive_messages(params: params) }

    it "creates a path object" do
      expect(subject).to be_kind_of Blacklight::SearchState
      expect(subject.params).to eq raw_params
    end
  end
end
