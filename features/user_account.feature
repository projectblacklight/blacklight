@account
Feature: User Account
  In order to save information between sessions
  As a user
  I want to create an account and login and logout of my account

  Scenario: Login page
    Given I am on the home page
    Then I should see "Login"
    When I follow "Login"
    Then I should see "Don't have an account? Create one"
    
  Scenario: Create an account
    Given I am on the login page
    When I follow "Create one"
    Then I should be on the new user page
    When I fill in "Login" with "user1"
    And I fill in "Email" with "user1@email.com"
    And I fill in "Password" with "password"
    And I fill in "Confirm Password" with "password"
    And I press "Create Account"
    Then I should see "Welcome user1"
    And I should see "Log Out"
    
  Scenario: Failed create an account
    Given I am on the login page
    When I follow "Create one"
    Then I should be on the new user page
    When I fill in "Login" with "user1"
    And I fill in "Email" with "user1@email.com"
    And I fill in "Password" with "password"
    And I fill in "Confirm Password" with "wrong-password"
    And I press "Create Account"
    Then I should see "There were problems with the following fields"
    
  Scenario: Login
    Given user with login "user1" and email "user1@foo.com" and password "password"
    And I am on the login page
    When I fill in "Login" with "user1"
    When I fill in "Password" with "password"
    And I press "Login"
    Then I should see "Welcome user1!"
        
    
  Scenario: Failed Login
    Given user with login "user1" and email "user1@foo.com" and password "password"
    And I am on the login page
    When I fill in "Login" with "user1"
    When I fill in "Password" with "wrong-password"
    And I press "Login"
    Then I should see "Couldn't locate a user with those credentials"
    
  Scenario: Logout
    Given I am logged in as "user1"
    Then I should see "Log Out"
    When I follow "Log Out"
    Then I should see "You have successfully logged out."
    
  Scenario: Link to Profile
    Given I am logged in as "user1"
    Then I should see "user1"
    When I follow "user1"
    Then I should be on the user profile page