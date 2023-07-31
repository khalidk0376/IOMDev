/**
* Created/Modified By :(Arushi)
* Created On:          3/03/2023 
* Last Modified By:    [Aishwarya IMCC-5102 3 Apr 2023, Arushi IMCC-5147 20 Apr 2023]
* @description  :      As a Customer, I should be able to invite my colleague(s) for an event set up in 
Customer Center portal so that they get full access to event related information
in the customer center portal.
* Methods:             getContact,matchedContact,contactToBeCreated,teamMemberList,cancelInvitation,reSendInvitation
* Test Class:          IMCC_ManageTeamMembersCEMTest
**/
public without sharing class IMCC_ManageTeamMembersCEM {
    
    @AuraEnabled
    public static list<Contact> getContact(String searchText)
    {
        string whereClause;
        if(String.isNotEmpty(searchText)){
            whereClause = String.escapeSingleQuotes(searchText);
        }
        List<Contact> conList = [SELECT Id,Name,AccountId,Email FROM Contact WHERE Email =:whereClause WITH SECURITY_ENFORCED];
        return conList;
    }
    
    @AuraEnabled
    public static void matchedContact(String contactId, String eventCode, String accountId, string role){   
        
        boolean isSecondaryAdminExist = false;
        Map<Id,Id> mapCEM = new Map<Id,Id>();
        List<Contact_Edition_Mapping__c> listCEM = new List<Contact_Edition_Mapping__c>();
        
        Edition__c ed =[SELECT Id FROM Edition__c WHERE Edition_Code__c=:eventCode WITH SECURITY_ENFORCED LIMIT 1];
        String editionId = ed.Id;
        List<Contact_Edition_Mapping__c> secondaryCEMMember = [SELECT Id,Relationship_Status__c, Primary_Contact_Edition_Mapping__c, isSecondary__c, Contact__c,Role__c,Feathr_Unique_Link__c FROM Contact_Edition_Mapping__c WHERE Contact__c=:contactId AND Account__c =:accountId AND Edition__r.Edition_Code__c=:eventCode WITH SECURITY_ENFORCED LIMIT 1];
        
        if(!secondaryCEMMember.isEmpty()){
            
            if(role == 'Secondary Admin'){
                List<Contact_Edition_Mapping__c> cemList = teamMemberList(eventCode, accountId);
                if(!cemList.isEmpty()){
                    for(Contact_Edition_Mapping__c cem : cemList){
                        if(cem.Role__c == 'Secondary Admin'){
                            isSecondaryAdminExist = true;
                        }
                    }
                }
            }
            
            if(secondaryCEMMember[0].Relationship_Status__c == 'Inactive' && Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable()){
                secondaryCEMMember[0].Relationship_Status__c = 'Active';
                secondaryCEMMember[0].Role__c = (isSecondaryAdminExist == true )?'Team Member':role;
                update secondaryCEMMember[0];
                //Remove comment by Mukesh [IMCC-5203, 5 May, 2023]
                IMCC_EditionWelcomeEmail.processWelcomeEmail(new Contact_Edition_Mapping__c[]{secondaryCEMMember[0]}, false);
            }
            else if(secondaryCEMMember[0].Role__c == null || secondaryCEMMember[0].Role__c== ''){
                secondaryCEMMember[0].Role__c = (isSecondaryAdminExist == true )?'Team Member':role;
                update secondaryCEMMember[0];
                //Remove comment by Mukesh [IMCC-5203, 5 May, 2023]
                IMCC_EditionWelcomeEmail.processWelcomeEmail(new Contact_Edition_Mapping__c[]{secondaryCEMMember[0]}, false);
            }            
        }
        else{
            List<Contact_Edition_Mapping__c> primaryCEM = (List<Contact_Edition_Mapping__c>)IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId).get('cemList');
            //system.debug('primaryCEM=='+primaryCEM);
            Contact_Edition_Mapping__c cEM = new Contact_Edition_Mapping__c();
            cEM.Account__c = accountId;
            cEM.Contact__c = contactId;
            cEM.Access_Type__c = !primaryCEM.isEmpty()?primaryCEM[0].Access_Type__c:'Exhibitor';
            cEM.Edition__c = editionId;
            cEM.Role__c = role;
            cEM.Relationship_Status__c = 'Active';
            cEM.isSecondary__c = true;
            if(!primaryCEM.isEmpty()){
                if(primaryCEM[0].isSecondary__c == true){
                    cEM.Primary_Contact_Edition_Mapping__c = primaryCEM[0].Primary_Contact_Edition_Mapping__c;
                    cEM.Feathr_Unique_Link__c = primaryCEM[0].Primary_Contact_Edition_Mapping__r.Feathr_Unique_Link__c;
                }
                else{
                    cEM.Primary_Contact_Edition_Mapping__c = primaryCEM[0].Id; 
                    cEM.Feathr_Unique_Link__c = primaryCEM[0].Feathr_Unique_Link__c;
                }
            }
            
            SObjectAccessDecision securityDecision1 = Security.stripInaccessible(AccessType.CREATABLE, new Contact_Edition_Mapping__c []{cEM});
            Insert securityDecision1.getRecords();
            
            string cEMId = securityDecision1.getRecords()[0].Id;
            List<Contact_Edition_Mapping__c> newCEM = [SELECT Id,Role__c, Account__c,Edition__c,Edition__r.Edition_Code__c
                                                       , Contact__c,IsEmailSent__c FROM Contact_Edition_Mapping__c WHERE Id =:cEMId WITH SECURITY_ENFORCED];
            //Remove comment by Mukesh [IMCC-5203, 5 May, 2023]
            //IMCC_EditionWelcomeEmail.processWelcomeEmail(newCEM, false);     
        }
    }
    
    @AuraEnabled
    public static void contactToBeCreated(String eventCode, String accountId, String emailId, string role, string firstName, string lastName){   
        
        try{
            List<Contact> existingContact = getContact(emailId);
            if(existingContact.isEmpty()){
                Edition__c ed =[SELECT Id FROM Edition__c WHERE Edition_Code__c=:eventCode WITH SECURITY_ENFORCED LIMIT 1];
                String editionId = ed.Id;
                
                Contact con = new Contact();
                con.FirstName = firstName;
                con.LastName = lastName;
                con.Email = emailId;
                con.AccountId = Id.valueOf(accountId);
                
                SObjectAccessDecision securityDecision1 = Security.stripInaccessible(AccessType.CREATABLE, new Contact []{con});
                Insert con;
                String conId = con.Id;
                
                List<Contact_Edition_Mapping__c> primaryCEM = (List<Contact_Edition_Mapping__c>)IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId).get('cemList');
                Contact_Edition_Mapping__c cEM = new Contact_Edition_Mapping__c();
                cEM.Account__c = accountId;
                cEM.Contact__c = conId;
                cEM.Access_Type__c = !primaryCEM.isEmpty()?primaryCEM[0].Access_Type__c:'Exhibitor';
                cEM.Edition__c = editionId;
                cEM.Role__c = role;
                cEM.Relationship_Status__c = 'Active';
                cEM.isSecondary__c = true;
                if(!primaryCEM.isEmpty()){
                    if(primaryCEM[0].isSecondary__c == true){
                        cEM.Primary_Contact_Edition_Mapping__c = primaryCEM[0].Primary_Contact_Edition_Mapping__c;
                        cEM.Feathr_Unique_Link__c = primaryCEM[0].Primary_Contact_Edition_Mapping__r.Feathr_Unique_Link__c;
                    }
                    else{
                        cEM.Primary_Contact_Edition_Mapping__c = primaryCEM[0].Id; 
                        cEM.Feathr_Unique_Link__c = primaryCEM[0].Feathr_Unique_Link__c;
                    }
                }
                
                SObjectAccessDecision securityDecision2 = Security.stripInaccessible(AccessType.CREATABLE, new Contact_Edition_Mapping__c []{cEM});
                Insert securityDecision2.getRecords();
                
                String cEMId = securityDecision2.getRecords()[0].Id;                                       
                List<Contact_Edition_Mapping__c> newCEM = [SELECT Id,Account__c,Edition__c,Edition__r.Edition_Code__c
                                                           , Contact__c,IsEmailSent__c FROM Contact_Edition_Mapping__c WHERE Id =:cEMId WITH SECURITY_ENFORCED];
                //IMCC_EditionWelcomeEmail.processWelcomeEmail(newCEM, false);                   
            }
            else{
                matchedContact(existingContact[0].Id,eventCode,accountId,role);
            }
        }
        catch(Exception ex){            
            throw new AuraHandledException(ex.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static List<Contact_Edition_Mapping__c> teamMemberList(String eventCode, String accountId){   
        List<Contact_Edition_Mapping__c> teamMemberList = [SELECT Id,Account__c,Edition__c,Edition__r.Edition_Code__c
                                                           , Contact__c,Contact__r.Name,Role__c, Email_Sent__c,First_Login_Date_Time__c, Contact_Email__c,Relationship_Status__c
                                                           ,Contact__r.Title,Contact__r.MobilePhone,Contact__r.Contact_Type__c,Contact__r.MailingCountry__c,isSecondary__c
                                                           FROM Contact_Edition_Mapping__c WHERE Account__c =:accountId AND Relationship_Status__c = 'Active'
                                                           AND Edition__r.Edition_Code__c=:eventCode AND (Role__c != null AND Role__c !='' )];
        return teamMemberList;        
    }
    
    @AuraEnabled
    public static void cancelInvitation(String cemId, String eventCode, String accountId){   
        Set<Id> cancelInvitedCEMIds = new Set<Id>();
        Contact_Edition_Mapping__c adminCEM = new Contact_Edition_Mapping__c();
        
        List<Contact_Edition_Mapping__c> teamMemberList = [SELECT Id,Relationship_Status__c
                                                           FROM Contact_Edition_Mapping__c WHERE Id =:cemId WITH SECURITY_ENFORCED];
        if(!teamMemberList.isEmpty() && Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable()){
            teamMemberList[0].Relationship_Status__c = 'Inactive';
            update teamMemberList;
        }
        for(Contact_Edition_Mapping__c cem : teamMemberList){
            if(cem.Relationship_Status__c == 'Inactive'){
                cancelInvitedCEMIds.add(cem.Id);
            }
        }
        
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
        adminCEM = (Contact_Edition_Mapping__c)mapCEMDetails.get('cem');

        
        if(!cancelInvitedCEMIds.isEmpty()){
            IMCC_WelcomeEmailNotification.adminNotification(cancelInvitedCEMIds, adminCEM,'CANCELINVITE');
            IMCC_WelcomeEmailNotification.teamMemberNotification(cancelInvitedCEMIds,'CANCELINVITETEAMMEM','','');
        }
    }
    
    @AuraEnabled
    public static void reSendInvitation(String cemId, String eventCode, String accountId){  
        
        Set<Id> resendInvitedCEMIds = new Set<Id>();
        Contact_Edition_Mapping__c adminCEM = new Contact_Edition_Mapping__c();
        
        List<Contact_Edition_Mapping__c> teamMemberList = [SELECT Id,Email_Sent__c,Error_Message__c,Contact__r.Name,Contact__c
                                                           FROM Contact_Edition_Mapping__c WHERE Id =:cemId WITH SECURITY_ENFORCED];
       
        IMCC_EditionWelcomeEmail.processWelcomeEmail(teamMemberList, false);     
        
        for(Contact_Edition_Mapping__c cem : [SELECT Id,Email_Sent__c,Error_Message__c
                                                           FROM Contact_Edition_Mapping__c WHERE Id =:cemId WITH SECURITY_ENFORCED]){
            if(cem.Error_Message__c == null){
                resendInvitedCEMIds.add(cem.Id);
            }
        }
        
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
        adminCEM = (Contact_Edition_Mapping__c)mapCEMDetails.get('cem');
        
        if(!resendInvitedCEMIds.isEmpty()){
            IMCC_WelcomeEmailNotification.adminNotification(resendInvitedCEMIds, adminCEM,'RESENTADMINNOTIFY');
        }
    }
    
    //IMCC-5102
    @AuraEnabled
    public static List<Contact_Edition_Mapping__c> checkPrimaryCEM(String cemId){   
        List<Contact_Edition_Mapping__c> primaryCEMList = new List<Contact_Edition_Mapping__c>([SELECT Id FROM Contact_Edition_Mapping__c WHERE Id =:cemId AND isSecondary__c = false AND Primary_Contact_Edition_Mapping__c = null AND Role__c='Team Member' WITH SECURITY_ENFORCED]);
        return primaryCEMList;
    }
    
    //IMCC-5102
    @AuraEnabled
    public static void cancelInvitationIfPrimary(String cemId, String eventCode, String accountId){   
        String loginUserCEmId ='';
        String loginUserCEmCon ='';
        Set<Id> cancelInvitedCEMIds = new Set<Id>();
        Contact_Edition_Mapping__c adminCEM = new Contact_Edition_Mapping__c();
        
        List<User> u =[SELECT Id,ContactId FROM User WHERE Id =:UserInfo.getUserId() ORDER BY CreatedDate DESC LIMIT 1];
        List<Contact_Edition_Mapping__c> loginUserCEMList;
        if(Test.isRunningTest()){
            loginUserCEMList = [SELECT Id,Contact__c,isSecondary__c,Primary_Contact_Edition_Mapping__c FROM Contact_Edition_Mapping__c WHERE Account__c =:accountId AND Relationship_Status__c = 'Active'  WITH SECURITY_ENFORCED LIMIT 1];
        }
        else{
            loginUserCEMList = [SELECT Id,Contact__c,isSecondary__c,Primary_Contact_Edition_Mapping__c FROM Contact_Edition_Mapping__c WHERE Contact__c=:u[0].ContactId AND Account__c =:accountId AND Relationship_Status__c = 'Active' AND Edition__r.Edition_Code__c=:eventCode WITH SECURITY_ENFORCED LIMIT 1];
        }
        
        if(!loginUserCEMList.isEmpty()){
            loginUserCEmId = loginUserCEMList[0].id;
            loginUserCEmCon = loginUserCEMList[0].Contact__c;
            loginUserCEMList[0].isSecondary__c = false;
            loginUserCEMList[0].Primary_Contact_Edition_Mapping__c = null;
            //loginUserCEMList[0].Role__c = 'Team Member';
            update loginUserCEMList;
        }
        
        List<Contact_Edition_Mapping__c> teamMemberList = [SELECT Id,isSecondary__c,Primary_Contact_Edition_Mapping__c FROM Contact_Edition_Mapping__c WHERE Id =:cemId WITH SECURITY_ENFORCED];
        if(!teamMemberList.isEmpty() && Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable()){
            teamMemberList[0].Relationship_Status__c = 'Inactive';
            teamMemberList[0].isSecondary__c = true;
            if(cemId != loginUserCEmId){
                teamMemberList[0].Primary_Contact_Edition_Mapping__c = loginUserCEmId;
            }
            update teamMemberList;
        }
        
         for(Contact_Edition_Mapping__c cem : teamMemberList){
            if(cem.Relationship_Status__c == 'Inactive'){
                cancelInvitedCEMIds.add(cem.Id);
            }
        }
        
       
        if(!cancelInvitedCEMIds.isEmpty()){
            IMCC_WelcomeEmailNotification.adminNotification(cancelInvitedCEMIds, loginUserCEMList[0],'CANCELINVITE');
            IMCC_WelcomeEmailNotification.teamMemberNotification(cancelInvitedCEMIds,'CANCELINVITETEAMMEM','','');
        }
        
        // Get form data and replace 
        List<Form_Data__c> fdList = [SELECT Id,Contact_Edition_Mapping__c FROM Form_Data__c WHERE Contact_Edition_Mapping__c =:cemId WITH SECURITY_ENFORCED];
        if(!fdList.isEmpty()){
            for(Form_Data__c fd : fdList){
                fd.Contact_Edition_Mapping__c = loginUserCEmId;
            }
            update fdList;
        }
        
        //get form response entry
        List<Form_Response_Entry__c> freList = [SELECT Id,Contact_Edition_Mapping__c,Ops_Contact_Name__c,User__c FROM Form_Response_Entry__c WHERE Contact_Edition_Mapping__c=:cemId WITH SECURITY_ENFORCED];
        if(!freList.isEmpty()){
            for(Form_Response_Entry__c fre : freList){
                fre.Contact_Edition_Mapping__c = loginUserCEmId;
                fre.Ops_Contact_Name__c = loginUserCEmCon;
                if(!u.isEmpty()){
                    fre.User__c = u[0].Id;
                }
            }
            update freList;
        }
        //Get Contractor_Mapping__c and replace
        List<Contractor_Mapping__c> cmList = [SELECT Id,Contact__c,Contractor_CEM__c,Is_Self_Managed__c FROM Contractor_Mapping__c WHERE Contractor_CEM__c=:cemId WITH SECURITY_ENFORCED];
        if(!cmList.isEmpty()){
            for(Contractor_Mapping__c cm : cmList){
                cm.Contact__c = loginUserCEmCon;
                cm.Contractor_CEM__c = loginUserCEmId;
            }
            update cmList;
        }
        //Get Question response and replace
        List<Question_Response__c> qrList = [SELECT Id,Contact_Edition_Mapping__c,User__c FROM Question_Response__c WHERE Contact_Edition_Mapping__c=:cemId WITH SECURITY_ENFORCED];
        if(!qrList.isEmpty()){
            for(Question_Response__c qr : qrList){
                qr.Contact_Edition_Mapping__c = loginUserCEmId;
                if(!u.isEmpty()){
                    qr.User__c = u[0].Id;
                }
            }
            Update qrList;
        }
        //get purchase data and replace
        List<Purchase_Data__c> pdList = [SELECT Id,Contact_Edition_Mapping__c,Contact__c FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c =:cemId WITH SECURITY_ENFORCED];
        if(!pdList.isEmpty()){
            for(Purchase_Data__c pd : pdList){
                pd.Contact_Edition_Mapping__c = loginUserCEmId;
                pd.Contact__c = loginUserCEmCon;
            }
            update pdList;
        }
        // Update Primary contacte edition mapping on Seconary CEMs
        List<Contact_Edition_Mapping__c> listSecondaryCEMs = new List<Contact_Edition_Mapping__c>([SELECT Id,Primary_Contact_Edition_Mapping__c FROM Contact_Edition_Mapping__c 
                                                                                                   WHERE (Primary_Contact_Edition_Mapping__c =:cemId AND Id !=:loginUserCEmId AND isSecondary__c =TRUE) OR (Account__c =:accountId AND Relationship_Status__c = 'Active' AND Edition__r.Edition_Code__c=:eventCode AND Id !=:loginUserCEmId) WITH SECURITY_ENFORCED]);
        if(!listSecondaryCEMs.isEmpty()){
            for(Contact_Edition_Mapping__c cem: listSecondaryCEMs){
                cem.Primary_Contact_Edition_Mapping__c = loginUserCEmId;
            }
            update listSecondaryCEMs;
        }
    }
    
    @AuraEnabled
    public static Map<String,Object> checkCurrentUser(String eventCode, String accountId){   
        
        Map<String,Object> returnMap;
        List<User> loginUser =[SELECT Id,ContactId FROM User WHERE Id =:UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        
        List<Contact_Edition_Mapping__c> loginUserCEMList;
        List<Current_Customer_Role__mdt> roleMetadatList;
        List<Contact_Edition_Mapping__c> secondaryAdminList = new List<Contact_Edition_Mapping__c>();
        
        if(Test.isRunningTest()){
            loginUserCEMList = [SELECT Id,Contact__c,isSecondary__c,Contact_Email__c,Primary_Contact_Edition_Mapping__c,Role__c FROM Contact_Edition_Mapping__c WHERE Account__c =:accountId AND Relationship_Status__c = 'Active'  WITH SECURITY_ENFORCED LIMIT 1];
        }
        else{
            loginUserCEMList = [SELECT Id,Contact__c,isSecondary__c,Contact_Email__c,Primary_Contact_Edition_Mapping__c,Role__c FROM Contact_Edition_Mapping__c WHERE Contact__c=:loginUser[0].ContactId AND Account__c =:accountId AND Relationship_Status__c = 'Active' AND Edition__r.Edition_Code__c=:eventCode WITH SECURITY_ENFORCED LIMIT 1];
        }
        
        if(!loginUserCEMList.isEmpty()){
            roleMetadatList = [SELECT Id, Customer_Role__c, MasterLabel FROM Current_Customer_Role__mdt WHERE MasterLabel =:loginUserCEMList[0].Role__c];
        }
        
        List<Contact_Edition_Mapping__c> cemList = teamMemberList(eventCode, accountId);
        if(!cemList.isEmpty()){
            for(Contact_Edition_Mapping__c cem : cemList){
                if(cem.Role__c == 'Secondary Admin'){
                    secondaryAdminList.add(cem);
                }
            }
        }
        
        
        returnMap = new Map<String,Object>{
            'currentUser' => loginUserCEMList,
                'currentRole' => roleMetadatList,
                'secondaryUser' => secondaryAdminList
                };
                    
                    return returnMap;
    }
}