/**
* Created By   :   IBM(Bharath)
* Created On   :   9 May 2023
* ******************************************************************************************************************
* @description  : Test Class to give covrage to SendIOMEmails(100%)]
* ******************************************************************************************************************
*/
@isTest
private class SendIOMEmails_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    
    @isTest 
    static void sendiomEmailTest(){
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
		Contact con = new Contact();
        User userObj;
        Id contactId;
        Id accId;
        string sendEmail='bharath.sharma@informa.com';
        Id standardPricebookId = Test.getStandardPricebookId();
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
            contObj[0].Email=sendEmail;
            update contObj;
            contactId = contObj[0].Id;
            con = contObj[0];
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
        }

        List<Edition__c> listOfEditions = new List<Edition__c>();
        Edition__c edition = new Edition__c();
        for(Integer i=0;i<2;i++){
            edition =  new Edition__c(Invoice_to_be_issued_before__c='30');
            
            listOfEditions.add(edition);
        }
        insert listOfEditions;

        Opportunity opp = new Opportunity( 
            Pricebook2Id =standardPricebookId,
            CloseDate =Date.newInstance(2019, 11, 5),
            StageName ='Proposal',
            Default_Edition__c=listOfEditions[0].Id,
            Name ='TESTOPP',  
            AccountId=accId,
            Sales_Person__c=sendEmail,
            Bill_To_Account__c = accId,
            Ship_To_Account__c = accId,
            Billing_Contact__c=contactId);
        insert opp;
          
        Change_Request__c cr = new Change_Request__c(Account__c=accId,Opportunity__c=opp.Id,Product_Type__c='Financial'
                                                     ,Type_of_Change__c='Cancellation',New_Payment_Schedule__c='50-50'
                                                     ,Edition__c=listOfEditions[0].id,Requested_By__c=sendEmail);
        List<Change_Request__c> lstCr = new  List<Change_Request__c>();
        lstCr.add(cr);
        insert lstCr;
        Test.startTest();
        SendIOMEmails.sendEmailTemplateWithTemplate(cr.Id,'Amendment_Request_Rejection');
        SendIOMEmails.sendEmailTemplateWithTemplate(opp.Id,'Opportunity_Custom_Billing_Rejection');
        Test.stopTest();
    }
}