@isTest
public class IMCC_ContractorMappingTrigHandler_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
        
        // Setup Test Data 
        //User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        Contact con = new Contact();
        User userObj;
        Id contactId;
        Id contact2Id;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(250);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
            contactId = contObj[0].Id;
            contact2Id = contObj[1].Id;
            con = contObj[0];
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
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting2(serviceObjId,docObjId,eveSettingObjId,2);
        Id editionObjId = editionObj[0].Id;
        IMCC_TestUtilities.createEventTabs(eveSettingObjId,1,10,null,'Standard','Stand Contractors',null);
        IMCC_TestUtilities.createEventTabs(eveSettingObjId,1,20,null,'Standard','Stand Design',null);
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        IMCC_TestUtilities.createContactEditionMapping(contact2Id,accId,editionObjId);
        IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        
        List<Purchase_Data__c> boothObj = IMCC_TestUtilities.createPurchaseData4(cemObj.Id,editionObjId,1);
        Id boothObjId = boothObj[0].Id;
        IMCC_TestUtilities.createContractorMappingData(accId,contactId,cemObj.Id,boothObjId,'Contractor Nominated',editionObjId,'',1);
        
        List<Email_Templates__c> listEmailTemp = IMCC_TestUtilities.createEmailTemplate();
        Map<String,Email_Template_Types_Mapping__mdt> mapETTTM = Trig_UpdateStatusOnFormData_Handler.getEmailTemplateTypesByModule('Stand Contractor');
        List<String> codes = new List<String>();
        List<String> listEmailTypes = new List<String>();
        for(String s : mapETTTM.keySet()){
            codes.add(mapETTTM.get(s).Email_Template_Code__c);
            listEmailTypes.add('Email:'+s);
        }
        IMCC_TestUtilities.createEditionEmailTemplate(editionObjId,listEmailTemp[0].Id,codes);
    }
    
    @isTest
    public static void testContractorMapping(){
        List<Contractor_Mapping__c> cmObj = [SELECT Id,Is_Self_Managed__c,Contractor_Status__c FROM Contractor_Mapping__c];
        User userObj = [SELECT Id FROM User WHERE Profile.Name='IM Customer Community Login User' AND Email='davidjones@test.com' LIMIT 1];
        Test.startTest();
        System.runAs(userObj) {
            cmObj[0].Contractor_Status__c = 'Contractor Accepted Nomination';
            cmObj[0].Is_Self_Managed__c = false;
            update cmObj[0];
            cmObj[0].Contractor_Status__c = 'Contractor Declined Nomination';
            update cmObj[0];
            System.assertEquals('Contractor Declined Nomination', cmObj[0].Contractor_Status__c,'Status Mismatch');
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testContractorMapping2(){
        List<Contractor_Mapping__c> cmObj = [SELECT Id,Is_Self_Managed__c,Contractor_Status__c FROM Contractor_Mapping__c];
        Test.startTest();
        cmObj[0].Contractor_Status__c = 'New Contractor Nomination In Review';
        update cmObj[0];
        cmObj[0].Contractor_Status__c = 'Contractor Nominated';
        update cmObj[0];
        cmObj[0].Contractor_Status__c = 'New Contractor Nomination In Review';
        update cmObj[0];
        cmObj[0].Contractor_Status__c = 'New Contractor Nomination Rejected';
        update cmObj[0];
        System.assertEquals('New Contractor Nomination Rejected', cmObj[0].Contractor_Status__c,'Status Mismatch');
        Test.stopTest();
    }
    
    @isTest
    public static void testContractorMapping3(){
        List<Contractor_Mapping__c> cmObj = [SELECT Id,Is_Self_Managed__c,Contractor_Status__c FROM Contractor_Mapping__c];
        Test.startTest();
        cmObj[0].Contractor_Status__c = 'Permission to Build';
        update cmObj[0];
        cmObj[0].Contractor_Status__c = 'In Review';
        update cmObj[0];
        cmObj[0].Contractor_Status__c = 'Pending Sales Approval';
        update cmObj[0];
        cmObj[0].Contractor_Status__c = 'Stand Design Rejected/Incomplete';
        Stand_Detail__c standDetail = new Stand_Detail__c();
        standDetail.Contractor_Mapping__c = cmObj[0].Id;
        standDetail.Stand_Detail_Status__c='In Progress';
        standDetail.Current_Step__c='1';
        IMCC_StandDesignSubmissionCtrl.saveStandDetail(standDetail);
        update cmObj[0];
        cmObj[0].Contractor_Status__c = 'Stand Design Resubmitted';
        update cmObj[0];
        cmObj[0].Contractor_Status__c = 'Pending Venue Approval';
        update cmObj[0];
        cmObj[0].Contractor_Status__c = 'Tentative Approval';
        update cmObj[0];
        cmObj[0].Contractor_Status__c = 'Cancelled';
        update cmObj[0];
        System.assertEquals('Cancelled', cmObj[0].Contractor_Status__c,'Status Mismatch');
        Test.stopTest();
    }
}