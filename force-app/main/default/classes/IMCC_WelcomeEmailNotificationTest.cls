/**
* Created/Modified By :(Arushi [IMCC-5307])
* Created On:          07/07/2023 
* @description  :      As a primary and/or secondary admin, I want to be able to trigger an email to the relevant 
                       invited team members. So that they are aware they have been invited to the platform.
* Methods:             adminNotification,teamMemberNotification
* Apex Class:          IMCC_WelcomeEmailNotification
**/
@isTest
public class IMCC_WelcomeEmailNotificationTest {
    
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    
    public static testMethod void cancelNotification(){
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        Contact con = new Contact();
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
            contactId = contObj[0].Id;
            con = contObj[0];
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
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting2(serviceObjId,docObjId,eveSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs2(eveSettingObj[0].Id, 200, 10, null, 'Standard', 'Manage My Task',null);
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        Contact_Edition_Mapping__c cemObj2 = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        cemObj2.Role__c = 'Platform Admin';
        Update cemObj2;
        
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
       
        Purchase_Data__c booth = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);
        booth.Contact_Edition_Mapping__c = cemObj.Id;
        Update booth;
        
        Email_Templates__c adminTemp = IMCC_TestUtilities.createEmailTemplateNotification('Admin Notification – Invitation Cancelled','Invitation is Cancelled for {EVENT}','CANCELINVITE','Hello {NAME} {TEAM MEMBER} {EVENT}');
        Email_Templates__c teamMemTemp = IMCC_TestUtilities.createEmailTemplateNotification('Team Member Notification – Invitation Cancelled','Invitation is Cancelled for {EVENT}','CANCELINVITETEAMMEM','Hello {NAME} {EVENT}{SupportEmail} {HotlineNumber} ');
        Email_Templates__c adminResentTemp = IMCC_TestUtilities.createEmailTemplateNotification('Team Member Notification – Invitation Cancelled','Invitation is Cancelled for {EVENT}','RESENTADMINNOTIFY','Hello {NAME} {TEAM MEMBER} {EVENT}{SupportEmail} {HotlineNumber} ');
        
        string edId = string.valueOf(editionObjId);
        Event_Edition_Email_Template__c eEETLst = IMCC_TestUtilities.createEditionEmailTemplate2(editionObjId,adminTemp.Id,'Admin Notification – Invitation Cancelled','Invitation is Cancelled for {EVENT}','CANCELINVITE','Hello {NAME} {TEAM MEMBER} {EVENT}');
        Event_Edition_Email_Template__c eEETLst1 = IMCC_TestUtilities.createEditionEmailTemplate2(editionObjId,teamMemTemp.Id,'Team Member Notification – Invitation Cancelled','Invitation is Cancelled for {EVENT}','CANCELINVITETEAMMEM','Hello {NAME} {EVENT}{SupportEmail} {HotlineNumber} ');
        Event_Edition_Email_Template__c eEETLst2 = IMCC_TestUtilities.createEditionEmailTemplate2(editionObjId,adminResentTemp.Id,'Admin Notification – Invitation Resent','Invitation is Resent for {EVENT}','CANCELINVITETEAMMEM','Hello {NAME} {TEAM MEMBER} {EVENT}{SupportEmail} {HotlineNumber} ');

        Test.startTest();        
        System.runAs(userObj) {
            Set<Id> teamMemberIds = new Set<Id>();
            teamMemberIds.add(cemObj.Id);
            IMCC_WelcomeEmailNotification.adminNotification(teamMemberIds,cemObj2, 'CANCELINVITE');
            IMCC_WelcomeEmailNotification.adminNotification(teamMemberIds,cemObj2, 'RESENTADMINNOTIFY');
            IMCC_WelcomeEmailNotification.teamMemberNotification(teamMemberIds,'CANCELINVITETEAMMEM','','');
         }
        Test.stopTest();
    }
    
    public static testMethod void resendNotification(){
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        Contact con = new Contact();
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
            contactId = contObj[0].Id;
            con = contObj[0];
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
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting2(serviceObjId,docObjId,eveSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs2(eveSettingObj[0].Id, 200, 10, null, 'Standard', 'Manage My Task',null);
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        Contact_Edition_Mapping__c cemObj2 = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        cemObj2.Role__c = 'Platform Admin';
        Update cemObj2;
        
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
       
        Purchase_Data__c booth = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);
        booth.Contact_Edition_Mapping__c = cemObj.Id;
        Update booth;
        
        Email_Templates__c adminTemp = IMCC_TestUtilities.createEmailTemplateNotification('Admin Notification – Invitation Cancelled','Invitation is Cancelled for {EVENT}','CANCELINVITE','Hello {NAME} {TEAM MEMBER} {EVENT}');
        Email_Templates__c teamMemTemp = IMCC_TestUtilities.createEmailTemplateNotification('Team Member Notification – Invitation Cancelled','Invitation is Cancelled for {EVENT}','CANCELINVITETEAMMEM','Hello {NAME} {EVENT}{SupportEmail} {HotlineNumber} ');
        Email_Templates__c adminResentTemp = IMCC_TestUtilities.createEmailTemplateNotification('Team Member Notification – Invitation Cancelled','Invitation is Cancelled for {EVENT}','RESENTADMINNOTIFY','Hello {NAME} {TEAM MEMBER} {EVENT}{SupportEmail} {HotlineNumber} ');
        
        string edId = string.valueOf(editionObjId);
        Event_Edition_Email_Template__c eEETLst = IMCC_TestUtilities.createEditionEmailTemplate2(editionObjId,adminTemp.Id,'Admin Notification – Invitation Cancelled','Invitation is Cancelled for {EVENT}','CANCELINVITE','Hello {NAME} {TEAM MEMBER} {EVENT}');
        Event_Edition_Email_Template__c eEETLst1 = IMCC_TestUtilities.createEditionEmailTemplate2(editionObjId,teamMemTemp.Id,'Team Member Notification – Invitation Cancelled','Invitation is Cancelled for {EVENT}','CANCELINVITETEAMMEM','Hello {NAME} {EVENT}{SupportEmail} {HotlineNumber} ');
        Event_Edition_Email_Template__c eEETLst2 = IMCC_TestUtilities.createEditionEmailTemplate2(editionObjId,adminResentTemp.Id,'Admin Notification – Invitation Resent','Invitation is Resent for {EVENT}','RESENTADMINNOTIFY','Hello {NAME} {TEAM MEMBER} {EVENT}{SupportEmail} {HotlineNumber} ');

        Test.startTest();        
        System.runAs(userObj) {
            Set<Id> teamMemberIds = new Set<Id>();
            teamMemberIds.add(cemObj.Id);
            IMCC_WelcomeEmailNotification.adminNotification(teamMemberIds,cemObj2, 'RESENTADMINNOTIFY');
          //  IMCC_WelcomeEmailNotification.teamMemberNotification(teamMemberIds,'CANCELINVITETEAMMEM','','');
         }
        Test.stopTest();
    }  

}