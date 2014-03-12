require 'spec_helper' 
describe Blacklight::Routes do
  subject { Blacklight::Routes.new(router, options) }
  let(:router) { double }

  describe "solr_document" do
    describe "without constraints" do
      let(:options) { Hash.new }
      it "should define the resources" do
        router.should_receive(:resources).with(:solr_document, {:path=>:records, :controller=>:records, :only=>[:show]})
        router.should_receive(:resources).with(:records, :only=>[:show])
        subject.solr_document(:records)
      end
    end

    describe "with constraints" do
      let(:options) { { :constraints => {id: /[a-z]+/, format: false } } }
      it "should define the resources" do
        router.should_receive(:resources).with(:solr_document, {:path=>:records, :controller=>:records, :only=>[:show], :constraints=>{:id=>/[a-z]+/, :format=>false} })
        router.should_receive(:resources).with(:records, :only=>[:show], :constraints=>{:id=>/[a-z]+/, :format=>false})
        subject.solr_document(:records)
      end
    end
  end
end
