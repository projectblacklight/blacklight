# frozen_string_literal: true
# = Document Extensions
# An Blacklight::Document extension is simply a ruby module which is mixed
# in to individual Document instances.  The intended use case is for documents
# containing some particular format of source material, such as Marc. An
# extension can be registered with your document class, along with a block
# containing custom logic for which documents to apply the extension to.
#
# SolrDocument.use_extension(MyExtension) { |document| my_logic_on_document(document) }
#
# MyExtension will be mixed-in (using ruby 'extend') only to those documents
# where the block results in true.
#
# == Extension Parameters
# Every class that includes Blacklight::Solr::Document::Extensions gets a
# #extension_parameters method for saving arbitrary parameters on class-wide
# level that can be retrieved by extensions. These are arbitrary, just
# conventions with a given extension. For instance:
# SolrDocument.extension_parameters[:marc_source_field] = "solr_stored_field_name"
#
module Blacklight::Document::Extensions
  extend ActiveSupport::Concern

  # Needs to be called in initializer of class including this module, to
  # apply all registered extensions on a per-document basis
  def apply_extensions
    self.class.registered_extensions.each do |registration|
      extend(registration[:module_obj]) if registration[:condition_proc].nil? || registration[:condition_proc].call(self)
    end
  end

  module ClassMethods
    attr_writer :registered_extensions

    # want to zero out all previously registered extensions you can call:
    # SolrDocument.registered_extensions = nil
    def registered_extensions
      @registered_extensions ||= []
    end

    def extension_parameters
      @extension_parameters ||= {}
    end

    # Register an extension module with the class. A block taking one
    # parameter can be supplied; the block will be passed an instance of
    # a Document, and the extension will be applied only if the block
    # evaluates as true. If no condition is given, the extension will
    # be applied to every instance of the class.
    #
    # SolrDocument.use_extension( SomeExtensionModule ) { | document | should_apply_some_extension?(document) }
    # SolrDocument.use_extension( SomeExtensionModule) # will be applied to all docs
    def use_extension(module_obj, &condition)
      registered_extensions << { module_obj: module_obj, condition_proc: condition }
    end
  end
end
