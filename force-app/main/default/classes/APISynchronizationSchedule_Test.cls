/**
* File         :   APISynchronizationSchedule_Test 
* Project      :   Order & Billing Plateform
* Created Date :   31 march 2023
* Created By   :   Girikon(Deepak)
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - APISynchronizationSchedule(100%)
* Last Modified By :
*/
@isTest
private class APISynchronizationSchedule_Test {
    private static Date[] cutOffDatesOppty = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
    private static Date[] cutOffDatesEdition = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
    private static Decimal[] cutOffPercentagesOppty = new Decimal[]{25,25,25,25};
    private static Decimal[] cutOffPercentagesEdition = new Decimal[]{25,25,25,25};
    private static  String nbrOfTransactionApiName='Total_No_of_payment__c';
    private static String paymentTermApiNameEdition = 'Invoice_to_be_issued_before__c';
    private static  String billingSchedulesApiNameOppty='Payment_Schedule__c';

    // Setting up the database for the test
    @testSetup 
    static void setup() 
    {
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Integer maxTransactionsforOppty = 12;
        Integer maxTransactionsforEdition = 4;
        String billingSchedulesValue='25-25-25-25';
        String mileDelDateApiNamePart1='Milestone_';
        String mileDelPercentApiNamePart1='Milestone_';
        String mileDelDateApiNamePart2='_Delivery_Date__c';
        String mileDelPercentApiNamePart2='_Percent__c';
        // String mileDelDateQuerypart='';
        // String mileDelPercentQuerypart='';
        String billingSchedulesApiNameEdition='Payment_Schedule__c';
        
        // cut Off dates field Api name to construct the query part
        // String cutOffDatesApiNameQuerypart ='';
        // cut Off Percentages field Api name to construct the query part
        // String cutOffPercentageQuerypart ='';
        String cutOffApiName='CutoffDate_';
        
        // Trigger Record 
        //Create Trigger test record 
        Trigger__c trig = new Trigger__c(Name = 'ActivateOrderAfterCalculate_Trig' , Trigger_Name_Unique__c='ActivateOrderAfterCalculate_Trig',Enabled__c=true,Object__c='Order',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,Before_Update__c=true);
        Insert trig;

        // Create an account
        // Account acc = new Account(name='TESTACC',Payment_Term__c='Net 10');
        Account acc = new Account ();
        acc.Name = 'TESTACC';
        acc.currencyisocode='USD';
        acc.BillingStreet ='street2';
        acc.BillingCity='test';
        acc.BillingCity='Alaska';
        acc.BillingState='tamil nadu';
        acc.BillingCountryCode='IN';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.Payment_Term__c='Net 10';
        insert acc;

        // setup the Custom Settings
        TestDataFactory.insertBillingCustomSettings();
        
        blng__LegalEntity__c billingLegalEntity = TestDataFactory.setupLegalEntity();
        
        blng__RevenueRecognitionRule__c revRecRule = TestDataFactory.setupRevRec(billingLegalEntity.Id);
        
        blng__BillingRule__c billingRule = TestDataFactory.setupBillingRule(billingLegalEntity.Id);
        
        blng__TaxRule__c taxRule = TestDataFactory.setupTaxRule(billingLegalEntity.Id);
        
        // create the product 
        Product2 product = new Product2();
        product = TestDataFactory.createProduct2( billingRule, taxRule,  revRecRule);
        
        // create the PricebookEntry 
        PricebookEntry priceBookEntry1 = TestDataFactory.createPricebookEntry(standardPricebookId,product.Id);
        
        
        // create the product 
        Product2 product2 = new Product2();
        product2 = TestDataFactory.createProduct2( billingRule, taxRule,  revRecRule);
        
        // create the PricebookEntry 
        PricebookEntry priceBookEntry2 = TestDataFactory.createPricebookEntry(standardPricebookId,product2.Id);
        
        //Insert Series
        Series__c seriesObj = new Series__c();
        seriesObj.Name = 'testSeries';
        seriesObj.Status__c = 'Active';
        seriesObj.Legal_Entity__c = billingLegalEntity.Id;
        insert seriesObj;

        // create list of edition to be used on the quote
        List<Edition__c> listOfEditions = new List<Edition__c>();
        Edition__c edition = new Edition__c();
        for(Integer i=0;i<2;i++)
        {
            edition =  new Edition__c(Invoice_to_be_issued_before__c='30');
            edition.Name = 'testEdition'+i;
            edition.Part_of_Series__c = seriesObj.Id;
            edition.Order_Creation__c = false;
            edition.Order_Activation__c = true;
            edition.Contract_Creation__c = true;
            edition.Invoice_Creation__c = true;
            edition.External_Tax_System__c = GlobalConstants.ONESOURCE;
            edition.External_Relationship__c = true; 
            for(Integer j=0;j<maxTransactionsforEdition;j++)
            {
                if(j==0)
                {
                    edition.put(cutOffApiName+'_c',cutOffDatesEdition[j]);
                }else
                {
                    edition.put(cutOffApiName+j+'__c',cutOffDatesEdition[j]);
                }
                edition.put(billingSchedulesApiNameEdition,billingSchedulesValue);
                edition.put(paymentTermApiNameEdition,'30');
            }
            listOfEditions.add(edition);
        }
        insert listOfEditions;
        
        // Create an Oppty
        Opportunity opp = new Opportunity( 
            Pricebook2Id =standardPricebookId,
            CloseDate =Date.newInstance(2019, 11, 5),
            StageName ='Proposal',
            Default_Edition__c=listOfEditions[0].Id,
            Name ='TESTOPP',Address_Status__c = 'Valid',  
            AccountId=acc.Id,
            Bill_To_Account__c =acc.Id);
        
        // set the cutOff dates to the Oppty
        for(Integer i = 1 ; i<= cutOffDatesOppty.size();i++){
            opp.put(mileDelDateApiNamePart1+i+mileDelDateApiNamePart2,cutOffDatesOppty[i-1]);
            opp.put(mileDelPercentApiNamePart1+i+mileDelPercentApiNamePart2,cutOffPercentagesOppty[i-1]);
        }

        insert opp;
        
        // create the quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote = TestDataFactory.buildTestSFCPQQuote('TESTQUOTECITY',opp.Id, acc.Id, standardPricebookId, 'Quote',listOfEditions.get(0));
        quote.SBQQ__Primary__c = true; 
        insert quote;
        
        // create the quote lines
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine = TestDataFactory.buildTestSFCPQQuoteLine(product.Id, quote.Id, priceBookEntry1.Id, 200,listOfEditions.get(0),1);
        insert quoteLine;
        
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c();
        quoteLine2 = TestDataFactory.buildTestSFCPQQuoteLine(product2.Id, quote.Id, priceBookEntry2.Id, 100,listOfEditions.get(0),-1);
        insert quoteLine2;
        
        opp.SBQQ__PrimaryQuote__c=quote.Id;
        update opp;
        
        // create the Order from the quote
        quote.SBQQ__Ordered__c  = true;     
        update quote;
    }

    @isTest 
    static void testPositiveOrderTax()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{"data": {"companyId": "1005243996-100030889800003","companyName": "Informa Middle East Ltd","companyRole": "S","currency": "USD","minAccountableUnit": "0.01","roundingPrecision": "2","roundingRule": "1","documentDate": "2021-09-01","documentNumber": "00000109","totalTaxAmount": "0.00","lines": [{"itemNumber": "1","grossAmount": "8750.00","pointOfTitleTransfer": "I","shipFromCountry": "UNITED STATES","shipToCountry": "UNITED STATES","totalTaxAmount": "0.00","transactionType": "GS","taxSummary": {"taxableBasis": "8750.00","exemptAmount": "0.00","taxRate": "0","effectiveTaxRate": "0"},"taxes": [{"addressType": "SF","adminZoneLevel": "State","authorityName": "PA - STATE SALES/USE TAX","authorityType": "State Sales/Use","calculationMethod": "1","comment": "ORACLE[USPA]","erpTaxCode": "USPA","effectiveZoneLevel": "State","documentDescription": "No Liability","jurisdictionText": "USSG190: No Tax Applies Because Seller is not Established.","ruleOrder": "5000","taxableCountry": "US","taxableCountryName": "UNITED STATES","taxableState": "PENNSYLVANIA","taxableCounty": "DELAWARE","taxableCity": "UNINCORPORATED","taxablePostalCode": "19073","taxRateCode": "NL","taxType": "NL","zoneName": "PENNSYLVANIA","zoneLevel": "State","taxRate": "0","natureOfTax": "P","euTransaction": "false","authorityUuid": "d54baeff-6c9d-4a49-80d5-c75b23ea452c","authorityCurrencyCode": "USD","currencyConversion": [{"taxExchangeRateDate": "2021-09-01"}],"exemptAmount": {"documentAmount": "0.00","unroundedDocumentAmount": "0.0000000000","authorityAmount": "0.00","unroundedAuthorityAmount": "0.0000000000"},"grossAmount": {"authorityAmount": "8750.00","unroundedAuthorityAmount": "8750.0000000000"},"nonTaxableBasis": {"documentAmount": "0.00","unroundedDocumentAmount": "0.0000000000","authorityAmount": "0.00","unroundedAuthorityAmount": "0.0000000000"},"taxableBasis": {"documentAmount": "8750.00","unroundedDocumentAmount": "8750.0000000000","authority_amount": "8750.00","unrounded_authority_amount": "8750.0000000000"},"taxAmount": {"documentAmount": "0.00","unroundedDocumentAmount": "0.0000000000","authorityAmount": "0.00","unroundedAuthorityAmount": "0.0000000000"},"taxDeterminationDate": "2021-09-01","taxPointDate": "2021-09-01"}]},{"itemNumber": "2","grossAmount": "175.00","pointOfTitleTransfer": "I","shipFromCountry": "UNITED STATES","shipToCountry": "UNITED STATES","totalTaxAmount": "0.00","transactionType": "GS","taxSummary": {"taxableBasis": "175.00","exemptAmount": "0.00","taxRate": "0","effectiveTaxRate": "0"},"taxes": [{"addressType": "SF","adminZoneLevel": "State","authorityName": "PA - STATE SALES/USE TAX","authorityType": "State Sales/Use","calculationMethod": "1","comment": "ORACLE[USPA]","erpTaxCode": "USPA","effectiveZoneLevel": "State","documentDescription": "No Liability","jurisdictionText": "USSG190: No Tax Applies Because Seller is not Established.","ruleOrder": "5000","taxableCountry": "US","taxableCountryName": "UNITED STATES","taxableState": "PENNSYLVANIA","taxableCounty": "DELAWARE","taxableCity": "UNINCORPORATED","taxablePostalCode": "19073","taxRateCode": "NL","taxType": "NL","zoneName": "PENNSYLVANIA","zoneLevel": "State","taxRate": "0","natureOfTax": "P","euTransaction": "false","authorityUuid": "d54baeff-6c9d-4a49-80d5-c75b23ea452c","authorityCurrencyCode": "USD","currencyConversion": [{"taxExchangeRateDate": "2021-09-01"}],"exemptAmount": {"documentAmount": "0.00","unroundedDocumentAmount": "0.0000000000","authorityAmount": "0.00","unroundedAuthorityAmount": "0.0000000000"},"grossAmount": {"authorityAmount": "175.00","unroundedAuthorityAmount": "175.0000000000"},"nonTaxableBasis": {"documentAmount": "0.00","unroundedDocumentAmount": "0.0000000000","authorityAmount": "0.00","unroundedAuthorityAmount": "0.0000000000"},"taxableBasis": {"documentAmount": "175.00","unroundedDocumentAmount": "175.0000000000","authority_amount": "175.00","unrounded_authority_amount": "175.0000000000"},"taxAmount": {"documentAmount": "0.00","unroundedDocumentAmount": "0.0000000000","authorityAmount": "0.00","unroundedAuthorityAmount": "0.0000000000"},"taxDeterminationDate": "2021-09-01","taxPointDate": "2021-09-01"}]}]},"meta": {"status": "success","message": "document Calcualted Successfully","code": 200,"partnerMessages": []}}';
        mapURIBody.put('/calculate-tax?','200###'+resJSON);

        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id , Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
		update lstOrdItemInsert;

        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.External_Tax_System__c = 'Onesource';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Order';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   'Tax';
        item.External_Tax_System__c     = 'Onesource';
        item.Order__c   = order.Id;
        item.Edition__c = quote.Edition__c;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
        Test.startTest();
            APISynchronizationSchedule sh1 = new APISynchronizationSchedule();
            String sch = '0 0 23 * * ?'; 
            System.schedule('Test APISynchronizationSchedule', sch, sh1); 
        	sh1.execute(null);
        Test.stopTest();
        Order order2 = Database.query('SELECT Id ,Tax_Status__c FROM Order WHERE Id  = \''+order.Id+'\'');
        System.assertEquals('Tax Complete',order2.Tax_Status__c,'Order tax Upadte Failed');
    }
}