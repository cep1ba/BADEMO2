public with sharing class BatchSendEmail implements Database.Batchable<SObject>, Database.Stateful {
/*
Given that a student is on a long term course (i.e. MCA, ADAC, MCDC, ACT/AID, ACD) 
When the system generates the warm letter to be sent to the student at the beginning of the month 2 of the course
Then the email contains the student name, student number, the course, the welcome message, and any other onboarding information.
BatchSendEmail batchJob = new BatchSendEmail ();
Id batchJobId = Database.executeBatch(batchJob, 200);
*/   
    public Database.QueryLocator start(Database.BatchableContext context){
        //System.Label.MyLabelName
        String query = 'SELECT Id,Supervisor__c,Contact__c,Contact__r.Email,Course__c, Months_from_Start__c, Emails_Sent__c FROM Enrolment__c ' +
                           'WHERE Id=\'a0lPt000001Bc2zIAC\' AND Contact__r.Email <> null AND Course__c in (\'MCA\', \'ADAC\', \'MCDC\', \'ACT\', \'AID\', \'ACD\')' +
                           ' AND Months_from_Start__c in (1,3,6,9,12,14,18,20)' +
                           ' AND Is_Closed__c = false AND CreatedDate = LAST_N_DAYS:730';
        return Database.getQueryLocator(query);
    }
    
    public void execute (Database.BatchableContext context, List <sObject> scope){
        List<Enrolment__c> enrolments = (List<Enrolment__c>)scope;
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        Map <String,String> ruleMap = new Map <String,String>();
        Map <String,Id> templateMap = new Map <String,String>();
        
        //Populate map of Reminder Emails
        for (Student_Reminder_Email__mdt  re : [SELECT MasterLabel, Course_Code__c, Month__c, Identifier__c FROM Student_Reminder_Email__mdt]){
            ruleMap.put(re.Identifier__c , re.MasterLabel);
        }
        
        system.debug('ruleMap.size()'+templateMap.size());
        
        //Populate map of Lightning templates
        for (EmailTemplate et : [SELECT Id,Name FROM EmailTemplate WHERE Name in :ruleMap.values()]){
            templateMap.put(et.Name, et.Id);
        }
        
        system.debug('templateMap.size()'+templateMap.size());
        
        String emailTemplateName = 'Chase up - email 1 warm letter - MCDC';
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE Name=:emailTemplateName];
        
        for(Enrolment__c e : enrolments){
            //Does a rule exist exist for this Enrolment at this time?
            if(ruleMap.get(e.Course__c + '-' + e.Months_from_Start__c) != null){
                String emailTemplate = ruleMap.get(e.Course__c + '-' + e.Months_from_Start__c);
                System.debug('emailTemplate='+emailTemplate);
                
                //Check if email has been sent already
                if(String.isBlank(e.Emails_Sent__c) || !e.Emails_Sent__c.containsIgnoreCase(emailTemplate)){
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new List<String>{e.Contact__r.Email});
                    //email.setSenderDisplayName(emailTemplate.Subject); 
                    Messaging.SingleEmailMessage renderedEmail = Messaging.renderStoredEmailTemplate(templateMap.get(emailTemplate), e.Supervisor__c, e.Id);
                    email.setHtmlBody(renderedEmail.getHtmlBody());
                    email.setPlainTextBody(renderedEmail.getPlainTextBody());
                    email.setSubject(renderedEmail.getSubject());
                    
                    email.setTargetObjectId(e.Supervisor__c);
                    email.setWhatId(e.Id);
                    //email.setCcAddresses(new List<String>{UserInfo.getUserEmail()});
                    email.setSaveAsActivity(false);
                    email.setUseSignature(false);
                    emailsToSend.add(email);
                    e.Emails_Sent__c = emailTemplate +';';
                }
            }
        }

        if(emailsToSend.size() > 0){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend);
            if (results[0].success) {
                System.debug('success');
                update enrolments;
            }
            else {
                System.debug('Error email failed to send: ' + results[0].errors[0].message);
            }
        }
    }
    
    public void finish(Database.BatchableContext context){
        // Perform any post-processing logic if needed
    }
    
    public void execute(SchedulableContext context){
        // Implement the scheduling logic here
            BatchSendEmail batchJob = new BatchSendEmail();
            Database.executeBatch(batchJob);
    }
}