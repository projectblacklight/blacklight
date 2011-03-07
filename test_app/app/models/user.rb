class User < ActiveRecord::Base
  include Blacklight::User::UserGeneratedContent
  include Blacklight::User::Authlogic
  
  #
  # Does this user actually exist in the db?
  #
  def is_real?
    self.class.count(:conditions=>['id = ?',self.id]) == 1
  end
end
