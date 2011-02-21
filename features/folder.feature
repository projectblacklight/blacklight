Feature: User Folder
  In order to keep track of items
  As a user
  I want to be able to store items in my folder

  Scenario: Ensure "Add to Folder" form is present in search results
	  Given I am on the home page
    When I fill in "q" with "history"
    And I select "All Fields" from "search_field"
    And I press "search"
 	  Then I should see an add to folder form
      
 	Scenario: Ensure "Add to Folder" for is present on individual record
    Given I am on the document page for id 2007020969
 	  Then I should see an add to folder form
 	  
 	Scenario: Adding an item to the folder should produce a status message
    Given I am on the home page
    And I follow "English"
 	  And I add record 2008308175 to my folder
 	  Then I should see "Pluvial nectar of blessings successfully selected"
	  
	Scenario: Do not show "Add to Favorites" when not logged in
	  Given I have record 2007020969 in my folder
	  When I follow "Selected Items"
	  Then I should not see "Add to Folder"
	  
	Scenario: Show "Add to Favorites" when logged in and viewing folder
    Given I am logged in as "user1"
	  And I have record 2007020969 in my folder
    When I follow "Selected Items"
    Then I should see "Add to Bookmarks"
    	  
	Scenario: Do multiple citations when the folder has multiple items
    Given I have record 2007020969 in my folder
    And I have record 2008308175 in my folder
	  And I follow "Cite"
 	  Then I should see "Pluvial Nectar of Blessings : a Supplication to the Noble Lama Mahaguru Padmasambhava. Dharamsala: Library of Tibetan Works and Archives, 2002."
 	  And I should see "a Native American elder has her say : an oral history. 1st Atria Books hardcover ed. New York: Atria Books."
 	  
 	Scenario: Make sure the folder page doesn't bomb if there is no search session
 	  Given I am on the folder page
 	  # That's all that is needed -- it will fail to render if it's not right
 	  
 	Scenario: Don't show the tools if there are no items in the folder
 	  Given I am on the folder page
 	  Then I should not see the Folder tools

  Scenario: Show the tools if there are items in the folder
    Given I have record 2008308175 in my folder
 	  And I follow "Selected Items"
 	  Then I should see the Folder tools
 	  
 	Scenario: Controls on the record view
 	  When I am on the document page for id 2008308175
 	  Then I should see an add to folder form
 	  Given I have record 2008308175 in my folder
 	  When I am on the document page for id 2008308175
 	  Then I should see a remove from folder form
 	  
 	Scenario: Controls on the folder view
    Given I have record 2008308175 in my folder
    When I am on the folder page
    Then I should see a remove from folder form
    When I remove record 2008308175 from my folder
    Then I should not see the Folder tools