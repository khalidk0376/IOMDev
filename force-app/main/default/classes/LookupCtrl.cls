/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 14 Sept, 2021
* @description           : Use to create lookup question 
* Test Class             : LookupCtrl_Test 
* Code Coverage          : 100%

* Modification Log----- 
* Modified by            : Girikon(Mukesh)
**/
public with sharing class LookupCtrl {

    /**
     * FLS Check DONE
     * @sobjectName - Name of SObject
     * @field_API_Text - API name of field to display to user while searching
     * @field_API_ID - API name of field to be returned by Lookup COmponent
     * @limit   - Total number of record to be returned
     * @field_API_Search - API name of field to be searched
     * @searchText - text to be searched
     * Returns JSON of list of LookupWrapper to Lookup Components
     * */
    @AuraEnabled 
    public static String searchDB(String sobjectName, String field_API_Name, String field_ID,String searchText ){
        List<LookupWrapper> lstLookup = new List<LookupWrapper>();     
        try{   
        SObjectType schemaType = ((SObject)Type.forName(sobjectName).newInstance()).getSObjectType();
        Map<String, SObjectField> fields = schemaType.getDescribe().fields.getMap();
        List<sObject> sobjList = new List<sObject>();
        if (fields.get(field_API_Name).getDescribe().isAccessible() && fields.get(field_ID).getDescribe().isAccessible()){
            String query = 'SELECT ' +String.escapeSingleQuotes(field_ID)+','+String.escapeSingleQuotes(field_API_Name)+ ' FROM ' + String.escapeSingleQuotes(sobjectName) +' WHERE '+String.escapeSingleQuotes(field_API_Name)+' LIKE \'%' + String.escapeSingleQuotes(searchText.trim()) + '%\' WITH SECURITY_ENFORCED LIMIT 10';
            sobjList = Database.query(query);
            for(SObject s : sobjList){
                LookupWrapper obj = new LookupWrapper();
                obj.text = String.valueOf(s.get(field_API_Name)) ;
                obj.val = String.valueOf(s.get(field_ID))  ;
                lstLookup.add(obj);
            } 
        }
    }catch(Exception e) {
        String stackTrace = e.getStackTraceString().substringBefore('\n');
        String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
       throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
    }
        return JSON.serialize(lstLookup) ;
    }
    /**
     * wrapper class for lookup
     */

    public class LookupWrapper{
        public String text{get;set;}
        public String val{get;set;}
    }

}