/**
* Created By   :   Girikon(Ashish) : JIRA ref: [IML2R-299]
* Created On   :   27 Nov 2019
* *********************************************************************************
* @description  : CPQ Models And Api methords for save,read And Calculate price 
* Test Class    : AddCPQQuoteLines_Test(97%)
* *********************************************************************************
* Modification log -- 
* 
*/ 
public with sharing class CPQAPIUtils
{
    /**
    * @description read Quote using CPQ Api
    * @param quoteId salesforce Quote record Id
    * @return      CPQ QuoteModel
    */
    public QuoteModel readQuote(String quoteId)
    {
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quoteId);
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }

    /**
    * @description Save Quote using CPQ Api
    * @param quote CPQ QuoteModel 
    * @return      CPQ QuoteModel
    */
    public QuoteModel saveQuoteModel(QuoteModel quote)
    {
        String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quote));
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }

    /**
    * @description Read Product using CPQ Api
    * @param       productId salesforce Quote record Id,
    * @param       pricebookId salesforce pricebook record Id,
    * @param       currencyCode
    * @return      CPQ ProductModel
    */
    public ProductModel readProduct(Id productId, Id pricebookId, String currencyCode)
    {
        ProductReaderContext ctx = new ProductReaderContext(pricebookId, currencyCode);
        String productJSON = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', productId, JSON.serialize(ctx));
        //system.debug('ProductModel=='+ (ProductModel) JSON.deserialize(productJSON, ProductModel.class));
        return (ProductModel) JSON.deserialize(productJSON, ProductModel.class);
    }

    /**
    * @description Add package Products to QLI
    * @param       quote CPQ QuoteModel,
    * @param       products List of CPQ ProductModel,
    * @param       groupKey
    * @return      CPQ QuoteModel
    */
    public QuoteModel addProductsToQuote(QuoteModel quote, ProductModel[] products, Integer groupKey) 
    {
        AddProductsContext ctx = new AddProductsContext(quote, products, groupKey);
        String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, JSON.serialize(ctx));
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }

    /**
    * @description calculate price rule and Save QLI through a Callback Class
    * @param       quote CPQ QuoteModel,
    * @param       callbackClass Name
    */
    public void calculateQuotePrice(QuoteModel quote, String callbackClass)
    {
        QuoteCalculatorContext ctx = new QuoteCalculatorContext(quote, callbackClass);
        SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteCalculator', null, JSON.serialize(ctx));    
    }  

    private class QuoteCalculatorContext 
    {        
        private QuoteModel quote;
        private String callbackClass;        
        private QuoteCalculatorContext(QuoteModel quote, String callbackClass) 
        {
            this.quote = quote;            
            this.callbackClass = callbackClass;
        }      
    }

    private class AddProductsContext
    {
        private QuoteModel quote;
        private ProductModel[] products;
        private Integer groupKey;
        private final Boolean ignoreCalculate = true; //Must be hardcoded to true
    
        private AddProductsContext(QuoteModel quote, ProductModel[] products, Integer groupKey) {
            this.quote = quote;
            this.products = products;
            this.groupKey = groupKey;
        }
    }
        
    private class ProductReaderContext {
        private Id pricebookId;
        private String currencyCode;
        
        private ProductReaderContext(Id pricebookId, String currencyCode) {
            this.pricebookId = pricebookId;
            this.currencyCode = currencyCode;
        }
    }
    
    /** @description QuoteModel */
    public class QuoteModel {
        public SBQQ__Quote__c record;
        public QuoteLineModel[] lineItems;
        public QuoteLineGroupModel[] lineItemGroups;
        public Integer nextKey;
        public Boolean applyAdditionalDiscountLast;
        public Boolean applyPartnerDiscountFirst;
        public Boolean channelDiscountsOffList;
        public Decimal customerTotal;
        public Decimal netTotal;
        public Decimal netNonSegmentTotal;
    }
    
    /** @description ProductModel */
    public class ProductModel {
        public Product2 record;
        public Id upgradedAssetId;
        public String currencySymbol;
        public String currencyCode;
        public String[] featureCategories;
        public OptionModel[] options;
        public FeatureModel[] features;
        public ConfigurationModel configuration;
        public ConfigAttributeModel[] configurationAttributes;
        public ConfigAttributeModel[] inheritedConfigurationAttributes;
        public ConstraintModel[] constraints; 
    }
    
    /** @description OptionModel */
    public class OptionModel { 
        public SBQQ__ProductOption__c record; 
        public Map<String,String> externalConfigurationData; 
        public Boolean configurable; 
        public Boolean configurationRequired; 
        public Boolean quantityEditable; 
        public Boolean priceEditable; 
        public Decimal productQuantityScale; 
        public Boolean priorOptionExists; 
        public Set<Id> dependentIds; 
        public Map<String,Set<Id>> controllingGroups; 
        public Map<String,Set<Id>> exclusionGroups; 
        public String reconfigureDimensionWarning; 
        public Boolean hasDimension; 
        public Boolean isUpgrade; 
        public String dynamicOptionKey;  
    }
    
    /** @description FeatureModel */
    public class FeatureModel { 
        public SBQQ__ProductFeature__c record; 
        public String instructionsText; 
        public Boolean containsUpgrades;
    }
    
    /** @description QuoteLineModel */
    public class QuoteLineModel {
        public SBQQ__QuoteLine__c record;
        public Boolean amountDiscountProrated;
        public Integer parentGroupKey;
        public Integer parentItemKey;
        public Integer key;
        public Boolean upliftable;
        public String configurationType;
        public String configurationEvent;
        public Boolean reconfigurationDisabled;
        public Boolean descriptionLocked;
        public Boolean productQuantityEditable;
        public Decimal productQuantityScale;
        public String dimensionType;
        public Boolean productHasDimensions;
        public Decimal targetCustomerAmount;
        public Decimal targetCustomerTotal;
    }
    
    /** @description QuoteLineGroupModel */
    public class QuoteLineGroupModel {
        public SBQQ__QuoteLineGroup__c record;
        public Decimal netNonSegmentTotal;
        public Integer key;
    }      
    
    /** @description ConfigurationModel */
    public class ConfigurationModel { 
        public Id configuredProductId; 
        public Id optionId; 
        public SBQQ__ProductOption__c optionData; // Editable data about the option in question, such as quantity or discount 
        public SBQQ__ProductOption__c configurationData; 
        public SBQQ__ProductOption__c inheritedConfigurationData; 
        public ConfigurationModel[] optionConfigurations; 
        public Boolean configured; 
        public Boolean changedByProductActions; 
        public Boolean isDynamicOption; 
        public Boolean isUpgrade; 
        public Set<Id> disabledOptionIds; 
        public Set<Id> hiddenOptionIds; 
        public Decimal listPrice; 
        public Boolean priceEditable; 
        public String[] validationMessages; 
        public String dynamicOptionKey; 

         /** @description ConfigurationModel constructor */
        public ConfigurationModel()
        {            
            disabledOptionIds = new set<Id>();
            hiddenOptionIds = new set<Id>();
        }
    }
    
    /** @description ConfigAttributeModel */
    public class ConfigAttributeModel { 
        public String name; 
        public String targetFieldName; 
        public Decimal displayOrder; 
        public String colmnOrder;
        public Boolean required;
        public Id featureId;
        public String position;
        public Boolean appliedImmediately;
        public Boolean applyToProductOptions;
        public Boolean autoSelect;
        public String[] shownValues;
        public String[] hiddenValues;
        public Boolean hidden;
        public String noSuchFieldName;
        public Id myId;
    }
    
    /** @description ConstraintModel */
    public class ConstraintModel { 
        public SBQQ__OptionConstraint__c record; 
        public Boolean priorOptionExists; 
    }
    
    /**
    * @description get fields of sobject
    * @param       sObjectApiName object name
    * @return      string fields
    */
    public string dynamicGetAllFieldsQuery(string sObjectApiName)
    {
        String commaSepratedFields = '';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();

        for(String fieldName : fieldMap.keyset()){
            if(commaSepratedFields == null || commaSepratedFields == ''){
                commaSepratedFields = fieldName;
            }else{
                commaSepratedFields = commaSepratedFields + ', ' + fieldName;
            }
        }
        return commaSepratedFields;
    }
}