/**
* File         :   ViewIOMRecordController_Test 
* Project      :   GECI
* Created Date :   20th Feb 2023
* Created By   :   IBM 
* Test Class   :   ViewIOMRecordController_Test (99%)
* ***************************************************************************************************
* @description : Test class for ViewIOMRecordController controller  (GECI-737)
* ***************************************************************************************************
* Modification log :  
*/
@IsTest
public class ViewIOMRecordController_Test {

    /** 
     * @description : method to create test data
	 */
    @TestSetup
    public static void createTestData(){
        blng__LegalEntity__c billingLegalEntity = TestDataFactory.setupLegalEntity();
        
        //Insert Series
        Series__c seriesObj = new Series__c();
        seriesObj.Name = 'testSeries';
        seriesObj.Status__c = 'Active';
        seriesObj.Legal_Entity__c = billingLegalEntity.Id;
        insert seriesObj;
        
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
        
        Account oacc = new Account (Name = 'testAccount',Legacy_CRM_Instance__c = 'Penton',BillingCountry='India',BillingPostalCode='121212', BillingCity='Noida',BillingState='Uttar Pradesh',BillingStreet='ABC');
        insert oacc ;
        
        Contact oCon = new Contact(LastName = 'ContTest1',Legacy_CRM_Instance__c = 'Penton', Email = 'test1contact@duptest.com', AccountId = oacc.Id, MailingStreet = 'Test', MailingCity = 'Test', MailingState = '', MailingCountry = 'India');
        insert oCon;
        
        Opportunity oOpportunity = new Opportunity(Default_Edition__c=edition.Id,Name = 'Expocad Opportunity', CloseDate = Date.today(), StageName = 'Proposal', AccountId = oacc.Id, Billing_Contact__c = oCon.Id, Bill_To_Account__c = oacc.Id,Opportunity_Number_Text__c='IMO-00781');
        insert oOpportunity;
    }
    
     /** 
     * @description : method to test ViewIOMRecordController.redirectToRecordPage method postive scenario
	 */
    @IsTest
    public static void test_RedirectToRecordPage_PositiveScenario(){
     	ApexPages.currentPage().getParameters().put('iomoppno','IMO-00781');
        ViewIOMRecordController viewRecController = new ViewIOMRecordController();
        PageReference pg = viewRecController.redirectToRecordPage();
        
        system.assert(pg!=null, 'Redirect Url not formed correctly');
       
    }
    
    /** 
     * @description : method to test ViewIOMRecordController.redirectToRecordPage method negative scenario
	 */
    @IsTest
    public static void test_RedirectToRecordPage_NegativeScenario(){
     	ApexPages.currentPage().getParameters().put('iomoppno','IMO-00711');
        ViewIOMRecordController viewRecController = new ViewIOMRecordController();
        PageReference pg = viewRecController.redirectToRecordPage();
        
        System.assertEquals(null, pg,'Page Reference should return null');
    }
}