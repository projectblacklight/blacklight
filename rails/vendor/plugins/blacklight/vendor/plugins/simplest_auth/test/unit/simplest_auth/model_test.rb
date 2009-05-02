require File.dirname(__FILE__) + '/../../test_helper'

class User
  include SimplestAuth::Model
end

class UserTest < Test::Unit::TestCase
  include BCrypt
  
  context "the User class" do
    should "find a user by email for authentication" do
      user_stub = stub()
      user_stub.stubs(:authentic?).with('password').returns(true)
      User.stubs(:find_by_email).with('joe@schmoe.com').returns(user_stub)
      
      assert_equal user_stub, User.authenticate('joe@schmoe.com', 'password')
    end
  end
  
  context "an instance of the User class" do
    setup do
      @user = User.new
      @user.stubs(:crypted_password).returns('abcdefg')
    end
    
    should "determine if a password is authentic" do
      password_stub = stub
      password_stub.stubs(:==).with('password').returns(true)
      Password.stubs(:new).with('abcdefg').returns(password_stub)
      
      assert @user.authentic?('password')
    end
    
    should "determine when a password is not authentic" do
      password_stub = stub
      password_stub.stubs(:==).with('password').returns(false)
      Password.stubs(:new).with('abcdefg').returns(password_stub)
      
      assert_equal false, @user.authentic?('password')
    end
    
    should "use the Password class == method for comparison" do
      password_stub = mock
      password_stub.expects(:==).with('password').returns(true)
      Password.stubs(:new).with('abcdefg').returns(password_stub)
      
      @user.authentic?('password')
    end
    
    should "use a new Password made from crypted_password" do
      password_stub = stub
      password_stub.stubs(:==).with('password').returns(true)
      Password.expects(:new).with('abcdefg').returns(password_stub)
      
      @user.authentic?('password')
    end
  end
end
