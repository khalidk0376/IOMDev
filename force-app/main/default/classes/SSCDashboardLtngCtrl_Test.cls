/**
* Created By       :   Girikon(Sachin[IML2R-742])
* Created On       :   Feb 25, 2020
* @description     :   Test class for SSCDashboardLtngCtrl class 80%
* Modified by      :   
**/

@IsTest
public class SSCDashboardLtngCtrl_Test {
     @IsTest
    private static void getTest()
    {
       
        //@Description: Insert Account.
        Account acc = TestDataFactoryUtils.createAccount();
        insert acc;
        System.assertEquals('Test Account', acc.name,'true');
        
       //@Description: Insert Contact.
        Contact ocontact = TestDataFactoryUtils.createContact(acc.Id);
        insert ocontact;
        
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
        Edition__c eventEdition = TestDataFactoryUtils.createEdition(oSeries.Id, oCongaCNTemp.Id, onCongaInv.Id);
        insert eventEdition;
        
        //@Description: Insert Opportunity.
        Opportunity opp = new Opportunity();
        opp.Name = 'Testing Opportunity';
        opp.Default_Edition__c = eventEdition.Id;
        opp.Opportunity_Contact__c = ocontact.Id;
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.Today().addDays(1);
        opp.stagename = 'Closed Won';
        insert opp;
        System.assertEquals('Testing Opportunity', opp.name,'true');
        
        SSCDashboardLtngCtrl.getSSCTeamMember();
        //SSCDashboardLtngCtrl.getOperationTeamMember();
        SSCDashboardLtngCtrl.isSSCBrazilUser();
        SSCDashboardLtngCtrl.getProductBrasilCondition(opp.Id);
        SSCDashboardLtngCtrl.isVisible('abcd',opp.Id);
        SSCDashboardLtngCtrl.isShowProductHeader(opp.Id);
        SSCDashboardLtngCtrl.getAgreements(opp.id,'%Test%');
        SSCDashboardLtngCtrl.approveContract(opp);
        SSCDashboardLtngCtrl.getRejectionOptions();
        SSCDashboardLtngCtrl.approveRejectAmmendedOpportunit(opp.Id,'sAction','Test','No signature on contract');
        SSCDashboardLtngCtrl.getPickListValuesIntoList();
    }
}