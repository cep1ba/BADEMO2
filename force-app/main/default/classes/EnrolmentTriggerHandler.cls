/**
 * Created by BA Westbrook on 13/06/24.
 */

public without sharing class EnrolmentTriggerHandler{

    private final Boolean triggerIsExecuting;
    private final Integer triggerSize;
    public EnrolmentTriggerHelper helper;
    
    public EnrolmentTriggerHandler (Boolean triggerIsExecuting, Integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.helper = new EnrolmentTriggerHelper ();
    }
    public void afterUpdate(List<Enrolment__c> oldList, List<Enrolment__c> newList, Map<Id, Enrolment__c> oldMap, Map<Id, Enrolment__c> newMap) {
        helper.GenerateStudentNumber (oldList, newList, oldMap, newMap);
        helper.SetParent (oldList, newList, oldMap, newMap);
    }
    public void beforeUpdate(List<Enrolment__c> oldList, List<Enrolment__c> newList, Map<Id, Enrolment__c> oldMap, Map<Id, Enrolment__c> newMap) {
        helper.SetIntakeDate (oldList, newList, oldMap, newMap);
    }
    /*
    public void beforeInsert(List<Enrolment__c> newList, Map<Id, Enrolment__c> newMap) {
        helper.SetIntakeDate (newList, newMap);
    }
    public void beforeUpdate(List<Enrolment__c> oldList, List<Enrolment__c> newList, Map<Id, Enrolment__c> oldMap, Map<Id, Enrolment__c> newMap) {
        helper.SetIntakeDate (oldList, newList, oldMap, newMap);
    }
    public void beforeDelete(List<Enrolment__c> oldList, Map<Id, Enrolment__c> oldMap) {
    }
    public void afterInsert(List<Enrolment__c> newList, Map<Id, Enrolment__c> newMap) {
    }
    public void afterDelete(List<Enrolment__c> oldList, Map<Id, Enrolment__c> oldMap) {
    }
    public void afterUndelete(List<Enrolment__c> newList, Map<Id, Enrolment__c> newMap) {
    }
    */
}