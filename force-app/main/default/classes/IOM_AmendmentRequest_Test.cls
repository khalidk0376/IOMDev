/**
* File      	:   IOM_AmendmentRequest_Test
* Project       : 	Informa Order Management 
* Created By  	:   Ashish(Girikon)
* Created Date  :   27th Dec 2021
* ******************************************************************************************************
* @description 	: Test Class to provide code covrage to classes - IOM_AmendmentRequestUtils() 
* Last Modified By :
*/
@isTest
public with sharing class IOM_AmendmentRequest_Test {
    @testsetup
    static void createdata(){
        Id pricebookId = Test.getStandardPricebookId(); // StandardPricebook
        
        Product2 packagePrd = new Product2(Name = 'Booth Package');
        insert packagePrd; // Main Package Product
        
        PricebookEntry pbStndrdPriceP = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = packagePrd.Id, UnitPrice = 100, IsActive = true);
        insert pbStndrdPriceP;
        
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
        oCon1.LastName = 'ContTest11';
        oCon1.Email = 'abcd1@gmail.com';
        oCon1.AccountId = acc1.Id;
        oCon1.MailingStreet = 'Test1';
        oCon1.MailingCity = 'Test1';
        oCon1.MailingState='';
        oCon1.MailingCountry='India';
        oCon1.Phone = 'aa345564788a'; 
        //oCon1.Inactive__c = false;
        oCon1.AssistantPhone = '+12445567788'; 
        oCon1.HomePhone = '+12345567388'; 
        oCon1.MobilePhone = '+12335567788'; 
        oCon1.OtherPhone = '+12346567788';
        insert oCon1;   
    }

    
    @isTest static void testvalidatepositive() {
        
        Account acc1 = [Select Id from Account limit 1];
        Product2 packagePrd = [Select Id from Product2 limit 1];
        PricebookEntry pbStndrdPriceP = [Select Id from PricebookEntry limit 1];
        
        
        List<Opportunity> opplst = new List<Opportunity>();
        opportunity opp = new opportunity(Name='World of Concrete 2017',AccountId = acc1.id,Amount=20.00,CloseDate=System.Today(),StageName='Closed Won',Probability = 100.00);
        opplst.add(opp);
        insert opplst;
        
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        oppLineItem.Product2Id = packagePrd.Id;
        oppLineItem.Quantity = 2;
        oppLineItem.PricebookEntryId = pbStndrdPriceP.Id;
        oppLineItem.TotalPrice = 160.00;
        oppLineItem.OpportunityId = opp.Id;
        insert oppLineItem;
        
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{"meta": {"status": "success","message": "The JSON is validated successfully and being processed further."}}';
        mapURIBody.put('mulesoft','200###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new IOM_MulesoftSalesforce_Mock(mapURIBody));
        
        Test.startTest();
        IOM_SendForOrderUtils.testIntegrationMappingRecords = '[{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008PGUEA2"},"Id":"m0J050000008PGUEA2","CRM_Object__c":"01I050000004mNM","CRM_Object_Field__c":"IOM_Opportunity__r.IOM_Opportunity_No__c","IOM_Node_Data_Length__c":240,"IOM_Node_Name__c":"IOMOpportunityId","IOM_Node_Type__c":"Text","Required__c":true,"Record_Id_Filter_Field__c":"Id","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/01I050000004mNM"},"Id":"000000000000000AAA","DurableId":"01I050000004mNM","QualifiedApiName":"IOM_Amendment_Request__c"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008PGFEA2"},"Id":"m0J050000008PGFEA2","CRM_Object__c":"01I050000004mNM","CRM_Object_Field__c":"IOM_Request_Instruction__c","IOM_Node_Data_Length__c":131072,"IOM_Node_Name__c":"RequestInstructions","IOM_Node_Type__c":"Long Text Area","Required__c":true,"Record_Id_Filter_Field__c":"Id","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/01I050000004mNM"},"Id":"000000000000000AAA","DurableId":"01I050000004mNM","QualifiedApiName":"IOM_Amendment_Request__c"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008PGAEA2"},"Id":"m0J050000008PGAEA2","CRM_Object__c":"01I050000004mNM","CRM_Object_Field__c":"IOM_Request_Category__c","IOM_Node_Data_Length__c":80,"IOM_Node_Name__c":"RequestCategory","IOM_Node_Type__c":"Text","Required__c":true,"Record_Id_Filter_Field__c":"Id","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/01I050000004mNM"},"Id":"000000000000000AAA","DurableId":"01I050000004mNM","QualifiedApiName":"IOM_Amendment_Request__c"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008PG5EAM"},"Id":"m0J050000008PG5EAM","CRM_Object__c":"01I050000004mNM","CRM_Object_Field__c":"Name","IOM_Node_Data_Length__c":80,"IOM_Node_Name__c":"AmendmentNumber","IOM_Node_Type__c":"Text","Required__c":true,"Record_Id_Filter_Field__c":"Id","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/01I050000004mNM"},"Id":"000000000000000AAA","DurableId":"01I050000004mNM","QualifiedApiName":"IOM_Amendment_Request__c"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008PGKEA2"},"Id":"m0J050000008PGKEA2","CRM_Object__c":"01I050000004mNM","CRM_Object_Field__c":"IOM_Status__c","IOM_Node_Data_Length__c":240,"IOM_Node_Name__c":"Status","IOM_Node_Type__c":"Text","Required__c":false,"Record_Id_Filter_Field__c":"Id","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/01I050000004mNM"},"Id":"000000000000000AAA","DurableId":"01I050000004mNM","QualifiedApiName":"IOM_Amendment_Request__c"}}]';
        
        IOM_Amendment_Request__c amdReq = new IOM_Amendment_Request__c();
        amdReq.IOM_Opportunity__c = opplst.get(0).id;
        amdReq.IOM_Request_Category__c = 'Cancellation';
        amdReq.IOM_Request_Instruction__c =  'My Test Request Instruction';

        Insert amdReq;
        
        Integer recordCount = Database.countQuery('Select Count() from IOM_Synchronization_Transaction__c where IOM_CRM_Opportunity__c = \''+opplst.get(0).id+'\'');
        System.assertEquals(1, recordCount, 'IOM Synchronization Transaction not created');
        
        Test.stopTest();
       
        amdReq.IOM_Request_Instruction__c =  'My Test Upadted Request Instruction';
        update amdReq;
        Integer recordCount1 = Database.countQuery('Select Count() from IOM_Synchronization_Transaction__c where IOM_CRM_Opportunity__c = \''+opplst.get(0).id+'\'');
        System.assertEquals(1, recordCount1, 'IOM Synchronization Transaction not created');
        
    }
}