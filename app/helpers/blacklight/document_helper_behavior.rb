# frozen_string_literal: true

# Helper methods for catalog-like controllers that work with documents
module Blacklight::DocumentHelperBehavior
  ##
  # Get the classes to add to a document's div
  #
  # @param [Blacklight::Document] document
  # @return [String]
  def render_document_class(document = @document)
    types = document_presenter(document).display_type
    return if types.blank?

    Array(types).compact.map do |t|
      "#{document_class_prefix}#{t.try(:parameterize) || t}"
    end.join(' ')
  end

  ##
  # Return a prefix for the document classes infered from the document
  # @see #render_document_class
  # @return [String]
  def document_class_prefix
    'blacklight-'
  end

  ##
  # return the Bookmarks on a set of documents (all bookmarks on the page)
  # @private
  # @return [Enumerable<Bookmark>]
  def current_bookmarks
    @current_bookmarks ||= begin
      documents = @document.presence || @response.documents
      current_or_guest_user.bookmarks_for_documents(Array(documents)).to_a
    end
  end
  private :current_bookmarks

  ##
  # Check if the document is in the user's bookmarks
  # Note: we do string comparison of the classes, because hot reloading in the development environment may cause each to have
  #       separate versions of the class loaded (see document.class.object_id and Bookmark#document_type.object_id)
  # @param [Blacklight::Document] document
  # @return [Boolean]
  def bookmarked? document
    current_bookmarks.any? { |x| x.document_id == document.id && x.document_type.to_s == document.class.to_s }
  end

  ##
  # Returns a document presenter for the given document
  def document_presenter(document)
    document_presenter_class(document).new(document, self)
  end

  ##
  # Override this method if you want to use a differnet presenter for your documents
  # @param [Blacklight::Document] _document optional, here for extension + backwards compatibility only
  def document_presenter_class(_document = nil)
    case action_name
    when 'show', 'citation'
      blacklight_config.view_config(:show, action_name: action_name).document_presenter_class
    else
      blacklight_config.view_config(document_index_view_type, action_name: action_name).document_presenter_class
    end
  end
end
