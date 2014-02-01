## Release Notes
### 4.2.0
Bug fixes include:

- jQuery 1.9 compatibility (#545 and others)
- #548 remove duplicate favicon link tag
- #546 more straightforward testing (deprecating the test_support/bin/* scripts in favor of just 'rake')
- #549 add :helper_method to add_facet_field (similar to add_index/show_field) documented in [1]

### 4.2.1
Bug fixes include:

- Rails 4 support
- #554 enable users to update bootstrap-sass to the latest version
- #557 add the post route for sending email
- #559 Remove unnecessary require of 'mash' which was causing "uninitialized constant HashWithIndifferentAccess"
- Fixed issue with refworks exports [156e76](https://github.com/projectblacklight/blacklight/commit/156e7680630fcbae2defa4d07f1e1c0aabc67944)

### 4.2.2

Minor fixes for Rails 4.0 final release.

## Upgrade Guide

No known issues.