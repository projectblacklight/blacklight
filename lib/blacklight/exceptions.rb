# -*- encoding : utf-8 -*-
module Blacklight
  module Exceptions

    class AccessDenied < Exception
    end

    # When a request for a single solr document by id
    # is not successful, raise this:
    class InvalidSolrID < RuntimeError
    end
    
    class ExpiredSessionToken < Exception
    end

    class ECONNREFUSED < ::Errno::ECONNREFUSED; end

  end
end
