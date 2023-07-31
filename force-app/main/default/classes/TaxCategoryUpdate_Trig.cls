/**
* File         :   TaxCategoryUpdate_Trig
* Project      :   IE ECOM
* Created Date :   2nd Sept 2022
* Created By   :   Girikon(Ansh)
* Test Class   :  TaxCategoryUpdate_Trig_Test
* ******************************************************************************************************
@description : This class is used to update tax category field on Account Tax Number
*******************************************************************************************************
* Modification log :
*/

public with sharing class TaxCategoryUpdate_Trig implements TriggerInterface_AccountTaxNumber.Runnable{

    /** 
*   @description [Call Interface Class to fetch the new list and old map of Account Tax Number]
*   @param trig [fetch the trigger new list and old map]
*/
    public void run(TriggerInterface_AccountTaxNumber.Trig trig){
        if(trig.isBefore){
            updateTaxCategory(trig);
        }
    }
/**
*   @description Update Tax Category on Account Tax Number
*   @param trig
*/
    public void updateTaxCategory(TriggerInterface_AccountTaxNumber.Trig trig){
        for(Account_Tax_Number__c atn : trig.newList){
            String value;
            String key = atn.Tax_Country__c;
            Tax_Registration_Country__mdt tgn = Tax_Registration_Country__mdt.getInstance(key);
            value = tgn != null ? tgn.SAP_Tax_Type__c :'';

            atn.Tax_Category__c = value;
        }
    }

}