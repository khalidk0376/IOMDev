/**
* Created/Modified By: Girikon(Aishwarya)
* Created On:          07/9/2021
* @description  :      This class covers the code coverage of the class IMCC_HeaderCtrl
* Methods:             headerDataInsert
* Apex Class:          IMCC_HeaderCtrl(88%) 
**/
@isTest
private class IMCC_HeaderCtrl_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    public static testMethod void headerDataInsert()
    {
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser){
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
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting(serviceObjId,docObjId,eveSettingObjId,250);
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 100);
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,10,'3 Column','Custom',null,null);
        System.assertEquals(evntTabsLst.Size(),5, 'evntTabsLst size should be 5');
        
        List<Tab_User_Type__c> tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,5,'Exhibitor');
        System.assertEquals(tabUserLst.Size(),5, 'Tab User List size should be 5');
        
        List<Tab_Context__c> tabContLst = IMCC_TestUtilities.createTabContext(evntTabsLst[0].id, 1);
        System.assertEquals(tabContLst.Size(),1, 'List size should be 200');
        tabContLst[0].Publish_Changes__c = true;
        update tabContLst[0];
        List<Purchase_Data__c> purchaseDataObj  = IMCC_TestUtilities.createPurchaseData2(cemObj.Id,editionObjId,2);
        
        System.runAs(userObj){
            Test.startTest();
                IMCC_HeaderCtrl.fetchUserTabDetails(editionObj[0].Edition_Code__c,accId,null);
                List<Event_Tabs__c> lstEvntTab = [Select id,Name,Event_Setting__c,Tab_Code__c from Event_Tabs__c where Event_Setting__c =: editionObj[0].Event_Setting__c];
                system.debug('Event Tab ' +lstEvntTab);
                if(!lstEvntTab.isEmpty()){
                  IMCC_HeaderCtrl.fetchUserTabDetails(editionObj[0].Edition_Code__c,accId,lstEvntTab[0].Tab_Code__c);  
                }
            Test.stopTest();
        }
    } 
    

    @isTest
    private static void testException(){

        try{IMCC_HeaderCtrl.fetchUserTabDetails('$$$','*****',' ');}
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
    }
    
    @isTest
    public static void headerDataInsert2()
    {
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser){
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
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting(serviceObjId,docObjId,eveSettingObjId,250);
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 100);
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,10,'3 Column','Custom',null,null);
        System.assertEquals(evntTabsLst.Size(),5, 'evntTabsLst size should be 5');
        evntTabsLst[0].Booth_Product_Types__c = 'Space Only;Shell Scheme';
        update evntTabsLst;
        
        List<Tab_User_Type__c> tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,5,'Exhibitor');
        System.assertEquals(tabUserLst.Size(),5, 'Tab User List size should be 5');
        
        List<Tab_Context__c> tabContLst = IMCC_TestUtilities.createTabContext(evntTabsLst[0].id, 1);
        System.assertEquals(tabContLst.Size(),1, 'List size should be 200');
        tabContLst[0].Publish_Changes__c = true;
        tabContLst[0].Booth_Product_Type__c = 'Space Only;Shell Scheme';
        update tabContLst[0];
        
        List<Tab_Context__c> tabContLst1 = IMCC_TestUtilities.createTabContext(evntTabsLst[0].id, 1);
        tabContLst1[0].Booth_Product_Type__c = 'Space Only;Shell Scheme';
        update tabContLst1;

        List<Purchase_Data__c> purchaseDataObj  = IMCC_TestUtilities.createPurchaseData2(cemObj.Id,editionObjId,2);
        
        System.runAs(userObj){
            Test.startTest();
                IMCC_HeaderCtrl.fetchUserTabDetails(editionObj[0].Edition_Code__c,accId,null);
                List<Event_Tabs__c> lstEvntTab = [Select id,Name,Event_Setting__c,Tab_Code__c from Event_Tabs__c where Event_Setting__c =: editionObj[0].Event_Setting__c];
                system.debug('Event Tab ' +lstEvntTab);
                if(!lstEvntTab.isEmpty()){
                  IMCC_HeaderCtrl.fetchUserTabDetails(editionObj[0].Edition_Code__c,accId,lstEvntTab[0].Tab_Code__c);  
                }
                
                IMCC_HeaderCtrl.WrapperUserTabDetails wrapTest = new IMCC_HeaderCtrl.WrapperUserTabDetails();
                //wrapTest.userTypeEventTabs = tabUserLst;
                //wrapTest.accountName = 'wrapTest';
                //wrapTest.tabContextLst = tabContLst;
                //wrapTest.listTabContextForNew = tabContLst1;
                //wrapTest.havingCEMRecords = true;
            Test.stopTest();
        }
    } 

   /* @isTest
    public static void headerDataInsert3()
    {
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser){
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
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting(serviceObjId,docObjId,eveSettingObjId,250);
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 100);
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,10,'3 Column','Custom',null,null);
        System.assertEquals(evntTabsLst.Size(),5, 'evntTabsLst size should be 5');
        
        List<Tab_User_Type__c> tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,5,'Exhibitor');
        System.assertEquals(tabUserLst.Size(),5, 'Tab User List size should be 5');
        
        List<Tab_Context__c> tabContLst = IMCC_TestUtilities.createTabContext(evntTabsLst[0].id, 1);
        System.assertEquals(tabContLst.Size(),1, 'List size should be 200');
        tabContLst[0].Publish_Changes__c = true;
        update tabContLst[0];
        
        List<Tab_Context__c> tabContLst1 = IMCC_TestUtilities.createTabContext(evntTabsLst[0].id, 1);
        List<Purchase_Data__c> purchaseDataObj  = IMCC_TestUtilities.createPurchaseData2(cemObj.Id,editionObjId,2);
        
        System.runAs(userObj){
            Test.startTest();
                IMCC_HeaderCtrl.fetchUserTabDetails(editionObj[0].Edition_Code__c,accId,null);
                List<Event_Tabs__c> lstEvntTab = [Select id,Name,Event_Setting__c,Tab_Code__c from Event_Tabs__c where Event_Setting__c =: editionObj[0].Event_Setting__c];
                system.debug('Event Tab ' +lstEvntTab);
                if(!lstEvntTab.isEmpty()){
                  IMCC_HeaderCtrl.fetchUserTabDetails(editionObj[0].Edition_Code__c,accId,lstEvntTab[0].Tab_Code__c);  
                }
                
                IMCC_HeaderCtrl.WrapperUserTabDetails wrapTest = new IMCC_HeaderCtrl.WrapperUserTabDetails();
                //wrapTest.userTypeEventTabs = tabUserLst;
                //wrapTest.accountName = 'wrapTest';
                //wrapTest.tabContextLst = tabContLst;
                //wrapTest.listTabContextForNew = tabContLst1;
                //wrapTest.havingCEMRecords = true;
            Test.stopTest();
        }
    }*/
}