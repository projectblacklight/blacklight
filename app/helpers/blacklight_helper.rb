# frozen_string_literal: true
module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  def javascript_include_tag_if_exists(source, **options)
    javascript_include_tag(source, **options) if asset_exists?("#{source}.js")
  end

  private

  def asset_exists?(logical_path)
    Rails.application.assets&.resolver&.resolve(logical_path).present?
  rescue StandardError
    false
  end
end
