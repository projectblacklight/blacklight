require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require "rake"

describe "blacklight:delete_old_searches" do

  before do
    @rake = Rake::Application.new      
    Rake.application = @rake
    Rake.application.rake_require "../lib/railties/blacklight"
    Rake::Task.define_task(:environment)
    @task_name = "blacklight:delete_old_searches"
  end
  
  it "should call Search.delete_old_searches" do
    days_old = 7
    Search.should_receive(:delete_old_searches).with(days_old)  
    @rake[@task_name].invoke(days_old)
  end
    
end
