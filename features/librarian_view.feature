Feature: Librarian view
  In order to verify that we are showing the librarian view
  As a user
  I want to see raw data

  Scenario: MARC
    Given I am on the document page for id 2009373513
    When I follow "Librarian View"
    Then I should see "Librarian View"
    And I should see "LEADER 01213nam a22003614a 4500"
    And I should see "100"
    And I should see "Lin, Xingzhi."
    And I should see "6|"
  
  
  

  
