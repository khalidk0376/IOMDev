@isTest
public with sharing class IMCC_StandContractorCtrl_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }

    public static testMethod void testStandContractor(){
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
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
       
        Purchase_Data__c booth = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);
        booth.Contact_Edition_Mapping__c = cemObj.Id;
        Update booth;

        Test.startTest();        
        System.runAs(userObj) {
            IMCC_StandContractorCtrl.getAccountContacts('test');
            Map<String,Object> obMap = IMCC_StandContractorCtrl.setAccountContacts(JSON.serialize(new TempAccount__c(Address__c='test',City__c='noida',Country__c='India',Name='Test Account',State__c='UP',Zip__c='201301')));
            System.assertEquals(true, obMap.containsKey('success'), 'If temp account created then return save account in list');

            TempContact__c tempContact = new TempContact__c();            
            tempContact.Name ='Tets Test';
            tempContact.FirstName__c='Tets';
            tempContact.LastName__c='Test';
            tempContact.MobilePhone__c='(000) 238-1122';
            tempContact.Phone__c='9328820238';
            tempContact.Country_Code__c='+91';
            tempContact.Email__c='test@tets.com';List<String> boothIds = new List<String>();
            
            boothIds.add(booth.Id);
            obMap = IMCC_StandContractorCtrl.setContact(JSON.serialize(tempContact),boothIds,editionObj[0].Edition_Code__c,accId);
            System.assertEquals(true, obMap.containsKey('success'), 'if saved return success key');  
            
        }
        Test.stopTest();
    }

    @IsTest
    static void methodName(){
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

        Test.startTest();
        System.runAs(userObj){
            IMCC_StandContractorCtrl.getCountries();            
            String counrtyCode = IMCC_StandContractorCtrl.getCountryCodeByName('USA');
            System.assertEquals('+1', counrtyCode, 'USA telephone country could +1');            
            counrtyCode = IMCC_StandContractorCtrl.getDepndentCustomVal('IN');
            System.assertEquals('+91', counrtyCode, 'India telephone country could +91');
        }
        Test.stopTest();        
    }
    
    public static testMethod void TestMethod2(){
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
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        Purchase_Data__c booth = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);
        booth.Contact_Edition_Mapping__c = cemObj.Id;
        Update booth;
        
        List<String> boothIds = new List<String>();
        Test.startTest();
            System.runAs(adminUser){
                Set<Id> setConMapIds = new Set<Id>();
                boothIds.add(booth.Id);
                TempContact__c tempCon = IMCC_TestUtilities.createTempContactData();
                List<Contractor_Mapping__c> listConMapping = IMCC_TestUtilities.createConMapping(tempCon.Id, accId, contactId, editionObjId, cemObj.Id, booth.Id);
                tempCon.Contractor_Status__c ='Approved';
                update tempCon;
                setConMapIds.add(listConMapping[0].Id);
                System.assertEquals('Approved', tempCon.Contractor_Status__c, 'Status should be equal to Approved');            
                tempCon.Contractor_Status__c ='Rejected';
                tempCon.Rejection_Reason__c ='Rejection Reason';
                update tempCon;
                System.assertEquals('Rejected', tempCon.Contractor_Status__c, 'Status should be equal to Rejected');
            }
        Test.stopTest();  
        IMCC_StandContractorCtrl.createContactMap(true,boothIds,null,editionObj[0].Edition_Code__c,JSON.serialize(con),accId);      
    }
    
    public static testMethod void TestMethod3(){
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
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        Purchase_Data__c booth = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);
    	booth.Contact_Edition_Mapping__c = cemObj.Id;
        Update booth;    
        
        List<String> boothIds = new List<String>();
        Test.startTest();
            System.runAs(adminUser){
                Set<Id> setConMapIds = new Set<Id>();
                boothIds.add(booth.Id);
                TempContact__c tempCon = IMCC_TestUtilities.createTempContactData();
                List<Contractor_Mapping__c> listConMapping = IMCC_TestUtilities.createConMapping(tempCon.Id, accId, contactId, editionObjId, null, booth.Id);
                tempCon.Contractor_Status__c ='Approved';
                update tempCon;
                setConMapIds.add(listConMapping[0].Id);
                System.assertEquals('Approved', tempCon.Contractor_Status__c, 'Status should be equal to Approved');            
                tempCon.Contractor_Status__c ='Rejected';
                tempCon.Rejection_Reason__c ='Rejection Reason';
                update tempCon;
                System.assertEquals('Rejected', tempCon.Contractor_Status__c, 'Status should be equal to Rejected');
            }
        Test.stopTest();       
        IMCC_StandContractorCtrl.createContactMap(true,boothIds,null,editionObj[0].Edition_Code__c,JSON.serialize(con),accId); 
    }
}