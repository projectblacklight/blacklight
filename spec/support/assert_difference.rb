# -*- encoding : utf-8 -*-
# Added based on http://www.arctickiwi.com/blog/upgrading-to-rspec-2-with-ruby-on-rails-3
# God bless you Jonathon Horsman 
def assert_difference(executable, how_many = 1, &block)
  before = eval(executable)
  yield
  after = eval(executable)
  after.should == before + how_many
end

def assert_no_difference(executable, &block)
  before = eval(executable)
  yield
  after = eval(executable)
  after.should == before
end

