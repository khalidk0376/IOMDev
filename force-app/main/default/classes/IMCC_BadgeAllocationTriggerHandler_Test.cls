/**
* Created By     :  Girikon(Shiv[IMCC-4279])
* Created On     :  05/09/2022
* @description   :  Test Class for cover code coverage of IMCC_BadgeAllocationTriggerHandler(100%),IMCC_BadgeAllocation_Trig(100%).
* Apex Class     :  IMCC_BadgeAllocationTriggerHandler(100%),IMCC_BadgeAllocation_Trig(100%)
**/

@isTest
private class IMCC_BadgeAllocationTriggerHandler_Test {
    
    @isTest
    private static void iMCCBadgeAllocationTriggerHandlerMethod(){
        Test.startTest();
        
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=false,Before_Update__c=false,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_BadgeAllocation_Trig', triggerConfiguration);

        List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
        Id accId = accObj[0].Id;
        List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
        Id contactId = contObj[0].Id;
        
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id serviceObjId = serviceObj[0].Id;
        List<Badge_Setting__c> badgeSettingObj  = IMCC_TestUtilities.createBadgeSetting(1);
        Id badgeSettingObjId = badgeSettingObj[0].Id;       
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithBadgeSetting(serviceObjId,docObjId,badgeSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Purchase_Data__c> purchaseDataObj  = IMCC_TestUtilities.createPurchaseData2(cemObj.Id,editionObjId,2);
        purchaseDataObj[0].User_Type__c = 'Exhibitor';
        purchaseDataObj[1].User_Type__c = 'Exhibitor';
        update purchaseDataObj;
        
        List<Badge_Allocation__c> badgeAllocateObj  = IMCC_TestUtilities.createBadgeAllocationSetting(badgeSettingObjId,'Shell Scheme',4);
        badgeAllocateObj[0].User_Type__c = 'Exhibitor';
        badgeAllocateObj[0].Unlimited_Badges__c = true;
        badgeAllocateObj[1].User_Type__c = 'Exhibitor';
        badgeAllocateObj[1].Unlimited_Badges__c = true;
        update badgeAllocateObj;
        
        System.assertEquals(True, badgeAllocateObj[1].Unlimited_Badges__c, 'Unlimited badge checkbox not updated');
        Test.stopTest();
    }
    
    @isTest
    private static void iMCCBadgeAllocationTriggerHandlerMethod2(){
        Test.startTest();
        
        Triggers_Configuration__mdt triggerConfiguration = new Triggers_Configuration__mdt(Before_Insert__c=false,Before_Update__c=false,After_Insert__c=true,After_Update__c=true);
        IMCC_UtilityMethods.mapTriggerConfiguration.put('IMCC_BadgeAllocation_Trig', triggerConfiguration);

        List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
        Id accId = accObj[0].Id;
        List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
        Id contactId = contObj[0].Id;
        
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id serviceObjId = serviceObj[0].Id;
        List<Badge_Setting__c> badgeSettingObj  = IMCC_TestUtilities.createBadgeSetting(1);
        Id badgeSettingObjId = badgeSettingObj[0].Id;       
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithBadgeSetting(serviceObjId,docObjId,badgeSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Purchase_Data__c> purchaseDataObj  = IMCC_TestUtilities.createPurchaseData2(cemObj.Id,editionObjId,2);
        purchaseDataObj[0].User_Type__c = 'Exhibitor';
        purchaseDataObj[1].User_Type__c = 'Exhibitor';
        update purchaseDataObj;
        
        List<Badge_Allocation__c> badgeAllocateObj  = IMCC_TestUtilities.createBadgeAllocationSetting(badgeSettingObjId,'Shell Scheme',4);
        badgeAllocateObj[0].User_Type__c = 'Exhibitor';
        badgeAllocateObj[0].Unlimited_Badges__c = true;
        badgeAllocateObj[1].User_Type__c = 'Exhibitor';
        badgeAllocateObj[1].Unlimited_Badges__c = true;
        badgeAllocateObj[1].Upper__c = null;
        update badgeAllocateObj;
        
        System.assertEquals(True, badgeAllocateObj[1].Unlimited_Badges__c, 'Unlimited badge checkbox not updated');
        Test.stopTest();
    }
}