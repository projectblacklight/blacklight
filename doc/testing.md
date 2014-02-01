## Using Blacklight source checkout as gem for development

The ordinary install instructions install the BL gem (which is not
full source code) in wherever your system installs gems. 

Sometimes, especially for development, it's useful to check out
a complete copy of the blacklight source code, and link your app
to that as a 'gem' instead. 

Checkout the code:

    $ git clone git@github.com:projectblacklight/blacklight.git  


## Automatically generate a test application (and run the tests)

To run the Blacklight test suite, Blacklight comes with a rake task that creates local dependencies like a Solr with indexed test data and a test Rails application, and then runs tests. 

Requirements:

  * Java (1.6 or above) (for Solr)
  * phantomjs (used by integration tests, you may be able to install with your local package manager, for instance on OSX with `brew install phantomjs`)

Then from the root directory of your blacklight git checkout:

```
rake ci  
```
This ensure a test Solr exists and is running, creates a test application, and loads the fixtures and then runs specs and cucumber tests.

### Step by step, with more control

`rake ci` will, every time you run it, re-index test data in solr, and re-build the test application. Re-building the test application in particular is kind of time-consuming. You may prefer to set up the environment and run tests as separate steps, to make development easier. 

To create the dummy test app:

    $ rake engine_cart:generate

(If you have an existing dummy app that is outdated, `rake engine_cart:clean` first, then `rake engine_cart:generate). 

Then start up the test jetty with:

    $ rake jetty:start

If you haven't yet indexed the test data in the test jetty. (??? Not sure how to do this. Run `rake ci` once to make sure test data has been indexed).  Run `rake jetty:stop` when you're done with it. 

Then run all the specs with:

    $ rake spec

Or just run one spec

    $ rake spec SPEC=just/one_spec.rb

And stop your test solr when you're done with it:

    $ rake jetty:stop