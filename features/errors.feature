@errors
Feature: Errors
  In order to recover gracefully
  As an imperfect application
  I want to provide a reasonable user experience when an error is encountered
  
  Scenario: Invalid item id
    Given I am on the document page for id "2004310985"
    Then I should see a flash error "Sorry, you seem to have encountered an error."

  Scenario: Submitting an invalid search 
    When I am on the home page
    And I fill in "q" with "+"
    And I select "All Fields" from "search_field"
    And I press "search"
    Then I should see a flash error "Sorry, I don't understand your search."
