/**
* Created/Modified By :(Arushi)
* Created On:          21/01/2022
* Modified By :(Arushi)
* Created On:          21/01/2022
* @description  :      As a Customer , I Should be able to see the Stand design tab only if I'm an onsite exhibitor(Exhibitor with a booth) so that I can complete my stand submission process on time.
* Methods:             getTabContext,getActivePHDatas
* Apex Class:          IMCCStandDesignCTRL(96%) 
**/
@IsTest
public class IMCCStandDesignCTRL_Test {
   @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }

    public static testMethod void testgetData(){
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
        List<Stand_Setting__c> standSettingObj = IMCC_TestUtilities.createStandSetting(250);
        Id standSettingObjId = standSettingObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithStandSetting(serviceObjId,docObjId,standSettingObjId,250,system.today(),system.today());
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        
        List<Purchase_Data__c> booth = IMCC_TestUtilities.createPurchaseData4(cemObj.Id,editionObjId,1);
        List<Contractor_Mapping__c> cmObj = IMCC_TestUtilities.createContractorMappingData(accId,contactId,cemObj.Id,booth[0].Id,'Contractor Nominated',editionObjId,null,1);
        
        System.runAs(userObj) {
            Test.startTest();
            List<IMCCStandDesignCTRL.wrapperlist> wrap = new List<IMCCStandDesignCTRL.wrapperlist>();
            IMCCStandDesignCTRL.getActivePHDatas(accId,editionObj[0].Edition_Code__c);
            Test.stopTest();
        }
    }      
    
    public static testMethod void testgetData2(){
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
        List<Stand_Setting__c> standSettingObj = IMCC_TestUtilities.createStandSetting(250);
        Id standSettingObjId = standSettingObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithStandSetting(serviceObjId,docObjId,standSettingObjId,250,system.today(),system.today());
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        
        List<Purchase_Data__c> booth = IMCC_TestUtilities.createPurchaseData4(cemObj.Id,editionObjId,1);
        
        System.runAs(userObj) {
            Test.startTest();
            List<IMCCStandDesignCTRL.wrapperlist> wrap = new List<IMCCStandDesignCTRL.wrapperlist>();
            IMCCStandDesignCTRL.getActivePHDatas(accId,editionObj[0].Edition_Code__c);
            IMCCStandDesignCTRL.buildOwnStandContactorMap(booth[0].Id,editionObj[0].Edition_Code__c,accId);
            Test.stopTest();
        }
    }   
}