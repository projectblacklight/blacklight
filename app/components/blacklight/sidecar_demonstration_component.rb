# This approach permits the addition of sidecar files in the installing application, but relies on less stable APIs
module Blacklight
  class SidecarDemonstrationComponent < ::ViewComponent::Base
    class << self
      def _sidecar_files(extensions)
        return [] unless source_location
        engine_directory = File.dirname(source_location)
        engine_sidecars = _sidecar_files_in(engine_directory, extensions)
        app_directory = "#{Rails.root}/#{engine_directory.slice(engine_directory.index(view_component_path)..-1)}"
        if app_directory == engine_directory
          return engine_sidecars.values
        else
          return engine_sidecars.merge(_sidecar_files_in(app_directory, extensions)).values
        end
      end

      # this is essentially the original _sidecar_files implementation with a parameterized directory,
      # allowing lookup in the installing app if necessary. It returns a Hash to allow override via merge
      def _sidecar_files_in(directory, extensions)
        return {} unless directory

        extensions = extensions.join(",")

        # view files in a directory named like the component
        filename = File.basename(source_location, ".rb")
        component_name = name.demodulize.underscore

        # Add support for nested components defined in the same file.
        #
        # for example
        #
        # class MyComponent < ViewComponent::Base
        #   class MyOtherComponent < ViewComponent::Base
        #   end
        # end
        #
        # Without this, `MyOtherComponent` will not look for `my_component/my_other_component.html.erb`
        nested_component_files =
          if name.include?("::") && component_name != filename
            Dir["#{directory}/#{filename}/#{component_name}.*{#{extensions}}"]
          else
            []
          end

        # view files in the same directory as the component
        sidecar_files = Dir["#{directory}/#{component_name}.*{#{extensions}}"]

        sidecar_directory_files = Dir["#{directory}/#{component_name}/#{filename}.*{#{extensions}}"]

        paths = (sidecar_files - [source_location] + sidecar_directory_files + nested_component_files).uniq
        paths.map { |path|  [path.sub(directory, ""), path]}.to_h
      end
    end
  end
end
