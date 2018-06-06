# frozen_string_literal: true
class AlternateController < CatalogController
  configure_blacklight do |config|
    config.index.thumbnail_method = :xyz
  end

  def xyz *args
    view_context.tag "img"
  end

  helper_method :xyz if respond_to? :helper_method

end
