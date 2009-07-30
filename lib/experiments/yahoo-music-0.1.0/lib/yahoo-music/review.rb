# <Review
#         id = xs:int
#         publishDate = dateTime
#         source = xs:string
#         writer = xs:string
#         >
#
#     Content:
#         { xs:string }
# </Review>

module Yahoo
  module Music
    class Review < Base      
      attr_reader :content
      
      attribute :id,            Integer
      attribute :source,        String
      attribute :published_on,  Date, :matcher => "publishDate"
      attribute :website,       String
      
      def initialize(xml)
        @content = xml.inner_html
        super
      end
      
      def to_s
        self.content
      end
    end
  end
end