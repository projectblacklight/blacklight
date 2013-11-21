# -*- encoding : utf-8 -*-
class AlternateController < CatalogController  
  configure_blacklight do |config|
    config.index.thumbnail_method = :xyz
  end

  def xyz *args
    view_context.image_tag "asdfg"
  end
  
  helper_method :xyz

end 
