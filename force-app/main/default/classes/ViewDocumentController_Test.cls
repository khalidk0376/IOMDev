/**
* File			: 	ViewDocumentController_Test
* Project      	:   GECI
* Created By	: 	IBM(Bharath)
* Created Date	: 	4-july-2023
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - ViewDocumentController(96%)
*/
@IsTest
private class ViewDocumentController_Test {
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
        String billingSchedulesApiNameEdition='Payment_Schedule__c';
        String cutOffApiName='CutoffDate_';
        
        // Trigger Record 
        //Create Trigger test record 
        Trigger__c trig = new Trigger__c(Name = 'ActivateOrderAfterCalculate_Trig' , Trigger_Name_Unique__c='ActivateOrderAfterCalculate_Trig',Enabled__c=true,Object__c='Order',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,Before_Update__c=true);
        Insert trig;
        
        // Create an account
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

    @isTest static void getERPReferencetest(){
        string resJSON = '{"errors":[{"id":"b0a0b361-a286-46ee-b18c-0471ff62697f","timestamp":"2023-07-03T17:09:32.326Z","status":400,"title":"Bad Request","detail":"Document number cannot be null or empty.","path":"/document/ERP-0056987/download?legalEntity=IN23"}]}';
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id ,AccountId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Initiated';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        inv.ERP_Reference__c='9500005097';
        insert inv;
        blng__CreditNote__c crNote = new blng__CreditNote__c();
        crNote.blng__Account__c = order.AccountId;
        crNote.blng__CreditNoteDate__c = Date.today();
        crNote.blng__Status__c = 'Draft';
        crNote.blng__RelatedInvoice__c = inv.Id;
        insert crNote;
        ApexPages.currentPage().getParameters().put('ERPRef',inv.ERP_Reference__c);
        ApexPages.currentPage().getParameters().put('RecordId',inv.Id);
        ViewDocumentController viewrec = new ViewDocumentController();
        Test.startTest();
        Test.setMock(HTTPCalloutMock.class, new viewDocument_Mock());
        API_Detail__mdt mtAPIDetails = APISynchronizationHelper.getAPIDetails('IOM_Invoice_PDF_Retrieval', GlobalConstants.ORACLE);
        HttpResponse response = ViewDocumentController.calltoExternalSystem(inv.ERP_Reference__c,'IN23',mtAPIDetails);
        viewrec.getDocument();
        test.stopTest();  
        ViewDocumentController.WrapperListView wrp=new ViewDocumentController.WrapperListView(inv,'',resJSON,'blng__Invoice__c',crNote,false,String.valueOf(response.getStatusCode()));
        ViewDocumentController.CreateAPIrecs(wrp);
        System.assertEquals('Initiated', inv.blng__InvoiceStatus__c,'Status should not be draft');
    }
    
    @isTest 
    static void getERPReferenceTestNegative()
    {
        string resJSON = '{"errors":[{"id":"b0a0b361-a286-46ee-b18c-0471ff62697f","timestamp":"2023-07-03T17:09:32.326Z","status":400,"title":"Bad Request","detail":"Document number cannot be null or empty.","path":"/document/ERP-0056987/download?legalEntity=IN23"}]}';
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id ,AccountId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Initiated';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        inv.ERP_Reference__c='9500005097';
        insert inv;
        blng__CreditNote__c crNote = new blng__CreditNote__c();
        crNote.blng__Account__c = order.AccountId;
        crNote.blng__CreditNoteDate__c = Date.today();
        crNote.blng__Status__c = 'Draft';
        crNote.blng__RelatedInvoice__c = inv.Id;
        insert crNote;
        blng__Invoice__c inv1 = null;
        ApexPages.currentPage().getParameters().put('ERPRef',crNote.ERPReference__c);
        ApexPages.currentPage().getParameters().put('RecordId',crNote.Id);
        Test.startTest();
        test.stopTest();
        ViewDocumentController.WrapperListView wrp=new ViewDocumentController.WrapperListView(inv1,'',resJSON,'blng__CreditNote__c',crNote,false,'200');
        ViewDocumentController.createAPIrecs(wrp);
        System.assertEquals('Initiated', inv.blng__InvoiceStatus__c,'Status should not be draft');
    }
}