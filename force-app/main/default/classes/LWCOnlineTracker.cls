/******************************************************************************
* Author: BA Westbrook
* Date: 11/06/2024
* Descpription: Online Tracker
* Set Course External Sharing to Public RO
* Access to child accounts provided by Portal Sharing Set
*/

public with sharing class LWCOnlineTracker {
    public class ChartData {
        @AuraEnabled public String course;
        @AuraEnabled public Integer total;
    }
    
    @AuraEnabled(Cacheable = true)
    public static List<ChartData> getChartData(List<Enrolment__c> enrolments){
        system.debug('enrolments='+enrolments);
        List<AggregateResult> aggrList;
        Set <Id> enrolmentIds = new Set <Id>();
        User portalUser = [Select Id,AccountId from User where Id = :UserInfo.getUserId()];
        Map<Id,Account> accs = new Map<Id,Account>([Select Id from Account where Id = :portalUser.AccountId OR ParentId = :portalUser.AccountId]);
        
        if(enrolments != null && !enrolments.isEmpty()){
            for (Enrolment__c e : enrolments){
                enrolmentIds.add(e.Id);
            }
            aggrList = [
                SELECT Module__r.Course__r.Code__c course,COUNT(Id) total 
                FROM Enrolment__c
                WHERE Id in :enrolmentIds AND Account__c in :accs.keySet()
                GROUP BY Module__r.Course__r.Code__c
            ];
        }
        else{
            aggrList = [
                SELECT Module__r.Course__r.Code__c course,COUNT(Id) total 
                FROM Enrolment__c
                WHERE Account__c in :accs.keySet()
                GROUP BY Module__r.Course__r.Code__c
            ];
        }
        
        List<ChartData> chartDataList = new List<ChartData>();
        for(AggregateResult aggr : aggrList){
            ChartData cd = new ChartData ();
            cd.course=(String)aggr.get('course');
            cd.total=(Integer)aggr.get('total');
            chartDataList.add(cd);
        }
        system.debug('aggrList='+aggrList);
        
        return chartDataList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Enrolment__c> getEnrolments () {
        User portalUser = [Select Id,AccountId from User where Id = :UserInfo.getUserId()];
        Map<Id,Account> accs = new Map<Id,Account>([Select Id from Account where Id = :portalUser.AccountId OR ParentId = :portalUser.AccountId]);
        return [
            SELECT Id,Account__r.Name,Account__r.Membership_Number__c,Account__r.ShippingPostalCode,
            Contact__r.Name,Course__c,Expected_Progress__c,
            Module__c,Module__r.Name,Module_Mark__c,Course_Type__c,
            Grade__c,Registered_Date__c,Status__c,Supervisor__r.Name,
            On_Track__c,Expected_Completion_Date__c,Portal_Link__c,
            (select Id,Component__r.Name,Mark__c,Grade__c from Results__r order by Component__r.Name) 
            FROM Enrolment__c
            WHERE Account__c in :accs.keySet() AND Module__c <> null
            ORDER BY Course__c,Contact__c
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Enrolment__c> getEnrolmentsByCriteria (String course, String status, String courseType, String branch) {
        system.debug('course='+course);
        system.debug('status='+status);
        system.debug('courseType='+courseType);
        User portalUser = [Select Id,AccountId from User where Id = :UserInfo.getUserId()];
        Map<Id,Account> accs = new Map<Id,Account>([Select Id from Account where Id = :portalUser.AccountId OR ParentId = :portalUser.AccountId]);
        
        String query = 'SELECT Id,Account__r.Name,Account__r.Membership_Number__c,Account__r.ShippingPostalCode,'+
            'Contact__r.Name,Course__c,Expected_Progress__c,'+
            'Module__c,Module__r.Name,Module_Mark__c,Course_Type__c,'+
            'Grade__c,Registered_Date__c,Status__c,Supervisor__r.Name,'+
            'On_Track__c,Expected_Completion_Date__c,Portal_Link__c,'+
            '(select Id,Component__r.Name,Mark__c,Grade__c from Results__r order by Component__r.Name) '+
            'FROM Enrolment__c '+
            'WHERE Account__c in (\'' + string.join(accs.keySet(),'\',\'') + '\') AND Module__c <> null';

        if(String.isNotBlank(course) && course != 'All'){
            query += ' AND Course__c = \'' + course + '\'';
        }
        if(String.isNotBlank(status) && status != 'All'){
            query += ' AND Status__c = \'' + status + '\'';
        }
        if(String.isNotBlank(courseType) && courseType != 'All'){
            query += ' AND Course_Type__c = \'' + courseType + '\'';
        }
        if(String.isNotBlank(branch) && branch != 'All'){
            query += ' AND Account__r.Membership_Number__c = \'' + branch + '\'';
        }
        
        query += ' ORDER BY Course__c,Contact__c';
        
        system.debug('query='+query);
        List<Enrolment__c> enrolments = Database.query(query);
        
        system.debug('enrolments.size()='+enrolments.size());

        return enrolments;
    }
}