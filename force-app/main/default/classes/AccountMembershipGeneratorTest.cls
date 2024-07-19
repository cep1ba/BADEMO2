/**
 * Created by himanshu on 09/12/2023.
 */

@IsTest
private class AccountMembershipGeneratorTest {
    private final static Integer Number_Of_Accounts = 10;
    @TestSetup
    static void dataSetup() {
        TestDataFactory.CreateAccount(null, Number_Of_Accounts, true);

    }
    @IsTest
    static void insertAccountTest() {

        List<Membership_Number_Generator__c> membershipNumbers = [SELECT Name FROM Membership_Number_Generator__c];
        List<Account> insertedAccs = [SELECT Name, Membership_Number__c FROM Account];

        Map<String, Account> mapNumberToAccount = new Map<String, Account>();
        for (Account acc : insertedAccs) {
            mapNumberToAccount.put(acc.Membership_Number__c, acc);
        }

        for (Membership_Number_Generator__c generator : membershipNumbers) {
            System.assertNotEquals(null, generator.Name);
            Account acc = mapNumberToAccount.get(generator.Name);
            System.assertEquals(generator.Name, acc.Membership_Number__c);
        }
    }

    //update the Join_Date__c
    @IsTest
    static void updateAccountTest() {
        List<Account> accs = [SELECT Name, Membership_Number__c, Join_Date__c FROM Account ORDER BY CreatedDate DESC];

        //A validation rule prevents changing the membership number to null. We must change to null in order to test update on join_date. 
        insert new Activations__c(SetupOwnerId = UserInfo.getUserId(), Disable_Validations__c = true);

        //Remove the Join_date__c and Membership_Number__c
        List<Account> updateAccounts = new List<Account>();
        for (Account acc : accs) {
            acc.Membership_Number__c = null;
            acc.Join_Date__c = null;
            updateAccounts.add(acc);
        }
        update updateAccounts;

        updateAccounts.clear();

        for (Account acc : accs) {
            acc.Join_Date__c = Date.today();
            updateAccounts.add(acc);
        }
        //update the Join_Date__c

        Test.startTest();
        update updateAccounts;
        Test.stopTest();
        
        List<Membership_Number_Generator__c> membershipNumbers = [SELECT Name FROM Membership_Number_Generator__c ORDER BY CreatedDate DESC LIMIT :Number_Of_Accounts];

        accs = [SELECT Name, Membership_Number__c FROM Account];

        Map<String, Account> mapNumberToAccount = new Map<String, Account>();
        for (Account acc : accs) {
            System.debug('Test acc Membership_Number__c >> ' + acc.Membership_Number__c);
            mapNumberToAccount.put(acc.Membership_Number__c, acc);
        }

        for (Membership_Number_Generator__c generator : membershipNumbers) {
            System.debug('Test generator.Name >> ' + generator.Name);
            System.assertNotEquals(null, generator.Name);
            Account acc = mapNumberToAccount.get(generator.Name);
            System.assertEquals(generator.Name, acc.Membership_Number__c);
        }
    }
}