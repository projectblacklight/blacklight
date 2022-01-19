# frozen_string_literal: true

RSpec.describe Blacklight::Engine do
  [:bookmarks_http_method, :email_regexp, :facet_missing_param, :sms_mappings].each do |dep_key|
    describe "config.#{dep_key}" do
      subject { described_class.config }

      let(:unlikely_value) { 'unlikely value' }

      it 'is deprecated' do
        allow(Deprecation).to receive(:warn)
        subject.send(dep_key)
        expect(Deprecation).to have_received(:warn)
      end

      it 'delegates to config.blacklight' do
        allow(subject.blacklight).to receive(dep_key).and_return(unlikely_value)
        expect(subject.send(dep_key)).to eql(unlikely_value)
      end
    end

    describe "config.#{dep_key}=" do
      subject { described_class.config }

      let(:unlikely_value) { 'unlikely value' }

      it 'is deprecated' do
        allow(Deprecation).to receive(:warn)
        allow(subject.blacklight).to receive(:"#{dep_key}=").with(unlikely_value)
        subject.send(:"#{dep_key}=", unlikely_value)
        expect(Deprecation).to have_received(:warn)
      end

      it 'delegates to config.blacklight' do
        allow(subject.blacklight).to receive(:"#{dep_key}=").with(unlikely_value)
        subject.send(:"#{dep_key}=", unlikely_value)
        expect(subject.blacklight).to have_received(:"#{dep_key}=").with(unlikely_value)
      end
    end
  end
end
