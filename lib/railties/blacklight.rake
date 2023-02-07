# frozen_string_literal: true

namespace :blacklight do
  # task to clean out old, unsaved searches
  # rake blacklight:delete_old_searches[days_old]
  # example cron entry to delete searches older than 7 days at 2:00 AM every day:
  # 0 2 * * * cd /path/to/your/app && /path/to/rake blacklight:delete_old_searches[7] RAILS_ENV=your_env
  desc "Removes entries in the searches table that are older than the number of days given."
  task :delete_old_searches, [:days_old] => [:environment] do |_t, args|
    args.with_defaults(days_old: 7)
    Search.delete_old_searches(args[:days_old].to_i)
  end

  namespace :index do
    desc <<-EODESC.gsub(/\n\s*/, ' ')
      Index sample data (from FILE, ./spec/fixtures/sample_solr_documents.yml in this application,
        or the test fixtures from blacklight) into solr.
    EODESC
    task seed: [:environment] do
      require 'yaml'

      app_file = Rails.root && "#{Rails.root}spec/fixtures/sample_solr_documents.yml"
      file = ENV.fetch('FILE') { (app_file && File.exist?(app_file) && app_file) } ||
             File.join(Blacklight.root, 'spec', 'fixtures', 'sample_solr_documents.yml')
      docs = YAML.safe_load(File.open(file))
      conn = Blacklight.default_index.connection
      conn.add docs
      conn.commit
    end
  end

  namespace :check do
    desc "Check the Solr connection and controller configuration"
    task :solr, [:controller_name] => [:environment] do
      conn = Blacklight.default_index
      if conn.ping
        puts "OK"
      else
        puts "Unable to reach: #{conn.uri}"
        exit 1
      end
    rescue => e
      puts e.to_s
      exit 1
    end

    task :controller, [:controller_name] => [:environment] do |_, args|
      errors = 0
      verbose = ENV.fetch('VERBOSE', false).present?
      controller = args[:controller_name].constantize.new if args[:controller_name]
      controller ||= CatalogController.new

      puts "[#{controller.class}]"

      print " - find: "

      begin
        response = controller.find q: '{!lucene}*:*'
        if response.header['status'].zero?
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
      rescue => e
        errors += 1
        puts e.to_s
      end

      print " - search_results: "

      begin
        response, docs = controller.search_results(q: '{!lucene}*:*')

        if response.header['status'].zero? && docs.any?
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
      rescue => e
        errors += 1
        puts e.to_s
      end

      print " - fetch: "

      begin
        doc_id = response.documents.first.id
        response, doc = controller.fetch doc_id

        if response.header['status'].zero? && doc
          puts "OK"
        else
          errors += 1
        end

        if verbose
          puts "\tstatus: #{response.header['status']}"
        end
      rescue => e
        errors += 1
        puts e.to_s
      end

      exit 1 if errors > 0
    end
  end
end

if Rake::Task.task_defined?('stimulus:manifest:display')
  Rake::Task['stimulus:manifest:display'].enhance do
    puts Stimulus::Manifest.generate_from(Blacklight::Engine.root.join("app/javascript/controllers")).join("\n").gsub('./blacklight/', 'blacklight-frontend/app/javascript/controllers/blacklight/')
  end
end

if Rake::Task.task_defined?('stimulus:manifest:update')
  Rake::Task['stimulus:manifest:update'].enhance do
    manifest = Stimulus::Manifest.generate_from(Blacklight::Engine.root.join("app/javascript/controllers")).join("\n").gsub('./blacklight/',
                                                                                                                            'blacklight-frontend/app/javascript/controllers/blacklight/')
    File.open(Rails.root.join("app/javascript/controllers/index.js"), "a+") do |index|
      index.puts manifest
    end
  end
end
