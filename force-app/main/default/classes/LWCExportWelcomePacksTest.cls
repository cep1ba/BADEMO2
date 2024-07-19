@isTest
public class LWCExportWelcomePacksTest {

    @isTest
    public static void testGetEnrolments(){
        Account acc = TestDataFactory.CreateAccount(null, 1, true)[0];
        List<Contact> contacts = TestDataFactory.CreateContact('Student', acc,'Student', 10, true);

        List<Student_Number_Generator__c> numbers = [SELECT Name FROM Student_Number_Generator__c];
        List<Contact> insertedContacts = [SELECT AccountId,Name, Student_Number__c FROM Contact];

        Map<String, Contact> mapNumberToContact = new Map<String, Contact>();
        for (Contact c : insertedContacts) {
            mapNumberToContact.put(c.Student_Number__c, c);
        }

        Course__c cs = new Course__c(name = 'ADAC');
        insert cs;
        
        Module__c mod = new Module__c (name = 'ADAC', Course__c = cs.Id,Primary__c=true);
        insert mod;
        
        Product2 p = new Product2 (IsActive = TRUE, Name = 'Test product', Module__c = mod.Id);
        insert p;
        
        List<Enrolment__c> enrolments = TestDataFactory.CreateEnrolments(insertedContacts, true, mod.Id, acc.Id);
        
        for (Enrolment__c e : enrolments) {
            e.Status__c = 'Accepted';
        }
        update enrolments;

        test.startTest();
        LWCExportWelcomePacks.getEnrolments();
        test.stopTest();
    }
    
    @isTest
    public static void testSetSentFlags(){
        List<Enrolment__c> enrolments = [SELECT Id,Parent__c,Welcome_Pack_Sent__c FROM Enrolment__c];
        List<String> enrolmentIds = new List<String>();
        for (Enrolment__c e : enrolments){
            enrolmentIds.add(e.Id);
        }
        test.startTest();
        LWCExportWelcomePacks.setSentFlags(enrolmentIds);
        test.stopTest();
        List<Enrolment__c> updatedEnrolments = [SELECT Id,Parent__c,Welcome_Pack_Sent__c FROM Enrolment__c WHERE Id in :enrolmentIds];
        for (Enrolment__c e : updatedEnrolments){
            System.assertEquals(true,e.Welcome_Pack_Sent__c);
        }
        
    }}