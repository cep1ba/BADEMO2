/**
 * Created by BA Westbrook on 13/06/24.
 * Set Student and Supervisor Contact Student Number and Pwd fields when Enrolment Status changes to Accepted for 
 */

public without sharing class EnrolmentTriggerHelper {
    public EnrolmentTriggerHelper () {
        System.debug('Inside EnrolmentTriggerHelper Constructor');
    }
    
    public void SetParent (List<Enrolment__c> oldList, List<Enrolment__c> newList, Map<Id, Enrolment__c> oldMap, Map<Id, Enrolment__c> newMap) {
        Map <String,Id> childMap = new Map<String,Id>();
        Map <String,Id> parentMap = new Map<String,Id>();
             
        for (Enrolment__c e : newList) {
            if(e.Parent__c ==  null && !e.Primary__c && e.Status__c != 'Completed' && e.Status__c != oldMap.get(e.Id).Status__c){
                childMap.put(e.Parent_Key__c,e.Id);
            }
        }
        
        if(!childMap.isEmpty()){
            for (Enrolment__c e : [SELECT Id,Parent_Key__c from Enrolment__c where Parent_Key__c in :childMap.keySet() AND Primary__c = true]) {
                parentMap.put(e.Parent_Key__c,e.Id);
            }
            
            if(!parentMap.isEmpty()){
                List <Enrolment__c> enrolmentUpdates = new List<Enrolment__c>();
                
                for (Enrolment__c e : [SELECT Id,Parent_Key__c from Enrolment__c where Parent_Key__c in :childMap.keySet() AND Primary__c = false]) {
                    Enrolment__c enrolment = new Enrolment__c(Id = e.Id,Parent__c = parentMap.get(e.Parent_Key__c));
                    enrolmentUpdates.add(enrolment);
                }
                system.debug('enrolmentUpdates[0]='+enrolmentUpdates[0]);
                if(!enrolmentUpdates.isEmpty()){
                    update enrolmentUpdates;
                }
            }
        }
    }
    
    public void SetIntakeDate (List<Enrolment__c> oldList, List<Enrolment__c> newList, Map<Id, Enrolment__c> oldMap, Map<Id, Enrolment__c> newMap) {
        //Weekly Course - start of current week
        //Monthly Course - 1st of next month with minimum gap of 15 days
        
        Enrolment_Settings__mdt setting = [SELECT IntakeLeadDays__c FROM Enrolment_Settings__mdt where Label = 'Default'];
        
        for (Enrolment__c e : newList) {
            if(e.Intake_Date__c ==  null && e.Status__c == 'Accepted' && e.Status__c != oldMap.get(e.Id).Status__c){
                if(e.Course_Frequency__c == 'Monthly'){
                    Date dateNextMonth = Date.Today().addMonths(1);
                    dateNextMonth  = Date.newInstance(dateNextMonth.year(), dateNextMonth.month(), 1);
                    Integer daysBetween = Date.Today().daysBetween(dateNextMonth);

                    if(daysBetween < setting.IntakeLeadDays__c){
                        dateNextMonth = Date.Today().addMonths(2+Integer.valueOf(e.IntakeDelayMonths__c));
                        e.Intake_Date__c = Date.newInstance(dateNextMonth.year(), dateNextMonth.month(), 1);
                    }
                    else{
                        dateNextMonth = Date.Today().addMonths(1+Integer.valueOf(e.IntakeDelayMonths__c));
                        e.Intake_Date__c = Date.newInstance(dateNextMonth.year(), dateNextMonth.month(), 1);
                    }
                }
                else{
                    e.Intake_Date__c = Date.Today().toStartofWeek();
                }
            }
        }
    }
    
    
    public void GenerateStudentNumber (List<Enrolment__c> oldList, List<Enrolment__c> newList, Map<Id, Enrolment__c> oldMap, Map<Id, Enrolment__c> newMap) {
        List<Student_Number_Generator__c> generators = new List<Student_Number_Generator__c>();
        Integer i = 0;
        Set <Id> generatorIds = new Set<Id>();
        Set <Id> contactIds = new Set<Id>();
        Id studentRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId();
        
        Map<Id,Enrolment__c> enrolmentMap = new Map<Id,Enrolment__c>([
            SELECT Supervisor__r.Student_Number__c,Contact__r.RecordTypeId,Contact__r.Student_Number__c 
            FROM Enrolment__c
            WHERE Id in : newMap.keySet()
        ]);
        
        for (Enrolment__c e : newList) {           
            if(e.Status__c == 'Accepted' && e.Status__c != oldMap.get(e.Id).Status__c){
                 //Enrolment Status changed to Accepted
                if(enrolmentMap.get(e.Id).Contact__r.RecordTypeId == studentRecTypeId && String.isBlank(enrolmentMap.get(e.Id).Contact__r.Student_Number__c)) {
                    contactIds.add(e.Contact__c);
                    generators.add(new Student_Number_Generator__c());
                }
                if(e.Supervisor__c != null && String.isBlank(enrolmentMap.get(e.Id).Supervisor__r.Student_Number__c)) {
                    contactIds.add(e.Supervisor__c);
                    generators.add(new Student_Number_Generator__c());
                }
            }
            else if(e.Supervisor__c != null && e.Supervisor__c != oldMap.get(e.Id).Supervisor__c && String.isBlank(enrolmentMap.get(e.Id).Supervisor__r.Student_Number__c)){
                //Enrolment Supervisor is changed
                contactIds.add(e.Supervisor__c);
                generators.add(new Student_Number_Generator__c());
            }
            else if(e.Contact__c != oldMap.get(e.Id).Contact__c && String.isBlank(enrolmentMap.get(e.Id).Contact__r.Student_Number__c)){
                //Enrolment Student is changed
                contactIds.add(e.Contact__c);
                generators.add(new Student_Number_Generator__c());
            }
        }
        
        List<Contact> conList = [SELECT Id from Contact where Id in :contactIds];
        
        
        if(!generators.isEmpty()){
            insert generators;
            
            for (Student_Number_Generator__c g : generators) {
                generatorIds.add(g.Id);
            }
            
            generators = [SELECT Name, Id FROM Student_Number_Generator__c WHERE Id IN :generatorIds];
            system.debug('generators='+generators);
            for (Contact c : conList) {
                if(generators[i] != null) {
                    c.Student_Number__c =  generators[i].Name;
                    c.Canvas_Password__c =  GeneratePassword(8);
                    c.VQM_Password__c =  GeneratePassword(8);
                    i++;
                }
            }
            update conList;
        }
        system.debug('conList='+conList);
    }
    
    private static String GeneratePassword(Integer len){
          Blob blobKey = crypto.generateAesKey(128);
          String key = EncodingUtil.convertToHex(blobKey);
          return key.substring(0,len);
     }
}