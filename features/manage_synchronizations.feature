@synchronizations
Feature: Synchronizations
  In order to have synchronizations on my website
  As an administrator
  I want to manage synchronizations

  Background:
    Given I am a logged in refinery user
    And I have no synchronizations

  @synchronizations-list @list
  Scenario: Synchronizations List
   Given I have synchronizations titled UniqueTitleOne, UniqueTitleTwo
   When I go to the list of synchronizations
   Then I should see "UniqueTitleOne"
   And I should see "UniqueTitleTwo"

  @synchronizations-valid @valid
  Scenario: Create Valid Synchronization
    When I go to the list of synchronizations
    And I follow "Add New Synchronization"
    And I fill in "Model Name" with "This is a test of the first string field"
    And I press "Save"
    Then I should see "'This is a test of the first string field' was successfully added."
    And I should have 1 synchronization

  @synchronizations-invalid @invalid
  Scenario: Create Invalid Synchronization (without model_name)
    When I go to the list of synchronizations
    And I follow "Add New Synchronization"
    And I press "Save"
    Then I should see "Model Name can't be blank"
    And I should have 0 synchronizations

  @synchronizations-edit @edit
  Scenario: Edit Existing Synchronization
    Given I have synchronizations titled "A model_name"
    When I go to the list of synchronizations
    And I follow "Edit this synchronization" within ".actions"
    Then I fill in "Model Name" with "A different model_name"
    And I press "Save"
    Then I should see "'A different model_name' was successfully updated."
    And I should be on the list of synchronizations
    And I should not see "A model_name"

  @synchronizations-duplicate @duplicate
  Scenario: Create Duplicate Synchronization
    Given I only have synchronizations titled UniqueTitleOne, UniqueTitleTwo
    When I go to the list of synchronizations
    And I follow "Add New Synchronization"
    And I fill in "Model Name" with "UniqueTitleTwo"
    And I press "Save"
    Then I should see "There were problems"
    And I should have 2 synchronizations

  @synchronizations-delete @delete
  Scenario: Delete Synchronization
    Given I only have synchronizations titled UniqueTitleOne
    When I go to the list of synchronizations
    And I follow "Remove this synchronization forever"
    Then I should see "'UniqueTitleOne' was successfully removed."
    And I should have 0 synchronizations
 