/**
* File         :   GlobalConstants 
* Project      :   Order & Billing Plateform
* Created Date :   09th Sept 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   APISynchronizationSchedule_Test (100%)
* ******************************************************************************************************
* @description : Used to Store Constant values
********************************************************************************************************
* Modification log :   
*/
public with sharing class GlobalConstants 
{
    public static final String BLANK_STRING = '';

    public static final String SUCCESS = 'success';

    public static final String ONESOURCE = 'Onesource';

    public static final String ORACLE = 'Oracle';
    
    public static final String SAP = 'SAP';

    public static final String ERROR = 'Error';

    public static final String PROCESSING = 'Processing';

    public static final String COMPLETED = 'Completed';

    public static final String SYNCHRONOUS = 'Synchronous';

    public static final String ASYNCHRONOUS = 'Asynchronous';

    public static final String QUEUED = 'Queued';

    public static final String PAUSED = 'Paused';

    public static final String ACTIVE = 'Active';

    public static final String DRAFT = 'Draft';

    public static final String REQUEUE_ALL = 'Requeue All';

    public static final String TAX = 'Tax';

    public static final String POST = 'POST';

    public static final String POST_DOCUMENTS = 'Post Documents';

    public static final String ACCOUNTING_CREDIT_STATUS = 'Accounting Credit Status';

    public static final String OPPORTUNITY_REJECTED = 'Opportunity Rejected';
    
    public static final String OPPORTUNITY_CLOSED_LOST = 'Opportunity Closed Lost';
    
    public static final String CHANGE_REQUEST_COMPLETED = 'Amendment Completed';

    public static final String AMENDMENT_REQUEST_APPROVED_REJECTED = 'Amendment Request Approved/Rejected';
    
    public static final String PO_NUMBER_CHANGE = 'PO number change';

    public static final String SYNC_REQUIRED = 'Sync Required';

    public static final String AMENDED_DATA_SYNC = 'Amended Data Sync';

    public static final String AMENDED_DATA_SYNC_OH = 'Amended Data Sync - OH';
    
    public static final String ACCOUNT_ERP_NUMBER_UPDATE = 'Account ERP Number Update';
    
    public static final String ACCOUNT_DELETE = 'Account Delete';
    
    public static final String OPPORTUNITY_DELETE = 'Opportunity Delete';
    
    public static final String CONTACT_DELETE = 'Contact Delete';

    public static final String POST_PAYMENT_TRANSACTIONS = 'Post Payment Transactions';
    
    public static final String OLI_START_END_AMOUNT_UPDATE = 'OLI Start End Amount Update';
    
    public static final String ERP_REF_NUMBER_BACK_UPDATE_TO_CRM = 'ERP Ref. Number back update to CRM';
    

    /**
    * @description : get Global Constant value
    * @param  key Developer Name of Global Comstant 
    * @return value from Global Constant
    */
    @AuraEnabled
    public static string getValue(string key)
    {
        string value;
        Global_Constant__mdt globalConstant = Global_Constant__mdt.getInstance(key);
        value = globalConstant != null ? globalConstant.Value__c :'';
        return value;
    }

}