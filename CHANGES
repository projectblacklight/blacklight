Blacklight v2.4.1, 12-11-2009

NOTABLE CHANGES:

	- template installer now puts "require" (instead of require_dependency) into your application_controller and application_helper files. This seems to fix a bug related to reloading code in development mode.
	
	- Blacklight::SolrHelper #get_search_results and #get_solr_response_for_doc_id methods now return an array where the first object is a solr response hash and the second is a SolrDocument instance or array of SolrDocuments, thanks to Jonathan Rochkind.
	
	- bug fixed where template installer would continue to add the same lines to appliation_controller and application_helper if the template was executed more than once.
	
	- Changed development solr port to 8983
	
	- New rake task for copying core assets into application: rake blacklight:copy_assets
	
	- New view helper methods implemented by Jonathan Rochkind: render_stylesheet_links, render_js_includes, and render_document_heading
	
	- Removed EAD implementation, considering new approach.
	
	- JRuby support and JRuby gem specs. Bill Dueber created a great write up on running Blacklight under JRuby: http://robotlibrarian.billdueber.com/running-blacklight-under-jruby/
	

CHANGE LOG:

088c26a updated template and readme for tag version
392e17f updated template for 2.4
21d40dc changed comment
64b2e85 updated tag version; removed branch variable
56aa4d6 updated template and readme for tag version
768e9d2 updated template for 2.4
440d291 Fixed issue CODEBASE-194
20ad46e updated development connection port to 8983
673a566 added jira url
991017b updated formatting
d7dd1ee updated git info
5545711 Merge branch 'solr_document_in_index_action' of git://github.com/jrochkind/blacklight into jrochkind/solr_document_in_index_action
35dc3e3 new get_search_results return values. This file doesn't currently actually contain any tests, but changed before(:each) so it should work when it does.
dacbe0f new return values of get_search_results. @document_list ivar is set for partial.  @doc is set to @document_list.first, so tests are run against SolrDocument not a Mash.
ca87858 SolrHelper spec changed to use new return values of @solr_helper.get_search_results.  New spec added to make sure @document_list contents match @response.docs contents. Specs that tested for size of @response.docs now also test to make sure @document_list is the same size.
16f1953 document list iterates through @document_list ivar instead of @response.docs, so it's iterating through actual SolrDocuments
d1e7eea index action adjusted for new return format of get_search_results, saving returned values in both @response and @document_list
295beb9  get_search_results returns a duple of solr_response and solr_document_list, on the analogy of get_solr_response_for_doc_id
0137346 removing schema.rb -- this is ignored
1d8bd27 Merge remote branch 'upstream/master' into more-display-helpers
4aa794c change name of title in dummy @document to make things absolutely clear
2f7a37b added specs for new helper methods render_stylesheet_links, render_js_includes, and render_document_heading
64f9ef7 took out debugging test
cc3d8b8 moved raise to method
8420dc6 added raise for running tests in jruby (need to start solr manually)
28b06ce added logic to handle jruby in spec
976e2f3 added jruby gem dependencies; indented line in spec rake file
d7adaea added task desc
2410573 added jruby gem deps (commented out); added new task: blacklight:copy_assets for copying plugin web assets to app
a031eff updated title
c4ebbee changed urls again
0aaad50 changed url to install readme
eed086b added installation readme, was main readme. Moved PROJECT readme to main README
6bc9dfd changed paths to new readme location
06edb15 moved readmes into doc dir
4140355 ignoring solr marc log files
77ad416 un-ignoring the jetty/solr/data contents
50a870d added require statements to fix the reload/nil bug
013b865 updated ignores
c35a1a1 Merge branch 'noead'
103dd37 fixed url file extension
e36c0f5 fixing readme urls
cc4ded7 fixed formatting of readme which was breaking github
a37c7e1 removed ead init stuff
97542e9 added proper autoloading for solr doc sub modules
22f3323 removing more refs to EAD
940b9be removed ead related partials
72f7708 removed refs to libxml/libxslt and nokogiri
022f689 removed libxml/xsl/nokogiri deps
ad52d43 ignoring a bunch-o-stuff
8c920be removed old dependency specs from test and cucumber envs
1e5e4c7 updated gem dep. for rsolr and rsolr-ext
fe82f9f Add helper methods for rendering certain html content, to make it easier for local over-ride without touching view.
36fcb85 Adjusting calls to get_response_for_doc_id, since it now returns the response and the document.
12f720e Changing get_solr_repsonse_for_doc_id so that it returns both the response and the document as a SolrDocument
94069ee PATCH: Link to account profile page in default _user_util_links.erb is broken.
c8cb0ed spelling fix
658d3a4 tag wording changes
d7799c1 organizational changes
fcb5657 wording changed
2c98dde grammar fix
9e1c26c basic overview of branching and tagging for Blacklight
c3e747c updated path for v2.4.0 template install
