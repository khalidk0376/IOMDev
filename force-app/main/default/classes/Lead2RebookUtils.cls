/**
* Created By       :   Girikon(Ashish)
* Created On       :   25/11/2019
* @description     :   This class provides following functionalities:          
*                      This is utility class for the project to get data for lookups with filter
*                      1. getSObjects(to get sObject Values  for CustomLookUp based on filter)
*                      
* Test Class       :   Lead2RebookUtils_Test(100%)
*/
public with sharing class Lead2RebookUtils 
{
    /*
    * @description  :   to get sObject Values  for CustomLookUp based on filter
    * @param        :   json of WraplookUp
    * @return       :   get list of top 10 sObject based on filter criteria
    */
    @AuraEnabled
    public static List<sObject> getSObjects(string prams) // Method to get sObject Values  for CustomLookUp Cmp
    {
        list<sObject> listObject  = new list<sObject>();
        WraplookUp parameter = new WraplookUp ();
        parameter = (WraplookUp)JSON.deserialize(prams, WraplookUp.class);
        String nameField    = (parameter.fieldSetAsLabel != 'Name'?','+parameter.fieldSetAsLabel:',Name');
        String idField      = (parameter.fieldSetAsValue != 'Id'?'Id,'+parameter.fieldSetAsValue:'Id');
        string strQuery = 'Select '+String.escapeSingleQuotes(idField) +String.escapeSingleQuotes(nameField)+' FROM '+String.escapeSingleQuotes(parameter.objectName);        
        
        if(String.isNotBlank(parameter.searchKey))
        {
            String searchKey = String.escapeSingleQuotes(parameter.searchKey);
            strQuery =strQuery+' WHERE '+String.escapeSingleQuotes(parameter.fieldSetAsLabel)+' LIKE \'%'+searchKey+'%\'';
        }
        if(String.isNotBlank(parameter.searchKey) && String.isNotBlank(parameter.filterByFieldValue))
        {
            String val = String.escapeSingleQuotes(parameter.filterByFieldValue);
            strQuery =strQuery+' AND '+String.escapeSingleQuotes(parameter.filterByFieldName)+'=\''+val+'\'';
        }
        if(String.isBlank(parameter.searchKey) && String.isNotBlank(parameter.filterByFieldValue))
        {
            String val = String.escapeSingleQuotes(parameter.filterByFieldValue);
            strQuery =strQuery+' WHERE '+String.escapeSingleQuotes(parameter.filterByFieldName)+'=\''+val+'\'';
        }

        strQuery = strQuery + ' ORDER BY '+String.escapeSingleQuotes(parameter.fieldSetAsLabel)+' ASC LIMIT 10 OFFSET 0'; 
        System.debug(strQuery);
        listObject = Database.query(strQuery);
        return listObject;
    }

    public class WraplookUp // CustomLook-Up Lightning Cmp Pram Wraper
    {
        @AuraEnabled public String searchKey;
        @AuraEnabled public String objectName;        
        @AuraEnabled public String filterByFieldName;
        @AuraEnabled public String filterByFieldValue;
        @AuraEnabled public String fieldSetAsLabel;
        @AuraEnabled public String fieldSetAsValue;
    }
}