/**
* Created/Modified By: Girikon(Keertiraj), 
* Created On:          19/10/2021
* Modified By :  [Aishwarya Kumar IMCC-3840,IMCC-3841],Girikon(Garima IMCC-4369),[Aishwarya Kumar IMCC-4936 16 Dec 2022]
* Modified On : 16/08/2022
* @description : This class is used to send welcome emails when send welcome email on edition is clicked, When Send Welcome Email button is clicked on CEM.                   
* Test Class: IMCC_EditionWelcomeEmailTest(94%)
*/
public without sharing class IMCC_EditionWelcomeEmail {

    /**
    * @description  send Welcome Email To User
    * @param  cemList
    * @return  List<Contact_Edition_Mapping__c>
    */
    @AuraEnabled
    public static List<Contact_Edition_Mapping__c> sendWelcomeEmail(List<Contact_Edition_Mapping__c> cemList){
        Integer batchBreakpoint = (Test.isRunningTest()?(25):(50)); // Sending the emails in batch size of 50 if records are more than 50
        if(cemList.size() <= batchBreakpoint){
            processWelcomeEmail(cemList, true);
        }
        else{
            Set<Id> cemIds = new Set<Id>();
            for(Contact_Edition_Mapping__c cem : cemList){
                cemIds.add(cem.Id);
            }

            List<Contact_Edition_Mapping__c> cems = [SELECT Id, Role__c, Edition__c FROM Contact_Edition_Mapping__c WHERE Id IN:cemIds WITH SECURITY_ENFORCED];

            IMCC_SendWelcomeEmailBatch batch = new IMCC_SendWelcomeEmailBatch(cems,true);
            Id jobId = Database.executeBatch(batch,50);

            update new Edition__c(Id=cems[0].Edition__c,Welcome_Email_Job_Id__c=jobId,Welcome_Email_Job_Status__c='In Progress');
        }
        Set<Id> setIds = new Set<Id>();
        for(Contact_Edition_Mapping__c cem : cemList){
            setIds.add(cem.Id);
        }
        return [SELECT Id,IsEmailSent__c,Error_Message__c,Edition__r.Welcome_Email_Job_Id__c FROM Contact_Edition_Mapping__c WHERE Id IN:setIds];
    }

    /**
    * @description  process Welcome Emails
    * @param  cemList
    * @param  isManual
    */
    public static void processWelcomeEmail(List<Contact_Edition_Mapping__c> cemList, Boolean isManual){
        Set<Id> conIds = new Set<Id>(); 
        Set<Id> duplicateUserConLst = new Set<Id>();
        Set<Id> newUserConIds = new Set<Id>(); 
        Set<Id> cemIds = new Set<Id>();
        Set<Id> cemIdsForEmail = new Set<Id>();
        List<User> commUserLst = new List<User>();
        list<contact> newUsercontactList = new list<contact>();
        List<Contact_Edition_Mapping__c> listConEdMap = new List<Contact_Edition_Mapping__c>();
        List<Contact_Edition_Mapping__c> oldUserConEvnMap = new List<Contact_Edition_Mapping__c>();
        List<Contact_Edition_Mapping__c> newUserConEvnMap = new List<Contact_Edition_Mapping__c>();
        boolean bypass = true;

        List<Contact_Edition_Mapping__c> listCEMUpdate = new List<Contact_Edition_Mapping__c>();
        Map<String,Contact_Edition_Mapping__c> mapConIdCEM = new Map<String,Contact_Edition_Mapping__c>();
        for(Contact_Edition_Mapping__c cem : cemList){
            cemIds.add(cem.Id);
            listCEMUpdate.add(new Contact_Edition_Mapping__c(Id=cem.Id,IsEmailSent__c=false));
        }
        if(!listCEMUpdate.isEmpty() && (Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable() || bypass)){
            update listCEMUpdate;
        }

        try{
            if(!cemIds.isEmpty()){
                String strQuery = 'SELECT Id, Account__c, Contact__c, Contact__r.Email,Contact__r.AccountId, Edition__c, CC_Status__c, Relationship_Status__c, Access_Type__c,Role__c FROM Contact_Edition_Mapping__c where Id IN :cemIds AND (CC_Status__c = \'Active\' OR CC_Status__c = \'In Progress\')';
                if(!isManual){
                    strQuery += ' AND Edition__r.Send_Welcome_email__c = true';
                }
                List<Contact_Edition_Mapping__c> listConEdMap2 = Database.query(strQuery);
                listCEMUpdate = new List<Contact_Edition_Mapping__c>();
                for(Contact_Edition_Mapping__c cem : listConEdMap2){
                    if(String.isBlank(cem.Contact__r.Email)){
                        listCEMUpdate.add(new Contact_Edition_Mapping__c(Id=cem.Id,Error_Message__c=System.Label.IMCC_Welcome_Email_Error_Msg1)); // Using labels for displaying/populating(error message field on CEM) the error message on screen duirng sending welcome email
                    }
                    else if(String.isBlank(cem.Contact__r.AccountId)){
                        listCEMUpdate.add(new Contact_Edition_Mapping__c(Id=cem.Id,Error_Message__c=System.Label.IMCC_Welcome_Email_Error_Msg2)); // Using labels for displaying/populating(error message field on CEM) the error message on screen duirng sending welcome email
                    }
                    else if(cem.Relationship_Status__c != 'Active'){
                        listCEMUpdate.add(new Contact_Edition_Mapping__c(Id=cem.Id,Error_Message__c=System.Label.IMCC_Welcome_Email_Error_Msg6)); // Using labels for displaying/populating(error message field on CEM) the error message on screen duirng sending welcome email
                    }
                    else if(String.isBlank(cem.Access_Type__c)){
                        listCEMUpdate.add(new Contact_Edition_Mapping__c(Id=cem.Id,Error_Message__c=System.Label.IMCC_Welcome_Email_Error_Msg5)); // Using labels for displaying/populating(error message field on CEM) the error message on screen duirng sending welcome email
                    }
                    else{
                        conIds.add(cem.Contact__c);
                        listConEdMap.add(cem);
                        mapConIdCEM.put(cem.Contact__c,cem);
                    }
                }
            }   

            if(!conIds.isEmpty() && (Schema.sObjectType.User.isAccessible() || bypass)){
                for(User usr : [SELECT Id, ContactId FROM User WHERE ContactId IN:conIds]){
                    duplicateUserConLst.add(usr.contactid);// Creating Set of contacts for which users are alredy created (Duplicate Contacts)
                }
            }

            for(Contact_Edition_Mapping__c cem : listConEdMap){
                if(!newUserConIds.contains(cem.Contact__c) && !duplicateUserConLst.contains(cem.Contact__c)){  
                    newUserConIds.add(cem.Contact__c);//Creating set of contacts for which user is not created (valid Contacts) 
                }
                if(duplicateUserConLst.contains(cem.Contact__c)){  
                    oldUserConEvnMap.add(cem);
                    cemIdsForEmail.add(cem.Id);
                }
                else{
                    newUserConEvnMap.add(cem);
                }
            }
            
            if(!newUserConIds.isEmpty() && Schema.sObjectType.Contact.isAccessible()){
                newUsercontactList = [SELECT Id, LastName, FirstName, AccountId, Account.Name, Email FROM Contact where Id IN:newUserConIds];
            }
            
            Id communityProfileId = IMCC_UtilityMethods.getCommProfile();
            if(!newUsercontactList.isEmpty()){
                commUserLst = IMCC_UtilityMethods.prepareCommunityUser(communityProfileId, newUsercontactList);
            }

            List<Id> listNewUserContacts = new List<Id>();
            List<Id> newUserIds = new List<Id>();
            if(!commUserLst.isEmpty()){
                Database.SaveResult[] listSaveRes = Database.insert(commUserLst, false);
                Integer index = -1;
                for(Database.SaveResult saveRes : listSaveRes){
                    index++;
                    if(saveRes.isSuccess()){
                        newUserIds.add(saveRes.getId());
                    }
                    else{
                        String conId = commUserLst[index].ContactId;
                        String errorMsg = '';
                        for(Database.Error err : saveRes.getErrors()){
                            errorMsg += err.getMessage();
                        }
                        listCEMUpdate.add(new Contact_Edition_Mapping__c(Id=mapConIdCEM.get(conId).Id, Error_Message__c=errorMsg, Role__c = 'Team Member'));
                    }
                }

                for(User usr : [SELECT Id, ContactId FROM User WHERE Id IN:newUserIds]){
                    listNewUserContacts.add(usr.contactid);// Creating Set of contacts for which users are created
                }
                for(Contact_Edition_Mapping__c cem : newUserConEvnMap){
                    if(listNewUserContacts.contains(cem.Contact__c)){
                        cemIdsForEmail.add(cem.Id);
                    }
                }
            }

            if(!listCEMUpdate.isEmpty() && (Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable() || bypass)){
                update listCEMUpdate;
            }
            
            if(!cemIdsForEmail.isEmpty()){
                IMCC_UtilityMethod_Handler.sendEmailToExistingUser(cemIdsForEmail);
            }
        }
        catch (Exception ex) {
            listCEMUpdate = new List<Contact_Edition_Mapping__c>();
            for(Contact_Edition_Mapping__c cem : cemList){
                listCEMUpdate.add(new Contact_Edition_Mapping__c(Id=cem.Id,Error_Message__c=ex.getMessage()));
            }
            if(!listCEMUpdate.isEmpty() && (Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable() || bypass)){
                update listCEMUpdate;
            }
        }
    }
    
    /**
    * @description  get Contact Edition Mappings
    * @param  editionId
    * @param  searchKey
    * @param  sortBy
    * @param  sortDirection
    * @param  eventLogger
    * @param  eventReceiver
    * @return  List<Contact_Edition_Mapping__c>
    */
    @AuraEnabled
    public static List<Contact_Edition_Mapping__c> getContactEditionMappings(Id editionId,String searchKey,String sortBy,String sortDirection,String eventLogger, String eventReceiver){
        if(sortBy == 'ContactName'){
            sortBy = 'Contact__r.Name';
        }
        else if(sortBy == 'AccountName'){
            sortBy = 'Account__r.Name';
        }
        else if(sortBy == 'ContactEmail'){
            sortBy = 'Contact_Email__c';
        }
        else if(sortBy == 'IsEmailSent'){
            sortBy = 'IsEmailSent__c';
        }
        else  if(sortBy == 'EmailSentDate'){
            sortBy = 'Email_Sent__c';
        }
        else if(sortBy == 'UserType'){
            sortBy = 'Access_Type__c';
        }
        else if(sortBy == 'FirstLoginDateTime'){
            sortBy = 'First_Login_Date_Time__c'; //IMCC-4936
        }

        String query = '';
        try{
            if(editionId!=null && Schema.sObjectType.Contact_Edition_Mapping__c.isAccessible()){
                query = 'SELECT Id, Account__c,Account__r.Name,Contact__c, Contact__r.Name,Contact_Email__c,IsEmailSent__c, Email_Sent__c, Edition__c, CC_Status__c, Relationship_Status__c, Access_Type__c, First_Login_Date_Time__c FROM Contact_Edition_Mapping__c where Edition__c =:editionId AND Access_Type__c!= null AND Relationship_Status__c = \'Active\' AND CC_Status__c = \'Active\'';             
                if(searchKey != null && searchKey != ''){
                    String key = '%' + searchKey + '%';
                    System.debug(LoggingLevel.DEBUG, key);
                    query += ' AND ((Contact__r.Name LIKE :key) OR (Account__r.Name LIKE :key) OR (Contact_Email__c LIKE :key))';
                }
                if(String.isNotBlank(eventLogger) && eventLogger != 'All'){
                    query += ' AND First_Login_Date_Time__c' + (eventLogger=='Whologgedin'?'!=':'=') + ' NULL'; //IMCC-4936
                }
                if(String.isNotBlank(eventReceiver) && eventReceiver != 'All'){
                    query += ' AND IsEmailSent__c=' + (eventReceiver=='ReceivedEmail'?'true':'false');  //IMCC-4936
                }
                if ( sortBy != null && sortDirection != null ) {
                   string nullvaluessort = '';
                    if(sortDirection == 'asc'){
                        nullvaluessort = 'NULLS FIRST';                       
                    }
                    else{
                        nullvaluessort = 'NULLS LAST'; 
                    }
                    query += ' ORDER BY ' + String.escapeSingleQuotes(sortBy) + ' ' + String.escapeSingleQuotes(sortDirection) + ' ' + String.escapeSingleQuotes(nullvaluessort);
                }    
            }
        } 
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Edition__c', 'Edition Welcome Email');
        } 
        return Database.query( query );
    }
    
    /**
    * @description  check Send Welcome Email Status
    * @param  editionId
    * @return  Map<String,Object>
    */
    @AuraEnabled
    public static Map<String,Object> checkSendWelcomeEmailStatus(Id editionId){
        boolean isSendWelcomeEmail = false;
        boolean hasWelcomeEmailTemplate = false;
        List<Edition__c> editionRecs = new List<Edition__c>();
        
        try{
            if(editionId != null && Schema.sObjectType.Edition__c.isAccessible()){
                editionRecs = [SELECT Id, Name, Send_Welcome_email__c, Customer_Center_Status__c,Welcome_Email_Job_Id__c,Welcome_Email_Job_Status__c FROM Edition__c WHERE Id=:editionId LIMIT 1];
            }
            if(!editionRecs.isEmpty()){
                isSendWelcomeEmail = (editionRecs[0].Customer_Center_Status__c == 'Active');  
            }

            List<Event_Edition_Email_Template__c> listEEET = [SELECT Id FROM Event_Edition_Email_Template__c WHERE Template_Code__c LIKE'WELNew%' AND Edition__c=:editionId WITH SECURITY_ENFORCED];
            hasWelcomeEmailTemplate = (!listEEET.isEmpty());
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Edition__c', 'Edition Welcome Email');
        }

        return new Map<String,Object>{
            'editionRecs' => editionRecs,
            'hasWelcomeEmailTemplate' => hasWelcomeEmailTemplate
        };
    }
    
    /**
    * @description : this method will fetch apex jobs and will update status,JobItemsProcessed,NumberOfErrors,TotalJobItems
    * @param batchId batch Id
    * @return AsyncApexJob
    **/
    @AuraEnabled
    public static Map<String,Object> getJobs(String batchId) {
        AsyncApexJob apexJobs; // Added Query in for loop for Sales Profile Access [SFV-880]
        Boolean isAccess = true;
        if(Schema.sObjectType.AsyncApexJob.isAccessible() || isAccess){
            List<AsyncApexJob> jobs = [SELECT TotalJobItems, Status, NumberOfErrors, ExtendedStatus, JobItemsProcessed, Id, JobType, ApexClassId, CreatedDate FROM AsyncApexJob WHERE Id=:batchId];
            apexJobs = (jobs.isEmpty()?null:jobs.get(0));
        }
        List<Contact_Edition_Mapping__c> listCEM = [SELECT Id,IsEmailSent__c,Error_Message__c,Edition__r.Welcome_Email_Job_Id__c FROM Contact_Edition_Mapping__c WHERE Welcome_Email_Job_Id__c=:apexJobs.Id];
        return new Map<String,Object>{
            'apexJobs' => apexJobs,
            'listCEM' => listCEM
        };
    } 
}