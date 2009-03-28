
require 'test/unit'
require './multi_param'

class MultiParamTest < Test::Unit::TestCase
  
  def setup
    params = {
      'q'=>'a query',
      'location_facet'=>'one|two',
      'format_facet'=>'three|four',
      'subject_facet'=>'one',
      'random_param'=>10
    }
    @mp = MultiParam.new(params, ['location_facet', 'format_facet', 'subject_facet'])
  end
  
  def test_fields
    assert_equal ['location_facet', 'format_facet', 'subject_facet'], @mp.fields
  end
  
  def test_params
    assert_equal({"location_facet"=>["one", "two"], "format_facet"=>["three", "four"], "subject_facet"=>["one"]}, @mp)
  end
  
  def test_add
    assert_equal({"location_facet"=>["one", "two"], "format_facet"=>["three", "four", "CD"], "subject_facet"=>["one"]}, @mp.add('format_facet', 'CD'))
  end
  
  def test_remove
    assert_equal({"location_facet"=>["one", "two"], "subject_facet"=>["one"]}, @mp.remove('format_facet'))
  end
  
  # This prevents empty params from hangin' out
  def test_removing_last_param_removes_entire_key
    assert_equal({"location_facet"=>["one", "two"], "format_facet"=>["three", "four"]}, @mp.remove('subject_facet', 'one'))
  end
  
  def test_toggle
    assert_equal({"location_facet"=>["one", "two"], "format_facet"=>["-three", "four"], "subject_facet"=>["one"]}, @mp.toggle('format_facet', 'three'))
  end
  
  def test_has?
    assert @mp.has?('location_facet')
    assert @mp.has?('location_facet', 'two')
    assert @mp.has?('location_facet', 'one')
    assert false==@mp.has?('location_facet', 'NOPE')
  end
  
end