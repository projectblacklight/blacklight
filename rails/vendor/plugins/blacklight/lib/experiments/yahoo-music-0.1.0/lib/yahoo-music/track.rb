# <Track
#         discNumber = xs:int
#         duration = xs:int
#         explicit = xs:boolean
#         flags = xs:int
#         id = xs:string
#         label = xs:string
#         popularity = xs:int
#         rating = xs:int
#         releaseYear = xs:int
#         rights = xs:int
#         title = xs:string
#         >
# 
#      Content: 
#          Image*, Price*, Track*, Artist*, Category*, Fan*, Review*, ItemInfo?
# </Track>

module Yahoo
  module Music
    class Track < Base      
      attribute :id,           Integer
      attribute :title,        String
      attribute :duration,     Integer
      attribute :explicit,     Boolean
      
      attribute :release_year, Integer, :matcher => "releaseYear"
      attribute :track_number, Integer, :matcher => "trackNumber"
      attribute :disc_number,  Integer, :matcher => "discNumber"
      
      attribute :artists,       Artist
      attribute :releases,      Release
    end
  end
end