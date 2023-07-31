/*
Created By    : Girikon(Sunil)
Created On    : Sep 06 2019
@description   : This class is used to redirect the user to the customer center community.
Test Class    : 
Modification log :
Modified By    : 
*/
@isTest
private class DefaultCtrl_Test{
    @isTest static void validateCreateContactandMapping(){
        Account acc = new Account ();
        acc.Name = 'TESTACC';
        System.assertEquals('TESTACC', acc.name,'true');
        DefaultCtrl obj = new DefaultCtrl();
        obj.redirectCommunity();
    }  
}