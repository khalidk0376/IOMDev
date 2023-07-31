@IsTest
public with sharing class IMCC_HomeCtrl_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
        
        // Setup Test Data 
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
            contactId = contObj[0].Id;
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
        }
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id serviceObjId = serviceObj[0].Id;
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(1);
        Id eveSettingObjId = eveSettingObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting(serviceObjId,docObjId,eveSettingObjId,1);
        editionObj[0].Company_Profile_Submission_Due_Date__c = System.Today();
        Update editionObj[0];
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        
        cemObj.Completed_Purchase_Summaries__c = 'Badge';
        update cemObj;
        
        IMCC_TestUtilities.createEditionWebsites(editionObjId, 1);
        
        IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);        
        
        Announcement__c announcement = IMCC_TestUtilities.createAnnouncementData(editionObjId);
        //List<Tab_User_Type__c> tabUserLst = IMCC_TestUtilities.createTabUserTypeForAnnouncement(announcement.Id,'Exhibitor');
        //System.assertEquals(tabUserLst.Size(),2, 'Tab User List size should be 2');
        
        List<Event_Tabs__c> eventTabs = IMCC_TestUtilities.createEventTabs(eveSettingObjId,1,10,null,'Custom','HTML',null);
        List<Event_Tabs__c> eventTabs1 = IMCC_TestUtilities.createEventTabs(eveSettingObjId,1,20,null,'Standard','Forms',null);
        List<Tab_User_Type__c> tabUserLst1 = IMCC_TestUtilities.createTabUserType(eventTabs1[0].Id,1,'Exhibitor');
        tabUserLst1[0].Announcement__c = announcement.Id;
        update tabUserLst1;
        System.assertEquals(tabUserLst1.Size(),1, 'Tab User List size should be 1');
        
        IMCC_TestUtilities.createContentVer(1);
        
        List<ContentDocument> documents = [SELECT Id FROM ContentDocument LIMIT 1];
        IMCC_TestUtilities.createContentDocLink(documents[0].Id,eventTabs[0].Id,1);
        
        List<Purchase_Summary__c> listPS = new List<Purchase_Summary__c>();
        Purchase_Summary__c ps = new  Purchase_Summary__c();
        ps.Event_Setting__c = eveSettingObjId;
        ps.Event_Tab__c = eventTabs.get(0).Id;
        ps.Name='Test';
        ps.Purchase_Summary_Type__c = 'Badge';
        ps.External_Link__c='https://test.com';
        ps.External_Link_Label__c='test link';
        ps.Information_Label__c='test';
        ps.Order__c = 10;
        ps.Is_Active__c = true;
        listPS.add(ps);
        
        ps = new  Purchase_Summary__c();
        ps.Event_Setting__c = eveSettingObjId;
        ps.Event_Tab__c = eventTabs.get(0).Id;
        ps.Name='Test';
        ps.Purchase_Summary_Type__c = 'Virtual Event';
        ps.External_Link__c='https://test.com';
        ps.External_Link_Label__c='test link';
        ps.Information_Label__c='test';
        ps.Order__c = 20;
        ps.Is_Active__c = true;
        listPS.add(ps);
        Insert listPS;
        
        List<Purchase_Data__c> purchaseList = IMCC_TestUtilities.createPurchaseData(cemObj.Id,accId,1);
        System.assertEquals(purchaseList.Size(),1, 'Purchase Data List size should be 1');
    } 
    
    @isTest
    public static void testAnnouncement(){
        User userObj = [SELECT Id FROM User WHERE Profile.Name='IM Customer Community Login User' AND Email='davidjones@test.com' LIMIT 1];
        Account acc = [SELECT Id FROM Account Limit 1];
        List<Contact_Edition_Mapping__c> cemObjs = [SELECT Id FROM Contact_Edition_Mapping__c];
        Edition__c edition = [SELECT Id,Edition_Code__c FROM Edition__c Limit 1];
        Test.startTest();
        System.runAs(userObj) {
            IMCC_HomeCtrl.getAnnouncements(edition.Edition_Code__c,acc.Id);
            IMCC_HomeCtrl.getTabContext(edition.Edition_Code__c,acc.Id,null);
            IMCC_HomeCtrl.getPurchaseSummary(edition.Edition_Code__c,acc.Id);
            IMCC_HomeCtrl.getEventSummary(edition.Edition_Code__c,acc.Id);
            IMCC_HomeCtrl.updatePurchaseSummary('Badge',cemObjs[0].Id);
            Event_Tabs__c et = [SELECT Tab_Code__c FROM Event_Tabs__c LIMIT 1];
            String str = IMCC_HomeCtrl.getHtml(et.Tab_Code__c);
            System.assertEquals('Some Text', str, 'Incorrect String');
            
            IMCC_HomeCtrl.getTabId(edition.Edition_Code__c,acc.Id);
        }
        Test.stopTest();
    } 
    
    @isTest
    private static void testForException()
    {
        Account acc = [SELECT Id FROM Account Limit 1];
        IMCC_HomeCtrl.getAnnouncements(null,acc.Id);
        
        IMCC_HomeCtrl.getTabContext(null,acc.Id,null);
        try{IMCC_HomeCtrl.getPurchaseSummary(null,null);}
        catch(Exception e){
          System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        
        IMCC_HomeCtrl.getBadges(null,null);
        
        try{IMCC_HomeCtrl.updatePurchaseSummary(null,null);}
        catch(Exception e){
          System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        } 
        
        try{IMCC_HomeCtrl.getEventSummary(null,null);}
        catch(Exception e){
          System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        } 
        
        IMCC_HomeCtrl.getHtml(null);
        IMCC_HomeCtrl.getTabId(null,null);
    }
}