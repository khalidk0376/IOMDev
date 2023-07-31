/**
* Created/Modified By    : Girikon(Deepak)
* Created On             : 23-03-2022
* @description           : Custom AuthProviderPluginClass For Login Using IIRIS
* Test Class             : IMCC_IIRISAuthProvider_Test
* Code Coverage          : 100%
* Modified by 
**/
public class IMCC_IIRISAuthProvider extends Auth.AuthProviderPluginClass {
    
    /**
    * @description  returns custom metadata type apiname for external auth provider
    * @return  String
    */
    public String getCustomMetadataType() {
        return 'IIRIS_Auth_Provider__mdt';
    }

    /**
    * @description Method to initiate external auth provider
    * @param  authProviderConfiguration
    * @param  stateToPropagate
    * @return PageReference
    */
    public PageReference initiate(Map<String,String> authProviderConfiguration, String stateToPropagate){
        String redirectUrl = authProviderConfiguration.get('Redirect_Url__c');
        String passPortLogInURL = authProviderConfiguration.get('Custom_Login_Endpoint__c');
        String iirisAppId = authProviderConfiguration.get('appid__c');
        String url = passPortLogInURL + '?appid='+iirisAppId+'&redirecturl='+ redirectUrl + '&state=' + stateToPropagate;
        System.debug(LoggingLevel.debug, 'url====='+url);
        string finalUrl = ''+url;
        return new PageReference(finalUrl);
    }

    /**
    * @description Method to handle callback for external auth provider
    * @param  authProviderConfiguration
    * @param  state
    * @return Auth.AuthProviderTokenResponse
    */
    public Auth.AuthProviderTokenResponse handleCallback(Map<string,string> authProviderConfiguration, Auth.AuthProviderCallbackState state) {
        Map<String,String> queryParams = state.queryParameters;
        System.debug(LoggingLevel.DEBUG, 'queryParams==='+queryParams);
        String strRes = queryParams.get('code');
        System.debug(LoggingLevel.DEBUG, 'strRes==='+strRes);
        String sfdcState = queryParams.get('state');
        System.debug(LoggingLevel.DEBUG, 'state==='+state);
        return new Auth.AuthProviderTokenResponse('IIRIS', strRes, 'refreshToken', sfdcState);
    }

    /**
    * @description Method to get userifo for external auth provider
    * @param  authProviderConfiguration
    * @param  response
    * @return Auth.UserData
    */
    public Auth.UserData getUserInfo(Map<string,string> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {
        String userRes = response.oauthToken;
        List<String> splitUserRes = userRes.split('\\.');
        System.debug(LoggingLevel.DEBUG, 'splitUserRes==='+splitUserRes);
        System.debug(LoggingLevel.DEBUG, 'splitUserRes==='+splitUserRes.size());
        Auth.UserData authUserData;
        if(splitUserRes.size() == 3){
            String userDataBase64 = splitUserRes.get(1).replace('-', '+').replace('_', '/');
            String userData = EncodingUtil.base64Decode(userDataBase64).toString();
            userData = userData.replace('"cognito:', '"cognito');
            userData = userData.replace('"custom:', '"custom');
            userData = userData.replace('"given_name"', '"givenname"');
            userData = userData.replace('"email_verified"', '"emailverified"');
            userData = userData.replace('"origin_jti"', '"originjti"');
            userData = userData.replace('"event_id"', '"eventid"');
            userData = userData.replace('"token_use"', '"tokenuse"');
            userData = userData.replace('"auth_time"', '"authtime"');
            userData = userData.replace('"family_name"', '"familyname"');
            userData = userData.replace('"custombusiness_email"', '"custombusinessemail"');
            System.debug(LoggingLevel.DEBUG, 'userData==='+userData);
            UserDetail ud = (UserDetail)JSON.deserialize(userData, UserDetail.Class);
            System.debug(LoggingLevel.DEBUG, 'ud==='+ud);
            String id = ud.cognitousername;
            String fname = ud.givenname;
            String lname = ud.familyname;
            String flname = fname + ' ' + lname;
            String uname = ud.cognitousername;
            String email = (String.isNotBlank(ud.custombusinessemail)?ud.custombusinessemail:ud.email);
            String locale = '';
            String communityUrl = authProviderConfiguration.get('Community_URL__c');
            Map<String,String> provMap = new Map<String,String>();
            authUserData = new Auth.UserData(id, fname, lname, flname,email,null, uname, locale,'IIRIS', communityUrl, provMap);
        }
        return authUserData;
    }

    private class UserDetail{
        private String sub; 
        private Boolean emailverified;
        private String iss;
        private String givenname;
        private String originjti;
        private String aud;
        private String eventid;
        private String tokenuse;
        private Decimal authtime;
        private Decimal exp;
        private Decimal iat;
        private String familyname;
        private String jti;
        private String email;
        private String cognitousername;
        private String custombusinessemail;
    }
}