/**
* File             : BulkUploadMetadata
* Created Date     : 23 Dec 2021
* Created By       : Ansh(Girikon)
* Test Class       : IOM_BulkUploadMetadata_Test
* @description     : to Bulk Upload Metadata Records
********************************************************************
* Last Modified By : 
*/
public class IOM_BulkUploadMetadata {    
    
    /**
    * @description updateBulkMetadata
    * @param  jsonString
    * @param  mappingString
    * @param  customMetaDataName
    * @return string
    */
    @AuraEnabled
    public static string updateBulkMetadata(String jsonString, String mappingString,String customMetaDataName){        
        Map<String,List<CustomMetadataDataWrapper>> dataMap = (Map<String,List<CustomMetadataDataWrapper>>)JSON.deserialize(jsonString, Map<String,List<CustomMetadataDataWrapper>>.class);
        Map<String,CustomMetadataMappingWrapper> mappingMap = (Map<String,CustomMetadataMappingWrapper>)JSON.deserialize(mappingString, Map<String,CustomMetadataMappingWrapper>.class);
        System.debug(LoggingLevel.DEBUG,'dataMap**'+dataMap);  
        System.debug(LoggingLevel.DEBUG,'mappingMap**'+mappingMap); 
        System.debug(LoggingLevel.DEBUG,'customMetaDataName**'+customMetaDataName);  
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for(String devName : dataMap.keySet()){
            Metadata.CustomMetadata metadataRec =  new Metadata.CustomMetadata();
            metadataRec.fullName = customMetaDataName+'.'+devName;
            for(CustomMetadataDataWrapper data : dataMap.get(devName)){
                CustomMetadataMappingWrapper mapping = mappingMap.get(data.index);
                if(mapping.fieldname == 'MasterLabel'){
                    metadataRec.label = data.value;
                }
                else{
                    Metadata.CustomMetadataValue customFieldtoUpdate = new Metadata.CustomMetadataValue();
                    customFieldtoUpdate.field = mapping.fieldname;
                    customFieldtoUpdate.value = getValue(mapping.datatype,data.value);

                    metadataRec.values.add(customFieldtoUpdate);
                }
            }
            mdContainer.addMetadata(metadataRec);
        }
        System.debug(LoggingLevel.DEBUG,'mdContainer**'+mdContainer);            
        // Enqueue custom metadata deployment
        // jobId is the deployment ID
        String jobId = 'Deploying..';
        if(!Test.isRunningTest())
        {
        	jobId = Metadata.Operations.enqueueDeployment(mdContainer, null);    
        }
        System.debug(LoggingLevel.DEBUG,'jobId***'+jobId);                                   
        return jobId;
    }

    /**
    * @description getCustomMetaDataList
    * @return List<MdtWrapper>
    */
    @AuraEnabled
    public static List<MdtWrapper> getCustomMetaDataList(){
        List<MdtWrapper> listMDTWrap = new List<MdtWrapper>();
        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()){
            String apiName = objTyp.getDescribe().getName();
            if(apiName.endsWith('__mdt') && apiName.countMatches('__') == 1){
                MdtWrapper mdtWrap = new MdtWrapper();
                mdtWrap.label = objTyp.getDescribe().getLabel();
                mdtWrap.value = apiName;
                listMDTWrap.add(mdtWrap);
            }
        }
        return listMDTWrap;
    }

    /**
    * @description get Type Converted Value 
    * @param  dataType  [Boolean,Number]
    * @param  value  Object value
    * @return Object
    */
    private static Object getValue(string dataType,string value)
    {
        Object val ;
        switch on dataType {
            when 'Boolean' {
                val = Boolean.valueOf(value);
            }	
            when 'Double' {
                val = Decimal.valueOf(value);
            }
            when else {
                val = value;
            }
        }
        return val;
    }

    /** @description */
    public class CustomMetadataDataWrapper{
        public String index;
        public String value;
    }

    /** @description */
    public class CustomMetadataMappingWrapper{
        public String fieldname;
        public String datatype;
    }

    /** @description */
    public class MdtWrapper{
        /** @description */
        @AuraEnabled
        public String label;
        /** @description */
        @AuraEnabled
        public String value;
    }
}