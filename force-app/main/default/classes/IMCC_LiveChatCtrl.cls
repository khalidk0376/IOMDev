/**
 * Created/Modified By: Girikon(Aishwarya)
 * Created/LastModifiedDate: [Aishwarya IMCC-1258 24 March 2022],[Aishwarya IMCC-2261 14 Apr 2022]
 * Modified By:  Girikon(Garima Gupta)
 * LastModifiedDate: [Garima IMCC-3625 8th Aug 2022]
 * Test Class:    IMCC_LiveChatCtrl_Test(100%)
 * @description : This class call from the VF page - IMCC_Live_Chat. It is used to fetch Edition List
 *                based on Contact,Account for selection and also fetches the Live Agent Setup details.
**/

public without sharing class IMCC_LiveChatCtrl{
    /** @description Account Id */
    private String accountId;
    
    /** @description Contact Id */
    public String contactId;
    /** @description Contact First Name */
    public String contactFirstName {get;set;}
    /** @description Contact Last Name */
    public String contactLastName  {get;set;}
    /** @description Contact Email */
    public String contactEmail     {get;set;}
    /** @description Current Page URL */
    public String ccURL            {get;set;}
    /** @description Edition Id */
    public String editionId      {get;set;}
    /** @description is Chat Enabled */
    public Boolean isAgentOnline   {get;set;}
    /** @description is Edition Selected Or Not */
    public Boolean isEditionSelected   {get;set;}
    /** @description Support Team Name */
    public String supportTeam      {get;set;}
    /** @description chat Deployment Name */
    public String chatDeployment   {get;set;}
    /** @description Chat Button Id */
    public String buttonID         {get;set;}
    /** @description agent Name */
    public String agentDevName     {get;set;}
    /** @description chat deployment Id */
    public String deploymentId     {get;set;}
    /** @description base LiveAgent Content URL */
    public String baseLiveAgentContentURL {get;set;}
    /** @description base LiveAgent Live URL */
    public String baseLiveAgentURL {get;set;}
    /** @description Support Timings */
    public String supportHours     {get;set;}
    /** @description Support Timings */
    public String defaultMinimizedText     {get;set;}
    /** @description Edition List */
    public List<Edition__c> getEditionList     {get;set;}
    /** @description is Call Destroy Or Not */
    public Boolean isCallDestroy   {get;set;}
    
    /**
    * @description : Constructor For IMCC_LiveChatCtrl Class. It finds the Live Agent Setup details 
      based on Contact,Account and Edition
    */
    public IMCC_LiveChatCtrl(){
        List<Edition__c> listEvent = new List<Edition__c>();
        List<Contact_Edition_Mapping__c> conEdMapLst = new List<Contact_Edition_Mapping__c>();
        Set<Id> editionIds = new Set<Id>();
        getEditionList = new List<Edition__c>();
        contactFirstName = '';
        contactLastName = '';
        contactEmail = '';
        editionId = '';  
        supportTeam = '';
        chatDeployment = '';
        buttonID = '';
        agentDevName = '';
        deploymentId = '';
        isAgentOnline = false;
        supportHours = '';
        defaultMinimizedText = 'Hi how can we help?';
        String eveCodeFromURL ='';
        isCallDestroy = false;

        ccURL = ApexPages.currentPage().getHeaders().get('Referer');

        List<User> u = [SELECT Id, ContactId, Contact.FirstName, Contact.LastName, Contact.Email FROM User WHERE Id=:UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        
        if(!u.isEmpty()){
            contactId = u[0].ContactId;
        }
        
        if(ccURL !=null && ccURL !=''){
            if(ccURL.contains('ErrorDescription')){
                String errorDesc = ccURL.substringAfter('ErrorDescription');
                if(errorDesc.contains('&')){ errorDesc = errorDesc.substringBefore('&'); }
                if(errorDesc.contains('=')){ errorDesc = errorDesc.replace('=', ''); }
                if(errorDesc.startsWith('nu:')){
                    contactEmail = errorDesc.replace('nu:', '');
                    List<Contact> con = [SELECT id,Name,Email FROM Contact WHERE Email =: contactEmail WITH SECURITY_ENFORCED LIMIT 1];
                    contactId = con[0].id;
                }
            }
        }

        if(ccURL !=null && ccURL !=''){
            if(ccURL.contains('edcode')){
                eveCodeFromURL = ccURL.substringAfter('edcode');
                if(eveCodeFromURL.contains('&')){ eveCodeFromURL = eveCodeFromURL.substringBefore('&'); }
                if(eveCodeFromURL.contains('=')){ eveCodeFromURL = eveCodeFromURL.replace('=', ''); }
            }
            else if(ccURL.contains('accId')){
                accountId = ccURL.substringAfter('accId');
                if(eveCodeFromURL.contains('&')){ eveCodeFromURL = eveCodeFromURL.substringBefore('&'); }
                if(accountId.contains('=')){ accountId = accountId.replace('=', ''); }
            }
        }
        
        if(eveCodeFromURL !=''){
            listEvent= [SELECT Id,Business_Hours__c, Live_Agent_Online__c, Customer_Support_Team__c,Customer_Support_Team__r.Business_Hours__c, Customer_Support_Team__r.AgentDevName__c, Customer_Support_Team__r.Button_ID__c, Customer_Support_Team__r.Chat_Deployment__c,Customer_Support_Team__r.SupportTeam__c, Customer_Support_Team__r.Deployment_Id__c, Customer_Support_Team__r.baseLiveAgentContentURL__c, Customer_Support_Team__r.baseLiveAgentURL__c FROM Edition__c WHERE Edition_Code__c =:eveCodeFromURL WITH SECURITY_ENFORCED LIMIT 1];
        }
        else if(String.isNotBlank(accountId)){
            isAgentOnline = true;
            isEditionSelected = false;
            isCallDestroy = true;
            conEdMapLst = [SELECT Id,Account__c,Edition__c,Contact__c FROM Contact_Edition_Mapping__c WHERE Account__c =:accountId and Contact__c =:contactId AND Relationship_Status__c='Active' WITH SECURITY_ENFORCED];
        }
        else if(String.isNotBlank(contactId)){
            isAgentOnline = true;
            isEditionSelected = false;
            isCallDestroy = true;
            conEdMapLst = [SELECT Id,Account__c,Edition__c,Contact__c FROM Contact_Edition_Mapping__c WHERE Contact__c =:contactId AND Relationship_Status__c='Active' WITH SECURITY_ENFORCED];
        }
        else{
            getEditionList = [SELECT Id,Name,Business_Hours__c, Live_Agent_Online__c, Customer_Support_Team__c, Customer_Support_Team__r.Business_Hours__c,Customer_Support_Team__r.AgentDevName__c, Customer_Support_Team__r.Button_ID__c, Customer_Support_Team__r.Chat_Deployment__c,Customer_Support_Team__r.SupportTeam__c, Customer_Support_Team__r.Deployment_Id__c, Customer_Support_Team__r.baseLiveAgentContentURL__c, Customer_Support_Team__r.baseLiveAgentURL__c FROM Edition__c WHERE Live_Agent_Online__c =true AND (Customer_Center_Status__c = 'Active' OR Customer_Center_Status__c = 'In Progress') AND Customer_Support_Team__c != null WITH SECURITY_ENFORCED ORDER BY Name];
            isAgentOnline = true;
            isEditionSelected = false;
            isCallDestroy = true;
        }

        if(!conEdMapLst.isEmpty()){
            for(Contact_Edition_Mapping__c cem : conEdMapLst){
               editionIds.add(cem.Edition__c);
            }
            getEditionList = [SELECT Id,Name,Business_Hours__c, Live_Agent_Online__c, Customer_Support_Team__c, Customer_Support_Team__r.Business_Hours__c,Customer_Support_Team__r.AgentDevName__c, Customer_Support_Team__r.Button_ID__c, Customer_Support_Team__r.Chat_Deployment__c,Customer_Support_Team__r.SupportTeam__c, Customer_Support_Team__r.Deployment_Id__c, Customer_Support_Team__r.baseLiveAgentContentURL__c, Customer_Support_Team__r.baseLiveAgentURL__c FROM Edition__c where Id IN: editionIds AND Live_Agent_Online__c = true AND (Customer_Center_Status__c = 'Active' OR Customer_Center_Status__c = 'In Progress') AND Customer_Support_Team__c != null WITH SECURITY_ENFORCED ORDER BY Name];
         }
         
         if(getEditionList.size() == 1){
            listEvent.addAll(getEditionList);
         }
        
        if(!listEvent.isEmpty()){
            editionId   = listEvent[0].Id;
            isAgentOnline = listEvent[0].Live_Agent_Online__c;
            isEditionSelected = true;
            isCallDestroy = false;
        }
        
        // Get Customer Support Team object fields value
        if(!listEvent.isEmpty() && listEvent[0].Customer_Support_Team__c !=null){
            supportTeam    = listEvent[0].Customer_Support_Team__r.SupportTeam__c;            
            agentDevName   = listEvent[0].Customer_Support_Team__r.AgentDevName__c;
            buttonID       = listEvent[0].Customer_Support_Team__r.Button_ID__c;
            chatDeployment = listEvent[0].Customer_Support_Team__r.Chat_Deployment__c;
            deploymentId   = listEvent[0].Customer_Support_Team__r.Deployment_Id__c;
            baseLiveAgentContentURL   = listEvent[0].Customer_Support_Team__r.baseLiveAgentContentURL__c;
            baseLiveAgentURL   = listEvent[0].Customer_Support_Team__r.baseLiveAgentURL__c;
            supportHours = listEvent[0].Business_Hours__c!=null?listEvent[0].Business_Hours__c:listEvent[0].Customer_Support_Team__r.Business_Hours__c;
        }
        getCurrentUserContact(u);
        System.debug(LoggingLevel.DEBUG, getEditionList);
    }
    
    /**
    * @description : to Get Loggedin User's Contact Detail
    * @param user
    */
    public void getCurrentUserContact(List<User> user)
    {  
        if(!user.isEmpty()){
            contactFirstName = user[0].Contact.FirstName;
            contactLastName = user[0].Contact.LastName;
            contactEmail = user[0].Contact.Email;
        }
        // Get Contact Email when URL contains email Id
        if(ccURL !=null && ccURL !=''){
            if(ccURL.contains('ErrorDescription')){
                String errorDesc = ccURL.substringAfter('ErrorDescription');
                if(errorDesc.contains('&')){ errorDesc = errorDesc.substringBefore('&'); }
                if(errorDesc.contains('=')){ errorDesc = errorDesc.replace('=', ''); }
                if(errorDesc.startsWith('nu:')){
                    contactEmail = errorDesc.replace('nu:', '');
                }
            }
        }
    }

    /**
    * @description : to Get Chat Setting Detail of Selected Editions
    * @return Pagereference
    */
    public Pagereference eventSelected(){
        List<Edition__c> listEvent = [SELECT Id,Business_Hours__c, Live_Agent_Online__c, Customer_Support_Team__c,Customer_Support_Team__r.Business_Hours__c, Customer_Support_Team__r.AgentDevName__c, Customer_Support_Team__r.Button_ID__c, Customer_Support_Team__r.Chat_Deployment__c,Customer_Support_Team__r.SupportTeam__c, Customer_Support_Team__r.Deployment_Id__c, Customer_Support_Team__r.baseLiveAgentContentURL__c, Customer_Support_Team__r.baseLiveAgentURL__c FROM Edition__c WHERE Id=:editionId WITH SECURITY_ENFORCED LIMIT 1];

        if(!listEvent.isEmpty()){
            supportTeam    = listEvent[0].Customer_Support_Team__r.SupportTeam__c;            
            agentDevName   = listEvent[0].Customer_Support_Team__r.AgentDevName__c;
            buttonID       = listEvent[0].Customer_Support_Team__r.Button_ID__c;
            chatDeployment = listEvent[0].Customer_Support_Team__r.Chat_Deployment__c;
            deploymentId   = listEvent[0].Customer_Support_Team__r.Deployment_Id__c;
            baseLiveAgentContentURL   = listEvent[0].Customer_Support_Team__r.baseLiveAgentContentURL__c;
            baseLiveAgentURL   = listEvent[0].Customer_Support_Team__r.baseLiveAgentURL__c;
            supportHours = listEvent[0].Business_Hours__c!=null?listEvent[0].Business_Hours__c:listEvent[0].Customer_Support_Team__r.Business_Hours__c;
        }

        defaultMinimizedText = 'Loading';
        this.isEditionSelected = true;
        return null;
    }
}