# <Category
#         artistCount = xs:int
#         hasAudioStation = xs:boolean
#         hasRadioStation = xs:boolean
#         hasVideoStation = xs:boolean
#         id = xs:string
#         name = xs:string
#         rating = xs:int
#         releaseCount = xs:int
#         trackCount = xs:int
#         type = ("Genre"|"Theme"|"Era")
#         videoCount = xs:int
#         >
# 
#     Content: 
#         ShortDescription?, LongDescription?, Artist*, Station*, Category*
# </Category>

module Yahoo
  module Music
    class Category < Base      
      attribute :id,    Integer
      attribute :name,  String
    end
  end
end