/**
* File			: 	OracleOrderHubAPIUtils_Test
* Project      	:   Order & Billing Plateform
* Created By	: 	Ashish(Girikon)
* Created Date	: 	05th Oct 2021
* ************************************************************************************
* @description : Test Class to provide code covrage to classes - OracleOrderHubAPIUtils,OrderHubAPIWrapper
* Modification log :  
* 1.Girikon(Ashish) [GECI-916] 15 May 2023, Amendment process Changes to Allow Multiple Amendments for Order Hub
*/
@isTest
private  with sharing class OracleOrderHubAPIUtils_Test {
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
        acc.Legacy_CRM_Instance__c = 'GE';
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
            edition.CC_Emails__c= 'test@salesforce.com';
            edition.BCC_Emails__c = 'test1@salesforce.com';
            edition.Contract_Creation__c = true;
            edition.Invoice_Creation__c = true;
            edition.External_Tax_System__c = GlobalConstants.ONESOURCE;
            edition.External_Relationship__c = true;
            edition.X3rd_Party_ERP_System__c = 'SAP';
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
            AccountId=acc.Id,PO_Number__c='P-0056254',Legacy_CRM_Instance__c='GE');
        
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
        quote.SBQQ__PaymentTerms__c = 'Net 30';
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
    
    @isTest static void testPositiveInvoiceSyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents','202###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;
        
        
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;
        
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.POST_DOCUMENTS;
        item.X3rd_Party_ERP_System__c     = 'Oracle';
        item.Invoice__c   = inv.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);
        
        Test.stopTest();
        blng__Invoice__c inv2 = Database.query('SELECT Id ,Order_Hub_Sync_Status__c FROM blng__Invoice__c WHERE Id  = \''+inv.Id+'\'');
        System.assertEquals('success',inv2.Order_Hub_Sync_Status__c,'Invoice Sync Failed');
    }
    
    @isTest static void testNegInvoiceSyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "incomplete", "message": "Some items did not pass the validation and need to be reprocessed. Please see the detailed message", "detailedMessage": {"errors": [{"documentId": "CN-0006", "message": "BAD REQUEST : MISSING PRODUCT DATE" }]}} }';
        mapURIBody.put('/documents','202###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.POST_DOCUMENTS;
        item.X3rd_Party_ERP_System__c     = 'Oracle';
        item.Invoice__c   = inv.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);            
        Test.stopTest();
        blng__Invoice__c inv2 = Database.query('SELECT Id ,Order_Hub_Sync_Status__c FROM blng__Invoice__c WHERE Id  = \''+inv.Id+'\'');
        System.assertEquals('incomplete',inv2.Order_Hub_Sync_Status__c,'Invoice Sync Failed');
    }
    
    @isTest static void testNegInvoiceSyncC400()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "Error", "message": "Some items did not pass the validation and need to be reprocessed. Please see the detailed message", "detailedMessage": null} }';
        mapURIBody.put('/documents','400###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.POST_DOCUMENTS;
        item.X3rd_Party_ERP_System__c     = 'Oracle';
        item.Invoice__c   = inv.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);            
        Test.stopTest();
        blng__Invoice__c inv2 = Database.query('SELECT Id ,Order_Hub_Sync_Status__c FROM blng__Invoice__c WHERE Id  = \''+inv.Id+'\'');
        System.assertEquals('Error',inv2.Order_Hub_Sync_Status__c,'Invoice Sync Failed');
    }
    
    @isTest static void testPositiveCreditNoteSyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents','202###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,OpportunityId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;
        
        inv.Tax_Status__c = 'Tax Complete';
        inv.blng__InvoiceStatus__c = 'Posted';
        update inv;
        
        blng__CreditNote__c crNote = new blng__CreditNote__c();
        crNote.blng__Account__c = order.AccountId;
        crNote.blng__CreditNoteDate__c = Date.today();
        crNote.blng__Status__c = 'Draft';
        crNote.blng__RelatedInvoice__c = inv.Id;
        crNote.blng__BillToContact__c = con.Id;
        crNote.Alternate_Exchange_Rate__c = 100;
        crNote.Ledger_Exchange_Rate__c = 200;
        crNote.Tax_Exchange_Rate__c =300;
        insert crNote;
        
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Posted';            
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        list<blng__CreditNoteLine__c> listCreditNoteLines = new list<blng__CreditNoteLine__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
            
            blng__CreditNoteLine__c crNoteLine = new blng__CreditNoteLine__c();
            crNoteLine.blng__CreditNote__c = crNote.Id;
            crNoteLine.blng__Product__c = invLine.blng__Product__c;
            crNoteLine.Line_Item_Number__c = invLine.Line_Item_Number__c;
            crNoteLine.blng__InvoiceLine__c = invLine.Id;
            crNoteLine.Alternate_Exchange_Rate__c = 10;
            crNoteLine.Ledger_Exchange_Rate__c = 20;
            crNoteLine.Tax_Exchange_Rate__c = 30;
            crNoteLine.blng__TotalAmount__c = 10;
            listCreditNoteLines.add(crNoteLine);
        }
        insert listTaxLines;
        insert listCreditNoteLines;
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Credit Note';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.POST_DOCUMENTS;
        item.X3rd_Party_ERP_System__c     = 'Oracle';
        item.Credit_Note__c   = crNote.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);            
        Test.stopTest();
        blng__CreditNote__c crdNote = Database.query('SELECT Id ,Order_Hub_Sync_Status__c FROM blng__CreditNote__c WHERE Id  = \''+crNote.Id+'\'');
        System.assertEquals('success',crdNote.Order_Hub_Sync_Status__c,'Credit Note Sync Failed');
    }
    
    @isTest static void testCreditNoteSyncDuplicateError()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents','202###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,OpportunityId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;
        
        inv.Tax_Status__c = 'Tax Complete';
        inv.blng__InvoiceStatus__c = 'Posted';
        update inv;
        
        List<blng__CreditNote__c> listCreditNote = new List<blng__CreditNote__c>();
        blng__CreditNote__c crNote = new blng__CreditNote__c();
        crNote.blng__Account__c = order.AccountId;
        crNote.blng__CreditNoteDate__c = Date.today();
        crNote.blng__Status__c = 'Draft';
        crNote.blng__RelatedInvoice__c = inv.Id;
        crNote.blng__BillToContact__c = con.Id;
        crNote.Alternate_Exchange_Rate__c = 100;
        crNote.Ledger_Exchange_Rate__c = 200;
        crNote.Tax_Exchange_Rate__c =300;
        listCreditNote.add(crNote);
        
        crNote = new blng__CreditNote__c();
        crNote.blng__Account__c = order.AccountId;
        crNote.blng__CreditNoteDate__c = Date.today();
        crNote.blng__Status__c = 'Draft';
        crNote.blng__RelatedInvoice__c = inv.Id;
        crNote.blng__BillToContact__c = con.Id;
        crNote.Alternate_Exchange_Rate__c = 100;
        crNote.Ledger_Exchange_Rate__c = 200;
        crNote.Tax_Exchange_Rate__c =300;
        listCreditNote.add(crNote);
        
        insert listCreditNote;
        
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Posted';            
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        list<blng__CreditNoteLine__c> listCreditNoteLines = new list<blng__CreditNoteLine__c>();
        for(blng__InvoiceLine__c invLine : lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
            
            blng__CreditNoteLine__c crNoteLine = new blng__CreditNoteLine__c();
            crNoteLine.blng__CreditNote__c = listCreditNote[0].Id;
            crNoteLine.blng__Product__c = invLine.blng__Product__c;
            crNoteLine.Line_Item_Number__c = invLine.Line_Item_Number__c;
            crNoteLine.blng__InvoiceLine__c = invLine.Id;
            crNoteLine.Alternate_Exchange_Rate__c = 10;
            crNoteLine.Ledger_Exchange_Rate__c = 20;
            crNoteLine.Tax_Exchange_Rate__c = 30;
            crNoteLine.blng__TotalAmount__c = 10;
            listCreditNoteLines.add(crNoteLine);
            
            crNoteLine = new blng__CreditNoteLine__c();
            crNoteLine.blng__CreditNote__c = listCreditNote[1].Id;
            crNoteLine.blng__Product__c = invLine.blng__Product__c;
            crNoteLine.Line_Item_Number__c = invLine.Line_Item_Number__c;
            crNoteLine.blng__InvoiceLine__c = invLine.Id;
            crNoteLine.Alternate_Exchange_Rate__c = 10;
            crNoteLine.Ledger_Exchange_Rate__c = 20;
            crNoteLine.Tax_Exchange_Rate__c = 30;
            crNoteLine.blng__TotalAmount__c = 10;
            listCreditNoteLines.add(crNoteLine);
        }
        insert listTaxLines;
        insert listCreditNoteLines;
        
        update new blng__CreditNote__c(Id=listCreditNote[0].Id,Order_Hub_Sync_Status__c='success');
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Credit Note';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.POST_DOCUMENTS;
        item.X3rd_Party_ERP_System__c     = 'Oracle';
        item.Credit_Note__c   = listCreditNote[1].Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);            
        Test.stopTest();
        blng__CreditNote__c crdNote = Database.query('SELECT Id ,Order_Hub_Sync_Status__c FROM blng__CreditNote__c WHERE Id  = \''+crNote.Id+'\'');
        System.assertEquals('Error',crdNote.Order_Hub_Sync_Status__c,'Credit Note Sync Failed');
    }
    
    /********Invoice Amendment Test*********/
    
    /** @description testPosInvAmend01SyncC202*/
    
    @isTest static void testPosInvAmend01SyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        //mapURIBody.put('/documents/events?eventType=document_amend&sourceSystem=IOM','202###'+resJSON);
        mapURIBody.put('/documents/events?eventType=full_amend&sourceSystem=IOM','202###'+resJSON);

        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));

        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');

            Order order = Database.query('SELECT Id ,AccountId,Status,OpportunityId,Tax_Status__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');

        order.Tax_Status__c = 'Tax Complete';
        order.Status = 'Activated';
        update order;
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        con.Legacy_CRM_Instance__c = 'GE';
        Insert con;

        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');

        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        inv.ERP_Reference__c = 'ERP-002';
        insert inv;

        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        

        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;            
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;

        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';

            listTaxLines.add(taxLine);
        }
        insert listTaxLines;

        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;

        Change_Request__c cr = new Change_Request__c(Account__c=order.AccountId,Opportunity__c=order.OpportunityId,Amendment_Type__c='PO number change',Edition__c=quote.Edition__c,ERP_Ref_Numbers__c='IM-IV00326,CN-003625');
        insert cr;

        List<API_Synchronization_Item__c> items = new list<API_Synchronization_Item__c>();
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC_OH; //'Re-Print for PO number change';
        item.X3rd_Party_ERP_System__c     = 'Oracle';
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        items.add(item);

        Insert items;

        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);

        Test.stopTest();
        API_Synchronization_Transaction__c apiTrans = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Transaction__c WHERE Id  = \''+apiSyncroTrs.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,apiTrans.Status__c,'Invoice Sync Failed');
    }

    @isTest static void testPosInvAmend02SyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents/events?eventType=full_amend&sourceSystem=IOM','202###'+resJSON);

        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));



        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');

        Order order = Database.query('SELECT Id ,AccountId,Status,OpportunityId,Tax_Status__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;        
        order.blng__BillingAccount__c = order.AccountId;
        order.BillToContactId = con.Id;
        order.Tax_Status__c = 'Tax Complete';
        order.Status = 'Activated';
        update order;

        AccountContactRelation accConRel = [SELECT Id,IM_Contact_No__c,SourceOrg__c,Source_Contact_ID__c,AccountId,ContactId FROM AccountContactRelation where IsActive=true AND AccountId =: order.AccountId AND ContactId =: con.Id  WITH SECURITY_ENFORCED LIMIT 1];
        accConRel.SourceOrg__c = null;
        Update accConRel;

        Change_Request__c cr = new Change_Request__c(Account__c=order.AccountId,Opportunity__c=order.OpportunityId,Amendment_Type__c='Update Bill To Contact',Edition__c=quote.Edition__c,ERP_Ref_Numbers__c='IM-IV00326,CN-003625');
        insert cr;

        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');

        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        inv.ERP_Reference__c = 'ERP-002';
        insert inv;

        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        

        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;            
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;

        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;

        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;

        List<API_Synchronization_Item__c> items = new list<API_Synchronization_Item__c>();
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item02 = new API_Synchronization_Item__c();
        item02.API_Call_Type__c   =   'POST';
        item02.Status__c          =   'Queued';
        item02.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC_OH; //'Re-Print for Contact Details Change';
        item02.X3rd_Party_ERP_System__c     = 'Oracle';
        item02.Amendment_Request__c  = cr.Id;
        item02.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        items.add(item02);

        Insert items;

        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);

        Test.stopTest();
        API_Synchronization_Transaction__c apiTrans = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Transaction__c WHERE Id  = \''+apiSyncroTrs.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,apiTrans.Status__c,'Invoice Sync Failed');
    }

    @isTest static void testPosInvAmend03SyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents/events?eventType=full_amend&sourceSystem=IOM','202###'+resJSON);

        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));

        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');

        Order order = Database.query('SELECT Id ,AccountId,Status,OpportunityId,Tax_Status__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        order.Tax_Status__c = 'Tax Complete';
        order.Status = 'Activated';
        update order;

        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        Change_Request__c cr = new Change_Request__c(Account__c=order.AccountId,Opportunity__c=order.OpportunityId,Amendment_Type__c='Ship To Account Change',Edition__c=quote.Edition__c,ERP_Ref_Numbers__c='IM-IV00326,CN-003625');
        insert cr;

        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');

        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        inv.ERP_Reference__c = 'ERP-002';
        insert inv;

        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        

        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;            
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;

        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;

        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;

        List<API_Synchronization_Item__c> items = new list<API_Synchronization_Item__c>();
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item03 = new API_Synchronization_Item__c();
        item03.API_Call_Type__c   =   'POST';
        item03.Status__c          =   'Queued';
        item03.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC_OH; //'Re-Print for Ship To Account Details Change';
        item03.X3rd_Party_ERP_System__c     = 'Oracle';
        item03.Amendment_Request__c  = cr.Id;
        item03.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        items.add(item03);

        Insert items;

        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);

        Test.stopTest();
        API_Synchronization_Transaction__c apiTrans = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Transaction__c WHERE Id  = \''+apiSyncroTrs.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,apiTrans.Status__c,'Invoice Sync Failed');
    }

    @isTest static void testPosInvAmend04SyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents/events?eventType=full_amend&sourceSystem=IOM','202###'+resJSON);

        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));

        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');

        Order order = Database.query('SELECT Id ,AccountId,OpportunityId,Status,Tax_Status__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        order.Tax_Status__c = 'Tax Complete';
        order.Status = 'Activated';
        update order;

        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        Change_Request__c cr = new Change_Request__c(Account__c=order.AccountId,Opportunity__c=order.OpportunityId,Amendment_Type__c='Bill To Account Change',Edition__c=quote.Edition__c,ERP_Ref_Numbers__c='IM-IV00326,CN-003625');
        insert cr;

        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');

        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        inv.ERP_Reference__c = 'ERP-002';
        insert inv;

        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        

        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;            
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;

        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;

        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;

        List<API_Synchronization_Item__c> items = new list<API_Synchronization_Item__c>();
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item04 = new API_Synchronization_Item__c();
        item04.API_Call_Type__c   =   'POST';
        item04.Status__c          =   'Queued';
        item04.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC_OH; //'Re-Print for Bill To Account Details Change';
        item04.X3rd_Party_ERP_System__c     = 'Oracle';
        item04.Amendment_Request__c  = cr.Id;
        item04.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        items.add(item04);

        Insert items;

        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);

        Test.stopTest();
        API_Synchronization_Transaction__c apiTrans = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Transaction__c WHERE Id  = \''+apiSyncroTrs.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,apiTrans.Status__c,'Invoice Sync Failed');
    }
    
    /*********** OLD before GECI-916******* */
    
    /**@description */
   /* @isTest static void testPosInvAmend01SyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents/events?eventType=document_amend&sourceSystem=IOM','202###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,Status,OpportunityId,Tax_Status__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        order.Tax_Status__c = 'Tax Complete';
        order.Status = 'Activated';
        update order;
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        con.Legacy_CRM_Instance__c = 'GE';
        Insert con;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        inv.ERP_Reference__c = 'ERP-002';
        insert inv;
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;            
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;
        
        Change_Request__c cr = new Change_Request__c(Account__c=order.AccountId,Opportunity__c=order.OpportunityId,Amendment_Type__c='PO number change',Edition__c=quote.Edition__c,ERP_Ref_Numbers__c='IM-IV00326,CN-003625');
        insert cr;
        
        List<API_Synchronization_Item__c> items = new list<API_Synchronization_Item__c>();
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   'Re-Print for PO number change';
        item.X3rd_Party_ERP_System__c     = 'Oracle';
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        items.add(item);
        
        Insert items;
        
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);
        
        Test.stopTest();
        API_Synchronization_Transaction__c apiTrans = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Transaction__c WHERE Id  = \''+apiSyncroTrs.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,apiTrans.Status__c,'Invoice Sync Failed');
    }
    
    @isTest static void testPosInvAmend02SyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents/events?eventType=contact_amend&sourceSystem=IOM','202###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,Status,OpportunityId,Tax_Status__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        order.blng__BillingAccount__c = order.AccountId;
        order.BillToContactId = con.Id;
        order.Tax_Status__c = 'Tax Complete';
        order.Status = 'Activated';
        update order;
        
        
        
        AccountContactRelation accConRel = [SELECT Id,IM_Contact_No__c,SourceOrg__c,Source_Contact_ID__c,AccountId,ContactId FROM AccountContactRelation where IsActive=true AND AccountId =: order.AccountId AND ContactId =: con.Id  WITH SECURITY_ENFORCED LIMIT 1];
        accConRel.SourceOrg__c = null;
        Update accConRel;
        
        Change_Request__c cr = new Change_Request__c(Account__c=order.AccountId,Opportunity__c=order.OpportunityId,Amendment_Type__c='Update Bill To Contact',Edition__c=quote.Edition__c,ERP_Ref_Numbers__c='IM-IV00326,CN-003625');
        insert cr;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        inv.ERP_Reference__c = 'ERP-002';
        insert inv;
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;            
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;
        
        List<API_Synchronization_Item__c> items = new list<API_Synchronization_Item__c>();
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item02 = new API_Synchronization_Item__c();
        item02.API_Call_Type__c   =   'POST';
        item02.Status__c          =   'Queued';
        item02.Type__c    =   'Re-Print for Contact Details Change';
        item02.X3rd_Party_ERP_System__c     = 'Oracle';
        item02.Amendment_Request__c  = cr.Id;
        item02.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        items.add(item02);
        
        Insert items;
        
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);
        
        Test.stopTest();
        API_Synchronization_Transaction__c apiTrans = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Transaction__c WHERE Id  = \''+apiSyncroTrs.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,apiTrans.Status__c,'Invoice Sync Failed');
    }
    
    @isTest static void testPosInvAmend03SyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents/events?eventType=account_amend&sourceSystem=IOM','202###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,Status,OpportunityId,Tax_Status__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        order.Tax_Status__c = 'Tax Complete';
        order.Status = 'Activated';
        update order;
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        Change_Request__c cr = new Change_Request__c(Account__c=order.AccountId,Opportunity__c=order.OpportunityId,Amendment_Type__c='Ship To Account Change',Edition__c=quote.Edition__c,ERP_Ref_Numbers__c='IM-IV00326,CN-003625');
        insert cr;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        inv.ERP_Reference__c = 'ERP-002';
        insert inv;
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;            
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;
        
        List<API_Synchronization_Item__c> items = new list<API_Synchronization_Item__c>();
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item03 = new API_Synchronization_Item__c();
        item03.API_Call_Type__c   =   'POST';
        item03.Status__c          =   'Queued';
        item03.Type__c    =   'Re-Print for Ship To Account Details Change';
        item03.X3rd_Party_ERP_System__c     = 'Oracle';
        item03.Amendment_Request__c  = cr.Id;
        item03.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        items.add(item03);
        
        Insert items;
        
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);
        
        Test.stopTest();
        API_Synchronization_Transaction__c apiTrans = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Transaction__c WHERE Id  = \''+apiSyncroTrs.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,apiTrans.Status__c,'Invoice Sync Failed');
    }
    
    @isTest static void testPosInvAmend04SyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents/events?eventType=account_amend&sourceSystem=IOM','202###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,OpportunityId,Status,Tax_Status__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        order.Tax_Status__c = 'Tax Complete';
        order.Status = 'Activated';
        update order;
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        Change_Request__c cr = new Change_Request__c(Account__c=order.AccountId,Opportunity__c=order.OpportunityId,Amendment_Type__c='Bill To Account Change',Edition__c=quote.Edition__c,ERP_Ref_Numbers__c='IM-IV00326,CN-003625');
        insert cr;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        inv.ERP_Reference__c = 'ERP-002';
        insert inv;
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;            
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;
        
        List<API_Synchronization_Item__c> items = new list<API_Synchronization_Item__c>();
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item04 = new API_Synchronization_Item__c();
        item04.API_Call_Type__c   =   'POST';
        item04.Status__c          =   'Queued';
        item04.Type__c    =   'Re-Print for Bill To Account Details Change';
        item04.X3rd_Party_ERP_System__c     = 'Oracle';
        item04.Amendment_Request__c  = cr.Id;
        item04.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        items.add(item04);
        
        Insert items;
        
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);
        
        Test.stopTest();
        API_Synchronization_Transaction__c apiTrans = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Transaction__c WHERE Id  = \''+apiSyncroTrs.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,apiTrans.Status__c,'Invoice Sync Failed');
    }*/
    
    @isTest static void testInvAmend01SyncC400()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents/events?eventType=account_amend&sourceSystem=IOM','400###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,OpportunityId,Status,Tax_Status__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        order.Tax_Status__c = 'Tax Complete';
        order.Status = 'Activated';
        update order;
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        Change_Request__c cr = new Change_Request__c(Account__c=order.AccountId,Opportunity__c=order.OpportunityId,Amendment_Type__c='Bill To Account Change',Edition__c=quote.Edition__c,ERP_Ref_Numbers__c='IM-IV00326,CN-003625');
        insert cr;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        inv.ERP_Reference__c = 'ERP-002';
        insert inv;
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;            
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;
        
        List<API_Synchronization_Item__c> items = new list<API_Synchronization_Item__c>();
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item04 = new API_Synchronization_Item__c();
        item04.API_Call_Type__c   =   'POST';
        item04.Status__c          =   'Queued';
        item04.Type__c    =   'Re-Print for Bill To Account Details Change';
        item04.X3rd_Party_ERP_System__c     = 'Oracle';
        item04.Amendment_Request__c  = cr.Id;
        item04.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        items.add(item04);
        
        Insert items;
        
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);
        apiSyncroTrs.Status__c = 'Completed With Errors';
        update apiSyncroTrs;
        Test.stopTest();
        API_Synchronization_Transaction__c apiTrans = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Transaction__c WHERE Id  = \''+apiSyncroTrs.Id+'\'');
        System.assertEquals('Completed With Errors',apiTrans.Status__c,'Invoice Sync Failed');
    }
    
    /************** Payment Sync ***************/
    /** @description testPositivePaymentSyncC202*/
    @isTest static void testPositivePaymentSyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents/payments','202###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;               
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;
        
        Payment_Transaction__c pt = new Payment_Transaction__c();
        pt.Amount__c	= 	100;
        pt.Invoice__c	=   inv.Id;   
        pt.Card_Type__c	=	'Visa';
        pt.Payment_Method__c	=	'Credit Card';
        pt.Payment_Status__c	=	'Success';
        pt.Authorization_Date__c=	DateTime.now();
        pt.Payment_Type__c= 'payment';
        pt.ERP_Sync_Status__c= 'Sync Required';
        insert pt;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.POST_PAYMENT_TRANSACTIONS;
        item.X3rd_Party_ERP_System__c     = 'Oracle';
        item.Invoice__c   = inv.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);
        
        Test.stopTest();
        API_Synchronization_Item__c apiItem = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Id  = \''+item.Id+'\'');
        System.assertEquals('Completed',apiItem.Status__c,'Payment Sync Failed');
    }
    
    @isTest static void testPaymentSyncC400()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents/payments','400###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;               
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;
        
        Payment_Transaction__c pt = new Payment_Transaction__c();
        pt.Amount__c	= 	100;
        pt.Invoice__c	=   inv.Id;   
        pt.Card_Type__c	=	'Visa';
        pt.Payment_Method__c	=	'Credit Card';
        pt.Payment_Status__c	=	'Success';
        pt.Authorization_Date__c=	DateTime.now();
        pt.Payment_Type__c= 'payment';
        pt.ERP_Sync_Status__c= 'Sync Required';
        insert pt;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.POST_PAYMENT_TRANSACTIONS;
        item.X3rd_Party_ERP_System__c     = 'Oracle';
        item.Invoice__c   = inv.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);
        
        Test.stopTest();
        API_Synchronization_Item__c apiItem = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Id  = \''+item.Id+'\'');
        System.assertEquals('Error',apiItem.Status__c,'Payment Sync Failed');
    }
    
    @isTest static void testPositivePaymentSyncCError()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "incomplete", "message": "Some items did not pass the validation and need to be reprocessed. Please see the detailed message", "detailedMessage": {"errors": [{"documentId": "CN-0006", "message": "BAD REQUEST : MISSING PRODUCT DATE" }]}} }';
        mapURIBody.put('/documents/payments','202###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;               
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;
        
        Payment_Transaction__c pt = new Payment_Transaction__c();
        pt.Amount__c	= 	100;
        pt.Invoice__c	=   inv.Id;   
        pt.Card_Type__c	=	'Visa';
        pt.Payment_Method__c	=	'Credit Card';
        pt.Payment_Status__c	=	'Success';
        pt.Authorization_Date__c=	DateTime.now();
        pt.Payment_Type__c= 'payment';
        pt.ERP_Sync_Status__c= 'Sync Required';
        insert pt;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.POST_PAYMENT_TRANSACTIONS;
        item.X3rd_Party_ERP_System__c     = 'Oracle';
        item.Invoice__c   = inv.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);
        
        Test.stopTest();
        API_Synchronization_Item__c apiItem = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Id  = \''+item.Id+'\'');
        System.assertEquals('Error',apiItem.Status__c,'Payment Sync Failed');
    }
    
    /************** Taslation Data Sync ***************/
    /** @description testPositiveTraslationSyncC202*/
    @isTest static void testPositiveTraslationSyncC202()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": {"status": "success", "message": "All items have been successfully captured and will be processed soon", "detailedMessage": null} }';
        mapURIBody.put('/documents','202###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,Order_Translation_Status__c,AccountId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        
        order.Order_Translation_Status__c = 'Completed';
        update order;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;               
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');        
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;            
            invLine.blng__TaxRule__c = taxRule.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            //invLine.Line_Item_Number__c = num;
            //num++;
            lstInvoiceLineInsert.add(invLine);
        }
        insert lstInvoiceLineInsert;
        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(blng__InvoiceLine__c invLine:lstInvoiceLineInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Invoice_Line__c = invLine.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            taxLine.Zone_Level__c= 'State';
            taxLine.Taxable_City__c= 'UNINCORPORATED';
            taxLine.Taxable_State__c= 'PENNSYLVANIA';
            taxLine.Taxable_Country__c='US';
            taxLine.Taxable_County__c ='DELAWARE';
            taxLine.Nature_of_Tax__c ='P';
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Due_Dates__c = inv.blng__DueDate__c;
        paySch.Amounts__c = inv.blng__TotalAmount__c;
        paySch.Invoice__c = inv.Id;
        paySch.Percentage__c = '100';
        insert paySch;
        
        Translated_Record__c tr = new Translated_Record__c();
        tr.Contact__c =	con.Id;
        tr.Translated_Contact_LastName__c =	'اسم الاختبار';
        tr.Account__c =	order.AccountId;
        tr.Translated_Account_Name__c =	'اسم الاختبار';
        tr.Translated_Language__c =	'ar';
        tr.Translated_Billing_City__c =	'دبي';
        tr.Translated_Billing_Address_Line_1__c ='شارع الاختبار';
        tr.Translated_Billing_Country__c = 'الامارات العربية المتحدة';
        insert tr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.X3rd_Party_ERP_System__c = 'Oracle';
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;
        
        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.POST_DOCUMENTS;
        item.X3rd_Party_ERP_System__c     = 'Oracle';
        item.Invoice__c   = inv.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
        Test.startTest();
        Database.executeBatch(new APISynchronizationBatch(),1);
        
        Test.stopTest();
        blng__Invoice__c inv2 = Database.query('SELECT Id ,Order_Hub_Sync_Status__c FROM blng__Invoice__c WHERE Id  = \''+inv.Id+'\'');
        System.assertEquals('success',inv2.Order_Hub_Sync_Status__c,'Invoice Sync Failed');
    }
}