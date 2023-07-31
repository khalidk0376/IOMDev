/**
* File         :   IOM_ConnectionCallbackCtrl 
* Project      :   Order & Billing Plateform [IOM-519]
* Created Date :   19th Jan 2022
* Created By   :   Girikon(Ashish)
* Test Class   :   IOM_ConnectionCallbackCtrl_Test (94%)
* ******************************************************************************************************
 @description : Apex to Connect with IOM & get Access or Refresh Tokens 
*******************************************************************************************************
* Modification log :
* 1. 
*/
public with sharing class IOM_ConnectionCallbackCtrl 
{   
    /***** Final Variables *****/    
    private static final String IOM_CLIENT_ID_META_NAME = 'IOM_ClientId';
    private static final String IOM_CLIENT_SECRET_META_NAME = 'IOM_ClientSecret';
    private static final String IOM_LIGHTNING_OUT_URL_META_NAME = 'IOM_Lightning_Redirect_URL';
    @Testvisible private static String IOM_REFRESH_TOKEN_FILE_NAME = 'IOM_Refresh_Token_Details';
    @Testvisible private static final String IOM_FOLDER_NAME = 'IOM Details';

    /***** Public Varables ****/
    public string authId;
	public string fullAccessToken;
    public string instanceURL;
    
    /**
    * @description : sessionId/AccessToken for IOM 
    **/
    public string  sessionId {get;set;}
    /**
    * @description : IOM Opportunity Number
    **/
    public string  iomrecordNo {get;set;}
    /**
    * @description : Component Code
    **/
    public string  compCode {get;set;}
    /**
    * @description : IOM Lighting Out redirect URL
    **/    
    public string  iomRedirectURL {get;set;}
    /**
    * @description : Show Lightning Out Component 
    **/
    public Boolean  showCmp {get;set;}
    /**
    * @description : Show Lightning Out Component 
    **/
    public Boolean  showError {get;set;}
    

    /**
    * @description : Default Constructor
    **/
    public IOM_ConnectionCallbackCtrl() 
    {        
        if(ApexPages.currentPage() != null)
        {
            authId = ApexPages.currentPage().getParameters().get('code');            
            iomrecordNo = ApexPages.currentPage().getParameters().get('iomrecordNo');
            compCode = ApexPages.currentPage().getParameters().get('compCode');
        }
        iomRedirectURL = IOM_GlobalConstantsData.getValue(IOM_LIGHTNING_OUT_URL_META_NAME);        
        showCmp = false; 
        showError = false;
    }

    /**
    * @description : This Initial methord on Page load     
    * @return PageReference
    **/
    public Pagereference initAction()
    {
        Pagereference pg;
        if(String.isNotBlank(authId))
        {
            pg = getFirstAccesstoken(authId);
        }else{
            pg = getRefreshTokenfromSystem();
            showCmp = true;
        }
        return pg;
    }

    /**
    * @description : This method is to get IOM AccessToken from Refresh token using Document
    * @return PageReference
    **/
    public Pagereference getRefreshTokenfromSystem()
    {
        
        List<Document> listDocument = new List<Document>([Select ID,Body from Document where DeveloperName=: IOM_REFRESH_TOKEN_FILE_NAME limit 1]);

        if(!listDocument.isEmpty())
        {
            sessionId = getAccessToken(listDocument.get(0).Body.toString());
        }else{// Error
            System.debug(logginglevel.DEBUG,'IOM Refresh Token file not found !');
        }  
        return null;
    }
    
    public void revokeToken() {
        HttpRequest req1 = new HttpRequest();
        req1.setMethod('POST');
        //req1.setHeader('Accept', 'application/json');
        req1.setHeader('Content-type', 'application/x-www-form-urlencoded');
        system.debug('fullAccessToken=='+fullAccessToken);
        req1.setBody('token='+fullAccessToken);
        //req1.setHeader('Authorization','Bearer '+sessionId);
        
        // web server flow request
        req1.setEndpoint(instanceURL+'/services/oauth2/revoke');
        Http h = new Http();
        HttpResponse httpResponse = h.send(req1);
        System.debug(httpResponse.getBody());
    }

    /************* Other Methods **********/
    /**
    * @description : This method is to get IOM AccessToken from Refresh token 
    * @param refreshToken refresh Access Token value
    * @return string new Access token
    **/
    private string getAccessToken(String refreshToken) 
    {    
        String clientId = IOM_GlobalConstantsData.getValue(IOM_CLIENT_ID_META_NAME);
        String clientsecret = IOM_GlobalConstantsData.getValue(IOM_CLIENT_SECRET_META_NAME);       
        String urlPrefix = getLoginURL();

        String reqbody = 'client_id='+clientId+'&client_secret='+clientsecret+'&grant_type=refresh_token&refresh_token='+refreshToken;

        HttpRequest req1 = new HttpRequest();
        req1.setHeader('Accept', 'application/json');
        req1.setHeader('Content-type', 'application/x-www-form-urlencoded');
        System.debug(logginglevel.DEBUG,+urlPrefix+' - BODY : '+ reqbody);
        req1.setBody(reqbody);
        req1.setMethod('POST');
        
        // web server flow request
        req1.setEndpoint(URLPrefix+'/services/oauth2/token');
        String response = '';
        jsonWrapper jsondatawrapper=new jsonWrapper();
        
        try{
            Http h = new Http();
            HttpResponse httpResponse = h.send(req1);
            System.debug(logginglevel.DEBUG,'Body - ' +httpResponse.getBody());
            if (httpResponse.getStatusCode() == 200 ) 
            {  
                response = JSON.serializePretty( JSON.deserializeUntyped(httpResponse.getBody()));  
                jsondatawrapper = (jsonWrapper)JSON.deserialize(response,jsonWrapper.class);
            } else {  
                System.debug(logginglevel.DEBUG,' httpResponse ' + httpResponse.getBody() );  
                throw new CalloutException( httpResponse.getBody() );  
            }  
        } catch( System.Exception e) {  
            System.debug(logginglevel.DEBUG,'ERROR: '+ e);  
            throw e;  
        } 
        fullAccessToken = String.valueof(jsondatawrapper.access_token);
        instanceURL = jsondatawrapper.instance_url;
        return jsondatawrapper.access_token.SubString(15);
    }
    /**
    * @description : This method is to get IOM AccessToken & save in Documents
    * @param authId authKey    
    **/
    private Pagereference getFirstAccesstoken (string authId){
      
        String clientId = IOM_GlobalConstantsData.getValue(IOM_CLIENT_ID_META_NAME);
        String clientsecret = IOM_GlobalConstantsData.getValue(IOM_CLIENT_SECRET_META_NAME); 
        string redirectionurl = URL.getOrgDomainUrl().toExternalForm()+'/apex/IOMConnectionCallback';
        string authorizationCode = EncodingUtil.urlDecode(authId,'UTF-8.');
        String urlPrefix = getLoginURL();

        String reqbody ='client_id='+clientId+'&client_secret='+clientsecret+'&grant_type=authorization_code&code='+authorizationCode+'&redirect_uri='+redirectionurl;

        System.debug(logginglevel.DEBUG,urlPrefix+'- BODY : '+ reqbody);
        HttpRequest req1 = new HttpRequest();
        req1.setHeader('Content-type', 'application/x-www-form-urlencoded');
        req1.setBody(reqbody);
        req1.setMethod('POST');
        req1.setEndpoint(urlPrefix+'/services/oauth2/token');
        Http h = new Http();
        HttpResponse httpResponse = h.send(req1);
        System.debug(logginglevel.DEBUG,'authorization_code RES ' + httpResponse.getStatusCode());
        System.debug(logginglevel.DEBUG,'Body - ' +httpResponse.getBody());
        jsonWrapper jsonDatawrapper=new jsonWrapper();
        if (httpResponse.getStatusCode() == 200 ) { 
            Jsondatawrapper = (jsonWrapper)JSON.deserialize(httpResponse.getBody(),jsonWrapper.class);
			
            // System.debug('F '+IOM_FOLDER_NAME+' d '+IOM_REFRESH_TOKEN_FILE_NAME);
            Document document = new Document();
            document.Body = Blob.valueOf(jsonDatawrapper.refresh_token);
            document.ContentType = 'text/plain';
            document.DeveloperName = IOM_REFRESH_TOKEN_FILE_NAME;
            document.IsPublic = true;
            document.Name = 'IOM Refresh Token Detail';
            document.FolderId = [select id from folder where name =: IOM_FOLDER_NAME].id;
        
            List<Document> listDocument = new List<Document>([Select ID,Body from Document where DeveloperName=: IOM_REFRESH_TOKEN_FILE_NAME limit 1]);

            if(!listDocument.isEmpty())
            {
                document.Id = listDocument.get(0).Id;
            }
            upsert document;
        }else{ 
            System.debug(logginglevel.DEBUG,' httpResponse ' + httpResponse.getBody() );  
            throw new CalloutException( httpResponse.getBody() );}
        // system.debug(JSON.serializePretty( JSON.deserializeUntyped(httpResponse.getBody()) ));
        return new PageReference('/lightning/n/IOM');
    }
	/**
    * @description : This method is to get Login Url
    * @return Login URL   
    **/
    private string getLoginURL()
    {
        Organization org = [select IsSandbox from Organization limit 1];
        return org.IsSandbox ? 'https://test.salesforce.com':'https://login.salesforce.com';
    }
    /**
    * @description : This method is to validate Refresh Token file before Callout
    * @return validation
    **/
    @AuraEnabled
    public static Boolean isReadyForIOMCallout()
    {
        List<Document> listDocument = new List<Document>([Select ID,Body from Document where DeveloperName=: IOM_REFRESH_TOKEN_FILE_NAME limit 1]);
        return !listDocument.isEmpty();
    }

    /**
    * @description : This method is to validate IOM Folder before Callout
    * @return validation
    **/
    @AuraEnabled
    public static Boolean hasIOMFolder()
    {
        List<Folder> listFolder = new List<Folder>([select id from folder where name =: IOM_FOLDER_NAME limit 1]);
        return !listFolder.isEmpty();
    }
    /**
    * @description : This method is to validate IOM Folder before Callout
    * @return validation
    **/
    @AuraEnabled
    public static string getAuthenticationURL()
    {
        String clientId = IOM_GlobalConstantsData.getValue(IOM_CLIENT_ID_META_NAME);
        string redirectionurl = URL.getOrgDomainUrl().toExternalForm()+'/apex/IOMConnectionCallback';
        string authURL = IOM_GlobalConstantsData.getValue(IOM_LIGHTNING_OUT_URL_META_NAME)+'/services/oauth2/authorize?client_id='+clientId+'&response_type=code&scope=full+refresh_token&redirect_uri='+redirectionurl;
        return authURL;
    }
    /**
    * @description : This JSON Wrapeer class
    **/
    public class JsonWrapper
    {      
        public string access_token ;
        public string refresh_token;
        public string instance_url ; 
    }
}