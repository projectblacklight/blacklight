#
# A generic mapping class for "collections"
# bm = BlockMapper.new
# bm.before_each {|rec,index| # do something here like: rec.extend(MyMethods) }
# bm.map :indexer, 'Matt'
# bm.map :id do |rec,index|
#   rec[:id]
# end
# 
# mapped_data = bm.run(my_collection_of_somethings)
#
class BlockMapper
  
  attr :mappings
  attr :before_each_source_item_blk
  attr :after_each_mapped_value_blk
  
  def initialize
    @mappings = []
  end
  
  def map(output_field_name, value=nil, &blk)
    raise 'Can provide a value (second arg) or a block, not both' if value and block_given?
    @mappings << {:field_name=>output_field_name, :value=>value, :blk=>blk}
  end
  
  def before_each_source_item(&blk)
    @before_each_source_item_blk = blk
  end
  
  def after_each_mapped_value(&blk)
    @after_each_mapped_value_blk=blk
  end
  
  def run(collection, &blk)
    docs=[]
    collection.each_with_index do |rec,index|
      @before_each_source_item_blk.call(rec,index) if @before_each_source_item_blk
      doc={}
      @mappings.each do |m|
        field = m[:field_name]
        value = m[:blk] ? m[:blk].call(rec, index) : m[:value].to_s
        value = @after_each_mapped_value_blk.call(field, value) if @after_each_mapped_value_blk
        doc[field] = value
      end
      yield(doc, index) if block_given?
      docs << doc
    end
    docs
  end
  
end