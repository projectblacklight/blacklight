require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe 'Blacklight::Utils' do
  describe Blacklight::OpenStructWithHashAccess do
    it "should provide hash-like accessors for OpenStruct data" do
      a = Blacklight::OpenStructWithHashAccess.new :foo => :bar, :baz => 1

      a[:foo].should == :bar
      a[:baz].should == 1
      a[:asdf].should be_nil
    end

    it "should provide hash-like writers for OpenStruct data" do
      a = Blacklight::OpenStructWithHashAccess.new :foo => :bar, :baz => 1

      a[:asdf] = 'qwerty'
      a.asdf.should == 'qwerty'

    end
    
    it "should treat symbols and strings interchangeably in hash access" do
      h = Blacklight::OpenStructWithHashAccess.new
      
      h["string"] = "value"
      h[:string].should == "value"
      h.string.should == "value"
      
      h[:symbol] = "value"
      h["symbol"].should == "value"
      h.symbol.should == "value"      
    end

    describe "internal hash table" do
      before do
        @h = Blacklight::OpenStructWithHashAccess.new

        @h[:a] = 1
        @h[:b] = 2


      end
      it "should expose the internal hash table" do
        @h.to_h.should be_a_kind_of(Hash)
        @h.to_h[:a].should == 1
      end

      it "should expose keys" do
        @h.keys.should include(:a, :b)
      end

      it "should expose merge" do
        @h.merge(:a => 'a')[:a].should == 'a'
      end

    end
  end
end
