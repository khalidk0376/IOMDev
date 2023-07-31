/**
* Created/Modified By: Girikon(Aishwarya)
* Created On:          07/9/2021
* @description  :      This class covers the code coverage of the class IMCC_GreetingPopup
* Apex Class:          IMCC_GreetingPopup(88%) 
**/

@isTest
private class IMCC_GreetingPopup_Test{
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        Profile p = [SELECT Id FROM Profile WHERE Name= 'IM System Administrator'];
        
        User user = new User(Alias = 'standt', Email='davidjones@test.com', 
        EmailEncodingKey='UTF-8', LastName='Kumar', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id,IsActive = true,
        TimeZoneSidKey='America/Los_Angeles', UserName='IMAdmin1@testorg.com');
        insert user;
         
        //User adminUser = [Select Id, UserRoleId From User Where Profile.Name='IM - Customer Center Admin' and IsActive = true Limit 1];
        //adminUser.UserRoleId = userrole.Id;
        //update adminUser;
        user.UserRoleId = userrole.Id;
        update user;
    }
    
    public static testMethod void headerDataInsert()
    {
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='IM System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id accId;
        System.runAs(adminUser) {
            List<Account> accObj  = IMCC_TestUtilities.createAccount(250);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
            contactId = contObj[0].Id;
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
        }
        
        List<Document> docObj  = IMCC_TestUtilities.createDocument(250);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(250);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 250);
        Id serviceObjId = serviceObj[0].Id;
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(250);
        Id eveSettingObjId = eveSettingObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting(serviceObjId,docObjId,eveSettingObjId,2);
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Purchase_Data__c> pdata = IMCC_TestUtilities.createPurchaseData4(cemObj.Id,editionObjId, 2);
        
        List<Edition_Popup__c> listEditionPopup = IMCC_TestUtilities.createEditionPopupData(editionObj[0].Id,200);
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabListData(eveSettingObj[0].Id,200);
        System.assertEquals(evntTabsLst.Size(),200, 'evntTabsLst size should be 200');
        
        List<Tab_User_Type__c> evntTabUserTypeList = IMCC_TestUtilities.createEventntTabUserTypeData2(evntTabsLst[0].Id,listEditionPopup[0].Id,cemObj.Access_Type__c,200);
        System.assertEquals(evntTabUserTypeList.Size(),200, 'Tab User List size should be 5');
        
         System.runAs(userObj) {
            Test.startTest();
                IMCC_GreetingPopup.fetchPopupDetails(editionObj[0].Edition_Code__c,accId);
                IMCC_GreetingPopup.updateMarkAsRead(cemObj.Id);
             IMCC_GreetingPopup.fetchStandDetails(editionObj[0].Edition_Code__c,accId);
            Test.stopTest();
        }
    }    

    @isTest
    public static void testException() {
        Test.startTest();
       try{ IMCC_GreetingPopup.fetchPopupDetails(null,null);}
       catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        try{ IMCC_GreetingPopup.updateMarkAsRead(null); }
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        Test.stopTest();
    }
}