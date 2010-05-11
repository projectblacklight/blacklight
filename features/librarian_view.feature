Feature: Librarian view
  In order to verify that we are showing the librarian view
  As a user
  I want to see raw data

  Scenario: MARC
    Given I am on the document page for id 2009373513
    When I follow "Librarian View"
    Then I should see a "div" element containing "LEADER 01213nam a22003614a 4500"
    And I should see a "span" element containing "100"
    And I should see a "div" element containing "Lin, Xingzhi."
    And I should see a "span" element containing "6|"
  
  
  

  
