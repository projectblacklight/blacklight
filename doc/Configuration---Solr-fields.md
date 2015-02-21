# Discovery configuration

In this section, we will discuss some of the features available to control the discovery experience, including pagination, sorting, and fielded searches.

## Per Page

<img align="right" src="https://f.cloud.github.com/assets/111218/2491030/2ce8acc0-b1d7-11e3-8466-659a1759dde7.png" />

Three configuration options control the behavior of the per-page and pagination controls.

```ruby
config.per_page # [10,20,50,100]
config.default_per_page # the first per_page value, or the value given here
config.max_per_page # 100
```

The options presented in the per-page dropdown are the values for the `per_page` configuration, in the order given. The `default_per_page` can  be used if you want to offer a default per-page value that isn't the smallest value. Finally, `max_per_page` is used as a sanity check for user-supplied values. 

We can explicitly set the configuration in our `CatalogController` configuration:

<img align="right" src="https://f.cloud.github.com/assets/111218/2491066/6cc93f38-b1d9-11e3-9047-f6beccbb93ff.png" />

```ruby
class CatalogController
...
  configure_blacklight do |config|
    ...
    config.per_page = [6,12,24,48]
    config.default_per_page = 24
  end
end
```

## Sort Fields

You can configure the available sort options. The sort parameter is passed through to Solr, so the value must be a supported [sort format](http://wiki.apache.org/solr/CommonQueryParameters#sort).

```ruby
config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
config.add_sort_field 'pub_date_sort desc, title_sort asc', :label => 'year'
config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author'
config.add_sort_field 'title_sort asc, pub_date_sort desc', :label => 'title'
```

#### An aside about Blacklight solr field configurations

The Blacklight solr field configuration is very expressive, and supports several different flavors of configuration. These are all functionally equivalent:

```ruby
config.add_sort_field 'pub_date_sort desc, title_sort asc', :label => 'year'

# for sort fields, the `sort` key contains the Solr sort information. For other fields, the `field` key is used.
config.add_sort_field :sort => 'pub_date_sort desc, title_sort asc', :label => 'year'

# the "key" (first argument) will be used in user-facing url parameters.
config.add_sort_field 'year', :sort => 'pub_date_sort desc, title_sort asc', :label => 'year' 

# The block format may be useful when using complex logic in the configuration settings
config.add_sort_field 'year' do |field|
  field.sort = 'pub_date_sort desc, title_sort asc'
  field.label = field.key.humanize
end

# The array-format allows you to add multiple values at once.
config.add_sort_field [
  {sort: 'pub_date_sort desc, title_sort asc', label: 'year}, { sort: '....', ...}
]
```

You may choose the format that is appropriately concise and legible in the context of your application and configuration.

The `add_*_field` is appending values to a configuration hash. In some cases, it may be useful to modify that hash directly.

```ruby
config.sort_fields['year'].label = "Year Created"
```

## Targeting Search Queries at Configurable Fields

Search queries can be targeted at configurable fields (or sets of fields) to return precise search results.

<img src="https://github.com/projectblacklight/projectblacklight.github.com/raw/master/images/search_fields.png" />

```ruby
    config.add_search_field 'all_fields', :label => 'All Fields'
```

```ruby
    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields. 
    
    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params. 
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = { 
        :qf => '$title_qf',
        :pf => '$title_pf'
      }
    end
```