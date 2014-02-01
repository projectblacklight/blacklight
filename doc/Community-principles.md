# Community Principles

## Overview
* Blacklight is an open source application for libraries (and anyone else), built on top of SOLR, and meant to deliver excellent access to all classes of information resources.
* Blacklight can ultimately be successful and sustainable in the long run only if it is an open project; that is, it takes contributions from a community of developers across many institutions to enhance and support it
* We will work to balance progress on Blacklight’s codebase with open community discussion and transparent decision making as coequal goals
* Blacklight code is available through the Apache 2.0 open source license.

## Technical Leadership
Technical leadership of the project will be through a small group of proven developers who have demonstrated commitment to Blacklight’s progress and success (and have commit rights to the source code)

Committers must be:

* technically adept
* constructive, positive members of the Blacklight software community
* committed to producing useful, practical code for the community

To become a committer, candidates must be…

* nominated by a current committer
* voted on and approved by a majority of the current committers
* committers may be voted out at any time by a (super?) majority of the other committers

Committers will have a regular meeting, usually in the form of a conference call, to coordinate development & direction.

Releases will be vetted and controlled by a designated lead or leads. These roles may shift from release to release.

## Code Contributions & Principles
* the users of, interest in, resources, and talent pool of the Blacklight community will spread far beyond the developers on the committers list, and their institutions
* Blacklight encourages and will facilitate taking code from contributors from many sources
the structure of the source code management (soon GIT) will facilitate incorporating and using code from many sources
* Blacklight committers will actively take code contributions from non-committers and incorporate it into the code trunk
* Working code wins
* You get what you give
* All contributed code must have full test coverage before it is committed. The current testing infrastructure is RSpec for everything but Rails views, and Cucumber for for Rails views.
* Tests must be committed at the same time code is.
* All javascript features (where feasible) should be added using “progressive enhancement” or “unobtrusive javascript” styles. Meaning the basic feature should work without Javascript, and the JS should be added as a progressive enhancement, and added via externally linked js files, not in-line in html source as script tags, onclick attributes, etc.
* All bugs and development tasks will be tracked in GitHub Issues
* All code must be documented before it’s committed

## Roadmap & Transparency
We will publish a roadmap to guide overall development. The items on this roadmap will be determined after an inclusive process of canvassing the wider Blacklight community, including code committers, contributors, users and a potential advisory board.

We envision regular/quarterly/semiannual/annual Blacklight convention of community members to help guide and galvanize new developments. These are likely to be appended to other community events, e.g., code4lib, for the sake of logistics.