/**
* Created       :  Girikon(Arushi [IMCC-1685])
* Created On    :  24/03/2022
* @description  :  As a customer, I would like to view details of the Badge Registration as a tab in the portal.
* Methods          :   getProgressPercent(),getPurchaseData(),setUpdatedValue(),getPurchaseSummary()
* Apex Class       :   IMCC_BadgeRegistrationCTRL 
* Apex Test Class  :   IMCC_BadgeRegistrationCTRL_Test (97%)
**/
@isTest
public class IMCC_BadgeRegistrationCTRL_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    
    public static testMethod void testBadgeRegistrationTest(){
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        Contact con = new Contact();
        User userObj;
        Id contactId;
        Id accId;
        
         System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(250);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
            contactId = contObj[0].Id;
            con = contObj[0];
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
        }        
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
         List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 250);
        Id serviceObjId = serviceObj[0].Id;
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(250);
        Id eveSettingObjId = eveSettingObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting(serviceObjId,docObjId,eveSettingObjId,250);
        Id editionObjId = editionObj[0].Id;
        string editionCode = editionObj[0].Edition_Code__c;
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        cemObj.Completed_Purchase_Summaries__c = 'Badge';
        Update cemObj;
        List<Purchase_Data__c> purchaseDataObj  = IMCC_TestUtilities.createPurchaseData2(cemObj.Id,editionObjId,2);
        Purchase_Summary__c purchaseSum = new Purchase_Summary__c(Purchase_Summary_Type__c = 'Badge',Is_Active__c = TRUE
                                                                  , Event_Setting__c = eveSettingObjId,Order__c = 2);
        Insert purchaseSum;
        
        System.runAs(userObj) {
        Test.startTest();
        IMCC_BadgeRegistrationCTRL.getProgressPercent(accId,editionCode);
        IMCC_BadgeRegistrationCTRL.getPurchaseData(accId,editionCode);
        IMCC_BadgeRegistrationCTRL.setUpdatedValue('Badge',cemObj.Id);
        IMCC_BadgeRegistrationCTRL.getPurchaseSummary(editionCode,accId);
        Test.stopTest();
        }
    }
    
    @isTest
    private static void testForException()
    {
      
        try{IMCC_BadgeRegistrationCTRL.getProgressPercent(null,null);}
        catch(Exception e){
            System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
         } 
        
        try{IMCC_BadgeRegistrationCTRL.getPurchaseSummary(null,null);}
        catch(Exception e){
            System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
         } 
          
    }

}