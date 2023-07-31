/**
* File			: 	AccountFieldUpdate_Trig
* Project       :   GE-CRM-IOM [GECI-763]
* Created By	: 	Girikon(Ansh)
* Created Date	: 	17th Mar 2023
* Test Class    :   
* **************************************************************************************
* @description : Helper class to update account fields
****************************************************************************************
* Modification log :
* 1.
*/
public with sharing class AccountFieldUpdate_Trig implements TriggerInterface_Account.Runnable{
    public static final string ACCOUNTLEGACYCRMINSTANCE = 'AccountLegacyCRMInstance';
    /*
    * @description [Call Interface Class to fetch the new list and old map of account]
    * @param TriggerInterface_Account [fetch the trigger new list and old map]
    */
    public void run(TriggerInterface_Account.Trig trig)
    {
        if(trig.isBefore && (trig.isInsert || trig.isUpdate)) 
        {   
            updateIOMAccount(trig);
        }
    }
    /*
    * @description [method to update account fields]
    * @param TriggerInterface_Account [fetch the trigger new list and old map]
    */
    public static void updateIOMAccount(TriggerInterface_Account.Trig trig){
        String legacyCRMValuesCSV = GlobalConstants.getValue(ACCOUNTLEGACYCRMINSTANCE);

        List<String> legacyCRMValues = legacyCRMValuesCSV.split(',');
		
        Set<Id> accountIdsToUpdate = new Set<Id>();
        for (Account acc : trig.newList) {
            Account oldacc = trig.isUpdate ? trig.oldMap.get(acc.Id):new Account();
            if (String.isNotBlank(acc.Legacy_CRM_Instance__c) && legacyCRMValues.contains(acc.Legacy_CRM_Instance__c)) {
                if((trig.isUpdate && 
                    (acc.Legacy_CRM_Instance__c != oldacc.Legacy_CRM_Instance__c ||
                     acc.Legacy_Account_Id__c != oldacc.Legacy_Account_Id__c))
                     || (trig.isInsert))
                {
                    acc.Account_Number_Text__c = acc.Legacy_Account_Id__c;
                }
            }
        }
    }
}