module MARC

  # MARC records contain control fields, each of which has a 
  # tag and value. Tags for control fields must be in the
  # 001-009 range.

  class ControlField

    # the tag value (007, 008, etc)
    attr_accessor :tag

    # the value of the control field
    attr_accessor :value

    # The constructor which must be passed a tag value and 
    # an optional value for the field.

    def initialize(tag,value='')
      @tag = tag
      @value = value
      if tag.to_i > 9 
        raise MARC::Exception.new(), "tag must be greater than 009"
      end
    end

    # Two control fields are equal if their tags and values are equal.

    def ==(other)
      if @tag != other.tag
        return false 
      elsif @value != other.value
        return false
      end
      return true
    end

    def to_s
      return "#{tag} #{value}" 
    end

    def =~(regex)
      return self.to_s =~ regex
    end

  end

end
