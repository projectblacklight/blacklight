@search
Feature: Search
  In order to find documents
  As a user
  I want to enter terms, select fields, and select number of results per page
  
  Scenario: Home Page
    When I go to the home page
    Then I should see a search field
    And I should see a selectable list with field choices
    And I should see a "search" button
    And I should see link "start over"
  
  Scenario: Search Page
    When I go to the catalog page
    Then I should see a search field
    And I should see a selectable list with field choices
    And I should see a "search" button
    And I should see link "start over"
    And I should see "You have no search criteria"
  
  Scenario: Search Page's field choices
    When I am on the home page
    Then I should see select list "select#qt" with field labels "All Fields, Title, Author"
    
  Scenario: Submitting a Search
    When I am on the home page
    And I fill in "q" with "book"
    And I select "All Fields" from "qt"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for book"
    And I should see select list "select#qt" with "All Fields" selected
    And I should see "per page"
    And I should see a selectable list with per page choices
    And I should see "1."
    And I should see "2."
    And I should see "3."
    And I should see "results sorted by"

  Scenario: Submitting a Search with specific field selected
    When I am on the home page
    And I fill in "q" with "inmul"
    And I select "Title" from "qt"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for inmul"
    And I should see select list "select#qt" with "Title" selected
    And I should see "1."
    And I should see "1 result"

  Scenario: Results Page Has Sorting Available
    Given I am on the home page
    And I fill in "q" with "book"
    When I press "search"
    Then I should see select list "select#sort" with field labels "relevance, title, format"
  
  Scenario: Can clear a search
    When I am on the home page
    And I fill in "q" with "book"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see "You searched for book"
    And the "search" field should contain "book"
    When I follow "start over"
    Then I should be on "the catalog page"
    And I should see " You have no search criteria"
    And the "search" field should not contain "book"
  
