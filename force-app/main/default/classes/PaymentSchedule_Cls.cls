/**
* Project:      Greenfield
* Date:         11/13/2019
* Created By:   Prashant Choudhary
* Test Class:   UpdateCustomBillingSchedule_Trig_Test (94%)
* *************************************************************************
* @description :  Class for Lightning component "PaymentSchedule" on Opportunity .
* *************************************************************************
* Modification log :
* 1. Girikon (Ashish)  [11 Feb 2022 (IOM-839)] ERP Payment Term Code and additional Tax details to be sent to OrderHub
*/

public with sharing class PaymentSchedule_Cls {
    /**
    * @description   This method is used get Payment Schedule Options
    * @param  oppId Opportunity Id
    * @return  List of Options
    */
    @AuraEnabled 
    public static list<String> getPaymentPicklistValues(String oppId)
    {
       Set<String> options = new Set<String>();
        //    options.add('None');
       
        Schema.DescribeFieldResult fieldResult = Opportunity.Payment_Schedule__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.add(p.getLabel());
        }
        /*
        for(Payment_Term_Code__c ptc : [SELECT Id,Payment_Split_Percentage__c FROM Payment_Term_Code__c WHERE Edition__c IN (SELECT Default_Edition__c FROM Opportunity WHERE Id =:oppId) WITH SECURITY_ENFORCED])s
        {
            options.add(ptc.Payment_Split_Percentage__c);
        }*/
        return new List<String>(options);
    }
    /**
    * @description   This method is used get All Opportunity Fileds
    * @param  recordIdget Opportunity Id
    * @return  Opportunity Record
    */
    @AuraEnabled
    public static Opportunity getallDataRecord(String recordIdget){
        List<Opportunity> listOpportunity = [SELECT id ,Custom_Payment__c,Start_Date__c,Payment_Schedule__c,Total_No_of_payment__c,Milestone_1_Delivery_Date__c,Milestone_2_Delivery_Date__c,Milestone_3_Delivery_Date__c,Milestone_4_Delivery_Date__c ,Milestone_5_Delivery_Date__c ,Milestone_6_Delivery_Date__c, Milestone_7_Delivery_Date__c ,  Milestone_8_Delivery_Date__c, Milestone_9_Delivery_Date__c,Milestone_10_Delivery_Date__c ,Milestone_11_Delivery_Date__c ,Milestone_12_Delivery_Date__c, Milestone_1_Amount__c,Milestone_2_Amount__c,Milestone_3_Amount__c,Milestone_4_Amount__c, Milestone_5_Amount__c,Milestone_6_Amount__c,Milestone_7_Amount__c,Milestone_8_Amount__c,Milestone_9_Amount__c,Milestone_10_Amount__c,Milestone_11_Amount__c,Milestone_12_Amount__c, Amount,CurrencyIsoCode, AccountId, Account.One_Invoice_Per_Contract__c, Default_Edition__c, Default_Edition__r.One_Invoice_Per_Contract__c FROM Opportunity WHERE Id =:recordIdget WITH SECURITY_ENFORCED LIMIT 1];
        if(listOpportunity.size() > 0){
            return listOpportunity[0];
        } else {
            return null;
        }
    }
    /**
    * @description   This method is used Save Payment Schedules On Opportunity
    * @param  fields Opportunity fields
    */
    @AuraEnabled
    public static void saveData (Opportunity fields){
        if(fields != null){
            Opportunity opp = new Opportunity();
            opp = fields;
            opp.Payment_Schedule__c = (opp.Payment_Schedule__c  == 'None') ? null : opp.Payment_Schedule__c;
            update fields;
        }
    }    
}