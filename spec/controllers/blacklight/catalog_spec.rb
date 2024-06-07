# frozen_string_literal: true

RSpec.describe Blacklight::Catalog do
  subject { controller }

  let(:controller) { (Class.new(ApplicationController) { include Blacklight::Catalog }).new }

  describe "#search_state" do
    subject { controller.send(:search_state) }

    let(:raw_params) { ActiveSupport::HashWithIndifferentAccess.new a: 1 }
    let(:params) { ActionController::Parameters.new raw_params }

    before do
      controller.blacklight_config.search_state_fields << :a
      allow(controller).to receive_messages(params: params)
    end

    it "creates a path object" do
      expect(subject).to be_kind_of Blacklight::SearchState
      expect(subject.params).to eq raw_params
    end
  end
end
