/**
* Created/Modified By: Girikon(Aishwarya)
* Created On:          07/9/2021
* @description  :      This class covers the code coverage of the class IMCC_UserLoginCtrl
* Methods:             loginCtrlDataInsert
* Apex Class:          IMCC_UserLoginCtrl(92%) 
**/

@isTest
private class IMCC_UserLoginCtrl_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;

        Id contactId;
        Id accId;
        User userObj;
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
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEdition(serviceObjId,docObjId,1);
        Id editionObjId = editionObj[0].Id;
        IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
    }

    @isTest
    public static void loginCtrlDataInsert()
    {
        Test.StartTest();
        List<Edition__c> editionObj = [SELECT Id,Edition_Code__c FROM Edition__c];
        User userObj = [SELECT Id,Username FROM User WHERE Email='davidjones@test.com'];
        
        System.runAs(userObj){
            ApexPages.currentPage().getHeaders().put('Host','');
            PageReference pageRef = new PageReference('/IMCC_UserLogin');
            Test.setCurrentPage(pageRef);
            apexpages.currentpage().getparameters().put('edcode','');
            apexpages.currentpage().getparameters().put('reset','1');
            
            IMCC_UserLoginCtrl oLoginCtrl6 = new IMCC_UserLoginCtrl(); 
            oLoginCtrl6.iirislogin();       
            oLoginCtrl6.username = 'Test@testorg.com';
            oLoginCtrl6.password ='Test12345';     
            oLoginCtrl6.login();
            oLoginCtrl6.getOrgId();
            oLoginCtrl6.eventSet = null;
            oLoginCtrl6.eventEditionCode = null;
            oLoginCtrl6.brandingColor = null;
            oLoginCtrl6.imageURL = null;
            
            pageRef = new PageReference('/IMCC_UserLogin?startURL=%2FCustomerProfile%3Feventcode%3DTEV210');
            Test.setCurrentPage(pageRef);
            
            apexpages.currentpage().getparameters().put('er','iunp');
            IMCC_UserLoginCtrl oLoginCtrl = new IMCC_UserLoginCtrl();

            apexpages.currentpage().getparameters().put('er','iufte');
            IMCC_UserLoginCtrl oLoginCtrl1 = new IMCC_UserLoginCtrl();
            System.debug(LoggingLevel.DEBUG, oLoginCtrl1);

            apexpages.currentpage().getparameters().put('er','iu');
            IMCC_UserLoginCtrl oLoginCtrl2 = new IMCC_UserLoginCtrl();
            System.debug(LoggingLevel.DEBUG, oLoginCtrl2);

            apexpages.currentpage().getparameters().put('edcode','');
            IMCC_UserLoginCtrl oLoginCtrl4 = new IMCC_UserLoginCtrl();
            System.debug(LoggingLevel.DEBUG, oLoginCtrl4);

            apexpages.currentpage().getparameters().put('edcode','TEV211');
            IMCC_UserLoginCtrl oLoginCtrl5 = new IMCC_UserLoginCtrl();
            System.debug(LoggingLevel.DEBUG, oLoginCtrl5);

            oLoginCtrl5.getSiteURL();
            System.debug(LoggingLevel.DEBUG, JSON.serialize(userObj));
            oLoginCtrl.username = userObj.Username;
            oLoginCtrl.password ='Test12345';
            System.assertEquals(oLoginCtrl.username, 'davidjones@test.com', 'both values should equal');
            System.assertEquals(oLoginCtrl.password, 'Test12345', 'Password should equal to Test12345');        
            apexpages.currentpage().getparameters().put('edcode',editionObj[0].Edition_Code__c);
            oLoginCtrl.login();
            oLoginCtrl.forgotPassword();
            oLoginCtrl.backToSignIn();
            oLoginCtrl.resetPassword();
            oLoginCtrl.iirislogin();
        }
        Test.stopTest();        
    }   
    
    @isTest
    public static void loginCtrlDataInsert2()
    {
        Test.StartTest();
        List<Edition__c> editionObj = [SELECT Id,Edition_Code__c FROM Edition__c];
        User userObj = [SELECT Id,Username FROM User WHERE Email='davidjones@test.com'];
        
        System.runAs(userObj){
            ApexPages.currentPage().getHeaders().put('Host','');
            PageReference pageRef = new PageReference('/IMCC_UserLogin');
            Test.setCurrentPage(pageRef);
            pageRef = new PageReference('/IMCC_UserLogin?startURL=%2FCustomerProfile%3Feventcode%3DTEV210');
            Test.setCurrentPage(pageRef);
            
            apexpages.currentpage().getparameters().put('er','iunp');
            IMCC_UserLoginCtrl oLoginCtrl = new IMCC_UserLoginCtrl();
            oLoginCtrl.username = userObj.Username+'123';
            oLoginCtrl.password ='Test12345';
            System.assertEquals(oLoginCtrl.username, 'davidjones@test.com123', 'both values should equal');
            System.assertEquals(oLoginCtrl.password, 'Test12345', 'Password should equal to Test12345');        
            apexpages.currentpage().getparameters().put('edcode',editionObj[0].Edition_Code__c);
            oLoginCtrl.login();
            oLoginCtrl.forgotPassword();
            oLoginCtrl.backToSignIn();
            oLoginCtrl.resetPassword();
        }
        Test.stopTest();        
    } 
    
    @isTest
    public static void loginCtrlDataInsert3()
    {
        Test.StartTest();
        List<Edition__c> editionObj = [SELECT Id,Edition_Code__c FROM Edition__c];
        User userObj = [SELECT Id,Username FROM User WHERE Email='davidjones@test.com'];
        delete [Select Id FROM Contact_Edition_Mapping__c];
        
        System.runAs(userObj){
            ApexPages.currentPage().getHeaders().put('Host','');
            PageReference pageRef = new PageReference('/IMCC_UserLogin');
            Test.setCurrentPage(pageRef);
            pageRef = new PageReference('/IMCC_UserLogin?startURL=%2FCustomerProfile%3Feventcode%3DTEV210');
            Test.setCurrentPage(pageRef);
            
            apexpages.currentpage().getparameters().put('er','iunp');
            IMCC_UserLoginCtrl oLoginCtrl = new IMCC_UserLoginCtrl();
            oLoginCtrl.username = userObj.Username;
            oLoginCtrl.password ='Test12345';
            System.assertEquals(oLoginCtrl.username, 'davidjones@test.com', 'both values should equal');
            System.assertEquals(oLoginCtrl.password, 'Test12345', 'Password should equal to Test12345');        
            apexpages.currentpage().getparameters().put('edcode',editionObj[0].Edition_Code__c);
            oLoginCtrl.login();
            oLoginCtrl.forgotPassword();
            oLoginCtrl.backToSignIn();
            oLoginCtrl.username = '';
            oLoginCtrl.resetPassword();
            oLoginCtrl.iirislogin();
        }
        Test.stopTest();        
    }
}