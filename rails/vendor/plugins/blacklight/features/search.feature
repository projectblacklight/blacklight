Feature: Search
  In order to find documents
  As a user
  I want enter terms, select fields, and select number of results per page

  Scenario: Search Page
    When I go to the home page
    Then I should see a search field
    And I should see a selectable list with field choices
    And I should see a "search" button
  
  Scenario: Search Page's field choices
    Given the application is configured to have searchable fields "All Fields, Title, Author, Subject"
    And I am on the home page
    Then I should see select list "select#qt" with field labels "All Fields, Title, Author, Subject"
    
  Scenario: Submitting a Search
    Given the application is configured to have searchable fields "All Fields, Title, Author, Subject"
    When I am on the home page
    And I fill in "q" with "book"
    And I select "All Fields" from "qt"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see select list "select#qt" with "All Fields" selected
    And I should see "per page"
    And I should see a selectable list with per page choices
    And I should see "1."
    And I should see "2."
    And I should see "3."
    And I should see "results sorted by"

  Scenario: Submitting a Search with specific field selected
    Given the application is configured to have searchable fields "All Fields, Title, Author, Subject"
    When I am on the home page
    And I fill in "q" with "book"
    And I select "Title" from "qt"
    And I press "search"
    Then I should be on "the catalog page"
    And I should see select list "select#qt" with "Title" selected
    And I should see "1."
    And I should see "2."
    And I should see "3."
    And I should see "results sorted by"

  Scenario: Results Page
    Given I am on the home page
    And the application is configured to have sort fields "relevance, title, format"
    And I fill in "q" with "book"
    When I press "search"
    Then I should see select list "select#sort" with field labels "relevance, title, format"
  
  
  
  
  
  
