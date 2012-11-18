Blacklight uses Solr as its data index. Blacklight is agnostic as to how that Solr index gets populated. Many Blacklight contributors work in university libraries and have to deal with library data in the MARC format. The Blacklight out-of-the-box demo and test suite is geared towards that use case.

## What’s the relationship between Blacklight and SolrMarc?

However, one excellent way to index lots of MARC records into Solr quickly is to use SolrMarc. Some of the same people are active in both projects, e.g, Bob Haschart from UVA and Naomi Dushay from Stanford University. SolrMarc is not a Blacklight-specific project, it is also used by VuFind and other projects, and is a separate project that exists in its own right.