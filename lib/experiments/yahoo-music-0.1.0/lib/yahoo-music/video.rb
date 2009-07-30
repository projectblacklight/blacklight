# <Video
#         copyrightYear = xs:int
#         duration = xs:int
#         explicit = xs:boolean
#         flags = xs:int
#         id = xs:string
#         label = xs:string
#         localOnly = xs:boolean
#         rating = xs:int
#         rights = xs:int
#         salesGenre = xs:int
#         title = xs:string
#         typeID = xs:int
#         >
# 
#     Content: 
#         Image*, Artist*, Client*, Category*, Album*, Media*, Bumper?, PaymentLabel?, FlaggedWith*, ItemInfo?, xspf:track?, RecentlyPlayed?
# </Video>

module Yahoo
  module Music
    class Video < Base      
      attribute :id,        Integer
      attribute :title,     String
      attribute :duration,  Integer
      attribute :explicit,  Boolean
      
      attribute :copyright_year, Integer, :matcher => "copyrightYear"      
    end
  end
end