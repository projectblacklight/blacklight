# <Release
#         UPC = xs:string
#         catzillaID = xs:int
#         explicit = xs:boolean
#         flags = xs:int
#         id = xs:string
#         label = xs:string
#         rating = xs:int
#         releaseDate = xs:dateTime
#         releaseYear = xs:int
#         rights = xs:int
#         title = xs:string
#         typeID = xs:int
#         >
# 
#     Content: 
#         Image*, Price*, Track*, Artist*, Category*, Fan*, Review*, ItemInfo?
# </Release>

module Yahoo
  module Music
    class Release < Base      
      attribute :id,          Integer
      attribute :title,       String
      attribute :upc,         String,  :matcher => "UPC"
      attribute :explicit,    Boolean, :matcher => "explicit"
      attribute :released_on, Date,    :matcher => "releaseDate"
      
      attribute :artists,     Artist
      attribute :categories,  Category
      attribute :reviews,     Review
      attribute :tracks,      Track
    end
  end
end