require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Blacklight::CoreExt::DeepMergeUnlessBlank do
  
  def base_hash
    {:id=>1, :nested=>{:one=>1, :two=>[1, 2, 3, 4, 5]}, :blank=>'', :nil=>nil}
  end
  
  describe 'the deep_merge_unless_blank method' do
    
    it 'should not change the original hash' do
      a = {:id => 100}
      a.deep_merge_unless_blank(base_hash)
      a.should == {:id => 100}
    end
    
    it 'should not override values if the overriding values are blank' do
      a = {:nested=>{:one=>1, :two=>nil}}
      b = base_hash.deep_merge_unless_blank(a)
      b[:blank].should  == ''
      b[:id].should     == 1
      b[:nested].should == {:one=>1, :two=>[1, 2, 3, 4, 5]}
      b[:nil].should    == nil
    end
    
    it 'should override values that are not blank' do
      a = {:id=>'ID', :nested=>{:one=>1, :two=>2}}
      b = base_hash.deep_merge_unless_blank(a)
      b[:blank].should  == ''
      b[:id].should     == 'ID'
      b[:nested].should == {:one=>1, :two=>2}
      b[:nil].should    == nil
    end
    
  end
  
end