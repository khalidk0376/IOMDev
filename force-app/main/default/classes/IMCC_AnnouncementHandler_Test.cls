/**
* Created By        :  Girikon(Arushi[IMCC-2026],[IMCC-4300])
* Created On        :  06/4/2022
* @description      :   As an Ops user, I should be able to redirect to internal tab links in the portal from within the announcement description
* Apex Test Class   :   IMCC_AnnouncementHandler,IMCC_AnnouncementTrig
**/
@IsTest
public class IMCC_AnnouncementHandler_Test {
    public static testMethod void testAnnouncement(){
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
        editionObj[0].Company_Profile_Submission_Due_Date__c = System.Today();
        Update editionObj[0];
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        
        cemObj.Completed_Purchase_Summaries__c = 'Badge';
        update cemObj;
        
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        Tab_Group__c tabGroup = new Tab_Group__c(Sequence__c = 4,Type__c = 'Multiple',Display_Always__c = true);
        insert tabGroup;
        Event_Tabs__c eveTab = new Event_Tabs__c(Event_Setting__c = eveSettingObjId, Sequence__c = 999, Tab_Type__c = 'Standard',Tab_Group__c = tabGroup.Id,Standard_Tab_Type__c = 'Badge Registration');
        Insert eveTab;
        Purchase_Data__c booth = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);        
        Test.startTest();
        Announcement__c announcement = IMCC_TestUtilities.createAnnouncementData2(editionObjId,eveTab.Id);
        List<Tab_User_Type__c> tabUserLst = IMCC_TestUtilities.createTabUserTypeForAnnouncement(announcement.Id,'Exhibitor');
        System.assertEquals(tabUserLst.Size(),2, 'Tab User List size should be 5');
        
        Test.stopTest();
        //Purchase_Summary__c ps = IMCC_TestUtilities.createPurchaseSummary(eveSettingObjId,tabUserLst[0].Id);
        
        
    }     

}