/**
* Created/Modified By: Girikon(Garima)
* Created On:          22/10/2021
* @description  :      This class covers the code coverage of the class IMCC_FAQCtrl
* Methods:             IMCC_FAQCtrl,quesAnsDataInsert
* Apex Class:          IMCC_FAQCtrl(91%) 
**/

@isTest
private class IMCC_FAQCtrl_Test {
   @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    public static testMethod void quesAnsDataInsert()
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
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,1,2,'Header and 2 Column','Standard','FAQ',null);
        System.assertEquals(evntTabsLst[0].Standard_Tab_Type__c,'FAQ', 'Standard Tab Type should be FAQ');   
        
        List<Q_s_A_s_How_To__c> quesAnsLst1 = IMCC_TestUtilities.createQuesAnsHowTo(evntTabsLst[0].Id,'FAQ',5);
        System.assertEquals(quesAnsLst1.size(),5, 'List size should be 5'); 
        
        List<Q_s_A_s_How_To__c> quesAnsLst2 = IMCC_TestUtilities.createQuesAnsHowTo(evntTabsLst[0].Id,'How to',5);
        System.assertEquals(quesAnsLst2.size(),5, 'List size should be 5');  
        
        List<ContentVersion> cvLst = IMCC_TestUtilities.createContentVer(10);      
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cvLst[0].Id];
        
        List<ContentDocumentLink> newFileShareLst = IMCC_TestUtilities.createContentDocLink(testContent.ContentDocumentId, quesAnsLst2[0].id, 1);
        
        System.runAs(userObj) {
            Test.startTest();
            List<Event_Tabs__c> lstEvntTab = [Select id,Name,Event_Setting__c,Tab_Code__c from Event_Tabs__c where Event_Setting__c =: eveSettingObjId];
            if(!lstEvntTab.isEmpty()){
                IMCC_FAQCtrl.fetchQuesAnsDetails(editionObj[0].Edition_Code__c,accId,lstEvntTab[0].Tab_Code__c);
                IMCC_FAQCtrl.fetchHowToDetails(editionObj[0].Edition_Code__c,accId,lstEvntTab[0].Tab_Code__c);
            }
            IMCC_FAQCtrl.fetchContentVerId(quesAnsLst2[0].id);
            Test.stopTest();
        }
    }    

    @isTest
    public static void testException () {

        IMCC_FAQCtrl.fetchQuesAnsDetails(null,null,null);
        IMCC_FAQCtrl.fetchHowToDetails(null,null,null);
        try{ IMCC_FAQCtrl.fetchContentVerId(null);}
        catch(Exception e){
            System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
         }
    }
 }