require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "unAPI formats list" do  
  

  before(:all) do
    class UnapiMockDocument
      include Blacklight::Solr::Document
    end
        module FakeExtension
          def self.extended(document)
            document.will_export_as(:mock, "application/mock")
          end

          def export_as_mock
            "mock_export"
          end
        end

    UnapiMockDocument.use_extension( FakeExtension )
  end

  it "should provide a list of object formats which should be supported for all documents" do
    @export_formats = { :mock => { :content_type => "application/mock" } }
    render :template => "catalog/unapi.xml.builder", :content_type => "application/mock"
    h = Hash.from_xml(rendered)

    h['formats'].should_not be_nil
    h['formats']['format'].should_not be_nil
    h['formats']['format']['name'].should == 'mock'
    h['formats']['format']['type'].should == 'application/mock'
  end

  it "should provide a list of object formats available from the unAPI service for the document" do
    @document = UnapiMockDocument.new({})
    @export_formats = @document.export_formats
    render :template => "catalog/unapi.xml.builder", :content_type => "application/mock"
    h = Hash.from_xml(rendered)

    h['formats'].should_not be_nil
    h['formats']['format'].should_not be_nil
    h['formats']['format']['name'].should == 'mock'
    h['formats']['format']['type'].should == 'application/mock'
  end
end
