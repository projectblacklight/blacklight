@unapi
Feature: unAPI
  In order to discover underlying document data
  As a user
  I want to use an unAPI endpoint
  
  Scenario: Search Page has unAPI discovery link and microformats
    When I go to the catalog page
    And I fill in the search box with ""
    And I press "search"
    Then I should see an unAPI discovery link 
    And I should see a "abbr" element with "class" = "unapi-id" exactly 10 times

  Scenario: Document Page has an unAPI discovery link and microformat
    Given I am on the document page for id 2007020969
    Then I should see an unAPI discovery link
    And I should see a "abbr" element with "class" = "unapi-id" at least 1 time

  Scenario: unAPI endpoint with no parameters
    When I go to the unAPI endpoint

  Scenario: Request list of formats for an object
    When I go to the unAPI endpoint for "2007020969"

  Scenario: Request format of object
    When I go to the unAPI endpoint for "2007020969" with format "oai_dc_xml"
