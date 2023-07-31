/**
* File			: 	UpdateCPQQuoteFields_Trig_Test
* Project      	:   Order & Billing Plateform
* Created By	: 	Ashish(Deepak)
* Created Date	: 	03rd Feb 2022
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - UpdateCPQQuoteFields_Trig
* Last Modified By :
*/
@isTest
private  with sharing Class UpdateCPQQuoteFields_Trig_Test 
{
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
        Trigger__c trig = new Trigger__c(Name = 'UpdateCPQQuoteFields_Trig' , Trigger_Name_Unique__c='UpdateCPQQuoteFields_Trig',Enabled__c=true,Object__c='SBQQ__Quote__c',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,Before_insert__c=true,After_Update__c=true);
        Insert trig;

        // Create an account
        // Account acc = new Account(name='TESTACC',Payment_Term__c='Net 10');
        Account acc = new Account ();
        acc.Name = 'TESTACC';
        acc.currencyisocode='USD';
        acc.BillingStreet ='street2';
        acc.BillingCity='test';
        acc.Legacy_CRM_Instance__c = 'Penton';
        acc.BillingCity='Alaska';
        acc.BillingState='tamil nadu';
        acc.BillingCountryCode='IN';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.Payment_Term__c='Net 10';
        insert acc;
        
        // Create Contact
        Contact oCon = new Contact(LastName = 'ContTest1', Legacy_CRM_Instance__c = 'Penton', Email = 'test1contact@duptest.com', 
        AccountId = acc.Id, MailingStreet = 'Test', MailingCity = 'Test', MailingState = '', 
        MailingCountry = 'India', Phone = '2423122323', AssistantPhone = '2423122323', 
        HomePhone = '2121212121', MobilePhone = '2121212145', OtherPhone = '2154215421');
        insert oCon;
        
        Account_Tax_Number__c atn = new Account_Tax_Number__c(Account__c=acc.Id,Status__c='Valid',Tax_Country__c='US',
         Tax_ID__c='123',Tax_Number_Name__c='123',Start_Date__c=System.today(),End_Date__c=System.today());
        insert atn;

        // setup the Custom Settings
        TestDataFactory.insertBillingCustomSettings();
        blng__LegalEntity__c billingLegalEntity = TestDataFactory.setupLegalEntity();
        
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
            StageName ='Closed Won',
            Default_Edition__c=listOfEditions[0].Id,
            Name ='TESTOPP',Address_Status__c = 'Valid',  
            AccountId=acc.Id,Ship_To_Account__c=acc.Id,Bill_To_Account__c=acc.Id,
        	Billing_Contact__c=oCon.Id,PO_Number__c='1234',Tax_Rule__c='UAE VAT Refund',
            Account_Tax_Number__c=atn.Id);
        
        // set the cutOff dates to the Oppty
        for(Integer i = 1 ; i<= cutOffDatesOppty.size();i++){
            opp.put(mileDelDateApiNamePart1+i+mileDelDateApiNamePart2,cutOffDatesOppty[i-1]);
            opp.put(mileDelPercentApiNamePart1+i+mileDelPercentApiNamePart2,cutOffPercentagesOppty[i-1]);
        }

        insert opp;
    }

    @isTest static void testUpdateCPQQuoteFieldsOnInsert()
    {
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity Limit 1];
        Account acc = [SELECT Id FROM Account Limit 1];
        Edition__c edt = [SELECT Id FROM Edition__c Limit 1];
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote = TestDataFactory.buildTestSFCPQQuote('TESTQUOTECITY',opp.Id, acc.Id, Test.getStandardPricebookId(), 'Quote',edt);
        quote.SBQQ__Primary__c = true; 
        insert quote;
		quote.SBQQ__Status__c = 'Approved';
        update quote;
        SBQQ__Quote__c qt = [SELECT Id FROM SBQQ__Quote__c Limit 1];
        System.assertNotEquals(null,qt,'quote Created');
        Test.stopTest();
    }
}