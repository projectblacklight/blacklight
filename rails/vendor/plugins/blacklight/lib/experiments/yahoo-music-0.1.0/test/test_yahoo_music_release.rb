require File.dirname(__FILE__) + '/test_helper.rb'

class TestYahooMusicRelease < Test::Unit::TestCase
  def test_release_initialization_from_string
    flexmock(Release).should_receive(:fetch_and_parse).
      once.with("release/v1/list/search/all/lon+gisland+ep").
      and_return(Hpricot::XML(fixture(:release)))
    
    assert_nothing_raised do
      @release = Release.new("Lon Gisland EP")
    end
  end
  
  def test_release_initialization_from_id
    flexmock(Release).should_receive(:fetch_and_parse).
      once.with("release/v1/item/39477375").
      and_return(Hpricot::XML(fixture(:release)))
      
    assert_nothing_raised do
      @release = Release.new(39477375)
    end
  end
  
  def test_release_class_attributes_and_associations
    flexmock(Release).should_receive(:fetch_and_parse).
      once.with("release/v1/item/39477375").
      and_return(Hpricot::XML(fixture(:release)))
      
    assert_nothing_raised do
      @release = Release.new(39477375)
    end
    
    assert ! Release.attributes.empty?
    Release.attributes.keys.each do |attribute|
      assert_respond_to @release, attribute
    end
    
    assert ! Release.associations.empty?
    Release.associations.each do |association|
      assert_respond_to @release, association
    end
  end
  
  def test_release_instance_variables
    flexmock(Release).should_receive(:fetch_and_parse).
      once.with("release/v1/item/39477375").
      and_return(Hpricot::XML(fixture(:release)))
      
    assert_nothing_raised do
      @release = Release.new(39477375)
    end
    
    assert_equal @release.id,       39477375
    assert_equal @release.title,    "Lon Gisland EP"
    assert_equal @release.upc,      "600197005224"
    assert_equal @release.explicit, false
    assert_nothing_raised do
      ["Elephant Gun", "My Family's Role In The World Revolution", "Scenic World (Version)",
       "The Long Island Sound", "Carousels"].each do |track_title|
         assert @release.tracks.collect{|track| track.title}.include?(track_title)
      end
    end
  end
end
