require 'spec_helper'

RSpec.describe Blacklight::Configuration::Field do
  let(:instance) { described_class.new(key: key, label: label) }
  let(:key) { 'some_key' }
  let(:label) { 'some label' }

  describe '#display_label' do
    subject { instance.display_label('my_context') }
    it "looks up the label to display for the given document and field" do
      allow(I18n).to receive(:t).with(:"blacklight.search.fields.my_context.some_key", default: [:"blacklight.search.fields.some_key", label, instance.default_label]).and_return('x')
      expect(subject).to eq 'x'
    end
  end

  describe "#field_label" do
    it "looks up the label as an i18n string" do
      allow(I18n).to receive(:t).with(:some_key, default: []).and_return "my label"
      label = instance.send :field_label, :some_key

      expect(label).to eq "my label"
    end

    it "passes the provided i18n keys to I18n.t" do
      allow(I18n).to receive(:t).with(:key_a, default: [:key_b, "default text"])

      label = instance.send :field_label, :key_a, :key_b, "default text"
    end

    it "compacts nil keys (fixes rails/rails#19419)" do
      allow(I18n).to receive(:t).with(:key_a, default: [:key_b])

      label = instance.send :field_label, :key_a, nil, :key_b
    end
  end
end
