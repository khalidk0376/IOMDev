/**
* File         :   CustomLookupLwcCtrl 
* Project      :   Order & Billing Plateform  [GECI-236]
* Created Date :   15th Dec 2022
* Created By   :   Girikon(Ashish)  
* Test Class   :   CustomLookupLwcCtrl_Test(95%)
* ******************************************************************************************************
 @description : for Dynamic LWC Lookup Ctrl
*******************************************************************************************************
* Modification log :
*/
public class CustomLookupLwcCtrl {
/**
    * @description  This method is used to get lookup Options
    * @param searchKey serach key "value"
    * @param inputJSON input Prams
    * @return List<sObject> records
    */
     @AuraEnabled(cacheable=true)
     public static list<sObject> fetchLookupData(string searchKey ,string inputJSON) {
        CustomLookupLwcCtrl.LookupWrapper inputObj = (CustomLookupLwcCtrl.LookupWrapper)JSON.deserialize(inputJSON,CustomLookupLwcCtrl.LookupWrapper.class);        
        List < sObject > returnList = new List < sObject > ();
        string sWildCardText = '%' + searchKey + '%';
        string labelFieldAPI = String.isNotBlank(inputObj.labelFieldAPI) ? inputObj.labelFieldAPI: 'Name';
        String allFieldAPI = labelFieldAPI+(String.isNotBlank(inputObj.otherFields)?','+inputObj.otherFields:'');
        string filterCondition = String.isNotBlank(inputObj.filterCondition) ? 'AND '+inputObj.filterCondition: '';
        String[] otherSearchFields = String.isNotBlank(inputObj.otherSearchFields) ? inputObj.otherSearchFields.split(',') : new List<String>();
        //string sQuery = 'Select Id,'+allFieldAPI+' From ' + inputObj.sObjectApiName + ' Where '+labelFieldAPI+' Like : sWildCardText '+filterCondition+' order by createdDate DESC LIMIT 5';
        string sQuery = 'Select Id,'+allFieldAPI+' From ' + inputObj.sObjectApiName + ' Where '+getSearchQueryString(labelFieldAPI,otherSearchFields)+filterCondition+' order by createdDate DESC LIMIT 5';
        System.debug('Query -'+ sQuery);
        return database.query(sQuery);
     }

    private static string getSearchQueryString(String labelFieldAPI,String[] otherFields)
    {
        string searchQuery = labelFieldAPI+' Like : sWildCardText ';
        if(!otherFields.isEmpty()){   
            searchQuery = '( '+searchQuery;
            for(String otherField:otherFields){
                searchQuery += ' OR '+otherField+' Like : sWildCardText';
            }
            searchQuery += ') ';
        }
        return searchQuery;
    }
     
    /**
    * @description  This method is used to get the default value
    * @param recordId Record Id
    * @param sObjectApiName sObject Name
    * @return String 
    */
     @AuraEnabled
     public static sObject fetchDefaultRecord(string recordId , string sObjectApiName) {
         string sRecId = recordId;    
         string sQuery = 'Select Id,Name From ' +String.escapeSingleQuotes(sObjectApiName)+ ' Where Id = : sRecId LIMIT 1';
         for (sObject obj: database.query(sQuery)) {
             return obj;
         }
         return null;
     }

     public class LookupWrapper{
        string sObjectApiName;
        string labelFieldAPI;
        string filterCondition;
        string otherFields;
        string otherSearchFields;
     }
}