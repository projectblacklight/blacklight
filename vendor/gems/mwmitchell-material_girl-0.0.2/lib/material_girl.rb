module MaterialGirl
  
  def self.parse(set, opts={})
    unless block_given?
      opts[:delimiter]  ||= '::'
      opts[:field]      ||= :path
    end
    root = Composite.new('root')
    set.each do |item|
      val = block_given? ? yield(item) : item[opts[:field]].to_s.split(opts[:delimiter])
      acc = nil # define in outer scope to set the :item
      val.compact.inject(root) do |acc,k|
        acc.children << Composite.new(k, acc) unless acc.children.any?{|i|i.value==k}
        acc.children.detect{|i|i.value==k}
      end
      # the last path item is always the object
      acc.children.last.object = item
    end
    root
  end

  class Composite

    attr_reader :value, :parent
    attr_accessor :object

    def initialize(value='', parent=nil)
      @value, @parent = value, parent
    end

    def children
      @children ||= []
    end

    def descendants
      self.children + self.children.map{|c| c.descendants }.flatten
    end

    def ancestors
      self.parent ? ([self.parent] + self.parent.ancestors) : []
    end

    def siblings
      self.parent ? (self.parent.children - [self]) : []
    end
    
    def self_and_siblings
      self.parent ? (self.parent.children) : []
    end
    
  end
  
end