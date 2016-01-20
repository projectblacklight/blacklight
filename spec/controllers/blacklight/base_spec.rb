# frozen_string_literal: true
require 'spec_helper'

describe Blacklight::Base do
  let(:controller) { (Class.new(ApplicationController) { include Blacklight::Base }).new }
  subject { controller}

  describe "#search_state" do
    let(:raw_params) { HashWithIndifferentAccess.new a: 1 }
    let(:params) { ActionController::Parameters.new raw_params }
    before { allow(controller).to receive_messages(params: params) }
    subject { controller.send(:search_state) }

    it "creates a path object" do
      expect(subject).to be_kind_of Blacklight::SearchState
      expect(subject.params).to eq raw_params
    end
  end
end
