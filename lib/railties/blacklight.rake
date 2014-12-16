
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
      conn = RSolr.connect(Blacklight.connection_config)
      conn.add docs
      conn.commit
    end
  end

  namespace :check do
    desc "Check the Solr connection and controller configuration"
    task :solr, [:controller_name] => [:environment] do |_, args|
      errors = 0
      verbose = ENV.fetch('VERBOSE', false).present?

      conn = RSolr.connect(Blacklight.connection_config)
      puts "[#{conn.uri}]"

      print " - admin/ping: "
      begin
        response = conn.send_and_receive 'admin/ping', {}
        puts response['status']
        errors += 1 unless response['status'] == "OK"
      rescue Exception => e
        errors += 1
        puts e.to_s
      end

      exit 1 if errors > 0
    end

    task :controller, [:controller_name] => [:environment] do |_, args|
      errors = 0
      verbose = ENV.fetch('VERBOSE', false).present?
      controller = args[:controller_name].constantize.new if args[:controller_name]
      controller ||= CatalogController.new

      puts "[#{controller.class.to_s}]"

      print " - find: "

      begin
        response = controller.find q: '{!lucene}*:*'
        if response.header['status'] == 0
          puts "OK"
        else
          errors += 1
        end

        if verbose
          puts "\tstatus: #{response.header['status']}"
          puts "\tnumFound: #{response.response['numFound']}"
          puts "\tdoc count: #{response.docs.length}"
          puts "\tfacet fields: #{response.facets.length}"
        end
      rescue Exception => e
        errors += 1
        puts e.to_s
      end

      print " - get_search_results: "
  
      begin
        response, docs = controller.get_search_results({}, q: '{!lucene}*:*')

        if response.header['status'] == 0 and docs.length > 0
          puts "OK"
        else
          errors += 1
        end

        if verbose
          puts "\tstatus: #{response.header['status']}"
          puts "\tnumFound: #{response.response['numFound']}"
          puts "\tdoc count: #{docs.length}"
          puts "\tfacet fields: #{response.facets.length}"
        end
      rescue Exception => e
        errors += 1
        puts e.to_s
      end

      print " - get_solr_response_for_doc_id: "

      begin
        doc_id = response.docs.first[SolrDocument.unique_key]
        response, doc = controller.get_solr_response_for_doc_id doc_id

        if response.header['status'] == 0 and doc
          puts "OK"
        else
          errors += 1
        end

        if verbose
          puts "\tstatus: #{response.header['status']}"
        end
      rescue Exception => e
        errors += 1
        puts e.to_s
      end

      exit 1 if errors > 0
    end
  end
end
