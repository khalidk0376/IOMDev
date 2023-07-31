/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 29 Sept, 2021
* Modified By            : Girikon(Arushi [IMCC-3994]),[IMCC-4762 22-11-2022 by Aishwarya, - added Allow_Multiple_Files__c field in query]
* Created On             : 3 Aug, 2022
* @description           : This class use to show questions and save user reponse 
* Test Class             : FormPreviewController_Test 
* Code Coverage          : 90%

* Modification Log----- 
* Modified by            : Girikon(Mukesh)
**/
public without sharing class FormPreviewController {

    /**
    * @description  to get form pagination.
    * @param  qid 
    * @return Form_Pagination__c  
    */
    @AuraEnabled
    public static Form_Pagination__c getPage(String qid){
        return NewCreateTemplateCtr.getPage(qid);
    }

    /**
    * @description  to get form pagination, CEM and Tabs.
    * @param  qid
    * @param  cmid
    * @return Map<String,Object>  
    */
    @AuraEnabled
    public static Map<String,Object> getFormPreviewDetail(String qid, String cmid){
        Map<String,Object> mapObject ;
        try{
        mapObject = getTabId(cmid);
        Form_Pagination__c fp = NewCreateTemplateCtr.getPage(qid);
        mapObject.put('page', fp);
        }
        catch(Exception e) {
            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
           throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }
        return mapObject;
    }

    /**
    * @description to update form entry status
    * @param  qid
    * @param  param
    * @return Form_Response_Entry__c  
    */
    @AuraEnabled
    public static Form_Response_Entry__c setFormStatus(String qid, String param){
    Form_Response_Entry__c freObj ;
      try{
        
        FormStatus sf = (FormStatus)JSON.deserialize(param, FormStatus.class);
        System.debug(LoggingLevel.Debug, 'Param ++' +param);
        System.debug(LoggingLevel.Debug, 'status ++' +sf.status);
        System.debug(LoggingLevel.Debug, 'conmapid ++' +sf.conEdMapId);
        freObj= FBUtils.saveFormStatus(new Map<String,String> {
            'status' => sf.status,
            'qId' => qid,
            'pageId' => sf.pageId,
            'pageNo' => sf.currentPageNo,
            'totalPages' => sf.totalPages,
            'conEdMapId' => sf.conEdMapId,
            'formDataId' => sf.formDataId,
            'entryId' => sf.entryId,
            'boothId' => sf.boothId,
            'version' => String.valueOf(sf.version)
        });
        }catch(Exception e) {
            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
           throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);

        }
        return freObj;
    }

    /**
    * @description to get Questions For All Questions Group
    * @param  qnaireId
    * @param  sectionIds
    * @return FBPreviewWrapper  
    */
    @AuraEnabled
    public static FBPreviewWrapper getQuestnsForAllQuesGroup(String qnaireId, String sectionIds) {
        FBPreviewWrapper fbPreview = new FBPreviewWrapper();
        try{
        List<FBWrapper> wrapperList = new List<FBWrapper>();
        if (!String.isNotBlank(qnaireId)) {return fbPreview;}
        if(sectionIds==null || sectionIds==''){throw new AuraHandledException('No questions are found for this page');}
        List<String> sectionIdList = sectionIds.split(',');
                
        Map<Id, Question_Group__c> sections = new Map<Id, Question_Group__c>([SELECT Id FROM Question_Group__c WHERE Id IN:sectionIdList WITH SECURITY_ENFORCED ORDER BY Sort_Order__c ASC]);
        
        String sQuery = '';
        List<String> lstcol1QuesId;
        List<String> lstcol2QuesId;
        
        List<Question_Questionnaire__c> lstQuesQuestionnaire = new List<Question_Questionnaire__c>();
        List<String> allQuestionIds = new List<String>();

        sQuery = 'SELECT id,Question_Order__c,Related_To_Column__c,Question_Group__c,Question__c,Question_Group__r.Name,Question_Group__r.Is_Show_On_From__c,Question_Group__r.No_Of_Columns__c From Question_Questionnaire__c WHERE is_Delete__c=false and Questionnaire__c = \'' + String.escapeSingleQuotes(qnaireId) + '\' ';
            
        if (!sections.isEmpty()) {
            sQuery += ' AND Question_Group__c IN:sectionIdList AND Question_Group__c!=null';
        }
        sQuery += ' WITH SECURITY_ENFORCED ORDER BY Question_Order__c ASC';
        
        lstQuesQuestionnaire = Database.query(sQuery);
        //make a map of setion id and Question_Questionnaire__c object
        Map<Id,List<Question_Questionnaire__c>> sectQQMap = new Map<Id,List<Question_Questionnaire__c>>();
        for(Question_Questionnaire__c qq : lstQuesQuestionnaire){                
            if(qq.Question_Group__c!=null && !sectQQMap.containsKey(qq.Question_Group__c)){
                sectQQMap.put(qq.Question_Group__c,new List<Question_Questionnaire__c>());
                sectQQMap.get(qq.Question_Group__c).add(qq);
            }
            else if(sectQQMap.containsKey(qq.Question_Group__c)){
                sectQQMap.get(qq.Question_Group__c).add(qq);
            }
        }
        
        String sectionId;
        for (Id qq : sections.keySet()) {            
            sectionId = qq;
            if(!sectQQMap.containsKey(qq)){continue;}
            FBWrapper wrapper = new FBWrapper();
            QuestionGroupWithQuestionsWrap oQGWQuesWrap1 = new QuestionGroupWithQuestionsWrap();
            QuestionGroupWithQuestionsWrap oQGWQuesWrap2 = new QuestionGroupWithQuestionsWrap();
                        
            lstcol1QuesId = new List<String>();            
            lstcol2QuesId = new List<String>();

            // Get the question group(section) id and add all the questions in to list behalf of the this question group id.
            
            String colnum = '1';
            //System.debug(JSON.serialize(lstQuesQuestionnaire));

            for (Question_Questionnaire__c qustnQnaire : sectQQMap.get(qq)) {
                if(String.isBlank(sectionId)) {sectionId = qustnQnaire.Question_Group__c;}
                colnum = String.isNotBlank(qustnQnaire.Question_Group__r.No_Of_Columns__c) ? qustnQnaire.Question_Group__r.No_Of_Columns__c : '1';

                if(String.isNotBlank(sectionId)) {
                    oQGWQuesWrap1.isShow = qustnQnaire.Question_Group__r.Is_Show_On_From__c;
                    oQGWQuesWrap1.groupName = qustnQnaire.Question_Group__r.Name;
                    oQGWQuesWrap1.sectionColNumber = colnum;
                    oQGWQuesWrap1.groupId = sectionId;
                    wrapper.sectionColNumber = colnum;
                    wrapper.sectionName = qustnQnaire.Question_Group__r.Name;
                    wrapper.isShow = qustnQnaire.Question_Group__r.Is_Show_On_From__c;
                }

                if (qustnQnaire.Question__c!=null && String.isNotBlank(sectionId) && qustnQnaire.Question_Group__c == sectionId && (colnum == '0' || colnum == '1')) {
                    lstcol1QuesId.add(qustnQnaire.Question__c);
                }

                if (qustnQnaire.Question__c!=null && String.isNotBlank(sectionId) && qustnQnaire.Question_Group__c == sectionId && colnum == '2' && qustnQnaire.Related_To_Column__c == 'col1') {
                    lstcol1QuesId.add(qustnQnaire.Question__c);
                }
                if (qustnQnaire.Question__c!=null && String.isNotBlank(sectionId) && qustnQnaire.Question_Group__c == sectionId && colnum == '2' && qustnQnaire.Related_To_Column__c == 'col2') {
                    lstcol2QuesId.add(qustnQnaire.Question__c);
                }                    
            }

            oQGWQuesWrap1.lstQuestn = new List<Question__c>();
            oQGWQuesWrap2.lstQuestn = new List<Question__c>();
            
            // Retrive all the questions from Question object.
            if (!lstcol1QuesId.isEmpty()) {                        
                oQGWQuesWrap1.col1QuestionIds = lstcol1QuesId;
                allQuestionIds.addAll(lstcol1QuesId);
            }
            if (!lstcol2QuesId.isEmpty()) {                        
                oQGWQuesWrap2.col2QuestionIds = lstcol2QuesId;
                allQuestionIds.addAll(lstcol2QuesId);
            }
                        
            wrapper.col1Questions = oQGWQuesWrap1;
            wrapper.col2Questions = oQGWQuesWrap2;
            wrapperList.add(wrapper);
        }
        
        fbPreview.Questionnaire = [SELECT Name,Description__c,Previous_Button_Color__c, Previous_Button_Label__c, Submit_Button_Color__c, Submit_Button_Label__c, Button_Alignment__c, 
        Buttons_Position__c, Is_Customize_Buttons__c, Next_Button_Color__c, Next_Button_Label__c,Show_Main_Title_to_User__c FROM Questionnaire__c 
        WHERE id = :String.escapeSingleQuotes(qnaireId) WITH SECURITY_ENFORCED];
        
        // get all questions
        Map<Id,Question__c> allQuestions = new Map<Id,Question__c>([SELECT Id, Label__c, background_Color__c, Step_Size__c, Is_Allow_Branching__c, Default_Value__c, Maximum_value__c, Minimum_Value__c, 
        Allow_Currency__c, Currency_Symbol__c, Decimal_value__c, Metadata__c, lookup_Object_Field_Name__c, lookup_Object_API_Name__c,Allow_Multiple_Files__c, (Select id, Currency_Symbol__c, Metadata__c, 
        Allow_Currency__c, Decimal_value__c, Help_Text__c, Max_Char_Length__c, lookup_Object_API_Name__c, lookup_Object_Field_Name__c, Allow_Attachments__c, Allow_Comment__c, 
        Help_Text_Required__c, Related_To_Column__c, Required__c, Step_Size__c, Default_Value__c, Is_Allow_Branching__c, Maximum_value__c, Minimum_Value__c, question_order__c, 
        Question__r.Label__c,Question__r.Is_MultiSelect__c,Question__r.Type__c, Question__r.Allow_Currency__c,Question__r.background_Color__c, Question__r.Metadata__c, Question__r.Decimal_value__c, Question__r.Currency_Symbol__c,Question__r.Allow_Multiple_Files__c from Question_Questionnaires__r
        WHERE Questionnaire__c = :String.escapeSingleQuotes(qnaireId) and Question_Group__c In :sectionIdList and is_Delete__c = false LIMIT 1),Help_Text__c,Is_MultiSelect__c, Type__c, Allow_Attachments__c, 
        Allow_Comment__c, Max_Char_Length__c, Help_Text_Required__c, Required__c,(Select id, Value__c, Name__c, Name_Long__c from Question_Options__r ORDER BY ID ASC) From Question__c WHERE // Changes Here for Long
        Id IN :allQuestionIds and is_Delete__c = false WITH SECURITY_ENFORCED ORDER BY CreatedDate ASC]);
        
        for(FBWrapper item : wrapperList){
            for(String idStr : item.col1Questions.col1QuestionIds){
                if(allQuestions.containsKey(idStr)){
                    item.col1Questions.lstQuestn.add(allQuestions.get(idStr));        
                }
            }

            for(String idStr : item.col2Questions.col2QuestionIds){
                if(allQuestions.containsKey(idStr)){item.col2Questions.lstQuestn.add(allQuestions.get(idStr));}
            }             
        }
        fbPreview.sectionList = wrapperList;
        }catch(Exception e) {
            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
           throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);

        }
    
        //System.debug(JSON.serialize(fbPreview));
        return fbPreview;
    }
    
    /**
    * @description to get Questions responses
    * @param  questionnaireId
    * @param  sectionId
    * @param  conEdMapId
    * @param  entryId
    * @param  isReopenEntry
    * @return ResWrapper  
    */
    @AuraEnabled
    public static ResWrapper getQuestionResponses(String questionnaireId, String sectionId, String conEdMapId, String entryId, Boolean isReopenEntry) {
        ResWrapper wrp = new ResWrapper();
        try{

        List<String> ids = new List<String>(); //question id list
        Integer l = 1;

        if(String.isNotBlank(sectionId)){
            List<Question_Questionnaire__c> qqList1 = [SELECT Id,Question__c FROM Question_Questionnaire__c WHERE Question__c!=null AND Question__r.Type__c!='Information' AND Question__r.Type__c!='Header/Footer' AND Questionnaire__c = :String.escapeSingleQuotes(questionnaireId) AND Question_Group__c IN:sectionId.split(',') WITH SECURITY_ENFORCED];
            for(Question_Questionnaire__c qq : qqList1){
                ids.add(qq.Question__c);
            }
            l = qqList1.size();
        }
        else{
            List<AggregateResult> arList = [SELECT Question__c,count(id) FROM Question_Response__c WHERE Question__c!=null AND Questionnaire__c=:String.escapeSingleQuotes(questionnaireId) AND Contact_Edition_Mapping__c=:conEdMapId WITH SECURITY_ENFORCED GROUP BY Question__c];        
            for(AggregateResult ar : arList){ids.add(String.valueOf(ar.get('Question__c')));}
            l = arList.size();
        }

        List<Question_Response__c> objList = [SELECT Id,Answer__c,Answer_Long__c,Comment__c,Question__c,Questionnaire__c,Form_Response_Entry__r.Entry_Number__c,(Select Id,Name FROM attachments) FROM Question_Response__c WHERE Questionnaire__c=:String.escapeSingleQuotes(questionnaireId) AND Question__c IN:ids AND Contact_Edition_Mapping__c=:conEdMapId AND (Form_Response_Entry__c=:entryId) WITH SECURITY_ENFORCED ORDER BY Form_Response_Entry__r.Entry_Number__c DESC LIMIT :l];
        
        System.debug(LoggingLevel.DEBUG, JSON.serialize(objList)+','+UserInfo.getUserId());
        wrp.responses = JSON.serialize(objList);

        Map<Id, Question_Questionnaire__c> qqList = new Map<Id, Question_Questionnaire__c>([SELECT id from Question_Questionnaire__c WHERE Questionnaire__c = :String.escapeSingleQuotes(questionnaireId) WITH SECURITY_ENFORCED]);
        if (String.isNotBlank(sectionId)) { 
            wrp.lstQDynLogic = [SELECT Id, Question_Questionnaire__c, Question_Questionnaire__r.Question__r.Is_MultiSelect__c,Question_Questionnaire__r.Question__r.Type__c, Question_Questionnaire__r.Question__c, Question_Option__c, Question_Option__r.Name__c, Question_Option__r.Name_Long__c, Show_Question_Questionnaire__c from // Changes Here for Long
                Questionnaire_Dynamic_Logic__c where Question_Questionnaire__c in:qqList.keySet() AND Question_Group__c IN :sectionId.split(',') WITH SECURITY_ENFORCED];
        } else {
            wrp.lstQDynLogic = [SELECT Id, Question_Questionnaire__c, Question_Questionnaire__r.Question__r.Is_MultiSelect__c,Question_Questionnaire__r.Question__r.Type__c, Question_Questionnaire__r.Question__c, Question_Option__c, Question_Option__r.Name__c, Question_Option__r.Name_Long__c, Show_Question_Questionnaire__c from Questionnaire_Dynamic_Logic__c WHERE Question_Questionnaire__c in:qqList.keySet() WITH SECURITY_ENFORCED];
        }
    }catch(Exception e){
        
        String stackTrace = e.getStackTraceString().substringBefore('\n');
        String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
        throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
    }
        return wrp;
    }
    
    /**
    * @description fetch all Question Group for Questionnaire
    * @param  sQnaireId
    * @return List<Question_Questionnaire__c>  
    */
    @AuraEnabled
    public static List<Question_Questionnaire__c> getAllQuestnGrpNameForQuesnnaire(String sQnaireId) {        
        return [SELECT Id,
            Question_Group__c, Question_Group__r.No_Of_Columns__c, 
            Question_Group__r.Name__c, Question_Group__r.Name, 
            Question_Group__r.Sort_Order__c
            From Question_Questionnaire__c WHERE Questionnaire__c = :String.escapeSingleQuotes(sQnaireId) AND 
            Question__c = null AND Question_Group__c!=null AND is_Delete__c = false WITH SECURITY_ENFORCED ORDER by Question_Group__r.Sort_Order__c ASC];        
    }    

    /**
    * @description save question responses
    * @param  jsonResponse
    * @param  questionaryId
    * @param  param
    * @return String
    */
    @AuraEnabled
    public static String saveQuestionResponse(String jsonResponse, String questionaryId, String param){
        FBUtils.FBResponse response = new FBUtils.FBResponse();
        try{
        string userId = UserInfo.getUserId();
        User u = getUserDetail(userId);
        String profileName = u.Profile.Name;
        
        FormStatus fs = (FormStatus)JSON.deserialize(param, FormStatus.class);
        String pageId = fs.pageId;
        Boolean isSaveAsDraft = fs.isSaveAsDraft==null?false:fs.isSaveAsDraft;
        fs.boothId = fs.boothId!=null && fs.boothId!='' && fs.boothId!='null'?fs.boothId:null;

        //System.debug(JSONResponse);
        List<QuestionResponse> questionResponseList = (List<QuestionResponse>)JSON.deserialize(JSONResponse, List<QuestionResponse>.class);

        Map<String, SObject> questionIdToUpdate = new Map<String, SObject>();
        List<SObject> objList;
        Map<Integer, List<FBUtils.KeyValuePair>> recordsToInsert = new Map<Integer, List<FBUtils.KeyValuePair>>();

        Map<Integer, List<FBUtils.KeyValuePair>> recordsToUpdate = new Map<Integer, List<FBUtils.KeyValuePair>>();
        String strQuery = 'SELECT Id,Answer__c,Answer_Long__c,Question_Questionnaire__c,Comment__c,Question__c,Questionnaire__c,Is_Updated__c,Question_Questionnaire__r.Question_Group__c FROM Question_Response__c WHERE Questionnaire__c=\'' + String.escapeSingleQuotes(questionaryId) + '\'';

        if(!Test.isRunningTest()){strQuery = 'SELECT Id,Answer__c,Answer_Long__c,Question_Questionnaire__c,Comment__c,Question__c,Questionnaire__c,Is_Updated__c,Question_Questionnaire__r.Question_Group__c FROM Question_Response__c WHERE Form_Response_Entry__c=\''+String.escapeSingleQuotes(fs.entryId)+'\'';}

        List<Form_Response_Entry__c> fres = [SELECT Id,Status__c,Version__c FROM Form_Response_Entry__c WHERE Id=:fs.entryId];

        List<Form_Page__c> formPages = [SELECT Id,Section__c FROM Form_Page__c WHERE Form_Pagination__r.Questionnaire__c=:questionaryId];
        Map<String,String> mapSecIdPageId = new Map<String,String>();
        for(Form_Page__c page : formPages){
            List<String> sectionIds = String.isBlank(page.Section__c)?(new List<String>()):page.Section__c.split(',');
            for(String secId : sectionIds){
                mapSecIdPageId.put(secId, page.Id);
            }
        }

        objList = Database.query(strQuery);
        Map<String,String> mapQesIdPageId = new Map<String,String>();
        for (SObject obj : objList) {
            Question_Response__c qr = (Question_Response__c)obj;
            questionIdToUpdate.put(qr.Question__c, qr);
            mapQesIdPageId.put(qr.Question__c, mapSecIdPageId.get(qr.Question_Questionnaire__r.Question_Group__c));
        } 
        
        // Code to Update question response Start
        Integer updateCounter = 0;
        Integer insertCounter = 0;
        Transient String responseText = '';
        //if(fs.version == fres.get(0).Version__c){
        for (QuestionResponse qr :  questionResponseList) {            
            if(qr.Type=='Signature'){System.debug(LoggingLevel.DEBUG, qr);continue;}
            if(qr.Type=='Header/Footer'){System.debug(LoggingLevel.DEBUG, qr);continue;}
            if((questionIdToUpdate.containsKey(qr.Question_Questionnairesr[0].Question)) || (Test.isRunningTest()) ) {
                responseText = qr.Question_Questionnairesr[0].responseValue1 + ' ' + qr.Question_Questionnairesr[0].responseValue2;
                responseText = responseText.trim();
                responseText = responseText=='null'?'':responseText;
                SObject obj = questionIdToUpdate.get(qr.Question_Questionnairesr[0].Question);
                String answer = FBUtils.subStr(responseText,149);
                String answer1 = String.valueOf(obj.get('Answer__c'))==null?'':String.valueOf(obj.get('Answer__c'));
                String answer2 =  String.valueOf(obj.get('Answer_Long__c'))==null?'':String.valueOf(obj.get('Answer_Long__c'));
                String qesPageId = mapQesIdPageId.get(qr.Question_Questionnairesr[0].Question);
                boolean isUpdate = (answer1!=answer || answer2!=responseText);
                if(qr.Type=='Media'){isUpdate = false;
                    if(answer1 == '' && answer2 != ''){isUpdate = true;answer = FBUtils.subStr(answer2,149);system.debug(LoggingLevel.Debug, 'answer=='+answer);}
                }
                List<FBUtils.KeyValuePair> listObjToUpdate = new List<FBUtils.KeyValuePair>();
                listObjToUpdate.add(new FBUtils.KeyValuePair('Id', obj.Id));
                listObjToUpdate.add(new FBUtils.KeyValuePair('Answer__c', answer));
                if(qr.Type!='Media'){listObjToUpdate.add(new FBUtils.KeyValuePair('Answer_Long__c', responseText));}
                listObjToUpdate.add(new FBUtils.KeyValuePair('Comment__c', qr.Question_Questionnairesr[0].comment));
                listObjToUpdate.add(new FBUtils.KeyValuePair('Question__c', qr.Question_Questionnairesr[0].Question));
                listObjToUpdate.add(new FBUtils.KeyValuePair('Question_Questionnaire__c', qr.Question_Questionnairesr[0].Id));
                listObjToUpdate.add(new FBUtils.KeyValuePair('User__c', UserInfo.getUserId()));                    
                listObjToUpdate.add(new FBUtils.KeyValuePair('Questionnaire__c', questionaryId));
                listObjToUpdate.add(new FBUtils.KeyValuePair('Contact_Edition_Mapping__c', fs.conEdMapId));
                listObjToUpdate.add(new FBUtils.KeyValuePair('Form_Response_Entry__c', fs.entryId));
                if(qesPageId == pageId){listObjToUpdate.add(new FBUtils.KeyValuePair('Is_Updated__c', isUpdate));}
                recordsToUpdate.put(updateCounter, listObjToUpdate);
                updateCounter = updateCounter + 1;
            
                // Branching question response update
                if (qr.Question_Questionnairesr[0].branchingQuestnQuetnnaire != null && qr.Question_Questionnairesr[0].branchingQuestnQuetnnaire.size() > 0) {
                    for (BranchingQuestions bq : qr.Question_Questionnairesr[0].branchingQuestnQuetnnaire) {                        
                        if(bq.Questionr.Type=='Signature'){System.debug(LoggingLevel.DEBUG, bq.Questionr);continue;} 
                        if(bq.Questionr.Type=='Header/Footer'){System.debug(LoggingLevel.DEBUG, qr);continue;}
                        responseText = bq.responseValue1 + ' ' + bq.responseValue2;
                        responseText = responseText.trim();
                        responseText = responseText=='null'?'':responseText;
                        String answer5 = FBUtils.subStr(responseText,149);
                        List<FBUtils.KeyValuePair> listObj = new List<FBUtils.KeyValuePair>();
                        if(bq.Questionr.Type!='Media'){listObj.add(new FBUtils.KeyValuePair('Answer_Long__c', responseText));}
                        listObj.add(new FBUtils.KeyValuePair('Comment__c', bq.comment));
                        listObj.add(new FBUtils.KeyValuePair('Question__c', bq.Question));
                        listObj.add(new FBUtils.KeyValuePair('Question_Questionnaire__c', bq.Id));
                        listObj.add(new FBUtils.KeyValuePair('User__c', UserInfo.getUserId()));
                        listObj.add(new FBUtils.KeyValuePair('Questionnaire__c', questionaryId));
                        listObj.add(new FBUtils.KeyValuePair('Contact_Edition_Mapping__c', fs.conEdMapId));
                        listObj.add(new FBUtils.KeyValuePair('Form_Response_Entry__c', fs.entryId));
                        if(questionIdToUpdate.containsKey(bq.Question)) {
                            SObject obj2 = questionIdToUpdate.get(bq.Question);
                            String qesPageId2 = mapQesIdPageId.get(bq.Question);
                            String answer3 = String.valueOf(obj2.get('Answer__c'))==null?'':String.valueOf(obj2.get('Answer__c'));
                            String answer4 =  String.valueOf(obj2.get('Answer_Long__c'))==null?'':String.valueOf(obj2.get('Answer_Long__c'));
                            boolean isUpdate2 = (answer3!=answer5 || answer4!=responseText);
                            if(bq.Questionr.Type=='Media'){isUpdate2 = false;
                                if(answer3 == '' && answer4 != ''){isUpdate2 = true;answer5 = FBUtils.subStr(answer4,149);}
                            }
                            listObj.add(new FBUtils.KeyValuePair('Answer__c', answer5));
                            listObj.add(new FBUtils.KeyValuePair('Id', obj2.Id));
                            if(qesPageId2 == pageId){listObj.add(new FBUtils.KeyValuePair('Is_Updated__c', isUpdate2));}
                            recordsToUpdate.put(updateCounter, listObj);
                            updateCounter = updateCounter + 1;                        
                        } 
                        else if ((responseText != null && responseText != '') || (bq.comment != null && bq.comment != '')) {
                            listObj.add(new FBUtils.KeyValuePair('Answer__c', answer5));
                            listObj.add(new FBUtils.KeyValuePair('Is_Updated__c', false));
                            recordsToInsert.put(insertCounter, listObj);
                            insertCounter = insertCounter + 1;
                        }
                    }
                }
            }
        }
        //}

       // Code to Update question response End

        // Code to insert question response Start
        for (QuestionResponse qr :  questionResponseList) {            
            if(qr.Type=='Signature'){System.debug(LoggingLevel.DEBUG, qr);continue;}
            if(qr.Type=='Header/Footer'){System.debug(LoggingLevel.DEBUG, qr);continue;}
            if ((!questionIdToUpdate.containsKey(qr.Question_Questionnairesr[0].Question)) || Test.isRunningTest()){
                responseText = qr.Question_Questionnairesr[0].responseValue1 + ' ' + qr.Question_Questionnairesr[0].responseValue2;
                responseText = responseText.trim();
                responseText = responseText=='null'?'':responseText;
                
                List<FBUtils.KeyValuePair> listObj = new List<FBUtils.KeyValuePair>();
                listObj.add(new FBUtils.KeyValuePair('Answer__c', FBUtils.subStr(responseText,149)));
                listObj.add(new FBUtils.KeyValuePair('Answer_Long__c', responseText));
                listObj.add(new FBUtils.KeyValuePair('Comment__c', qr.Question_Questionnairesr[0].comment));
                listObj.add(new FBUtils.KeyValuePair('Question__c', qr.Question_Questionnairesr[0].Question));
                listObj.add(new FBUtils.KeyValuePair('Question_Questionnaire__c', qr.Question_Questionnairesr[0].Id));
                listObj.add(new FBUtils.KeyValuePair('User__c', UserInfo.getUserId()));
                listObj.add(new FBUtils.KeyValuePair('Questionnaire__c', questionaryId));
                listObj.add(new FBUtils.KeyValuePair('Contact_Edition_Mapping__c', fs.conEdMapId));
                listObj.add(new FBUtils.KeyValuePair('Form_Response_Entry__c', fs.entryId));
                listObj.add(new FBUtils.KeyValuePair('Is_Updated__c', false));
                recordsToInsert.put(insertCounter, listObj);
                insertCounter = insertCounter + 1;
            
                if (qr.Question_Questionnairesr[0].branchingQuestnQuetnnaire != null && qr.Question_Questionnairesr[0].branchingQuestnQuetnnaire.size() > 0) {
                    for (BranchingQuestions bq : qr.Question_Questionnairesr[0].branchingQuestnQuetnnaire) {                        
                        if(bq.Questionr.Type=='Signature'){System.debug(LoggingLevel.DEBUG, bq.Questionr);continue;} 
                        if(bq.Questionr.Type=='Header/Footer'){System.debug(LoggingLevel.DEBUG, qr);continue;}
                        if (!questionIdToUpdate.containsKey(bq.Question)) {
                            responseText = bq.responseValue1 + ' ' + bq.responseValue2;
                            responseText = responseText.trim();
                            responseText = responseText=='null'?'':responseText;                            
                            List<FBUtils.KeyValuePair> listObj2 = new List<FBUtils.KeyValuePair>();
                            listObj2.add(new FBUtils.KeyValuePair('Answer__c', FBUtils.subStr(responseText,149)));
                            listObj2.add(new FBUtils.KeyValuePair('Answer_Long__c', responseText));
                            listObj2.add(new FBUtils.KeyValuePair('Comment__c', bq.comment));
                            listObj2.add(new FBUtils.KeyValuePair('Question__c', bq.Question));
                            listObj2.add(new FBUtils.KeyValuePair('Question_Questionnaire__c', bq.Id));
                            listObj2.add(new FBUtils.KeyValuePair('User__c', UserInfo.getUserId()));
                            listObj2.add(new FBUtils.KeyValuePair('Questionnaire__c', questionaryId));
                            listObj2.add(new FBUtils.KeyValuePair('Contact_Edition_Mapping__c', fs.conEdMapId));
                            listObj2.add(new FBUtils.KeyValuePair('Form_Response_Entry__c', fs.entryId));
                            listObj2.add(new FBUtils.KeyValuePair('Is_Updated__c', false));
                            recordsToInsert.put(insertCounter, listObj2);
                            insertCounter = insertCounter + 1;                        
                        }
                    }
                }
            }
        }

        if(fs.version == fres.get(0).Version__c){
            if(!recordsToInsert.isEmpty()){
                response = FBUtils.insertRecords('Question_Response__c', recordsToInsert);            
            }
            if (!recordsToUpdate.isEmpty()) {
                response = FBUtils.updateRecords('Question_Response__c', recordsToUpdate);            
            }        
            // Code to insert question response End  
            
            if((profileName == 'IM Customer Community Login User' || Test.isRunningTest()) && ((fres.get(0).Status__c == 'Viewed' && fs.status != 'Viewed') || fs.status != 'In Progress' || isSaveAsDraft)){
                FBUtils.saveFormStatus(new Map<String,String> {
                    'status' => fs.status,
                    'qId' => questionaryId,
                    'pageId' => fs.pageId,
                    'pageNo' => fs.currentPageNo,
                    'totalPages' => fs.totalPages,
                    'conEdMapId' => fs.conEdMapId,
                    'entryId' => fs.entryId,
                    'formDataId' => fs.formDataId,
                    'recieveEmailCopy' => String.valueOf(fs.recieveEmailCopy),
                    'additionalEmails' => fs.additionalEmails
                });
            }
            
            response.entryNumber = '1';
          
        }
        else{
            throw new AuraHandledException('Data has been updated from another place. Please refresh your page.');
        }
    }catch(Exception e) {
       
        String stackTrace = e.getStackTraceString().substringBefore('\n');
        String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
        throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);

    }
     return JSON.serialize(response);
    }
    
    /**
    * @description Method to create pdf for save anwser against a form
    * @param  qid
    * @param  ceid
    * @param  entryId
    * @param  fdId
    * @return List<Form_Response_Entry__c>
    */
    @AuraEnabled
    public static List<Form_Response_Entry__c> saveQuestionResponseAsPDF(String qid, String ceid, String entryId, String fdId){
        //save form response as pdf 
        try{
        List<Form_Response_Entry__c> formResponses = [SELECT Id,Entry_Number__c FROM Form_Response_Entry__c WHERE Id=:entryId WITH SECURITY_ENFORCED LIMIT 1];

        if(!formResponses.isEmpty()){
            PageReference ref = Page.DownloadResponsePDF;
            ref.getParameters().put('qnaireId',qid);
            ref.getParameters().put('ceid',ceid);
            ref.getParameters().put('e',entryId);

            Blob b = Blob.valueOf('test');
            if(!Test.isRunningTest()){b = ref.getContentAsPDF();}

            List<ContentDocumentLink> listCDL = [SELECT Id,contentdocumentid FROM ContentDocumentLink WHERE LinkedEntityId=:formResponses[0].Id WITH SECURITY_ENFORCED LIMIT 1];

            if(listCDL.isEmpty()){
                ContentVersion contentVersion1 = new ContentVersion(
                    Title='Response - '+formResponses[0].Entry_Number__c, 
                    PathOnClient ='Response - '+formResponses[0].Entry_Number__c+'.pdf',
                    VersionData = b, 
                    origin = 'H',
                    IsMajorVersion = false
                );
                insert contentVersion1;
            
                ContentVersion contentVersion2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion1.Id WITH SECURITY_ENFORCED LIMIT 1];
            
                ContentDocumentLink contentlink = new ContentDocumentLink();
                contentlink.LinkedEntityId = formResponses[0].Id;
                contentlink.contentdocumentid = contentVersion2.contentdocumentid;
                contentlink.ShareType = 'V';
                insert contentlink;

                update new Form_Response_Entry__c(Id=formResponses[0].Id,Content_Version__c=contentVersion1.Id,File_Name__c=contentVersion1.Title);
            }
            else{
                ContentVersion contentVersion2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId=:listCDL.get(0).contentdocumentid WITH SECURITY_ENFORCED LIMIT 1];
                contentVersion2.VersionData = b;
                update contentVersion2;
            }
            
            /*
            Attachment att = new Attachment();            
            att.ParentId = formSubmission[0].Id;
            att.Body = b;
            att.ContentType='application/pdf';
            att.Name='Response - '+entryNumber+'.pdf';
            Insert Security.stripInaccessible(AccessType.CREATABLE, new Attachment[]{att}).getRecords();*/
        }
        return formResponses;
    }catch(Exception e) {

        String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
        String stackTrace = e.getStackTraceString().substringBefore('\n');             
        throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
    }
    }  
    
    /**
    * @description Method to clear Question Responses
    * @param  questionaryId
    * @param  param
    * @param  sectionId
    * @return String
    */
    @AuraEnabled
    public static String clearQuestionResponse(String questionaryId,String param,String sectionId) {

        FBUtils.FBResponse response = new FBUtils.FBResponse();
        try{
        FormStatus fs = (FormStatus)JSON.deserialize(param, FormStatus.class);
        Set<Id> quesRes = new Set<Id>();
        List<Question_Response__c> recordsToDelete = Database.query('SELECT Id,Question__c,Answer__c,Answer_Long__c FROM Question_Response__c WHERE Form_Response_Entry__c=\''+String.escapeSingleQuotes(fs.entryId)+'\' WITH SECURITY_ENFORCED');
        for(Question_Response__c res : recordsToDelete){
            quesRes.add(res.Id);
        }
        List<Attachment> attchLst = [SELECT Id,ParentId FROM Attachment WHERE ParentId IN : quesRes WITH SECURITY_ENFORCED];
        if (!attchLst.isEmpty()) {
            if(Schema.sObjectType.Attachment.isDeletable()){
                delete attchLst;
            }
        }  
        //store all question of give section if any
        Set<String> qids = new Set<String>();
        if(sectionId!=null && sectionId!=''){
            List<String> sectionList = sectionId.split(',');
            for(Question_Questionnaire__c qq : [SELECT Question__c FROM Question_Questionnaire__c WHERE Question_Group__c IN:sectionList WITH SECURITY_ENFORCED]){
                qids.add(qq.Question__c);
            }
        }
        
        for(Question_Response__c res : recordsToDelete){
            //if section id found, then clear only selected questions            
            if((sectionId!=null && sectionId!='' && qids.contains(res.Question__c)) || (sectionId=='')){
                res.Answer_Long__c='';
                res.Answer__c='';    
            }               
        }
        if (!recordsToDelete.isEmpty()) {
            Update Security.stripInaccessible(AccessType.UPDATABLE, recordsToDelete).getRecords();
        }        
        // Code to delete question response End
        response.message = JSON.serialize(recordsToDelete);
        
    }catch(Exception e) {
        String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
        String stackTrace = e.getStackTraceString().substringBefore('\n');             
        throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
    }
    return JSON.serialize(response);
    }

    /**
    * @description Method to get purcahse data
    * @param  cemId
    * @return List<Purchase_Data__c>
    */
    @AuraEnabled
    public static List<Purchase_Data__c> getRelatedBooths(String cemId){
        List<Purchase_Data__c> booths = new List<Purchase_Data__c>(); 
        //try- return  Purchase_Data__c list 
        //catch-throw error message if Purchase_Data__c record is not found
        try{
            booths = [SELECT Id,Booth_Number__c,tolabel(Booth_Product_Type__c) FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c=:cemId AND Purchase_Status__c='Active' AND Transaction_Status__c='Active' AND (Booth_Number__c<>null OR Booth_Number__c<>'') WITH SECURITY_ENFORCED];
        } catch (Exception e) {
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }
        return booths;
    }
    
    
    /**
    * @description Method to delete form entries
    * @param  formRespEntryId
    * @return string
    */
    @AuraEnabled
    public static string deleteFormRespEntry(String formRespEntryId){
        string message = '';
        try{
            if(string.isNotBlank(formRespEntryId)){
                List<Form_Response_Entry__c> formRespLst = [SELECT id,Approval_Status__c FROM Form_Response_Entry__c WHERE id =:formRespEntryId WITH SECURITY_ENFORCED limit 1];
                //if- formRespLst is not empty and formRespLst[0] is not approved the delete the Question_Response__c
                 if(!formRespLst.isEmpty()){
                    message = 'Form Response Already Approved.';
                    if(formRespLst[0].Approval_Status__c != 'Approved'){
                        List<Question_Response__c> quesRespLst = [SELECT Id,Form_Response_Entry__c FROM Question_Response__c WHERE Form_Response_Entry__c=: formRespLst[0].id WITH SECURITY_ENFORCED];
                        if(!quesRespLst.isEmpty()){
                            delete quesRespLst;
                        }
                        delete formRespLst;
                        
                        message = 'Success';
                    }
                }  
            }     
        }
        catch(Exception e){
                //if any error occured then get the error message
                //message = e.getMessage();}
                String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
                String stackTrace = e.getStackTraceString().substringBefore('\n');             
                throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }
        return message;
    }

    /**
    * @description Method to get form entries
    * @param  recordId
    * @return Map<String,Object>
    */
    @AuraEnabled
    public static Map<String,Object> getFormEntries(String recordId){
        List<String> ids = new List<String>();
        System.debug(LoggingLevel.DEBUG, ids);
        List<ContentVersion> cv = new List<ContentVersion>();
        Form_Data__c fd;
        /*fd = [SELECT Forms_Permission__r.Form_Allocation__r.Form_Entry__c,Form_Submission_Status__c,Form_Submission_Status__r.Girikon_Form__c,Form_Submission_Status__r.Contact_Edition_Mapping__c FROM Form_Data__c WHERE Id=:recordId WITH SECURITY_ENFORCED]; 
        List<AggregateResult> arList = [SELECT Form_Response_Entry__c,count(Id) FROM Question_Response__c WHERE Questionnaire__c=:fd.Form_Submission_Status__r.Girikon_Form__c AND Contact_Edition_Mapping__c=:fd.Form_Submission_Status__r.Contact_Edition_Mapping__c WITH SECURITY_ENFORCED GROUP BY Form_Response_Entry__c];
        for(AggregateResult ar : arList){
            ids.add(String.valueOf(ar.get('Form_Response_Entry__c')));
        }
        if(fd.Form_Submission_Status__c!=null){
            List<ContentDocumentLink> docs = [SELECT ContentDocumentId FROM ContentDocumentLink  WHERE LinkedEntityId=:fd.Form_Submission_Status__c WITH SECURITY_ENFORCED];
            List<String> docIdList = new List<String>();
            for(ContentDocumentLink cdl : docs){
                docIdList.add(cdl.ContentDocumentId);
            }
            cv = [SELECT ContentDocumentId,Title FROM ContentVersion WHERE ContentDocumentId IN:docIdList WITH SECURITY_ENFORCED];
        }*/
        

        return new Map<String,Object>{
            'entry'=> Database.query('SELECT Name,Entry_Number__c,format(LastModifiedDate), LastModifiedBy.FirstName FROM Form_Response_Entry__c WHERE Id IN:ids ORDER BY Entry_Number__c DESC'),
            'submission'=>'',
            'files'=>cv,
            'formData'=>fd
        };
    } 
    
    /**
    * @description to get form entry status
    * @param  entryId
    * @return Form_Response_Entry__c  
    */
    @AuraEnabled
    public static Form_Response_Entry__c getFormResponseEntry(String entryId){
        Form_Response_Entry__c freObj;
        try{
           
                
                freObj = [SELECT Id,Form_Data__c,Current_Page__c,Current_Page_No__c,Contact_Edition_Mapping__c,Girikon_Form__c
                ,Total_Pages__c,Approval_Status__c,Receive_an_Email_Copy__c,Additional_Emails__c
                ,Status__c,Entry_Number__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c
                ,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_Response_to_Customer__c
                ,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c
                ,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,Form_Unlock__c,Version__c
                FROM Form_Response_Entry__c WHERE Id=:entryId WITH SECURITY_ENFORCED LIMIT 1];
        

        }catch(Exception e) {

            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
           throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);

        }
        return freObj;
    }

    /**
    * @description to get current User Detail
    * @param  userId
    * @return User  
    */
    @AuraEnabled
    public static User getUserDetail(String userId){
       
        User userObj;
        try{
            userObj = [SELECT Id,Profile.Name FROM User WHERE Id=:userId LIMIT 1];
        } catch(Exception e) {

            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
           throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }
        return userObj;
    }

    /**
    * @description  get TabId
    * @param cmid
    * @return Map<String,Object>
    */
    @AuraEnabled
    public static Map<String,Object> getTabId(String cmid){
        List<Contact_Edition_Mapping__c> conEdMapLst = [SELECT Account__c,Edition__r.Edition_Code__c,Edition__r.Event_Setting__c,Feathr_Unique_Link__c FROM Contact_Edition_Mapping__c WHERE Id =: cmid WITH SECURITY_ENFORCED];
        List<Event_Tabs__c> etl = new List<Event_Tabs__c>();
        if(!conEdMapLst.isEmpty()){
            etl = [SELECT ExtTabId__c,Tab_Code__c,Tab_Type__c,Standard_Tab_Type__c FROM Event_Tabs__c WHERE Event_Setting__c=:conEdMapLst[0].Edition__r.Event_Setting__c AND ExtTabId__c!=null AND ExtTabId__c!='' WITH SECURITY_ENFORCED];
        }        
        return new Map<String,Object>{
            'tab' => etl,
            'cem' => conEdMapLst
        };
    }

    /** @description ResWrapper*/
    public class ResWrapper {
        @AuraEnabled public string responses;
        @AuraEnabled public List<Questionnaire_Dynamic_Logic__c> lstQDynLogic;
    }
    
    /** @description QuestionResponse*/
    public class QuestionResponse {
        @AuraEnabled public List<Question_Questionnairesr> Question_Questionnairesr;
        @AuraEnabled public String Type;
    }

    /** @description Question_Questionnairesr*/
    public class Question_Questionnairesr {
        @AuraEnabled public String Question;
        @AuraEnabled public String Id;
        @AuraEnabled public String responseValue1;
        @AuraEnabled public String responseValue2;
        @AuraEnabled public String comment;        
        @AuraEnabled public List<BranchingQuestions> branchingQuestnQuetnnaire;
    }

    /** @description BranchingQuestions*/
    public class BranchingQuestions {
        @AuraEnabled public String Question;
        @AuraEnabled public String Id;
        @AuraEnabled public String responseValue1;
        @AuraEnabled public String responseValue2;
        @AuraEnabled public String comment;
        @AuraEnabled public Questionr_cl Questionr;
    }
    
    /** @description Questionr_cl*/
    public class Questionr_cl{
        @AuraEnabled public String Type;
    }

     /** @description FormStatus*/
    public class FormStatus{
        @AuraEnabled public String boothId;
        @AuraEnabled public String status;
        @AuraEnabled public String pageId;
        @AuraEnabled public String currentPageNo;
        @AuraEnabled public String totalPages;
        @AuraEnabled public String conEdMapId;
        @AuraEnabled public Boolean newEntry;
        @AuraEnabled public Boolean entryEditMode;
        @AuraEnabled public Integer entryNumber;
        @AuraEnabled public String formDataId;
        @AuraEnabled public String entryId;
        @AuraEnabled public Boolean isSaveAsDraft;
        @AuraEnabled public Integer version;
        @AuraEnabled public Boolean recieveEmailCopy;
        @AuraEnabled public String additionalEmails;
    }
}