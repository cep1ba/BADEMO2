/**
 * Created by BA Westbrook on 13/06/24.
 * Set Enrolment & Result Pass flags and Grades
 */

public without sharing class ResultTriggerHelper {
    public ResultTriggerHelper () {
        System.debug('Inside ResultTriggerHelper Constructor');
    }
    
    public void CalculatePass (List<Result__c> oldList, List<Result__c> newList, Map<Id, Result__c> oldMap, Map<Id, Result__c> newMap) {        
        for (Result__c r : newList) {
            if(r.Mark__c > 0 && r.Pass__c != r.PassCalculated__c){
                r.Pass__c = r.PassCalculated__c;
            }
        }
    }
    
    public void CalculateGrade (List<Result__c> oldList, List<Result__c> newList, Map<Id, Result__c> oldMap, Map<Id, Result__c> newMap) {
        Set <Id> enrolmentIds= new Set<Id>();
        Set <String> enrolmentComponentIds = new Set<String>();
        
        for (Result__c r : newList) {
            if(r.Mark__c > 0 && oldMap == null){
                enrolmentIds.add(r.Enrolment__c);
            }
            else if(r.Mark__c > 0 && r.Mark__c != oldMap.get(r.Id).Mark__c){
                enrolmentIds.add(r.Enrolment__c);
            }
        }
        
        if(!enrolmentIds.isEmpty()){
            System.debug('enrolmentIds='+enrolmentIds);
            
            Map<Id,Enrolment__c> enrolmentMap = new Map<Id,Enrolment__c>([
                SELECT Id,Module_Mark__c
                FROM Enrolment__c
                WHERE Id in : enrolmentIds
            ]);
            
            for (Enrolment__c e : enrolmentMap.values()){
                e.Module_Mark__c = 0;
            }
            
            //Only take the result with the highest resit value
            for (Result__c r : [SELECT Id,Enrolment__c,Component__c,Mark_Weighted__c,EnrolmentComponent__c from Result__c 
                WHERE Enrolment__c in :enrolmentIds ORDER BY Resit__c DESC]
            ) {
                if(enrolmentMap.get(r.Enrolment__c).Module_Mark__c == null){
                    enrolmentMap.get(r.Enrolment__c).Module_Mark__c = 0;
                }
                System.debug('r.EnrolmentComponent__c='+r.EnrolmentComponent__c);
                if(!enrolmentComponentIds.contains(r.EnrolmentComponent__c)){
                    enrolmentMap.get(r.Enrolment__c).Module_Mark__c += r.Mark_Weighted__c;
                    enrolmentComponentIds.add(r.EnrolmentComponent__c);
                }
            }
            System.debug('enrolmentMap.values()='+enrolmentMap.values());
            update enrolmentMap.values();
        }
    }
}