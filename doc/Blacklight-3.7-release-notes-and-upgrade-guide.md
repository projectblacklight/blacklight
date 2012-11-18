## Bookmarks and Folders merged

When upgrading to Blacklight 3.7, if you want to keep the 'folders' feature (of session-based, anonymous item selection), you should add this gem to your Gemfile:

```
gem 'devise-guests'
```

The bookmarks (database persisted, user-based) and folders (session stored, session-based) features have been merged into a single bookmarks feature (database persisted, user-based). These bookmarks are database-persisted and assume an ActiveRecord-based user model. 

The [devise-guests](http://rubygems.org/gems/devise-guests), generated into new applications by default, provides (session-based) guest user functionality to Devise (and, to Blacklight for applications that are using Devise). When a guest user logs in, the bookmarks associated with the guest user are transfered to the logged in user.

### Implementation details for those not using devise.

We've added a new method ```#current_or_guest_user```. By default, this is just the value of ```#current_user``` (provided by Devise, or whatever authentication layer you are using). Applications that want to provide session-based bookmarks should implement ```#current_or_guest_user``` and ``#guest_user``` in the application and return the current user (when logged in) or a session-based guest user record.

When a user logs in, your application should call ```#transfer_guest_user_actions_to_current_user``` to move the bookmarks and saved searches to the logged in user.

## Query Facets

Blacklight 3.7 adds support for Solr query facets. There's an example of this in the [Blacklight demo](http://demo.projectblacklight.org) with the Publish Date facet.

The Publish Date facet is using this configuration:

```ruby
    config.add_facet_field 'example_query_facet_field', :label => 'Publish Date', :query => {
       :years_5 => { :label => 'within 5 Years', :fq => "pub_date:[#{Time.now.year - 5 } TO *]" },
       :years_10 => { :label => 'within 10 Years', :fq => "pub_date:[#{Time.now.year - 10 } TO *]" },
       :years_25 => { :label => 'within 25 Years', :fq => "pub_date:[#{Time.now.year - 25 } TO *]" }
    }
```

The first argument (which maps to the facet field for plain facets) is used in the Blacklight URL when the facet is selected.

The ```:query``` hash maps the URL key into a facet label (to show to the user) and a fq to send to `facet.query` and, after selection, the Solr `fq` parameter.


### A small change to the Blacklight configuration to get Blacklight to generate facet.query for you. 

In older versions of Blacklight, the facet field keys mapped directly to the Solr ```facet.field``` parameter. By default, Blacklight generated the following into your CatalogController configuration:

```
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
```

In the new model, this logic is deferred as part of the Blacklight solr search params logic. The above line should be replaced with:

```
    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!
```

This will add the plain facets to the ```facet.field``` and the query facets to the ```facet.query```.

### Adding facet queries to the solr request handler yourself

If you want to add the facet queries directly to your solr request handler, you should ensure the configuration for the Blacklight facet queries ```fq``` field matches a Solr ```facet.query``` field. 

So, given this Solr response:

```xml
<lst name="facet_counts">
  <lst name="facet_queries">
    <int name="lc_alpha_facet:A">0</int>
  </lst>
  ...
</lst>
```

The Blacklight-side config would look something like:

```ruby
    config.add_facet_field 'contrived_blacklight_configuration_example',  :query => {
       :a => { :label => 'starting with A', :fq => "lc_alpha_facet:A" },
    }
```