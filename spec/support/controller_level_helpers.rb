module ControllerLevelHelpers
  module ControllerViewHelpers
    include Blacklight::Facet

    def blacklight_path
      @blacklight_path ||= Blacklight::Path.new(params, blacklight_config)
    end
  end

  def initialize_controller_helpers(helper)
    helper.extend ControllerViewHelpers
  end
end