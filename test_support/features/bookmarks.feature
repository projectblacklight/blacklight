@bookmarks
Feature: Bookmarks
  In order to collect documents
  As a user
  I want to bookmark documents
  
  Scenario: Bookmarks Menu Link
    Given I am logged in as "user1"
    When I am on the home page
    Then I should see "Bookmarks"
    When I follow "Bookmarks"
    Then I should be on the bookmarks page
    And I should see a stylesheet
  
    Scenario: No Bookmarks
      Given I am logged in as "user1"
      When I go to the bookmarks page
      Then I should see "You have no bookmarks"
        
    Scenario: Clearing Bookmarks
      Given I am on the document page for id 2007020969
      And I press "Bookmark"
      When I am on the bookmarks page
      Then I should see "Clear Bookmarks"
      When I follow "Clear Bookmarks"
      Then I should see "Cleared your bookmarks."
      And I should see "You have no bookmarks"
      
    Scenario: Adding and removing a bookmark from search results
      Given I am logged in as "user1"
      When I am on the home page
      And I fill in "q" with "book"
      And I press "search"
      When I press "Bookmark"
      Then I should see "Successfully added bookmark."
      # We should be back on search results here, but due to
      # what I believe is a bug in Cucumber with query strings
      # and http Referer, we're not, we're on home page, so we'll
      # navigate back, sorry. 
      And I fill in "q" with "book"
      And I press "search"
      Then I press "Remove bookmark"
      And I should see "Successfully removed bookmark."
      
    Scenario: Adding and deleting bookmark from show page
      Given I am logged in as "user1"
      When I am on the document page for id 2007020969
      Then I should see a "Bookmark" button
      And I press "Bookmark"
      #Then I should see "Successfully added bookmark"
      And I should see a "Remove bookmark" button
      And I press "Remove bookmark"
      And I should see "Successfully removed bookmark"
      
    Scenario: Adding bookmarks after a user logs in
      Given I am on the document page for id 2007020969
      Then I should see a "Bookmark" button
      And I press "Bookmark"
      And I am logged in as "user1"
      When I go to the bookmarks page
      Then I should see a "Remove bookmark" button