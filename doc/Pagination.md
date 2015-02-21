Blacklight uses [kaminari](https://github.com/amatsuda/kaminari) for providing pagination of Solr responses. 

One motivation for this is so a pagination view theme can be provided that you can use for your custom code with ordinary ActiveRecord or anything else kaminari can handle, to have consistency between the rest of your app's pagination and Blacklight's Solr response pagination. 

## How it works

The Blacklight response objects are Kaminari-ready #paginate, so you could call:

    paginate(@response )  # where @response is an RSolr::Response

Or, 
    paginate @response, :theme => 'blacklight'

![Blacklight theme](https://f.cloud.github.com/assets/111218/2059081/97fe4082-8b95-11e3-9fd2-ae824bcf7b7e.png)

The `theme => 'blacklight'` part will be passed through kaminari, and tell kaminari to use the theme that the Blacklight plugin supplies at [app/views/kaminari/blacklight](https://github.com/projectblacklight/blacklight/tree/master/app/views/kaminari/blacklight)

Any other arguments of ordinary kaminari paginate can also be passed in there.

Additionally, we sometimes want to output a "X through Y of N" message with some basic pagination controls, which kaminari doesn't have a (good) way to do by default. Blacklight provides a simple partial to provide this behavior:

```ruby
  render partial: 'catalog/paginate_compact', object: @response
```

Or, using all kaminari-native methods:

```erb
<%= paginate paginate_compact, :page_entries_info => page_entries_info(paginate_compact), :theme => :blacklight_compact %>
```

![Compact](https://f.cloud.github.com/assets/111218/2059080/97fc3ee0-8b95-11e3-8c66-ab31dcd7eedb.png)

## Changing the kaminari theme

If you want to change how pagination links are rendered, the easiest/cleanest thing to do is to over-ride the 'blacklight' theme that the Blacklight plugin defines. Copy the view templates in Blacklight source at app/views/kaminari/blacklight to your own local app/views/kaminari/blacklight.  You actually only need to copy files you'll want to modify, templates not overridden with a local copy will still be found by kaminari from the Blacklight gem.  You can use any techniques available for creating a kaminari theme when editing these files, including over-riding more kaminari view templates if available. See the kaminari documentation. 

There are other ways you could change how Blacklight pagination renders, but by doing it this way, any code (in core Blacklight or additional plugins you install) that tries to render pagination using kaminari with 'blacklight' theme will get your locally defined theme. 

## Changing the default kaminari pagination options

Sometimes you you just want to tweak a few things with pagination and it doesn't require crawling into the RSolr response or creating a kaminari theme. Here's how you do that.

First, generate the kaminari config initializer:

    rails g kaminari:config

You will get a file in config/initializers/kaminari_config.rb that is mostly commented out.  The config options are mostly self-explanatory, but let's say that you don't like that Blacklight gives you 4 pages of links on either side of the current page.  Uncomment: 

    # config.window = 4

and change 4 to whatever number is preferable. More information on the kaminari general configuration options is available here: https://github.com/amatsuda/kaminari#general-configuration-options