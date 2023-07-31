/**
* Created By   :   Girikon(Ashish) : JIRA ref: [IML2R-129]
* Created On   :   31 Dec 2019
* ******************************************************************************************************************
* @description  : Test Class to give covrage to [OpportunityOrderCreation_Trig(100%)]
* ******************************************************************************************************************
* Modification log -- 
*           -  [IML2R-208] - Girikon(Ashish)-  6 march 2020, Code Covrage
*/
@istest
private class OpportunityOrderCreation_Trig_Test 
{
    @isTest
    static void test() {
        
        
        //Create Trigger test record 
        Trigger__c trig = new Trigger__c(Name = 'OpportunityOrderCreation_Trig' , Trigger_Name_Unique__c='OpportunityOrderCreation_Trig',Enabled__c=true,Object__c='Opportunity',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,After_Update__c=true,Before_Update__c=true);
        Insert trig;
        
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');    
        Insert rt;   
        
        //Call account  trigger interface
        TriggerInterface_Opportunity obj = new TriggerInterface_Opportunity();
        System.debug(LoggingLevel.DEBUG, obj);
        
        //Call trigger app handler for insert event
        // string accountOnHoldID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Opportunity_Account_Unhold').getRecordTypeId();
        // system.debug('accountOnHoldID: '+accountOnHoldID);
        String recTypeId = [Select Id From RecordType Where sObjectType IN ('opportunity') LIMIT 1].Id;
        System.debug(LoggingLevel.DEBUG, 'recTypeId:'+recTypeId);
        TriggerInterfaceHelper.runTrigger('OpportunityOrderCreation_Trig','Opportunity',5, 'bi', recTypeId,null,'All'); 
        
        //Account Insert
        Account acc2 = new Account ();
        acc2.Name = 'Account2';
        acc2.BillingCity='test';
        acc2.BillingPostalCode='12342';
        acc2.BillingState='Delhi';
        acc2.Legacy_CRM_Instance__c = 'Penton';
        acc2.BillingCountry='INDIA';
        acc2.BillingStreet ='street2';
        acc2.Address_Status__c = 'Valid';
        acc2.Accounting_Credit_Hold__c ='OK';
        insert acc2;
        
        Contact oCon = TestDataFactoryUtils.createContact(acc2.Id);
        oCon.Legacy_CRM_Instance__c = 'Penton';
        insert oCon;
        
        Account acc1 = new Account ();
        acc1.Name = 'Account0';
        acc1.BillingCity='test';
        acc1.BillingPostalCode='12342';
        acc1.BillingState='Delhi';
        acc1.Legacy_CRM_Instance__c = 'GE';
        acc1.BillingCountry='INDIA';
        acc1.BillingStreet ='street2';
        acc1.Address_Status__c = 'Valid';
        acc1.Accounting_Credit_Hold__c ='OK';
        insert acc1;
        
        //Insert Legal Entity
        blng__LegalEntity__c entityObj = new blng__LegalEntity__c();
        entityObj.Name = 'TestLegal';
        entityObj.blng__Active__c = true;
        insert entityObj;
        
        //Insert Series
        Series__c seriesObj = new Series__c();
        seriesObj.Name = 'testSeries';
        seriesObj.Status__c = 'Active';
        seriesObj.Legal_Entity__c = entityObj.Id;
        insert seriesObj;
        
        //Insert Edition
        Edition__c editionObj = new Edition__c();
        editionObj.Name = 'testEdition';
        editionObj.Part_of_Series__c = seriesObj.Id;
        editionObj.Opportunity_Status_When_Ordering__c = 'Awaiting Payment';
        editionObj.Require_SSC_Approval__c = false;
        editionObj.Order_Creation__c = true;
        insert editionObj;
        
        // Insert Association
        Association__c associationObj = new Association__c();
        //associationObj.Product_Edition__c = editionObj.Id;
        associationObj.Series__c = seriesObj.Id;
        Insert associationObj;
        
        //Insert Account Association
        Account_Associations__c  accAssociationObj = new Account_Associations__c ();
        accAssociationObj.Association__c = associationObj.Id;
        accAssociationObj.Account__c = acc2.Id;
        insert accAssociationObj;
        
        System.assertNotEquals(null, editionObj, 'Edition cannot be null');
        
        // Creates second opportunity
        Opportunity oppt2 = new Opportunity(Name ='New mAWS Deal2',Is_Barter_Opportunity__c  = true,Default_Edition__c = editionObj.Id, AccountID = acc2.ID,Address_Status__c = 'Valid',StageName = 'Discover',CloseDate = System.today());
        oppt2.Bill_To_Account__c = acc2.Id;
        oppt2.Ship_To_Account__c = acc2.Id;
        oppt2.Billing_Contact__c = oCon.Id;
        oppt2.Account_Association__c = accAssociationObj.Id;
        insert oppt2;
        
        //Insert SBQQ__Quote
        SBQQ__Quote__c quoteobj = new SBQQ__Quote__c();
        quoteobj.SBQQ__Opportunity2__c = oppt2.Id;
        quoteobj.SBQQ__Primary__c = true;
        quoteobj.SBQQ__Status__c = 'Approved';
        Insert quoteobj;
                
        oppt2.SBQQ__PrimaryQuote__c = quoteobj.Id;
        oppt2.StageName = 'Closed Won';
        oppt2.Status__c = 'Pending Accounting Approval';
        
        Change_Request__c cr2 = new Change_Request__c(Account__c=acc2.Id,Opportunity__c=oppt2.Id,Product_Type__c='Financial',Type_of_Change__c='Cancellation',Amended_Quote_Id__c = quoteobj.Id,Edition__c=editionObj.id,Amended_Opportunity__c=oppt2.Id);
        insert cr2;
        Test.startTest();
        oppt2.Legacy_CRM_Instance__c = 'GE';
        oppt2.Bill_To_Account__c = acc1.Id;
        update oppt2;
        map<Id,Opportunity> mapAmendmentOppids = new map<Id,Opportunity>();
        mapAmendmentOppids.put(oppt2.Id,oppt2);
        OpportunityOrderCreation_Trig.updateChangeRequestStatus(mapAmendmentOppids); 
        Test.stopTest();        
        oppt2.StageName = 'Cancelled';
        update oppt2;
    }
}