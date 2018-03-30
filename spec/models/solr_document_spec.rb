# frozen_string_literal: true

RSpec.describe SolrDocument do
  describe "access methods" do
    let(:solrdoc) do
      SolrDocument.new(id: '00282214', format: ['Book'], title_tsim: 'some-title')
    end

    describe "#[]" do
      subject { solrdoc[field] }

      context "with title_tsim" do
        let(:field) { :title_tsim }
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

  describe '.attribute' do
    subject(:title) { document.title }
    let(:doc_class) do
      Class.new(SolrDocument) do
        attribute :title, Blacklight::Types::String, 'title_tesim'
        attribute :author, Blacklight::Types::Array, 'author_tesim'
        attribute :date, Blacklight::Types::Date, 'date_dtsi'

      end
    end
    let(:document) do
      doc_class.new(id: '123',
                    title_tesim: ['Good Omens'],
                    author_tesim: ['Neil Gaiman', 'Terry Pratchett'],
                    date_dtsi: '1990-01-01T00:00:00Z')
    end

    it "casts the attributes" do
      expect(document.title).to eq 'Good Omens'
      expect(document.author).to eq ['Neil Gaiman', 'Terry Pratchett']
      expect(document.date).to eq Date.new(1990)
    end
  end
end
