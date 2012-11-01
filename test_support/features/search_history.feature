@search_history
Feature: Search History Page
  As a user
  In order see searches I've used and reuse them
  I want a page that shows my (unique) search history from this session
  
  Scenario: Menu Link
    When I am on the home page
    Then I should see "History"
    When I follow "History"
    Then I should be on the search history page
    And I should see a stylesheet
  
  Scenario: Have No Searches
    Given no previous searches
    When I go to the search history page
    Then I should see "You have no search history"
    
  Scenario: Have Searches
    Given I have done a search with term "book"
    When I go to the search history page
    Then I should see "Your recent searches"
    And I should see "book"
    And I should not see "dang"
    Given I have done a search with term "dang"
    When I go to the search history page
    Then I should see "dang"
    And I should see "book"

  Scenario: Clearing Search History
    Given I have done a search with term "book"
    And I have done a search with term "dang"
    And I am on the search history page
    Then I should see "Clear Search History"
    When I follow "Clear Search History"
    Then I should see "Cleared your search history."
    And I should see "You have no search history"
    Then I should not see "book"
    And I should not see "dang"
    
  Scenario: Saving a Search when logged in
    Given I am logged in as "user1"
    And I have done a search with term "book"
    And I am on the search history page
    Then I should see a "save" button
    When I press "save"
    Then I should see "Successfully saved your search."
    And I should be on the search history page
    And I should see a "forget" button

  # Scenario: Saving a Search when not logged in
  #   Given I have done a search with term "book"
  #   And I am on the search history page
  #   Then I should see a "save" button
  #   When I press "save"
  #   Then I should see "Sign in"

  Scenario: Un-Saving a Search when logged in
    Given I am logged in as "user1"
    And I have done a search with term "book"
    And I am on the search history page
    Then I should see a "save" button
    When I press "save"
    Then I should see "Successfully saved your search."
    And I should be on the search history page
    And I should see a "forget" button
    When I press "forget"
    Then I should see "Successfully removed that saved search."
    And I should be on the search history page
    And I should see a "save" button

  Scenario: Visiting Search History with saved searches after logging out
    Given I am logged in as "user1"
    And I have done a search with term "book"
    And I am on the search history page
    Then I should see a "save" button
    When I press "save"
    Then I should see "Successfully saved your search."
    And I should be on the search history page
    And I should see a "forget" button
    When I follow "Log Out"
    Then I should see "Login"
    And I should not see "user1"
    When I follow "History"
    Then I should not see "book"
      
