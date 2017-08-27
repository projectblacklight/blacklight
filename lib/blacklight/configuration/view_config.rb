# frozen_string_literal: true
class Blacklight::Configuration
  class ViewConfig < Blacklight::OpenStructWithHashAccess
    def search_bar_presenter_class
      super || Blacklight::SearchBarPresenter
    end

    class Show < ViewConfig
      def document_presenter_class
        super || Blacklight::ShowPresenter
      end
    end

    class Index < ViewConfig
      def document_presenter_class
        super || Blacklight::IndexPresenter
      end
    end
  end
end
