/**
* Created/Modified By: Girikon(Arushi[IMCC-58])
* Created On    :      21/12/2021
* @description  :      This class is used to fetch the badge Allocation records to update the purchase data field with the current badge numbers in bulk
* Methods:             getData
* Apex Class:          IMCC_SyncBadgeNumbersBulkCtrl 
* Apex Test Class:     IMCC_SyncBadgeNumbersBulkCtrl_Test(84%)
**/

public without sharing class IMCC_SyncBadgeNumbersBulkCtrl {

    /**
    * @description Recalculate Badges for purchase Datas 
    * @param badgeSettingId
    */
    @auraEnabled
    public static void getData(Id badgeSettingId){
        try
        {
            List<Purchase_Data__c> listPData = new List<Purchase_Data__c>();
            if(Schema.sObjectType.Purchase_Data__c.isAccessible()){
                listPData = new List<Purchase_Data__c>([SELECT Id,Booth_Product_Type__c,Badge_Allocated__c,Contact_Edition_Mapping__c,Purchase_Status__c,Quantity_Area__c,Transaction_Status__c,User_Type__c,Edition__c FROM Purchase_Data__c WHERE Purchase_Status__c = 'Active' AND Transaction_Status__c ='Active' AND Edition__r.Badge_Setting__c=: badgeSettingId AND Edition__r.Edition_Status__c = 'Confirmed']);
                IMCC_PurchaseDataTriggerHandler.recalculateBadge(listPData,false);
            }
        }
        catch(exception ex){
           throw new AuraHandledException(ex.getMessage());
        }
    }
}