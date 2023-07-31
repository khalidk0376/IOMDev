/*
* Created By        :    Girikon(Deepak)
* Created On        :    28/04/2022
* @description      :    Class will test Class For  IMCC_IIRISAuthProvider,IMCC_IIRISRegistrationHandler
*/
@IsTest
public class IMCC_IIRISAuthProvider_Test {
    private static final String REDIRECT_URL = 'https://imcc-servcloud.informamarkets.net/services/authcallback/IIRIS_Auth_Provider';
    private static final String KEY = 'testKey';
    private static final String COMMUNITY_URL = 'https://www.dummy.com';
    private static final String AUTH_URL = 'http://www.dummy.com/authurl';
    private static final String STATE = 'mocktestState';
    private static final String STATE_TO_PROPOGATE  = 'testState';
    private static final String OAUTH_TOKEN  = 'eyJjdXN0b206Y291bnRyeSI6IkluZGlhIiwic3ViIjoiMGRjYjMyMmEtZWM5OS00OTllLWIwZGItMWRhMzA4ZjllOGI5IiwiY29nbml0bzpncm91cHMiOlsiKlwvYXVkaWVuY2VcLyoiXSwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC5ldS13ZXN0LTEuYW1hem9uYXdzLmNvbVwvZXUtd2VzdC0xX2t2RWZ4UnV2RyIsImNvZ25pdG86dXNlcm5hbWUiOiIwZGNiMzIyYS1lYzk5LTQ5OWUtYjBkYi0xZGEzMDhmOWU4YjkiLCJnaXZlbl9uYW1lIjoiZGVlcGFrIiwib3JpZ2luX2p0aSI6IjM3NGJkNDdjLWUxM2EtNGZhNC1hODhhLWFiNTE1YWRmM2QzMyIsImF1ZCI6IjMzOTFsNmZ0bGZqbWJvYjRua2t0ZmhuYXE2IiwiY3VzdG9tOnRlcm1zIjoidHJ1ZSIsImV2ZW50X2lkIjoiNjRmOTI1YzctNDUxZi00YTQ4LTlmOGYtZjlhYTZkZTMwZWMxIiwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE2NTEwNzQyMjEsImV4cCI6MTY1MTA3NzgyMSwiaWF0IjoxNjUxMDc0MjIxLCJmYW1pbHlfbmFtZSI6InNodWtsYSIsImp0aSI6ImRhMjEyMTk0LWE5MWQtNGE2ZS05Yzk2LWVkMGVhOGMzMTlmOSIsImVtYWlsIjoiZGVlcGFrLmMuc2h1a2xhLmdiMUBpbmZvcm1hLmNvbSJ9';
    
    private static final String LOGIN_ID = '0dcb322a-ec99-499e-b0db-1da308f9e8b9';
    private static final String USERNAME = '0dcb322a-ec99-499e-b0db-1da308f9e8b9';
    private static final String FIRST_NAME = 'deepak';
    private static final String LAST_NAME = 'shukla';
    private static final String EMAIL_ADDRESS = 'deepak.c.shukla.gb1@informa.com';
    private static final String LOCALE_NAME = '';
    private static final String FULL_NAME = FIRST_NAME + ' ' + LAST_NAME;
    private static final String PROVIDER = 'IIRIS';

    // in the real world scenario , the key and value would be read from the (custom fields in) custom metadata type record
    private static Map<String,String> setupAuthProviderConfig () {
        Map<String,String> authProviderConfiguration = new Map<String,String>();
        authProviderConfiguration.put('appid__c', KEY);
        authProviderConfiguration.put('Custom_Login_Endpoint__c', AUTH_URL);
        authProviderConfiguration.put('Redirect_Url__c', REDIRECT_URL);
        authProviderConfiguration.put('Community_URL__c', COMMUNITY_URL);
        return authProviderConfiguration;
    }

    @IsTest
    static void testInitiateMethod() {
        Test.startTest();
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        IMCC_IIRISAuthProvider iirisCls = new IMCC_IIRISAuthProvider();
        iirisCls.getCustomMetadataType();
        PageReference expectedUrl =  new PageReference(authProviderConfiguration.get('Custom_Login_Endpoint__c') + '?appid='+ 
                                               authProviderConfiguration.get('appid__c') +'&redirecturl='+ 
                                               authProviderConfiguration.get('Redirect_Url__c') + '&state=' + STATE_TO_PROPOGATE);
        PageReference actualUrl = iirisCls.initiate(authProviderConfiguration, STATE_TO_PROPOGATE);
        System.assertEquals(expectedUrl.getUrl(), actualUrl.getUrl(),'URL is incorrect');
        Test.stopTest();
    }
    
    @IsTest
    static void testHandleCallback() {
        Test.startTest();
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        IMCC_IIRISAuthProvider iirisCls = new IMCC_IIRISAuthProvider();

        Map<String,String> queryParams = new Map<String,String>();
        queryParams.put('code','test.'+OAUTH_TOKEN+'.test');
        queryParams.put('state',STATE_TO_PROPOGATE);
        Auth.AuthProviderCallbackState cbState = new Auth.AuthProviderCallbackState(null,null,queryParams);
        Auth.AuthProviderTokenResponse actualAuthProvResponse = iirisCls.handleCallback(authProviderConfiguration, cbState);
        Auth.AuthProviderTokenResponse expectedAuthProvResponse = new Auth.AuthProviderTokenResponse(PROVIDER, 'test.'+OAUTH_TOKEN+'.test', 'refreshToken', STATE_TO_PROPOGATE);
        
        System.assertEquals(expectedAuthProvResponse.provider, actualAuthProvResponse.provider,'provider mismatch');
        System.assertEquals(expectedAuthProvResponse.oauthToken, actualAuthProvResponse.oauthToken,'oauthToken mismatch');
        System.assertEquals(expectedAuthProvResponse.oauthSecretOrRefreshToken, actualAuthProvResponse.oauthSecretOrRefreshToken,'oauthSecretOrRefreshToken mismatch');
        System.assertEquals(expectedAuthProvResponse.state, actualAuthProvResponse.state,'state mismatch');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetUserInfo() {
        Test.startTest();
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        IMCC_IIRISAuthProvider iirisCls = new IMCC_IIRISAuthProvider();

        Auth.AuthProviderTokenResponse response = new Auth.AuthProviderTokenResponse(PROVIDER, 'test.'+OAUTH_TOKEN+'.test' ,'sampleOauthSecret', STATE);
        Auth.UserData actualUserData = iirisCls.getUserInfo(authProviderConfiguration, response) ;
        
        Map<String,String> provMap = new Map<String,String>();
                    
        Auth.UserData expectedUserData = new Auth.UserData(LOGIN_ID, FIRST_NAME, LAST_NAME, FULL_NAME, EMAIL_ADDRESS,
                        null, USERNAME, LOCALE_NAME, PROVIDER, COMMUNITY_URL, provMap);
        
        System.assertNotEquals(expectedUserData,null,'User Data null');
        System.assertEquals(expectedUserData.firstName, actualUserData.firstName,'firstName mismatch');
        System.assertEquals(expectedUserData.lastName, actualUserData.lastName,'lastName mismatch');
        System.assertEquals(expectedUserData.fullName, actualUserData.fullName,'fullName mismatch');
        System.assertEquals(expectedUserData.email, actualUserData.email,'email mismatch');
        System.assertEquals(expectedUserData.username, actualUserData.username,'username mismatch');
        System.assertEquals(expectedUserData.locale, actualUserData.locale,'locale mismatch');
        System.assertEquals(expectedUserData.provider, actualUserData.provider,'provider mismatch');
        System.assertEquals(expectedUserData.siteLoginUrl, actualUserData.siteLoginUrl,'siteLoginUrl mismatch');
        
        IMCC_IIRISRegistrationHandler regCls = new IMCC_IIRISRegistrationHandler();
        User adminUser = [Select Id, UserRoleId,Email From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id accId;
        System.runAs(adminUser)
        {
            List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
            contactId = contObj[0].Id;
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            update new User(Id=userObj.Id,Email=EMAIL_ADDRESS);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
        }
        
        try{regCls.createUser(null,actualUserData);}catch(Exception ex){}
        try{regCls.updateUser(userObj.Id,null,actualUserData);}catch(Exception ex){}
        expectedUserData.email = 'test@test.com';
        try{
            regCls.createUser(null,expectedUserData);
        }
        catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,ex);
        }
        try{
            regCls.updateUser(null,null,actualUserData);
        }
        catch(Exception ex2){
            System.debug(LoggingLevel.DEBUG,ex2);
        }
        Test.stopTest();
    }
}