@record
Feature: Record View
  In order to verify the information on the record view (CatalogController#show)
  As a user
  I want to see the appropriate information in context to the records being viewed

  # DHF:  Note, I removed the within 'dt' and 'dd' below - while possible to make it work
  #       it doesn't seem in line with the user-perspective nature of these cucumber tests
  #       and it also doesn't seem to add anything of value to test for these - but rather
  #       makes the test more brittle. 

  Scenario: Normal record
    Given I am on the document page for id 2007020969
    Then I should see "Title:" 
    And I should see "Strong Medicine speaks" 
    And I should see "Subtitle:" 
    And I should see "a Native American elder has her say : an oral history" 
    And I should see "Author:" 
    And I should see "Hearth, Amy Hill, 1958-"
    And I should see "Format:" 
    And I should see "Book" 
    And I should see "Call number:"
    And I should see "E99.D2 H437 2008"
    And I should see link rel=alternate tags

  Scenario: Blank titles do not show up
    Given I am on the document page for id 2008305903
    Then I should not see "More Information:"

  Scenario: Vernacular record
    Given I am on the document page for id 2009373513
    Then I should see /次按驟變/
    And I should see /林行止/
    And I should see /臺北縣板橋市/

  Scenario: a document is requested doesn't exist in solr
    Given I am on the document page for id this_id_does_not_exist
    Then I should get a status code 404
    And I should see "Sorry, you have requested a record that doesn't exist."
    
