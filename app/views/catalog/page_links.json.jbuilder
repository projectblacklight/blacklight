# frozen_string_literal: true

if @search_context.previous_document || @search_context.next_document
  json.prev page_links_document_path(@search_context.previous_document, @search_context.counter - 1) if @search_context.previous_document
  json.next page_links_document_path(@search_context.next_document, @search_context.counter + 1) if @search_context.next_document
  json.counterRaw @search_context.counter
  json.totalRaw @search_context.total
  json.counterDelimited number_with_delimiter(@search_context.counter) if @search_context.counter
  json.totalDelimited number_with_delimiter(@search_context.total) if @search_context.total.positive?
end
