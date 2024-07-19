/**
 * Created by jay on 08/07/2024.
 */

public without sharing class GlobalPayEnrolmentUpdate {
    @AuraEnabled
    public static void updateEnrolments(List<String> enrolmentNames, String status, String paymentStatus, String paymentReference) {
        List<Enrolment__c> enrolmentsToUpdate = new List<Enrolment__c>();

        List<Enrolment__c> enrolments = [SELECT Id, Name, Contact__r.Name, Contact__r.Email, Status__c, Payment_Status__c, EnrolmentFlowGUID__c FROM Enrolment__c WHERE EnrolmentFlowGUID__c IN :enrolmentNames];

        for (Enrolment__c enrolment : enrolments) {
            enrolment.Status__c = status;
            enrolment.Payment_Status__c = paymentStatus;
            enrolment.Payment_Ref_No__c = paymentReference;
            enrolmentsToUpdate.add(enrolment);
        }
        System.debug('enrolmentsToUpdate :::: ' + enrolmentsToUpdate);
        upsert enrolmentsToUpdate;
    }
}