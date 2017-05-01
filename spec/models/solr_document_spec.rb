# frozen_string_literal: true

RSpec.describe SolrDocument do
  describe "access methods" do
    let(:solrdoc) do
      SolrDocument.new(id: '00282214', format: ['Book'], title_display: 'some-title')
    end

    describe "#[]" do
      subject { solrdoc[field] }

      context "with title_display" do
        let(:field) { :title_display }
        it { is_expected.to eq 'some-title' }
      end
      context "with format" do
        let(:field) { :format }
        it { is_expected.to eq ['Book'] }
      end
    end
    
    describe "#id" do
      subject { solrdoc.id }
      it { is_expected.to eq '00282214' }
    end
  end
end
