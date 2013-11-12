# This class has dubious semantics and we only have it so that people can write
# params[:key] instead of params['key'].
class Mash < HashWithIndifferentAccess
  def initialize *args, &block
    ActiveSupport::Deprecation.warn("Mash is deprecated, and should be replaced with HashWithIndifferentAccess")

    super
  end
end

unless Hash.respond_to?(:to_mash)
  class Hash
    def to_mash
      ActiveSupport::Deprecation.warn("Hash#to_mash is deprecated, and should be replaced with #with_indifferent_access")

      HashWithIndifferentAccess.new(self)
    end
  end
end
