/**
* File         :   IOM_BulkUploadMetadata_Test 
* Project      :   Order & Billing Plateform
* Created Date :   24th Jan 2022
* Created By   :   Girikon(Ashish)
* ******************************************************************************************************
 @description : Test Class to cover IOM_BulkUploadMetadata
*******************************************************************************************************
* Modification log :
* 1. 
*/
@isTest
private with sharing class IOM_BulkUploadMetadata_Test
{
    @isTest static void testUpdateBulkMetadata()
    {
        String jsonString  = '{"TEST_META001":[{"index":"1","value":"TEST_001"},{"index":"2","value":"My_Test_Node"},{"index":"3","value":"Name"},{"index":"4","value":"Opportunity"},{"index":"5","value":"255"},{"index":"6","value":"Text"},{"index":"7","value":"Id"},{"index":"8","value":"false"},{"index":"9","value":"false"},{"index":"10","value":"Opportunity Sync"},{"index":"11","value":"true"}]}';
        String mappingString = '{"0":{"fieldname":"DeveloperName","datatype":"String"},"1":{"fieldname":"MasterLabel","datatype":"String"},"2":{"fieldname":"IOM_Node_Name__c","datatype":"String"},"3":{"fieldname":"CRM_Object_Field__c","datatype":"String"},"4":{"fieldname":"CRM_Object__c","datatype":"String"},"5":{"fieldname":"IOM_Node_Data_Length__c","datatype":"Double"},"6":{"fieldname":"IOM_Node_Type__c","datatype":"Picklist"},"7":{"fieldname":"Record_Id_Filter_Field__c","datatype":"String"},"8":{"fieldname":"Required__c","datatype":"Boolean"},"9":{"fieldname":"Child_Node__c","datatype":"Boolean"},"10":{"fieldname":"Type__c","datatype":"Picklist"},"11":{"fieldname":"Active__c","datatype":"Boolean"}}';
        String customMetaDataName = 'IOM_Integration_Mapping__mdt';
        String res = IOM_BulkUploadMetadata.updateBulkMetadata(jsonString, mappingString, customMetaDataName);
        System.assertNotEquals(null, res,'Metadata Insert Failed');        
    }
    @isTest static void testGetCustomMetaDataList()
    {        
        List<IOM_BulkUploadMetadata.MdtWrapper> listMetaData = IOM_BulkUploadMetadata.getCustomMetaDataList();
        System.assertNotEquals(0,listMetaData.size(),'Metadata Objcet not found');        
    }
}