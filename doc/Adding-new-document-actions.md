In your `CatalogController`, you can register document actions that display in various places within the default Blacklight UI:

- `add_show_tools_partial`: displays on the `catalog#show` page, using the `render_show_doc_actions` helper
- `add_results_document_tool`: displays on every search result, using the `render_index_doc_actions` helper
- `add_results_collection_tool`: displays at the top of a search result page, using the `render_results_collection_tools` helper
- `add_nav_action`: displays in the top application navbar, using the `render_nav_actions` helper

All types of actions take the same parameters, e.g.:

```ruby
      ##
      # Add a partial to the tools for rendering a document
      # @param partial [String] the name of the document partial
      # @param opts [Hash]
      # @option opts [String] :partial render this action using the provided partial
      # @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true.
      #                             The proc will receive the action configuration and the document or documents for the action.
      # @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true
      #                             The proc will receive the action configuration and the document or documents for the action.
      def add_show_tools_partial name, opts = {}
```

Examples:

```
class CatalogController
  ...

  # only show patron information if a user is logged in. Note that `current_user?` has to be defined as a helper method
  add_nav_action :patron_information, if: :current_user?

  # In Rails 4+, this can also be defined using an inline proc:
  add_nav_action :patron_information, if: Proc.new { |context, config, options| context.current_user? }

  # Actions can also trigger based on properties of the document:
  add_show_tools_partial :download_image_widget, if: Proc.new { |context, config, options| options[:document].image? }
 
  ...
end
```


## Show Tools
You can register an action that displays on the document show page using the `add_show_tools_partial` controller method. In addition to the functionality offered by the other types of tools and actions, show tools also offer conventional defaults.

Here is a trivial example of registering a new type of action:

```ruby
# app/controllers/catalog_controller.rb
class CatalogController
   add_show_tools_partial :my_custom_action

  ## OPTIONAL
  # def my_custom_action
  #   # render some content..
  #   # by default, Blacklight will try to render the partial of the same name (i.e. `app/views/catalog/my_custom_action.html.erb`)
  # end
end

# config/routes
Rails.application.routes.draw do
   ...
  get '/catalog/:id/my_custom_action' => 'catalog#my_custom_action', as: 'my_custom_action_catalog'
end
```


If the action will receive form data from a `POST` request, you can also register a callback for handling that request. Optionally, the `POST` params can be validated using a helper method.

```ruby
class CatalogController
  include Blacklight::Catalog
  ...

  # Register a new action called "email".
  # On a POST request, validate the params using the `#validate_email_params` method
  # and process the request using `#email_action`.
  add_show_tools_partial :email, callback: :email_action, validator: :validate_email_params

  def validate_email_params
    # validate that the posted params are suitable for the action
  end

  def email_action documents
    # send an email with the attached documents
  end
 
  ...
end
```

By convention, the action name is used to determine the route name for the action. For this email action, Blacklight will link to `email_catalog_path`.

The action will render the template [`catalog/email.html.erb`](https://github.com/projectblacklight/blacklight/blob/master/app/views/catalog/email.html.erb) template when the action is selected. This template provides a form, which, when submitted, will trigger the `email_action` method and will render the [`catalog/email_success.html.erb`](https://github.com/projectblacklight/blacklight/blob/master/app/views/catalog/email_success.html.erb) template. 