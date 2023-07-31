/**
* Created/Modified By: Girikon(Aishwarya)
* Created On:          13/9/2021
* @description  :      This class covers the code coverage of the class IMCC_AccountSelectionCtrl
* Methods:             loginCtrlDataInsert
* Apex Class:          IMCC_AccountSelectionCtrl(92%) 
**/
@isTest
private class IMCC_AccountSelectionCtrl_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    @isTest
    public static void loginCtrlDataInsert()
    {
        Test.startTest();
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
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEdition(serviceObjId,docObjId,250);
        Id editionObjId = editionObj[0].Id;
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        
        System.runAs(userObj) {            
            IMCC_AccountSelectionCtrl.fetchAccountFromEditionMapping(editionObj[0].Edition_Code__c);
            IMCC_AccountSelectionCtrl.fetchAccounts(editionObj[0].Edition_Code__c);
            IMCC_AccountSelectionCtrl.getEditionDetails(editionObj[0].Edition_Code__c);
            IMCC_AccountSelectionCtrl.fetchEventFromEditionMapping(accId);
            IMCC_AccountSelectionCtrl.fetchEventList(accId);
            IMCC_AccountSelectionCtrl.getEditionName(editionObj[0].Edition_Code__c);        
            
            
        }
        Test.stopTest();
    }    
    
    @isTest
    private static void testForException()
    {
        try{ IMCC_AccountSelectionCtrl.fetchAccountFromEditionMapping(null);  }
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        try{ IMCC_AccountSelectionCtrl.fetchAccounts(null);   }
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }            
        try{IMCC_AccountSelectionCtrl.fetchEventFromEditionMapping(null);}
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        try{ IMCC_AccountSelectionCtrl.fetchEventList(null);} 
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
       
        
    }

}