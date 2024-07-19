/**
 * Created by BA Westbrook on 13/06/24.
 */

public without sharing class ResultTriggerHandler{

    private final Boolean triggerIsExecuting;
    private final Integer triggerSize;
    public ResultTriggerHelper helper;
    
    public ResultTriggerHandler (Boolean triggerIsExecuting, Integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.helper = new ResultTriggerHelper ();
    }
    public void beforeUpdate(List<Result__c> oldList, List<Result__c> newList, Map<Id, Result__c> oldMap, Map<Id, Result__c> newMap) {
        helper.CalculatePass (oldList, newList, oldMap, newMap);
    }
    public void afterUpdate(List<Result__c> oldList, List<Result__c> newList, Map<Id, Result__c> oldMap, Map<Id, Result__c> newMap) {
        helper.CalculateGrade (oldList, newList, oldMap, newMap);
    }
    public void beforeInsert(List<Result__c> newList, Map<Id, Result__c> newMap) {
        helper.CalculatePass (null, newList, null, newMap);
    }
    public void afterInsert(List<Result__c> newList, Map<Id, Result__c> newMap) {
        helper.CalculateGrade (null, newList, null, newMap);
    }
    /*
    public void beforeDelete(List<Result__c> oldList, Map<Id, Result__c> oldMap) {
    }
    public void afterDelete(List<Result__c> oldList, Map<Id, Result__c> oldMap) {
    }
    public void afterUndelete(List<Result__c> newList, Map<Id, Result__c> newMap) {
    }
    */
}