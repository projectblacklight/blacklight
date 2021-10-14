# frozen_string_literal: true

RSpec.describe Blacklight::OpenStructWithHashAccess do
  it "provides hash-like accessors for OpenStruct data" do
    a = described_class.new foo: :bar, baz: 1

    expect(a[:foo]).to eq :bar
    expect(a[:baz]).to eq 1
    expect(a[:asdf]).to be_nil
  end

  it "provides hash-like writers for OpenStruct data" do
    a = described_class.new foo: :bar, baz: 1

    a[:asdf] = 'qwerty'
    expect(a.asdf).to eq 'qwerty'
  end

  it "treats symbols and strings interchangeably in hash access" do
    h = described_class.new

    h["string"] = "value"
    expect(h[:string]).to eq "value"
    expect(h.string).to eq "value"

    h[:symbol] = "value"
    expect(h["symbol"]).to eq "value"
    expect(h.symbol).to eq "value"
  end

  describe "internal hash table" do
    before do
      @h = described_class.new
      @h[:a] = 1
      @h[:b] = 2
    end

    it "exposes the internal hash table" do
      expect(@h.to_h).to be_a_kind_of(Hash)
      expect(@h.to_h[:a]).to eq 1
    end

    it "exposes keys" do
      expect(@h.keys).to include(:a, :b)
    end
  end

  describe "#key?" do
    subject do
      h = described_class.new
      h[:a] = 1
      h[:b] = 2
      h
    end

    it "is true if the key exists" do
      expect(subject.key?(:a)).to eq true
    end

    it "is false if the key does not exist" do
      expect(subject.key?(:c)).to eq false
    end
  end

  describe "#replace" do
    subject { described_class.new a: 1 }

    it "can use #replace to reorder the hash" do
      subject.replace b: 1
      expect(subject.b).to eq 1
    end
  end

  describe "#sort_by" do
    subject { described_class.new c: 3, b: 1, a: 2 }

    it "sorts the underlying hash" do
      sorted = subject.sort_by { |_k, v| v }
      expect(sorted.keys).to match_array [:b, :a, :c]
    end
  end

  describe "#sort_by!" do
    subject { described_class.new c: 3, b: 1, a: 2 }

    it "sorts the underlying hash" do
      subject.sort_by! { |_k, v| v }
      expect(subject.keys).to match_array [:b, :a, :c]
    end
  end

  describe "#merge" do
    before do
      @h = described_class.new
      @h[:a] = 1
      @h[:b] = 2
    end

    it "merges the object with a hash" do
      expect(@h.merge(a: 'a')[:a]).to eq 'a'
    end

    it "merges the object with another struct" do
      expect(@h.merge(described_class.new(a: 'a'))[:a]).to eq 'a'
    end
  end

  describe "#merge!" do
    before do
      @h = described_class.new
      @h[:a] = 1
      @h[:b] = 2
    end

    it "merges the object with a hash" do
      @h[:a] = 'a'
      expect(@h[:a]).to eq 'a'
    end

    it "merges the object with another struct" do
      @h.merge!(described_class.new(a: 'a'))
      expect(@h[:a]).to eq 'a'
    end
  end

  describe '#reverse_merge' do
    before do
      @h = described_class.new
      @h[:a] = 1
      @h[:b] = 2
    end

    it 'reverse merges the object with the hash, preserving the object class' do
      expect(@h.reverse_merge(b: 3, c: 4)).to have_attributes a: 1, b: 2, c: 4
    end
  end

  describe "#to_json" do
    subject { described_class.new a: 1, b: 2 }

    it "serializes as json" do
      expect(subject.to_json).to eq({ a: 1, b: 2 }.to_json)
    end
  end

  describe "#deep_dup" do
    subject { described_class.new a: 1, b: { c: 1 } }

    it "duplicates nested hashes" do
      copy = subject.deep_dup
      copy.a = 2
      copy.b[:c] = 2

      expect(subject.a).to eq 1
      expect(subject.b[:c]).to eq 1
      expect(copy.a).to eq 2
      expect(copy.b[:c]).to eq 2
    end
  end

  describe "#try" do
    subject { described_class.new a: 1 }

    it "works (and doesn't throw a stack error...)" do
      expect(subject.try(:a)).to eq 1
    end
  end
end
