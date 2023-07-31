/**
* Created By   :   Girikon(Sachin)
* Created On   :   25/02/2020
* ******************************************************************************************************************
* @description  : Test Class to give covrage to AmendmentUtils(100%)]
* ******************************************************************************************************************
* Modification log --
*   [IML2R-208] - Girikon(Ashish)-  4 march 2020, Code Covrage
*/
@istest
public class AmendmentUtils_Test {
    private static Pricebook2 stdPriceBook;
    public static Date[] cutOffDatesOppty = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
        public static Date[] cutOffDatesEdition = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
            public static Decimal[] cutOffPercentagesOppty = new Decimal[]{25,25,25,25};
                public static Decimal[] cutOffPercentagesEdition = new Decimal[]{25,25,25,25};
                    public static String nbrOfTransactionApiName='Total_No_of_payment__c';
    public static String paymentTermApiNameEdition = 'Invoice_to_be_issued_before__c';
    public static  String billingSchedulesApiNameOppty='Payment_Schedule__c';
    
    @testSetup static void testSetupData() 
    {
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Integer maxTransactionsforEdition = 4;
        String billingSchedulesValue='25-25-25-25';
        String mileDelDateApiNamePart1='Milestone_';
        String mileDelPercentApiNamePart1='Milestone_';
        String mileDelDateApiNamePart2='_Delivery_Date__c';
        String mileDelPercentApiNamePart2='_Percent__c';
        
        String billingSchedulesApiNameEdition='Payment_Schedule__c';
        
        String cutOffApiName='CutoffDate_';
        
        // Create an account
        // Account acc = new Account(name='TESTACC',Payment_Term__c='Net 10');
        Account acc = new Account ();
        acc.Name = 'TESTACC';
        acc.currencyisocode='USD';
        acc.BillingStreet ='street2';
        acc.BillingCity='Alaska';
        acc.BillingState='tamil nadu';
        acc.BillingCountryCode='IN';
        acc.Legacy_CRM_Instance__c = 'Penton';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'OK';
        acc.Payment_Term__c='Net 15';
        acc.Address_Verified__c =true;
        acc.Address_Status__c = 'Valid';
        insert acc;
        
        Contact con = TestDataFactoryUtils.createContact(acc.Id);
        con.Legacy_CRM_Instance__c = 'Penton';
        insert con;
        
        // create list of edition to be used on the quote
        List<Edition__c> listOfEditions = new List<Edition__c>();
        Edition__c edition = new Edition__c();
        for(Integer i=0;i<2;i++){
            edition =  new Edition__c(Invoice_to_be_issued_before__c='30');
            for(Integer j=0;j<maxTransactionsforEdition;j++){
                if(j==0){
                    edition.put(cutOffApiName+'_c',cutOffDatesEdition[j]);
                }else{
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
            Name ='TESTOPP',  
            AccountId=acc.Id,
            Bill_To_Account__c = acc.Id,
            Ship_To_Account__c = acc.Id,
            Billing_Contact__c=con.Id);
        
        // set the cutOff dates to the Oppty
        for(Integer i = 1 ; i<= cutOffDatesOppty.size();i++){
            opp.put(mileDelDateApiNamePart1+i+mileDelDateApiNamePart2,cutOffDatesOppty[i-1]);
            opp.put(mileDelPercentApiNamePart1+i+mileDelPercentApiNamePart2,cutOffPercentagesOppty[i-1]);
        }
        insert opp;
        
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
        
        // create the quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote = TestDataFactory.buildTestSFCPQQuote('TESTQUOTECITY',opp.Id, acc.Id, standardPricebookId, 'Quote',listOfEditions.get(0));
        quote.SBQQ__Primary__c = true; 
        quote.SBQQ__StartDate__c = System.today();
        quote.SBQQ__SubscriptionTerm__c=12;
        insert quote;
        
        // create the quote lines
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine = TestDataFactory.buildTestSFCPQQuoteLine(product.Id, quote.Id, priceBookEntry1.Id, 200,listOfEditions.get(0),1);
        quoteLine.SBQQ__SubscriptionTerm__c=12;
        insert quoteLine;
        
        opp.SBQQ__PrimaryQuote__c=quote.Id;
        opp.StageName = 'Closed Won';
        opp.Address_Status__c = 'Valid';
        update opp;
        
        // create the Order from the quote
        quote.SBQQ__Ordered__c  = true;     
        update quote; 
        
        Order order = Database.query('SELECT Id , Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        order.EffectiveDate = Date.today().addDays(70);
        //order.Tax_Status__c = 'Tax Complete';
        //update order;
        order.Status='Activated';
        //update order;
        order.SBQQ__Contracted__c =true;
        //update order;
        order.blng__BillNow__c=true;        
        //update order;
        
        Contract oContract = new Contract(AccountId = acc.id,CustomerSignedId =con.Id 
                                          ,StartDate = Date.today(), ContractTerm = 12, 
                                          SBQQ__Opportunity__c = opp.id, SBQQ__Quote__c = quote.Id
                                          ,SBQQ__Order__c=order.Id);
        insert oContract;
        
        Change_Request__c cr = new Change_Request__c(Account__c=acc.Id,Opportunity__c=opp.Id,Product_Type__c='Financial'
                                                     ,Type_of_Change__c='Cancellation',New_Payment_Schedule__c='50-50'
                                                     ,Edition__c=edition.id);
        Change_Request__c cr2 = new Change_Request__c(Account__c=acc.Id,Opportunity__c=opp.Id,Product_Type__c='Financial'
                                                      ,Type_of_Change__c='Cancellation',New_Payment_Schedule__c='50-50'
                                                      ,Edition__c=edition.id,New_Order__c=order.Id);
        List<Change_Request__c> lstCr = new  List<Change_Request__c>();
        lstCr.add(cr);
        lstCr.add(cr2);
        insert lstCr;
    }
    
    @isTest
    static void unitTest1(){
        
        Test.startTest();
        Change_Request__c cr = [Select Id,Change_Request_Status__c,New_Order__c,Type_of_Change__c,Opportunity__c,Order_IDs__c 
                                from Change_Request__c Where New_Order__c=null];
        Change_Request__c cr2 = AmendmentUtils.getChangeRequest(cr.Id);
        system.assertEquals(null, cr2.New_Order__c,'New_Order__c should be null');
        AmendmentUtils.updateChangeRequest(cr);
        AmendmentUtils.executeFullCancelRebill(cr,new list<Id>());
        AmendmentUtils.executeUnHoldOrder(cr);
        Test.stopTest();
    }
    
    @isTest
    static void unitTest2(){
        Test.startTest();
        Change_Request__c cr = [Select Id,Change_Request_Status__c,New_Order__c,Type_of_Change__c,Opportunity__c,Order_IDs__c 
                                from Change_Request__c Where New_Order__c!=null];
        Change_Request__c cr2 = AmendmentUtils.getChangeRequest(cr.Id);
        system.assertNotEquals(null, cr2.New_Order__c,'Order Can not be null');
        AmendmentUtils.updateChangeRequest(cr);
        AmendmentUtils.executeFullCancelRebill(cr,new list<Id>());
        AmendmentUtils.executeUnHoldOrder(cr);
        AmendmentUtils.fetchIOMAmdCatDetails();
        list<Change_Request__c>crList = new list<Change_Request__c>();
        crList.add(cr);
        AmendmentUtils.createAmendmentTransactionRequests(crList,GlobalConstants.CHANGE_REQUEST_COMPLETED,'PUT');
        Test.stopTest();
    }
    
    @isTest
    static void unitTest3(){
        
        Change_Request__c cr = [Select Id,Change_Request_Status__c,New_Order__c,Type_of_Change__c,Opportunity__c from Change_Request__c Where New_Order__c!=null];
        contract crt = Database.query('SELECT Id  FROM contract where SBQQ__Order__c  = \''+cr.New_Order__c+'\'');
        cr.New_Order__c = null;
        cr.Type_of_Change__c = '';
        cr.Contract__c = crt.Id;
        
        Test.startTest();
        cr.Amended_Quote_Id__c = AmendmentUtils.amendOpportunity(cr);
        
        System.assertNotEquals(null, cr.Amended_Quote_Id__c,'Amendment Process Failed');
        
        AmendmentUtils.executeFullCancelRebillQuote(cr);
        try{AmendmentUtils.executePartialCreditORAddtionalInvoiceQuote(cr);}catch(Exception e){system.debug(logginglevel.DEBUG,'Error --> '+e.getMessage());}
        Test.stopTest();
    }
    
    @isTest
    static void completeAmendmentProcessTest(){
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c LIMIT 1');
        
        Order order = Database.query('SELECT Id ,AccountId,OpportunityId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        con.email = 'test256456564@abc.com';
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
            listTaxLines.add(taxLine);
            
            blng__CreditNoteLine__c crNoteLine = new blng__CreditNoteLine__c();
            crNoteLine.blng__CreditNote__c = crNote.Id;
            crNoteLine.blng__Product__c = invLine.blng__Product__c;
            crNoteLine.Line_Item_Number__c = invLine.Line_Item_Number__c;
            crNoteLine.blng__InvoiceLine__c = invLine.Id;
            crNoteLine.blng__TotalAmount__c = 10;
            listCreditNoteLines.add(crNoteLine);
        }
        insert listTaxLines;
        insert listCreditNoteLines;
        
        crNote.blng__Status__c = 'Posted';
        update crNote;
        
        Change_Request__c cr = new Change_Request__c(Account__c=order.AccountId,Opportunity__c=order.OpportunityId,Type_of_Change__c='PO number change',Edition__c=quote.Edition__c,ERP_Ref_Numbers__c='IM-IV00326,CN-003625');
        insert cr;
        
        string invCnListJSON = AmendmentUtils.getAllInvoicesAndCreditNotes(cr.Opportunity__c);
        AmendmentUtils.getAllInvoices(cr);
        map<string,Object> dataObj = (Map<String, Object>)JSON.deserializeUntyped(invCnListJSON);
        List<sObject> sobjList = new List<sObject>();
        sobjList.addAll((List<sObject>)JSON.deserialize(JSON.serialize(dataObj.get('Invoices')),List<sObject>.Class));
        //sobjList.addAll((List<sObject>)JSON.deserialize(JSON.serialize(dataObj.get('CreditNotes')),List<sObject>.Class));      
        AmendmentUtils.completeAmendmentProcess(cr);
        
        Integer totalItems = Database.countQuery('Select Count() from API_Synchronization_Item__c');
        System.assertNotEquals(0,totalItems,'No Items to process Created');
        System.assertEquals(3,totalItems,'All Items Not Created');
    }
    
    @isTest
    static void updateChangeRequestTest01(){
        Change_Request__c cr = [Select Id,Opportunity__c from Change_Request__c limit 1];
        Account acc = [Select id from Account Limit 1];
        contact con = [Select id from Contact limit 1];
        Order order = Database.query('SELECT Id , Status FROM Order WHERE OpportunityId  = \''+cr.Opportunity__c+'\'');
        order.EffectiveDate = Date.today().addDays(70);
        order.Tax_Status__c = 'Tax Complete';
        //update order;
        order.Status='Activated';
        //update order;
        //order.SBQQ__Contracted__c =true;
        //update order;
        //order.blng__BillNow__c=true;    
        Test.startTest(); 
        //update order;
        System.assertNotEquals(null,acc.Id,'No Account Found');
        String dataObjJSON = '{"amendmentObj":{"Id":"'+cr.Id+'","Amendment_Type__c":"Bill To Account Change;Billing Address Change;Account Name Change;Update Bill To Contact;Bill to Contact Details Change;PO number change","New_Billing_Street__c":"1311 Simpson Street","New_Billing_City__c":"Orekhovo-zuevo","New_Billing_Postal_Code__c":"61201","Old_Billing_Street__c":"1312 Simpson Street","Old_Billing_State__c":"Illinois","Old_Billing_Postal_Code__c":"61201","Old_Billing_Country__c":"United States","Old_Billing_City__c":"Rock Island","New_PO_Number__c":"T-PO-14534","Old_PO_Number__c":"T-PO-23456","New_Billing_Account__c":"'+acc.Id+'","Old_Billing_Account__c":"'+acc.Id+'","New_Billing_Contact__c":"'+con.Id+'","Old_Bill_To_Contact__c":"'+con.Id+'","New_Account_NameD__c":"Impossible Mission Forceu","Old_Account_Name__c":"Impossible Mission Force","New_Contact_FirstName__c":"Ethan o","New_Contact_LastName__c":"Hunt","New_Contact_Phone__c":"9868789976","New_Contact_Email__c":"ethan.hunt@imf.com","Old_Contact_FirstName__c":"Ethan","Old_Contact_LastName__c":"Hunt","Old_Contact_Email__c":"ethan.hunt@imf.com"},"opportunityObj":{"PO_Number__c":"T-PO-14534","Bill_To_Account__c":"'+acc.Id+'","Billing_Contact__c":"'+con.Id+'","Id":"'+cr.Opportunity__c+'"},"billToAccountObj":{"BillingStreet":"1311 Simpson Street","BillingCity":"Orekhovo-zuevo","BillingCountryCode":"US","BillingStateCode":"IL","BillingPostalCode":"61201","Name":"Impossible Mission Forceu","Id":"'+acc.id+'"},"billToContactObj":{"FirstName":"Ethan o","LastName":"Hunt","Email":"ethan.hunt@imf.com","Phone":"9868789976","Id":"'+con.Id+'"}}';
        
        AmendmentUtils2.updateChangeRequest(dataObjJSON);
        Test.stopTest();
    }
    /*** AmendmentUtils2 */
    
    /** @description testexecuteReBillOrder*/
    @isTest
    static void testexecuteReBillOrder(){
        Test.startTest();
        Change_Request__c cr = [SELECT Id,Change_Request_Status__c,New_Order__c,Type_of_Change__c,Opportunity__c,Order_IDs__c  
                                FROM Change_Request__c WHERE New_Order__c!=null];
        Change_Request__c cr2 = AmendmentUtils.getChangeRequest(cr.Id);
        System.assertNotEquals(null, cr2.New_Order__c,'Order Can not be null');
        AmendmentUtils.executeFullCancelRebill(cr,new List<Id>());
        Order ord = [SELECT Id FROM Order WHERE Id=:cr.New_Order__c];
        blng__BillingConfig__c disableBillingTrigger = new blng__BillingConfig__c(Name = 'DISABLE_TRIGGERS',
                                                                          blng__FieldType__c = 'Boolean',
                                                                          blng__Description__c = 'Disable triggers',
                                                                          blng__Category__c ='General',
                                                                          blng__BooleanValue__c = true);
        insert  disableBillingTrigger;
        ord.Tax_Status__c = 'Tax Complete';
        update ord;
        delete [SELECT Id FROM blng__BillingSchedule__c];
        ord.Status='Activated';
        update ord;
        AmendmentUtils2.executeReBillOrder(cr);
        Test.stopTest();
    }
    
    @isTest
    static void testCompleteAmendmentProcess(){
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c LIMIT 1');
        
        Order order = Database.query('SELECT Id ,AccountId,OpportunityId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        con.email = 'test256456564@abc.com';
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
            listTaxLines.add(taxLine);
            
            blng__CreditNoteLine__c crNoteLine = new blng__CreditNoteLine__c();
            crNoteLine.blng__CreditNote__c = crNote.Id;
            crNoteLine.blng__Product__c = invLine.blng__Product__c;
            crNoteLine.Line_Item_Number__c = invLine.Line_Item_Number__c;
            crNoteLine.blng__InvoiceLine__c = invLine.Id;
            crNoteLine.blng__TotalAmount__c = 10;
            listCreditNoteLines.add(crNoteLine);
        }
        insert listTaxLines;
        insert listCreditNoteLines;
        
        crNote.blng__Status__c = 'Posted';
        update crNote;
        
        Change_Request__c cr = new Change_Request__c(Account__c=order.AccountId,Opportunity__c=order.OpportunityId,Amendment_Type__c='PO number change;Cancellation',Edition__c=quote.Edition__c,ERP_Ref_Numbers__c='IM-IV00326,CN-003625');
        insert cr;
        
        Test.startTest();
        String x3rderp = 'Oracle';
        AmendmentUtils2.completeAmendmentProcess(cr,x3rderp);
        AmendmentUtils.completeAmendmentProcess(cr);
        AmendmentUtils2.cancleInvoies(new List<Id>{inv.Id});
        Test.stopTest();        
        Integer totalItems = Database.countQuery('Select Count() from API_Synchronization_Item__c');
        System.assertNotEquals(0,totalItems,'No Items to process Created');        
        AmendmentUtils2.isQuoteCalculationInProgress(order.OpportunityId);
    }
    
    //Adress Validate
    @IsTest
    private static void testGoogleAddress() {
        Test.startTest();          
        Test.setMock(HttpCalloutMock.class, new AddressAutoComplete());
        string responseAC = AmendmentUtils2.getAddressAutoComplete('123 creek lane');
        System.assert(responseAC != NULL, 'Response should not be NULL');        
        string response = AmendmentUtils2.getAddressDetails('testplaceid');
        System.assert(response != NULL, 'Response should not be NULL');
        Test.stopTest();
    }
    
    @IsTest
    private static void updateChangeRequestTest02() {
        Change_Request__c cr = [Select Id,Opportunity__c from Change_Request__c limit 1];
        Account acc = [Select id from Account Limit 1];
        contact con = [Select id from Contact limit 1];
        Translated_Record__c trans = new Translated_Record__c(Account__c=acc.Id,Translated_Account_Name__c='wqwqwqwq',Translated_Language__c='ar');
        insert trans;
        AmendmentUtils2.getOpportunityRecord('Name',cr.Opportunity__c);
        List<Order> orders = AmendmentUtils2.getAllOrders(cr.Opportunity__c);
        string oliJSON = '';
        for(OrderItem oi : [SELECT Id,ServiceDate,EndDate,UnitPrice,SBQQ__QuoteLine__c FROM OrderItem WHERE OrderId in:orders]) 
        {
            oliJSON += '{"Id":"'+oi.Id+'","ServiceDate":"'+String.valueOf(oi.ServiceDate.addDays(30))+'"},';
        }            
        System.assertNotEquals(null,acc.Id,'No Account Found');
        String dataObjJSON = '{"amendmentObj":{"Id":"'+cr.Id+'","Amendment_Type__c":"Ship To Account Change;Billing Address Change;Account Name Change;Update Bill To Contact;Bill to Contact Details Change;PO number change;VAT Registration Number Change;Bill To Account Change","Opportunity__c":"'+cr.Opportunity__c+'"},"shipToAccountObj":{"BillingStreet":"1311 Simpson Street","BillingCity":"Orekhovo-zuevo","BillingCountryCode":"US","BillingStateCode":"IL","BillingPostalCode":"61201","Name":"Impossible Mission Forceu","Id":"'+acc.id+'"},"billToAccountObj":{"BillingStreet":"1311 Simpson Street","BillingCity":"Orekhovo-zuevo","BillingCountryCode":"US","BillingStateCode":"IL","BillingPostalCode":"61201","Name":"Impossible Mission Forceu","Id":"'+acc.id+'"},"opportunityObj":{"PO_Number__c":"T-PO-14534","Bill_To_Account__c":"'+acc.Id+'","Billing_Contact__c":"'+con.Id+'","Id":"'+cr.Opportunity__c+'"},"accTaxObj":{"Account__c":"'+acc.id+'","Tax_ID__c":"61201"},"billToAccountTransObj":{"Id":"'+trans.id+'","Translated_Account_Name__c":"asasasa"},"shipToAccountTransObj":{"Id":"'+trans.id+'","Translated_Account_Name__c":"asasasa"},"orderItemsObj":['+oliJSON.removeEnd(',')+']}';
        Test.startTest();
        AmendmentUtils2.updateChangeRequest(dataObjJSON);
        Test.stopTest();
    }

    @IsTest
    private static void updateChangeRequestTest02Negative() {
        Change_Request__c cr = [Select Id,Opportunity__c from Change_Request__c limit 1];
        Account acc = [Select id from Account Limit 1];
        contact con = [Select id from Contact limit 1];
        AmendmentUtils2.getOpportunityRecord('Name',cr.Opportunity__c);
        List<Order> orders = AmendmentUtils2.getAllOrders(cr.Opportunity__c);
        string oliJSON = '';
        for(OrderItem oi : [SELECT Id,ServiceDate,EndDate,UnitPrice,SBQQ__QuoteLine__c FROM OrderItem WHERE OrderId in:orders]) 
        {
            oliJSON += '{"Id":"'+oi.Id+'","ServiceDate":"'+String.valueOf(oi.ServiceDate.addDays(30))+'"},';
        }            
        System.assertNotEquals(null,acc.Id,'No Account Found');
        String dataObjJSON = '{"amendmentObj":{"Id":"'+cr.Id+'","Amendment_Type__c":"Ship To Account Change;Billing Address Change;Account Name Change;Update Bill To Contact;Bill to Contact Details Change;PO number change;VAT Registration Number Change;Bill To Account Change","Opportunity__c":"'+cr.Opportunity__c+'"},"shipToAccountObj":{"BillingStreet":"1311 Simpson Street","BillingCity":"Orekhovo-zuevo","BillingCountryCode":"US","BillingStateCode":"IL","BillingPostalCode":"61201","Name":"Impossible Mission Forceu","Id":"'+acc.id+'"},"billToAccountObj":{"BillingStreet":"1311 Simpson Street","BillingCity":"Orekhovo-zuevo","BillingCountryCode":"US","BillingStateCode":"IL","BillingPostalCode":"61201","Name":"Impossible Mission Forceu","Id":"'+acc.id+'"},"opportunityObj":{"PO_Number__c":"T-PO-14534","Bill_To_Account__c":"'+acc.Id+'","Billing_Contact__c":"'+con.Id+'","Id":"'+cr.Opportunity__c+'"},"accTaxObj1":{"Account__c":"'+acc.id+'","Tax_ID__c":"61201"},"orderItemsObj":['+oliJSON.removeEnd(',')+']}';
        Test.startTest();
        AmendmentUtils2.updateChangeRequest(dataObjJSON);
        Test.stopTest();
    }

    private class AddressAutoComplete implements HTTPCalloutMock{
        /**
* @description AddressAutoComplete Mock for test class
* @param req
* @return HTTPResponse
*/
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/JSON');
            res.setBody('{predictions : [{description : Girikon - Salesforce Consulting, North Tatum Boulevard, Phoenix, AZ, USA,id : 36f85aab59c54f4d93f3dd5ee5c76ec30837fb55,matched_substrings : [{length : 7,offset : 0}],place_id : ChIJe2Fsc5YNK4cRsyMLNVZi0Po,reference : ChIJe2Fsc5YNK4cRsyMLNVZi0Po,structured_formatting : {main_text : Girikon - Salesforce Consulting,main_text_matched_substrings : [{length : 7,offset : 0}],secondary_text : North Tatum Boulevard, Phoenix, AZ, USA},terms : [{offset : 0,value : Girikon - Salesforce Consulting},{offset : 33,value : North Tatum Boulevard},{offset : 56,value : Phoenix},{offset : 65,value : AZ},{offset : 69,value : USA}],types : [ establishment ]},{description : Girikon USA, South 48th Street, Tempe, AZ, USA,id : 35c9ef1cb6700c0754f5e9c46d79e83ae906841f,matched_substrings : [{length : 7,offset : 0}],place_id : ChIJwXcapeAOK4cR1jC6B-hR7nk,reference : ChIJwXcapeAOK4cR1jC6B-hR7nk,structured_formatting : {main_text : Girikon USA,main_text_matched_substrings : [{length : 7,offset : 0}],secondary_text : South 48th Street, Tempe, AZ, USA},terms : [{offset : 0,value : Girikon USA},{offset : 13,value : South 48th Street},{offset : 32,value : Tempe},{offset : 39,value : AZ},{offset : 43,value : USA}],types : [ establishment ]},{description : Kirkenes, Norway,id : c5273ef6d456f35e6cc08dd7bc856f0f96fdac9b,matched_substrings : [{length : 8,offset : 0}],place_id : ChIJD0qdGM5Iy0URrY07tVlYRyE,reference : ChIJD0qdGM5Iy0URrY07tVlYRyE,structured_formatting : {main_text : Kirkenes,main_text_matched_substrings : [{length : 8,offset : 0}],secondary_text : Norway},terms : [{offset : 0,value : Kirkenes},{offset : 10,value : Norway}],types : [ locality, political, geocode ]},{description : Girkonjárgohppi, Russenes, Norway,id : 270ddcbe7b7058d4c1f5adb4f92973e926b77d2d,matched_substrings : [{length : 6,offset : 0}],place_id : ChIJPSiTnk8kyUURXQOhSFZjmyg,reference : ChIJPSiTnk8kyUURXQOhSFZjmyg,structured_formatting : {main_text : Girkonjárgohppi,main_text_matched_substrings : [{length : 6,offset : 0}],secondary_text : Russenes, Norway},terms : [{offset : 0,value : Girkonjárgohppi},{offset : 17,value : Russenes},{offset : 27,value : Norway}],types : [ natural_feature, establishment, geocode ]},{description : Girkonuorri, Tana, Norway,id : 9a66fe5ad1ca6c2a1cf8a0e1ea9c6daebc1738b5,matched_substrings : [{length : 6,offset : 0}],place_id : ChIJ0_VBaMeWy0UReKPpORLIbag,reference : ChIJ0_VBaMeWy0UReKPpORLIbag,structured_formatting : {main_text : Girkonuorri,main_text_matched_substrings : [{length : 6,offset : 0}],secondary_text : Tana, Norway},terms : [{offset : 0,value : Girkonuorri},{offset : 13,value : Tana},{offset : 19,value : Norway}],types : [ natural_feature, establishment, geocode ]}],status : OK}');
            res.setStatusCode(200);
            return res;
        }
    }
}