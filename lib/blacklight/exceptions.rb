module Blacklight
  module Exceptions

    class AccessDenied < Exception
    end

    # When a request for a single solr document by id
    # is not successful, raise this:
    class InvalidSolrID < RuntimeError
    end

  end
end
