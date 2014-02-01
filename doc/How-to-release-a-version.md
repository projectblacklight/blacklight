Before releasing, ensure that you're on the master branch.  Run all  tests and ensure that they pass. Also check the [[continuous integration server|https://travis-ci.org/projectblacklight/blacklight]] to make sure tests are passing.
    ```bash
    $ bundle exec rake
    ```

1. Update the version number in ./VERSION
    ```
    {major}.{minor}.{patch}
    ```

1. Fix GitHub issue tracker to know about the release
      * Create a milestone in GitHub for the NEXT version.
      * Move any open tickets for released version to the next version.
      * Mark the milestone as closed.

1. Write Github [release notes](https://github.com/projectblacklight/blacklight/tags) for the tag.

1. Prepare announcement
  * Include URL to GitHub closed issues for version 
  * Include URL to github commits between tags. github can show all commits between two versions with a URL of this form: [[http://github.com/projectblacklight/blacklight/compare/v2.5.0...v2.6.0]]  Replace with previous version and current release version tags. 
  * Include URL to the Github wiki [[Release Notes And Upgrade Guides]].

1. Release the gem 
```bash
$ rake release
```

1. Announce
  * Write emails announcing the release to Blacklight Development 