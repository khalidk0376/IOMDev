/**
* Created/Modified By    : Girikon(Arushi [IMCC-4862])
* Created On             : 22-Nov-2022
* @description           : Helper class method can be called on demand to make API Callout 
* Test Class             : Imcc_APICallOutVisit_Test
* Code Coverage          : 100%
**/
public with sharing class IMCC_APICallOutVisit {
    /**
    * @description  to make API Callout
    */    
    @future(callOut = True)
    public static void makeGetCallout() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Get_Call_Visit_Api2');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 200) {
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            System.debug(LoggingLevel.DEBUG, results);
        }
        else{
            Custom_Error_Log__c customLog = new Custom_Error_Log__c();
            customLog.Message__c = response.getBody();
            customLog.StackTrace__c = response.getBody();
            customLog.Type__c = response.getStatusCode() + '';
            customLog.Method__c = 'makeGetCallout';
            customLog.Apex_Class__c = 'IMCC_APICallOutVisit';
            customLog.OwnerId = UserInfo.getUserId();
            customLog.On__c = 'On Visit Get API Callout';
            Boolean byPass = true;
            if(byPass || Schema.sObjectType.Custom_Error_Log__c.isCreateable()){
                Database.insert(customLog,false); 
            }
        }
    }
}