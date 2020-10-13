# frozen_string_literal: true

RSpec.describe Blacklight::Configuration::ViewConfig do
  subject { described_class.new(key: key, label: label) }

  let(:key) { 'my_view' }
  let(:label) { 'some label' }

  describe '#display_label' do
    it "looks up the label to display for the given document and field" do
      allow(I18n).to receive(:t).with(:"blacklight.search.view_title.my_view", default: [:"blacklight.search.view.my_view", label, nil, "My view"]).and_return('x')
      expect(subject.display_label(key)).to eq 'x'
    end
  end
end
