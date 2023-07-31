/**
* Created/Modified By         : Girikon(Garima)
* Created On/Last Modified By : 1/11/2021, [Aishwarya IMCC-131 24 Nov 2021]
* @description                : This class is used to fetch forms permission and Contact Edition Mapping and also to update some fields on Form Data Object
* Methods                     : customerFormListWrpData,updateFormData
* Modified By                 :  IBM(Srikanth)
* Modified On                 :  20 Sept, 2022
* @description                :  For all Auraenabled methods added try-catch block and threw Aura exception.
* Apex Class                  : IMCC_FormsCtrl 
* Apex Test Class             : IMCC_FormsCtrl_Test(91%)

**/
public without sharing class IMCC_FormsCtrl {
    /**
    * @description fetch forms permissions and Contact Edition Mapping
    * @param  eventCode
    * @param  accountId
    * @param  tabId
    * @return Map<String,Object>
    */
    @AuraEnabled
    public static Map<String,Object> customerFormListWrpData(String eventCode, String accountId, String tabId){
        Map<Id,Form_Data__c> mapFormData = new Map<Id,Form_Data__c>();
        Map<Id,List<Form_Response_Entry__c>> mapEntries = new Map<Id,List<Form_Response_Entry__c>>();
        List<Purchase_Data__c> listPD = new List<Purchase_Data__c>();
        String stanTabType = '';
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
        String conEdMApId;
        List<Contact_Edition_Mapping__c> conEdMapLst = (List<Contact_Edition_Mapping__c>)mapCEMDetails.get('cemList');
        try{
            if(!conEdMapLst.isEmpty()){
                if(String.isNotBlank(conEdMapLst.get(0).Primary_Contact_Edition_Mapping__c)){
                    conEdMApId = conEdMapLst.get(0).Primary_Contact_Edition_Mapping__c;
                }
                else{
                    conEdMApId = conEdMapLst.get(0).Id;
                }
            }

            //conEdMapLst = [SELECT Id,Name,Access_Type__c,Account__c,Account__r.Name,CC_Status__c,Contact__c,Edition__c,Relationship_Status__c,isSecondary__c,Edition__r.Form_Setting__c from Contact_Edition_Mapping__c where Contact__c =: u.ContactId And Account__c =: accountId And Relationship_Status__c = 'Active' And Edition__r.Edition_Code__c =: eventCode WITH SECURITY_ENFORCED];
            
            if(!conEdMapLst.isEmpty()){
                listPD = FormPreviewController.getRelatedBooths(conEdMApId);

                List<Event_Tabs__c> evntTabLst = [SELECT id,Name,Standard_Tab_Type__c,Tab_Code__c,Tab_Type__c FROM Event_Tabs__c WHERE Tab_Code__c =: tabId WITH SECURITY_ENFORCED];
                
                if(!evntTabLst.isEmpty()){
                    stanTabType = evntTabLst[0].Standard_Tab_Type__c;
                }
                
                if(!evntTabLst.isEmpty()){
                    String featureCategory = (evntTabLst[0].Standard_Tab_Type__c == 'Manuals'?'Manual':'Form');
                    
                    Map<Id,Forms_Permission__c> formPermIds = new Map<Id,Forms_Permission__c>([SELECT Id FROM Forms_Permission__c WHERE Form_Allocation__r.Feature_Category__c=:featureCategory and Tab_User_Type__r.User_Type__c=:conEdMapLst[0].Access_Type__c and Is_Active__c = true and Form_Allocation__r.Form_Status__c = 'Visible' AND Form_Allocation__r.Form_Setting__c=:conEdMapLst[0].Edition__r.Form_Setting__c WITH SECURITY_ENFORCED]);

                    mapFormData = new Map<Id,Form_Data__c>([SELECT Id,Forms_Permission__r.Form_Allocation__r.Name,Forms_Permission__r.Form_Allocation__r.Form__r.Category__c,Forms_Permission__r.Form_Allocation__r.Form_Type__c,Forms_Permission__r.Form_Allocation__r.Form_Category__c,Forms_Permission__r.Form_Allocation__r.Form_Provider__c,Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c,Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c,Forms_Permission__r.Form_Allocation__r.Form__c,Is_Viewed__c,Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Status1__c,Not_Applicable__c,Forms_Permission__r.Form_Allocation__r.Form_Url__c,Forms_Permission__r.Form_Allocation__r.Form_Heading__c,Forms_Permission__r.Form_Allocation__r.Form_Entry__c,Forms_Permission__r.Form_Allocation__r.CountMultiSubmission__c,Is_Agreed__c,Approved_Responses__c,Rejected_Responses__c,Total_Responses__c,Submitted_Responses__c,Forms_Permission__r.Form_Allocation__r.Entry_Limit__c,Forms_Permission__r.Form_Allocation__r.Feature_Category__c,Forms_Permission__r.Form_Allocation__r.Booth_Product_Types__c,Purchase_Data__c,Overall_Status__c FROM Form_Data__c WHERE Contact_Edition_Mapping__c =:conEdMApId AND Forms_Permission__c IN:formPermIds.keySet() AND Is_Active__c=true WITH SECURITY_ENFORCED ORDER BY Forms_Permission__r.Form_Allocation__r.Name]);

                    List<Form_Response_Entry__c> listEntries = [SELECT Id,Name,Content_Version__c,File_Name__c,Approval_Status__c,Contact_Edition_Mapping__c,Current_Page__c,Current_Page_No__c,Entry_Number__c,Form_Data__c,Form_Unlock__c,Girikon_Form__c,Purchase_Data__c,Rejection_Reason__c,Status__c,Total_Pages__c,User__c,User_Type1__c,Purchase_Data__r.Booth_Number__c,Version__c FROM Form_Response_Entry__c WHERE Form_Data__c IN:mapFormData.keySet() WITH SECURITY_ENFORCED];
                    for(Form_Response_Entry__c entry : listEntries){
                        List<Form_Response_Entry__c> listEntries2 = (mapEntries.containsKey(entry.Form_Data__c)?mapEntries.get(entry.Form_Data__c):(new List<Form_Response_Entry__c>()));
                        listEntries2.add(entry);
                        mapEntries.put(entry.Form_Data__c,listEntries2);
                    }
                }
            }
        }
        catch (Exception e) {
            //System.debug(LoggingLevel.DEBUG, 'Exception hit ' +e.getMessage());
            //HandleAllCustomException.logException(e,'Forms_Permission__c', 'After Insert');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        } 
        return new Map<String,Object>{
            'listFormData'=>mapFormData.values(),
            'mapEntries'=>mapEntries,
            'listPD'=>listPD,
            'conEdMapId'=>conEdMApId,
            'contactId'=>(conEdMapLst.size()>0?conEdMapLst[0].Contact__c:null),
            'isCEMSecondary'=>(conEdMapLst.size()>0?conEdMapLst[0].isSecondary__c:false),
            'stanTabType'=>stanTabType,
            'contactData'=>contactData(eventCode,accountId).listContacts
        };
    }
    
    /**
    * @description Update FormData Is Viewed Field
    * @param  formType
    * @param  formId
    * @param  isViewed
    * @param  formTempId
    * @param  conEdMapId
    * @return string
    */
    @AuraEnabled
    public static string updateFormData(string formType, id formId, string isViewed, string formTempId, string conEdMapId)
    {
        string message = '';
        if(string.isNotBlank(formType) && (formType == 'Link' || formType == 'PDF')){
            try{
                Form_Data__c formData = new Form_Data__c();
                formData.id = formId;
                formData.Is_Viewed__c = true;
                if(Schema.sObjectType.Form_Data__c.isUpdateable())
                {
                    update formData;
                }
                FBUtils.saveFormStatus(new Map<String,String> {
                    'status' => 'Viewed',
                    'conEdMapId' => conEdMapId,
                    'formDataId' => formId,
                    'entryId' => '',
                    'pageNo' => '0',
                    'totalPages' => '0',
                    'boothId' => ''
                });
                message = 'success';
            }
            catch (DmlException e){message = e.getMessage();}
        }
        return message;
    }

    /**
    * @description create form entry for Link and PDF
    * @param  formType    
    * @param  formId    
    * @param  conEdMapId    
    * @param  entryId    
    * @param  status    
    * @param  pdId      
    * @return Form_Response_Entry__c
    */
    @AuraEnabled
    public static Form_Response_Entry__c updateFormDataNew(String formType, Id formId, String conEdMapId, String entryId, String status, String pdId)
    {
        Form_Response_Entry__c fres = null;
        try{
            if(string.isNotBlank(formType) && (formType == 'Link' || formType == 'PDF')){
                //try{
                    fres = FBUtils.saveFormStatus(new Map<String,String> {
                        'status' => status,
                        'conEdMapId' => conEdMapId,
                        'formDataId' => formId,
                        'entryId' => entryId,
                        'pageNo' => '0',
                        'totalPages' => '0',
                        'boothId' => pdId
                    });
                //}
                //catch (DmlException e){fres = null;}
            }
        }
        catch (Exception e) {
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);                     
        } 
        return fres;
    }
    
    /**
    * @description update not apllicable field
    * @param  formId    
    * @param  isApplicable 
    * @return string
    */
    @AuraEnabled
    public static string updateApplicableFormData(id formId, boolean isApplicable)
    {
        string message = '';
        try 
        {   List<Form_Data__c> formDataDetail = [SELECT Contact_Edition_Mapping__c,Forms_Permission__c FROM Form_Data__c WHERE Id=:formId];
            List<Form_Data__c> cemFormDatas = [SELECT Id FROM Form_Data__c WHERE Contact_Edition_Mapping__c=:formDataDetail.get(0).Contact_Edition_Mapping__c AND Forms_Permission__c=:formDataDetail.get(0).Forms_Permission__c WITH SECURITY_ENFORCED];
            for(Form_Data__c formData : cemFormDatas){
                formData.Not_Applicable__c = isApplicable;
            }
            if(Schema.sObjectType.Form_Data__c.isUpdateable()){
                update cemFormDatas;
            }
            message = 'success';
        } 
        catch (Exception e){
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }
        return message;
    }
    
    /**
    * @description update Form Data AfterUpload
    * @param  formId    
    * @return string
    */
    @AuraEnabled
    public static string updateFormDataAfterUpload(id formId)
    {
        string message = '';
        List<Form_Data__c> formDataLst;
        List<FormDataSecondaryCEM__c> listFormDataSecondaryCEM = [SELECT Form_Data__c FROM FormDataSecondaryCEM__c WHERE Id=:formId WITH SECURITY_ENFORCED LIMIT 1];
        if(!listFormDataSecondaryCEM.isEmpty()){
            formDataLst = [SELECT id FROM Form_Data__c where id =:listFormDataSecondaryCEM[0].Form_Data__c LIMIT 1];
        }
        else{
            formDataLst = [SELECT id FROM Form_Data__c where id =:formId WITH SECURITY_ENFORCED LIMIT 1];
        }
        try 
        {   
            Form_Data__c formData = new Form_Data__c();
            formData.id = formDataLst[0].Id;
            formData.Is_Agreed__c = true;
            if(Schema.sObjectType.Form_Data__c.isUpdateable()){
                update formData;
            }
            message = 'success';
        } 
        catch (DmlException e){message = e.getMessage();}
        return message;
    }
    
    /**
    * @description to get contact Data
    * @param  eventCode    
    * @param  accountId    
    * @return CustomerFormListWrp
    */
    @AuraEnabled
    public static CustomerFormListWrp contactData(String eventCode, String accountId){
        CustomerFormListWrp wrpobj = new CustomerFormListWrp();
        User u;
        if(User.SObjectType.getDescribe().isAccessible()){
            u = [Select id,Name,ContactId from User where Id =: UserInfo.getUserId()];
        }
        try{
            List<Contact> listContacts = new List<Contact>();
            if(Contact.SObjectType.getDescribe().isAccessible()){
                listContacts =[Select Id, Name FROM Contact where AccountId =: accountId AND Id !=: u.ContactId];
            }
            if(!listContacts.isEmpty()){
                Wrpobj.listContacts = listContacts;
            }
        }
        catch (Exception e) {System.debug(LoggingLevel.DEBUG, 'Exception hit ' +e.getMessage());HandleAllCustomException.logException(e,'Forms_Permission__c', 'After Insert');} 
        return Wrpobj;
    }
    
    /**
    * @description to check Delegate Details
    * @param  formDataId    
    * @param  conEdMapId    
    * @return string
    */
    @AuraEnabled
    public static string checkDelegateDetails(String formDataId, String conEdMapId){
        return '';
    }
    
    /**
    * @description to assign Forms To Delegate
    * @param  conId    
    * @param  eventCode    
    * @param  formDataIds     
    * @param  accountId 
    */
    @AuraEnabled
    public static void assignFormsToDelegate(String conId, String eventCode, List<String> formDataIds, String accountId){
        try{
        Edition__c edition;
        if(Edition__c.SObjectType.getDescribe().isAccessible() && eventCode !=''){
            edition = [Select Id FROM Edition__c WHERE Edition_Code__c =: eventCode LIMIT 1];
        }
       
            List<FormDataSecondaryCEM__c> listFormDataSecondary = new List<FormDataSecondaryCEM__c>();
            List<Contact_Edition_Mapping__c> conEdMapLst;
            Set<String> setFormDataIds = new Set<String>();
            if(FormDataSecondaryCEM__c.SObjectType.getDescribe().isAccessible()){
                listFormDataSecondary =[Select Id, Form_Data__c, Contact_Edition_Mapping__c FROM FormDataSecondaryCEM__c WHERE Form_Data__c IN:formDataIds];
            }
            
            for(FormDataSecondaryCEM__c fds:listFormDataSecondary){setFormDataIds.add(fds.Form_Data__c+'='+fds.Contact_Edition_Mapping__c);}

            if(Contact_Edition_Mapping__c.SObjectType.getDescribe().isAccessible()){
                conEdMapLst = [Select Id, Name, Contact__c, Edition__c, Relationship_Status__c, isSecondary__c FROM Contact_Edition_Mapping__c WHERE Contact__c =: conId And Edition__r.Edition_Code__c =: eventCode];
                if(!conEdMapLst.isEmpty() && formDataIds.size()>0){
                    for(integer i=0;i<formDataIds.size();i++){
                        FormDataSecondaryCEM__c fds = new FormDataSecondaryCEM__c();
                        if(!setFormDataIds.contains(formDataIds[i]+'='+conEdMapLst[0].Id)){
                            fds.Form_Data__c = formDataIds[i];
                            fds.Contact_Edition_Mapping__c = conEdMapLst[0].Id;
                            listFormDataSecondary.add(fds);
                        }
                    }
                    conEdMapLst[0].isSecondary__c = true;
                    if(!listFormDataSecondary.isEmpty()){
                        Database.insert(listFormDataSecondary,false);
                        update conEdMapLst;
                    }
                }
                else if(conEdMapLst.isEmpty() && formDataIds.size()>0){
                    User userExh = [Select ContactId FROM User WHERE id=:userInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
                    List<Contact_Edition_Mapping__c> exhibitorCEM = [SELECT Id, Access_Type__c  FROM Contact_Edition_Mapping__c WHERE Contact__c=:userExh.ContactId AND Account__c =:accountId AND Edition__r.Edition_Code__c=:eventCode WITH SECURITY_ENFORCED LIMIT 1];

                    Contact_Edition_Mapping__c cem = new Contact_Edition_Mapping__c();
                    cem.Contact__c = conId;
                    cem.Relationship_Status__c ='Active';
                    cem.isSecondary__c = true;
                    if(edition != null){
                        cem.Edition__c = edition.Id; 
                    }
                    cem.Account__c = accountId;
                    if(!ExhibitorCEM.isEmpty()){
                        cem.Access_Type__c = ExhibitorCEM[0].Access_Type__c; //'Exhibitor';
                    }
                    insert cem;
                    // inserting FormDataSecondary records according to assigned forms
                    for(integer i=0;i<formDataIds.size();i++){
                        listFormDataSecondary.add(new FormDataSecondaryCEM__c(Form_Data__c=formDataIds[i],Contact_Edition_Mapping__c=cem.Id));
                    }
                    
                    if(!listFormDataSecondary.isEmpty()){Database.insert(listFormDataSecondary,false);}
                }
            }
        }
        catch(Exception e) {
            System.debug(LoggingLevel.debug, 'Exception hit ' +e.getMessage());
           // HandleAllCustomException.logException(e,'Forms_Permission__c', 'After Insert');
           String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);  
        }
        return;
    }

    /**
    * @description to delete Uploaded Pdf
    * @param  linkEntId
    * @return String
    */
    @AuraEnabled
    public static String deleteUploadedPdf(String linkEntId){
        String message;
        try{
            List<ContentDocumentLink> cntnDocLinkLst;
            if(String.isNotBlank(linkEntId)){
                cntnDocLinkLst = [SELECT Id, LinkedEntityId, ContentDocumentId, SystemModstamp, Visibility, ShareType FROM ContentDocumentLink where LinkedEntityId =: linkEntId WITH SECURITY_ENFORCED Order By SystemModstamp Desc limit 1];
            }
            message = 'Success';
            if(!cntnDocLinkLst.isEmpty()){
                if(Schema.sObjectType.ContentDocumentLink.isDeletable()){
                    delete cntnDocLinkLst;
                }
            }
            else{
                message = 'Error';
            }
        }
        catch (Exception e) {
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);                     
        } 
        return message;
    }
    
    /**
    * @description to update Form Agreed
    * @param  formDataId
    */
    @AuraEnabled
    public static void updateFormAgreed(String formDataId){  
        try{
            Form_Data__c fd = new Form_Data__c(Id=formDataId);
            fd.Is_Agreed__c = true;
            fd.Status1__c = 'Agreed';
            if(Schema.SObjectType.Form_Data__c.isUpdateable()){
                Update fd;
            }
            List<Form_Response_Entry__c> lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:formDataId WITH SECURITY_ENFORCED LIMIT 1];
            for (Form_Response_Entry__c fre : lst) {
                fre.Status__c = 'Submitted';
            }
            if(Schema.SObjectType.Form_Response_Entry__c.isUpdateable() && !lst.isEmpty()){
                Update lst;
            }
        }              
        catch (Exception e) {
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);                     
        } 
    }

    /**
    * @description fetch form data detail
    * @param  formDataId
    * @param  allFormdataIds
    * @return Map<String,Object>
    */
    @AuraEnabled
    public static Map<String,Object> getFormDataDetail(String formDataId, List<String> allFormdataIds){
        Form_Data__c formData = new Form_Data__c();
        List<Form_Response_Entry__c> listEntries = new List<Form_Response_Entry__c>();
        Map<Id,Form_Data__c> mapFormData = new Map<Id,Form_Data__c>();
        try{
            mapFormData = new Map<Id,Form_Data__c>([SELECT Id,Overall_Status__c,Not_Applicable__c FROM Form_Data__c WHERE Id IN:allFormdataIds]);

            formData = [SELECT Id,Forms_Permission__r.Form_Allocation__r.Name,Forms_Permission__r.Form_Allocation__r.Form__r.Category__c,Forms_Permission__r.Form_Allocation__r.Form_Type__c,Forms_Permission__r.Form_Allocation__r.Form_Category__c,Forms_Permission__r.Form_Allocation__r.Form_Provider__c,Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c,Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c,Forms_Permission__r.Form_Allocation__r.Form__c,Is_Viewed__c,Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Status1__c,Not_Applicable__c,Forms_Permission__r.Form_Allocation__r.Form_Url__c,Forms_Permission__r.Form_Allocation__r.Form_Heading__c,Forms_Permission__r.Form_Allocation__r.Form_Entry__c,Forms_Permission__r.Form_Allocation__r.CountMultiSubmission__c,Is_Agreed__c,Approved_Responses__c,Rejected_Responses__c,Total_Responses__c,Submitted_Responses__c,Forms_Permission__r.Form_Allocation__r.Entry_Limit__c,Forms_Permission__r.Form_Allocation__r.Feature_Category__c,Forms_Permission__r.Form_Allocation__r.Booth_Product_Types__c,Purchase_Data__c,Overall_Status__c FROM Form_Data__c WHERE Id=:formDataId WITH SECURITY_ENFORCED ORDER BY Forms_Permission__r.Form_Allocation__r.Name];

            listEntries = [SELECT Id,Name,Content_Version__c,File_Name__c,Approval_Status__c,Contact_Edition_Mapping__c,Current_Page__c,Current_Page_No__c,Entry_Number__c,Form_Data__c,Form_Unlock__c,Girikon_Form__c,Purchase_Data__c,Rejection_Reason__c,Status__c,Total_Pages__c,User__c,User_Type1__c,Purchase_Data__r.Booth_Number__c,Version__c FROM Form_Response_Entry__c WHERE Form_Data__c =:formDataId WITH SECURITY_ENFORCED];
        }
        catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, 'Exception hit ' +e.getMessage());
          //  HandleAllCustomException.logException(e,'getFormDataDetail', 'getFormDataDetail');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);      
        } 

        return new Map<String,Object>{
            'formData'=>formData,
            'listEntries'=>listEntries,
            'mapFormData'=>mapFormData
        };
    }
     
    /** @description wrapper class*/
    public class CustomerFormListWrp {
        @AuraEnabled
        public List<String> lstformPermissionMan;
        @AuraEnabled
        public List<String> lstformPermissionAdd;
        @AuraEnabled
        public List<String> lstformPermissionOpt;
        @AuraEnabled
        public String conEdMapId;
        @AuraEnabled
        public String contactId;
        @AuraEnabled
        public String stanTabType;
        @AuraEnabled
        public Boolean isCEMSecondary;
        @AuraEnabled
        public List<Contact> listContacts;
        @AuraEnabled
        public String delegataId;
        @AuraEnabled
        public List<Id> formDataIds;
    }

    /**
    * @description  get Form Data regarding particular CEM Id
    * @param  cemId
    * @param  searchKey
    * @param  sortBy
    * @param  sortDirection
    * @return  List<Form_Data__c>
    */
    @AuraEnabled
    public static List<Form_Data__c> getFormData(Id cemId, String searchKey,String sortBy,String sortDirection){
        //List<Form_Data__c> listFormData = new List<Form_Data__c>();
        if(sortBy == 'formAllocName'){
            sortBy = 'Forms_Permission__r.Form_Allocation__r.Name';
        }
        else if(sortBy == 'formHeading'){
            sortBy = 'Forms_Permission__r.Form_Allocation__r.Form_Heading__c';
        }
        else if(sortBy == 'formFeatureCategory'){
            sortBy = 'Forms_Permission__r.Form_Allocation__r.Feature_Category__c';
        }
        else if(sortBy == 'formType'){
            sortBy = 'Forms_Permission__r.Form_Allocation__r.Form_Type__c';
        }
        else  if(sortBy == 'formEntry'){
            sortBy = 'Forms_Permission__r.Form_Allocation__r.Form_Entry__c';
        }
        else if(sortBy == 'BoothNumber'){
            sortBy = 'Purchase_Data__r.Booth_Number__c';
        }
        else if(sortBy == 'Status'){
            sortBy = 'Status1__c';
        }
        String query = '';
        
        try{
            if(cemId!=null && Schema.sObjectType.Form_Data__c.isAccessible()){
            query = 'SELECT Id,Forms_Permission__c,Forms_Permission__r.Form_Allocation__r.Name,Forms_Permission__r.Form_Allocation__r.Form_Heading__c,Forms_Permission__r.Form_Allocation__r.Feature_Category__c,Forms_Permission__r.Form_Allocation__r.Form_Entry__c,Forms_Permission__r.Form_Allocation__r.Form_Type__c,Status1__c,Purchase_Data__c,Purchase_Data__r.Booth_Number__c FROM Form_Data__c where Contact_Edition_Mapping__c =: cemId And Status1__c != \'Not Started\'';
            if(searchKey != null && searchKey != ''){
                String key = '%' + searchKey + '%';
                System.debug(LoggingLevel.DEBUG, key);
                query += ' AND ((Forms_Permission__r.Form_Allocation__r.Name LIKE :key) OR (Forms_Permission__r.Form_Allocation__r.Form_Heading__c LIKE :key) OR (Forms_Permission__r.Form_Allocation__r.Feature_Category__c LIKE :key) OR (Forms_Permission__r.Form_Allocation__r.Form_Entry__c LIKE :key) OR (Forms_Permission__r.Form_Allocation__r.Form_Type__c LIKE :key) OR (Status1__c LIKE:key) OR (Purchase_Data__r.Booth_Number__c LIKE :key))';
            }
            if ( sortBy != null && sortDirection != null ) {
               string nullvaluessort = '';
                if(sortDirection == 'asc'){
                    nullvaluessort = 'NULLS FIRST';                       
                }
                else{
                    nullvaluessort = 'NULLS LAST'; 
                }
                query += ' ORDER BY ' + String.escapeSingleQuotes(sortBy) + ' ' + String.escapeSingleQuotes(sortDirection) + ' ' + String.escapeSingleQuotes(nullvaluessort);
            }  
        }  
        } 
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Form_Data__c', 'Form Data');
        } 
        return Database.query( query );
	}

    /**
    * @description  Delete Form Response Entry and Question Response
    * @param  formDataList
    * @return  string
    */
    @AuraEnabled
    public static string resetFormDataStatus(List<Form_Data__c> formDataList){
        string message = '';
        if(!formDataList.isEmpty()){
            try{
                Set<id> formDataIds = new Set<id>();
                Set<id> formResponseIds = new Set<id>();
                List<Form_Data__c> formDataUpdate = new List<Form_Data__c>();
                for(Form_Data__c formData : formDataList){
                    formDataIds.add(formData.Id);
                }
                List<Form_Response_Entry__c> formRespLst = [SELECT id,Form_Data__c FROM Form_Response_Entry__c WHERE Form_Data__c IN:formDataIds WITH SECURITY_ENFORCED];

                if(!formRespLst.isEmpty()){
                    for(Form_Response_Entry__c fre : formRespLst){
                        formResponseIds.add(fre.Id);
                    }
                    List<Question_Response__c> quesRespLst = [SELECT Id,Form_Response_Entry__c FROM Question_Response__c WHERE Form_Response_Entry__c IN: formResponseIds WITH SECURITY_ENFORCED];
                    if(!quesRespLst.isEmpty()){
                        if(Schema.sObjectType.Question_Response__c.isDeletable()){
                            delete quesRespLst;
                        }
                    }
                    if(Schema.sObjectType.Form_Response_Entry__c.isDeletable()){
                        delete formRespLst;
                    }
                }
                        
                List<Form_Data__c> formDataLst = [Select id,Is_Agreed__c,Is_Viewed__c,Name,Forms_Permission__c,Forms_Permission__r.Form_Allocation__r.Feature_Category__c,Status1__c FROM Form_Data__c where Forms_Permission__r.Form_Allocation__r.Feature_Category__c = 'Manual' and Id IN: formDataIds WITH SECURITY_ENFORCED];
                for(Form_Data__c formData : formDataLst){
                    Form_Data__c formDataObj = new Form_Data__c();
                    formDataObj.Id = formData.Id;
                    formDataObj.Is_Agreed__c = false;
                    formDataObj.Is_Viewed__c = false;
                    formDataUpdate.add(formDataObj);
                }
                if(Schema.sObjectType.Form_Data__c.isUpdateable()){
                    update formDataUpdate;
                }
                
                message = 'Success';       
            }
            catch(DmlException e){message = e.getMessage();}
        }
        return message;
        
    }

    /**
    * @description  get IMCC_Global_Constant__mdt custom metadataType
    * @return  List
    */
    @AuraEnabled
    public static List <IMCC_Global_Constant__mdt> fetchGlobalConstant() {
        
        return [ SELECT Id, MasterLabel, Description__c,Value__c FROM IMCC_Global_Constant__mdt WHERE MasterLabel = 'PDF form Instructions'];
    }

    /**
    * @description  get Contentversion to fetch the uploaded file size
    * @param  idList
    * @return  List
    */
    @AuraEnabled
    public static List <Contentversion> fetchfileUploadSize(string idList) {
        list<Contentversion> cvtestidlist = [SELECT Id,ContentSize ,Description ,FileExtension,Title FROM ContentVersion WHERE Id =: idList];
        return cvtestidlist;
        
    }
}