# frozen_string_literal: true

RSpec.describe Blacklight::NestedOpenStructWithHashAccess do
  subject { described_class.new(Blacklight::OpenStructWithHashAccess) }

  describe '#key' do
    context 'for an object provided by the initializer' do
      subject { described_class.new(Blacklight::OpenStructWithHashAccess, a: { b: 1 }) }

      it 'copies the key to the initialized value' do
        expect(subject.a).to have_attributes key: :a, b: 1
      end
    end

    context 'for an object provided through assignment' do
      it 'copies the key to the initialized value' do
        subject.a!

        expect(subject.a).to have_attributes key: :a
      end
    end
  end

  describe "#deep_dup" do
    it "preserves the current class" do
      expect(described_class.new(described_class).deep_dup).to be_a_kind_of described_class
    end

    it "preserves the default proc" do
      nested = described_class.new Hash

      copy = nested.deep_dup
      copy.a[:b] = 1
      expect(copy.a[:b]).to eq 1
    end
  end

  describe '#<<' do
    subject { described_class.new(Blacklight::Configuration::Field) }

    it 'includes the key in the hash' do
      subject << :blah
      expect(subject.blah).to have_attributes(key: :blah)
    end
  end

  describe 'adding new parameters' do
    subject { described_class.new(Blacklight::Configuration::Field) }

    it 'strips the trailing !' do
      subject.blah!
      expect(subject.blah).to have_attributes(key: :blah)
      expect(subject.keys).to eq [:blah]
    end

    it 'supports direct assignment' do
      subject.blah = '123'
      expect(subject.blah).to eq '123'
      expect(subject.keys).to eq [:blah]
    end
  end
end
