/**
 * Created By   :  Girikon(Aishwarya)
 * Created On   :  21/03/2022
 * @description : This test class covers the apex class : IMCC_LiveChatCtrl
 * Apex Class   : IMCC_LiveChatCtrl (100%)
 
 * Modification Log-----
 * Modified by : Girikon(Garima Gupta)
 * Modified Date : 8th Aug 2022 (IMCC-3625)
**/
@isTest
private class IMCC_LiveChatCtrl_Test
{
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
        
        Customer_Services_Team__c chatSupport = IMCC_TestUtilities.createChatSupport();
        Edition__c edcode = IMCC_TestUtilities.createEdition(serviceObjId,docObjId,eveSettingObjId,chatSupport.Id);
        
        IMCC_TestUtilities.createContactEditionMapping(contactId,accId,edcode.Id);
    }
    
    @isTest
    private static void testLiveChat()  
    {
        List<Account> listAcc = [SELECT Id FROM Account LIMIT 1];
        List<Contact> listCon = [SELECT Id,Name,Email FROM Contact LIMIT 1];
        List<Edition__c> listEdt = [SELECT Id, Edition_Code__c FROM Edition__c LIMIT 1];
        User userOBJ = [SELECT Id FROM User WHERE ContactId!=null AND IsActive=true ORDER BY CreatedDate DESC LIMIT 1];
        
        Test.StartTest();
        
        PageReference pageRef = Page.IMCC_Live_Chat;
        pageRef.getHeaders().put('referer','https://servcloud-globalexhibitions.cs24.force.com/IMCC/apex/IMCC_AuthorizationErrorPage');
        Test.setCurrentPageReference(pageRef);
        IMCC_LiveChatCtrl ctr = new IMCC_LiveChatCtrl();
        
        pageRef = Page.IMCC_Live_Chat;
        pageRef.getHeaders().put('referer','https://servcloud-globalexhibitions.cs24.force.com/IMCC/apex/IMCC_AuthorizationErrorPage?edcode='+listEdt[0].Edition_Code__c);
        Test.setCurrentPageReference(pageRef);
        ctr = new IMCC_LiveChatCtrl();
        
        pageRef = Page.IMCC_Live_Chat;
        pageRef.getHeaders().put('referer','https://servcloud-globalexhibitions.cs24.force.com/IMCC/apex/IMCC_AuthorizationErrorPage?accId='+listAcc[0].Id);
        Test.setCurrentPageReference(pageRef);
        ctr = new IMCC_LiveChatCtrl();
         
        System.runAs(userOBJ){
            pageRef = Page.IMCC_Live_Chat;
            pageRef.getHeaders().put('referer','https://servcloud-globalexhibitions.cs24.force.com/IMCC/apex/IMCC_AuthorizationErrorPage');
            Test.setCurrentPageReference(pageRef);
            ctr = new IMCC_LiveChatCtrl();
            
            pageRef = Page.IMCC_Live_Chat;
            pageRef.getHeaders().put('referer','https://servcloud-globalexhibitions.cs24.force.com/IMCC/apex/IMCC_AuthorizationErrorPage?edcode='+listEdt[0].Edition_Code__c);
            Test.setCurrentPageReference(pageRef);
            ctr = new IMCC_LiveChatCtrl();
            
            pageRef = Page.IMCC_Live_Chat;
            pageRef.getHeaders().put('referer','https://servcloud-globalexhibitions.cs24.force.com/IMCC/apex/IMCC_AuthorizationErrorPage?accId='+listAcc[0].Id);
            Test.setCurrentPageReference(pageRef);
            ctr = new IMCC_LiveChatCtrl();
            
            pageRef = Page.IMCC_Live_Chat;
            pageRef.getHeaders().put('referer','https://servcloud-globalexhibitions.cs24.force.com/IMCC/apex/IMCC_AuthorizationErrorPage?ErrorDescription=nu:'+listCon[0].Email);
            Test.setCurrentPageReference(pageRef);
            ctr = new IMCC_LiveChatCtrl();
            System.assertEquals('firstname@test.com0', ctr.contactEmail, 'Email Not Same.');
            
            ctr.editionId = listEdt[0].Id;
            ctr.eventSelected();
        }
        Test.StopTest();
    }
}