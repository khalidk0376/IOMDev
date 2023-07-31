/**
* Created/Modified By: Girikon(Garima)
* Created On:          6/9/2021
* @description  : This class provides following functionalities:
*                      If community url is having event code then display event data on login page i.e. event name & log
*                      Allow login to valid user (with or without event code) else show proper error message
*                      Allow valid user to put the request for new password.
* Methods:             GetUserData, getEventCode, login 
* Apex Class:          IMCC_UserLoginCtrl 
* Apex Test Class:     IMCC_UserLoginCtrl_Test (92%)
**/

public without sharing class IMCC_UserLoginCtrl{
    /**@description username */
    public string username {get;set;}
    /**@description password */
    public string password {get;set;}
    /**@description errMsg */
    public string errMsg{get;set;}
    /**@description username */
    public string successMsg{get;set;}
    
    /**@description event */
    public Edition__c event{get;set;}
    /**@description eventSet */
    public Event_Setting__c eventSet{get;set;}
    /**@description editionWeb */
    public List<Edition_Websites__c> editionWeb{get;set;}
    /**@description eventEditionCode */
    public String eventEditionCode{get;set;}
    /**@description brandingColor */
    public String brandingColor{get;set;}  
    /**@description editionDescription */
    public String editionDescription{get;set;} 
    /**@description showHours */
    public String showHours{get;set;}
    /**@description backgroundColor */
    public String backgroundColor{get;set;}
    /**@description textColor */
    public String textColor{get;set;}
    /**@description imageURL */
    public String imageURL{get;set;}  
    /**@description facebook */
    public String facebook{get;set;}
    /**@description twitter */
    public String twitter{get;set;}
    /**@description youtube */
    public String youtube{get;set;}
    /**@description linkedin */
    public String linkedin{get;set;}
     
    
    /**@description log */
    public String log{get;set;}

    /**
    * @description : Get site url
    * @return : SiteURL
    */
    public String getSiteURL() 
    {
        return System.URL.getSalesforceBaseURL().toExternalForm();   
    }
    
    /**
    * @description : get Current Org ID
    * @return :  Org ID
    */
    public String getOrgId() 
    {
        return UserInfo.getOrganizationId();
    }
    
    /**
    * @description : Class constructor
    */
    public IMCC_UserLoginCtrl()
    {  
        log =  JSON.serialize(ApexPages.currentPage().getparameters());
        successMsg = '';        
        try
        {     
            string errorCode= apexpages.currentpage().getparameters().get('er');
            System.Debug(LoggingLevel.DEBUG,'ErrorCode: '+errorCode);
            
            //Display proper error message as per errorcode
            if(string.isNotBlank(errorCode))
            {
                if(ErrorCode.equalsIgnoreCase('iunp'))
                {
                    errMsg='Invalid Username/Password';
                }
                else if(ErrorCode.equalsIgnoreCase('iufte'))
                {
                    errMsg='Invalid user for this event.';
                }
                else if(ErrorCode.equalsIgnoreCase('iu'))
                {
                    errMsg='Invalid Username/Password';            
                }
            }
            
            //Get event code from to get event details to display on login page
            string eventCode= apexpages.currentpage().getparameters().get('edcode');
            if(eventCode !=null)
            {
                if(string.isBlank(EventCode))
                {
                    eventCode = getEventCode();
                }
                
                if(string.isNotBlank(eventCode))
                {
                    List<Edition__c> eves;
                    if(Edition__c.SObjectType.getDescribe().isAccessible()){
                        eves = [SELECT id,Name,End_Date__c,Edition_Image_URL__c,Edition_Description__c,Background_Colour__c,Text_Colour__c,Show_Hours__c,FaceBook__c,LinkedIn__c,Twitter__c,YouTube__c FROM Edition__c WHERE Edition_Code__c =:eventCode AND Edition_Status__c='Confirmed'];
                    }
                    
                    if(eves!=null && eves.size()>0)
                    {
                        event=eves[0];
                        if(Edition_Websites__c.SObjectType.getDescribe().isAccessible()){
                            editionWeb = [Select Edition__c,Website_Label__c,Website_Link__c,Sequence__c from Edition_Websites__c where Edition__c =: event.Id Order By Sequence__c asc];
                        }
                        backgroundColor= event.Background_Colour__c;
                        textColor= event.Text_Colour__c;
                        editionDescription = event.Edition_Description__c;
                        showHours = event.Show_Hours__c;
                        facebook = event.FaceBook__c;
                        twitter = event.Twitter__c;
                        youtube = event.YouTube__c;
                        linkedin = event.LinkedIn__c; 
                    }
                    else{
                        errMsg='Either invalid event code OR event has been ended.';
                    }
                }
            }
            System.debug(LoggingLevel.DEBUG,'errMsg: '+errMsg);
        }
        catch(Exception ex)
        {
            System.Debug(LoggingLevel.DEBUG,'Error : '+ex.getMessage());
            HandleAllCustomException.logException(ex,'Edition__c', 'After Insert');   
        }
    } 

    /**
    * @description : Method to get user data & redirect user to respective page
    * @param eventCode
    * @return PageReference
    */
    public PageReference getUserData(string eventCode)
    {
        PageReference pageRef;
        try{
            username = username.trim();
            System.debug(LoggingLevel.DEBUG,'username: '+username);
            
            List<User> usr = [SELECT Id,ContactId FROM User WHERE Username=:username AND IsActive=True];
            System.debug(LoggingLevel.DEBUG,'User: '+usr);
            if(!usr.isEmpty() && usr[0].ContactId!=null){
                string strQuery='select id,Edition__r.Edition_Code__c from Contact_Edition_Mapping__c where Contact__c =\''+ String.escapeSingleQuotes(usr[0].ContactId)+'\'';
                strQuery +=' AND Edition__r.Edition_Code__c != null';
                if(string.isNotBlank(EventCode)){
                    strQuery +=' AND Edition__r.Edition_Code__c =\''+String.escapeSingleQuotes(EventCode)+'\'';
                }    
                List<Contact_Edition_Mapping__c> conEdMap = Database.query(strQuery);
                
                if(conEdMap!=null && conEdMap.size()>0){
                    String u = (eventCode!=null && eventCode!='') ? 'edcode='+eventCode:'';                    
                    String communityURL ='/s/accountselection?'+u;
                    pageRef = Site.login(username, password, communityURL);
                    if(pageRef == null){        
                        u = (eventCode!=null && eventCode!='') ? '&edcode='+eventCode:'';             
                        pageRef=new PageReference('/apex/IMCC_UserLogin?er=iunp'+u);
                        pageRef.setRedirect(true);
                    }
                }
                else if(string.isNotBlank(EventCode)){
                    pageRef=new PageReference('/apex/IMCC_UserLogin?er=iufte&edcode='+EventCode);
                    pageRef.setRedirect(true);
                }
            }
            else{
                pageRef=new PageReference('/apex/IMCC_UserLogin?&er=iu'+(String.isNotBlank(eventCode)?('&edcode='+eventCode):''));
                pageRef.setRedirect(true);
            }
        }
        catch(exception e){
            HandleAllCustomException.logException(e,'Account', 'After Insert');
        }
        return pageRef;
    }
    
    /**
    * @description : Get event code from encoded url
    * @return : EventCode
    */
    public string getEventCode()
    {
        string eventCode = '';
        string url='';
        try{
            string headerdata= ApexPages.currentPage().getHeaders().get('Host');
            string urlvalue=Apexpages.currentPage().getUrl(); 
            string currentURL ='https://' + headerdata+ urlvalue;
            String encoded = EncodingUtil.urlDecode(currentURL, 'UTF-8');
            string[] strArr=encoded.split('\\?');
            
            if(strArr!=null && strArr.size()>0)
            {
                URL=strArr[1];
                if(strArr.size()>2)
                {
                    EventCode=strArr[2];
                }                    
                string[] strURLArr=URL.split('=');
                if(strURLArr!=null && strURLArr.size()>1)
                {
                    URL=strURLArr[1];
                    URL=URL.remove('\'');
                }
                string[] strparamArr;
                if(String.IsNotBlank(EventCode))
                {
                    strparamArr=EventCode.split('=');
                }                
                if(strparamArr!=null && strparamArr.size()>0)
                {
                    EventCode=strparamArr[1];
                }
            }
        }
        catch(exception e){
            HandleAllCustomException.logException(e,'Account', 'After Insert');
        }
        return EventCode;
    }

    /**
    * @description : Login functionality with or without event code
    * @return : pageRef
    */
    public PageReference login(){
        PageReference pageRef;
        string eventCode= apexpages.currentpage().getparameters().get('edcode');
        if(EventCode!=null && string.isBlank(EventCode)){
            EventCode = getEventCode();
        }
        pageRef=getUserData(EventCode);
        
        return pageRef;
    }
    
    /**
    * @description : Show forgot password panel
    * @return : pageRef
    */
    public PageReference forgotPassword(){
        errMsg='';
        PageReference pageRef = new PageReference('/apex/IMCC_ForgotPassword');
        pageRef.setRedirect(true);
        return pageRef;
    }
    /* End*/
    
    /**
    * @description : Back to login page
    * @return : pageRef
    */
    public PageReference backToSignIn(){
        errMsg='';        
        PageReference pageRef = new PageReference('/apex/IMCC_UserLogin');
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    /**
    * @description : Processing for reset password
    * @return : pageRef
    */
    public PageReference resetPassword(){
        successMsg='';
        if(username != null && username != ''){
            username = username.trim();
            List<user> listbs = [SELECT Username,Email FROM user WHERE Username=:username LIMIT 1];
            if(!listbs.isEmpty()){
                string str = listbs[0].Email;
                
                boolean success = Site.forgotPassword(username);
                if(success){
                    successMsg = 'Password reset link has been sent to '+ str;
                    username = '';
                    errMsg = '';
                }
                else{
                    errMsg = 'Something went wrong, Please try again later.';
                }
            } 
            else{
                System.debug(LoggingLevel.DEBUG,'No record');
                errMsg= 'Invalid user name';
            }
        }
        else{
            System.debug(LoggingLevel.DEBUG,'Outside username');
            errMsg = 'Please enter user name!' ;
        }
        return null;
    }

    /**
    * @description : Login Using IIRIS External Auth. Provider
    * @return : pageRef
    */
    public PageReference iirislogin(){
        PageReference pageRef;
        string eventCode = apexpages.currentpage().getparameters().get('edcode');
        if(EventCode!=null && string.isBlank(EventCode)){
            EventCode = getEventCode();
        }
        String u = ((eventCode!=null && eventCode!='')?'edcode='+eventCode:'');                    
        String startURL ='/s?'+u;
        String startURL2 = apexpages.currentpage().getparameters().get('startURL');
        if(String.isNotBlank(startURL2)){startURL = EncodingUtil.urlDecode(startURL2,'UTF-8');}
        Id networkId = Network.getNetworkId();
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(networkId,null);
        List<AuthProvider> authPrvs = authConfig.getAuthProviders();
        if(!authPrvs.isEmpty()){
            for(AuthProvider provider : authPrvs){
                if(provider.DeveloperName == Label.IMCC_IIRIS_Auth_Provider){
                    System.debug(LoggingLevel.Debug, 'sso===' + getSiteURL()+'/IMCC/services/auth/sso/'+provider.DeveloperName+'?startURL='+ EncodingUtil.urlEncode(startUrl,'UTF-8'));
                    pageRef = new PageReference(getSiteURL()+'/IMCC/services/auth/sso/'+provider.DeveloperName+'?startURL='+ EncodingUtil.urlEncode(startUrl,'UTF-8'));
                }
            }
        }
        return pageRef;
    }
    /* End*/
}