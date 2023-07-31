/**
* File			: 	IOM_AddressValidation
* Project		: 	Informa Order Management
* Created By	: 	Ansh(Girikon)
* Test Class	:  	IOM_AddressValidation_Test
* Coverage		:  	92%  
* Created Date	: 	8th Feb 2022
* *******************************************************************************************************
* @description : class to fetch address detail from google api
* *******************************************************************************************************
* Last Modified By :
*/

public with sharing class IOM_AddressValidation {


    /**
    * @description : Auto suggestion Web Service 
    * @param searchKey Search text
    * @return String autocomplete json
    */
    @AuraEnabled
    public static string getAddressAutoComplete(String searchKey) {

        String url = IOM_GlobalConstantsData.getValue('IOM_Google_Autocomplete_API').replaceAll('<key>',IOM_GlobalConstantsData.getValue('IOM_Google_Api_Key')).replaceAll('<searchkey>',EncodingUtil.urlEncode(searchKey, 'UTF-8'));

        return getHttp(url);
    }
    
    /**
    * @description Place Details Web Service 
    * @param placeId Unique Place Id
    * @return String address json
    */ 
    @AuraEnabled
    public static string getAddressDetails(String placeId) {

        String url = IOM_GlobalConstantsData.getValue('IOM_Google_Place_API').replaceAll('<key>',IOM_GlobalConstantsData.getValue('IOM_Google_Api_Key')).replaceAll('<placeid>',placeId);

        return getHttp(url);
    }
    
    /**
    * @description Common Utility method for making call out
    * @param url API End Point
    * @return String response
    */    
    private static string getHttp(String url){
        try{            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('GET');
            HttpResponse response = http.send(request);

            return response.getBody();
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());}
    } 


    /**
    * @description Get if by pass account address edit
    * @return boolean is by passed or not
    */ 
    @AuraEnabled
    public static boolean getAllowAccountAddressEdit() {
        IOM_Application_Bypass__c abpProfile = IOM_Application_Bypass__c.getInstance(UserInfo.getProfileId());
        boolean isAllow = false;
        if(abpProfile != null){
            isAllow = abpProfile.Allow_Account_Address_Edit__c;
        }
        if(!isAllow){
            IOM_Application_Bypass__c abpUser = IOM_Application_Bypass__c.getInstance(UserInfo.getUserId());
            if(abpUser != null){
                isAllow = abpUser.Allow_Account_Address_Edit__c;
            }
        }
        return isAllow;
    }

    /**
    * @description Get Current user profile Name
    * @return String Current user profile Name
    */ 
    @AuraEnabled
    public static String getProfileName() {
        String profileName = '';
        if(Schema.sObjectType.profile.isaccessible())
        {
            profile pro = [Select id ,name from profile where id =: UserInfo.getProfileId()];
            profileName = pro.Name;
        }
        return profileName;
    }

    /**
    * @description : get custom metadata record based on Country code (MasterLabel) from Custom MetaData type.    
    * @return : Map<String, IOM_Google_Place_Api_Field_Mapping__mdt>
    **/
    @AuraEnabled(cacheable = true)
    public static Map<String , IOM_Google_Place_Api_Field_Mapping__mdt> getGoogleApiMetaData(){
        Map<String , IOM_Google_Place_Api_Field_Mapping__mdt> mapGoogleApi = new Map<String , IOM_Google_Place_Api_Field_Mapping__mdt>();
        List<IOM_Google_Place_Api_Field_Mapping__mdt> lstGoogleApiData = [SELECT Id,MasterLabel, QualifiedApiName, IOM_Country__c, IOM_State__c, IOM_City__c, IOM_District__c, IOM_Postal_Code__c FROM IOM_Google_Place_Api_Field_Mapping__mdt];
        for(IOM_Google_Place_Api_Field_Mapping__mdt fieldMap : lstGoogleApiData){
            mapGoogleApi.put(fieldMap.MasterLabel , fieldMap);
        }
        return  mapGoogleApi;
    }

}