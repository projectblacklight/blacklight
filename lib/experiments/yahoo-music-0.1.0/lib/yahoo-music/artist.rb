# <Artist
#         catzillaID = xs:int
#         flags = xs:int
#         hotzillaID = xs:int
#         id = xs:string
#         name = xs:string
#         rating = xs:int
#         salesGenreCode = xs:int
#         sortName = xs:string
#         trackCount = xs:int
#         website = xs:string
#         >
# 
#     Content: 
#         Image*, Category*, Releases?, TopTracks?, TopSimilarArtists?, RadioStations?, Events?, Fans?, NewsArticles?, ReleaseReviews?, ShortBio?, FullBio?, ItemInfo?, Video*
# </Artist>

module Yahoo
  module Music
    class Artist < Base      
      attribute :id,          Integer
      attribute :name,        String
      attribute :sort_name,   String, :matcher => "sortName"
      attribute :website,     String
      
      attribute :releases,    Release
      attribute :categories,  Category
      attribute :videos,      Video
    end
  end
end