require 'rubygems'
require 'test/unit'

# sudo gem install thoughtbot-shoulda -v 2.10.1
require 'shoulda'

require File.join(File.dirname(__FILE__), '..', 'lib', 'material_girl')

class MaterialGirlTest < Test::Unit::TestCase
  
  should 'build a composite object from a set of paths' do
    set = [
    	{:id=>1, :path=>'A::poems::one::1'},
    	{:id=>2, :path=>'A::poems::one::2'},
    	{:id=>5, :path=>'A::poems::two::11'},
    	{:id=>7, :path=>'A::b::c::a'},
    	{:id=>8, :path=>'A::b::c::a::11'},
    	{:id=>100, :path=>'Z::100'},
    	{:id=>7, :path=>'A::b::c::d'}
    ]
    root = MaterialGirl.parse(set)
    
    # the root has "a" and "b"
    assert_equal 2, root.children.size
    
    assert_equal ['A', 'Z'], root.children.map{|n|n.value}
    
    a = root.children[0]
    assert_equal 'A', a.value
    assert_equal ['poems', 'b'], a.children.map{|c|c.value}
    
    b = root.children[1]
    assert_equal 'Z', b.value
    assert_equal ['100'], b.children.map{|c|c.value}
    
    # a has poems
    poems = root.children[0].children[0]
    assert_equal 'poems', poems.value
    assert_equal ['one', 'two'], poems.children.map{|c|c.value}
    
    # "poems" has "one" and "two"
    assert_equal 2, poems.children.size
    poems_one = poems.children[0]
    assert_equal 'one', poems_one.value
    assert_equal ['1', '2'], poems_one.children.map{|c|c.value}
    
    poems_two = poems.children[1]
    assert_equal 'two', poems_two.value
    assert_equal ['11'], poems_two.children.map{|c|c.value}
    
    assert_equal ['100'], b.children.map{|c|c.value}
    
    expected_values = ["A", "Z", "poems", "b", "one", "two", "1", "2", "11", "c", "a", "d", "11", "100"]
    assert_equal expected_values, root.descendants.map{|c|c.value}
    
    two_11 = root.descendants.detect{|d|d.object and d.object[:id]==5}
    assert_equal ["two", "poems", "A", "root"], two_11.ancestors.map{|a|a.value}
    
  end
  
end