require 'deprecation'

class Blacklight::Configuration
  class ViewConfig < Blacklight::OpenStructWithHashAccess
    class Show < ViewConfig
      extend Deprecation
      self.deprecation_horizon = 'blacklight 6.0'

      def html_title
        Deprecation.warn(self.class, "config.show.html_title is deprecated; use config.show.title_field instead")
        fetch(:html_title, title_field)
      end

      def heading
        Deprecation.warn(self.class, "config.show.heading is deprecated; use config.show.title_field instead")
        fetch(:heading, title_field)
      end

      def display_type
        Deprecation.warn(self.class, "config.show.display_type is deprecated; use config.show.display_type_field instead")
        fetch(:display_type, display_type_field)
      end

      def html_title= value
        Deprecation.warn(self.class, "config.show.html_title is deprecated; use config.show.title_field instead")
        super value
        self.title_field = value
      end

      def heading= value
        Deprecation.warn(self.class, "config.show.heading is deprecated; use config.show.title_field instead")
        super value
        self.title_field = value
      end

      def display_type= value
        Deprecation.warn(self.class, "config.show.display_type is deprecated; use config.show.display_type_field instead")
        super value
        self.display_type_field = value
      end
    end

    class Index < ViewConfig
      extend Deprecation
      self.deprecation_horizon = 'blacklight 6.0'

      def record_display_type
        Deprecation.warn(self.class, "config.index.record_display_type is deprecated; use config.index.display_type_field instead")
        fetch(:record_display_type, display_type_field)
      end

      def record_display_type= value
        Deprecation.warn(self.class, "config.index.record_display_type is deprecated; use config.index.display_type_field instead")
        super value
        self.display_type_field = value
      end

      def show_link
        Deprecation.warn(self.class, "config.index.show_link is deprecated; use config.index.title_field instead")   
        fetch(:show_link, title_field)
      end

      def show_link= value
        Deprecation.warn(self.class, "config.index.show_link is deprecated; use config.index.title_field instead")
        super value
        self.title_field = value
      end

    end
  end
end
