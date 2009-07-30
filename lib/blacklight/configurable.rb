module Blacklight::Configurable
  
  # The config environment name used by the #config method
  #
  # Example:
  #   class MyThing
  #     extend Blacklight::Configurable
  #   end
  # 
  # Now MyThing.config will be the result of:
  #   MyThing.configure(:production) {|config|}
  #
  # You set shared attributes by leaving the first argument blank or passing the :shared value:
  #   MyThing.configure {|config|} 
  # or
  #   MyThing.cofigure(:shared) {|config|}
  
  # sets the @configs variable to a new Hash with empty Hash for :shared key and @config to nil
  def reset_configs!
    @config = nil
    @configs = {:shared=>{}}
  end
  
  # A hash of all environment configs
  # The key is the environment name, the value a Hash
  def configs
    @configs ? @configs : (reset_configs! and @configs)
  end
  
  # The main config accessor. It merges the current configs[RAILS_ENV] 
  # with configs[:shared] and lazy-loads @config to the result.
  def config
    @config ||= configs[:shared].merge(configs[RAILS_ENV] ||= {})
  end
  
  # Accepts a value for the environment to configure and a block
  # A hash is yielded to the block
  # If the "env" != :shared,
  # the hash is created by deep cloning the :shared environment config.
  # This makes it possible to create defaults in the :shared config
  def configure(env = :shared, &blk)
    configs[env] = {}
    yield configs[env]
  end
  
end