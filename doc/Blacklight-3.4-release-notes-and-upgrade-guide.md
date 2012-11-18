# Blacklight 3.4 Release notes
Blacklight 3.4.0 is now available. It fixes a number of bugs and
tests, but also adds a handful of new features.

 - Fixed Rails 3.1 compatibility for rspec tests
 - changes to make Blacklight work better with arbitrary solr indexes.
 - Use ERb to parse the solr.yml configuration (allowing environment
variables to be referenced in the config)
 - fixed #351, saving Selected Items (Folder) to Bookmarks
(SavedRecords), more than 10.
 - fixed #398 document fetching/config refactor, which elevates
document-request solr parameters into the controller's
blacklight_config.
 - fixed #333, Blacklight should throw more helpful errors if it
unable to connect to Solr
 - fixed #96, supporting configurable request handler paths

The full list of Github issues are at:
https://github.com/projectblacklight/blacklight/issues?milestone=4&state=closed

Also, the GitHub compare view of this release vs. our last release is
located at:
https://github.com/projectblacklight/blacklight/compare/v3.3.0...v3.4.0

# Upgrade notes

No known issues updating from 3.3 to 3.4.