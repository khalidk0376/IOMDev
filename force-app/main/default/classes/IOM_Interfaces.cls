/**
* File         :   IOM_Interfaces 
* Project      :   IOM
* Created Date :   20 Nov 2022
* Created By   :   Girikon(Ashish)
* Test Class   :   IOM_SendForOrder_Test
* ******************************************************************************************************
@description :  An interface that overrides the Default IOM package functionality
*******************************************************************************************************
* Modification log : 
* 1. 
*/
public with sharing class IOM_Interfaces
{    
    /**
    * @description - Override IOM_SendForOrderUtils functionality
    */
    public interface SendForOrderoverride {

        /**
        * @description  This method is used for genrate Dynamic Payload for IOM
        * @param  opportunityId  Opportunity Id
        * @param  payloadMapMap<string,object>  - JSON in OBject 
        * @return Map<string,object> - Final payload Object
        */
        Map<string,object> overridePayloadJSON(String oppId,Map<string,object> payloadMap);


        /**
        * @description  This method is used for genrate Dynamic Payload for IOM
        * @param  payloadObjectNodeGroupMap - label Map
        * @return Map<string,string> - lables map
        */
        Map<string,string> overrideGroupNodeLabel(Map<string,string> payloadObjectNodeGroupMap);
    }
}