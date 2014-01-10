
namespace :blacklight do
  # task to clean out old, unsaved searches
  # rake blacklight:delete_old_searches[days_old]
  # example cron entry to delete searches older than 7 days at 2:00 AM every day: 
  # 0 2 * * * cd /path/to/your/app && /path/to/rake blacklight:delete_old_searches[7] RAILS_ENV=your_env
  desc "Removes entries in the searches table that are older than the number of days given."
  task :delete_old_searches, [:days_old] => [:environment] do |t, args|
    args.with_defaults(:days_old => 7)    
    Search.delete_old_searches(args[:days_old].to_i)
  end

  namespace :solr do
    desc "Put sample data into solr"
    task :seed do
      docs = YAML::load(File.open(File.join(Blacklight.root, 'solr', 'sample_solr_documents.yml')))
      Blacklight.solr.add docs
      Blacklight.solr.commit
    end
  end

end
  

