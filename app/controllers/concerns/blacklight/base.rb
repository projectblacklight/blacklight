# frozen_string_literal: true
module Blacklight::Base
  extend ActiveSupport::Concern

  include Blacklight::Configurable
  include Blacklight::SearchContext
end
