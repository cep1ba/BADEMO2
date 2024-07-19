/**
 * Created by BA Westbrook on 13/06/24
 */

@IsTest
private class EnrolmentTriggerTest {
    @IsTest
    static void test() {
        Account acc = TestDataFactory.CreateAccount(null, 1, true)[0];
        List<Contact> contacts = TestDataFactory.CreateContact('Student',acc,'Student', 10, true);
        List<Contact> supervisors = TestDataFactory.CreateContact('Supervising Pharmacist',acc,'Contact', 2, true);

        List<Student_Number_Generator__c> numbers = [SELECT Name FROM Student_Number_Generator__c];
        List<Contact> insertedContacts = [SELECT AccountId,Name, Student_Number__c FROM Contact where Type__c = 'Student'];

        Map<String, Contact> mapNumberToContact = new Map<String, Contact>();
        for (Contact c : insertedContacts) {
            mapNumberToContact.put(c.Student_Number__c, c);
        }
        
        Course__c cs = new Course__c(name = 'ADAC');
        insert cs;
        
        Course__c cs2 = new Course__c(name = 'BTEC',Intake_Frequency__c = 'Monthly');
        insert cs2;
        
        Module__c mod = new Module__c (name = 'BTEC Year 1', Course__c = cs2.Id,Primary__c = true);
        insert mod;
        
        Module__c mod2 = new Module__c (name = 'BTEC Year 2', Course__c = cs2.Id);
        insert mod2;
        
        Product2 p = new Product2 (IsActive = TRUE, Name = 'Test product', Module__c = mod.Id);
        insert p;
        
        List<Enrolment__c> enrolments = new List<Enrolment__c>();
        for (Contact c : insertedContacts) {
            enrolments.add(new Enrolment__c(Contact__c = c.Id,Module__c = mod.Id, Account__c = acc.Id,Supervisor__c = supervisors[0].Id));
            enrolments.add(new Enrolment__c(Contact__c = c.Id,Module__c = mod2.Id, Account__c = acc.Id,Supervisor__c = supervisors[0].Id));
        }
        insert enrolments;
        
        for (Enrolment__c e : enrolments) {
            e.Status__c = 'Accepted';
        }
        update enrolments;

        for (Student_Number_Generator__c generator : numbers) {
            System.assertNotEquals(null, generator.Name);
            Contact c = mapNumberToContact.get(generator.Name);
            System.assertEquals(generator.Name, c.Student_Number__c);
        }
    }
}