@record
Feature: Record View
  In order to verify the information on the record view (CatalogController#show)
  As a user
  I want to see the appropriate information in context to the records being viewed

  Scenario: Normal record
    Given I am on the document page for id 2007020969
    Then I should see a "dt" element containing "Title:"
    And I should see a "dd" element containing "Strong Medicine speaks"
    And I should see a "dt" element containing "Subtitle:"
    And I should see a "dd" element containing "a Native American elder has her say : an oral history"
    And I should see a "dt" element containing "Author:"
    And I should see a "dd" element containing "Hearth, Amy Hill, 1958-"
    And I should see a "dt" element containing "Format:"
    And I should see a "dd" element containing "Book"
    And I should see a "dt" element containing "Call number:"
    And I should see a "dd" element containing "E99.D2 H437 2008"
    And I should see link rel=alternate tags

  Scenario: Blank titles do not show up
    Given I am on the document page for id 2008305903
    Then I should not see a "dt" element containing "More Information:"

  Scenario: Vernacular record
    Given I am on the document page for id 2009373513
    Then I should see a "dd" element containing "次按驟變"
    And I should see a "dd" element containing "林行止"
    And I should see a "dd" element containing "臺北縣板橋市"
