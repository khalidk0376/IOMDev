/**
* File:             cls_amendContract.cls
* Date:             Dec 31, 2019
* Test Class:       cls_amendContract_Test
* Code Coverage:    89%
* Created By:       Sachin Chaudhary
* *************************************************************************
* @description   Controller to amend Closed Opportunity.
* *************************************************************************
*/
public with sharing class cls_amendContract {

    // Variables
    public string OppId {get; set;}
    public String sShowMsg {get; set;}
    public string sProductType {get; set;}
    public string sTypeOfChg {get; set;}

    /**
     * Custructor.
     * @param  controller [ApexPages.StandardController]
     */
    public cls_amendContract(ApexPages.StandardController controller) {
        OppId = ApexPages.currentPage().getParameters().get('oppId').escapeHtml4();

        if (String.IsNotBlank(ApexPages.currentPage().getParameters().get('prdType')) && String.IsNotBlank(ApexPages.currentPage().getParameters().get('tyChg'))) {
            sProductType = ApexPages.currentPage().getParameters().get('prdType').escapeHtml4();
            sTypeOfChg = ApexPages.currentPage().getParameters().get('tyChg').escapeHtml4();
        }
    }

    /**
     * Method to call SB API to request an amend for Opportunity.
     * @return [pageReference]
     */
    public pageReference amendContract() {
        if (!String.isBlank(OppId) && Schema.sObjectType.Opportunity.isAccessible()) {
            QuoteModel  qmodels ;
            Opportunity parentOpportunity = [SELECT Id, Name, OwnerId, Main_Contract__c, Opportunity_Contact__c,Bill_To_Account__c, Billing_Contact__c, Series__c, Default_Edition__c, Partner_Account__c, SBQQ__AmendedContract__c, StageName, Is_Amend_Opportunity__c FROM Opportunity WHERE Id = :oppId WITH SECURITY_ENFORCED];
            if (parentOpportunity != NULL && parentOpportunity.StageName == 'Closed Won' && parentOpportunity.SBQQ__AmendedContract__c == NULL && !String.isBlank(parentOpportunity.Main_Contract__c)) {
                String qmodelJson = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', parentOpportunity.Main_Contract__c, null);
                qmodels = (QuoteModel )System.JSON.deserialize(qmodelJson, QuoteModel.class);
                Utility.isReviewProcess = true;
                // Calling Future method to update few things on amend oppty and quote asynchronously.
                    if (String.IsNotBlank(sProductType)) {
                        cls_amendContract.updateAmendOpptyAndQuote(oppId, qmodels.record.Id, sProductType, sTypeOfChg);
                    } else {
                        cls_amendContract.updateAmendOpptyAndQuote(oppId, qmodels.record.Id, '', '');
                    }

                if (qmodels != null && !String.isblank(qmodels.record.Id)) {                    
                    PageReference pageRef = new PageReference('/apex/SBQQ__sb?id=' + qmodels.record.Id + '#quote/le?qId=' + qmodels.record.Id);
                    return pageRef;
                }
            }
            if (parentOpportunity.SBQQ__AmendedContract__c != NULL) {
                sShowMsg = 'This is not master opportunity, you can not process for amendment.';
                return null;
            }
            if (parentOpportunity.StageName != 'Closed Won') {
                sShowMsg = 'You can not process for amendment, Opportunity is not Colsed Won.';
                return null;
            }
            if (String.isBlank(parentOpportunity.Main_Contract__c)) {
                sShowMsg = 'Contract is not found for this opportunity, hence amendment cannot be processed.';
                return null;
            }
        }
        return null;
    }

    /**
    * Future method to update Amend Opportunity and Quote Billng/Primary Contact
    * @param oppId    [Parent Opportunity Id]
    * @param qModelId [Amend Quote Id]
    */
    @future(callout = true)
    public static void updateAmendOpptyAndQuote(Id oppId, Id qModelId, String sProductType, String sTypeofchange) {
        List<blng__Invoice__c> lstInvoiceUpdate = new List<blng__Invoice__c>();
        Application_Bypass__c appbypass = Application_Bypass__c.getInstance();
        if (oppId != NULL && qModelId != NULL && Schema.sObjectType.SBQQ__Quote__c.isAccessible()) {
            Opportunity parentOpportunity = [SELECT Id, Name, OwnerId ,Ship_To_Account__c,Bill_To_Account__c,Billing_Contact__r.AccountId, Main_Contract__c, Opportunity_Contact__c, Billing_Contact__c, Series__c, Default_Edition__c, Partner_Account__c, SBQQ__AmendedContract__c, IsAmendContractOpp__c , StageName , CurrencyIsoCode, AccountId,Legacy_CRM_Instance__c,Legal_Entity__c FROM Opportunity WHERE Id = :oppId WITH SECURITY_ENFORCED];

            List<SBQQ__Quote__c> lstAmendQuote = [select id, SBQQ__Opportunity2__c from SBQQ__Quote__c where id = :qModelId WITH SECURITY_ENFORCED];
            if (lstAmendQuote != null && !String.isBlank(lstAmendQuote[0].SBQQ__Opportunity2__c)) {
                Opportunity oAmendOpportunityToUpdate = new Opportunity();
                oAmendOpportunityToUpdate.Id = lstAmendQuote[0].SBQQ__Opportunity2__c ;
                if (parentOpportunity.Partner_Account__c != null) {
                    oAmendOpportunityToUpdate.Partner_Account__c = parentOpportunity.Partner_Account__c;
                }
                if (parentOpportunity.Opportunity_Contact__c != null) {
                    oAmendOpportunityToUpdate.Opportunity_Contact__c = parentOpportunity.Opportunity_Contact__c;
                }
                if (parentOpportunity.Billing_Contact__c != null) {
                    oAmendOpportunityToUpdate.Billing_Contact__c = parentOpportunity.Billing_Contact__c;
                }
                if (parentOpportunity.Bill_To_Account__c != null) {
                    oAmendOpportunityToUpdate.Bill_To_Account__c = parentOpportunity.Bill_To_Account__c;
                }
                if (parentOpportunity.Ship_To_Account__c != null) {
                    oAmendOpportunityToUpdate.Ship_To_Account__c = parentOpportunity.Ship_To_Account__c;
                }
                
                oAmendOpportunityToUpdate.Series__c             = parentOpportunity.Series__c;
                oAmendOpportunityToUpdate.Default_Edition__c    = parentOpportunity.Default_Edition__c;
                oAmendOpportunityToUpdate.Legal_Entity__c       = parentOpportunity.Legal_Entity__c;
                oAmendOpportunityToUpdate.Legacy_CRM_Instance__c = parentOpportunity.Legacy_CRM_Instance__c;
                oAmendOpportunityToUpdate.Master_Opportunity__c = oppId;
                oAmendOpportunityToUpdate.Main_Contract__c      = parentOpportunity.Main_Contract__c;
                oAmendOpportunityToUpdate.IsAmendContractOpp__c = true;
                oAmendOpportunityToUpdate.CurrencyIsoCode       = parentOpportunity.CurrencyIsoCode;

                if (appbypass.Bypass_Validation_Rules__c) {
                    oAmendOpportunityToUpdate.OwnerId = parentOpportunity.OwnerId;
                }
                SBQQ__Quote__c oQuoteToUpdate = new SBQQ__Quote__c() ;
                oQuoteToUpdate.Id = qModelId;
                if (parentOpportunity.Billing_Contact__c != null) {
                    oQuoteToUpdate.Billing_Contact__c = parentOpportunity.Billing_Contact__c;
                }

                if (parentOpportunity.Opportunity_Contact__c != null) {
                    oQuoteToUpdate.SBQQ__PrimaryContact__c = parentOpportunity.Opportunity_Contact__c;
                }
                oQuoteToUpdate.CurrencyIsoCode = parentOpportunity.CurrencyIsoCode;

                if (oQuoteToUpdate.Id != NULL && Schema.sObjectType.SBQQ__Quote__c.isUpdateable()) {
                    Utility.isRebookInProcess = true;
                    update oQuoteToUpdate;
                }
                if (oAmendOpportunityToUpdate.Id != NULL && Schema.sObjectType.Opportunity.isUpdateable()) {
                    Utility.isRebookInProcess = true;
                    update oAmendOpportunityToUpdate;
                }
                parentOpportunity.Is_Amend_Opportunity__c = True;
                //parentOpportunity.Bill_To_Account__c= parentOpportunity.Billing_Contact__r.AccountId;
                parentOpportunity.Status__c = 'Amended';
                if (parentOpportunity.Id != null) {
                    Utility.isRebookInProcess = true;
                    update parentOpportunity;
                }
            }
        }
    }

    /**
     * Redirect to Parent Opportunity.
     * @return [pageReference]
     */
    public pageReference redirectOppty() {
        PageReference pageRef = new PageReference('/' + OppId);
        return pageRef;
    }

    /**
     * Inner Wrapper Class QuoteModel
     */
    public class QuoteModel {
        public Record record {get; set;}
    }

    /**
     * Inner Wrapper Class Record
     */
    public class Record {
        public String Id {get; set;}
    }

}