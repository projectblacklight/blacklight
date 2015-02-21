Faceted search allows users to constrain searches by controlled vocabulary items.

Note that these must be INDEXED fields in the Solr index, and are generally a single token (e.g. a string).

By default, Blacklight will handle creating the Solr requests to handle the different configuration options below. For performance or other reasons, this behavior can be disabled by removing or commenting out: 

```ruby
config.add_facet_fields_to_solr_request!
```

Note: When disabled, you are responsible for ensuring Solr returns the necessary values to drive the Blacklight interface.

## Basic Configuration

```ruby
config.add_facet_field 'format_facet'
```

* label

```ruby
config.add_facet_field 'format_facet', label: "Format"
```

* sort

Note: setting 'index' causes Blacklight to sort by count and then by index. If your data is strings, you can use this to perform an alphabetical sort of the facets.

```ruby
   config.add_facet_field :my_count_sorted_field, sort: 'count'
   config.add_facet_field :my_index_sorted_field, sort: 'index'
```

* collapse

```ruby
config.add_facet_field 'format_facet', collapse: true  # the default
```

```ruby
config.add_facet_field 'format_facet', collapse: false 
```

* show

```ruby
config.add_facet_field 'format_facet', show: false # don't display the facet, but configure it in case it displays in the constraints (or e.g. a saved search)
```

* helper_method

```ruby
config.add_facet_field 'format_facet', helper_method: :render_format_with_icon
```

```ruby
module ApplicationHelper
  def render_format_with_icon value
    content_tag :span do
      content_tag :span, '', class: "glyphicon glyphicon-#{value.parameterize}" +
      content_tag :span, value
    end 
  end
end
```

* partial

```ruby
config.add_facet_field 'format_facet', partial: 'custom_format_facet'
```
## Single-value facets

* single

Only one value can be selected at a time. When the value is selected, the value of this field is ignored when calculating facet counts for this field.

```ruby
config.add_facet_field 'format_facet', single: true
```

## Tag/Ex Facets

Single-select facets (above) are one example of Solr's tag/ex functionality. More advanced uses of tag/ex can be done using the `tag` and `ex` configuration.

```ruby
config.add_facet_field 'some_field', tag: 'xyz',ex: 'xyz'
config.add_facet_field 'mutually_exclusive_with_above', tag: 'xyz', ex: 'xyz'
```

## Query Facets

```ruby
config.add_facet_field 'a_query_field', query: {
  a_to_n: { label: 'A-N', fq: 'some_field:[A* TO N*]' }
  m_to_z: { label: 'M-Z', fq: 'some_field:[A* TO N*]' }
}
```

## Pivot Facets

```ruby
config.add_facet_field 'a_pivot_facet', pivot: ['first_field', 'last_field']
```

## Date Facets


If you have date facets in Solr, you should add a hint to the Blacklight configuration to trigger date-based solr querying, and ensure the values are displayed using a localized date format provided by the Rails date helpers:
```ruby
config.add_facet_field 'date_format', date: true
```

If you want to use a particular localization format, you can provide that as well:

```ruby
   config.add_facet_field :my_date_field, :date => { :format => :short }
```

## Range Facets

blacklight_range_limit

## Advanced Configuration

You can also use this facet configuration to inject field-specific configuration

```ruby
    config.add_facet_field :my_field, solr_params: { 'facet.mincount' => 15 }
```