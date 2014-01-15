require 'spec_helper'

describe 'Blacklight::Utils' do
  describe Blacklight::OpenStructWithHashAccess do
    it "should provide hash-like accessors for OpenStruct data" do
      a = Blacklight::OpenStructWithHashAccess.new :foo => :bar, :baz => 1

      expect(a[:foo]).to eq :bar
      expect(a[:baz]).to eq 1
      expect(a[:asdf]).to be_nil
    end

    it "should provide hash-like writers for OpenStruct data" do
      a = Blacklight::OpenStructWithHashAccess.new :foo => :bar, :baz => 1

      a[:asdf] = 'qwerty'
      expect(a.asdf).to eq 'qwerty'

    end
    
    it "should treat symbols and strings interchangeably in hash access" do
      h = Blacklight::OpenStructWithHashAccess.new
      
      h["string"] = "value"
      expect(h[:string]).to eq "value"
      expect(h.string).to eq "value"
      
      h[:symbol] = "value"
      expect(h["symbol"]).to eq "value"
      expect(h.symbol).to eq "value"      
    end

    describe "internal hash table" do
      before do
        @h = Blacklight::OpenStructWithHashAccess.new

        @h[:a] = 1
        @h[:b] = 2


      end
      it "should expose the internal hash table" do
        expect(@h.to_h).to be_a_kind_of(Hash)
        expect(@h.to_h[:a]).to eq 1
      end

      it "should expose keys" do
        expect(@h.keys).to include(:a, :b)
      end

      it "should expose merge" do
        expect(@h.merge(:a => 'a')[:a]).to eq 'a'
      end

    end
  end
end
