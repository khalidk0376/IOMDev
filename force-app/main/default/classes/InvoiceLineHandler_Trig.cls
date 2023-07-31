/**
* Raider Data Services, TT
* @description Handler Class for Trigger_InvoiceLine to populate BillToContact on Invoice
* Test Class - InvoiceLineHandler_TrigTest(92%)
* Date 12/07/2019
*/
public with sharing class InvoiceLineHandler_Trig implements TriggerInterface_InvoiceLine.Runnable{
    
    // static reference of the SObjects to be used across methods and initialized only once
    static Map<String, Map<Id, SObject>> mapSObjRecords;
    // static reference of Map to query additional fields for objects
    static Map<String, String> mapSObjAddtlFields = new Map<String, String>();
    
    /**
     * @description Trigger handler method for Invoice based on the event called, the processing is dispatched accordingly
     * @param trig TriggerInterface_Invoice.Trig class instance 
     */
    public void run(TriggerInterface_InvoiceLine.Trig trig) {
        if(trig.isBefore && trig.isInsert){
            //Method to set Deferred Revenue Start and End Dates On Invoice.
            //InvoiceLineHandler_Trig.setDeferredRevDates(trig.newList, 'blng__InvoiceLine__c');
            //Method to add sequence Numberson InvoiceLines
            InvoiceLineHandler_Trig.addInvLineSequenceNo(trig.newList);  
        }
    
        //if(trig.isAfter && trig.isInsert){
            //Method to populate BillToContact On Invoice.
            //InvoiceLineHandler_Trig.updateBillToContact(trig.newMap);
            //Add sequence no on InvoiceLines
            //InvoiceLineHandler_Trig.addInvLineSequenceNo(trig.newMap);  
        //}
    }

    /**
    *@description add sequence No on invoiceLines   
    *@param listOfInvLine List Of InvoiceLines
    */    
     public static void addInvLineSequenceNo(List<blng__InvoiceLine__c> listOfInvLine){
         Map<Id,Integer> mapInvIdStartSequenceNum = new Map<Id,Integer>();
         for(blng__InvoiceLine__c invLine : listOfInvLine){
             mapInvIdStartSequenceNum.put(invLine.blng__Invoice__c,0);
         }
 
         for(blng__InvoiceLine__c invLine : [SELECT Id,Line_Item_Number__c,blng__Invoice__c FROM blng__InvoiceLine__c WHERE blng__Invoice__c IN:mapInvIdStartSequenceNum.keySet() WITH Security_Enforced ORDER BY blng__Invoice__c,Line_Item_Number__c ASC]){
             mapInvIdStartSequenceNum.put(invLine.blng__Invoice__c,Integer.valueOf(invLine.Line_Item_Number__c));
         }
 
         for(blng__InvoiceLine__c invLine : listOfInvLine){
             Integer seq = mapInvIdStartSequenceNum.get(invLine.blng__Invoice__c) + 1;
             invLine.Line_Item_Number__c = seq;
             mapInvIdStartSequenceNum.put(invLine.blng__Invoice__c,seq);
         }
     }

    /**
     * @description Method to update BillTocontact on Invoice
     * @param mapInvLine Map Of InvoiceLines.
     */
    /*public static void updateBillToContact(Map<id, blng__InvoiceLine__c> mapInvLine){
        Map<Id,blng__InvoiceLine__c> mapOfInvToInvLine = new Map<Id,blng__InvoiceLine__c>(); 
        List<blng__Invoice__c> lstOfInvoicesToUpdate = new List<blng__Invoice__c>();
        Set<Id> setOfOrderItemId = new Set<Id>();
        Map<Id,Id> mapOrderProductIdInvoiceId = new Map<Id,Id>();
        for(blng__InvoiceLine__c invLine : mapInvLine.values()){
            mapOfInvToInvLine.put(invLine.blng__Invoice__c,invLine);
            setOfOrderItemId.add(invLine.blng__OrderProduct__c);
        }
        //retrieve all Invoices related to InvoiceLines  
        Map<Id,blng__Invoice__c> mapOfInvoices = new Map<Id,blng__Invoice__c>([Select Id,Name,blng__BillToContact__c,Legal_Entity__c,PO_Number__c,Tax_Registration__c, Tax_Rule__c , Tax_Exempt__c from blng__Invoice__c Where id=:mapOfInvToInvLine.KeySet() WITH SECURITY_ENFORCED]);
        Map<Id,OrderItem> mapOfOrderItems = new Map<Id,OrderItem>();
        //method to get InvoiceLine Realted OrderItem and Order.
         mapOfOrderItems = InvoiceLineHandler_Trig.getOrders(setOfOrderItemId);
        //Update Invoices
        for(blng__Invoice__c inv : mapOfInvoices.values()){
            blng__InvoiceLine__c invLine = mapOfInvToInvLine.get(inv.Id);
            if(invLine !=null && invLine.blng__OrderProduct__c !=null ){
                OrderItem ordItem = mapOfOrderItems.get(invLine.blng__OrderProduct__c);
                inv.blng__Order__c = invLine.Order_ID__c;
                if(ordItem.OrderId != null && ordItem.Order.BillToContactId != null){
                    //populate Billing_Contact__c field on Invoice. 
                    inv.blng__BillToContact__c = ordItem.Order.BillToContactId;
                }
                if(ordItem.OrderId != null && ordItem.Order.Legal_Entity__c != null){
                    //populate Legal_Entity__c field on Invoice. 
                    inv.Legal_Entity__c = ordItem.Order.Legal_Entity__c;
                }
                if(ordItem.OrderId != null && ordItem.Order.PoNumber != null){
                    //populate PO_Number__c field on Invoice. 
                    inv.PO_Number__c = ordItem.Order.PoNumber;
                }
                if(ordItem.OrderId != null && ordItem.Order.Account_Tax_Number__c != null){
                    //populate Account_Tax_Number__c field on Invoice. 
                    inv.Tax_Registration__c = ordItem.Order.Account_Tax_Number__c;
                }
                if(ordItem.OrderId != null && ordItem.Order.Tax_Rule__c != null){
                    //populate Tax_Rule__c field on Invoice. 
                    inv.Tax_Rule__c = ordItem.Order.Tax_Rule__c;
                }
                if(ordItem.OrderId != null && ordItem.Order.Tax_Exempt1__c != null){
                    //populate Tax_Exempt__c field on Invoice. 
                    inv.Tax_Exempt__c = ordItem.Order.Tax_Exempt1__c;
                }
                lstOfInvoicesToUpdate.add(inv);
                //Add order product Id
                mapOrderProductIdInvoiceId.put(ordItem.Id,inv.Id);
            }
        }
        
        //if Invoice has update permission then update Invoice
        if(lstOfInvoicesToUpdate.size() > 0 && Schema.sObjectType.blng__Invoice__c.isUpdateable()){
            update lstOfInvoicesToUpdate;
        }
        
    }*/
    
    /**
     * @description Method to get Map of Orders
     * @param setOfOrderItemId set of OrderItem Id
     * @return Map<Id,OrderItem> map of OrderItems
     */
    /*public static Map<Id,OrderItem> getOrders(Set<Id> setOfOrderItemId){
        Map<Id,OrderItem> mapOfOrderItems = new Map<Id,OrderItem>();
        if(setOfOrderItemId.size() > 0){
            //retrieve OrderItems related to setOfOrderItemId
            for(OrderItem ordItem:[SELECT Id,OrderItemNumber,OrderId,Order.BillToContactId,Order.PoNumber,Order.Legal_Entity__c,Order.Account_Tax_Number__c,Order.Tax_Rule__c,Order.Tax_Exempt1__c FROM OrderItem WHERE id=:setOfOrderItemId WITH SECURITY_ENFORCED]){
                mapOfOrderItems.put(ordItem.Id,ordItem);
            }
        }
        return mapOfOrderItems;
    }*/

    /**
     * @description Method to format the line description based on the format given on the Product with related object fields
     * @param lstNewInvli  list of lines - the function modifies the input lines 
     * @param sObjType name of the sObject
     */
    /*public static void setDeferredRevDates(List<SObject> lstNewInvli, String sObjType){
        Map<String, Schema.SObjectField> fieldMap = 
            Schema.getGlobalDescribe().get(sObjtype).getDescribe().fields.getMap();
        System.debug(LoggingLevel.DEBUG, fieldMap);
        
        // hold reference of field api name and its related sObject Type
        Map<String, String> mapFieldObject = new Map<String,String>();
        
        // also hold reference to SObject Type to the related field
        // THIS WILL BREAK IF THERE ARE TWO FIELDS OF THE SAME TYPE IN QLI AS THE LINE DESCRIPTION
        // IS EXPECTED TO BE OF THE FORM - Object Name.Field Name
        Map<String, String> mapObjectToLookup = new Map<String,String>();
        
        // hold Ids specific to each sObjectType
        Map<String, Set<Id>> mapSObjToSFIDs = new Map<String, Set<Id>>();
        
        initReferenceMaps(sObjType, mapFieldObject, mapObjectToLookup);
        for(SObject inLi : lstNewInvli){
            for(String sObjField : mapFieldObject.keySet()){
                Object lookupId = inLi.get(sObjField);
                Set<Id> sObjIds = mapSObjToSFIDs.get(sObjField);
                if(sObjIds == null) {
                    sObjIds = new Set<Id>();
                }  
                // if referenced field is null, continue
                if(lookupId != null) {
                    // get Ids specific to lookup field                    
                    sobjIds.add(String.valueOf(lookupId));                    
                }
                //map of InvoiceLine Field Api with set of Reference object Id Values.
                // e.g.<'blng__Product__c',set<'01tS0000007h2eqIAA','01tS0000007h2eqIAS'>>                  
                mapSObjToSFIDs.put(sObjField, sObjIds);
            }
        }
        Map<Id, Product2> mapProduct2 = new Map<Id, Product2>();
        // get Product Ids from the above map based on Product reference
        Set<Id> prodIds = new Set<ID>();
        prodIds = mapSObjToSFIDs.get('blng__product__c');
        if(prodIds != null && prodIds.size() > 0){
            mapProduct2 = new Map<Id,Product2>((list<Product2>)queryDB('Product2', prodIds));
        }

        //collect all referred object api name in Revenue Rule format for querying related products
        Set<String> setObjName = getObjNames(mapProduct2, 'Revenue_Recognition_End_Date_Rule__c');
        setObjName.addAll(getObjNames(mapProduct2, 'Revenue_Recognition_Start_Date_Rule__c'));

        //query all related objects for the values being referred in Revenue Rule Format
        mapSObjRecords = getAllRelatedSObjects(setObjName, mapFieldObject, mapSObjToSFIDs); 
        for (SObject objInvLI : lstNewInvli ){
            transformInLI(objInvLI, mapProduct2, mapObjectToLookup);          
        }        
    }*/

    /**
     * @description init reference maps
     * @param sObjType 
     * @param mapFieldObject the first map to hold Field to Object api mapping
     * @param mapObjectToLookup with map to hold object api name to Lookup field
     */
    /*private static void initReferenceMaps(String sObjType, Map<String, String> mapFieldObject,
        Map<String, String> mapObjectToLookup) {
        
        Map<String, Schema.SObjectField> fieldMap =  
            Schema.getGlobalDescribe().get(sObjtype).getDescribe().fields.getMap();
        for (String fieldName: fieldMap.keySet()) {
            DescribeFieldResult fldResult = fieldMap.get(fieldName).getDescribe();
            if(fldResult.getType() == Schema.DisplayType.reference){
                String refTo = (fldResult.getReferenceTo() + '').replace('(', '').replace(')','');
                mapFieldObject.put(fieldName, refTo);
                mapObjectToLookup.put(refTo, fieldName);
            }
        }
    }*/

    /**
     * @description method to format the line description on the actual line
     * @param objInLI the specific Invoice Line item that needs to be transformed
     * @param mapProduct2 map of related Product records
     * @param mapObjectToLookup reference map with Object to lookup fields     
     */
    /*private static void transformInLI(SObject objInLI, Map<Id, Product2> mapProduct2,Map<String, String> mapObjectToLookup) {
        String prodDesc = '';
        ID prod2Id = (ID)objInLI.get('blng__product__c');
        prodDesc = (String)mapProduct2.get(prod2Id).get('Revenue_Recognition_End_Date_Rule__c');
        prodDesc =  getDeferredRevenueDates(prodDesc,objInLI,mapObjectToLookup);
        if(prodDesc != '' && prodDesc!= 'null' && prodDesc!= null ){
            // cleanup final value    
            String endDateRevRec = String.join(getCleanDescriptions(prodDesc), '');
            endDateRevRec = setDateFormatWithLocale(endDateRevRec);
            // put final value in InvLI
            objInLI.put('Revenue_Recognition_End_Date__c', Date.parse(endDateRevRec));
        }     
        //get Revenue_Recognition_Start_Date_Rule__c
        prodDesc = (String)mapProduct2.get(prod2Id).get('Revenue_Recognition_Start_Date_Rule__c');
        prodDesc =  getDeferredRevenueDates(prodDesc,objInLI,mapObjectToLookup);
        if(prodDesc != '' && prodDesc!= 'null' && prodDesc!= null){
            // cleanup final value                
            String startDateRevRec = String.join(getCleanDescriptions(prodDesc), '');
            startDateRevRec = setDateFormatWithLocale(startDateRevRec);
            // put final value in InvLI
            objInLI.put('Revenue_Recognition_Start_Date__c', Date.parse(startDateRevRec));
        }         
    }*/
   
    /**
     * @description change date fromat according to locale
     * @param str String Date Format
     * @return String date formate according to the locale.
     */
    /*public static String setDateFormatWithLocale(String str){
        String newDateFormat ;
        Set<String> setOflocale = new Set<String>{'en_IN','en_GB','en_CA'} ;
        String locale = Userinfo.getlocale();
        string part1 = str.substringBefore('/') ;
        str = str.substringAfter('/');
        String part2 = str.substringBefore('/') ;
        str = str.substringAfter('/');
        String part3 = str;
        if(setOflocale.contains(locale)){
            newDateFormat = part2 +'/'+part1+'/'+part3;
        }
        else{
            newDateFormat = part1 +'/'+part2+'/'+part3;
        }
        return newDateFormat;
    }*/
    
    
    /**
     * @description method to get date values from format
     * @param prodDesc Revenue Recognition field format from products
     * @param objInLI the specific Invoice Line item that needs to be transformed
     * @param mapObjectToLookup reference map with Object to lookup fields   
     * @return String  date values in string format 
     */
    /*private static String getDeferredRevenueDates(String prodDesc,SObject objInLI,Map<String, String> mapObjectToLookup){
        prodDesc = (prodDesc == null ? '' : prodDesc);
        for (String description : prodDesc.split('\\+')) {
            if (description.contains('[') && description.contains(']') && description.contains('.')) {
                String strFieldProd = description.substring(description.indexof('[')+1,description.indexof(']'));
                
                String recValStr = transformField(description, objInLI, mapObjectToLookup);                                               
                prodDesc = prodDesc.replace('['+strFieldProd+']', recValStr+'');
            }
            else if (description.contains('[') && description.contains(']')) {
                String strFieldInL = description.substring(description.indexof('[')+1,description.indexof(']'));
                prodDesc = prodDesc.replace('['+strFieldInL+']', objInLI.get(strFieldInL)+'');
            }
        }
        return prodDesc;
    }*/
    
    /**
     * @description Method for final cleanup of transformed line Date Rule to remove actual field references from template string
     * @param prodDesc with input string
     * @return list of String with field and object references removed
     */
    /*private static List<String> getCleanDescriptions(String prodDesc) {
        List<String> lineDescription = new List<String>();
        for(String str : prodDesc.split('\\+')){
            if(str.contains('[') && str.contains('[')){
                str = str.substring(str.indexof('[')+1,str.indexof(']'));
                str = str.replace(str, '');
            }
            lineDescription.add(str);
        }
        return lineDescription;
    }*/

    /**
     * @description Method to transform a specific string with description having field references
     * @param description input string         
     * @param objQLI source Quote line item
     * @param mapObjectToLookup reference map with Object to lookup field api name
     * @return String value of the description part
     */
    /*private static String transformField(String description, SObject objQLI,
        Map<String, String> mapObjectToLookup) {
        String recValStr = '';
        if (description.contains('[') && description.contains(']') && description.contains('.')) {
            String strFieldProd = description.substring(description.indexof('[')+1,description.indexof(']'));
            
            // get records associated with this object
            String objName = strFieldProd.split('\\.')[0];
            String fldName = strFieldProd.replace(objName + '.', '');
            Map<Id, SObject> records = mapSObjRecords.get(objName);
            String relatedFldName = '';
            Object lookupVal;
            SObject refRecord;                
            
            relatedFldName = mapObjectToLookup.get(objName);
            lookupVal = objQLI.get(relatedFldName);
            refRecord = (lookupVal == null ? null : records.get((Id)lookupVal));
            recValStr = (refRecord == null ? '' : getFieldVal(refRecord, fldName));          
        }
        return recValStr;
    }*/

    /**
     * @description Method to get comma separated string for query clause from a set of ids
     * @param recordIds set of record ids
     * @return comma separated string
     */
    /*public static String getCSVIds(Set<Id> recordIds) {
        String result = '';
        for(Id recordId: recordIds) {
            String entry = '\'' + String.escapeSingleQuotes((String)recordId) + '\'';
            if(result == '') {
                result = entry;
            }
            else {
                result = result + ',' + entry;
            }
        }
        return '(' + result + ')';
    }*/
    
    /**
     * @description Method to query and return results
     * @param sObjType SObject to query
     * @param recordIds set of record ids
     * @return List<SObject>
     */
    /*public static List<SObject> queryDB(String sObjType, Set<Id>recordIds) {
        String addtlFields = mapSObjAddtlFields.get(sObjType);
        if(addtlFields == null) {
            addtlFields = '';
        }
        else {
            addtlFields = addtlFields +',';
        }
         Set<String> setOfFields = new set<String>();
        if(addtlFields != null && addtlFields!= 'null' && addtlFields!= ''){
             setOfFields.addAll(addtlFields.split('\\,'));
        }
        String extraFields = '';
        if(setOfFields.size() > 0 ) {
            for(String str : setOfFields){
                extraFields = extraFields + str + ',';
            }
        }
        
        String query = 'SELECT '+ extraFields + 
            String.join(new List<String>(Schema.getGlobalDescribe().get(sObjType).getDescribe().fields.getMap().keySet()), ',') + ' FROM ' + sObjType + ' WHERE Id in ' + getCSVIds(recordIds);
                                
        List<SObject> lstSObject = DataBase.query(String.escapeSingleQuotes(query).replace('\\',''));
        return lstSObject;
    }*/
    
    /**
     * @description method to get value from an sObject
     * @param setObjName
     * @param mapFieldObject
     * @param mapSObjToSFIDs
     * @return Map<String, Map<Id, SObject>> map of SObjects identified by sObject type
     */
    /*public static Map<String, Map<Id, SObject>> getAllRelatedSObjects(Set<String> setObjName, Map<String, String> mapFieldObject,
        Map<String, Set<Id>> mapSObjToSFIDs) {
        Map<String, Map<Id, SObject>> mapSObjRecords = new Map<String, Map<Id, sObject>>();
        for(String objName: setObjName) {
            // get all ids related to this object from previous maps
            Set<Id> sObjIds = new Set<Id>();
            for(String sObjField : mapFieldObject.keySet()){
                if(mapFieldObject.get(sObjField).toLowerCase() == objName.toLowerCase() &&
                    mapSObjToSFIDs.get(sObjField.toLowerCase()) != null) {
                        // get all ids related to this field
                        sObjIds.addAll(mapSObjToSFIDs.get(sObjField.toLowerCase()));
                    }
            }
            // query related objName and store records in the map
            Map<Id, SObject> mapRecordsDb = new Map<Id,SObject>(queryDB(objName, sObjIds));
            mapSObjRecords.put(objName, mapRecordsDb);
        }
        return mapSObjRecords;
    }*/

    /**
     * @description Method to get FieldValue from Object by handling different data types
     * @param refRecord related sObject
     * @param fldName the field for which we need the value
     * @return String value blank or actual value
     */
    /*public static String getFieldVal(SObject refRecord, String fldName) {
        String recValStr = '';
        Object recVal;
        if(!fldName.contains('.')) {
            recVal = refRecord.get(fldName);
        }
        else {
            SObject relatedObject = refRecord.getSObject(fldName.split('\\.')[0]);
            if(relatedObject != null) {
                recVal = relatedObject.get(fldName.split('\\.')[1]);
            }
        }
        DateTime dt;
        if(recVal instanceOf Date) {
            Date recValDate = (Date)recVal;
            dt = DateTime.newInstance(recValDate.year(), recValDate.month(), recValDate.day());
        }
        if(recVal instanceof DateTime) {
            dt = ((DateTime)recval);
        }
        if(dt != null) {
            recValStr = dt.formatGMT('MM/dd/YYYY');
        }
        else {
            recValStr = recVal + '';
        }
        return recValStr;
    }*/

    
    /**
     * @description Method to get all related Objects referred in the Product Line description
     * @param mapProduct2 affected products in this transaction
     * @param revrecField Revenue Recognition rule on product.
     * @return set of String with object name
     */
    /*private static Set<String> getObjNames(Map<Id, Product2> mapProduct2, String revrecField) {
        Set<String> setObjName = new Set<String>();
        for(Product2 prd : mapProduct2.values()){
            if(prd.get(revRecField) !=null ){
                for (String description : ((String)prd.get(revRecField)).split('\\+')) {
                    // pick fields referred from another object
                    if (description.contains('[') && description.contains(']') && description.contains('.')) {
                        String strFieldProd = description.substring(description.indexof('[')+1,description.indexof(']'));
                        //s=s.substring(s.indexof('[')+1,s.indexof(']'));                        
                        List<String> allParts=strFieldProd.split('\\.');
                        if(allParts.size() > 2) {
                            String fldName = strFieldProd.replace(allParts[0]+'.', '');
                            String existingFlds = mapSObjAddtlFields.get(allParts[0]); 
                            existingFlds = (existingFlds == null) ?  fldName : existingFlds + ',' + fldName;
                            mapSObjAddtlFields.put(allParts[0], existingFlds);
                        }
                        allParts.remove(allParts.size()-1);
                        setObjName.add(allParts[0]);
                    }
                }
            }
        }
        return setObjName;
    }*/
}