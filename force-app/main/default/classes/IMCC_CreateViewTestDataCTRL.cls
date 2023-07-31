/**
* Created/Modified By :(Arushi [IMCC-5107])
* Created On:          23/03/2023
* @description  :      As an Ops User, I should be able to easily create Test Accounts to validate In Progress events
* Methods:             getEixstingTestData,testDataCreated,cancelInvitation,sendEmailInvite
* Test Class:          IMCC_CreateViewTestDataCTRLTest
**/
public without sharing class IMCC_CreateViewTestDataCTRL {
    
    @auraEnabled
    public static List<Contact_Edition_Mapping__c> getEixstingTestData(string editionId){
        system.debug('editionId'+editionId);
        List<Contact_Edition_Mapping__c> testCEMList = [SELECT Id,Account__c,Edition__c,Edition__r.Edition_Code__c,Edition__r.Customer_Center_Status__c
                                                        , Contact__c,Contact__r.Name,Role__c, Email_Sent__c,First_Login_Date_Time__c,Name
                                                        ,Access_Type__c,isTestUser__c, Contact_Email__c,Relationship_Status__c,(SELECT Id,Booth_Product_Type__c FROM Purchase_Data__r)
                                                        FROM Contact_Edition_Mapping__c WHERE Relationship_Status__c = 'Active' AND isTestUser__c = True
                                                        AND Edition__c=:editionId AND Role__c =:'Team Member' AND Edition__r.Customer_Center_Status__c = 'In Progress' WITH SECURITY_ENFORCED];
        system.debug('testCEMList'+testCEMList);
        return testCEMList;
    }
    
    @AuraEnabled
    public static Map<string,object> testDataCreated(string editionId, string userType, string boothType){
        
        Map<String,Object> result = new Map<String,Object>();
        
        List<Contact> conList = [SELECT Id,Name,AccountId,Access_Type__c,IsTestUser__c FROM Contact WHERE Access_Type__c=: userType AND 
                                 IsTestUser__c = True WITH SECURITY_ENFORCED];
        string contactId = conList[0].Id;
        string contactName = conList[0].Name;
        
        List<Contact_Edition_Mapping__c> testCEMList = [SELECT Id,Account__c,Relationship_Status__c, Primary_Contact_Edition_Mapping__c
                                                        , isSecondary__c, Contact__c,Role__c,isTestUser__c FROM Contact_Edition_Mapping__c WHERE Contact__c=:contactId AND 
                                                        Access_Type__c =:userType AND Edition__c=:editionId AND isTestUser__c = True WITH SECURITY_ENFORCED LIMIT 1];
        string pdId = '';
        try {
            if(!testCEMList.isEmpty()){
                if(testCEMList[0].Relationship_Status__c == 'Inactive' && Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable()){
                    testCEMList[0].Relationship_Status__c = 'Active';
                    testCEMList[0].Role__c = 'Team Member';
                    testCEMList[0].isTestUser__c = True;
                    update testCEMList[0];
                }
                string cemId = testCEMList[0].Id;
                string cemAccountId = testCEMList[0].Account__c;
                
                List<Purchase_Data__c> pdList = [SELECT Id,Booth_Product_Type__c,User_Type__c,Contact_Edition_Mapping__c 
                                                 ,Contact__c,Account__c,Edition__c FROM Purchase_Data__c WHERE Booth_Product_Type__c=: boothType AND 
                                                 Contact_Edition_Mapping__c=:cemId AND User_Type__c=: userType AND Contact__c=: contactId AND 
                                                 Account__c=:cemAccountId AND Edition__c=:editionId WITH SECURITY_ENFORCED];
                
                if(pdList.isEmpty()){
                    Purchase_Data__c pd = new Purchase_Data__c();
                    pd.Account__c = testCEMList[0].Account__c;
                    pd.Contact__c = contactId;
                    pd.Contact_Edition_Mapping__c = testCEMList[0].Id;
                    pd.Edition__c = editionId;
                    pd.Purchase_Status__c = 'Active';
                    pd.Transaction_Status__c = 'Active';
                    pd.User_Type__c = userType;
                    pd.Booth_Product_Type__c = boothType;
                    pd.Booth_Number__c = 'booth-1';
                    pd.Hall_Name__c = 'Test';
                    pd.Quantity_Area__c = 1;
                    
                    SObjectAccessDecision securityDecision3 = Security.stripInaccessible(AccessType.CREATABLE, new Purchase_Data__c []{pd});
                    Insert securityDecision3.getRecords();
                    result.put('success',contactId);
                }
                else{
                    result.put('error',contactId+ '_'+contactName);                
                }  
            }
            else{
                Contact_Edition_Mapping__c cEM = new Contact_Edition_Mapping__c();
                cEM.Account__c = conList[0].AccountId;
                cEM.Contact__c = contactId;
                cEM.Access_Type__c = userType;
                cEM.Edition__c = editionId;
                cEM.Role__c = 'Team Member';
                cEM.Relationship_Status__c = 'Active';
                cEM.isTestUser__c = True;
                
                
                SObjectAccessDecision securityDecision1 = Security.stripInaccessible(AccessType.CREATABLE, new Contact_Edition_Mapping__c []{cEM});
                Insert securityDecision1.getRecords();
                Id cEMId = securityDecision1.getRecords()[0].Id;
                
                Purchase_Data__c pd = new Purchase_Data__c();
                pd.Account__c = conList[0].AccountId;
                pd.Contact__c = contactId;
                pd.Contact_Edition_Mapping__c = cEMId;
                pd.Edition__c = editionId;
                pd.Purchase_Status__c = 'Active';
                pd.Transaction_Status__c = 'Active';
                pd.User_Type__c = userType;
                pd.Booth_Product_Type__c = boothType;
                pd.Booth_Number__c = 'booth-1';
                pd.Hall_Name__c = 'Test';
                //pd.Unit_of_Measurement__c = 'Feet';
                pd.Quantity_Area__c = 1;
                
                SObjectAccessDecision securityDecision2 = Security.stripInaccessible(AccessType.CREATABLE, new Purchase_Data__c []{pd});
                Insert securityDecision2.getRecords();
                pdId = securityDecision2.getRecords()[0].Id;
                result.put('success',contactId);
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void cancelInvitation(String cemId){   
        
        List<Contact_Edition_Mapping__c> teamMemberList = [SELECT Id
                                                           FROM Contact_Edition_Mapping__c WHERE Id =:cemId WITH SECURITY_ENFORCED];
        if(!teamMemberList.isEmpty() && Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable()){
            teamMemberList[0].Relationship_Status__c = 'Inactive';
            update teamMemberList;
        }
    }
    
    @auraEnabled
    public static void sendEmailInvite(string cemId, string emailAddress){
        
        Map<Id,User> mapConUser = new Map<Id,User>();
        List<User> lstUsr = new List<User>();
        String confluenceURL = System.Label.Confluence_Page_URL_For_Test_Data;
        try{
            Contact_Edition_Mapping__c cem = [SELECT Id, Account__c,Account__r.Name, Contact__c,Edition__c,Edition__r.Name, CC_Status__c,Edition__r.Edition_Code__c,Relationship_Status__c, Access_Type__c FROM Contact_Edition_Mapping__c where Id=:cemId WITH SECURITY_ENFORCED];
            
            Id sConId = cem.Contact__c;
            Id sEventId = cem.Edition__c;   
            
            List<Purchase_Data__c> pdList = [SELECT Id,Booth_Product_Type__c,User_Type__c,Contact_Edition_Mapping__c 
                                             ,Contact__c,Account__c,Edition__c FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c=:cemId WITH SECURITY_ENFORCED];
            
            Set<String> boothTypeSet = new Set<String>();
            String bType = '';

            if(!pdList.isEmpty()){
                for(Purchase_Data__c pd : pdList){
                    boothTypeSet.add(pd.Booth_Product_Type__c);
                }
                bType = String.join( (Iterable<String>)boothTypeSet, ',' );
            }
            
            lstUsr = [SELECT Id,Email,username,firstname,ContactId,Contact.account.name,Contact.name,Contact.email,IsActive,IsPortalEnabled FROM User where ContactId=: sConId AND IsPortalEnabled=true AND Profile.Name='IM Customer Community Login User' AND IsActive=true WITH SECURITY_ENFORCED];  
           
            for(User oUser : lstUsr){
                mapConUser.put(oUser.ContactId,oUser);
            }
            
            List<Email_Templates__c> listET = [SELECT Content__c, Subject__c,Template_Code__c,Name FROM Email_Templates__c WHERE Template_Code__c =:'WELEMAILForTestData' WITH SECURITY_ENFORCED];
            
            if(!listET.isEmpty() && mapConUser.size() > 0){
                if(mapConUser.containsKey(sConId)){
                String htmlValue = listET[0].Content__c;
                
                //String companyName = cem.Account__r.Name!=null?cem.Account__r.Name:'';                
                String accessType = cem.Access_Type__c;
                String boothType = bType != ''?bType:'';
                String userName = mapConUser.get(cem.Contact__c).userName;
                userName = userName!=null?userName:'';
                String eventName = cem.Edition__r.Name!=null?cem.Edition__r.Name:'';
                
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                htmlValue = htmlValue!=null?htmlValue:'';
                htmlValue = htmlValue.replace('{Event Name}',eventName);                    
                htmlValue = htmlValue.replace('{Access Type}',accessType);     
                htmlValue = htmlValue.replace('{Booth Type}',boothType);               
                htmlValue = htmlValue.replace('{Username}',userName);
                htmlValue = htmlValue.replace('{here}',confluenceURL);
                String emailSubject = listET[0].Subject__c;
                emailSubject = emailSubject.replace('{Event Name}', eventName);
                //emailSubject = emailSubject.replace('{COMPANY NAME}', companyName);
                
                List<string> toAddress = new List<string>();
                toAddress.add(emailAddress);
                
                mail.setToAddresses(toAddress);
                mail.setSubject(emailSubject);
                mail.setHtmlBody(htmlValue);
                mail.setSaveAsActivity(false);
                //mail.setTargetObjectId(mapConUser.get(cem.Contact__c).Id);
                
                system.debug('mail'+ mail);
                //Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {mail};
                
                mails.add(mail);
                
                
                
                Messaging.sendEmail(mails,true);
            }
            else{
                String errorMsg = (!mapConUser.containsKey(cem.Contact__c)?System.Label.IMCC_Welcome_Email_Error_Msg3:System.Label.IMCC_Welcome_Email_Error_Msg4); 
            }
            }
            
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }  
    }       
}