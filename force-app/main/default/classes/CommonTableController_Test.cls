/**
* Created By       :   Girikon(Sachin[IML2R-742])
* Created On       :   Feb 25, 2020
* @description     :   Test class for CommonTableController class 80%
* Modified by      :   
**/
@IsTest
public class CommonTableController_Test {
  // @description : Setting up all test data and covering all methods of apex class
  @IsTest
    private static void getTest() {
        Test.startTest();
        Account acc = TestDataFactoryUtils.createAccount();
        insert acc;
        System.assertEquals('Test Account',acc.Name,'True');
        
        DateTime dT = System.now().addDays(3);
        Date myDate = date.newinstance(dT.year(), dT.month(), dT.day());
        Opportunity opp = new Opportunity();
        opp.Name = 'Tets';
        opp.Amount=34.4;
        opp.CloseDate = myDate;
        opp.StageName = 'Discover';
        opp.AccountId = acc.Id;
        insert opp;
        
        APXTConga4__Conga_Template__c oCongaContractTemp = TestDataFactoryUtils.createCongaContractTemplate();
        insert oCongaContractTemp;
        
        APXTConga4__Conga_Template__c onCongaInv = TestDataFactoryUtils.createCongaInvoiceTemplate();
        insert onCongaInv;
        
        APXTConga4__Conga_Template__c oCongaQuoteTemp = TestDataFactoryUtils.createCongaQuoteTemplate();
        insert oCongaQuoteTemp;
        
        APXTConga4__Conga_Template__c oCongaCNTemp = TestDataFactoryUtils.createCongaCreditNoteTemplate();
        insert oCongaCNTemp;
        
        blng__LegalEntity__c oLegalEntity = TestDataFactoryUtils.createLegalEntity(oCongaContractTemp.Id,onCongaInv.Id,oCongaQuoteTemp.Id,oCongaCNTemp.Id);
        insert oLegalEntity;
        
        Series__c oSeries = TestDataFactoryUtils.createSeries(oLegalEntity.Id);
        insert oSeries;
        
        //@Description: Insert Event Edition.
        Edition__c edition = TestDataFactoryUtils.createEdition(oSeries.Id, oCongaCNTemp.Id, onCongaInv.Id);
        insert edition;
        
        CommonTableController.getGenericObjectRecord('false', 'Opportunity','IsClosed,Id,Name,IsClosed,Status__c,IsWon,HasOpportunityLineItem,Account.blng__BillToContact__c',10.0,false,false,-1,'Name','asc', '',true);
        CommonTableController.getGenericObjectRecord('test', 'Opportunity','Id,Name,IsClosed,Status__c,IsWon,HasOpportunityLineItem',10.0,false,true,0,'Name','asc', 'Name!=\'\'',false);
        //CommonTableController.getAgreegatedObjectRecord('Agent Pavilion Shell',edition.Id,10.0,false,false,-1);
        //CommonTableController.getAgreegatedObjectRecord('Agent Pavilion Shell',edition.Id,10.0,false,true,-1);
        //CommonTableController.getAgreegatedObjectRecord('Agent Pavilion Shell',edition.Id,10.0,true,false,-1);
        List<Opportunity> results = CommonTableController.getRecordDetail('Opportunity','Id,Name',opp.Id);
        CommonTableController.getRecordDetail2('Opportunity','Id,Name',opp.Id);
        CommonTableController.getRecordDetail3('Opportunity','Id,Name','Name!=\'\'');
        CommonTableController.getFileDetail('Attachment','Id',opp.Id);
        Contact conObj = new Contact();
        conObj.LastName='test';
        conObj.Email='test@gmail.com';
        insert conObj;
        CommonTableController.getAggregateData('Name!=\'\'', 'Opportunity', 'Name');
        CommonTableController.getAggregateData2('Name!=\'\'', 'Opportunity', 'Name');
        CommonTableController.getTotalAmount('Name!=\'\'', 'Opportunity', 'Name');
        opp.StageName='Customize';
        CommonTableController.massUpdateRecords(new Opportunity[]{opp});
        CommonTableController.deleteRecord(new sobject[]{conObj});        
        CommonTableController.massInsertRecords(new sobject[]{conObj});
        Integer recordCount = CommonTableController.getRecordCount('Opportunity','Id,Name','Id != null');
        System.assertNotEquals(0,recordCount,'Records did not match');
        /*Profile_Option_Visibility__c povObj = new Profile_Option_Visibility__c(Social_Media_Links__c=true,Booth_Contact_Info__c=true,Print_Description__c=true,Web_Description__c=true,Logo__c=true,Event_Edition__c = edition.Id);
        Insert povObj;
        
        Profile_Package_Setting__c ppsObj = new Profile_Package_Setting__c(Is_Default__c=true,Social_Media_Links__c=true,Booth_Contact_Info__c=true,Print_Description__c=true,Web_Description__c=true,Logo__c=true,Event_Edition__c = edition.Id);
        Insert ppsObj;*/
        
        //CommonTableController.getFieldVisibility(acc.Id,edition.Id);
        Test.stopTest();
    }
}