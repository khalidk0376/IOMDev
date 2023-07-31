/**
* Created/Modified By    : Girikon(Deepak)
* Created On             : 23-03-2022
* @description           : Auth RegistrationHandle Class For Login Using IIRIS
* Test Class             : IMCC_IIRISAuthProvider_Test
* Code Coverage          : 100%
* Modified by 
**/
public without sharing class IMCC_IIRISRegistrationHandler implements Auth.RegistrationHandler{

    /**
    * @description return existing user if found orherwise return error
    * @param  portalId
    * @param  data
    * @return User
    */
    public User createUser(Id portalId, Auth.UserData data){
        List<User> listUsers = [SELECT Id,username,FederationIdentifier,email,lastName,firstName,alias,languagelocalekey,localesidkey,emailEncodingKey,timeZoneSidKey,profileId,contactId FROM User WHERE ContactId!=null AND IsActive=true AND IsPortalEnabled=True AND FederationIdentifier=:data.email WITH SECURITY_ENFORCED LIMIT 1];
        if(listUsers.isEmpty()){
            throw new Auth.AuthProviderPluginException('nu:'+data.email);
        }
        else{
            System.debug(LoggingLevel.DEBUG, listUsers);
            return listUsers.get(0);
        }
    }

    /**
    * @description update existing user
    * @param  userId
    * @param  portalId
    * @param  data
    */
    public void updateUser(Id userId, Id portalId, Auth.UserData data){
        System.debug(LoggingLevel.DEBUG, data);
        System.debug(LoggingLevel.DEBUG, userId);
    }
}