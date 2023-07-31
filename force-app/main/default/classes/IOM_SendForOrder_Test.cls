/**
* File          :   IOM_SendForOrder_Test
* Project       :   Informa Order Management 
* Created By    :   Suresh(Girikon)
* Created Date  :   17th Nov 2021
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - IOM_SendForOrderUtils
* Last Modified By :
*/
@isTest
public class IOM_SendForOrder_Test {
    
    private static string testMetadataJSON = '[{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008PCIEA2"},"Id":"m0J050000008PCIEA2","CRM_Object__c":"Opportunity","CRM_Object_Field__c":"Id","IOM_Node_Data_Length__c":255,"IOM_Node_Name__c":"OpportunityId","IOM_Node_Type__c":"Text","Required__c":true,"Record_Id_Filter_Field__c":"Id","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/Opportunity"},"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008PA7EAM"},"Id":"m0J050000008PA7EAM","CRM_Object__c":"Opportunity","CRM_Object_Field__c":"Account.IOM_Account_No__c","IOM_Node_Data_Length__c":255,"IOM_Node_Name__c":"IOMAccountNumber","IOM_Node_Type__c":"Text","Required__c":true,"Record_Id_Filter_Field__c":"Id","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/Opportunity"},"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008P8uEAE"},"Id":"m0J050000008P8uEAE","CRM_Object__c":"OpportunityLineItem","CRM_Object_Field__c":"Product2Id","IOM_Node_Data_Length__c":18,"IOM_Node_Name__c":"Product2Id","IOM_Node_Type__c":"Text","Required__c":true,"Record_Id_Filter_Field__c":"OpportunityId","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/OpportunityLineItem"},"Id":"000000000000000AAA","DurableId":"OpportunityLineItem","QualifiedApiName":"OpportunityLineItem"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008P9OEAU"},"Id":"m0J050000008P9OEAU","CRM_Object__c":"Opportunity","IOM_Node_Name__c":"SourceName","IOM_Node_Type__c":"Text","Required__c":false,"Static_Value__c":"IOM","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/Opportunity"},"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008P8fEAE"},"Id":"m0J050000008P8fEAE","CRM_Object__c":"OpportunityLineItem","CRM_Object_Field__c":"Product2.Name","IOM_Node_Data_Length__c":225,"IOM_Node_Name__c":"ProductName","IOM_Node_Type__c":"Text","Required__c":true,"Record_Id_Filter_Field__c":"OpportunityId","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/OpportunityLineItem"},"Id":"000000000000000AAA","DurableId":"OpportunityLineItem","QualifiedApiName":"OpportunityLineItem"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008P7wEAE"},"Id":"m0J050000008P7wEAE","CRM_Object__c":"Opportunity","CRM_Object_Field__c":"AccountId","IOM_Node_Data_Length__c":255,"IOM_Node_Name__c":"AccountId","IOM_Node_Type__c":"Text","Required__c":true,"Record_Id_Filter_Field__c":"Id","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/Opportunity"},"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008PBAEA2"},"Id":"m0J050000008PBAEA2","CRM_Object__c":"OpportunityContactRole","CRM_Object_Field__c":"Contact.MobilePhone","IOM_Node_Data_Length__c":20,"IOM_Node_Name__c":"ContactMobilePhone","IOM_Node_Type__c":"Phone","Required__c":true,"Record_Id_Filter_Field__c":"OpportunityId","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/OpportunityContactRole"},"Id":"000000000000000AAA","DurableId":"OpportunityContactRole","QualifiedApiName":"OpportunityContactRole"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008P7rEAE"},"Id":"m0J050000008P7rEAE","CRM_Object__c":"Opportunity","CRM_Object_Field__c":"Name","IOM_Node_Data_Length__c":25,"IOM_Node_Name__c":"OpportunityName","IOM_Node_Type__c":"Text","Required__c":true,"Record_Id_Filter_Field__c":"Id","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/Opportunity"},"Id":"000000000000000AAA","DurableId":"Opportunity","QualifiedApiName":"Opportunity"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008P8REAU"},"Id":"m0J050000008P8REAU","CRM_Object__c":"OpportunityLineItem","CRM_Object_Field__c":"ProductCode","IOM_Node_Data_Length__c":255,"IOM_Node_Name__c":"ProductCode","IOM_Node_Type__c":"Text","Required__c":false,"Record_Id_Filter_Field__c":"OpportunityId","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/OpportunityLineItem"},"Id":"000000000000000AAA","DurableId":"OpportunityLineItem","QualifiedApiName":"OpportunityLineItem"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008PACEA2"},"Id":"m0J050000008PACEA2","CRM_Object__c":"OpportunityContactRole","CRM_Object_Field__c":"Contact.IOM_Contact_No__c","IOM_Node_Data_Length__c":255,"IOM_Node_Name__c":"SourceContactNumber","IOM_Node_Type__c":"Text","Required__c":true,"Record_Id_Filter_Field__c":"OpportunityId","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/OpportunityContactRole"},"Id":"000000000000000AAA","DurableId":"OpportunityContactRole","QualifiedApiName":"OpportunityContactRole"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008PBFEA2"},"Id":"m0J050000008PBFEA2","CRM_Object__c":"OpportunityContactRole","CRM_Object_Field__c":"Contact.Account.Name","IOM_Node_Data_Length__c":255,"IOM_Node_Name__c":"AccountName","IOM_Node_Type__c":"Text","Required__c":true,"Record_Id_Filter_Field__c":"OpportunityId","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/OpportunityContactRole"},"Id":"000000000000000AAA","DurableId":"OpportunityContactRole","QualifiedApiName":"OpportunityContactRole"}},{"attributes":{"type":"IOM_Integration_Mapping__mdt","url":"/services/data/v53.0/sobjects/IOM_Integration_Mapping__mdt/m0J050000008P8kEAE"},"Id":"m0J050000008P8kEAE","CRM_Object__c":"OpportunityLineItem","CRM_Object_Field__c":"TotalPrice","IOM_Node_Data_Length__c":80,"IOM_Node_Name__c":"TotalPrice","IOM_Node_Type__c":"Decimal","Required__c":true,"Record_Id_Filter_Field__c":"OpportunityId","CRM_Object__r":{"attributes":{"type":"EntityDefinition","url":"/services/data/v53.0/sobjects/EntityDefinition/OpportunityLineItem"},"Id":"000000000000000AAA","DurableId":"OpportunityLineItem","QualifiedApiName":"OpportunityLineItem"}}]';

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
        acc1.IOM_Account_No__c ='IM-0001';
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
        IOM_SendForOrderUtils.testIntegrationMappingRecords = IOM_SendForOrder_Test.testMetadataJSON;
        IOM_OppFlowTriggerHandler.callApex(new List<Id>{opplst[0].Id}); 
        Test.stopTest();
        Opportunity item = Database.query('Select Id,IOM_Validation_Status__c from Opportunity limit 1');
        system.assertEquals('Success', item.IOM_Validation_Status__c, 'Payload Validation Success');
        
        // Interface Test


    }
    
    @isTest static void testvalidateNegative() {
        
        Account acc1 = [Select Id,IOM_Account_No__c from Account limit 1];
        Product2 packagePrd = [Select Id from Product2 limit 1];
        PricebookEntry pbStndrdPriceP = [Select Id from PricebookEntry limit 1];
        
        List<Opportunity> opplst = new List<Opportunity>();
        opportunity opp = new opportunity(Name='TEST Negative World of Concrete 2017',AccountId = acc1.id,Amount=20.00,CloseDate=System.Today(),StageName='Closed Won',Probability = 100.00);
        opplst.add(opp);
        insert opplst;
        
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        oppLineItem.Product2Id = packagePrd.Id;
        oppLineItem.Quantity = 2;
        oppLineItem.PricebookEntryId = pbStndrdPriceP.Id;
        oppLineItem.TotalPrice = 160.00;
        oppLineItem.OpportunityId = opp.Id;
        insert oppLineItem;

        acc1.IOM_Account_No__c = null;
        update acc1;
        
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{"meta": {"status": "success","message": "The JSON is validated successfully and being processed further."}}';
        mapURIBody.put('mulesoft','200###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new IOM_MulesoftSalesforce_Mock(mapURIBody));
        
        Test.startTest();
        IOM_SendForOrderUtils.testIntegrationMappingRecords = IOM_SendForOrder_Test.testMetadataJSON;
        IOM_OppFlowTriggerHandler.callApex(new List<Id>{opplst[0].Id}); 
        Test.stopTest();
        Opportunity item = Database.query('Select Id,IOM_Validation_Status__c from Opportunity limit 1');
        system.assertEquals('Error', item.IOM_Validation_Status__c, 'Payload Validation Success');
    }
    @isTest static void lengthTypeError() {
        
        Account acc1 = [Select Id from Account limit 1];
        Product2 packagePrd = [Select Id from Product2 limit 1];
        PricebookEntry pbStndrdPriceP = [Select Id from PricebookEntry limit 1];
        List<Opportunity> opplst = new List<Opportunity>();
        opportunity opp = new opportunity(Name='TEST NEG World of Concrete 2017',AccountId = acc1.id,Amount=20.00,CloseDate=System.Today(),StageName='Closed Won',Probability = 100.00);
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
        IOM_SendForOrderUtils.testIntegrationMappingRecords = IOM_SendForOrder_Test.testMetadataJSON;
        IOM_OppFlowTriggerHandler.callApex(new List<Id>{opplst[0].Id}); 
        Test.stopTest();
        Opportunity item = Database.query('Select Id,IOM_Validation_Status__c from Opportunity limit 1');
        system.assertEquals('Error', item.IOM_Validation_Status__c, 'Payload Validation Success');
    }
    @isTest static void dataTypeError() {
        
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
        IOM_SendForOrderUtils.testIntegrationMappingRecords = IOM_SendForOrder_Test.testMetadataJSON;
        IOM_OppFlowTriggerHandler.callApex(new List<Id>{opplst[0].Id}); 
        Test.stopTest();
        Opportunity item = Database.query('Select Id,IOM_Validation_Status__c from Opportunity limit 1');
        system.assertEquals('Success', item.IOM_Validation_Status__c, 'Payload Validation Success');
    }
    @isTest static void testMulesoftcallout(){
        
        Account acc1 = [Select Id from Account limit 1];

        opportunity opp = new opportunity(Name='World of Concrete 2017 Test Record data',AccountId = acc1.id,Amount=20.00,CloseDate=System.Today(),StageName='Closed Won',Probability = 100.00);
        insert opp;
        
        Set<Id> ids = new Set<Id>();
        
        IOM_Synchronization_Transaction__c o = new IOM_Synchronization_Transaction__c();
        o.IOM_CRM_Opportunity__c = opp.Id;        
        o.IOM_Processing_Status__c = 'Processing';
        o.IOM_Type__c = 'Opportunity Sync';
        o.IOM_Request_Body__c = '{"OpportunityContactRole":[{"ContactMailingStreet":"24 B Block Road","AccountShippingCity":"Dubai","AccountBillingCountry":"India","AccountShippingCountry":"United Arab Emirates","ContactId":"0030500000Hr3kUAAR","Role":"Business User","ContactSalutation":"Mr.","ContactMailingPostalCode":"201301","AccountShippingPostalCode":"","AccountName":"Jupiter Marine International","ContactMailingCity":"Noida","IOMContactNumber":"IM-006","SourceContactNumber":"IMC-00002","AccountBillingState":"Uttar Pradesh","AccountBillingPostalCode":"201301","ContactMailingState":"Uttar Pradesh","IOMAccountNumber":"","ContactMailingCountry":"India","IsPrimary":"true","ContactMobilePhone":"5456897845","AccountId":"0010500000K6YFDAA3","AccountShippingStreet":"20th Floor, Dubai World Trade Center Tower - Sheikh Zayed Rd","ContactEmail":"ashish.anand@girikon.com","ContactTitle":"Developer","ContactFirstName":"Ashish","AccountShippingState":"","ContactLastName":"Anand","SourceAccountNumber":"","AccountBillingStreet":"24 B Block Road","AccountBillingCity":"Noida"}],"OpportunityLineItem":[{"OpportunityProductName":"IOM Test Opportunity 001 Raw Space","ListPrice":"175.00","TotalPrice":"7875.00","Quantity":"45.00","ProductCode":"IM01-00002","LineDescription":"","ProductName":"Raw Space","Product2Id":"01t050000017qQnAAI"},{"OpportunityProductName":"IOM Test Opportunity 001 Meeting Room","ListPrice":"175.00","TotalPrice":"175.00","Quantity":"1.00","ProductCode":"IM01-00009","LineDescription":"","ProductName":"Meeting Room","Product2Id":"01t050000017qV5AAI"}],"AccountShippingState":"","OpportunityProbability":"100","CustomPaymentScheduleInfo":"","OpportunityCloseDate":"2021-11-01 00:00:00","AccountBillingStreet":"24 B Block Road","OpportunityCurrency":"USD","AccountRecordType":"AccountUnHold","AccountShippingPostalCode":"","OpportunityEditionCode":"PSIM2","OpportunityAmount":"8050.00","OpportunityStageName":"Closed Won","AccountShippingCountry":"United Arab Emirates","SourceAccountNumber":"","OpportunityName":"IOM Test Opportunity 001","AccountId":"0010500000K6YFDAA3","PaymentSchedule":"Custom","AccountBillingCity":"Noida","AccountShippingCity":"Dubai","AccountBillingPostalCode":"201301","AccountName":"Jupiter Marine International","SourceName":"IOM","AccountBillingState":"Uttar Pradesh","AccountBillingCountry":"India","IOMAccountNumber":"","OpportunityId":"00605000005jnInAAI","AccountShippingStreet":"20th Floor, Dubai World Trade Center Tower - Sheikh Zayed Rd"}';
        insert o;
        
        o.IOM_Processing_Status__c = 'Requeue';
        update o;
        
        ids.add(o.Id);
        
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{"meta": {"status": "success","message": "The JSON is validated successfully and being processed further."}}';
        mapURIBody.put('mulesoft','200###'+resJSON);
        
        Test.setMock(HttpCalloutMock.class, new IOM_MulesoftSalesforce_Mock(mapURIBody));
        Test.startTest();
        Database.executeBatch(new IOM_MulesoftSalesforceCalloutBatch(ids),1);
        Test.stopTest();
        IOM_Synchronization_Transaction__c item2 = Database.query('Select id,IOM_Processing_Status__c from IOM_Synchronization_Transaction__c limit 1');
        System.assertEquals('Error', item2.IOM_Processing_Status__c, 'Operation Success');
    }

    @isTest static void testIntClass()
    {
        IOM_Interfaces.SendForOrderoverride overrideOBJ = new IOM_SendForOrder_Test.SetIOMPayloadTestData();

        Map<string,string> payloadLabel = overrideOBJ.overrideGroupNodeLabel(new Map<string,string>());

        System.assertEquals(payloadLabel.get('OpportunityContactRole-OpportunityId-Id'),'OCR','payloadOverride Failed!');
    }

    // Interface Test
    public class SetIOMPayloadTestData implements IOM_Interfaces.SendForOrderoverride {

        public Map<string,object> overridePayloadJSON(String oppId,Map<string,object> payloadMap) 
        {
            payloadMap.put('ShippingAccountNo','T-23659850154');
            return payloadMap;
        }
    
        public Map<string,string> overrideGroupNodeLabel(Map<string,string> payloadObjectNodeGroupMap) 
        {            
            payloadObjectNodeGroupMap.put('OpportunityContactRole-OpportunityId-Id','OCR');
            return payloadObjectNodeGroupMap;
        }
    }
}