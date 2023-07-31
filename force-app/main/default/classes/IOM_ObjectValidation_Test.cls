/**
* File      :   IOM_ObjectValidation_Test
* Project        : Informa Order Management 
* Created By  :   Suresh(Girikon)
* Created Date  :   28th Dec 2021
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - IOM_ObjectValidation() 
* Last Modified By :
*/
@isTest
public with sharing class IOM_ObjectValidation_Test {

    @isTest
    public static void testPreventAccDel() {
        
        insert new IOM_Application_Bypass__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Account_Deletion__c=false);
        
        Account acc1 = new Account();
        acc1.Name='acc1';
        acc1.BillingCity ='Delhi' ;
        acc1.BillingCountry='india';
        acc1.BillingPostalCode='600075';
        acc1.BillingState='Delhi';
        acc1.IOM_Sync_Status__c = 'Complete';
        acc1.BillingStreet='water well street';              
        insert acc1;

        try{
            delete acc1;
        }catch(DMLexception e){
            system.assert(e.getMessage().contains('You are not allowed to delete Account records!'),'You are not allowed to delete Account records!');                       
        }
    }
    @isTest
    public static void testPreventOppDel() {
        
        insert new IOM_Application_Bypass__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Account_Deletion__c=false);
        
        Account acc1 = new Account();
        acc1.Name='acc1';
        acc1.BillingCity ='Delhi' ;
        acc1.BillingCountry='india';
        acc1.BillingPostalCode='600075';
        acc1.BillingState='Delhi';
        acc1.BillingStreet='water well street';              
        insert acc1;
        
        Opportunity opp = new Opportunity(
            CloseDate =Date.newInstance(2019, 11, 5),
            StageName ='Proposal',
            Name ='TESTOPP',Address_Status__c = 'Valid',
            IOM_Sync_Status__c = 'Complete',
            AccountId=acc1.Id);
        insert opp;

        try{
            delete opp;
        }catch(DMLexception e){
            system.assert(e.getMessage().contains('You are not allowed to delete Opportunity records!'),'You are not allowed to delete Opportunity records!');                       
        }
    }
    @isTest
    public static void testPreventConDel() {
        
        insert new IOM_Application_Bypass__c(SetupOwnerId=UserInfo.getUserId(), Bypass_Account_Deletion__c=false);
        
        Account acc1 = new Account();
        acc1.Name='acc1';
        acc1.BillingCity ='Delhi' ;
        acc1.BillingCountry='india';
        acc1.BillingPostalCode='600075';
        acc1.BillingState='Delhi';
        acc1.BillingStreet='water well street';              
        insert acc1;
        
        Contact oCon1 = new Contact();
        oCon1.FirstName = 'test';
        oCon1.Contact_Type__c = 'Invoice Contact';
        oCon1.LastName = 'ContTest11';
        oCon1.Email = 'abcd1@gmail.com';
        oCon1.AccountId = acc1.Id;
        oCon1.MailingStreet = 'Test1';
        oCon1.IOM_Sync_Status__c = 'Complete';
        oCon1.MailingCity = 'Test1';
        oCon1.MailingState='';
        oCon1.MailingCountry='India';
        oCon1.Phone = '+12345564788'; 
        oCon1.Inactive__c = false;
        oCon1.AssistantPhone = '+12445567788'; 
        oCon1.HomePhone = '+12345567388'; 
        oCon1.MobilePhone = '+12335567788'; 
        oCon1.OtherPhone = '+12346567788';
        insert oCon1;

        try{
            delete oCon1;
        }catch(DMLexception e){
            system.assert(e.getMessage().contains('You are not allowed to delete Contact records!'),'You are not allowed to delete Contact records!');                       
        }
    }
}