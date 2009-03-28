require File.dirname(__FILE__) + '/test_helper.rb'

class TestYahooMusicArtist < Test::Unit::TestCase  
  def test_artist_initialization_from_string
    flexmock(Artist).should_receive(:fetch_and_parse).
      once.with("artist/v1/list/search/all/beirut").
      and_return(Hpricot::XML(fixture(:artist)))
    
    assert_nothing_raised do
      @artist = Artist.new("Beirut")
    end
  end
  
  def test_artist_initialization_from_id
    flexmock(Artist).should_receive(:fetch_and_parse).
      once.with("artist/v1/item/33892447").
      and_return(Hpricot::XML(fixture(:artist)))
      
    assert_nothing_raised do
      @artist = Artist.new(33892447)
    end
  end
  
  def test_artist_class_attributes_and_associations
    flexmock(Artist).should_receive(:fetch_and_parse).
      once.with("artist/v1/item/33892447").
      and_return(Hpricot::XML(fixture(:artist)))
      
    assert_nothing_raised do
      @artist = Artist.new(33892447)
    end
    
    assert ! Artist.attributes.empty?
    Artist.attributes.keys.each do |attribute|
      assert_respond_to @artist, attribute
    end
    
    assert ! Artist.associations.empty?
    Artist.associations.each do |association|
      assert_respond_to @artist, association
    end
  end
  
  def test_artist_instance_variables
    flexmock(Artist).should_receive(:fetch_and_parse).
      once.with("artist/v1/item/33892447").
      and_return(Hpricot::XML(fixture(:artist)))
      
    assert_nothing_raised do
      @artist = Artist.new(33892447)
    end
    
    assert_equal @artist.id,       33892447
    assert_equal @artist.name,     "Beirut"
    assert_equal @artist.website,  "http://www.beirutband.com/"
    assert_nothing_raised do
      assert @artist.releases.collect{|release| release.title}.include?("Lon Gisland EP")
    end
  end
end
