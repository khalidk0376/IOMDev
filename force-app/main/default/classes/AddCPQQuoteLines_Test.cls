/**
* File      	:   AddCPQQuoteLines_Test
* Project       : 	Informa Order Management 
* Created By  	:   Deepak(Girikon)
* Created Date  :   2nd Feb 2022
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - AddCPQQuoteLines,CPQAPIUtils,CPQCallbackCls
* Last Modified By :
*/
@istest
private class AddCPQQuoteLines_Test {
    @testSetup 
    static void testSetupData() 
    {

        // Create Account
        Account oAccount = new Account(Name = 'Expocad Account', CurrencyIsoCode = 'USD',
        Phone = '2423122323');
        oAccount.BillingCity = 'Dubai';
        oAccount.BillingCountry = 'India';
        oAccount.BillingPostalCode = '00000';
        oAccount.Legacy_CRM_Instance__c = 'Penton';
        oAccount.BillingState = 'Delhi';
        oAccount.BillingStreet = 'Dubai Test Centre, Building No. 4 - Happiness St';        
        insert oAccount;

        // Create Contact
        Contact oCon = new Contact(LastName = 'ContTest1', Legacy_CRM_Instance__c = 'Penton', Email = 'test1contact@duptest.com', 
        AccountId = oAccount.Id, MailingStreet = 'Test', MailingCity = 'Test', MailingState = '', 
        MailingCountry = 'India', Phone = '2423122323', AssistantPhone = '2423122323', 
        HomePhone = '2121212121', MobilePhone = '2121212145', OtherPhone = '2154215421');
        insert oCon;

        Series__c oSeries = new Series__c(Name = 'Arab Health', CurrencyISOCode = 'USD');
        insert oSeries;

        /**  Package Product Setup **/
        Id pricebookId = Test.getStandardPricebookId(); // StandardPricebook
        
        Edition__c oEdition = new Edition__c(Name = 'Arab Health Exhibition and Congress Test',
        CurrencyIsoCode = 'USD', Edition_Code__c = 'arabh19',Part_of_Series__c = oSeries.id);
        insert oEdition;

        Product2 childPrd = new Product2(Name = 'Raw Space', Booth_Product_Type__c = 'Space Only', 
        Booth_Type__c = 'esc', Family = 'Booth',SBQQ__SubscriptionTerm__c=1,CurrencyIsoCode = 'USD');
        insert childPrd;    // Child product-1 of main Bundle (Stand Alone Type)

        PricebookEntry pbStndrdPriceP1 = new PricebookEntry(Pricebook2Id = pricebookId, 
        Product2Id = childPrd.Id, UnitPrice = 100, IsActive = true,CurrencyIsoCode = 'USD');
        insert pbStndrdPriceP1;  // Child product-1 Standard Pricebook entry

        Product2 childPrd2 = new Product2(Name = 'Admin Fee',Family = 'Booth', Booth_Type__c = 'esc',SBQQ__SubscriptionTerm__c=1,CurrencyIsoCode = 'USD');
        insert childPrd2;       // Child product-2 of main Bundle (Package Type)

        PricebookEntry pbStndrdPriceP2 = new PricebookEntry(Pricebook2Id = pricebookId, 
        Product2Id = childPrd2.Id, UnitPrice = 100, IsActive = true,CurrencyIsoCode = 'USD');
        insert pbStndrdPriceP2;      // Child product-2 Standard Pricebook entry
        /**  Product Set Up - End  **/

        Opportunity oOpportunity = new Opportunity(Name = 'Expocad Opportunity',
        Default_Edition__c =oEdition.Id ,CloseDate = Date.today(), StageName = 'Proposal', 
        AccountId = oAccount.Id, Billing_Contact__c = oCon.Id, Bill_To_Account__c = oAccount.Id,CurrencyIsoCode = 'USD');
        insert oOpportunity;

        SBQQ__Quote__c oQuote = new SBQQ__Quote__c(CurrencyIsoCode = 'USD', SBQQ__Status__c = 'Quote Sent', 
        SBQQ__Type__c = 'Quote', SBQQ__Opportunity2__c = oOpportunity.Id, SBQQ__Account__c = oAccount.Id, 
        SBQQ__Primary__c = true);
        insert oQuote;
    }

    /** @description : testRest*/
    @isTest
    private static void  testRest(){
        Test.startTest();
        SBQQ__Quote__c qt = [SELECT Id,Name FROM SBQQ__Quote__c LIMIT 1];
        List<Product2> listProduct = [SELECT Id,IM_ProductCode__c FROM Product2];

        List<AddCPQQuoteLines.QuoteLineModelWrapper> quoteLines = new List<AddCPQQuoteLines.QuoteLineModelWrapper>();
        AddCPQQuoteLines.QuoteLineModelWrapper wrap = new AddCPQQuoteLines.QuoteLineModelWrapper();
        wrap.imProductCode = listProduct.get(0).IM_ProductCode__c;
        wrap.quantity = 1;
        wrap.unitPrice = 105;
        wrap.startDate = date.newinstance(2022, 2, 1);
        wrap.endDate = date.newinstance(2022, 2, 28);
        quoteLines.add(wrap);

        wrap = new AddCPQQuoteLines.QuoteLineModelWrapper();
        wrap.imProductCode = listProduct.get(0).IM_ProductCode__c;
        wrap.quantity = 1;
        wrap.unitPrice = 100;
        wrap.startDate = date.newinstance(2022, 3, 1);
        wrap.endDate = date.newinstance(2022, 3, 31);
        quoteLines.add(wrap);

        AddCPQQuoteLines.QuoteModelWrapper wrap2 = new AddCPQQuoteLines.QuoteModelWrapper();
        wrap2.lines = quoteLines;
        wrap2.quoteId = qt.Id;
        wrap2.currencyISOcode = 'USD';
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/insertquotelineitems'; 
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(wrap2)); 
        RestContext.request = req;
        RestContext.response = res;
        
        AddCPQQuoteLines.ResponseData resWrap = AddCPQQuoteLines.addQLI();
        System.assertEquals('Success', resWrap.status, 'Success');
        Test.stopTest();
    }
    
    /** @description : testRestNegative*/
    @isTest
    private static void  testRestNegative(){
        Test.startTest();
        SBQQ__Quote__c qt = [SELECT Id,Name FROM SBQQ__Quote__c LIMIT 1];

        List<AddCPQQuoteLines.QuoteLineModelWrapper> quoteLines = new List<AddCPQQuoteLines.QuoteLineModelWrapper>();
        AddCPQQuoteLines.QuoteLineModelWrapper wrap = new AddCPQQuoteLines.QuoteLineModelWrapper();
        wrap.imProductCode = 'IM-00089';
        wrap.quantity = 1;
        wrap.unitPrice = 105;
        wrap.startDate = date.newinstance(2022, 2, 1);
        wrap.endDate = date.newinstance(2022, 2, 28);
        quoteLines.add(wrap);

        wrap = new AddCPQQuoteLines.QuoteLineModelWrapper();
        wrap.imProductCode = 'IM-00089';
        wrap.quantity = 1;
        wrap.unitPrice = 100;
        wrap.startDate = date.newinstance(2022, 3, 1);
        wrap.endDate = date.newinstance(2022, 3, 31);
        quoteLines.add(wrap);

        AddCPQQuoteLines.QuoteModelWrapper wrap2 = new AddCPQQuoteLines.QuoteModelWrapper();
        wrap2.lines = quoteLines;
        wrap2.quoteId = qt.Id;
        wrap2.currencyISOcode = 'USD';
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/insertquotelineitems'; 
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(wrap2)); 
        RestContext.request = req;
        RestContext.response = res;
        
        AddCPQQuoteLines.ResponseData resWrap = AddCPQQuoteLines.addQLI();
        System.assertEquals('Error', resWrap.status, 'Error');
        try{
            CPQAPIUtils oCPQreader  = new CPQAPIUtils();
            oCPQreader.dynamicGetAllFieldsQuery('Account');
            CPQAPIUtils.ConfigurationModel obj = new CPQAPIUtils.ConfigurationModel();
            System.debug(LoggingLevel.DEBUG, obj);
            oCPQreader.saveQuoteModel(new CPQAPIUtils.QuoteModel());
        }catch(Exception e){System.debug(LoggingLevel.DEBUG,e);}
        Test.stopTest();
    }
}