# frozen_string_literal: true

# Methods added to this helper will be available to all templates in the hosting application
module Blacklight::BlacklightHelperBehavior
  include Blacklight::UrlHelperBehavior
  include Blacklight::LayoutHelperBehavior
  include Blacklight::IconHelperBehavior

  ##
  # Get the name of this application from an i18n string
  # key: blacklight.application_name
  # Try first in the current locale, then the default locale
  #
  # @return [String] the application name
  def application_name
    # It's important that we don't use ActionView::Helpers::CacheHelper#cache here
    # because it returns nil.
    Rails.cache.fetch 'blacklight/application_name' do
      t('blacklight.application_name',
        default: t('blacklight.application_name', locale: I18n.default_locale))
    end
  end

  ##
  # Render a partial of an arbitrary format inside a
  # template of a different format. (e.g. render an HTML
  # partial from an XML template)
  # code taken from:
  # http://stackoverflow.com/questions/339130/how-do-i-render-a-partial-of-a-different-format-in-rails (zgchurch)
  #
  # @param [String] format suffix
  # @yield
  def with_format(format)
    old_formats = formats
    self.formats = [format]
    yield
    self.formats = old_formats
    nil
  end

  # @return [Class]
  def search_bar_presenter_class
    blacklight_config.view_config(action_name: :index).search_bar_presenter_class
  end
end
