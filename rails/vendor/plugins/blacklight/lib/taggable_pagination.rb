#
# Code started from: AR/ActsAsTaggable mod is from: http://www.mckinneystation.com/2007/08/20/pagination-with-acts_as_taggable_on_steroids-acts_as_ferret-and-will_paginate/
#
module ActiveRecord
  module Acts #:nodoc:
    module Taggable #:nodoc:
      
      module SingletonMethods
        
        def tagging_counts(tag)
          count_by_sql("select count(*) FROM tags, taggings WHERE " + sanitize_sql(['tags.name = ? AND tags.id = taggings.tag_id AND taggings.taggable_type = ?', tag, name]))
        end
        
        def paginate_by_tag(tag, options = {}, find_options = {})
          page, per_page, total = wp_parse_options(options)#WillPaginate::Finder::ClassMethods.send(:wp_parse_options, options)
          offset = (page.to_i - 1) * per_page
          find_options.merge!(:offset => offset, :limit => per_page.to_i)
          items = tag ? find_tagged_with(tag, find_options) : paginate(options)
          options.delete :page
          options.delete :per_page
          count = tag ? tagging_counts(tag) : self.count(options)
          returning WillPaginate::Collection.new(page, per_page, count) do |p|
            p.replace items
          end
        end
      
      end
      
    end
  end
end