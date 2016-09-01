# frozen_string_literal: true
module Blacklight::Solr::Response::Response
  def response
    self[:response] || {}
  end
  
  # short cut to response['numFound']
  def total
    response[:numFound].to_s.to_i
  end
  
  def start
    response[:start].to_s.to_i
  end

  def empty?
    total.zero?
  end
end
