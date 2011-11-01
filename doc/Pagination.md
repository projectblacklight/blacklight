Blacklight uses [kaminari](https://github.com/amatsuda/kaminari) for providing pagination of Solr responses. 

One motivation for this is so a pagination view theme can be provided that you can use for your custom code with ordinary ActiveRecord or anything else kaminari can handle, to have consistency between the rest of your app's pagination and Blacklight's Solr response pagination. 

## How it works

The Blacklight #paginate_params helper method takes an RSolr::Response, and converts it to something Kaminari #paginate can handle. (Basically just by translating some attribute names). So you could call:

    paginate( paginate_params(@response) )  # where @response is an RSolr::Response

But there's a shortcut Blacklight helper method which compacts this, #paginate_rsolr_response:

    paginate_solr_response @response, :theme => 'blacklight'

The `theme => 'blacklight'` part will be passed through kaminari, and tell kaminari to use the theme that the Blacklight plugin supplies at [app/views/kaminari/blacklight](https://github.com/projectblacklight/blacklight/tree/master/app/views/kaminari/blacklight)

Any other arguments of ordinary kaminari paginate can also be passed in there. If all client code uses #paginate_solr_response, it also provides a 'hook' for local apps to completely over-ride pagination rendering, perhaps not even using kaminari. 

Additionally, we sometimes want to output a "Showing X through Y of N" message, which kaminari doesnt' have a way to do by default, so we just provide our own way in a Blacklight view helper method, which takes a RSolr::Response too:

    render_pagination_info(@response)

## Changing the kaminari theme

If you want to change how pagination links are rendered, the easiest/cleanest thing to do is to over-ride the 'blacklight' theme that the Blacklight plugin defines. Copy the view templates in Blacklight source at app/views/kaminari/blacklight to your own local app/views/kaminari/blacklight.  You actually only need to copy files you'll want to modify, templates not overridden with a local copy will still be found by kaminari from the Blacklight gem.  You can use any techniques available for creating a kaminari theme when editing these files, including over-riding more kaminari view templates if available. See the kaminari documentation. 

There are other ways you could change how Blacklight pagination renders, but by doing it this way, any code (in core Blacklight or additional plugins you install) that tries to render pagination using kaminari with 'blacklight' theme will get your locally defined theme. 

The "pagination info" (showing X through Y of N) is not part of the kaminari theme, but just a blacklight view helper method, #render_pagination_info.  To change this, just over-ride this method [[over-ride locally|CUSTOMIZING]] like any other Blacklight view helper method. 

## Using kaminari theme for your own pagination

Your local app may show pagination of ActiveRecord objects, that you'd like to appear consistent with other Blacklight pagination. Just use kaminari to show the pagination HTML, with the theme :blacklight.  This technique can be used for anything kaminari can paginate, such as Mongoid et al, in addition to ActiveRecord. Fetch the ActiveRecords using ordinary kaminari techniques (see kaminari docs) and then:

    paginate @my_active_records, :theme => 'blacklight'

That's it. There's currently no great way to display the #render_pagination_info for anything but RSolr::Response. 

