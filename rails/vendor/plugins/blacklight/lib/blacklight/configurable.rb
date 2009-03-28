module Blacklight::Configurable
  
  # The config environment name used by the #config method
  #
  # Example:
  #   class MyThing
  #     extend Blacklight::Configurable
  #   end
  #   MyThing.config_env = :production
  # 
  # Now MyThing.config will be the result of:
  #   MyThing.configure(:production) {|config|}
  #
  attr_accessor :env_name
  
  # Serializes and de-serializes the object for deep cloning
  # This prevents a non-:shared environment from overriding the :shared settings
  def deepcopy(obj)
    Marshal::load(Marshal::dump(obj))
  end
  
  # sets the @configs variable to a new Hash
  def reset_configs!
    @configs = {:shared=>{}}
  end
  
  # A hash of all environment configs
  # The key is the environment name, the value a Hash
  def configs
    @configs ? @configs : (reset_configs! and @configs)
  end
  
  # The main config accessor
  def config
    configs[env_name]
  end
  
  # Accepts a value for the environment to configure and a block
  # A hash is yielded to the block
  # If the "env" != :shared,
  # the hash is created by deep cloning the :shared environment config.
  # This makes it possible to create defaults in the :shared config
  def configure(env = :shared, &blk)
    if configs[:shared] and env != :shared
      configs[env] ||= deepcopy(configs[:shared])
    end
    yield configs[env]
  end
  
end