describe Blacklight::Configuration::Field do
  subject { described_class.new(key: key, label: label) }
  let(:key) { 'some_key' }
  let(:label) { 'some label' }

  describe '#display_label' do
    it "looks up the label to display for the given document and field" do
      allow(I18n).to receive(:t).with(:"blacklight.search.fields.my_context.some_key", default: [:"blacklight.search.fields.some_key", label, subject.default_label]).and_return('x')
      expect(subject.display_label('my_context')).to eq 'x'
    end
  end
end
