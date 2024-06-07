# frozen_string_literal: true

# spec/support/features/search_helpers.rb
module Features
  module SearchHelpers
    def search_for q
      visit root_path
      fill_in "q", with: q
      click_on 'search'
    end

    def position_in_result_page(page, id)
      i = -1
      page.all(".index_title a").each_with_index do |link, idx|
        i = (idx + 1) if link['href'] =~ Regexp.new("#{Regexp.escape(id)}$")
      end
      i.to_i
    end

    def number_of_results_for_query(query)
      visit root_path
      fill_in "q", with: query
      click_on "search"
      get_number_of_results_from_page(page)
    end

    def number_of_results_from_page(page)
      tmp_value = Capybara.ignore_hidden_elements
      Capybara.ignore_hidden_elements = false
      val = begin
        page.find("meta[name=totalResults]")['content'].to_i
      rescue StandardError
        0
      end
      Capybara.ignore_hidden_elements = tmp_value
      val
    end
  end
end
