Blacklight uses Solr as its data index. Blacklight is agnostic as to how that Solr index gets populated. Many Blacklight contributors work in university libraries and have to deal with library data in the MARC format. The Blacklight out-of-the-box demo and test suite is geared towards that use case.

## Common Patterns

If you're not dealing with MARC records, you might do something like the following:

    class MyModel < ActiveRecord::Base
      after_save :index_record
      before_destroy :remove_from_index

      attr_accessible :field_i_want_to_index

      def to_solr
        # *_texts here is a dynamic field type specified in solrconfig.xml
        {'id' => id,
         'field_i_want_to_index_texts' => field_i_want_to_index}
      end

      def index_record
        SolrService.add(self.to_solr)
        SolrService.commit
      end

      def remove_from_index
        SolrService.delete_by_id(self.id)
        SolrService.commit
      end
    end

## What’s the relationship between Blacklight and SolrMarc?

However, one excellent way to index lots of MARC records into Solr quickly is to use SolrMarc. Some of the same people are active in both projects, e.g, Bob Haschart from UVA and Naomi Dushay from Stanford University. SolrMarc is not a Blacklight-specific project, it is also used by VuFind and other projects, and is a separate project that exists in its own right.