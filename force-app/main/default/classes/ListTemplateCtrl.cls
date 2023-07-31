/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 14 Sept, 2021
* @description           : Use to list all form 
* Test Class             : InformationInputCtr_Test 
* Code Coverage          : 89%

* Modification Log----- 
* Modified by            : Girikon(Mukesh)
**/
public with sharing class ListTemplateCtrl {
    
    @AuraEnabled
    public LightningTableWraper ltngTabWrap;     
    @AuraEnabled
    public integer offst;    
    @AuraEnabled
    public integer total;    
    @AuraEnabled
    public boolean hasprev;    
    @AuraEnabled
    public boolean hasnext;
    @AuraEnabled
    public Object questionCount;
    
    public static boolean hasprevious(integer off){ if(off>0){return false;}else{return true;}}
    public static boolean hasnxt(integer off,integer li,integer ps){if((off+ps) < li){return false;}else{return true;}}
    
    @AuraEnabled
    public static ListTemplateCtrl getGenericObjectRecord(String ObjectName,String fieldstoget,Decimal pagesize,boolean next,boolean prev,Decimal off,String selectCategory,String searchValue,String sortBy,String sortType){
        // set filter query
        string whereClause ='';
        String sQueryofTotal = 'Select count() From Questionnaire__c ';
        Boolean isAddWhere = false;
        if(String.isNotBlank(selectCategory)){
            whereClause +=' where Category__c =\''+ string.escapeSingleQuotes(selectCategory) + '\''; 
            sQueryofTotal +=' where Category__c =\''+ string.escapeSingleQuotes(selectCategory) + '\''; 
            isAddWhere =true;
        }
        if(String.isNotBlank(searchValue)){
            searchValue = string.escapeSingleQuotes(searchValue);
            searchValue ='%'+searchValue+'%';
            if(isAddWhere ==true){
                whereClause +=  ' AND Name LIKE \''+ string.escapeSingleQuotes(searchValue) + '\''; 
                sQueryofTotal +=  ' AND Name LIKE \''+ string.escapeSingleQuotes(searchValue) + '\''; 
            }
            else{
                whereClause +=  ' Where Name LIKE \''+ string.escapeSingleQuotes(searchValue) + '\'';
                sQueryofTotal +=  ' Where Name LIKE \''+ string.escapeSingleQuotes(searchValue) + '\'';
            }
        }
		// End filter query
		
        ListTemplateCtrl pg = new ListTemplateCtrl();
        Integer offset = (Integer)off;
        Integer psize = (Integer)pagesize;        
        list<account> li = new list<account>();
        integer listlength = Database.countQuery(sQueryofTotal);
        List<String> lstfieldstoget = fieldstoget.split(',');
        List<LightningTableColumnWrapper> lstTableColumn = new list<LightningTableColumnWrapper> ();        
        Transient DescribeSObjectResult objResult = Schema.getGlobalDescribe().get(ObjectName).getDescribe();
        Transient lightningTableColumnWrapper colWrapper;
        Transient DescribeFieldResult fieldResult;        
        for(String field : lstfieldstoget){
            fieldResult = objResult.fields.getMap().get(field).getDescribe();
            if(fieldResult.getName()=='CreatedDate' || fieldResult.getName()=='Id' || fieldResult.getName()=='Community_URL__c' || fieldResult.getName()=='NetworkId__c'){
                continue;
            }
            colWrapper = new LightningTableColumnWrapper();
            colWrapper.label = fieldResult.getLabel();
            colWrapper.fieldName = fieldResult.getName();
            colWrapper.type = String.valueof(fieldResult.getType()).toLowerCase();
            if(field!='Description__c'){
            	colWrapper.sortable = true;    
            }
            lstTableColumn.add(colWrapper);
        }
        
        String queryString = '';        
        if(next==false && prev==false){
            queryString = 'Select '+ String.escapeSingleQuotes(String.join(lstfieldstoget,','))+
                ' from '+ String.escapeSingleQuotes(ObjectName)+ whereClause + ' WITH SECURITY_ENFORCED ORDER BY '+sortBy+' '+sortType+' Limit '+psize+' OFFSET '+offset;
        }else if(next==true && (offset+psize)<=listlength){
            offset=offset+psize;
            queryString = 'Select '+ String.escapeSingleQuotes(String.join(lstfieldstoget,','))+
                ' from '+ String.escapeSingleQuotes(ObjectName) + whereClause+  ' WITH SECURITY_ENFORCED ORDER BY '+sortBy+' '+sortType+' Limit '+psize+' OFFSET '+offset;
        }else if(prev==true && offset>0){
            offset=offset-psize;
            queryString = 'Select '+ String.escapeSingleQuotes(String.join(lstfieldstoget,','))+
                ' from '+ String.escapeSingleQuotes(ObjectName) +whereClause+ ' WITH SECURITY_ENFORCED ORDER BY '+sortBy+' '+sortType+' Limit '+psize+' OFFSET '+offset;
        }
        try{			
            LightningTableWraper ltngTableWrapper = new LightningTableWraper();
            ltngTableWrapper.tableRecord = database.query(queryString);
            ltngTableWrapper.tableColumn = lstTableColumn;
            pg.ltngTabWrap = ltngTableWrapper;
            pg.offst = offset;
            pg.hasprev = hasprevious(offset);   
            pg.hasnext = hasnxt(offset,listlength,psize);
            pg.total = listlength;
            pg.questionCount = getQuestionCount();
        }
        catch(Exception e){
            system.debug(e.getLineNumber()+','+e.getMessage());
        }
        return pg;
    } 

    public class LightningTableColumnWrapper {
        @AuraEnabled
        public string label {get;set;}
        @AuraEnabled
        public String fieldName {get;set;}
        @AuraEnabled
        public string type {get;set;}
        @AuraEnabled
        public boolean sortable {get;set;}
    }

    public class LightningTableWraper{
        @AuraEnabled
        public List<sObject> tableRecord {get;Set;}
        @AuraEnabled
        public List<lightningTableColumnWrapper> tableColumn {get;set;}
    }
    
    /**
    * fetch all Questionnaire categories
    * @return list of Questionnaire categoires
    */
    @AuraEnabled
    public static List<String> getQuenaireCategory(){
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Questionnaire__c.Category__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }
        return options;
    }
    /**
    * fetch all Questionnaire categories
    * @return list of Questionnaire language
    */
    @AuraEnabled
    public static List<Wrapper_Class> getQuenaireLanguage(){
        List<ListTemplateCtrl.wrapper_class> options = new List<ListTemplateCtrl.wrapper_class>();
        Schema.DescribeFieldResult fieldResult = Questionnaire__c.Language__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(new ListTemplateCtrl.wrapper_class(f.getLabel(),f.getValue(),''));
        }
        return options;
    }
    
    @AuraEnabled
    public static List<Wrapper_Class> getCommunities(){
        /*List<ListTemplateCtrl.wrapper_class> options = new List<ListTemplateCtrl.wrapper_class>();
        String domainName='';
        options.add(new ListTemplateCtrl.wrapper_class('--None--','/',''));
     
        if(FBUtils.isAccessible('Network','Id,Name,UrlPathPrefix')){
            String path='', str='';
            for (Network net: [SELECT Id,Name,UrlPathPrefix FROM Network LIMIT 100]) {                
                str = Network.getLoginURL(net.Id);
                str = str.replace('/login','');
                path = (net.UrlPathPrefix==null||net.UrlPathPrefix=='')?str:str+'/'+net.UrlPathPrefix;                
                options.add(new ListTemplateCtrl.wrapper_class(net.Name,path,net.Id));
            }
        }
        return options;*/
        return new List<Wrapper_Class>();
    }
    public class Wrapper_Class{
        @AuraEnabled public String label;
        @AuraEnabled public String networkId;
        @AuraEnabled public String value;
        public Wrapper_Class(String label,String value,String networkId){
            this.label = label;
            this.value = value;
            this.networkId = networkId;
        }
    }

    /**
    * Creating Questionnaire record
    * @param  oQnaire : set value in Questionnaire instance.
    * @return         Questionnaire Id
    */
    @AuraEnabled
    public static String createQnaire(Questionnaire__c oQnaire,String sectionName,String colnum){
        try{

            SObjectAccessDecision sd = Security.stripInaccessible(AccessType.CREATABLE, new List<Questionnaire__c>{oQnaire});
            Insert sd.getRecords();
            System.debug(sd.getRecords());
            //Create default Question Group
            Question_Group__c oQGrp = new Question_Group__c(Name=sectionName,No_Of_Columns__c=colnum,Sort_Order__c=0);
            SObjectAccessDecision sd2 =Security.stripInaccessible(AccessType.CREATABLE, new List<Question_Group__c>{oQGrp});
            Insert sd2.getRecords();
            System.debug(sd2.getRecords());
            Question_Questionnaire__c oQueQnaire = new Question_Questionnaire__c(Name=String.valueOf(sd.getRecords()[0].get('Name')),Question_Group__c=sd2.getRecords()[0].Id,Questionnaire__c=sd.getRecords()[0].Id);
            SObjectAccessDecision sd3 = Security.stripInaccessible(AccessType.CREATABLE, new List<Question_Questionnaire__c>{oQueQnaire});
            Insert sd3.getRecords();
            
            //Create pagination            
            Form_Pagination__c pageObj = new Form_Pagination__c(Total_Pages__c=1.0,Name='Pagination',Questionnaire__c=sd.getRecords()[0].id);
            pageObj = NewCreateTemplateCtr.createPage(pageObj);
            
            //update page and insert section
            if(pageObj.Form_Pages__r!=null && !pageObj.Form_Pages__r.isEmpty()){                
                Form_Page__c fp = pageObj.Form_Pages__r[0];
                fp.Section__c = sd2.getRecords()[0].id;
                Update Security.stripInaccessible(AccessType.UPDATABLE, new List<Form_Page__c>{fp}).getRecords();
            }
            return sd.getRecords()[0].id;
        }
        catch(Exception ex){
            System.debug(ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static void updateQnaire(List<Questionnaire__c> oQnaire){
        try{
            if(Schema.SObjectType.Questionnaire__c.isUpdateable()){
                Update Security.stripInaccessible(AccessType.UPDATABLE, oQnaire).getRecords();                
            }
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    private static list<AggregateResult> getQuestionCount(){
        //AND Question__r.Type__c!='Header/Footer' AND Question__r.Type__c!='Information'
		return [SELECT count(Id), Questionnaire__c,Questionnaire__r.Name FROM Question_Questionnaire__c WHERE is_Delete__c=false AND Questionnaire__r.Name!='' AND Question__c!=null WITH SECURITY_ENFORCED GROUP BY Questionnaire__r.Name,Questionnaire__c];
    }  

    @AuraEnabled
    public static list<sObject> getAllApps(){        
        return [SELECT ApplicationId,Label,StartUrl,LogoUrl,Type,Description FROM AppMenuItem WHERE IsVisible=true AND IsAccessible=true AND Label!='Form Builder' AND Label!='App Launcher' WITH SECURITY_ENFORCED ORDER BY SortOrder ASC];
    }
    
    /**
    * fetch Questionnaire record
    * * @param  qnaireId : Questionnaire Id.
    * @return  Questionnaire record
    */
    @AuraEnabled
    public static Questionnaire__c getQnaireRecord(String qnaireId){
        Questionnaire__c qnaire=new Questionnaire__c();
        if(String.isNotBlank(qnaireId)){
            qnaire=[Select Id,Name,Language__c,NetworkId__c,isMerge__c,Buttons_Position__c,Is_Customize_Buttons__c,Button_Alignment__c,Next_Button_Color__c,Next_Button_Label__c,Previous_Button_Color__c,Previous_Button_Label__c,Submit_Button_Color__c,Submit_Button_Label__c,Community_URL__c,Allow_download_copy__c,Binding_Object__c,Category__c,Description__c,Name__c,Template__c,Send_Copy__c,Show_Main_Title_to_User__c From Questionnaire__c Where Id=:String.escapeSingleQuotes(qnaireId) WITH SECURITY_ENFORCED];
        }
        return qnaire;
    }
    
    /**
    * Save Questionnaire clone record
    * * @param  qnaireId : Questionnaire Id.
    * @return  Questionnaire record
    */
    @AuraEnabled
    public static String saveQnaireCloneRecord(Questionnaire__c oQnaire){
        Questionnaire__c cloneqnaire;
        Map<Id,Question_Group__c> oldqgroup = new Map<Id,Question_Group__c>();    
        Questionnaire__c qnaire = [SELECT Id,Name,Language__c,NetworkId__c,Buttons_Position__c,Is_Customize_Buttons__c,
        Button_Alignment__c,Next_Button_Color__c,Next_Button_Label__c,Previous_Button_Color__c,Previous_Button_Label__c,
        Submit_Button_Color__c,Submit_Button_Label__c,Community_URL__c,Allow_download_copy__c,Binding_Object__c,
        Category__c,Description__c,Name__c,Template__c,Send_Copy__c FROM Questionnaire__c WHERE Id=:oQnaire.id WITH SECURITY_ENFORCED];
                    
        cloneqnaire = qnaire.clone(false);
        cloneqnaire.Name=oQnaire.Name;                
        cloneqnaire.Category__c=oQnaire.Category__c;        
        cloneqnaire.isMerge__c=oQnaire.isMerge__c;        
        cloneqnaire.Description__c=oQnaire.Description__c;        
        Insert cloneqnaire;

        List<Question_Questionnaire__c> lstQuestionQuestionnaire = [SELECT Id,Name,Allow_Attachments__c,Allow_Comment__c,Allow_Currency__c,Category__c,Default_Value__c,
            Comment__c,Currency_Symbol__c,Help_Text__c,Help_Text_Required__c,Decimal_value__c,is_Delete__c,lookup_Object_API_Name__c,lookup_Object_Field_Name__c,Maximum_value__c,Minimum_Value__c,
            Max_Char_Length__c,Metadata__c,No_Of_Columns__c,Points__c,Question__c,Step_Size__c,Question_Group__c,Questionnaire__c,Question_Order__c,Related_To_Column__c,
            Required__c,Is_Allow_Branching__c,background_Color__c FROM Question_Questionnaire__c WHERE Questionnaire__c=:oQnaire.id and is_delete__c=false WITH SECURITY_ENFORCED];
        
        Map<String,List<Question_Questionnaire__c>> mapGrpQQ=new Map<String,List<Question_Questionnaire__c>>();
        Map<String,List<Question_Questionnaire__c>> mapQuestionQQ=new Map<String,List<Question_Questionnaire__c>>();
        List<Question_Questionnaire__c> lstCloneQQ= new List<Question_Questionnaire__c>();
        List<String> lstBranchedQstnQriIds= new List<String>();
        
        // Update tempalte Id in this loop.
        for (Question_Questionnaire__c pi : lstQuestionQuestionnaire) {
            Question_Questionnaire__c newQQ = pi.clone(false);
            newQQ.Questionnaire__c = cloneqnaire.id;
            lstCloneQQ.add(newQQ);
            if(pi.Is_Allow_Branching__c==true){
                lstBranchedQstnQriIds.add(pi.Id);
            }
        }
        
        // Get the Question dynamic branching             
        List<Questionnaire_Dynamic_Logic__c> lstQstnDynamicLgc = [SELECT Id,Question_Group__c,Question_Option__c,Question_Questionnaire__c,Show_Question_Questionnaire__c 
            FROM Questionnaire_Dynamic_Logic__c WHERE Question_Questionnaire__c IN:lstBranchedQstnQriIds WITH SECURITY_ENFORCED];
        
        Map<String,List<Questionnaire_Dynamic_Logic__c>> mapQstnGrpWithDynQstns=new Map<String,List<Questionnaire_Dynamic_Logic__c>>();
        List<Questionnaire_Dynamic_Logic__c> lstCloneDynLogic=new List<Questionnaire_Dynamic_Logic__c>();
        for(Questionnaire_Dynamic_Logic__c qstnDyn:lstQstnDynamicLgc){
            Questionnaire_Dynamic_Logic__c qstnaireDynLogic=qstnDyn.clone(false);
            lstCloneDynLogic.add(qstnaireDynLogic);
            //qstnaireDynLogic.Question_Group__c=
        }
        // Create the map with Question group as key and value Questionnaire_Dynamic_Logic__c record.
        for(Questionnaire_Dynamic_Logic__c qstnDyn : lstCloneDynLogic){
            if(mapQstnGrpWithDynQstns.containsKey(qstnDyn.Question_Group__c)){
                List<Questionnaire_Dynamic_Logic__c> lstMapQstnDynLgc=mapQstnGrpWithDynQstns.get(qstnDyn.Question_Group__c);
                lstMapQstnDynLgc.add(qstnDyn);
                mapQstnGrpWithDynQstns.put(qstnDyn.Question_Group__c,lstMapQstnDynLgc);
            }
            else{
                List<Questionnaire_Dynamic_Logic__c> lstQstnDynLgc=new List<Questionnaire_Dynamic_Logic__c>();
                lstQstnDynLgc.add(qstnDyn);
                mapQstnGrpWithDynQstns.put(qstnDyn.Question_Group__c,lstQstnDynLgc);
            }
        }
        
        for(Question_Questionnaire__c qq : lstCloneQQ){
            if(mapGrpQQ.containsKey(qq.Question_Group__c)){
                List<Question_Questionnaire__c> lstmapQQ=mapGrpQQ.get(qq.Question_Group__c);
                lstmapQQ.add(qq);
                mapGrpQQ.put(qq.Question_Group__c,lstmapQQ);
            }
            else{
                List<Question_Questionnaire__c> lstQQ=new List<Question_Questionnaire__c>();
                lstQQ.add(qq);
                mapGrpQQ.put(qq.Question_Group__c,lstQQ);
            }
        }
        
        Set<String> qustnGroupIds=mapGrpQQ.keySet();
        List<Question_Questionnaire__c> lstQstnQuriWithNewgrp=new List<Question_Questionnaire__c>();
        List<Questionnaire_Dynamic_Logic__c> lstDynQstnWithNewgrp=new List<Questionnaire_Dynamic_Logic__c>();
        List<Question_Group__c> lstQstnGroup = [SELECT Id,Name,is_Delete__c,Name__c,No_Of_Columns__c,
            Sort_Order__c FROM Question_Group__c WHERE Id IN:qustnGroupIds and is_Delete__c=false WITH SECURITY_ENFORCED];            
        List<Question_Group__c> lstCloneQstnGroup=new List<Question_Group__c>();
        List<Question_Group__c> lstCloneUpdateQstnGroup=new List<Question_Group__c>();
        for(Question_Group__c qstnGroup:lstQstnGroup){
            Question_Group__c cloneQstnGrp=qstnGroup.clone(false);
            system.debug(cloneQstnGrp);
            if(Schema.SObjectType.Question_Group__c.Fields.Name.isCreateable()){
                cloneQstnGrp.Name=qstnGroup.Name+'~'+qstnGroup.id;
            }
            lstCloneQstnGroup.add(cloneQstnGrp);
        }
        if(lstCloneQstnGroup!=null && lstCloneQstnGroup.size()>0){
            Insert lstCloneQstnGroup;

            for(Question_Group__c qstnGroup:lstCloneQstnGroup){
                String name=qstnGroup.Name;
                List<String> nameSplitWithGrpId=name.split('~');
                oldqgroup.put(nameSplitWithGrpId[1],qstnGroup);
                qstnGroup.Name=nameSplitWithGrpId[0];
                lstCloneUpdateQstnGroup.add(qstnGroup);
                List<Question_Questionnaire__c> lstQstnQsri=mapGrpQQ.get(nameSplitWithGrpId[1]);
                List<Questionnaire_Dynamic_Logic__c> lstDynQstns=mapQstnGrpWithDynQstns.get(nameSplitWithGrpId[1]);
                //Update new question group Id in to question_questionnaire record
                if(lstQstnQsri!=null && lstQstnQsri.size()>0){
                    for(Question_Questionnaire__c qq:lstQstnQsri){
                        qq.Question_Group__c=qstnGroup.id;
                        lstQstnQuriWithNewgrp.add(qq);
                    }
                }
                //Update new question group Id in to Dynamic question logic record
                if(lstDynQstns!=null && lstDynQstns.size()>0){
                    for(Questionnaire_Dynamic_Logic__c dynQstn:lstDynQstns){
                        dynQstn.Question_Group__c=qstnGroup.id;
                        lstDynQstnWithNewgrp.add(dynQstn);
                    }
                }
            }
            if(Schema.SObjectType.Question_Group__c.isUpdateable()){
                Update lstCloneUpdateQstnGroup;
            }
        }
        Map<String,List<Question_Questionnaire__c>> mapQstnQuriWithNewQuestions=new Map<String,List<Question_Questionnaire__c>>();
        List<Question_Questionnaire__c> lstQstnQuriWithOutQuestions=new List<Question_Questionnaire__c>();
        // Get all the question related to question_questionnaire
        for(Question_Questionnaire__c qq:lstQstnQuriWithNewgrp){
            if(qq.Question__c!=null){
                if(mapGrpQQ.containsKey(qq.Question__c)){
                    List<Question_Questionnaire__c> lstmapQQ=mapGrpQQ.get(qq.Question__c);
                    lstmapQQ.add(qq);
                    mapQstnQuriWithNewQuestions.put(qq.Question__c,lstmapQQ);
                }
                else{
                    List<Question_Questionnaire__c> lstQQ=new List<Question_Questionnaire__c>();
                    lstQQ.add(qq);
                    mapQstnQuriWithNewQuestions.put(qq.Question__c,lstQQ);
                }
            }
            else{
                lstQstnQuriWithOutQuestions.add(qq);
            }
        }
        
        // Create Map with key as Question_Option__c and value Questionnaire_Dynamic_Logic__c record
        Map<String,List<Questionnaire_Dynamic_Logic__c>> mapmainQstnOptnWithDynQstn=new Map<String,List<Questionnaire_Dynamic_Logic__c>>();
        // Get all the question related to question_questionnaire
        for(Questionnaire_Dynamic_Logic__c qstnDynWithNewGrp:lstDynQstnWithNewgrp){
            if(qstnDynWithNewGrp.Question_Option__c!=null){
                if(mapmainQstnOptnWithDynQstn.containsKey(qstnDynWithNewGrp.Question_Option__c)){
                    List<Questionnaire_Dynamic_Logic__c> lstDynQstn=mapmainQstnOptnWithDynQstn.get(qstnDynWithNewGrp.Question_Option__c);
                    lstDynQstn.add(qstnDynWithNewGrp);
                    mapmainQstnOptnWithDynQstn.put(qstnDynWithNewGrp.Question_Option__c,lstDynQstn);
                }
                else{
                    List<Questionnaire_Dynamic_Logic__c> lstDynlgc=new List<Questionnaire_Dynamic_Logic__c>();
                    lstDynlgc.add(qstnDynWithNewGrp);
                    mapmainQstnOptnWithDynQstn.put(qstnDynWithNewGrp.Question_Option__c,lstDynlgc);
                }
            }
        }
        Set<String> qustionsIds=mapQstnQuriWithNewQuestions.keySet();
        List<Question_Option__c> lstCloneQuestionOptions=new List<Question_Option__c>();
        List<Question_Questionnaire__c> lstCloneQuestionQuestionnaire=new List<Question_Questionnaire__c>();
        List<Question__c> lstQuestions = new List<Question__c>();
        
        lstQuestions=[Select Id,Name,Allow_Attachments__c,Allow_Comment__c,Allow_Currency__c,Category__c,Currency_Symbol__c,Decimal_value__c,Default_Value__c,
        Help_Text__c,Help_Text_Required__c,Is_Approve_For_Library__c,is_Delete__c,Label__c,lookup_Object_API_Name__c,lookup_Object_Field_Name__c,
        Max_Char_Length__c,Maximum_value__c,Metadata__c,Minimum_Value__c,Name__c,No_Of_Columns__c,Question_Library__c,Related_To_Column__c,Required__c,
        Step_Size__c,Type__c,Is_Allow_Branching__c,background_Color__c,
        (Select Id,Name,Index__c,Name__c,Name_Long__c,Question__c,Value__c From Question_Options__r) From Question__c Where Id IN:qustionsIds and is_Delete__c=false WITH SECURITY_ENFORCED];
            
        List<Question__c> lstCloneQstn=new List<Question__c>();
        List<Question__c> lstCloneUpdateQstnName=new List<Question__c>();
        List<String> lstOldQuestionIds=new List<String>();
        for(Question__c question:lstQuestions){
            Question__c cloneQuestion=question.clone(false);
            cloneQuestion.Name=question.Name+'~'+question.id;
            lstCloneQstn.add(cloneQuestion); 
            lstOldQuestionIds.add(question.id);
        }
        // Insert cloned question with old question id append with name.
        if(lstCloneQstn!=null && lstCloneQstn.size()>0){
            if(Schema.SObjectType.Question__c.isCreateable()){                
                Insert lstCloneQstn;
                List<String> ids = new List<String>();
                for(sobject obj : lstCloneQstn){
                    ids.add(String.valueOf(obj.Id));                    
                }
                lstCloneQstn = [Select Id,Name,Allow_Attachments__c, Allow_Comment__c, Allow_Currency__c, Category__c, Currency_Symbol__c, 
                                Decimal_value__c, Default_Value__c, Help_Text_Required__c, Help_Text__c, Is_Allow_Branching__c, 
                                Is_Approve_For_Library__c, Label__c, Max_Char_Length__c, Maximum_value__c, Metadata__c, Minimum_Value__c, 
                                Name__c, No_Of_Columns__c, Question_Library__c, Related_To_Column__c, Required__c, Step_Size__c, Type__c, 
                                background_Color__c, is_Delete__c, lookup_Object_API_Name__c, lookup_Object_Field_Name__c, 
                                Is_MultiSelect__c From Question__c WHERE Id In:ids WITH SECURITY_ENFORCED];
            }

            // Get question options with old question from name and attach new question id with question option.
                
            List<Question_Option__c> lstQstnOptions = [Select Id,Name,Index__c,Name__c,Name_Long__c,Question__c,Value__c From Question_Option__c Where Question__c IN:lstOldQuestionIds WITH SECURITY_ENFORCED];
            
            List<Question_Questionnaire__c> lstOldQstnQueries = [Select Id,Name,Question__c From Question_Questionnaire__c Where Question__c IN:lstOldQuestionIds WITH SECURITY_ENFORCED];
            
            for(Question__c question:lstCloneQstn){
                String name=question.Name;
                List<String> nameSplitWithQstnId=name.split('~');
                question.name=nameSplitWithQstnId[0];
                lstCloneUpdateQstnName.add(question);
                
                // Get question_questionnaire with this old question Id and update new question id.
                List<Question_Questionnaire__c> lstQstnQure=mapQstnQuriWithNewQuestions.get(nameSplitWithQstnId[1]);
                
                for(Question_Questionnaire__c oldQstnQri:lstOldQstnQueries){
                    for(Question_Questionnaire__c qq:lstQstnQure){
                        if(oldQstnQri.Question__c==nameSplitWithQstnId[1]){
                            qq.Question__c=question.id;
                            qq.Name=qq.Name+'~'+oldQstnQri.Id;
                            lstCloneQuestionQuestionnaire.add(qq);
                        }
                    }
                }

                // Update cloned question id in question options                    
                for(Question_Option__c qo:lstQstnOptions){
                    if(qo.Question__c==nameSplitWithQstnId[1]){
                        Question_Option__c cloneQstnOptn=qo.clone(false);
                        cloneQstnOptn.Question__c=question.id;
                        // cloneQstnOptn.Name=qo.Name+'~'+qo.id;
                        cloneQstnOptn.Name_Long__c=qo.Name+'~'+qo.id;
                        lstCloneQuestionOptions.add(cloneQstnOptn);
                    }
                }
            }
            // Update cloned question without old question id
            if(Schema.SObjectType.Question__c.isUpdateable()){
                Update lstCloneUpdateQstnName;
            }
        }
        List<Questionnaire_Dynamic_Logic__c> lstDynQstnWithNewQstnOptions=new List<Questionnaire_Dynamic_Logic__c>();
        List<Questionnaire_Dynamic_Logic__c> lstDynQstnWithNewBranchedQstnQri=new List<Questionnaire_Dynamic_Logic__c>();
        if(lstQstnQuriWithOutQuestions.size()>0 && Schema.SObjectType.Question_Questionnaire__c.isCreateable()){
            Insert lstQstnQuriWithOutQuestions;
        }

        if(lstCloneQuestionOptions.size()>0){
            if(Schema.SObjectType.Question_Option__c.isCreateable()){                
                Insert lstCloneQuestionOptions;
                List<String> ids = new List<String>();
                for(sobject obj : lstCloneQuestionOptions){
                    ids.add(String.valueOf(obj.Id));
                }
                lstCloneQuestionOptions = [SELECT Id,Name,Name_Long__c,Name__c,Question__c FROM Question_Option__c WHERE Id IN:ids WITH SECURITY_ENFORCED];
            }

            List<Question_Option__c> lstUpdateCloneQuestionOptionsName=new List<Question_Option__c>();
            
            for(Question_Option__c newQstnOption:lstCloneQuestionOptions){
                String name=newQstnOption.Name_Long__c;
                List<String> nameSplitOptionId=name.split('~');
                newQstnOption.Name_Long__c=nameSplitOptionId[0];
                lstUpdateCloneQuestionOptionsName.add(newQstnOption);
                List<Questionnaire_Dynamic_Logic__c> lstDynQstns=mapmainQstnOptnWithDynQstn.get(nameSplitOptionId[1]);
                //Update new question Option Id in to Dynamic question logic record
                if(lstDynQstns!=null && lstDynQstns.size()>0){
                    for(Questionnaire_Dynamic_Logic__c dynQstn:lstDynQstns){
                        dynQstn.Question_Option__c=newQstnOption.id;
                        lstDynQstnWithNewQstnOptions.add(dynQstn);
                    }
                }
            }
            if(Schema.SObjectType.Question_Option__c.isUpdateable()){
                Update lstUpdateCloneQuestionOptionsName;
            }
        }
        // Create Map with parent question key of Question_Questionnaire__c and value Questionnaire_Dynamic_Logic__c record
        Map<String,List<Questionnaire_Dynamic_Logic__c>> mapmainQstnQriWithDynQstn=new Map<String,List<Questionnaire_Dynamic_Logic__c>>();
        // Get all the question related to question_questionnaire
        for(Questionnaire_Dynamic_Logic__c qstnDynWithNewQstnOptn:lstDynQstnWithNewQstnOptions){
            if(qstnDynWithNewQstnOptn.Question_Questionnaire__c!=null){
                if(mapmainQstnQriWithDynQstn.containsKey(qstnDynWithNewQstnOptn.Question_Questionnaire__c)){
                    List<Questionnaire_Dynamic_Logic__c> lstDynQstn=mapmainQstnQriWithDynQstn.get(qstnDynWithNewQstnOptn.Question_Questionnaire__c);
                    lstDynQstn.add(qstnDynWithNewQstnOptn);
                    mapmainQstnQriWithDynQstn.put(qstnDynWithNewQstnOptn.Question_Questionnaire__c,lstDynQstn);
                }
                else{
                    List<Questionnaire_Dynamic_Logic__c> lstDynlgc=new List<Questionnaire_Dynamic_Logic__c>();
                    lstDynlgc.add(qstnDynWithNewQstnOptn);
                    mapmainQstnQriWithDynQstn.put(qstnDynWithNewQstnOptn.Question_Questionnaire__c,lstDynlgc);
                }
            }
        }
        if(lstCloneQuestionQuestionnaire.size()>0){
            if(Schema.SObjectType.Question_Questionnaire__c.isCreateable()){                
                Insert lstCloneQuestionQuestionnaire;
                List<String> ids = new List<String>();
                for(sobject obj : lstCloneQuestionQuestionnaire){
                    ids.add(String.valueOf(obj.Id));
                }
                lstCloneQuestionQuestionnaire = [SELECT Id,Name,Allow_Attachments__c, Allow_Comment__c, Allow_Currency__c, Category__c, Comment__c, Currency_Symbol__c, Decimal_value__c, Default_Value__c, Help_Text_Required__c, Help_Text__c, Is_Allow_Branching__c, Max_Char_Length__c, Maximum_value__c, Metadata__c, Minimum_Value__c, No_Of_Columns__c, Points__c, Question_Group__c, Question_Order__c, Question__c, Questionnaire__c, Related_To_Column__c, Required__c, Step_Size__c, background_Color__c, is_Delete__c, lookup_Object_API_Name__c, lookup_Object_Field_Name__c From Question_Questionnaire__c WHERE 
                                                 Id IN:ids WITH SECURITY_ENFORCED];
            }

            List<Question_Questionnaire__c> lstUpdateCloneQuestionQriName=new List<Question_Questionnaire__c>();
            List<Questionnaire_Dynamic_Logic__c> lstDynQstnWithNewMainQstnQri=new List<Questionnaire_Dynamic_Logic__c>();
            // Update main Question_Questionnaire__c in dynamic qstn
            for(Question_Questionnaire__c newQstnQri:lstCloneQuestionQuestionnaire){
                String name=newQstnQri.Name;
                List<String> nameSplitQstnQriId=name.split('~');
                //newQstnQri.Name=nameSplitQstnQriId[0];
                
                List<Questionnaire_Dynamic_Logic__c> lstDynQstns=mapmainQstnQriWithDynQstn.get(nameSplitQstnQriId[1]);
                //Update new question Questionnaire Id in to Dynamic question logic record
                if(lstDynQstns!=null && lstDynQstns.size()>0){
                    for(Questionnaire_Dynamic_Logic__c dynQstn:lstDynQstns){
                        dynQstn.Question_Questionnaire__c=newQstnQri.id;
                        lstDynQstnWithNewMainQstnQri.add(dynQstn);
                    }
                }
            }
            // Create Map with branched question_questionnaire as key and value Questionnaire_Dynamic_Logic__c record
            Map<String,List<Questionnaire_Dynamic_Logic__c>> mapmainBranchedQstnQriWithDynQstn=new Map<String,List<Questionnaire_Dynamic_Logic__c>>();
            // Get all the question related to question_questionnaire
            for(Questionnaire_Dynamic_Logic__c qstnDynWithNewMainQstnQri:lstDynQstnWithNewMainQstnQri){                    
                if(qstnDynWithNewMainQstnQri.Show_Question_Questionnaire__c !=null && mapmainBranchedQstnQriWithDynQstn.containsKey(qstnDynWithNewMainQstnQri.Show_Question_Questionnaire__c)){
                    List<Questionnaire_Dynamic_Logic__c> lstDynQstn=mapmainBranchedQstnQriWithDynQstn.get(qstnDynWithNewMainQstnQri.Show_Question_Questionnaire__c);
                    lstDynQstn.add(qstnDynWithNewMainQstnQri);
                    mapmainBranchedQstnQriWithDynQstn.put(qstnDynWithNewMainQstnQri.Show_Question_Questionnaire__c,lstDynQstn);
                }
                else if(qstnDynWithNewMainQstnQri.Show_Question_Questionnaire__c !=null){
                    List<Questionnaire_Dynamic_Logic__c> lstDynlgc=new List<Questionnaire_Dynamic_Logic__c>();
                    lstDynlgc.add(qstnDynWithNewMainQstnQri);
                    mapmainBranchedQstnQriWithDynQstn.put(qstnDynWithNewMainQstnQri.Show_Question_Questionnaire__c,lstDynlgc);
                }                
            }
            
            // Update branched  question -- Show_Question_Questionnaire__c in dynamic qstn list
            for(Question_Questionnaire__c newQstnQri:lstCloneQuestionQuestionnaire){
                String name=newQstnQri.Name;
                List<String> nameSplitQstnQriId=name.split('~');
                newQstnQri.Name=nameSplitQstnQriId[0];
                lstUpdateCloneQuestionQriName.add(newQstnQri);
                List<Questionnaire_Dynamic_Logic__c> lstDynQstns=mapmainBranchedQstnQriWithDynQstn.get(nameSplitQstnQriId[1]);
                //Update new question Questionnaire Id in to Dynamic question logic record
                if(lstDynQstns!=null && lstDynQstns.size()>0){
                    for(Questionnaire_Dynamic_Logic__c dynQstn:lstDynQstns){
                        dynQstn.Show_Question_Questionnaire__c=newQstnQri.id;
                        lstDynQstnWithNewBranchedQstnQri.add(dynQstn);
                    }
                }
            }
            if(Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
                Update lstUpdateCloneQuestionQriName;
            }
        }
        if(lstDynQstnWithNewBranchedQstnQri.size()>0 && Schema.SObjectType.Questionnaire_Dynamic_Logic__c.isCreateable()){
            Insert lstDynQstnWithNewBranchedQstnQri;
        }
        
        //clone form pagination
        Map<Id,Form_Pagination__c> formPaginations = new Map<Id,Form_Pagination__c>([SELECT Questionnaire__c,Name,Total_Pages__c FROM Form_Pagination__c WHERE Questionnaire__c=:oQnaire.id WITH SECURITY_ENFORCED LIMIT 1]);
        Form_Pagination__c pagination = new Form_Pagination__c();
        if(!formPaginations.isEmpty()){
            pagination.Questionnaire__c = cloneqnaire.Id;
            pagination.Total_Pages__c = formPaginations.values()[0].Total_Pages__c;
            pagination.Name = formPaginations.values()[0].Name;
            Insert pagination;
        }
        
        if(pagination.Id!=null){
            List<Form_Page__c> pageToCreate = new List<Form_Page__c>();
            List<Form_Page__c> pageList = [SELECT Form_Pagination__c, Page_Name__c,Page_No__c,Section__c FROM Form_Page__c WHERE Form_Pagination__c IN:formPaginations.keySet() WITH SECURITY_ENFORCED];
            for (Form_Page__c page : pageList) {
                page.Section__c = page.Section__c.replaceAll('null','');
                for(String str : page.Section__c.split(',')){
                    if(str!='' && oldqgroup.containsKey(str)){
                        page.Section__c = page.Section__c.replace(str,oldqgroup.get(str).Id);
                    }
                }
                pageToCreate.add(new Form_Page__c(Form_Pagination__c=pagination.Id,Section__c=page.Section__c,Page_Name__c=page.Page_Name__c,Page_No__c=page.Page_No__c));
            }
            if(!pageToCreate.isEmpty()){
                Insert pageToCreate;
            }            
        }
        return cloneqnaire.Id;
    }
}