/**
* File         :   IOM_GlobalConstantsData 
* Project      :   Order & Billing Plateform
* Created Date :   09th Sept 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   IOM_SendForOrder_Test(100%)
* ******************************************************************************************************
* @description : Used to Store Constant values
********************************************************************************************************
* Modification log :   
*/
public with sharing class IOM_GlobalConstantsData {
       
    public static final String BLANK_STRING = '';

    public static final String ERROR = 'Error';

    public static final String SUCCESS = 'Success';

    public static final String PENDING = 'Pending';

    public static final String YES = 'Yes';
    
    public static final String PROCESSING = 'Processing';
    
    public static final String MULESOFT = 'Mulesoft';

    public static final String REQUIRED_DATA_ERROR = 'RequiredDataMissing';

    public static final String DATA_TYPE_ERROR = 'InCorrectDataType';

    public static final String DATA_LEN_ERROR = 'ExcededDataLength';
    
    public static final String CUSTOM_ERROR = 'CustomError';

    public static final String OPPORTUNITY_FILTER_STAGE = 'Opportunity_Won_Stage_Name';
    
    public static final String COUNTRIESWITHPOSTALCODE = 'CountriesWithPostalCode';

    public static final String REQUIREDPOSTALCODE = 'RequiredPostalCode';
        
    public static final String COUNTRIESWITHOUTPOSTALCODE = 'CountriesWithoutPostalCode';

    public static final String IOM_SYNC_STATUS = 'IOM_Synchronization_Status';

    public static final String DISABLE_IOM_TRIGGER = 'Disable_IOM_Trigger';

   
    /**
    * @description : get Global Constant value
    * @param  key Developer Name of Global Comstant 
    * @return value from Global Constant
    */
    public static string getValue(string key)
    {
        string value;
        IOM_Global_Configuration_Data__mdt globalConstant = IOM_Global_Configuration_Data__mdt.getInstance(key);
        value = globalConstant != null && globalConstant.Active__c ? globalConstant.IOM_Value__c :'';
        return value;
    }
}