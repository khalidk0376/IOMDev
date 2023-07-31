/**
* Created/Modified By: Girikon(Arushi[IMCC-59])
* Created On    :      28/12/2021
* @description  :      This class is used to allocate the additional badges to the given Edition and to the related purchase data records 
* Methods:             getData
* Apex Class:          IMCC_AdditionBAdgesOnEvent 
* Apex Test Class:     IMCC_AdditionBAdgesOnEvent_Test(85%)
**/

@isTest
public class IMCC_AdditionBAdgesOnEvent_Test {
  public static testMethod void IMCC_SyncBadgeNumbersBulkCtrlTest(){
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
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithBadgeSetting(serviceObjId,docObjId,badgeSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Purchase_Data__c> purchaseDataObj  = IMCC_TestUtilities.createPurchaseData2(cemObj.Id,editionObjId,2);
        
        Test.startTest();
        IMCC_AdditionBAdgesOnEvent.getEditionData(editionObjId, 5);
        Test.stopTest();
        
    }
}