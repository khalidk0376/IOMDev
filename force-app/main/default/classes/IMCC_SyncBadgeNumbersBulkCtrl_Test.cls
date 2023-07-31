/**
* Created/Modified By: Girikon(Arushi[IMCC-58])
* Created On    :      23/12/2021
* @description  :      This class is used to fetch the badge Allocation records to update the purchase data field with the current badge numbers in bulk
* Methods:             getData
* Apex Class:          IMCC_SyncBadgeNumbersBulkCtrl, IMCC_PurchaseDataTriggerHandler 
* Apex Test Class:     IMCC_SyncBadgeNumbersBulkCtrl_Test(84%), IMCC_PurchaseDataTriggerHandler(86%)
**/

@isTest
private class IMCC_SyncBadgeNumbersBulkCtrl_Test {

    @isTest
    private static void syncBadgeNumbersBulkMethod1(){
        Id contactId;
        Id accId;
        
        List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
        accId = accObj[0].Id;
        List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
        contactId = contObj[0].Id;
        
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id serviceObjId = serviceObj[0].Id;
        List<Badge_Setting__c> badgeSettingObj  = IMCC_TestUtilities.createBadgeSetting(1);
        Id badgeSettingObjId = badgeSettingObj[0].Id;
        List<Badge_Allocation__c> badgeAllocateObj  = IMCC_TestUtilities.createBadgeAllocationSetting(badgeSettingObjId,'Shell Scheme',4);
        badgeAllocateObj[0].User_Type__c = 'Exhibitor';
        badgeAllocateObj[1].User_Type__c = 'Exhibitor';
        badgeAllocateObj[2].User_Type__c = 'Exhibitor';
        badgeAllocateObj[3].User_Type__c = 'Exhibitor';
        update badgeAllocateObj;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithBadgeSetting(serviceObjId,docObjId,badgeSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Purchase_Data__c> purchaseDataObj  = IMCC_TestUtilities.createPurchaseData2(cemObj.Id,editionObjId,2);
        purchaseDataObj[0].User_Type__c = 'Exhibitor';
        purchaseDataObj[1].User_Type__c = 'Exhibitor';
        update purchaseDataObj;
        Test.startTest();
        List<Purchase_Data__c> purchaseDataObj2  = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(2, purchaseDataObj2.size(),'mismatch');
        IMCC_SyncBadgeNumbersBulkCtrl.getData(badgeSettingObjId);
        Test.stopTest();
        
    }
    
    @isTest
    private static void syncBadgeNumbersBulkMethod2(){
        Id contactId;
        Id accId;
        
        List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
        accId = accObj[0].Id;
        List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
        contactId = contObj[0].Id;
        
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id serviceObjId = serviceObj[0].Id;
        List<Stand_Setting__c> standSettingObj = IMCC_TestUtilities.createStandSetting(250);
        Id standSettingObjId = standSettingObj[0].Id;
        
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithStandSetting(serviceObjId,docObjId,standSettingObjId,250,system.today(),system.today());
        Id editionObjId = editionObj[0].Id;
         Test.startTest();
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Purchase_Data__c> booth = IMCC_TestUtilities.createPurchaseData4(cemObj.Id,editionObjId,2);
        List<Contractor_Mapping__c> cmObj = IMCC_TestUtilities.createContractorMappingData(accId,contactId,cemObj.Id,booth[0].Id,'Contractor Nominated',editionObjId,null,1);
        System.assertEquals(1, cmObj.size(),'mismatch');
       
       Test.stopTest();
        
    }
    
    @isTest
    private static void syncBadgeNumbersBulkMethod3(){
        Id contactId;
        Id accId;
        
        List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
        accId = accObj[0].Id;
        List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
        contactId = contObj[0].Id;
        
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id serviceObjId = serviceObj[0].Id;
        List<Badge_Setting__c> badgeSettingObj  = IMCC_TestUtilities.createBadgeSetting(1);
        Id badgeSettingObjId = badgeSettingObj[0].Id;
        List<Badge_Allocation__c> badgeAllocateObj  = IMCC_TestUtilities.createBadgeAllocationSetting(badgeSettingObjId,'Shell Scheme',4);
        badgeAllocateObj[0].User_Type__c = 'Exhibitor';
        badgeAllocateObj[1].User_Type__c = 'Exhibitor';
        badgeAllocateObj[2].User_Type__c = 'Exhibitor';
        badgeAllocateObj[2].Upper__c = null;
        badgeAllocateObj[3].User_Type__c = 'Exhibitor';
        badgeAllocateObj[3].Upper__c = null;
        update badgeAllocateObj;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithBadgeSetting(serviceObjId,docObjId,badgeSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Purchase_Data__c> purchaseDataObj  = IMCC_TestUtilities.createPurchaseData2(cemObj.Id,editionObjId,2);
        purchaseDataObj[0].User_Type__c = 'Exhibitor';
        purchaseDataObj[1].User_Type__c = 'Co-Exhibitor';
        update purchaseDataObj;
        Test.startTest();
        IMCC_SyncBadgeNumbersBulkCtrl.getData(badgeSettingObjId);
        List<Purchase_Data__c> purchaseDataObj2  = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(2, purchaseDataObj2.size(),'mismatch');
        Test.stopTest();
        
    }
    
    @isTest
    private static void syncBadgeNumbersBulkMethod4(){
        Id contactId;
        Id accId;
        
        List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
        accId = accObj[0].Id;
        List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
        contactId = contObj[0].Id;
        
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id serviceObjId = serviceObj[0].Id;
        List<Badge_Setting__c> badgeSettingObj  = IMCC_TestUtilities.createBadgeSetting(1);
        Id badgeSettingObjId = badgeSettingObj[0].Id;
        List<Badge_Allocation__c> badgeAllocateObj  = IMCC_TestUtilities.createBadgeAllocationSetting(badgeSettingObjId,'Shell Scheme',4);
        badgeAllocateObj[0].User_Type__c = 'Exhibitor';
        badgeAllocateObj[1].User_Type__c = 'Exhibitor';
        badgeAllocateObj[2].User_Type__c = 'Exhibitor';
        badgeAllocateObj[2].Upper__c = null;
        badgeAllocateObj[3].User_Type__c = 'Exhibitor';
        badgeAllocateObj[3].Upper__c = null;
        update badgeAllocateObj;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithBadgeSetting(serviceObjId,docObjId,badgeSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Purchase_Data__c> purchaseDataObj  = IMCC_TestUtilities.createPurchaseData2(cemObj.Id,editionObjId,2);
        purchaseDataObj[0].User_Type__c = 'Exhibitor';
        purchaseDataObj[1].User_Type__c = 'Reseller';
        update purchaseDataObj;
        purchaseDataObj[1].User_Type__c = 'Exhibitor';
        purchaseDataObj[1].Addition_Badge_Count__c = null;
        update purchaseDataObj;
        Test.startTest();
        IMCC_SyncBadgeNumbersBulkCtrl.getData(badgeSettingObjId);
        List<Purchase_Data__c> purchaseDataObj2  = [SELECT Id FROM Purchase_Data__c];
        System.assertEquals(2, purchaseDataObj2.size(),'mismatch');
        Test.stopTest();
        
    }
}