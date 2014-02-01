# Blacklight 3.6 Release Notes And Upgrade Guide

## Release Notes
# Blacklight 3.6 Release notes
Blacklight 3.6.0 is now available. This is mostly a collection of small patches.


- Fix blacklight to be compatible with newly released version of Kaminari
- Split document_header into its own partial
- Utilizing rails own capability to determine partial paths for collections
- #423 using response.total instead of the underlying hash
- many more


The full list of Github issues are at:
https://github.com/projectblacklight/blacklight/issues?milestone=8&state=closed

Also, the GitHub compare view of this release vs. our last release is
located at:
https://github.com/projectblacklight/blacklight/compare/release-3.5...release-3.6


## Upgrade Guide

No known issues updating from 3.5 to 3.6. If you are overriding `app/views/catalog/_document_list.html.erb` in your local application, you may want to look at how it is now written in the gem.  See https://github.com/projectblacklight/blacklight/commit/b712d79fa88e80155972ce3e9bc7629d7e63c1eb
