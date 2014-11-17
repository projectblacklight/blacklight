# -*- encoding : utf-8 -*-
module Blacklight::Base   
  extend ActiveSupport::Concern

  include Blacklight::Configurable
  include Blacklight::SolrHelper

  include Blacklight::Catalog::SearchContext

  included do  
    # When RSolr::RequestError is raised, the rsolr_request_error method is executed.
    # The index action will more than likely throw this one.
    # Example, when the standard query parser is used, and a user submits a "bad" query.
    rescue_from RSolr::Error::Http, :with => :rsolr_request_error if respond_to? :rescue_from
  end

  protected

  # when solr (RSolr) throws an error (RSolr::RequestError), this method is executed.
  def rsolr_request_error(exception)

    if Rails.env.development? || Rails.env.test?
      raise exception # Rails own code will catch and give usual Rails error page with stack trace
    else

      flash_notice = I18n.t('blacklight.search.errors.request_error')

      # If there are errors coming from the index page, we want to trap those sensibly

      if flash[:notice] == flash_notice
        logger.error "Cowardly aborting rsolr_request_error exception handling, because we redirected to a page that raises another exception"
        raise exception
      end

      logger.error exception

      flash[:notice] = flash_notice 
      redirect_to root_path
    end
  end
end
