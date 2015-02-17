# -*- encoding : utf-8 -*-
module Blacklight
  module Exceptions

    class AccessDenied < Exception
    end

    # When a request for a single solr document by id
    # is not successful, we can raise this exception. 
    # Deprecated; this will be removed in Blacklight 6.0:
    class InvalidSolrID < RuntimeError
    end
    # In Blacklight 6.0, this exception can subclass RuntimeError directly
    class RecordNotFound < InvalidSolrID
    end

    class InvalidRequest < StandardError
    end

    class ExpiredSessionToken < Exception
    end

    class ECONNREFUSED < ::Errno::ECONNREFUSED; end

  end
end
