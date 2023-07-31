/**
* Created By       :   Girikon(Arushi)
* Created On       :   19/01/2022
* Modified By      :   Girikon(Arushi)
* Modified On      :   19/01/2022
* @description     :   This class use to get Contact's User Detail to Login to Community
* Methods          :   getUserLoginData()
* Apex Class       :   IMCC_LoginAsUser 
* Apex Test Class  :   IMCC_LoginAsUser_Test(100%)
**/
public with sharing class IMCC_LoginAsUser {

    /**
    * @description  This method is used to get Contact's User Detail to Login to Community
    * @param  contactId Contact Id
    * @return  Map<String,String>
    */
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getUserLoginData(String contactId){
        Map<String,String> contactUserData = new Map<String,String>();
        try{
            if(contactId != null){
            List<User> objUsr = [SELECT Id FROM User WHERE ContactId=:contactId AND IsActive=true WITH SECURITY_ENFORCED];
            contactUserData.put('UserId', (objUsr.isEmpty()?'':objUsr.get(0).Id));
            String communityName = 'IMCustomerCenter';
            List<Network> networks = [SELECT Id FROM Network WHERE Name=:communityName WITH SECURITY_ENFORCED];
            contactUserData.put('NetworkId', (networks.isEmpty()?'':String.valueOf(networks.get(0).Id).subString(0,15)));
            contactUserData.put('OrgId', UserInfo.getOrganizationId().subString(0,15));
            contactUserData.put('BaseURL', System.URL.getSalesforceBaseUrl().toExternalForm());
            }
            else{
                throw new AuraHandledException('Message= Contact is null');
            }
        }
        catch(Exception e) {
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';          
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }
        return contactUserData;
    }
}