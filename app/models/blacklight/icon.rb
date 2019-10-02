# frozen_string_literal: true

module Blacklight
  class Icon
    attr_reader :icon_name, :aria_hidden, :label, :role
    ##
    # @param [String, Symbol] icon_name
    # @param [Hash] options
    # @param [String] classes additional classes separated by a string
    # @param [Boolean] aria_hidden include aria_hidden attribute
    # @param [Boolean] label include <title> and aria-label as part of svg
    # @param [String] role role attribute to be included in svg
    def initialize(icon_name, classes: '', aria_hidden: false, label: true, role: 'image')
      @icon_name = icon_name
      @classes = classes
      @aria_hidden = aria_hidden
      @label = label
      @role = role
    end

    ##
    # Returns an updated version of the svg source
    # @return [String]
    def svg
      svg = ng_xml.at_xpath('svg')
      svg['role'] = role
      svg['aria-labelled-by'] = unique_id if label
      svg.add_child("<title id='#{unique_id}'>#{icon_label}</title>") if label
      ng_xml.to_xml
    end

    def icon_label
      I18n.translate("blacklight.icon.#{icon_name}", default: "#{icon_name} icon")
    end

    def unique_id
      @unique_id ||= "bl-icon-#{icon_name}-#{SecureRandom.hex(8)}"
    end

    ##
    # @return [Hash]
    def options
      {
        class: classes,
        "aria-hidden": (true if aria_hidden)
      }
    end

    ##
    # @return [String]
    def path
      "blacklight/#{icon_name}.svg"
    end

    ##
    # @return [String]
    def file_source
      raise Blacklight::Exceptions::IconNotFound, "Could not find #{path}" if file.blank?

      file.source.force_encoding('UTF-8')
    end

    def ng_xml
      @ng_xml ||= Nokogiri::XML(file_source).remove_namespaces!
    end

    private

    def file
      # Rails.application.assets is `nil` in production mode (where compile assets is enabled).
      # This workaround is based off of this comment: https://github.com/fphilipe/premailer-rails/issues/145#issuecomment-225992564
      (Rails.application.assets || ::Sprockets::Railtie.build_environment(Rails.application)).find_asset(path)
    end

    def classes
      " blacklight-icons #{@classes} ".strip
    end
  end
end
