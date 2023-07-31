/**
* File:          TestDataFactory
* Project:       PoC SFDC Informa 
* Created Date:  25/10/2019
* Created By:    Ayoub Ouarti (aouarti@salesforce.com)
* *******************************************************************************************************
* @description : This class is used as a Test Data Factory for all test classes.
* *******************************************************************************************************
*/
public with sharing  class TestDataFactory {

    /**
    * @description Method is used for creating Quote
    * @param city
    * @param opportunityId
    * @param accountId
    * @param priceBookId
    * @param type
    * @param edition
    * @return SBQQ__Quote__c
    */
    public static SBQQ__Quote__c buildTestSFCPQQuote(String city ,String opportunityId, String accountId, String priceBookId, String type, Edition__c edition) 
    {
        SBQQ__Quote__c cpqQuote = new SBQQ__Quote__c();
        cpqQuote.SBQQ__Primary__c = false;
        cpqQuote.SBQQ__StartDate__c = System.Today();
        cpqQuote.SBQQ__Opportunity2__c = opportunityId;
        cpqQuote.SBQQ__SubscriptionTerm__c = null;
        cpqQuote.SBQQ__BillingFrequency__c = 'Invoice Plan';
        cpqQuote.SBQQ__Account__c = accountId;
        cpqQuote.SBQQ__Type__c = type;
        cpqQuote.SBQQ__PriceBook__c = priceBookId;
        cpqQuote.SBQQ__PricebookId__c = priceBookId;
        cpqQuote.CurrencyIsoCode = UserInfo.getDefaultCurrency();
        cpqQuote.SBQQ__QuoteLanguage__c = 'English';
        cpqQuote.Edition__c = edition.Id;
        cpqQuote.SBQQ__BillingCity__c = city;
        return cpqQuote;
    }
    
    /**
    * @description Method is used for creating Quote Line
    * @param productId
    * @param quoteId
    * @param pricebookEntryId
    * @param price
    * @param edition
    * @param qte
    * @return SBQQ__QuoteLine__c
    */
    public static SBQQ__QuoteLine__c buildTestSFCPQQuoteLine(String productId, String quoteId, String pricebookEntryId, Decimal price, Edition__c edition,Integer qte) 
    {
        SBQQ__QuoteLine__c quoteLineInstance = new SBQQ__QuoteLine__c();
        quoteLineInstance.SBQQ__StartDate__c = System.Today();
        quoteLineInstance.SBQQ__Product__c = productId;
        quoteLineInstance.SBQQ__Quantity__c = qte;
        quoteLineInstance.SBQQ__DefaultSubscriptionTerm__c = null;
        quoteLineInstance.SBQQ__ListPrice__c = price;
        quoteLineInstance.SBQQ__CustomerPrice__c = price;
        quoteLineInstance.SBQQ__NetPrice__c = price;
        quoteLineInstance.SBQQ__SpecialPrice__c = price;
        quoteLineInstance.SBQQ__Quote__c = quoteId;
        quoteLineInstance.SBQQ__PricebookEntryId__c = pricebookEntryId;
        quoteLineInstance.SBQQ__PricingMethod__c = 'List';
        quoteLineInstance.SBQQ__SubscriptionPricing__c = null;
        quoteLineInstance.SBQQ__ChargeType__c ='Recurring';
        quoteLineInstance.SBQQ__BillingType__c = 'Advance';
        quoteLineInstance.SBQQ__BillingFrequency__c ='Invoice Plan';
        quoteLineInstance.Edition__c = edition.Id;
        quoteLineInstance.CurrencyIsoCode = UserInfo.getDefaultCurrency();
        return quoteLineInstance;
    }


    /**
    * @description Method is used for creating Quote Line
    * @param productId
    * @param quoteId
    * @param pricebookEntryId
    * @param price
    * @param edition
    * @param qte
    * @return SBQQ__QuoteLine__c
    */ 
    public static SBQQ__QuoteLine__c buildTestSFCPQQuoteLineAmend(String productId, String quoteId, String pricebookEntryId, Decimal price, Edition__c edition,Integer qte) 
    {
        SBQQ__QuoteLine__c quoteLineInstance = new SBQQ__QuoteLine__c();
        quoteLineInstance.SBQQ__StartDate__c = System.Today();
        quoteLineInstance.SBQQ__Product__c = productId;
        quoteLineInstance.SBQQ__Quantity__c = qte;
        quoteLineInstance.SBQQ__ListPrice__c = price;
        quoteLineInstance.SBQQ__Quote__c = quoteId;
        quoteLineInstance.SBQQ__PricebookEntryId__c = pricebookEntryId;
        quoteLineInstance.SBQQ__PricingMethod__c = 'List';
        quoteLineInstance.SBQQ__ChargeType__c ='Recurring';
        quoteLineInstance.SBQQ__BillingType__c = 'Advance';
        quoteLineInstance.SBQQ__BillingFrequency__c ='Invoice Plan';
        quoteLineInstance.Edition__c = edition.Id;
        quoteLineInstance.CurrencyIsoCode = UserInfo.getDefaultCurrency();
        return quoteLineInstance;
    }  
    
    /**
    * @description Method is used for creating Billing Custom Settings
    */ 
    public static void insertBillingCustomSettings() {
        
        List<blng__BillingConfig__c> listofConfiguration = new List<blng__BillingConfig__c>();
        blng__BillingConfig__c advancedARApplication = new blng__BillingConfig__c(Name = 'ADVANCED_AR_APPLICATION', blng__StringValue__c = '', blng__FieldType__c = 'Boolean', blng__Description__c = 'Advanced AR application', blng__PicklistIndicator__c ='', blng__Category__c ='Invoice', blng__Sequence__c = 2, blng__BooleanValue__c = true);
        listofConfiguration.add(advancedARApplication);
        blng__BillingConfig__c taxCalculationBasedOn = new blng__BillingConfig__c(Name = 'TAX_CALCULATION_BASED_ON', blng__StringValue__c = 'Order: Account Billing Address', blng__FieldType__c = 'Picklist', blng__Description__c = 'Tax calculation is based on?', blng__PicklistIndicator__c ='TaxcCalculationList', blng__Category__c ='General', blng__Sequence__c = 3);
        listofConfiguration.add(taxCalculationBasedOn);

        blng__BillingConfig__c alignBilling = new blng__BillingConfig__c(Name = 'ALIGN_BILLDAYOFMONTH_TO_ORDERSTARTDATE', blng__StringValue__c = '', blng__FieldType__c = 'Boolean', blng__Description__c = 'Align Billing day of month to Order start date', blng__PicklistIndicator__c ='', blng__Category__c ='General', blng__Sequence__c = 3, blng__BooleanValue__c = true);
        listofConfiguration.add(alignBilling);

        blng__BillingConfig__c calculationProrationType = new blng__BillingConfig__c(Name = 'PRORATION_TYPE',blng__StringValue__c = 'Calendar Days',blng__FieldType__c = 'Picklist',blng__Description__c = 'Proration type.',blng__PicklistIndicator__c ='CalendarDaysList',blng__Category__c ='Invoice',blng__Sequence__c = 3);
        listofConfiguration.add(calculationProrationType);
        
        blng__BillingConfig__c partialProrationType = new blng__BillingConfig__c(Name = 'PARTIAL_PERIOD_BILLING_PRORATION',blng__StringValue__c = 'Month + Daily',blng__FieldType__c = 'Picklist',blng__Description__c = 'Partial Proration Type',blng__PicklistIndicator__c ='PartialProrationTypeList',blng__Category__c ='Invoice',blng__Sequence__c = 3);
        listofConfiguration.add(partialProrationType);

        blng__BillingConfig__c invoiceTobeChargedOn = new blng__BillingConfig__c(Name = 'INVOICE_TO_BE_CHARGED_ON',blng__StringValue__c = 'Due Date',blng__FieldType__c = 'Picklist',blng__Description__c = 'Payment Scheduler to pickup unpaid invoices on OR after',blng__PicklistIndicator__c ='PaymentSchedulerList',blng__Category__c ='Invoice',blng__Sequence__c = 2,blng__BooleanValue__c = false);
        listofConfiguration.add(invoiceTobeChargedOn);  

        blng__BillingConfig__c periodPriceRounding = new blng__BillingConfig__c(Name = 'PERIOD_PRICE_ROUNDING',blng__StringValue__c = 'HALF_UP',blng__FieldType__c = 'Picklist',blng__Description__c = 'Billable Unit Price Rounding',blng__PicklistIndicator__c ='PeriodPriceRoundingList',blng__Category__c ='General',blng__Sequence__c = 8,blng__BooleanValue__c = false);
        listofConfiguration.add(periodPriceRounding);  
        
        blng__BillingConfig__c usageRatingProcess = new blng__BillingConfig__c(Name = 'USAGE_RATING_PROCESS',blng__StringValue__c = 'On Trigger',blng__FieldType__c = 'Picklist',blng__Description__c = 'Usage Rating Process based on',blng__PicklistIndicator__c ='UsageRatingProcessList',blng__Category__c ='General',blng__Sequence__c = 9,blng__BooleanValue__c = false);
        listofConfiguration.add(usageRatingProcess);    
        
        blng__BillingConfig__c billingRemainderProcessing = new blng__BillingConfig__c(Name = 'BILLING_REMAINDER_PROCESS',blng__StringValue__c = 'Last Period',blng__FieldType__c = 'Picklist',blng__Description__c = 'Billing Remainder Process',blng__PicklistIndicator__c ='billingRemainderProcessList',blng__Category__c ='Invoice',blng__Sequence__c = 5,blng__BooleanValue__c = false);
        listofConfiguration.add(billingRemainderProcessing);
        
        blng__BillingConfig__c revenueRemainderProcessing = new blng__BillingConfig__c(Name = 'REVENUE_REMAINDER_PROCESS',blng__StringValue__c = 'Last Period',blng__FieldType__c = 'Picklist',blng__Description__c = 'Revenue Remainder Process',blng__PicklistIndicator__c ='RevenueRemainderProcessList',blng__Category__c ='Invoice',blng__Sequence__c = 6,blng__BooleanValue__c = false);
        listofConfiguration.add(revenueRemainderProcessing);
        
        blng__BillingConfig__c saveCreditCardBetails = new blng__BillingConfig__c(Name = 'SAVE_CREDIT_CARD_ON_PAYMENT_PAGE',blng__StringValue__c = '',blng__FieldType__c = 'Boolean',blng__Description__c = 'Save credit card details',blng__PicklistIndicator__c ='',blng__Category__c ='General',blng__Sequence__c = 6,blng__BooleanValue__c = false);
        listofConfiguration.add(saveCreditCardBetails);
        
        blng__BillingConfig__c enableStateAndCountryPicklist = new blng__BillingConfig__c(Name = 'ENABLE_STATE_AND_COUNTRY_PICKLIST',blng__StringValue__c = '',blng__FieldType__c = 'Boolean',blng__Description__c = 'Enable state and country picklist in Site Page and Virtual Terminal(works when state and country feature is enabled in Salesforce)',blng__PicklistIndicator__c ='',blng__Category__c ='General',blng__Sequence__c = 6,blng__BooleanValue__c = false);
        listofConfiguration.add(enableStateAndCountryPicklist);
        
        
        blng__BillingConfig__c sampledata = new blng__BillingConfig__c(Name = 'INSERT_SAMPLE_DATA',blng__StringValue__c = '',blng__FieldType__c = 'Boolean',blng__Description__c = 'Insert Sample Data',blng__PicklistIndicator__c ='',blng__BooleanValue__c = false);
        listofConfiguration.add(sampledata);
        
        //Added by DL,W-4000272, In-order to make Tax Engine name dynamic
        blng__BillingConfig__c taxEngineName = new blng__BillingConfig__c(Name = 'AVALARA_AVATAX',blng__StringValue__c = 'Avalara AvaTax',blng__FieldType__c = '',blng__Description__c = '',blng__PicklistIndicator__c ='',blng__Category__c ='Tax',blng__BooleanValue__c = false);
        listofConfiguration.add(taxEngineName);
        
        if(Schema.sObjectType.blng__BillingConfig__c.isCreateable())
        {
           insert listofConfiguration;  
        }
    }
    
    /**
    * @description Method is used for creating Legal Entity
    * @return blng__LegalEntity__c
    */ 
    public static blng__LegalEntity__c setupLegalEntity() {
        blng__LegalEntity__c legalEntity = new blng__LegalEntity__c(blng__Active__c=true, blng__Country__c='USA');
        if(Schema.sObjectType.blng__LegalEntity__c.isCreateable())
        {
          insert legalEntity; 
        }
        return legalEntity;
    }
    
    /**
    * @description Method is used for creating Revenue Recognition Rule
    * @param legalEntityId
    * @return blng__RevenueRecognitionRule__c
    */ 
    public static blng__RevenueRecognitionRule__c setupRevRec(string legalEntityId) {
        blng__RevenueRecognitionRule__c revRecRule = new blng__RevenueRecognitionRule__c (blng__Active__c=true,blng__CreateRevenueSchedule__c='Yes',Name='Monthly');
        if(Schema.sObjectType.blng__RevenueRecognitionRule__c.isCreateable())
        {
          insert revRecRule;
        }
        
        blng__FinanceBook__c revFinanceBook = new blng__FinanceBook__c(blng__Active__c = true, Name = 'Rev Finance Book', blng__PeriodType__c = 'Revenue');
        if(Schema.sObjectType.blng__FinanceBook__c.isCreateable())
        {
           insert revFinanceBook;
        }

        
        blng__RevenueDistributionMethod__c revDist = new blng__RevenueDistributionMethod__c(CurrencyIsoCode = UserInfo.getDefaultCurrency(), blng__Active__c = true, Name = 'Monthly Invoice', blng__Type__c = 'Invoice', blng__RevenueTransactionCreationProcess__c = 'Automatic', blng__RevenueScheduleTermStartDate__c = 'Invoice Line Start Date', blng__RevenueScheduleTermEndDate__c = 'Invoice Line End Date', blng__MonthlyRecognitionProration__c = 'Number of Days', blng__DistributionMethod__c = 'Monthly');
        if(Schema.sObjectType.blng__RevenueDistributionMethod__c.isCreateable())
        {
          insert revDist;
        }
        
        blng__GLRule__c glRule = new blng__GLRule__c(blng__Active__c = true, Name = 'GL Rule');
        if(Schema.sObjectType.blng__GLRule__c.isCreateable())
        {
            insert glRule;
        }
              
        blng__RevenueRecognitionTreatment__c revRecTreatment = new blng__RevenueRecognitionTreatment__c(CurrencyIsoCode = UserInfo.getDefaultCurrency(), blng__Active__c = true, blng__RevenueLegalEntity__c = legalEntityId, blng__RevenueRecognitionRule__c = revRecRule.Id, blng__ProcessingOrder__c = 10, blng__Percentage__c = 100, blng__Type__c = 'Percentage', blng__RevenueScheduleCreationAction__c = 'Invoice Posting', blng__RevenueScheduleAmount__c = 'Transaction Amount', blng__RevenueFinanceBook__c = revFinanceBook.Id, blng__RevenueDistributionMethod__c = revDist.id, blng__RevenueGLRule__c = glRule.Id);
        if(Schema.sObjectType.blng__RevenueRecognitionTreatment__c.isCreateable())
        {
           insert revRecTreatment;
        }
        return revRecRule;
    }
    
    /**
    * @description Method is used for creating Billing Rule
    * @param legalEntityId
    * @return blng__BillingRule__c
    */ 
    public static blng__BillingRule__c setupBillingRule(string legalEntityId) {            
        blng__BillingRule__c billingRule = new blng__BillingRule__c(blng__InitialBillingTrigger__c = 'Order Product Activation Date', Name = 'TEST',blng__Active__c = true, blng__GenerateInvoices__c='Yes');
        if(Schema.sObjectType.blng__BillingRule__c.isCreateable())
        {
            insert billingRule;
        }
        
        blng__FinanceBook__c accoutingFinanceBook = new blng__FinanceBook__c(blng__Active__c = true, Name = 'Accounting Finance Book', blng__PeriodType__c = 'Accounting');
        if(Schema.sObjectType.blng__FinanceBook__c.isCreateable())
        {
           insert accoutingFinanceBook;
        }
        
        blng__BillingTreatment__c billingTreatment = new blng__BillingTreatment__c(CurrencyIsoCode = UserInfo.getDefaultCurrency(), blng__BillingFinanceBook__c = accoutingFinanceBook.Id, blng__Active__c = true, blng__BillingLegalEntity__c = legalEntityId, blng__BillingRule__c = billingRule.Id /*,blng__CancellationRule__c = 'LIFO based on Termination Date'*/);
        if(Schema.sObjectType.blng__BillingTreatment__c.isCreateable())
        {
           insert billingTreatment;
        }
        
        return billingRule;
    }
    
    /**
    * @description Method is used for creating Tax Rule
    * @param legalEntityId
    * @return blng__TaxRule__c
    */ 
    public static blng__TaxRule__c setupTaxRule(string legalEntityId) {            
        blng__TaxRule__c taxRule = new blng__TaxRule__c(blng__Active__c = true, blng__TaxableYesNo__c = 'Yes', Name = 'Tax Rule');
        if(Schema.sObjectType.blng__TaxRule__c.isCreateable())
        {
          insert taxRule;
        }
        
        blng__TaxIntegration__c stdTaxInt = new blng__TaxIntegration__c(blng__Active__c = true, blng__Default__c = true, blng__TaxEngine__c = 'Standard');
        if(Schema.sObjectType.blng__TaxIntegration__c.isCreateable())
        {
           insert stdTaxInt;
        }
        
        blng__TaxTreatment__c taxTreatment = new blng__TaxTreatment__c(CurrencyIsoCode = UserInfo.getDefaultCurrency(), blng__Active__c = true, blng__TaxLegalEntity__c = legalEntityId, blng__TaxRule__c = taxRule.Id, blng__TaxIntegration__c = stdTaxInt.Id);
        if(Schema.sObjectType.blng__TaxTreatment__c.isCreateable())
        {
           insert taxTreatment;
        } 
        return taxRule;
    }
    
    /**
    * @description Method is used for creating Tax Rules
    * @param legalEntityId
    * @return blng__TaxRule__c
    */ 
    public static blng__TaxRule__c setupTaxRuleasNO(string legalEntityId) {            
        blng__TaxRule__c taxRule = new blng__TaxRule__c(blng__Active__c = true, blng__TaxableYesNo__c = 'No', Name = 'Tax Rule NO');
        if(Schema.sObjectType.blng__TaxRule__c.isCreateable())
        {
          insert taxRule;
        } 
        return taxRule;
    }
    
    /**
    * @description Method is used for creating Product
    * @return Product2
    */ 
    public Product2 createProduct(){
        Product2 prod = new Product2();
        prod.isActive = true;
        prod.Name = 'Product';
        return prod;
    }
    
    /**
    * @description Method is used for creating PricebookEntry
    * @param pricebookId
    * @param productId
    * @return PricebookEntry
    */ 
    public static PricebookEntry createPricebookEntry(Id pricebookId, Id productId){
        PricebookEntry pbe = new PricebookEntry();
        pbe.isActive = true;
        pbe.UnitPrice = 100;
        pbe.Product2Id = productId;
        pbe.Pricebook2Id = pricebookId;
        pbe.CurrencyIsoCode = UserInfo.getDefaultCurrency();
        if(Schema.sObjectType.PricebookEntry.isCreateable())
        {
           insert pbe;
        }
        return pbe;
    }
    
    /**
    * @description Method is used for creating Product
    * @param billingRule
    * @param taxRule
    * @param revRecRule
    * @return Product2
    */ 
    public static Product2 createProduct2(blng__BillingRule__c billingRule,blng__TaxRule__c taxRule, blng__RevenueRecognitionRule__c revRecRule) {
        //Create Product
        Product2 p = new Product2();
        p.isActive = true;
        p.Name = 'Product';
        p.SBQQ__BlockPricingField__c = 'Quantity';
        p.SBQQ__AssetAmendmentBehavior__c = 'Default';
        p.SBQQ__AssetConversion__c = 'One per quote line';
        p.SBQQ__DefaultQuantity__c = 10;
        p.SBQQ__PricingMethod__c = 'List';
        p.SBQQ__ChargeType__c = 'Recurring';
        p.SBQQ__BillingFrequency__c = 'Annual';
        p.SBQQ__BillingType__c = 'Advance';
        p.SBQQ__SubscriptionTerm__c = 12;
        p.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p.SBQQ__SubscriptionType__c ='Renewable';
        p.blng__BillingRule__c = billingRule.id;
        p.SBQQ__BillingFrequency__c ='Invoice Plan';
        p.blng__TaxRule__c = taxRule.id;
        p.blng__RevenueRecognitionRule__c = revRecRule.id;
        if(Schema.sObjectType.Product2.isCreateable())
        {
          insert p;
        }
        return p;
    }

    /**
    * @description Method is used for creating Product
    * @param name
    * @param billingRule
    * @param taxRule
    * @param revRecRule
    * @return Product2
    */ 
    public static Product2 createProduct2(String name,blng__BillingRule__c billingRule,blng__TaxRule__c taxRule, blng__RevenueRecognitionRule__c revRecRule) {
        //Create Product
        Product2 p = new Product2();
        p.isActive = true;
        p.Name = name;
        p.SBQQ__BlockPricingField__c = 'Quantity';
        p.SBQQ__AssetAmendmentBehavior__c = 'Default';
        p.SBQQ__AssetConversion__c = 'One per quote line';
        p.SBQQ__DefaultQuantity__c = 10;
        p.SBQQ__PricingMethod__c = 'List';
        p.SBQQ__ChargeType__c = 'Recurring';
        p.SBQQ__BillingFrequency__c = 'Annual';
        p.SBQQ__BillingType__c = 'Advance';
        p.SBQQ__SubscriptionTerm__c = 12;
        p.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p.SBQQ__SubscriptionType__c ='Renewable';
        p.blng__BillingRule__c = billingRule.id;
        p.SBQQ__BillingFrequency__c ='Invoice Plan';
        p.blng__TaxRule__c = taxRule.id;
        p.blng__RevenueRecognitionRule__c = revRecRule.id;
        if(Schema.sObjectType.Product2.isCreateable())
        {
          insert p;
        }
        return p;
    }
}