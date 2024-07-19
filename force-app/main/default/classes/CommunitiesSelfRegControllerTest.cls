/**
 * An apex page controller that supports self registration of users in communities that allow self registration
 */
@IsTest public with sharing class CommunitiesSelfRegControllerTest {
    @IsTest(SeeAllData=true) 
    public static void testCommunitiesSelfRegController() {
        Account acc = TestDataFactory.CreateAccount(null, 1, true)[0];
        
        acc = [SELECT Id, Membership_Number__c FROM account WHERE Id = :acc.Id LIMIT 1];
         
        CommunitiesSelfRegController controller = new CommunitiesSelfRegController();
        controller.firstName = 'FirstName';
        controller.lastName = 'LastName';
        controller.email = 'test@force.com';
        controller.membershipNumber = acc.Membership_Number__c;
        controller.postcode = 'RG1 1TT';
        controller.password = 'Password1';
        controller.confirmPassword = 'Password1';
        
        // registerUser will always return null when the page isn't accessed as a guest user
        System.assert(controller.registerUser() == null);    
        
        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123';
        System.assert(controller.registerUser() == null);  
    }    
}