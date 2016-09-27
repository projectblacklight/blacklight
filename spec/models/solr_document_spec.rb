# frozen_string_literal: true

describe SolrDocument do

  before(:each) do
    @solrdoc = SolrDocument.new :id => '00282214', :format => ['Book'], :title_display => 'some-title'
  end

  describe "new" do
    it "takes a Hash as the argument" do
      expect { SolrDocument.new(:id => 1) }.not_to raise_error
    end
  end

  # Addresses https://github.com/projectblacklight/blacklight/issues/1528
  describe "splat operator interaction" do
    it "can be passed via the splat operator with keyword args" do
      splatter = Class.new do
        def splat(*args, **kwargs)
          args.first
        end
      end.new
      expect(splatter.splat(@solrdoc)).to eq(@solrdoc)
    end

    it "can be passed via the splat operator with a keyword" do
      splatter = Class.new do
        def splat(*args, to: nil)
          args.first
        end
      end.new
      expect(splatter.splat(@solrdoc)).to eq(@solrdoc)
    end

    it "can be passed via the splat operator without keyword args" do
      splatter = Class.new do
        def splat(*args)
          args.first
        end
      end.new
      expect(splatter.splat(@solrdoc)).to eq(@solrdoc)
    end
  end

  describe "access methods" do
    it "has the right value for title_display" do
      expect(@solrdoc[:title_display]).not_to be_nil
    end

    it "has the right value for format" do
      expect(@solrdoc[:format][0]).to eq 'Book'
    end

    it "provides the item's solr id" do
      expect(@solrdoc.id).to eq '00282214'
    end
  end
end
