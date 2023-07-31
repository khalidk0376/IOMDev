/**
* Created/Modified By: Girikon(Garima)
* Created On:          05/10/2021
* @description  :      This class covers the code coverage of the class IMCC_FloorplanCtrl
* Methods:             floorplanDataInsert
* Apex Class:          IMCC_FloorplanCtrl(96%) 
**/

@isTest
private class IMCC_FloorplanCtrl_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    public static testMethod void floorplanDataInsert()
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
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        
        List<Event_Tabs__c> evntTabsLst1 = IMCC_TestUtilities.createEventTabs(eveSettingObjId,1,2,'Header and 2 Column','Standard','Floorplan','Interactive');
        System.assertEquals(evntTabsLst1[0].Floorplan_Type__c,'Interactive', 'Floorplan Type should be Interactive');
        
        List<Event_Tabs__c> evntTabsLst2 = IMCC_TestUtilities.createEventTabs(eveSettingObjId,1,5,'Header and 2 Column','Standard','Floorplan','Manual');
        System.assertEquals(evntTabsLst2[0].Floorplan_Type__c,'Manual', 'Floorplan Type should be Manual');
        
        List<Tab_Context__c> tabContLst = IMCC_TestUtilities.createTabContext(evntTabsLst1[0].Id, 200);
        System.assertEquals(tabContLst.size(),200, 'List size should be 200');
        
        Purchase_Data__c prchseData = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId, accId);      
        
        List<PDF_Floorplan__c> pdfFloorplanLst = IMCC_TestUtilities.createPdfFloorplan(evntTabsLst2[0].id,10,'Group 1');
        
        List<ContentVersion> cvLst = IMCC_TestUtilities.createContentVer(10);      
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cvLst[0].Id];
        
        List<ContentDocumentLink> newFileShareLst = IMCC_TestUtilities.createContentDocLink(testContent.ContentDocumentId, pdfFloorplanLst[0].id, 1);
        
        System.runAs(userObj) {
            Test.startTest();
            List<Event_Tabs__c> lstEvntTab1 = [Select id,Name,Event_Setting__c,Tab_Code__c from Event_Tabs__c where Event_Setting__c =: editionObj[0].Event_Setting__c and Floorplan_Type__c = 'Interactive'];
            if(!lstEvntTab1.isEmpty()){
               IMCC_FloorplanCtrl.fetchBoothDetails(editionObj[0].Edition_Code__c,accId,lstEvntTab1[0].Tab_Code__c); 
            }
            List<Event_Tabs__c> lstEvntTab2 = [Select id,Name,Event_Setting__c,Tab_Code__c from Event_Tabs__c where Event_Setting__c =: editionObj[0].Event_Setting__c and Floorplan_Type__c = 'Manual'];
            if(!lstEvntTab2.isEmpty()){
            IMCC_FloorplanCtrl.fetchBoothDetails(editionObj[0].Edition_Code__c,accId,lstEvntTab2[0].Tab_Code__c);
            }
            IMCC_FloorplanCtrl.fetchManualPdfDetails(pdfFloorplanLst[0].id);
            Test.stopTest();
        }
    }    
    
    @isTest
    public static void testException() {

        IMCC_FloorplanCtrl.fetchBoothDetails(null,null,null); 
        try{ IMCC_FloorplanCtrl.fetchManualPdfDetails(null);}
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }

    }
}