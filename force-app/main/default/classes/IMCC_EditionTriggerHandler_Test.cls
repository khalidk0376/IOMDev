/*
* Created By         : Girikon(Keertiraj)
* Created On         : 12/10/2021
* @description       : This test class covers the apex class : IMCC_EditionTriggerHandler,IMCC_TrigEdition,IMCC_PurchaseDataTriggerHandler                    
* Apex Class         : IMCC_EditionTriggerHandler (95%), IMCC_TrigEdition(100%),IMCC_PurchaseDataTriggerHandler(64%)
  Modified By        : Girikon(Arushi)
* Modified On        : 9/02/2022
*/

@isTest
private class IMCC_EditionTriggerHandler_Test {
    
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
        
        Id contactId;
        Id contactId1;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj = IMCC_TestUtilities.createAccount(250);
            accId = accObj[0].Id;
            System.assertEquals('Test Account0', accObj[0].Name, 'Account name does not match');
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 2);
            contactId = contObj[0].Id;
            contactId1 = contObj[1].Id;
            IMCC_TestUtilities.createCommunityUser(contObj[1].Id);
        }
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id serviceObjId = serviceObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionInActive(serviceObjId,docObjId,2);
        Id editionObjId = editionObj[0].Id;
        Id editionObjId2 = editionObj[1].Id;
        List<Email_Templates__c> listEmailTemp = IMCC_TestUtilities.createEmailTemplateWelcome(); 
        IMCC_TestUtilities.createEditionEmailTemplate(editionObj[0].Id,listEmailTemp.get(0).Id, new List<String>{'WELNew'});
        IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId1,accId,editionObj[1].Id);
        IMCC_TestUtilities.createStandSetting(1);
        List<Purchase_Data__c> booth = IMCC_TestUtilities.createPurchaseData4(cemObj.Id,editionObjId2,2);
        IMCC_TestUtilities.createContractorMappingData(accId,contactId,cemObj.Id,booth[0].Id,'Contractor Nominated',editionObjId2,null,1);
    }
    
    @isTest
    private static void iMCCEditionTriggerHandlerTest(){
        
        Test.startTest();
        List<Edition__c> listEdition = [SELECT Name,Edition_Code__c,Edition_Status__c,Send_Welcome_email__c,Customer_Center_Status__c from Edition__c];
        listEdition[0].Customer_Center_Status__c='Active';
        listEdition[0].Send_Welcome_email__c = true;
        listEdition[1].Customer_Center_Status__c='Active';
        listEdition[1].Send_Welcome_email__c = true;
        update listEdition;
        List<Edition__c> listEdition2 = [SELECT Name,Edition_Code__c,Edition_Status__c,Send_Welcome_email__c,Customer_Center_Status__c from Edition__c WHERE Customer_Center_Status__c='Active'];
        System.assertEquals(2, listEdition2.size(), 'Data not updated.');
        Test.stopTest();
    }
    
    @isTest
    private static void iMCCEditionTriggerHandlerMethod2(){
        Test.startTest();
        List<Stand_Setting__c> standSettingObj = [SELECT Id FROM Stand_Setting__c];
        List<Edition__c> editionObj = [SELECT Id,Contractor_Nomination_Due_Date__c FROM Edition__c];
        for(Edition__c edt : editionObj){
            edt.Stand_Setting__c = standSettingObj[0].Id;
            edt.Customer_Center_Status__c='Active';
            edt.Send_Welcome_email__c = true;
        }
        Update editionObj;
        editionObj[1].Contractor_Nomination_Due_Date__c = System.Today().addDays(-3);
        Update editionObj[1];
        List<Task> listTask = [SELECT Id FROM Task WHERE Subject='Nominate the Contractor'];
        System.assertEquals(1, listTask.size(), 'Task not Created.');
        editionObj[1].Contractor_Nomination_Due_Date__c = System.Today();
        Update editionObj[1];
        Test.stopTest();
        
    }
    
    @isTest
    private static void iMCCEditionTriggerHandlerMethod2Negative(){
        Test.startTest();
        List<Stand_Setting__c> standSettingObj = [SELECT Id FROM Stand_Setting__c];
        List<Edition__c> editionObj = [SELECT Id,Contractor_Nomination_Due_Date__c FROM Edition__c];
        for(Edition__c edt : editionObj){
            edt.Stand_Setting__c = standSettingObj[0].Id;
            edt.Customer_Center_Status__c='Active';
            edt.Send_Welcome_email__c = true;
        }
        Update editionObj;
        Profile p = [SELECT Id FROM Profile WHERE Name= 'Sales Operations'];
        User user = new User(Alias = 'standt', Email='davidjones@test.com', 
        EmailEncodingKey='UTF-8', LastName='Kumar', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id,IsActive = true,
        TimeZoneSidKey='America/Los_Angeles', UserName='IMAdmin1@testorg.com');
        insert user;
        System.runAs(user){
            editionObj[1].Contractor_Nomination_Due_Date__c = System.Today().addDays(-3);
            Update editionObj[1];
        }
        List<Custom_Error_Log__c> listCEL = [SELECT Id from Custom_Error_Log__c];
        System.assertEquals(1, listCEL.size(), 'Data updated.');
        Test.stopTest();
        
    }
}