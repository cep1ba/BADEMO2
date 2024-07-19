/******************************************************************************
* Author: BA Westbrook
* Date: 11/06/2024
* Descpription: Export Welcome Packs as CSV
* Student Number,Title,Forenames,Surname,Member,Address1,Address2,Address3,Town,County,PostCode,AssessorTitle,AssessorForenames
   AssessorSurname,AssessorAddress1,AssessorAddress2,AssessorAddress3,AssessorTown,AssessorCounty,AssessorPostCode,Region,Member_No
*/

public with sharing class LWCExportWelcomePacks {
    @AuraEnabled(Cacheable = true)
    public static List<Enrolment__c> getEnrolments(){
        Map<String,Enrolment__c> enrolmentMap = new Map<String,Enrolment__c> ();
        List <Enrolment__c> enrolments =  [SELECT 
            Id, Module__r.Course__r.Code__c, Contact__r.Student_Number__c,
            Contact__r.Salutation,Contact__r.FirstName,Contact__r.LastName,Contact__r.Email,
            Contact__r.MailingStreet,Contact__r.MailingCity,Contact__r.MailingPostalCode,Contact__r.MailingCountry,
            Supervisor__r.FirstName,Supervisor__r.LastName,Supervisor__r.Email,
            Supervisor__r.MailingStreet,Supervisor__r.MailingCity,Supervisor__r.MailingPostalCode,
            Assessor_Title__c,Assessor_First_Name__c,Assessor_Last_Name__c,
            Assessor_Street__c,Assessor_Town__c,Assessor_County__c,Assessor_Postcode__c,
            Account__r.Name,Account__r.Membership_Number__c
            FROM Enrolment__c
            WHERE Welcome_Pack_Sent__c = false
            AND Primary__c = true
            AND Status__c in ('Accepted')
            ORDER BY Module__r.Course__r.Code__c,Account__r.Membership_Number__c,Contact__r.LastName LIMIT 200
        ];
              
        for (Enrolment__c e : enrolments){
            enrolmentMap.put(e.Contact__r.FirstName + e.Contact__r.LastName + e.Contact__r.Email + e.Module__r.Course__r.Code__c + e.Account__c,e);
        }
        
      return enrolments;
    }
    
    @AuraEnabled
    public static String setSentFlags(List<String> enrolmentIds){
        system.debug(enrolmentIds);
        Map<String,Enrolment__c> enrolmentMap = new Map<String,Enrolment__c> ();

        List <Enrolment__c> enrolments =  [SELECT Id FROM Enrolment__c WHERE Id in :enrolmentIds OR Parent__c in :enrolmentIds];
        system.debug(enrolments );
        for (Enrolment__c e : enrolments){
            e.Welcome_Pack_Sent__c = true;
        }
        
        update enrolments;
        
        return 'Success';
    }
}