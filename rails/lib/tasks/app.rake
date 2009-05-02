namespace :app do
  
  namespace :index do
    
    desc 'Index a marc file at FILE=<location-of-file> using the lib/marc_mapper class.'
    task :marc => :environment do
      
      t = Time.now
      
      marc_file = ENV['FILE']
      raise "Invalid file. Set the by using the FILE argument." unless File.exists?(marc_file.to_s)
      
      solr = Blacklight.solr
      
      mapper = MARCMapper.new
      mapper.from_marc_file(marc_file) do |doc,index|
        puts "#{index} -- adding doc w/id : #{doc[:id]} to Solr"
        solr.add(doc)
      end
      
      puts "Sending commit to Solr..."
      solr.commit
      puts "Complete."
      
      puts "Total Time: #{Time.now - t}"
      
    end
    
  end
  
end