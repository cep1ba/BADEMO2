public class LWCEnrolmentBulk {
    //LWCEnrolmentBulk.loadFile('001Pt00000C09NpIAJ');
    //FirstName - 40
    //Email - 80
    //LastName - 80
    //MemberNo - 10
    //Member - 255
    //Street - 255
    //City - 40
    //PostCode - 20
    
/*
Course name
Blended or Online?
Branch Membership Number
Pharmacy Name
Pharmacy Postcode
Student title
Student Forename
Student Surname
D.O.B
Student Email
Student Contact number
Supervisor title
Supervisor Forename
Supervisor Surname
Supervisor Email
Supervisor Contact number
GPhC No
*/
    
    @AuraEnabled
    public static String loadFile(String accId) {
        Integer errorCount = 0;
        
        List<ContentDocumentLink> cdl = [
            SELECT ContentDocumentId FROM ContentDocumentLink
            WHERE LinkedEntityId = :accId AND ContentDocument.FileType = 'CSV' AND ContentDocument.Title like '%enrolment%'
            ORDER BY SystemModstamp DESC
        ];
        
        if(cdl.isEmpty()){
            return 'There are no Enrolment CSV files for this account';
        }
        
        ContentDocument cd = [SELECT ParentId,FileExtension,FileType,Id,Title FROM ContentDocument WHERE filetype='CSV' AND Id = :cdl[0].ContentDocumentId];
        ContentVersion cv = [SELECT ContentBodyId,ContentDocumentId,FileType,Id,Title,VersionData FROM ContentVersion WHERE ContentDocumentId = :cdl[0].ContentDocumentId];
        Blob csvFileBlob = cv.VersionData;
        String csvFileString = csvFileBlob.toString();
        csvFileString = cleanData(csvFileString);
        List<String> csvFileLines = csvFileString.split('\n');
        List<String> fieldNames = new List<String>();
        List<String> ignoreFieldNames = new List<String>{'Pharmacy_Name__c','Pharmacy_Postcode__c','GPhC_No__c','Blended_or_Online__c'};
        List<String> fieldValues = new List<String>();
        List<EnrolmentBulk__c> enrolmentBulkList = new List<EnrolmentBulk__c>();
        Integer i=0;
        Integer lineCount=0;
        
        for (String value : csvFileLines[0].split(',')){
            if(String.isNotBlank(value)){
                fieldNames.add(value.replace('.','').replace('?','').replace(' ','_').trim()+'__c');
            }
        }
        string allFieldNames = string.join(fieldNames,',');
        system.debug('fieldNames='+allFieldNames);
        
        if(allFieldNames != 'Course_name__c,Blended_or_Online__c,Branch_Membership_Number__c,Pharmacy_Name__c,Pharmacy_Postcode__c,Student_title__c,Student_Forename__c,Student_Surname__c,DOB__c,Student_Email__c,Student_Contact_number__c,Supervisor_title__c,Supervisor_Forename__c,Supervisor_Surname__c,Supervisor_Email__c,Supervisor_Contact_number__c,GPhC_No__c'){
            String errMsg = 'CSV in incorrect format. Column headers must be: Course name, '+
                'Blended or Online?, Branch Membership Number, Pharmacy Name, '+
                'Pharmacy Postcode, Student title, Student Forename, '+
                'Student Surname, D.O.B, Student Email, '+
                'Student Contact number, Supervisor title, '+
                'Supervisor Forename, Supervisor Surname\nSupervisor Email, '+
                'Supervisor Contact number, GPhC No';
                
            throw new AuraHandledException(errMsg );
        }
        
        try{
            for (String line : csvFileLines){
                if(lineCount > 0){
                    EnrolmentBulk__c eb = new EnrolmentBulk__c ();
                    i=0;
                    fieldValues = line.split(',');
                    for (i = 0; i < fieldNames.size(); i++){
                        if(!ignoreFieldNames.contains(fieldNames[i])){
                            eb.put(fieldNames[i],fieldValues[i]);
                        }
                    }
                    enrolmentBulkList.add(eb);
                }
                lineCount++;
            }
            system.debug('enrolmentBulkList[0]='+enrolmentBulkList[0]);
            if(!enrolmentBulkList.isEmpty()){
                insert enrolmentBulkList;
                errorCount = createEnrolments (enrolmentBulkList);
            }
        }
        catch(Exception e) {
            throw new AuraHandledException('Something went wrong: ' + e.getMessage() + '/n'+e.getStackTraceString());
        }
        
        if (errorCount > 0){
            return 'There were ' + errorCount + ' errors out of ' + enrolmentBulkList.size() + ' rows in the CSV. Check the Enrolments Bulk tab for errors.';
        }
        
        return 'Success: ' + enrolmentBulkList.size() + ' student enrolments loaded';
    }
    
    private static Integer createEnrolments(List<EnrolmentBulk__c> enrolmentBulkList) {
        List<String> membershipNumbers = new List<String>();
        Map<String,String> membershipNumberMap = new Map<String,String>();
        Map<String,Id> contactMap = new Map<String,Id>();
        Map<String,Contact> newContactMap = new Map<String,Contact>();
        List<Enrolment__c> newEnrolments = new List<Enrolment__c>();
        Map <String,Set<Id>> moduleMap = new Map <String,Set<Id>>();
        Set <String> studentIdentifiers = new Set <String>();
        Set <String> supervisorIdentifiers = new Set <String>();
        Map<String, Contact> existingContactMap = new Map<String, Contact>();
        Map<String, Enrolment__c> existingEnrolmentMap = new Map<String, Enrolment__c>();
        Set<String> validCourseNames = new Set<String> ();
        Integer errorCount = 0;
        Id studentRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId();
        Id contactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        
        enrolmentBulkList =[
            SELECT Id,Student_title__c,Student_Forename__c,Student_Surname__c,Student_Email__c,Supervisor_Identifier__c,
            Supervisor_title__c,Supervisor_Forename__c,Supervisor_Surname__c,Supervisor_Email__c,
            Branch_Membership_Number__c,Unique_Identifier__c,Course_Name__c FROM EnrolmentBulk__c
            WHERE Error__c = '' and CreatedDate = TODAY
        ];
        
        for (EnrolmentBulk__c eb : enrolmentBulkList){
            if(String.isNotBlank(eb.Branch_Membership_Number__c)){
                membershipNumbers.add(eb.Branch_Membership_Number__c);
                studentIdentifiers.add(eb.Unique_Identifier__c);
                supervisorIdentifiers.add(eb.Supervisor_Identifier__c);
            }
        }
        
        //Get Account Ids
        List <Account> accs = [SELECT Id,Membership_Number__c FROM Account WHERE Membership_Number__c in :membershipNumbers];
        for (Account a : accs){
            membershipNumberMap.put(a.Membership_Number__c ,a.Id);
        }
        
        //Check for existing Students & Supervisors on the related Account
        for (Contact c : [SELECT Id, Unique_Identifier__c FROM Contact WHERE Unique_Identifier__c in :studentIdentifiers OR Unique_Identifier__c in :supervisorIdentifiers]){
            existingContactMap.put(c.Unique_Identifier__c, c); 
        }
        
        //Upsert Contacts      
        for (EnrolmentBulk__c eb : enrolmentBulkList){
            if(membershipNumberMap.get(eb.Branch_Membership_Number__c) == null){
                eb.Error__c = eb.Branch_Membership_Number__c + ' not found';
                errorCount += 1;
            }
            else if(String.isBlank(eb.Student_Email__c)){
                eb.Error__c = 'Email is required';
                errorCount += 1;
            }
            else if(String.isBlank(eb.Student_Surname__c)){
                eb.Error__c = 'Lastname/Surname is required';
                errorCount += 1;
            }
            else{
                if(existingContactMap.get(eb.Unique_Identifier__c) == null){
                    Contact c = new Contact (
                        RecordTypeId = studentRecTypeId,
                        Type__c = 'Student',
                        Salutation = checkTitle(eb.Student_title__c),
                        FirstName = checkField(eb.Student_Forename__c,80),
                        LastName = checkField(eb.Student_Surname__c,80),
                        email = checkField(eb.Student_Email__c,80),
                        AccountId = membershipNumberMap.get(eb.Branch_Membership_Number__c )
                    );
                    newContactMap.put(eb.Student_Surname__c.toLowerCase() + '-' + eb.Student_Email__c.toLowerCase() + '-' + eb.Branch_Membership_Number__c,c);
                    studentIdentifiers.add(eb.Student_Surname__c.toLowerCase() + '-' + eb.Student_Email__c.toLowerCase() + '-' + eb.Branch_Membership_Number__c);
                }
                if(existingContactMap.get(eb.Supervisor_Identifier__c) == null && String.isNotBlank(eb.Supervisor_Surname__c)  && String.isNotBlank(eb.Supervisor_Email__c)){
                    Contact c = new Contact (
                        RecordTypeId = contactRecTypeId,
                        Type__c = 'Supervising Pharmacist',
                        Salutation = checkTitle(eb.Supervisor_title__c),
                        FirstName = checkField(eb.Supervisor_Forename__c,80),
                        LastName = checkField(eb.Supervisor_Surname__c,80),
                        email = checkField(eb.Supervisor_Email__c,80),
                        AccountId = membershipNumberMap.get(eb.Branch_Membership_Number__c )
                    );
                    newContactMap.put(eb.Supervisor_Surname__c.toLowerCase() + '-' + eb.Supervisor_Email__c.toLowerCase() + '-' + eb.Branch_Membership_Number__c,c);
                    supervisorIdentifiers.add(eb.Supervisor_Surname__c.toLowerCase() + '-' + eb.Supervisor_Email__c.toLowerCase() + '-' + eb.Branch_Membership_Number__c);
                }
            }
        }
        
        if(!newContactMap.isEmpty()){ insert newContactMap.values(); }
             
        for (Contact c : [SELECT Id, Unique_Identifier__c FROM Contact 
            WHERE Unique_Identifier__c in :existingContactMap.keySet() OR Unique_Identifier__c in :supervisorIdentifiers]
        ){
            contactMap.put(c.Unique_Identifier__c,c.Id);
        }
        system.debug('contactMap='+contactMap);
        
        for (Enrolment__c e : [SELECT Id, Contact__c, Module__c,Is_Closed__c FROM Enrolment__c where Contact__c in :contactMap.values()]){
            system.debug(e.Contact__c + '-' + e.Module__c + '-' + e.Is_Closed__c);
            existingEnrolmentMap.put(e.Contact__c + '-' + e.Module__c + '-' + e.Is_Closed__c,e);
        }
        
        //Get Modules and Course Names
        for (Module__c m : [SELECT Id, Course__r.Name from Module__c]){
            if(moduleMap.get(m.Course__r.Name) == null){
                moduleMap.put(m.Course__r.Name, new Set<Id>());
            }
            moduleMap.get(m.Course__r.Name).add(m.Id);
            validCourseNames.add(m.Course__r.Name);
        }
        
        //Create Enrolments if they don't exist already
        for (EnrolmentBulk__c eb : enrolmentBulkList){
            if(!validCourseNames.contains(eb.Course_name__c)){
                eb.Error__c = 'Course not found';
                errorCount += 1;
            }
            else{
                for (Id moduleId : moduleMap.get(eb.Course_Name__c)){
                    system.debug(contactMap.get(eb.Unique_Identifier__c) + '-' + moduleId + '-' + false);
                    if(existingEnrolmentMap.get(contactMap.get(eb.Unique_Identifier__c) + '-' + moduleId + '-' + false) == null){
                        if(contactMap.get(eb.Unique_Identifier__c) != null){
                            Enrolment__c e = new Enrolment__c (
                                Contact__c = contactMap.get(eb.Unique_Identifier__c),
                                Module__c = moduleId,
                                Status__c = 'Draft'
                            );
                            if(contactMap.get(eb.Supervisor_Identifier__c) != null){
                                e.Supervisor__c = contactMap.get(eb.Supervisor_Identifier__c);
                            }
                            newEnrolments.add(e);
                        }
                    }
                }
            }
        }
        system.debug('newEnrolments='+newEnrolments);
        update enrolmentBulkList;
        insert newEnrolments;
        delete [SELECT Id FROM EnrolmentBulk__c WHERE Error__c = '' and CreatedDate = TODAY];
        
        return errorCount;
    }
    
    private static String checkField (String fieldValue,Integer maxLength){
        if(fieldValue != null && fieldValue.length() > maxLength){
            fieldValue = fieldValue.substring(0, maxLength);
        }
        return fieldValue;
    }
    
    private static String checkTitle (String fieldValue){
        List<String> allowedTitles = new List<String>{'Mr.','Ms.','Mrs.','Dr.','Prof.'};
        if(allowedTitles.contains(fieldValue)){
            return fieldValue;
        }
        return '';
    }
    
    private static String cleanData (String csvLine) {
        String prevLine = csvLine;
        Integer startIndex;
        Integer endIndex;
        
        while(csvLine.indexOf('"') > -1){
            if(startIndex == null){
                startIndex = csvLine.indexOf('"');
                csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex+1, csvLine.length());
            }else{
                if(endIndex == null){
                    endIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex+1, csvLine.length());
                }
            }
            
            if(startIndex != null && endIndex != null){
                String sub = csvLine.substring(startIndex, endIndex);
                sub = sub.replaceAll(',', ':comma:');
                csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                startIndex = null;
                endIndex = null;
            }
        }
        csvLine = csvLine.replaceAll(':quotes:', '').replaceAll(':comma:', ';');
        
        return csvLine;
    }
}