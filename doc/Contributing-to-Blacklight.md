# Contributing to Blacklight
Blacklight is a collaborative open source project by developers at various institutions, which we each work on largely motivated by our own local institutions' needs. We work on the shared project together so we can benefit from each other's code, but most developers primary priorities are to their own local development. In this it is like many such projects.

The Blacklight developers do want to create a product that is easy for newcomers to install and get started with -- both as a service to the community and in the interests of our own institutions in creating a sustainable project and product that continue to thrive through personnel changes. However, the developers may not always have time to find or fix bugs that may be affecting you, or lead you through every detail of getting Blacklight to work for you.

But we do try when we can -- please don't be scared to ask a question on the [[Blacklight mailing list|http://groups.google.com/group/blacklight-development]], just don't be shocked if we can't always give you the answer you want. We always welcome patch submissions; and we are always excited to hear about what others are doing with Blacklight. We're also always looking for more committers, although we usually like to see a patch or two before considering granting committer status.

If you follow this short guide, it will make it much easier for the community to review your changes, and the core team to get them included in the next release. If you are new to Git, be sure to read Github's (really good) [[step-by-step directions|http://help.github.com/fork-a-repo/]] for contributing to projects. If you want a basic introduction to git, check out [[Git Reference|http://gitref.org/]].

We also encourage a lot of peripheral functionality -- especially for features that may not be used by most implementations, as the Blacklight install base has a wide range of users -- to consider developing stand-alone, optional [[Blacklight add-ons]].

## Adding a ticket
Let us know you're interested in working on a feature by filing a ticket in our [[issue tracker|https://github.com/projectblacklight/blacklight/issues]].  

## Making Your Changes

* Fork the project (Github has really good step-by-step directions
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so we don't break it in a future version unintentionally.
* After making your changes, be sure to run the [[Blacklight rspec and cucumber tests|Testing]] to make sure everything works. 
* Submit your change as a [[Pull Request|http://help.github.com/pull-requests/]].

## Support
If you are interested in working on the Blacklight plugin, but want guidance or support, please send an email to our [[Blacklight-development mailing list|http://groups.google.com/group/blacklight-development]] and we'll be glad to help.