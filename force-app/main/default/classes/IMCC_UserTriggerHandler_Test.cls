/**
* Created By     :  Girikon(Arushi[IMCC-763])
* Created On     :  28/03/2022
* @description   :  On a new customer username creation in Salesforce, currently there are extra characters created along with the email in the username. This will need to be removed for the ease of use from customer's side. 
* Apex Test Class: IMCC_UserTriggerHandler_Test(100%)
**/
@isTest
private class IMCC_UserTriggerHandler_Test {
    @TestSetUp
    private static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    
    @isTest
    private static void unitTest(){
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        Id communityProfileId = IMCC_UtilityMethods.getCommProfile();
        Test.StartTest();
        System.runAs(adminUser){
            List<Account> accts = new List<Account>();
            List<String> accountNames = (new List<String>{'Airtel Payments Bank Ltd','Arabi Company','ASEAN Super 8 Virtual Connect','chandras','Edge Communications','Facebook','Girikon Inc.','Global Partners','Google','IBM Corporation','IM Acc1','IM Acc2','IM Acc3','Infosys Public Services Inc','IPL','Maruti Suzuki India Ltd','Microsoft','Naveen& Sons','Pfizer Middle East','pixla12','pixla2','Polystat','Raidu Cement Private Limited','RenewX','salesforce.com','Test Acc CC 2','Test Account 2','Trebing & Himstedt Prozessautomation GmbH & Co.KG','Wipro Technologies Inc','Yahoo Farm'});
            for(String s: accountNames){
                Account a = new Account(Name=s);
                accts.add(a);
            }
            insert accts;
            
            List<String> firstNames = (new List<String>{'Jack','liam','Email','Test','Test','Ayush','Pramod','Pramod','Jack','liam','','Keertiraj','Keertiraj',''});
            List<String> lastNames = (new List<String>{'Warner','walter','User','User','User','Tripathi','Tete','Tete','Warner','walter','Tripathi','Halli','Halli','Halli'});           
            Integer emailCounter = 0;
            Integer listLength = lastNames.size();
            
            List<Contact> conList = new List<Contact>();
            for(Account a : accts){
                Integer randomNumber = Integer.valueof((Math.random() * listLength));
                if(randomNumber == 0){randomNumber = 1;}
                for(integer i=0;i<randomNumber;i++){
                    conList.add(new Contact(firstname=firstNames[i],lastname=lastNames[i],
                                            AccountId=a.Id,Email='FirstName'+emailCounter+'@test.com')); 
                    emailCounter++;
                }
            }
            insert conList;
            
            List<User> commUserLst = new List<User>();
            Set<Id> conIds = new Set<Id>();
            for(Contact con : conList){
                conIds.add(con.Id);
                String aliasName = (String.isNotBlank(con.FirstName)?String.valueOf(con.FirstName.substring(0,1)):'') + String.valueOf(con.LastName.substring(0,1));
                
                User commUsr = new User(ContactId = con.Id,Username = con.Email,FirstName = con.FirstName,
                                        LastName = con.LastName,Email = con.Email,Alias = aliasName,
                                        ProfileId = communityProfileId,FederationIdentifier = con.Email,
                                        EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US',
                                        LocaleSidKey = 'en_US',TimeZoneSidKey = 'America/Los_Angeles');
                commUserLst.add(commUsr);                     
            }
            database.insert(commUserLst,false);
            List<User> users = [Select Id From User Where ContactId IN:conIds];
            
            System.assertEquals(conList.size(), users.size(), 'All Users Not Created');
            
            conList = new List<Contact>();
            for(Account a : accts){
                Integer randomNumber = Integer.valueof((Math.random() * listLength));
                if(randomNumber == 0){randomNumber = 1;}
                for(integer i=0;i<randomNumber;i++){
                    conList.add(new Contact(firstname=firstNames[i],lastname=lastNames[i],
                                            AccountId=a.Id,Email='FirstName'+emailCounter+'@test.com')); 
                    emailCounter++;
                }
            }
            insert conList;
            
            commUserLst = new List<User>();
            conIds = new Set<Id>();
            for(Contact con : conList){
                conIds.add(con.Id);
                String aliasName = (String.isNotBlank(con.FirstName)?String.valueOf(con.FirstName.substring(0,1)):'') + String.valueOf(con.LastName.substring(0,1));
                
                User commUsr = new User(ContactId = con.Id,Username = con.Email,FirstName = con.FirstName,
                                        LastName = con.LastName,Email = con.Email,Alias = aliasName,
                                        ProfileId = communityProfileId,FederationIdentifier = con.Email,
                                        EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US',
                                        LocaleSidKey = 'en_US',TimeZoneSidKey = 'America/Los_Angeles');
                commUserLst.add(commUsr);                     
            }
            database.insert(commUserLst,false);
            List<User> users2 = [Select Id From User Where ContactId IN:conIds];
            
            System.assertEquals(conList.size(), users2.size(), 'All Users Not Created');
            
            conList = new List<Contact>();
            for(Account a : accts){
                Integer randomNumber = Integer.valueof((Math.random() * listLength));
                if(randomNumber == 0){randomNumber = 1;}
                for(integer i=0;i<randomNumber;i++){
                    conList.add(new Contact(firstname=firstNames[i],lastname=lastNames[i],
                                            AccountId=a.Id,Email='FirstName'+emailCounter+'@test.com')); 
                    emailCounter++;
                }
            }
            insert conList;
            
            commUserLst = new List<User>();
            conIds = new Set<Id>();
            for(Contact con : conList){
                conIds.add(con.Id);
                String aliasName = (String.isNotBlank(con.FirstName)?String.valueOf(con.FirstName.substring(0,1)):'') + String.valueOf(con.LastName.substring(0,1));
                
                User commUsr = new User(ContactId = con.Id,Username = con.Email,FirstName = con.FirstName,
                                        LastName = con.LastName,Email = con.Email,Alias = aliasName,
                                        ProfileId = communityProfileId,
                                        EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US',
                                        LocaleSidKey = 'en_US',TimeZoneSidKey = 'America/Los_Angeles');
                commUserLst.add(commUsr);                     
            }
            database.insert(commUserLst,false);
            List<User> users3 = [Select Id From User Where ContactId IN:conIds];
            System.assertEquals(conList.size(), users3.size(), 'All Users Not Created');
            Email_Templates__c et = IMCC_TestUtilities.updateEmailTemplate();
            users3[0].FirstName = 'test';
            users3[0].Email = 'abc@test.com';
            update users3[0];
            
        }
        Test.stopTest();        
    }
    
}