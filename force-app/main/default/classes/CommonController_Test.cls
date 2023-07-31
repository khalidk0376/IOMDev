/****
Created By    : Sachin CHaudhary
Created On    : Feb 25, 2020
@description  : This is common class for Action Dashboard.
Test Class    : CommonController_Test - 100%
Modified by   : 
*****/
@IsTest
public with sharing class CommonController_Test {
    @isTest static void test1(){
        //@Description: Insert Account.
        Account acc = TestDataFactoryUtils.createAccount();
        acc.CurrencyIsoCode = 'USD';
        insert acc;
        System.assertEquals('Test Account', acc.name,'true');
        Test.startTest();
        CommonController.getUserRecordAccess(Userinfo.getUserId());
        CommonController.getOrderList(acc.Id);
        CommonController.isCreateable('Contact', 'Email');
        CommonController.isUpdateable('Contact', 'Email');
        CommonController.getRecordCount('Opportunity','Name!=Null');
        //CommonController.getDeclinedOptions();
        Test.stopTest();
    }
}