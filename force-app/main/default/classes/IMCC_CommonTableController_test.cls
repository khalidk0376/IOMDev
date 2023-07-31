/**
* Created By       :   Girikon(Garima)
* Created On       :   02/11/2021
* @description     :   Test class for IMCC_CommonTableController 
**/

@IsTest
public class IMCC_CommonTableController_test {
  @IsTest
    private static void getTest() {
        Test.startTest();
        Account acc = new Account();
        acc.Name='test acc';        
        insert acc;
        System.assertEquals('test acc',acc.Name,'True');
       
        IMCC_CommonTableController.getGenericObjectRecord('false', 'Form_Data__c','Name,Forms_Permission__r.Form_Allocation__r.Form_Type__c,Forms_Permission__r.Form_Allocation__r.Form__r.Id',10.0,true,false,-1,'Name','asc','Forms_Permission__r.Form_Allocation__r.Form_Status__c =\'Visible\'' ,true);
        IMCC_CommonTableController.getGenericObjectRecord('test', 'Form_Data__c','Name,Forms_Permission__r.Form_Allocation__r.Form_Type__c,Forms_Permission__r.Form_Allocation__r.Form__r.Id',10.0,false,false,0,'Name','asc','' ,true);
        Test.stopTest();
    }
    @isTest
    private Static void runMethods(){
        Test.startTest();
        IMCC_CommonTableController.getGenericObjectRecord('test', 'Form_Data__c','Name,Forms_Permission__r.Form_Allocation__r.Form_Type__c,Forms_Permission__r.Form_Allocation__r.Form__r.Id',10.0,true,false,0,'Name','asc','' ,true);
        IMCC_CommonTableController.getAggregateData2('Id!=null','Form_Data__c','Forms_Permission__r.Form_Allocation__r.Form_Provider__c');
        Test.stopTest();
    }
}