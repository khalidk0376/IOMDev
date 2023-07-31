/**
* File:        AccountRelatedAccountValidation_Test
* Date:        13 jan 2020
* Created By : Girikon(Ashish)
* Apex Class : AccountRelatedAccountValidation
* *************************************************************************
* @description: This test class test the AccountRelatedAccountValidation
* *************************************************************************
* History: 
*/

@isTest
public class AccountRelatedAccountValidation_Test {
    
    @testSetup static void createSetup( ) {
                Account acc = new Account( );
        acc.name              = 'TestAccount';
        acc.BillingStreet     = '456 Zepplin Avenue';
        acc.BillingCity       = 'Las Vegas';
        acc.BillingState      = 'Delhi';
        acc.BillingPostalCode = '110025';
        acc.BillingCountry    = 'India';
        acc.Legacy_CRM_Instance__c = 'Penton';
        acc.Phone             = '1234567890';
        acc.Fax               = '1234567890';
        insert acc;
        
        Contact con = new Contact( );
        con.Email             = 'test.test@gmail.com';
        con.Phone             = '1234567890';
        con.Title             = 'Mr.';
        con.Legacy_CRM_Instance__c = 'Penton';
        con.FirstName         = 'TestFN';
        con.LastName          = 'testLN';
        con.AccountId         = acc.Id;
        con.MailingStreet     = 'TestStreet';
        con.MailingCity       = 'Las Vegas';
        con.MailingPostalCode = '89131';
        con.MailingState      = 'Delhi';
        con.MailingCountry    = 'India';
        con.Fax               = '1234567890';
        insert con;
        
        // Create an Oppty
        Opportunity opp = new Opportunity(           
            CloseDate =Date.newInstance(2019, 11, 5),
            StageName ='Proposal',
            Name ='TESTOPP',  
            AccountId=acc.Id,Bill_To_Account__c=acc.Id,Opportunity_Contact__c=con.Id,Billing_Contact__c=con.Id);
        insert opp;     
    }
    @isTest static void testAccntValidation() 
    {    
        map<Id,Contact> mapCon = new map<Id,Contact>();
         Opportunity opp = Database.query('SELECT Id,Opportunity_Contact__c,Name FROM Opportunity WHERE Name = \'TESTOPP\'');
         System.assertEquals('TESTOPP' , opp.Name, 'true');
        for(Contact con:[select id,AccountId,Email, Phone, Title, Name, FirstName, LastName,MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry, Fax,Address_Verified__c  from Contact where id = : opp.Opportunity_Contact__c])
        {
            mapCon.put(con.AccountId,con);
        } 
        List<Account> aScopeList = new List<Account> ([SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Phone, Fax, blng__BillToContact__c, Tax_Id__c, BillingCountryCode, BillingStateCode FROM Account WHERE ID IN : mapCon.keyset()]); 
        Test.startTest();
        PageReference pg = Page.ValidateBlngContactAccntBlngAdd;
        Test.setCurrentPage( pg );
        pg.getParameters().put( 'Id', String.valueOf(opp.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);            
        AccountRelatedAccountValidationCtrl ctrl = new AccountRelatedAccountValidationCtrl(sc);
        
        Database.BatchableContext     bc;
        AccountRelatedAccountValidationCtrl ctrl2 = new AccountRelatedAccountValidationCtrl(mapCon.keySet(),mapCon,opp.Id);
        Test.setMock(HttpCalloutMock.class, new AccountRelatedAccountValidationMock());
        ctrl.validateAccountBillingAddress();
        ctrl2.execute(bc, aScopeList);
        ctrl2.finish(bc);
        ctrl.validateAccountBillingAddress();
        ctrl.back2opportunity();
        //ctrl.batchProcessId = opp.Id;
        //ctrl.batchStatus ='Start';
        ctrl.batchProcess();
        
        Test.stopTest();
    }
    @isTest static void testAccntValidation2() 
    { 
        Opportunity opp = Database.query('SELECT Id,Opportunity_Contact__c FROM Opportunity WHERE Name = \'TESTOPP\'');
        opp.Opportunity_Contact__c = null;
        update opp;
        System.assertNotEquals(null,opp.id,'opp update failed');
         Test.startTest();
        PageReference pg = Page.ValidateBlngContactAccntBlngAdd;
        Test.setCurrentPage( pg );
        pg.getParameters().put( 'Id', String.valueOf(opp.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);            
        AccountRelatedAccountValidationCtrl ctrl = new AccountRelatedAccountValidationCtrl(sc);
        ctrl.validateAccountBillingAddress();
        Test.stopTest();
    }
    @isTest static void testAccntValidation3() 
    { 
        Opportunity opp = Database.query('SELECT Id,Opportunity_Contact__c FROM Opportunity WHERE Name = \'TESTOPP\'');
        opp.Billing_Contact__c = null;
        update opp;
        System.assertNotEquals(null,opp.id,'opp update failed');
         Test.startTest();
        PageReference pg = Page.ValidateBlngContactAccntBlngAdd;
        Test.setCurrentPage( pg );
        pg.getParameters().put( 'Id', String.valueOf(opp.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);            
        AccountRelatedAccountValidationCtrl ctrl = new AccountRelatedAccountValidationCtrl(sc);
        ctrl.validateAccountBillingAddress();
        Test.stopTest();
    }
}