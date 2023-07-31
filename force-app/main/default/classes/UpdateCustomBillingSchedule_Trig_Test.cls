/**
* File			: 	UpdateCustomBillingSchedule_Trig_Test
* Project      	:   GECI
* Created By	: 	IBM
* Created Date	: 	4th Jan 2023
* ************************************************************************************
* @description : Test Class to provide code coverage to classes - UpdateCustomBillingSchedule_Trig
* Last Modified By :
*/
@IsTest
public class UpdateCustomBillingSchedule_Trig_Test {
	
    @testSetup 
    static void setup() 
    {
        blng__LegalEntity__c billingLegalEntity = TestDataFactory.setupLegalEntity();
        
        //Insert Series
        Series__c seriesObj = new Series__c();
        seriesObj.Name = 'testSeries';
        seriesObj.Status__c = 'Active';
        seriesObj.Legal_Entity__c = billingLegalEntity.Id;
        insert seriesObj;
        
        // create list of edition to be used on the quote
        Edition__c edition =  new Edition__c();
        edition.Name = 'testEdition 2022';
        edition.Part_of_Series__c = seriesObj.Id;
        edition.Order_Creation__c = false;
        edition.Order_Activation__c = true;
        edition.Contract_Creation__c = true;
        edition.Invoice_Creation__c = true;
        edition.External_Tax_System__c = GlobalConstants.ONESOURCE;
        edition.External_Relationship__c = true; 
        insert edition;
    }
    static testMethod void customBillingScheduleUpdate2() {
        
        Set<Id> setIds = new Set<Id>();
        Account oacc = new Account (Name = 'testAccount',Legacy_CRM_Instance__c = 'Penton',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;
        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, before_Insert__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();
        TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All'); 

        Contact oCon = new Contact(LastName = 'ContTest1',Legacy_CRM_Instance__c = 'Penton', Email = 'test1contact@duptest.com', AccountId = oacc.Id, MailingStreet = 'Test', MailingCity = 'Test', MailingState = '', MailingCountry = 'India');
        insert oCon;

        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');

        Opportunity oOpportunity = new Opportunity(Default_Edition__c=edtn.Id,Name = 'Expocad Opportunity', CloseDate = Date.today(), StageName = 'Proposal', AccountId = oacc.Id, Billing_Contact__c = oCon.Id, Bill_To_Account__c = oacc.Id);
        insert oOpportunity;

        SBQQ__Quote__c oQuote = new SBQQ__Quote__c(CurrencyIsoCode = 'USD', SBQQ__Status__c = 'Quote Sent', SBQQ__Type__c = 'Quote', SBQQ__Opportunity2__c = oOpportunity.Id, SBQQ__Account__c = oacc.Id);
        insert oQuote;

        Test.startTest();
        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), StageName = 'Closed Won' , Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,  Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 5 , Start_Date__c = Date.today() , Custom_Payment__c = true);
        insert opp1;
        opp1.Total_No_of_payment__c = 2;
        opp1.Milestone_1_Percent__c = 50;
        opp1.Milestone_2_Percent__c = 50;
        update opp1;
        system.assertEquals('ContTest1', oCon.LastName, true) ;
        
        Paymentschedule_cls.getallDataRecord(opp1.Id);
        Paymentschedule_cls.saveData(opp1);
        Paymentschedule_cls.getPaymentPicklistValues(opp1.Id);
        Test.stopTest();

    }
    static testMethod void customBillingScheduleUpdate3() {
        Account oacc = new Account (Name = 'testAccount',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;

        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();         TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All');

        Test.startTest();
        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');

        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), StageName = 'Closed Won', Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,   Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 5 , Start_Date__c = Date.newInstance(2018, 3, 3) , Custom_Payment__c = true);
        insert opp1;
        opp1.Total_No_of_payment__c = 3;
        opp1.Milestone_3_Amount__c = 3;
        opp1.Milestone_1_Percent__c = 30;
        opp1.Milestone_2_Percent__c = 30;
        opp1.Milestone_3_Percent__c = 40;
        update opp1;
        system.assertEquals('OpportunityTest', opp1.name, true) ;
        Test.stopTest();
    }
    static testMethod void unitTest4() {
        Account oacc = new Account (Name = 'testAccount',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;
        
        

        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();         TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All');

        Test.startTest();
        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');

        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), StageName = 'Closed Won' , Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,   Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 5 , Start_Date__c = Date.newInstance(2018, 3, 3) , Custom_Payment__c = true, Payment_Status__c = 'Invoice' );
        insert opp1;
        opp1.Total_No_of_payment__c = 4;
        opp1.Milestone_4_Amount__c = 4;
        opp1.Milestone_1_Percent__c = 25;
        opp1.Milestone_2_Percent__c = 25;
        opp1.Milestone_3_Percent__c = 25;
        opp1.Milestone_4_Percent__c = 25;
        opp1.Payment_Status__c = 'Paid';
        update opp1;
        system.assertEquals('OpportunityTest', opp1.name, true) ;
        Test.stopTest();
    }
    static testMethod void customBillingScheduleUpdate5() {
        Account oacc = new Account (Name = 'testAccount',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;
        
        
        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();         TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All');
       
        Test.startTest();
        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');

        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), StageName = 'Closed Won' , Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,   Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 4 , Start_Date__c = Date.newInstance(2018, 3, 3) , Custom_Payment__c = true);
        insert opp1;
        opp1.Total_No_of_payment__c = 5 ;
        opp1.Milestone_5_Amount__c = 5;
        opp1.Milestone_1_Percent__c = 20;
        opp1.Milestone_2_Percent__c = 20;
        opp1.Milestone_3_Percent__c = 20;
        opp1.Milestone_4_Percent__c = 20;
        opp1.Milestone_5_Percent__c = 20;
        update opp1;
        system.assertEquals('OpportunityTest', opp1.name, true) ;
        Test.stopTest();
    }
    static testMethod void customBillingScheduleUpdate6() {
        Account oacc = new Account (Name = 'testAccount',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;
        
        
        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All');
        
        Test.startTest();
        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');

        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), StageName = 'Closed Won' , Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,   Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 5 , Start_Date__c = Date.newInstance(2018, 3, 3) , Custom_Payment__c = true);
        insert opp1;
        opp1.Total_No_of_payment__c = 6 ;
        opp1.Milestone_1_Percent__c = 15;
        opp1.Milestone_2_Percent__c = 15;
        opp1.Milestone_3_Percent__c = 15;
        opp1.Milestone_4_Percent__c = 15;
        opp1.Milestone_5_Percent__c = 15;
        opp1.Milestone_6_Percent__c = 25;
        update opp1;
        system.assertEquals('OpportunityTest', opp1.name, true) ;
        Test.stopTest();
    }
    static testMethod void customBillingScheduleUpdate7() {
        Account oacc = new Account (Name = 'testAccount',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;
        
        
        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();         TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All');
       
        Test.startTest();
        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');

        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), StageName = 'Closed Won' , Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,  Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 5 , Start_Date__c = Date.newInstance(2018, 3, 3) , Custom_Payment__c = true);
        insert opp1;
        opp1.Total_No_of_payment__c = 7 ;
        opp1.Milestone_1_Percent__c = 15;
        opp1.Milestone_2_Percent__c = 15;
        opp1.Milestone_3_Percent__c = 15;
        opp1.Milestone_4_Percent__c = 15;
        opp1.Milestone_5_Percent__c = 15;
        opp1.Milestone_6_Percent__c = 15;
        opp1.Milestone_7_Percent__c = 10;
        update opp1;
        system.assertEquals('OpportunityTest', opp1.name, true) ;
        Test.stopTest();
    }
    static testMethod void customBillingScheduleUpdate8() {
        Account oacc = new Account (Name = 'testAccount',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;
        
        
        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();         TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All');
       
        Test.startTest();
        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');

        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), StageName = 'Closed Won' , Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,  Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 5 , Start_Date__c = Date.newInstance(2018, 3, 3) , Custom_Payment__c = true);
        insert opp1;
        opp1.Total_No_of_payment__c = 8 ;
        opp1.Milestone_1_Percent__c = 30;
        opp1.Milestone_2_Percent__c = 10;
        opp1.Milestone_3_Percent__c = 10;
        opp1.Milestone_4_Percent__c = 10;
        opp1.Milestone_5_Percent__c = 10;
        opp1.Milestone_6_Percent__c = 10;
        opp1.Milestone_7_Percent__c = 10;
        opp1.Milestone_8_Percent__c = 10;
        update opp1;
        system.assertEquals('OpportunityTest', opp1.name, true) ;
        Test.stopTest();
    }
    static testMethod void customBillingScheduleUpdate9() {
        Account oacc = new Account (Name = 'testAccount',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;
        
        
        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();         TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All');
      
        Test.startTest();
        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');

        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), StageName = 'Closed Won' , Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,   Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 5 , Start_Date__c = Date.newInstance(2018, 3, 3), Custom_Payment__c = true);
        insert opp1;
        opp1.Total_No_of_payment__c = 9 ;
        opp1.Milestone_1_Percent__c = 20;
        opp1.Milestone_2_Percent__c = 10;
        opp1.Milestone_3_Percent__c = 10;
        opp1.Milestone_4_Percent__c = 10;
        opp1.Milestone_5_Percent__c = 10;
        opp1.Milestone_6_Percent__c = 10;
        opp1.Milestone_7_Percent__c = 10;
        opp1.Milestone_8_Percent__c = 10;
        opp1.Milestone_9_Percent__c = 10;
        update opp1;
        system.assertEquals('OpportunityTest', opp1.name, true) ;
        Test.stopTest();
    }
    static testMethod void customBillingScheduleUpdate10() {
        Account oacc = new Account (Name = 'testAccount',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;
        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();         TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All');
        

        Test.startTest();
        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');

        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), StageName = 'Closed Won' , Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,  Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 5  , Start_Date__c = Date.newInstance(2018, 3, 3), Custom_Payment__c = true);
        insert opp1;
        opp1.Total_No_of_payment__c = 10 ;
        opp1.Milestone_1_Percent__c = 10;
        opp1.Milestone_2_Percent__c = 10;
        opp1.Milestone_3_Percent__c = 10;
        opp1.Milestone_4_Percent__c = 10;
        opp1.Milestone_5_Percent__c = 10;
        opp1.Milestone_6_Percent__c = 10;
        opp1.Milestone_7_Percent__c = 10;
        opp1.Milestone_8_Percent__c = 10;
        opp1.Milestone_9_Percent__c = 10;
        opp1.Milestone_10_Percent__c = 10;
        update opp1;
        system.assertEquals('OpportunityTest', opp1.name, true) ;
        Test.stopTest();
    }
    static testMethod void customBillingScheduleUpdate11() {
        Account oacc = new Account (Name = 'testAccount',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;
        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();         TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All');
        

        Test.startTest();
        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');

        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), StageName = 'Closed Won' , Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,  Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 5 , Start_Date__c = Date.newInstance(2018, 3, 3) , Custom_Payment__c = true);
        insert opp1;
        opp1.Total_No_of_payment__c = 11 ;
        opp1.Milestone_1_Percent__c = 10;
        opp1.Milestone_2_Percent__c = 10;
        opp1.Milestone_3_Percent__c = 10;
        opp1.Milestone_4_Percent__c = 10;
        opp1.Milestone_5_Percent__c = 10;
        opp1.Milestone_6_Percent__c = 10;
        opp1.Milestone_7_Percent__c = 10;
        opp1.Milestone_8_Percent__c = 10;
        opp1.Milestone_9_Percent__c = 10;
        opp1.Milestone_10_Percent__c = 5;
        opp1.Milestone_11_Percent__c = 5;
        update opp1;
        system.assertEquals('OpportunityTest', opp1.name, true) ;
        Test.stopTest();
    }

    static testMethod void customBillingScheduleUpdate12() {
        Account oacc = new Account (Name = 'testAccount',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;

        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();         TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All');
        

        Test.startTest();
        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');

        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), StageName = 'Closed Won' , Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,   Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 5 , Start_Date__c = Date.newInstance(2018, 3, 3), Custom_Payment__c = true);
        insert opp1;
        opp1.Total_No_of_payment__c = 12 ;
        opp1.Milestone_1_Percent__c = 10;
        opp1.Milestone_2_Percent__c = 10;
        opp1.Milestone_3_Percent__c = 10;
        opp1.Milestone_4_Percent__c = 10;
        opp1.Milestone_5_Percent__c = 10;
        opp1.Milestone_6_Percent__c = 10;
        opp1.Milestone_7_Percent__c = 10;
        opp1.Milestone_8_Percent__c = 10;
        opp1.Milestone_9_Percent__c = 5;
        opp1.Milestone_10_Percent__c = 5;
        opp1.Milestone_11_Percent__c = 5;
        opp1.Milestone_12_Percent__c = 5;
        update opp1;
        system.assertEquals('OpportunityTest', opp1.name, true) ;
        Test.stopTest();
    }
    static testMethod void customBillingScheduleUpdate01() {
        Account oacc = new Account (Name = 'testAccount',Legacy_CRM_Instance__c = 'Penton',Address_Status__c = 'Valid',Accounting_Credit_Hold__c = 'OK',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;
        
        Contact oCon = new Contact(LastName = 'ContTest1',Legacy_CRM_Instance__c = 'Penton', Email = 'test1contact@duptest.com', AccountId = oacc.Id, MailingStreet = 'Test', MailingCity = 'Test', MailingState = '', MailingCountry = 'India');
        insert oCon;
        
        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();         TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All');
        

        Test.startTest();
        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');
        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), Address_Status__c ='Valid' , StageName = 'Closed Won' , Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,   Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 5 , Start_Date__c = Date.newInstance(2018, 3, 3) , Custom_Payment__c = true);
        insert opp1;
        opp1.Total_No_of_payment__c = 1;
        opp1.Milestone_1_Percent__c = 100;
        update opp1;
        system.assertEquals('OpportunityTest', opp1.name, true) ;
        Test.stopTest();
    }
    static testMethod void customBillingScheduleUpdateNoCustomBilling() {
        
        Set<Id> setIds = new Set<Id>();
        Account oacc = new Account (Name = 'testAccount',Legacy_CRM_Instance__c = 'Penton',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;
        Trigger__c trig = new Trigger__c(Name = 'UpdateCustomBillingSchedule_Trig' , Trigger_Name_Unique__c = 'UpdateCustomBillingSchedule_Trig', Enabled__c = true, Object__c = 'Opportunity', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Update__c = true, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterface_Opportunity obj=new TriggerInterface_Opportunity();
        TriggerInterfaceHelper.runTrigger('UpdateCustomBillingSchedule_Trig','Opportunity',5, 'bu', null,null,'All'); 

        Contact oCon = new Contact(LastName = 'ContTest1',Legacy_CRM_Instance__c = 'Penton', Email = 'test1contact@duptest.com', AccountId = oacc.Id, MailingStreet = 'Test', MailingCity = 'Test', MailingState = '', MailingCountry = 'India');
        insert oCon;

        Edition__c edtn = Database.query('Select Id from Edition__c Limit 1');

        Opportunity oOpportunity = new Opportunity(Default_Edition__c=edtn.Id,Name = 'Expocad Opportunity', CloseDate = Date.today(), StageName = 'Proposal', AccountId = oacc.Id, Billing_Contact__c = oCon.Id, Bill_To_Account__c = oacc.Id);
        insert oOpportunity;

        SBQQ__Quote__c oQuote = new SBQQ__Quote__c(CurrencyIsoCode = 'USD', SBQQ__Status__c = 'Quote Sent', SBQQ__Type__c = 'Quote', SBQQ__Opportunity2__c = oOpportunity.Id, SBQQ__Account__c = oacc.Id);
        insert oQuote;

        Test.startTest();
        Opportunity opp1 = new Opportunity(Default_Edition__c=edtn.Id,name = 'OpportunityTest' , closeDate = Date.Today(), StageName = 'Closed Won' , Milestone_1_Amount__c = 3 , Milestone_2_Amount__c = 2 , Milestone_3_Amount__c = 2 , Milestone_4_Amount__c = 2 , Milestone_5_Amount__c = 2 , Milestone_6_Amount__c = 2 , Milestone_7_Amount__c = 2 , Milestone_8_Amount__c = 2 , Milestone_9_Amount__c = 2 , Milestone_10_Amount__c = 2 , Milestone_11_Amount__c = 2 , Milestone_12_Amount__c = 2 ,  Amount = 1000 , AccountId = oacc.id , Total_No_of_payment__c = 5 , Start_Date__c = Date.today() , Custom_Payment__c = false);
        insert opp1;
        opp1.Total_No_of_payment__c = 2;
        opp1.Milestone_2_Amount__c = 2;
        update opp1;
        system.assertEquals('ContTest1', oCon.LastName, true) ;
        
        Paymentschedule_cls.getallDataRecord(opp1.Id);
        Paymentschedule_cls.saveData(opp1);
        Paymentschedule_cls.getPaymentPicklistValues(opp1.Id);
        Test.stopTest();

    }
}