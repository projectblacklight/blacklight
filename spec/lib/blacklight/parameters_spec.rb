# frozen_string_literal: true

RSpec.describe Blacklight::Parameters do
  describe "sanitize_search_params" do
    subject { described_class.sanitize(params) }

    context "with nil values" do
      let(:params) { ActionController::Parameters.new a: nil, b: 1 }
      it "removes them" do
        expect(subject).to_not have_key(:a)
        expect(subject[:b]).to eq 1
      end
    end

    context "with blacklisted keys" do
      let(:params) { ActionController::Parameters.new action: true, controller: true, id: true, commit: true, utf8: true }
      it "removes them" do
        expect(subject).to be_empty
      end
    end
  end
end
