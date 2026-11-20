# frozen_string_literal: true

require 'rake'

RSpec.describe "blacklight:delete_old_searches" do
  let(:rake) { Rake::Application.new }
  let(:task_name) { "blacklight:delete_old_searches" }

  before do
    Rake.application = rake
    Rake.application.rake_require "../lib/railties/blacklight"
    Rake::Task.define_task(:environment)
  end

  it "calls Search.delete_old_searches" do
    days_old = 7
    allow(Search).to receive(:delete_old_searches)
    rake[task_name].invoke(days_old)
    expect(Search).to have_received(:delete_old_searches).with(days_old)
  end
end
