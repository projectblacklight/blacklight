# frozen_string_literal: true

# Represents a single document returned from the search index
class <%= model_name.classify %>
  # Mixes in the behavior appropriate for the search index adapter configured
  # in config/blacklight.yml (Solr by default, or Elasticsearch).
  include Blacklight.document_mixin

  # self.unique_key = 'id'

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)
end
