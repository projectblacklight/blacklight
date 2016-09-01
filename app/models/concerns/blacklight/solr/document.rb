# frozen_string_literal: true
require 'rsolr'
##
##
# = Introduction
# Blacklight::Solr::Document is the module with logic for a class representing
# an individual document returned from Solr results.  It can be added in to any
# local class you want, but in default Blacklight a SolrDocument class is
# provided for you which is pretty much a blank class "include"ing
# Blacklight::Solr::Document.
#
# Blacklight::Solr::Document provides some DefaultFinders.
#
# It also provides support for Document Extensions, which advertise supported
# transformation formats.
#

module Blacklight::Solr::Document
  autoload :MoreLikeThis, 'blacklight/solr/document/more_like_this'

  extend ActiveSupport::Concern
  include Blacklight::Document
  include Blacklight::Document::ActiveModelShim
  include Blacklight::Solr::Document::MoreLikeThis

  def has_highlight_field? k
    return false if response['highlighting'].blank? or response['highlighting'][self.id].blank?
    
    response['highlighting'][self.id].key? k.to_s
  end

  def highlight_field k
    response['highlighting'][self.id][k.to_s].map(&:html_safe) if has_highlight_field? k
  end
end
