@saved_searches
Feature: Saved Searches Page
  As a user
  In order see searches I've saved and reuse them
  I want a page that shows my saved searches
    
  Scenario: Menu Link
    Given I am logged in as "user1"
    When I am on the home page
    Then I should see "Saved Searches"
    When I follow "Saved Searches"
    Then I should be on the saved searches page
    And I should see a stylesheet
  
  Scenario: No Searches
    Given I am logged in as "user1"
    Given no previous searches
    When I go to the saved searches page
    Then I should see "You have no saved searches"
    
  # Scenario: Saved Searches not logged in
  #   When I go to the saved searches page
  #   Then I should see "Sign in"
    
  Scenario: Saved Searches
    Given I am logged in as "user1"
    And "user1" has saved a search with term "book"
    When I go to the saved searches page
    Then I should see "Your saved searches"
    And I should see "book"
    
  Scenario: Deleting a Saved Search
    Given I am logged in as "user1"
    And "user1" has saved a search with term "book"
    And I am on the saved searches page
    Then I should see a "delete" button
    When I press "delete"
    Then I should see "Successfully removed that saved search."

  Scenario: Clearing Saved Searches
    Given I am logged in as "user1"
    And "user1" has saved a search with term "book"
    And "user1" has saved a search with term "dang"
    And I am on the saved searches page
    Then I should see "Clear Saved Searches"
    When I follow "Clear Saved Searches"
    Then I should see "Cleared your saved searches."
    And I should see "You have no saved searches"

