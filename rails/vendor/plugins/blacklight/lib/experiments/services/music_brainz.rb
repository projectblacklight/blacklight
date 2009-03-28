
#mbids = Blacklight::MusicBrainz::ArtistSearch.new.find_album_ids_by_artist_and_album('paul simon', 'The rhythm of the saints')
#puts Blacklight::LastFM::AlbumInfo.new.find_by_music_brainz_id(mbids)

# /images/covers/music/catkey.u3964377.jpg
# /images/covers/books/isbn.9786256782.jpg

require 'open-uri'
require 'cgi'

require 'rubygems'
require 'hpricot'

module Blacklight;end

module Blacklight
  
  module MusicBrainz
    
    class ArtistSearch
      
      def find_album_ids_by_artist_and_album(artist, album=nil)
        data=[]
        base_url = "http://musicbrainz.org/ws/1/release/?type=xml&releasetypes=Official&limit=10"
        url = base_url + "&artist=#{CGI.escape(artist)}"
        url += "&title=#{CGI.escape(album)}" unless album.to_s.empty?
        puts "
        
        MUSIC BRAINZ URL: #{url}
        
        "
        
        uri = URI.parse(url)
        RAILS_DEFAULT_LOGGER.info "*** URL: #{uri.to_s}"
        
        begin
          doc = Hpricot(open(uri.to_s))
        rescue
          puts "
          MUSIC BRAINZ CONNECTION ERROR: #{$!}
          "
          RAILS_DEFAULT_LOGGER.info "*** MUSIC BRAINZ ERROR: #{$!} "
          RAILS_DEFAULT_LOGGER.info "*** URL: #{uri.to_s}"
          return data
        end
        
        doc.search('//release').each do |release|
          # check values here: release.text() =~ album etc.
          data << release['id'] unless data.include?(release['id'])
        end
        data
      end
      
    end
    
  end
  
end
