@isTest
public class LWCOnlineTrackerTest {

    @isTest
    public static void testGetChartData(){
        Account acc = TestDataFactory.CreateAccount(null, 1, true)[0];
        List<Contact> contacts = TestDataFactory.CreateContact('Student', acc,'Student', 10, true);
        
        User portalUser = TestDataFactory.createPortalUser(contacts[0].Id, true);

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
        
        System.runAs(portalUser){
            LWCOnlineTracker.getChartData();
        }
    }
    
    @isTest
    public static void testGetEnrolments(){
        LWCOnlineTracker.getEnrolments();
    }
}