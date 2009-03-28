class Blacklight::Installer
  
  def initialize
    
  end
  
  def install
    
  end
  
  protected
  
  # Install hook code here
  def copy_install_file(source, dest)
    full_dest = File.join(RAILS_ROOT, dest)
    return if File.exists?(full_dest)
    puts "
    * Copying #{source} to #{dest}
    "
    FileUtils.cp File.join(RAILS_ROOT, 'vendor', 'plugins', 'blacklight', 'install', source), full_dest
  end

  def install_solr
    puts "Do you want to install Solr with the default Blacklight settings?"
    return unless gets=~/^y/
    dest = File.join(RAILS_ROOT, 'tmp', 'apache-solr.1.3.0.tgz')
    File.rm(dest) if File.exists?(dest)
    `curl http://mirror.nyi.net/apache/lucene/solr/1.3.0/apache-solr-1.3.0.tgz -o #{dest}`
    #`mkdir ../../../apache-solr`
  end
  
  
end