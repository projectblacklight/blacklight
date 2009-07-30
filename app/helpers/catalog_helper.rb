module CatalogHelper
  
  #
  	# shortcut for built-in Rails helper, "number_with_delimiter"
  	#
  	def format_num(num); number_with_delimiter(num) end

  	#
  	#
  	#
  	def page_entries_info(collection, options = {})
      start = collection.next_page == 2 ? 1 : collection.previous_page * collection.per_page + 1
      total_hits = @response.total
      start_num = format_num(start)
      end_num = format_num(start + collection.per_page - 1)
      total_num = format_num(total_hits)

      entry_name = options[:entry_name] ||
        (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))

      if collection.total_pages < 2
        case collection.size
        when 0; "No #{entry_name.pluralize} found"
        when 1; "Displaying <b>1</b> #{entry_name}"
        else;   "Displaying <b>all #{total_num}</b> #{entry_name.pluralize}"
        end
      else
        "Displaying #{entry_name.pluralize} <b>#{start_num} - #{end_num}</b> of <b>#{total_num}</b>"
      end
  end
  
end