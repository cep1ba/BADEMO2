/**
 * Created by BA Westbrook on 13/06/24
 */

@IsTest
private class ResultTriggerTest {
    @IsTest
    static void test() {
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
        
        Module__c mod = new Module__c (name = 'ADAC', Course__c = cs.Id);
        insert mod;
        
        Component__c comp = new Component__c (name = 'ADAC Mod 1', Module__c = mod.Id,Pass_Mark__c=50);
        insert comp;
        
        Product2 p = new Product2 (IsActive = TRUE, Name = 'Test product', Module__c = mod.Id);
        insert p;
        
        List<Enrolment__c> enrolments = TestDataFactory.CreateEnrolments(insertedContacts, true, mod.Id, acc.Id);
        
        for (Enrolment__c e : enrolments) {
            e.Status__c = 'Accepted';
        }
        update enrolments;
        
        List<Result__c> results = new List<Result__c>();
        for (Enrolment__c e : enrolments) {
            Result__c res = new Result__c (Enrolment__c = e.Id,Component__c=comp.Id,Mark__c=77);
            results.add(res);
        }
        insert results;
        
        results[0].Mark__c=40;
        update results[0];
    }
}