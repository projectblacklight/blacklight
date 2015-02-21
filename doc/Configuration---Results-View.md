Note that Solr fields you configure for display must be STORED fields in the Solr index.

# Index View

![Index View](https://f.cloud.github.com/assets/111218/2058436/e322543c-8b71-11e3-90a3-6744cb6628c7.png)

## Basic configuration

The index view is configured from your CatalogController's blacklight configuration. Here is a listing of the configuration parameters Blacklight uses and their default values:

```ruby

configure_blacklight do |config|
   ...

   config.index.title_field = unique_key
   config.index.partials = [:index_header, :thumbnail, :index]
   config.index.display_type_field = 'format'
   config.index.group = false

   ...
end
```

The configuration keys are not limited or restricted, so plugins or applications that need additional index configuration may add additional parameters directly.

```ruby
config.index.my_custom_parameters = "some value"
```

#### title_field

The title field setting determines the Solr field that Blacklight will use to display the record title. 

If you need additional customization (e.g. to concatenate two fields, etc), you can provide your own implementation of the `#document_heading` partial method, e.g.

```
module ApplicationHelper
  def document_heading document = nil
    document ||= @document
    document.first(:main_title) + " - " + document.first(:sub_title)
  end
end
```

#### Partials and display_type_field

You can configure the partials that Blacklight will assemble to display a search result.

By default, Blacklight will render these three basic partials when displaying a document. The partial names are a combination of two configuration settings. The base name of the partial is given by the `partials` setting. The suffix is based on the type of document given by the value of the `display_type_field`. If a partial is not found with the given `display_type_field` value, it will attempt to render a default version of the base partial. If no matching partial is found, nothing will be displayed for that document.

For example, using the default values and a document without a `format` field, these partials will be rendered:

 * `index_header_default.html.erb`: The document title and document actions
 * `thumbnail_default.html.erb`: A representative thumbnail (from the `thumbnail_field` configuration below)
 * `index_default.html.erb`: A list of document fields

However, if the document had a format field with the value `book`, Blacklight would attempt to render these partials:

* `index_header_book.html.erb`; if that doesn't exist, it will fall back to `index_header_default.html.erb`
* `thumbnail_book.html.erb`; fall back to `thumbnail_default.html.erb`
* `index_book.html.erb`; fall back to `index_default.html.erb`

Blacklight only provides default partials for these three base partials. If you were to provide an `app/views/catalog/_index_book.html.erb` partial, Blacklight would render that partial instead of the default.


#### (Advanced) Result Collapsing / Grouping

Blacklight can use Solr's result collapsing feature. To use this feature, set the `group` parameter to the name of the field that Blacklight should use to render collapsed result sets. 

#### Respond_to

You can also affect which search results response formats are available, in addition to the out-of-the-box HTML, JSON, Atom and RSS feeds.

Options include:

- use the Rails default rendering options:
  ```ruby
  config.index.respond_to.yaml = true
  ```

- don't render the format (e.g. for overriding defaults):
  ```ruby
    config.index.respond_to.yaml = false
  ```

- options for render
  ```ruby
    config.index.respond_to.yaml = { layout: 'custom-layout' }
  ```

- custom proc to render
  ```ruby
    config.index.respond_to.yaml = lambda { render text: "stuff" }
   ```

- controller method to call to render
    ```ruby
    config.index.respond_to.yaml = :my_custom_yaml_serialization
    ```

### Fields

The fields the `index_default` template uses to render fields are configured using `add_index_field`:

```
config.add_index_field 'title_display'
```

This will add a field to the display that will pull values from the Solr field 'title_display'. If the field is multivalued, Blacklight will concatenate them using a separator (", " by default). This value can also be configured:

```
config.add_index_field 'multivalued_title', separator: '; '
```

Additional configuration options can be also be used:

#### Labels

By default, Blacklight will calculate a default label by `humanizing` the Solr field (which is rarely desirable, but convenient for initial configuration). To customize the label, a `:label` option can be provided.

```ruby
config.add_index_field 'title_display', label: "Title"
```

Or, using i18n syntax, may look something like:

```ruby
config.add_index_field 'title_display', label: I18n.t('my.application.index.title_display')
```

The given label is also passed through an i18n filter for adding e.g. prefixes and suffixes. By default, Blacklight will append a ":" to the field value.

#### Model Accessors

If the value you wish to display is defined on the model, instead of in a single solr field, you can configure Blacklight to use an accessor on the SolrDocument instance:

```ruby
config.add_index_field 'title_display', :accessor: 'title'
```

This will call `document.title` to get the value of the field, e.g.:

```ruby
class SolrDocument
  def title
    first(:main_title) + " - " + first(:sub_title)
  end
end
```

will concatenate the main and sub titles.
#### Highlight

Solr supports query hit-highlighting. Blacklight can display the highlighted version of the field:

```ruby
config.add_index_field 'my_highlighted_field', highlight: true
```

#### Helper Method

When preparing a value for display, Blacklight can be configured to call a custom helper method. 

```ruby
config.add_index_field 'some_field_with_an_external_link', helper_method: 'make_this_a_link'
```

```ruby
module ApplicationHelper
  def make_this_a_link options={}
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field

    link_to options[:value], options[:value]
  end
end
```

#### Link To Search

Some display fields are also facet fields, and often it makes sense to link the displayed value to the corresponding facet selection.

```ruby
config.add_index_field 'genre', link_to_search: true
```

Or use the value in a link to a different field (e.g. if your display field is not indexed)

```ruby
config.add_index_field 'genre', link_to_search: 'genre_facet'
```

#### Schema.org configuration

```ruby
config.add_index_field 'genre', itemprop: "genre"
```

The genre values will be marked up as schema.org genre values.

### View Types

Blacklight provides a default "list" view of results.

### (Advanced) Results Grouping

# Show view

![Show view](https://f.cloud.github.com/assets/111218/2058440/e32f32a6-8b71-11e3-9bd5-20b0a3af2fea.png)


## Advanced Configuration

You can also use the field configuration to inject field-specific configuration

```ruby
config.add_index_field 'an_index_field', solr_params: { 'hl.alternativeField' => 'field_x'}
config.add_show_field 'a_show_field', solr_params: { 'hl.alternativeField' => 'field_y'}
# provided you also use: config.add_field_configuration_to_solr_request!
```

This will add field-specific parameters to the solr request.