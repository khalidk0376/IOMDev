/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 10 Sept, 2021
* @description           : This class use create form,section,question and pagination 
* Test Class             : NewCreateTemplateCtrl_Test and FormPreviewController_Test
* Code Coverage          : 88%
* Modification Log----- 
* Modified by            : Girikon(Mukesh), [IMCC-4762 22-11-2022 by Aishwarya, - added Allow_Multiple_Files__c field in query]
**/
public without sharing class NewCreateTemplateCtr {
    
    /**
    * @description   This method is used to get Questions For Question Group
    * @param  qnaireId
    * @param  sectionId
    * @return FBWrapper
    */
    @AuraEnabled
    public static FBWrapper getQuestnsForQuesGroup(String qnaireId, String sectionId) {
        FBWrapper wrapper = new FBWrapper();

        QuestionGroupWithQuestionsWrap oQGWQuesWrap1 = new QuestionGroupWithQuestionsWrap();
        QuestionGroupWithQuestionsWrap oQGWQuesWrap2 = new QuestionGroupWithQuestionsWrap();

        if (String.isNotBlank(qnaireId)) {

            String sQuery = 'Select id,Related_To_Column__c,Question_Group__c,Question__c,Question_Group__r.Name,Question_Group__r.Is_Show_On_From__c,Question_Group__r.No_Of_Columns__c From Question_Questionnaire__c WHERE is_Delete__c=false and Questionnaire__c = \'' + String.escapeSingleQuotes(qnaireId) + '\' ';
            if (String.isNotBlank(sectionId)) {
                sQuery += ' AND Question_Group__c =\'' + String.escapeSingleQuotes(sectionId) + '\'';
            }
            sQuery += ' WITH SECURITY_ENFORCED ORDER BY Question_Order__c ASC';
            List<Question_Questionnaire__c> lstQuesQuestionnaire = new List<Question_Questionnaire__c>();
            
            lstQuesQuestionnaire = Database.query(sQuery);
            
            List<String> lstcol1QuesId = new List<String>();
            List<String> lstcol2QuesId = new List<String>();
            // Get the question group(section) id and add all the questions in to list behalf of the this question group id.

            String colnum = '1';

            for (Question_Questionnaire__c qustnQnaire : lstQuesQuestionnaire) {
                if (String.isBlank(sectionId)) {
                    sectionId = qustnQnaire.Question_Group__c;
                }
                colnum = String.isNotBlank(qustnQnaire.Question_Group__r.No_Of_Columns__c) ? qustnQnaire.Question_Group__r.No_Of_Columns__c : '1';

                if (String.isNotBlank(sectionId)) {
                    oQGWQuesWrap1.groupName = qustnQnaire.Question_Group__r.Name;
                    oQGWQuesWrap1.sectionColNumber = colnum;
                    oQGWQuesWrap1.groupId = sectionId;
                    oQGWQuesWrap1.isShow = qustnQnaire.Question_Group__r.Is_Show_On_From__c;
                }

                if (String.isNotBlank(sectionId) && qustnQnaire.Question_Group__c == sectionId && (colnum == '0' || colnum == '1')) {
                    lstcol1QuesId.add(qustnQnaire.Question__c);
                }

                if (String.isNotBlank(sectionId) && qustnQnaire.Question_Group__c == sectionId && colnum == '2' && qustnQnaire.Related_To_Column__c == 'col1') {
                    lstcol1QuesId.add(qustnQnaire.Question__c);
                }
                if (String.isNotBlank(sectionId) && qustnQnaire.Question_Group__c == sectionId && colnum == '2' && qustnQnaire.Related_To_Column__c == 'col2') {
                    lstcol2QuesId.add(qustnQnaire.Question__c);
                }
            }

            //Initialize value
            oQGWQuesWrap1.lstQuestn = new List<Question__c>();
            oQGWQuesWrap2.lstQuestn = new List<Question__c>();

            // Retrive all the questions from Question object.
            if (lstcol1QuesId.size() > 0) {
                oQGWQuesWrap1.lstQuestn = new List<Question__c>([SELECT Id, background_Color__c, Label__c, Step_Size__c, Is_Allow_Branching__c, Default_Value__c, Maximum_value__c, Minimum_Value__c, Allow_Currency__c, Currency_Symbol__c, Decimal_value__c
                        , Metadata__c, lookup_Object_Field_Name__c, lookup_Object_API_Name__c,Allow_Multiple_Files__c, (Select id, Currency_Symbol__c, Metadata__c, Allow_Currency__c
                                , Decimal_value__c, Help_Text__c, Max_Char_Length__c, lookup_Object_API_Name__c, lookup_Object_Field_Name__c, Allow_Attachments__c, Allow_Comment__c
                                , Help_Text_Required__c, Related_To_Column__c, Required__c, Step_Size__c, Default_Value__c, Is_Allow_Branching__c, Maximum_value__c, Minimum_Value__c, Question_Order__c, Question__r.Label__c,
                                Question__r.Type__c, Question__r.Allow_Currency__c, Question__r.background_Color__c,Question__r.Metadata__c, Question__r.Decimal_value__c, Question__r.Currency_Symbol__c,Question__r.Allow_Multiple_Files__c from Question_Questionnaires__r
                                where Questionnaire__c = :qnaireId and Question_Group__c = :sectionId and is_Delete__c = false ORDER BY Related_To_Column__c ASC LIMIT 1),
                        Help_Text__c, Type__c, Allow_Attachments__c, Allow_Comment__c, Max_Char_Length__c, Help_Text_Required__c, Required__c,
                        (Select id, Value__c, Name__c, Name_Long__c from Question_Options__r ORDER BY ID ASC)// Changes Here for Long
                        From Question__c WHERE id IN :lstcol1QuesId and is_Delete__c = false WITH SECURITY_ENFORCED ORDER BY CreatedDate ASC]);

            }
            if (lstcol2QuesId.size() > 0) {
                oQGWQuesWrap2.lstQuestn = new List<Question__c>([SELECT Id, background_Color__c, Label__c, Step_Size__c, Is_Allow_Branching__c, Default_Value__c, Maximum_value__c, Minimum_Value__c, Allow_Currency__c, Currency_Symbol__c, Decimal_value__c
                        , Metadata__c, lookup_Object_Field_Name__c, lookup_Object_API_Name__c,Allow_Multiple_Files__c, (Select id, Currency_Symbol__c, Metadata__c, Allow_Currency__c
                                , Decimal_value__c, Help_Text__c, Max_Char_Length__c, lookup_Object_API_Name__c, lookup_Object_Field_Name__c, Allow_Attachments__c, Allow_Comment__c
                                , Help_Text_Required__c, Related_To_Column__c, Required__c, Step_Size__c, Default_Value__c, Is_Allow_Branching__c, Maximum_value__c, Minimum_Value__c,Question_Order__c, Question__r.Label__c,
                                Question__r.Type__c, Question__r.Allow_Currency__c,Question__r.background_Color__c, Question__r.Metadata__c, Question__r.Decimal_value__c, Question__r.Currency_Symbol__c,Question__r.Allow_Multiple_Files__c from Question_Questionnaires__r
                                where Questionnaire__c = :qnaireId and Question_Group__c = :sectionId and is_Delete__c = false ORDER BY Related_To_Column__c ASC LIMIT 1),
                        Help_Text__c, Type__c, Allow_Attachments__c, Allow_Comment__c, Max_Char_Length__c, Help_Text_Required__c, Required__c,
                        (Select id, Value__c, Name__c, Name_Long__c from Question_Options__r ORDER BY ID ASC)// Changes Here for Long
                        From Question__c WHERE id IN :lstcol2QuesId and is_Delete__c = false WITH SECURITY_ENFORCED ORDER BY CreatedDate ASC]);

            }        
        }
        wrapper.col1Questions = oQGWQuesWrap1;
        wrapper.col2Questions = oQGWQuesWrap2;        
        //System.debug(JSON.serialize(wrapper));
        return wrapper;
    }
    
    /**
    * @description   This method is used to get All Questions For Question Group
    * @param  qnaireId
    * @param  sectionId pass sectionId empty
    * @return FBPreviewWrapper
    */
    @AuraEnabled
    public static FBPreviewWrapper getQuestnsForAllQuesGroup(String qnaireId, String sectionId) {
        FBPreviewWrapper fbPreview = new FBPreviewWrapper();
        /* not using any more
        List<FBWrapper> wrapperList = new List<FBWrapper>();
        if (String.isNotBlank(qnaireId)) {
            List<AggregateResult> qqlist;
            //order BY Question_Group__r.Sort_Order__c
            if (String.isNotBlank(sectionId)) {
                qqlist = [Select count(id), Question_Group__c from Question_Questionnaire__c where Question_Group__c = :String.escapeSingleQuotes(sectionId) AND Questionnaire__c = :String.escapeSingleQuotes(qnaireId) WITH SECURITY_ENFORCED group by Question_Group__c];
            } else {
                qqlist = [Select count(id), Question_Group__c from Question_Questionnaire__c where Questionnaire__c = :String.escapeSingleQuotes(qnaireId)  WITH SECURITY_ENFORCED group by Question_Group__c];
            }
            List<Id> sectionIdList = new List<Id>();
            for (AggregateResult qq : qqlist) {
                sectionIdList.add(String.valueOf(qq.get('Question_Group__c')));
            }
            
            Map<Id, Question_Group__c> sections = new Map<Id, Question_Group__c>([SELECT Id from Question_Group__c WHERE Id IN:sectionIdList WITH SECURITY_ENFORCED ORDER BY Sort_Order__c ASC]);
            
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
                
            for (Id qq : sections.keySet()) {
                if(!sectQQMap.containsKey(qq)){continue;}
                FBWrapper wrapper = new FBWrapper();
                QuestionGroupWithQuestionsWrap oQGWQuesWrap1 = new QuestionGroupWithQuestionsWrap();
                QuestionGroupWithQuestionsWrap oQGWQuesWrap2 = new QuestionGroupWithQuestionsWrap();
                sectionId = qq;
                lstcol1QuesId = new List<String>();
                lstcol2QuesId = new List<String>();

                // Get the question group(section) id and add all the questions in to list behalf of the this question group id.

                String colnum = '1';
                //System.debug(JSON.serialize(lstQuesQuestionnaire));

                for (Question_Questionnaire__c qustnQnaire : sectQQMap.get(qq)) {                    
                    if (String.isBlank(sectionId)) {
                        sectionId = qustnQnaire.Question_Group__c;
                    }
                    colnum = String.isNotBlank(qustnQnaire.Question_Group__r.No_Of_Columns__c) ? qustnQnaire.Question_Group__r.No_Of_Columns__c : '1';

                    if (String.isNotBlank(sectionId)) {
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
            Allow_Currency__c, Currency_Symbol__c, Decimal_value__c, Metadata__c, lookup_Object_Field_Name__c, lookup_Object_API_Name__c, (Select id, Currency_Symbol__c, Metadata__c, 
            Allow_Currency__c, Decimal_value__c, Help_Text__c, Max_Char_Length__c, lookup_Object_API_Name__c, lookup_Object_Field_Name__c, Allow_Attachments__c, Allow_Comment__c, 
            Help_Text_Required__c, Related_To_Column__c, Required__c, Step_Size__c, Default_Value__c, Is_Allow_Branching__c, Maximum_value__c, Minimum_Value__c, Question_Order__c, 
            Question__r.Label__c,Question__r.Type__c, Question__r.Allow_Currency__c,Question__r.background_Color__c, Question__r.Metadata__c, Question__r.Decimal_value__c, Question__r.Currency_Symbol__c from Question_Questionnaires__r
            WHERE Questionnaire__c = :String.escapeSingleQuotes(qnaireId) and Question_Group__c In :sectionIdList and is_Delete__c = false LIMIT 1),Help_Text__c,Is_MultiSelect__c, Type__c, Allow_Attachments__c, 
            Allow_Comment__c, Max_Char_Length__c, Help_Text_Required__c, Required__c,(Select id, Value__c, Name__c, Name_Long__c from Question_Options__r ORDER BY ID ASC) From Question__c WHERE // Changes Here for Long
            Id IN :allQuestionIds and is_Delete__c = false WITH SECURITY_ENFORCED ORDER BY CreatedDate ASC]);
            
            for(FBWrapper item : wrapperList){
                if(item.col1Questions.col1QuestionIds.size()>0){
                    for(String idStr : item.col1Questions.col1QuestionIds){
                        if(allQuestions.containsKey(idStr)){
                            item.col1Questions.lstQuestn.add(allQuestions.get(idStr));        
                        }
                    }
                }
                if(item.col2Questions.col2QuestionIds.size()>0){
                    for(String idStr : item.col2Questions.col2QuestionIds){
                        if(allQuestions.containsKey(idStr)){
                            item.col2Questions.lstQuestn.add(allQuestions.get(idStr));        
                        }
                    }
                }
                
            }
            fbPreview.sectionList = wrapperList;
        }
        //System.debug(JSON.serialize(fbPreview));
        */
        return fbPreview;
    }
    
    /**
    * @description   This method is used to get if section is merged
    * @param  qnaireId
    * @return boolean
    */
    @AuraEnabled
    public static boolean isMergeSection(String qnaireId) {
        Boolean isMergeSection = false;
        if (!String.isBlank(qnaireId)) {            
            List<Questionnaire__c> q = [SELECT id, isMerge__c from Questionnaire__c WHERE Id =:String.escapeSingleQuotes(qnaireId) WITH SECURITY_ENFORCED];
            if (q.size() > 0) {
                isMergeSection = q[0].isMerge__c;
            }
        }
        return isMergeSection;
    }
    
    /**
    * @description   This method is used to fetch Questionnaire(Template) record
    * @param  qnaireId
    * @return temp_record
    */
    @AuraEnabled
    public static temp_record getTemplateRecord(String qnaireId) {        
        temp_record tr = new temp_record();
        if (String.isNotBlank(qnaireId)) {            
            tr.totalQuest = Database.countQuery('SELECT count() FROM Question_Questionnaire__c WHERE Question__c!=\'\' AND is_Delete__c=false AND Questionnaire__c=\''+String.escapeSingleQuotes(qnaireId)+'\' WITH SECURITY_ENFORCED');
            List<Questionnaire__c> lstQuestnnaire = [SELECT Name, Language__c,Community_URL__c, Description__c, Category__c, is_Published__c FROM Questionnaire__c WHERE Id = :String.escapeSingleQuotes(qnaireId) WITH SECURITY_ENFORCED];
            tr.questionnaire = !lstQuestnnaire.isEmpty()?lstQuestnnaire[0]:new Questionnaire__c();            
        }
        return tr;
    }

    /**
    * @description   Temp_record wrapper class
    * @param  qnaireId
    * @return temp_record
    */
    public class Temp_record{
        @AuraEnabled public Long totalQuest;                
        @AuraEnabled public Questionnaire__c questionnaire;
    }

    /**
     * @description fetch Questionnaire(Template) name
     * @param  qnaireId : Questionnaire Id.
     * @return           : Questionnaire name
     */
    public static String getTemplateName(String qnaireId) {
        return [SELECT Name FROM Questionnaire__c WHERE Id = :String.escapeSingleQuotes(qnaireId) WITH SECURITY_ENFORCED].Name;        
    }


    /**
     * @description fetch all Question Group for Questionnaire
     * @param  sQnaireId : set Questionnaire id.
     * @return           : All Question Group name for Questionnaire.
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
     * @description fetch Question Categories picklist value
     * @return : list of Question Category.
     */
    @AuraEnabled
    public static List<String> getQueCategory() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Question__c.Category__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(f.getLabel());
        }
        return options;
    }

    /**
    * @description Create question and question questionnaire.
    * @param  qnaireId : Questionnaire id.
    * @param  qGroupId : Question group id.
    * @param  question : Question object values.
    * @param  qnaireName : Questionnaire name.
    * @param  qOrder : Order of question.
    * @param  colNumber : column number of question.
    */
    @AuraEnabled
    public static void createQuestnAndQuestnQnaire(String qnaireId, String qGroupId, Question__c question, String qnaireName, String qOrder, String colNumber) {
        try {
            String sQLib = getDefaultQuestnLibraryId();
            question.Name__c = question.Label__c;                        
            question.Related_To_Column__c = colNumber;            
            question.Question_Library__c = sQLib;            
            question.Name = qOrder;            
            SObjectAccessDecision sd =  Security.stripInaccessible(AccessType.CREATABLE, new List<Question__c>{question});
            Insert sd.getRecords();
            question = [SELECT Id,Type__c,Currency_Symbol__c,lookup_Object_API_Name__c,Required__c,Allow_Currency__c,Decimal_value__c,Help_Text__c,Help_Text_Required__c,Category__c,Allow_Attachments__c,Allow_Comment__c,Is_Allow_Branching__c,Max_Char_Length__c,Minimum_Value__c,Maximum_value__c,Step_Size__c,Default_Value__c FROM Question__c WHERE Id=:sd.getRecords()[0].Id WITH SECURITY_ENFORCED];
            Question_Questionnaire__c oQQuesnaire = new Question_Questionnaire__c();            
            oQQuesnaire.Required__c = question.Required__c;        
            oQQuesnaire.Related_To_Column__c = colNumber;         
            oQQuesnaire.Help_Text__c = question.Help_Text__c;        
            oQQuesnaire.Help_Text_Required__c = question.Help_Text_Required__c;        
            oQQuesnaire.Category__c = question.Category__c;        
            oQQuesnaire.Allow_Attachments__c = question.Allow_Attachments__c;         
            oQQuesnaire.Allow_Comment__c = question.Allow_Comment__c;        
            oQQuesnaire.Questionnaire__c = qnaireId;        
            oQQuesnaire.Name = qnaireName;        
            oQQuesnaire.Max_Char_Length__c = question.Max_Char_Length__c;         
            oQQuesnaire.Question_Group__c = qGroupId;                
            oQQuesnaire.Question__c = question.id;        
            oQQuesnaire.Question_Order__c = Integer.valueOf(qOrder);
            SObjectAccessDecision sd2 =  Security.stripInaccessible(AccessType.CREATABLE, new List<Question_Questionnaire__c>{oQQuesnaire});
            Insert sd2.getRecords();
            FieldInputCtr.sortQuestions(sd2.getRecords()[0].Id,qnaireId,qGroupId,colNumber,Integer.valueOf(qOrder));
        } 
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Deleting Question and Question Questionnaire record.
     * @param  questnQuestnnaireId : question record id
     *
     */
    @AuraEnabled
    public static void delQuestion(String questnQuestnnaireId) {
        if (String.isNotBlank(questnQuestnnaireId)) {
            List<Question_Questionnaire__c> lstQQnaire = [SELECT Id, is_delete__c, Question__c, Question__r.Is_Approve_For_Library__c FROM Question_Questionnaire__c WHERE Id =: String.escapeSingleQuotes(questnQuestnnaireId) WITH SECURITY_ENFORCED];
            
            if(!lstQQnaire.isEmpty() && Schema.SObjectType.Question_Questionnaire__c.Fields.is_delete__c.isUpdateable()){
                lstQQnaire[0].is_delete__c = true;
            }
            if(!lstQQnaire.isEmpty() && Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
                Update Security.stripInaccessible(AccessType.UPDATABLE, lstQQnaire).getRecords();                
            }

            if (!lstQQnaire.isEmpty() && lstQQnaire[0].Question__c != null && lstQQnaire[0].Question__r.Is_Approve_For_Library__c == false) {
                List<Question__c> lstQuestn =  [SELECT id, is_delete__c FROM Question__c WHERE Id = :lstQQnaire[0].Question__c WITH SECURITY_ENFORCED];
                if (!lstQuestn.isEmpty()) {                    
                    lstQuestn[0].is_delete__c = true;
                    Update Security.stripInaccessible(AccessType.UPDATABLE, lstQuestn).getRecords();
                    delQuestnDynLogic(questnQuestnnaireId);
                }
                //delete new Question__C(id=quesId);
            }            
        }
    }

    /**
     * @description Delete branching record when admin deleting input field record.
     * @param questnQuestnnaireId : Question Questionnaire Id
     */
    public static void delQuestnDynLogic(String questnQuestnnaireId) {        
        List<Questionnaire_Dynamic_Logic__c> lstQuestnDynLogic = [Select Id from Questionnaire_Dynamic_Logic__c where (Question_Questionnaire__c = :String.escapeSingleQuotes(questnQuestnnaireId) OR Show_Question_Questionnaire__c = :String.escapeSingleQuotes(questnQuestnnaireId)) WITH SECURITY_ENFORCED];
        if (Schema.SObjectType.Questionnaire_Dynamic_Logic__c.isDeletable()) {
            Delete lstQuestnDynLogic;
        }
    }

    /**
     * @description fetch a question detail
     * @param  quesId : Question record id
     * @return          question detail
     */
    @AuraEnabled
    public static Question__c getQuesDetail(String quesId) {
        if (String.isNotBlank(quesId)) {            
            return [SELECT Id, Is_MultiSelect__c,background_Color__c, Label__c, Is_Allow_Branching__c, lookup_Object_Field_Name__c,
                    Step_Size__c, Default_Value__c, Maximum_value__c, Minimum_Value__c, lookup_Object_API_Name__c, Help_Text__c, Currency_Symbol__c,
                    Allow_Currency__c, Decimal_value__c, Metadata__c, Max_Char_Length__c, Category__c, Type__c, Allow_Comment__c,
                    Allow_Attachments__c, Help_Text_Required__c,Allow_Multiple_Files__c, 
                    (SELECT Id, Value__c, Name__c, Name_Long__c from Question_Options__r ORDER BY Index__c,ID ASC), Required__c// Changes Here for Long
                    FROM Question__c WHERE id = :String.escapeSingleQuotes(quesId) WITH SECURITY_ENFORCED LIMIT 1];            
        }
        return new Question__c();
    }

    /**
     * @description save edited Question and Question Questionniare record
     * @param  oQues : Question object values.
     * @return      Boolean value for update secussfull.
     */
    @AuraEnabled
    public static Boolean saveEditQuesRecord(Question__c oQues) {
        
        if (oQues.Help_Text_Required__c == false && Schema.SObjectType.Question__c.Fields.Help_Text__c.isUpdateable()) {
            oQues.Help_Text__c = '';
        }
        if(Schema.SObjectType.Question__c.isUpdateable()){
            Update Security.stripInaccessible(AccessType.UPDATABLE, new List<Question__c>{oQues}).getRecords();
        }
        
        List<Question_Questionnaire__c> lstQQnnaire = [SELECT Id, Allow_Attachments__c, Allow_Comment__c,Help_Text_Required__c, Help_Text__c, Category__c FROM Question_Questionnaire__c WHERE Question__c = :oQues.id WITH SECURITY_ENFORCED];    
        
        if (lstQQnnaire != null && lstQQnnaire.size() > 0) {
            if(Schema.SObjectType.Question_Questionnaire__c.Fields.Allow_Attachments__c.isUpdateable()){
                lstQQnnaire[0].Allow_Attachments__c = oQues.Allow_Attachments__c;    
            }
            if(Schema.SObjectType.Question_Questionnaire__c.Fields.Allow_Comment__c.isUpdateable()){
                lstQQnnaire[0].Allow_Comment__c = oQues.Allow_Comment__c;
            }
            if(Schema.SObjectType.Question_Questionnaire__c.Fields.Help_Text_Required__c.isUpdateable()){
                lstQQnnaire[0].Help_Text_Required__c = oQues.Help_Text_Required__c;
            }
            if(Schema.SObjectType.Question_Questionnaire__c.Fields.Help_Text__c.isUpdateable()){
                lstQQnnaire[0].Help_Text__c = '';
            }
            if(Schema.SObjectType.Question_Questionnaire__c.Fields.Required__c.isUpdateable()){
                lstQQnnaire[0].Required__c = oQues.Required__c;
            }
            if (oQues.Help_Text_Required__c == true && Schema.SObjectType.Question_Questionnaire__c.Fields.Help_Text__c.isUpdateable()) {
                lstQQnnaire[0].Help_Text__c = oQues.Help_Text__c;
            }                
            if(Schema.SObjectType.Question_Questionnaire__c.Fields.Category__c.isUpdateable()){
                lstQQnnaire[0].Category__c = oQues.Category__c;
            }
            if(Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
                Update Security.stripInaccessible(AccessType.UPDATABLE, lstQQnnaire).getRecords();                    
            }
        }
        return true;
    
    }

    /**
     * @description fetch default set Question Library id
     * @return : Question library id
     */
    public static String getDefaultQuestnLibraryId() {
        String id;
        List<Question_Library__c> qlList = [SELECT id FROM Question_Library__c WHERE Name = 'Global Default' WITH SECURITY_ENFORCED Limit 1];
        if(!qlList.isEmpty()){
            return qlList[0].Id;
        }
        else{
            Question_Library__c objQLib = new Question_Library__c();
            if(Schema.SObjectType.Question_Library__c.Fields.Name__c.isCreateable()){
                objQLib.Name__c = 'Global Default';
            }
            if(Schema.SObjectType.Question_Library__c.Fields.Name.isCreateable()){
                objQLib.Name    = 'Global Default';
            }
            if(Schema.SObjectType.Question_Library__c.isCreateable()){
                Insert Security.stripInaccessible(AccessType.CREATABLE, new List<Question_Library__c>{objQLib}).getRecords();                    
            }
            return objQLib.Id;                
        }    
    }


    /**
    * @description Create new Question group
    * @param  sectionObj : Question Group.
    * @param  questionaryId : Questionniare Id.
    * @return Question_Group__c
    */
    @AuraEnabled
    public static Question_Group__c createSection(Question_Group__c sectionObj, String questionaryId) {
        Question_Group__c questnGroup = new Question_Group__c();
        try {
            if (String.isNotBlank(sectionObj.Name) && String.isNotBlank(questionaryId) && 
                String.isNotBlank(sectionObj.No_Of_Columns__c)) {
                
                List<Question_Questionnaire__c> lstQstnGrp = [SELECT id FROM Question_Questionnaire__c WHERE Questionnaire__c = :String.escapeSingleQuotes(questionaryId) WITH SECURITY_ENFORCED];
                
                if(Schema.SObjectType.Question_Group__c.Fields.Name.isCreateable()){
                    questnGroup.Name = sectionObj.Name;
                }
                if(Schema.SObjectType.Question_Group__c.Fields.No_Of_Columns__c.isCreateable()){
                    questnGroup.No_Of_Columns__c = sectionObj.No_Of_Columns__c;
                }
                if(Schema.SObjectType.Question_Group__c.Fields.Sort_Order__c.isCreateable()){
                    questnGroup.Sort_Order__c = lstQstnGrp.size();
                }
                if(Schema.SObjectType.Question_Group__c.Fields.Is_Show_On_From__c.isCreateable()){
                    questnGroup.Is_Show_On_From__c = sectionObj.Is_Show_On_From__c;
                }
                if(Schema.SObjectType.Question_Group__c.isCreateable()){
                    Insert questnGroup;
                }

                Question_Questionnaire__c questnQuestnnaire = new Question_Questionnaire__c(name = getTemplateName(questionaryId), Question_Group__c = questnGroup.id, Questionnaire__c = questionaryId);
                if(Schema.SObjectType.Question_Questionnaire__c.isCreateable()){
                    Insert questnQuestnnaire;
                }

                //add section to page
                Form_Pagination__c pageObj = getPage(questionaryId);
                if(pageObj.Form_Pages__r!=null && !pageObj.Form_Pages__r.isEmpty()){                
                    Form_Page__c fp = pageObj.Form_Pages__r[pageObj.Form_Pages__r.size()-1];
                    fp.Section__c = fp.Section__c+','+questnGroup.Id;
                    Update Security.stripInaccessible(AccessType.UPDATABLE, new List<Form_Page__c>{fp}).getRecords();
                }

                return questnGroup;
            }
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return questnGroup;
    }

    /**
    * @description update new Question group
    * @param  sectionObj : Question Group.
    * @param  questionaryId : Questionniare Id.
    */
    @AuraEnabled
    public static void updateSection(Question_Group__c sectionObj, String questionaryId) {
        
        try {
            //String colNum = 'col'+sectionObj.No_Of_Columns__c;
            Integer col1 = Integer.valueOf(sectionObj.No_Of_Columns__c);
            Integer col2=0;
            List<Id> questionIdList  = new List<Id>();
            if (String.isNotBlank(sectionObj.Name) && String.isNotBlank(questionaryId) && String.isNotBlank(sectionObj.No_Of_Columns__c)) {                
                //Update section name and column number
                List<Question_Group__c> qgList = [SELECT id,Name,No_Of_Columns__c FROM Question_Group__c WHERE id=:sectionObj.Id WITH SECURITY_ENFORCED];
                if(qgList.size()>0){                    
                    qgList[0].Name = sectionObj.Name;
                    qgList[0].No_Of_Columns__c = sectionObj.No_Of_Columns__c;
                    qgList[0].Is_Show_On_From__c = sectionObj.Is_Show_On_From__c;
                    Update Security.stripInaccessible(AccessType.UPDATABLE, qgList).getRecords();
                
                    //Update Related_To_Column__c field Question Questionnaire object
                    List<Question_Questionnaire__c> objt =  [SELECT Id,Question__c,Related_To_Column__c FROM Question_Questionnaire__c WHERE Questionnaire__c=:String.escapeSingleQuotes(questionaryId) AND Question_Group__c=:sectionObj.Id WITH SECURITY_ENFORCED];
                    
                    for(Question_Questionnaire__c qqObj : objt){
                        if(qqObj.Related_To_Column__c!=null){
                            questionIdList.add(qqObj.Question__c);
                            col2 = Integer.valueOf(qqObj.Related_To_Column__c.replace('col',''));
                            if(col1<col2 && Schema.SObjectType.Question_Questionnaire__c.Fields.Related_To_Column__c.isUpdateable()){
                                qqObj.Related_To_Column__c='col'+col1;
                            }
                        }
                    }
                    if(objt.size()>0 && Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
                        Update Security.stripInaccessible(AccessType.UPDATABLE, objt).getRecords();
                    }

                    //Update Related_To_Column__c field of Question Object                    
                    List<Question__c> questionsList = [SELECT id,Related_To_Column__c FROM Question__c WHERE id IN:questionIdList WITH SECURITY_ENFORCED];                    
                    for(Question__c quesObj : questionsList){
                        col2 = Integer.valueOf(quesObj.Related_To_Column__c.replace('col',''));
                        if(col1<col2 && Schema.SObjectType.Question__c.Fields.Related_To_Column__c.isUpdateable()){
                            quesObj.Related_To_Column__c='col'+col1;
                        }
                    }
                    if(questionsList.size()>0 && Schema.SObjectType.Question__c.isUpdateable()){
                        Update Security.stripInaccessible(AccessType.UPDATABLE, questionsList).getRecords();
                    }
                }
            }
        } 
        catch (Exception ex) {
              System.debug(Logginglevel.Debug, ex.getMessage()+',LineNo. '+ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Delete Question group(Section)
     * @param  sectionId : Question Group ID.
     * @param  questionaryId : Questionnaire ID
     */
    @AuraEnabled
    public static void deleteSectionWithQuestionsAndQstnQustnry(String sectionId, String questionaryId) {
        if (String.isNotBlank(sectionId)) {
            List<String> lstQuestionsId = new List<String>();
            List<Question_Group__c> lstQuestionGrp = new List<Question_Group__c>();
            List<Question__c> lstupdateQuestions = new List<Question__c>();
            List<Question_Questionnaire__c> lstQustnQustnire = new List<Question_Questionnaire__c>();
            List<Question_Questionnaire__c> lstqustnQuestionnaire;
            List<Question__c> lstQuestions;

            lstqustnQuestionnaire = [Select Id, Question_Group__c, Question__c, is_Delete__c from Question_Questionnaire__c Where Questionnaire__c = :String.escapeSingleQuotes(questionaryId) and Question_Group__c = :String.escapeSingleQuotes(sectionId) WITH SECURITY_ENFORCED];

            if (lstqustnQuestionnaire != null && lstqustnQuestionnaire.size() > 0) {
                for (Question_Questionnaire__c qq : lstqustnQuestionnaire) {
                    if(Schema.SObjectType.Question_Questionnaire__c.Fields.is_Delete__c.isUpdateable()){
                        qq.is_Delete__c = true;    
                    }
                    lstQuestionsId.add(qq.Question__c);
                    lstQustnQustnire.add(qq);
                }
                
                lstQuestionGrp = [Select id, is_Delete__c from Question_Group__c Where Id = :String.escapeSingleQuotes(lstqustnQuestionnaire[0].Question_Group__c) and is_Delete__c = false WITH SECURITY_ENFORCED];
            
                lstQuestions = [Select Id, is_Delete__c from Question__c Where Id IN:lstQuestionsId and Is_Approve_For_Library__c = false and is_Delete__c = false WITH SECURITY_ENFORCED];
            
                if (lstQuestions != null && lstQuestions.size() > 0) {
                    for (Question__c question : lstQuestions) {                        
                        question.is_Delete__c = true;                                                
                        lstupdateQuestions.add(question);
                    }
                }
            }
            if (lstQustnQustnire.size() > 0 && lstQuestionGrp.size() > 0 && lstupdateQuestions.size() > 0) {
                if(Schema.SObjectType.Question_Group__c.Fields.is_Delete__c.isUpdateable()){
                    lstQuestionGrp[0].is_Delete__c = true;
                }
                
                if(Schema.SObjectType.Question_Group__c.isUpdateable()){
                    Update Security.stripInaccessible(AccessType.UPDATABLE, lstQuestionGrp).getRecords();                    
                }
                if(Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
                    Update Security.stripInaccessible(AccessType.UPDATABLE, lstQustnQustnire).getRecords();
                }
                if(Schema.SObjectType.Question__c.isUpdateable()){
                    Update Security.stripInaccessible(AccessType.UPDATABLE, lstupdateQuestions).getRecords();                    
                }

            } 
            else 
            {
                if(Schema.SObjectType.Question_Group__c.Fields.is_Delete__c.isUpdateable()){
                    lstQuestionGrp[0].is_Delete__c = true;
                }
                if(Schema.SObjectType.Question_Group__c.isUpdateable()){
                    Update Security.stripInaccessible(AccessType.UPDATABLE, lstQuestionGrp).getRecords();
                    
                }
                if(Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
                    Update Security.stripInaccessible(AccessType.UPDATABLE, lstQustnQustnire).getRecords();                    
                }
            }
        }
    }

    /**
     * @description fetching Questionnaire Dynamic logic information.
     * @param  sectionId  Question Group Id
     * @return           list of Questionnaire Dynamic logic recoed.
     */
    @AuraEnabled
    public static List<Questionnaire_Dynamic_Logic__c> getBranchingQuestn(String sectionId) {
        return [SELECT Id, Question_Questionnaire__c, Question_Questionnaire__r.Question__r.Type__c, Question_Questionnaire__r.Question__c, Question_Option__c, Question_Option__r.Name__c, Question_Option__r.Name_Long__c, Show_Question_Questionnaire__c FROM 
                Questionnaire_Dynamic_Logic__c WHERE Question_Group__c = :String.escapeSingleQuotes(sectionId) WITH SECURITY_ENFORCED];
    } 

    /**
     * @description fetching Questionnaire Dynamic logic information.
     * @param  templateId : Questionnaire Id
     */
    @AuraEnabled
    public static void setpublishStatusOnTemplate(String templateId){        
        List<Questionnaire__c> questnnaire = [SELECT Id, is_Published__c FROM Questionnaire__c WHERE Id = :String.escapeSingleQuotes(templateId) WITH SECURITY_ENFORCED];        
        if (!questnnaire.isEmpty()) {            
            questnnaire[0].is_Published__c = true;                
            Update Security.stripInaccessible(AccessType.UPDATABLE, questnnaire).getRecords();            
        }
    }

    /**
     * @description Update Question Questionniare order.
     * @param  lstOrderOfQQniare : List of Quenstion Questionnaire Ids
     *
     */
    @AuraEnabled
    public static void setQuestnQnniareOrder(List<Question_Questionnaire__c> lstOrderOfQQniare) {
        if (lstOrderOfQQniare != null && lstOrderOfQQniare.size() > 0 && Schema.SObjectType.Question_Questionnaire__c.isUpdateable()) {
            Update Security.stripInaccessible(AccessType.UPDATABLE, lstOrderOfQQniare).getRecords();
        }
    }

    /**
     * @description Update question column and question questionnaire order fields
     * @param  lstOrderOfQQniare : List of Quenstion Questionnaire Ids
     * @param  lstOrderOfQst : List of Quenstion Ids
     */
    @AuraEnabled
    public static void setQuestnQnniareOrder(List<Question_Questionnaire__c> lstOrderOfQQniare, List<Question__c> lstOrderOfQst) {
        if (lstOrderOfQQniare != null && !lstOrderOfQQniare.isEmpty() && Schema.SObjectType.Question_Questionnaire__c.isUpdateable()) {
            Update Security.stripInaccessible(AccessType.UPDATABLE, lstOrderOfQQniare).getRecords();
        }
        if(lstOrderOfQst!=null && !lstOrderOfQst.isEmpty()  && Schema.SObjectType.Question__c.isUpdateable()){
            Update Security.stripInaccessible(AccessType.UPDATABLE, lstOrderOfQst).getRecords();
        }
    }

    /**
     * @description Update question column and question questionnaire order fields
     * @param  vQnaireId
     * @param  questionaryId
     * @param  questionId
     * @param  colNum
     * @param  selectedSectionId
     * @param  newIndex
     */
    @AuraEnabled
    public static void updateColumn(String vQnaireId,String questionaryId, String questionId, String colNum, String selectedSectionId,String newIndex) {
        System.debug(Logginglevel.DEBUG, questionaryId + '::' + questionId + '::' + colNum+',nexIndex: '+newIndex);

        Question_Questionnaire__c qq = new Question_Questionnaire__c();
        qq.Id = questionaryId;
        qq.Related_To_Column__c = colNum;
        qq.Question_Order__c = Integer.valueOf(newIndex);        
        Update Security.stripInaccessible(AccessType.UPDATABLE, new List<Question_Questionnaire__c>{qq}).getRecords();

        FieldInputCtr.sortQuestions(qq.Id,vQnaireId, selectedSectionId,colNum,Integer.valueOf(newIndex));
        
        Question__c q = new Question__c();
        q.Id = questionId;
        q.Related_To_Column__c = colNum;        
        Update Security.stripInaccessible(AccessType.UPDATABLE, new List<Question__c>{q}).getRecords();

        List<String> lstChildQstnQuariIds = new List<String>();
        List<String> questionIdList = new List<string>();
        List<Question__c> questionToUpdate = new List<Question__c>();

        Integer order = [SELECT count() FROM Question_Questionnaire__c WHERE Question_Group__c = :String.escapeSingleQuotes(selectedSectionId) WITH SECURITY_ENFORCED];

        List<Questionnaire_Dynamic_Logic__c> lstQuestnnaireDynLogic = [SELECT Id, Question_Questionnaire__c, Question_Group__c, Question_Option__c, Show_Question_Questionnaire__c FROM
                Questionnaire_Dynamic_Logic__c WHERE Question_Questionnaire__c = :String.escapeSingleQuotes(questionaryId) WITH SECURITY_ENFORCED];
        
        for (Questionnaire_Dynamic_Logic__c qstnDynlgc : lstQuestnnaireDynLogic) {
            lstChildQstnQuariIds.add(qstnDynlgc.Show_Question_Questionnaire__c);
        }
        if (lstChildQstnQuariIds.size() > 0) {
            List<Question_Questionnaire__c> lstQstnQuaire = [Select Id, Question__c, Question_Group__c, Is_Allow_Branching__c, Question_Order__c From Question_Questionnaire__c Where Id IN:lstChildQstnQuariIds WITH SECURITY_ENFORCED];
            
            Integer i = 2;
            for (Question_Questionnaire__c childQstnQuaire : lstQstnQuaire) {
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Related_To_Column__c.isUpdateable()){
                    childQstnQuaire.Related_To_Column__c = colNum;    
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Question_Order__c.isUpdateable()){
                    childQstnQuaire.Question_Order__c = order + i;
                }
                i = i + 1;
                questionIdList.add(childQstnQuaire.Question__c);
            }
            if(Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
                Update Security.stripInaccessible(AccessType.UPDATABLE, lstQstnQuaire).getRecords();
            }
            questionToUpdate = [SELECT id,Related_To_Column__c FROM Question__c WHERE Id In :questionIdList WITH SECURITY_ENFORCED];
            for (Question__c ques : questionToUpdate) {                
                if(Schema.SObjectType.Question__c.Fields.Related_To_Column__c.isUpdateable()){
                    ques.Related_To_Column__c = colNum;
                }
            }
            if(questionToUpdate.size()>0 && Schema.SObjectType.Question__c.isUpdateable()){
                Update Security.stripInaccessible(AccessType.UPDATABLE, questionToUpdate).getRecords();
            }
        }
    }
    
    /**
     * @description Create Page
     * @param  formPage : form page
     * @return  Form_Pagination__c
     */
    @AuraEnabled
    public static Form_Pagination__c createPage(Form_Pagination__c formPage){
        try {            
            Insert formPage;
            
            //Create page
            List<Form_Page__c> formPages = new List<Form_Page__c>();
            Decimal i = formPage.Total_Pages__c;
            Decimal j=1;
            for(;j<=i;){
                formPages.add(new Form_Page__c(Page_Name__c='Page '+j,Page_No__c=j,Form_Pagination__c=formPage.Id,Section__c=''));
                j = j + 1;
            }
            Insert Security.stripInaccessible(AccessType.CREATABLE, formPages).getRecords();
            return getPage(formPage.Questionnaire__c);
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description update Pagination Action
     * @param  formPage : form page
     * @return  Form_Pagination__c
     */
    @AuraEnabled
    public static Form_Pagination__c updatePaginationAction(Form_Pagination__c formPage){
        try {
            Form_Pagination__c existingPagination = [SELECT Total_Pages__c FROM Form_Pagination__c WHERE Questionnaire__c=:formPage.Questionnaire__c WITH SECURITY_ENFORCED];
            System.debug(Logginglevel.DEBUG, formPage);
            System.debug(Logginglevel.DEBUG, existingPagination);
            if(existingPagination.Total_Pages__c < formPage.Total_Pages__c){
                //new page will be add
                List<Form_Page__c> formPages = new List<Form_Page__c>();
                Decimal i = existingPagination.Total_Pages__c+1;
                for(;i<=formPage.Total_Pages__c;i++){
                    formPages.add(new Form_Page__c(Page_Name__c='Page '+i,Page_No__c=i,Form_Pagination__c=formPage.Id,Section__c=''));
                }
                Insert Security.stripInaccessible(AccessType.CREATABLE, formPages).getRecords();
            }
            else{
                List<String> pageList = new List<String>();
                //previous page will be delete
                Decimal i = 1;
                for(;i<=existingPagination.Total_Pages__c;){
                    if(i > formPage.Total_Pages__c){
                        pageList.add('Page '+i);
                    }
                    i = i + 1;
                }
                if(Schema.SObjectType.Form_Page__c.isDeletable()){
                    System.debug(Logginglevel.DEBUG, pageList);
                    delete ([SELECT Id FROM Form_Page__c WHERE Page_Name__c IN:pageList WITH SECURITY_ENFORCED]);
                }
            }
            Update formPage;            
            return getPage(formPage.Questionnaire__c);
        } 
        catch (Exception e) {
            System.debug(Logginglevel.DEBUG, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description get Page Detail
     * @param  qid
     * @return  Form_Pagination__c
     */
    @AuraEnabled
    public static Form_Pagination__c getPage(String qid){
        try {
            
            List<Form_Pagination__c> fpList = [SELECT Id,Total_Pages__c,Questionnaire__c,Name,(SELECT Id,Page_Name__c,Section__c FROM Form_Pages__r ORDER BY Page_No__c ASC) FROM Form_Pagination__c WHERE Questionnaire__c=:String.escapeSingleQuotes(qid) WITH SECURITY_ENFORCED LIMIT 1];
            //Form_Page__c
            return !fpList.isEmpty()?fpList[0]:new Form_Pagination__c(Total_Pages__c=1,Questionnaire__c=qid,Name='');
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description update Selected Page
     * @param  pageObj
     * @param  sectId
     */
    @AuraEnabled
    public static void updateSelectedPage(Form_Page__c pageObj, String sectId){
        try {
            System.debug(Logginglevel.DEBUG, pageObj+','+sectId);
            if(pageObj.Section__c!=null && pageObj.Section__c!='' && pageObj.Section__c.indexOf(sectId)<0){
                pageObj.Section__c = pageObj.Section__c+','+sectId;
                pageObj.Section__c = pageObj.Section__c.replaceAll(',,',',');
                pageObj.Section__c = pageObj.Section__c.trim();
            }
            else{
                pageObj.Section__c = sectId;
            }

            String queryParam = '%'+String.escapeSingleQuotes(sectId)+'%';
            List<Form_Page__c> pageList = [SELECT Id,Section__c FROM Form_Page__c WHERE Section__c LIKE:queryParam AND Id!=:pageObj.Id WITH SECURITY_ENFORCED];
            for(Form_Page__c page : pageList){
                page.Section__c = page.Section__c.replaceAll(sectId,'');
                page.Section__c = page.Section__c.replaceAll(',,',',');
            }
            
            pageList.add(pageObj);
            Update Security.stripInaccessible(AccessType.UPDATABLE, pageList).getRecords();            
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }    
}