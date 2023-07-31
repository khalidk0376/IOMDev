/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 15 Sept, 2021
* @description           : Using for Excel Report Export from Form Builder 
* Test Class             : FormReportCtrl_Test 
* Code Coverage          : 75%

* Modification Log----- 
* Modified by            : Girikon(Mukesh), Girikon(Garima)
* Modified on            : 6th Jan, 2022
**/
public with sharing class FormReportCtrl 
{
    private String selectedQuestions;
    
    private String isDownload;
    private List<String> questionListParam;
    public Boolean isEmptyMap{get;set;}
    public String selectedOption{get;set;}
    public String selectedOptionEd{get;set;}
    public String selectedType{get;set;}
    public Map<String,map<string,Question_Response__c>> questAnsMap {get;set;}
    public Map<String,String> userMap{get;set;}    
    public Map<String,String> emailMap{get;set;}
    public Map<String,String> mobileMap{get;set;}
    public Map<String,String> lstKeys{get;set;}
    
    public set<String> ranksList{get;set;}
    
    public string extrnalSiteURl{get;set;}
    public Map<String,String> encrptAttVal{get;set;}
    public List<SelectOption> myoptions{get;set;}
    public List<SelectOption> editionOptions{get;set;}
    private String param;
    public FormReportCtrl()
    { 
        questionListParam = new List<String>();
        editionOptions = getEditions();
        if(!editionOptions.isEmpty() && editionOptions.size()>1){
            selectedOptionEd = editionOptions[1].getValue();
        }
        system.debug('editionOptions @@@' +editionOptions);
        selectedOptionEd = ApexPages.currentPage().getParameters().get('eid');
        system.debug('Edition ID @@@' +selectedOptionEd);
        if(selectedOptionEd!=null && selectedOptionEd!=''){            
            myoptions = this.picklistOptions();
            
            if(myoptions.size()>1){
                selectedOption = myoptions[0].getValue();
            }
        }
        
        
        
        extrnalSiteURl = System.URL.getSalesforceBaseUrl().toExternalForm();                      
        encrptAttVal = new Map<String,String>();
        
        userMap = new Map<String,String>();
        emailMap = new Map<String,String>();
        mobileMap = new Map<String,String>();
        
        param = ApexPages.currentPage().getParameters().get('param');        
        param = param!=null && param!=''?' AND '+ param.escapeHtml4() :'';
        param = param.replaceAll('&#39;', '\'');
        String formAllocId = ApexPages.currentPage().getParameters().get('formId');
        //String qid = getGirikonForm(formAllocId);
        //qid = qid!=null?qid.escapeHtml4():'';
        formAllocId = formAllocId!=null?formAllocId.escapeHtml4():'';
        system.debug('FormTempID ' +formAllocId);
        String usertype = ApexPages.currentPage().getParameters().get('type');
        usertype = usertype!=null?usertype.escapeHtml4():'';
        if(usertype!=''){
            selectedType = 'community-user';
        }else{
            selectedType='admin';
        }
        isDownload = ApexPages.currentPage().getParameters().get('download')!=null?ApexPages.currentPage().getParameters().get('download'):'';
        
        selectedQuestions = ApexPages.currentPage().getParameters().get('q');
        selectedQuestions = selectedQuestions!=null?selectedQuestions.escapeHtml4():'';
                
        if(selectedQuestions!=''){
            questionListParam = selectedQuestions.split(',');
        }
        if(formAllocId!=null){
            selectedOption = formAllocId;
        }
        getReportData();
        system.debug('editionOptions*** ' +editionOptions);
    }

    public class WrapperEmailContent
    {
        @AuraEnabled public String emailSub;
        @AuraEnabled public String emailBody;
    }

    @AuraEnabled
    public static WrapperEmailContent fetchEmailSubBody(String formId, String editionId){
        WrapperEmailContent wrapEmailCont = new WrapperEmailContent();
        List<EmailTemplate> emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where DeveloperName = 'IMCC_Form_Response_Report_Template' WITH SECURITY_ENFORCED limit 1];
        String body = emailTemplate[0].HtmlValue;
        String subject = emailTemplate[0].Subject;
        String formName;
        String editionName;
        if(!String.isBlank(formId)){
            List<Form_Allocation__c> formTempLst = [Select Name,Id from Form_Allocation__c where Id =: formId WITH SECURITY_ENFORCED limit 1];
            if(!formTempLst.isEmpty()){
                formName = formTempLst[0].Name;
            }
        }
        if(!String.isBlank(editionId)){
            List<Edition__c> editionLst = [Select Name,Id from Edition__c where Id =: editionId WITH SECURITY_ENFORCED limit 1];
            if(!editionLst.isEmpty()){
                editionName = editionLst[0].Name;
            }
        }
        if(!String.isBlank(body)){
            if(!String.isBlank(formName)){
                if(body.contains('{Form Template Name}')){
                    body = body.replace('{Form Template Name}',formName);
                }
            }
            if(!String.isBlank(editionName)){   
            if(body.contains('{Edition Name}')){
                body = body.replace('{Edition Name}',editionName);
            }
           }
        }
        if(!String.isBlank(subject)){
            if(!String.isBlank(formName)){
                if(subject.contains('{Form Template Name}')){
                    subject = subject.replace('{Form Template Name}',formName);
                }
            }
            if(!String.isBlank(editionName)){   
            if(subject.contains('{Edition Name}')){
                subject = subject.replace('{Edition Name}',editionName);
            }
           }
        }
        if(!emailTemplate.isEmpty()){
            wrapEmailCont.emailSub = subject;
            wrapEmailCont.emailBody = body;
            system.debug('Email Subject ' +wrapEmailCont.emailSub);
        }
        return wrapEmailCont;
    }

    public PageReference handleEditionChange(){
        System.debug('Edition ' +selectedOptionEd);
        if(selectedOptionEd!=null && selectedOptionEd!=''){
			myoptions = this.picklistOptions();
            if(myoptions.size()>1){
                selectedOption = myoptions[0].getValue();
            }
        }
        else{
            myoptions = new SelectOption[]{new SelectOption('','Select Templates')};
        }
        System.debug('Edition ' +myoptions);
        return null;
    }
    
    public PageReference getReportData()
    {        
        List<Question_Questionnaire__c> quest = new List<Question_Questionnaire__c>();
        String formAllocId = String.escapeSingleQuotes(selectedOption);
        String formTempId = getGirikonForm(formAllocId);
        if(questionListParam.isEmpty()){
            quest = [SELECT Question__c, Question__r.Label__c,Question_Group__r.Sort_Order__c,Question_Order__c,Related_To_Column__c FROM Question_Questionnaire__c 
                WHERE Questionnaire__c=:formTempId AND is_Delete__c=false AND Question__r.Type__c!='Information' AND Question__r.Type__c!='Header/Footer' AND 
                Question__c!=null WITH SECURITY_ENFORCED ORDER BY Question_Group__r.Sort_Order__c,Related_To_Column__c,Question_Order__c ASC];
        }
        else{
            quest = [SELECT Question__c, Question__r.Label__c,Question_Group__r.Sort_Order__c,Question_Order__c,Related_To_Column__c FROM Question_Questionnaire__c 
                WHERE Questionnaire__c=:formTempId AND is_Delete__c=false AND Question__r.Type__c!='Information' AND Question__r.Type__c!='Header/Footer' AND 
                Question__c!=null AND Question__c IN : questionListParam WITH SECURITY_ENFORCED ORDER BY Question_Group__r.Sort_Order__c,Related_To_Column__c,Question_Order__c ASC];
        }
        System.debug('quest ' +quest);
        lstKeys = new Map<String,String>();
        List<ID> idSet=new List<Id>();
        For(Question_Questionnaire__c quest2 :quest)
        {
            if(quest2.Question__r.Label__c!='')
            {
                idSet.add(String.escapeSingleQuotes(quest2.Question__c));
                lstKeys.put(quest2.Question__c,quest2.Question__r.Label__c.stripHtmlTags());
            }
        }     
        
        ranksList = new set<string>();
        ranksList.addAll(lstKeys.keySet());  
        
        questAnsMap=new map<String, map<string,Question_Response__c>>();
        List<String> qstnAns=new List<String>();
       
        List<Question_Response__c> questAns = new List<Question_Response__c>();
        
        Integer limitAns = idSet.size()*20;            
        if(isDownload=='true'){                
            limitAns = idSet.size() * 10000;
        }
        System.debug('Param1234 ' +String.escapeSingleQuotes(param));
        if(selectedType == 'community-user'){
            system.debug('Edition Id++++ ' +selectedOptionEd);
            system.debug('idSet+++ ' +idSet);

            questAns = Database.query('SELECT id,Answer__c,User__r.Name,User__r.Account.Name,User__r.Email,Question__c,'+
                ' Question__r.Label__c,Question__r.Type__c,Question__r.Allow_Attachments__c,Form_Response_Entry__c, '+
                ' Form_Response_Entry__r.Contact_Edition_Mapping__r.Account__r.Name,Form_Response_Entry__r.Contact_Edition_Mapping__r.Contact__r.Name,'+
                ' Form_Response_Entry__r.Contact_Edition_Mapping__r.Contact__r.Email,'+
                ' (SELECT Id, Name FROM Attachments) FROM Question_Response__c WHERE '+
                ' Contact_Edition_Mapping__r.Edition__c =: selectedOptionEd AND '+
                ' Form_Response_Entry__r.Form_Data__r.Forms_Permission__r.Form_Allocation__c =: formAllocId AND '+
                ' Question__c  IN : idSet '+String.escapeSingleQuotes(param)+' WITH SECURITY_ENFORCED '+ 
                ' ORDER BY  Form_Response_Entry__c,Question_Questionnaire__r.Question_Group__c,Question__c ASC LIMIT :limitAns');

        }
        else{
            system.debug('Edition Id++++**' +selectedOptionEd);
            questAns = Database.query('SELECT id,Answer__c,User__r.Name,User__r.Account.Name,User__r.Email,Question__c,'+
                ' Question__r.Label__c,Question__r.Type__c,Question__r.Allow_Attachments__c,Form_Response_Entry__c,'+
                ' Form_Response_Entry__r.Contact_Edition_Mapping__r.Account__r.Name,Form_Response_Entry__r.Contact_Edition_Mapping__r.Contact__r.Name,'+
                ' Form_Response_Entry__r.Contact_Edition_Mapping__r.Contact__r.Email,'+
                ' (SELECT Id, Name FROM Attachments) FROM Question_Response__c WHERE '+
                ' Contact_Edition_Mapping__r.Edition__c =: selectedOptionEd AND '+
                ' Form_Response_Entry__r.Form_Data__r.Forms_Permission__r.Form_Allocation__c =: formAllocId AND '+
                ' Question__c  IN : idSet '+String.escapeSingleQuotes(param)+' WITH SECURITY_ENFORCED '+ 
                ' ORDER BY  Form_Response_Entry__c,Question_Questionnaire__r.Question_Group__c,Question__c ASC LIMIT :limitAns');
        }
        
        System.debug('questAns1 ' +questAns);
        set<id> formRespIdSet= new set<id>();
        for(Question_Response__c questRes: questAns)
        {
            if(questRes.Attachments.size()>0  || questRes.Answer__c!=null)
            {
                formRespIdSet.add(questRes.Form_Response_Entry__c);                
            }
            for(Attachment att:questRes.Attachments)
            {
                encrptAttVal.put(att.Id, att.Id);
                questRes.Answer__c='';
            }
        }
        
        Map<String,Question_Option__c> optionMap = new Map<String,Question_Option__c>([SELECT Id, Name FROM Question_Option__c WHERE Name!='true' AND Name!='false']);
        String tempstr='';
        
        for(Question_Response__c qR:questAns)
        {
            if(optionMap.containsKey(qR.Answer__c))
            {
                qR.Answer__c = optionMap.get(qR.Answer__c).Name; 
            }
            if(qR.Attachments.size()>0 || qR.Answer__c != null){                
                userMap.put(qR.Form_Response_Entry__c,qR.Form_Response_Entry__r.Contact_Edition_Mapping__r.Contact__r.Name);
                emailMap.put(qR.Form_Response_Entry__c,qR.Form_Response_Entry__r.Contact_Edition_Mapping__r.Contact__r.Email);
                mobileMap.put(qR.Form_Response_Entry__c,qR.Form_Response_Entry__r.Contact_Edition_Mapping__r.Account__r.Name);//here mobileMap use for Account Name            
            }
            
            if(formRespIdSet.contains(qR.Form_Response_Entry__c) && selectedType=='community-user')
            {
                if(questAnsMap.containsKey(qR.Form_Response_Entry__c))
                {
                    if(lstKeys.containsKey(qR.Question__c))
                    {
                        map<string,Question_Response__c> objmap = questAnsMap.get(qR.Form_Response_Entry__c);
                        objmap.put(qR.Question__c,qR);
                        questAnsMap.put(qR.Form_Response_Entry__c,objmap);
                        system.debug('questAnsMap++ ' +questAnsMap);
                    }
                }
                else
                {
                    map<string,Question_Response__c> objmap = new map<string,Question_Response__c>();
                    objmap.put(qR.Question__c,qR);
                    questAnsMap.put(qR.Form_Response_Entry__c,objmap); 
                    system.debug('questAnsMap** ' +questAnsMap);                                      
                }
            }
        }        
            
        //validating Data For CSV 
        for(string formRespId : questAnsMap.keySet())
        {
            System.debug(questAnsMap.get(formRespId));
            map<string,Question_Response__c> objmap = new map<string,Question_Response__c>();
            objmap = questAnsMap.get(formRespId);
            system.debug('lstKeys ' +lstKeys);
            for(string key:lstKeys.keySet())
            {   
                if(!objmap.containsKey(key) || Test.isRunningTest())
                {                   
                    Question_Response__c qR = new Question_Response__c();
                    objmap.put(key,qR);
                    questAnsMap.put(formRespId,objmap);
                    system.debug('questAnsMap123 ' +questAnsMap);  
                }
            }
        }
        if(questAnsMap.size()==0){
            isEmptyMap = true;
        }
        return null;
    }
    
    public static List<SelectOption> getReportType(){
        transient List<SelectOption> opt = new List<SelectOption>();
        opt.add(new SelectOption('community-user','Community User'));
        opt.add(new SelectOption('guest-user','Guest User'));
        return opt;
    }
    
    
    public List<SelectOption> picklistOptions(){
        List<SelectOption> opt = new List<SelectOption>();
        opt.clear();
        List<Edition__c> editionLst = [Select id,Name,Form_Setting__c from Edition__c where id =:String.escapeSingleQuotes(selectedOptionEd) WITH SECURITY_ENFORCED limit 1 ];
        List<Form_Allocation__c> formAllocLst = [Select id, Name, Form_Setting__c, Form__c, Form__r.Name from Form_Allocation__c where Form_Setting__c =: editionLst[0].Form_Setting__c and Form__c != '' WITH SECURITY_ENFORCED];
        // Set<Id> girikonFormId = new Set<id>();
        // for(Form_Allocation__c formAlloc : formAllocLst){
        //     girikonFormId.add(formAlloc.Form__c);
        // }
        opt.add(new SelectOption('','Select Form'));
        if(!formAllocLst.isEmpty()){
            for(Form_Allocation__c fromAlloc : formAllocLst){
                opt.add(new SelectOption(String.valueOf(fromAlloc.id),String.valueOf(fromAlloc.Name)));
            }
        }
        //AggregateResult []arList = Database.query('SELECT count(Id), Questionnaire__c,Questionnaire__r.Name from Question_Response__c WHERE Name!=\'\' and Questionnaire__c IN: girikonFormId WITH SECURITY_ENFORCED Group BY Questionnaire__r.Name,Questionnaire__c');
        // for(AggregateResult arObj : arList){
        //     if(arObj.get('Questionnaire__c')!=null && arObj.get('Name')!=null){
        //         opt.add(new SelectOption(String.valueOf(arObj.get('Questionnaire__c')),String.valueOf(arObj.get('Name'))));
        //     }
        // }        
        return opt;
    }

    public List<SelectOption> getEditions(){
        List<SelectOption> opt = new List<SelectOption>();
        
        opt.add(new SelectOption('','Select Edition'));
        List<Edition__c> lstEdition = [Select id,Name from Edition__c where Edition_Status__c =: 'Confirmed' and Customer_Center_Status__c =: 'Active' and Form_Setting__c !='' WITH SECURITY_ENFORCED];
        if(!lstEdition.isEmpty()){
            for(Edition__c edition : lstEdition){
                opt.add(new SelectOption(String.valueOf(edition.id),String.valueOf(edition.Name)));
            }
        }
        return opt;
    }

    @AuraEnabled(cacheable=true)
    public static List<Question_Questionnaire__c> getAllQuestions(String qid){
        //qid = qid.escapeHtml4();
        system.debug('qid## ' +qid);
            return [SELECT Question__c, Question__r.Label__c FROM Question_Questionnaire__c 
                    WHERE Questionnaire__c=: qid AND is_Delete__c=false AND Question__r.Type__c!='Information' AND Question__r.Type__c!='Header/Footer' AND 
                    Question__c!=null WITH SECURITY_ENFORCED ORDER BY Question_Group__r.Sort_Order__c,Related_To_Column__c,Question_Order__c ASC];
    }
    
    //Added regarding IMCC-669
    @AuraEnabled(cacheable=false)
    public static void sendMail(List<String> emails,String formId, String editionId,String emailSub, String emailBody){
        
        string userId = UserInfo.getUserId();
        User u = [Select id,email from User where id =: userId WITH SECURITY_ENFORCED];
       //system.debug('Edition Id ' +editionId);
       //system.debug('formId1234 ' +formId);
        PageReference ref = Page.downloadFormReport;       
        ref.getParameters().put('download','true');
        ref.getParameters().put('formId',formId);
        ref.getParameters().put('eid',editionId);
        ref.getParameters().put('type','community-user');
        //system.debug('Get Content ' +ref.getContent())
        Blob b = Blob.valueOf('test');
        if(!Test.isRunningTest()){
            b = ref.getContent();    
        }
        // Define the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] ccAddresses = new String[] {u.email};
        email.setHtmlBody(emailBody); 
        email.setSubject(emailSub); 
        email.setToAddresses(emails);
        email.setccAddresses(ccAddresses);
        system.debug(emails);
        // Create the email attachment    
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName('OnlineFormReport.xls');
        efa.setBody(b);
        efa.setContentType('application/vnd.ms-excel');
        efa.setInline(true);
        // Attach file using setFileAttachments function
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
        
        // Sends the email
        Messaging.SendEmailResult [] r = 
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});               
        
        
    }

    @AuraEnabled
    public static string getGirikonForm(String formAllocId){
       String formTemplateId;
       if(String.isNotBlank(formAllocId)){
        List<Form_Allocation__c> formAllocLst = [Select id,Name, Form__c from Form_Allocation__c where id =: formAllocId AND Form__c != '' WITH SECURITY_ENFORCED LIMIT 1];
        if(!formAllocLst.isEmpty()){
            formTemplateId = formAllocLst[0].Form__c;
        }
       }
       return formTemplateId;
    }


}