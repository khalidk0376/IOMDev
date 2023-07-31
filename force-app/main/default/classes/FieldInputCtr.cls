/**
 * TestClasses: FieldInputCtr_Test
 * Code Coverage : 91%
 */
public with sharing class FieldInputCtr
{
    /** 
* Create question and question questionnaire.
* @param  qnaireId: Questionnaire id.
* @param  qGroupId: Question group id.
* @param  question: Question object values.
* @param  qnaireName : Questionnaire name.
* @param  qOrder: Order of question.
* @param  colNumber: column number of question.
*/
    @AuraEnabled
    public static void createQuestnAndQuestnQnaire(String qnaireId,String qGroupId,Question__c question,String qnaireName,String qOrder,String colNumber)
    {
        try
        {
            String sQLib = NewCreateTemplateCtr.getDefaultQuestnLibraryId();
        
            question.Related_To_Column__c = colNumber;
            if(String.isNotBlank(sQLib)){
                question.Question_Library__c = sQLib; 
            }
            System.debug('qOrder::: '+qOrder);

            question.Name = String.valueOf(FieldInputCtr.countQuestnQuestnnaireRecord(qnaireId, qGroupId));
            SObjectAccessDecision sd = Security.stripInaccessible(AccessType.CREATABLE, new List<Question__c>{question}); 
            Insert sd.getRecords();
            question = [SELECT Id,Type__c,Currency_Symbol__c,lookup_Object_Field_Name__c,lookup_Object_API_Name__c,Required__c,Allow_Currency__c,Decimal_value__c,Help_Text__c,Help_Text_Required__c,Category__c,Allow_Attachments__c,Allow_Comment__c,Is_Allow_Branching__c,Max_Char_Length__c,Minimum_Value__c,Maximum_value__c,Step_Size__c,Default_Value__c FROM Question__c WHERE Id=:sd.getRecords()[0].Id WITH SECURITY_ENFORCED];

            Question_Questionnaire__c oQQuesnaire= new Question_Questionnaire__c(Required__c=question.Required__c,
            Allow_Currency__c =question.Allow_Currency__c,Decimal_value__c =question.Decimal_value__c,
            Related_To_Column__c=colNumber,Help_Text__c=question.Help_Text__c,Help_Text_Required__c=question.Help_Text_Required__c,
            Category__c=question.Category__c,Allow_Attachments__c=question.Allow_Attachments__c,Allow_Comment__c=question.Allow_Comment__c,
            Questionnaire__c = qnaireId,Name=qnaireName,Question_Group__c =qGroupId,Question__c=question.id,
            Question_Order__c=Integer.valueOf(qOrder),Is_Allow_Branching__c =question.Is_Allow_Branching__c);
        
            oQQuesnaire.Max_Char_Length__c=(question.Max_Char_Length__c != null?question.Max_Char_Length__c:0);
            oQQuesnaire.Minimum_Value__c=(question.Minimum_Value__c != null?question.Minimum_Value__c:0);
            oQQuesnaire.Maximum_value__c=(question.Maximum_value__c != null?question.Maximum_value__c:0);
            oQQuesnaire.Step_Size__c=(question.Step_Size__c != null?question.Step_Size__c:0);
            oQQuesnaire.Default_Value__c=(question.Default_Value__c != null?question.Default_Value__c:0);
            
            if(String.isNotBlank(question.lookup_Object_API_Name__c )){
                oQQuesnaire.lookup_Object_API_Name__c =question.lookup_Object_API_Name__c;
                oQQuesnaire.lookup_Object_Field_Name__c =question.lookup_Object_Field_Name__c;  
            }
            if(String.isNotBlank(question.Currency_Symbol__c)){
                oQQuesnaire.Currency_Symbol__c=question.Currency_Symbol__c;
            }
            SObjectAccessDecision sd2 = Security.stripInaccessible(AccessType.CREATABLE, new List<Question_Questionnaire__c>{oQQuesnaire});
            Insert sd2.getRecords();            
            sortQuestions(sd2.getRecords()[0].Id,qnaireId,qGroupId,colNumber,Integer.valueOf(qOrder));
            
            if(question.type__c=='Checkbox'){
                List<Question_Option__c> listQuestnOption = new List<Question_Option__c>();
                // Changes Here for Long
                Question_Option__c questnOptionChecked = new Question_Option__c(Question__c=question.id,Name='Checked',Name__c='Checked',Name_Long__c='Checked');
                listQuestnOption.add(questnOptionChecked);
                // Changes Here for Long
                Question_Option__c questnOptionUnchecked = new Question_Option__c(Question__c=question.id,Name='Unchecked',Name__c='Unchecked',Name_Long__c='Unchecked');
                listQuestnOption.add(questnOptionUnchecked);
                // Changes Here for Long                    
                Insert Security.stripInaccessible(AccessType.CREATABLE, listQuestnOption).getRecords();                
            }        
        }
        catch(Exception ex){
            System.debug(ex.getMessage()+', '+ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage()+', '+ex.getLineNumber());
        } 
    }
    
    /**
    * count Question Questionnaire record.
    * @param  qqId    : Question Questionnaire record id    
	* @param  colNum  : Related To Column like col1 or col2
	* @param  qnaireId: Questionnaire record id
    * @param  groupId : Queston Group record id
    * @param  qOrder  : Order of question from top position 
    */
    public static void sortQuestions(String qqId,String qnaireId, String groupId,String colNum,Integer qOrder)
    {        
        List<Question_Questionnaire__c> qqList = [SELECT id,Question_Order__c from Question_Questionnaire__c WHERE 
            Related_To_Column__c=:String.escapeSingleQuotes(colNum) AND Question_Group__c=:String.escapeSingleQuotes(groupId) AND Question_Order__c!=null AND 
            Questionnaire__c=:String.escapeSingleQuotes(qnaireId) AND is_Delete__c=false WITH SECURITY_ENFORCED ORDER BY Question_Order__c ASC];
        Question_Questionnaire__c temp;
        Integer total = qqList.size();
        Integer order=0;
        for(integer i=0;i<total;i++){
            order = order + 1;
            if(i<qOrder){
                continue;
            }
            if(qqList[i].Id==qqId){
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Question_Order__c.isUpdateable()){
                    qqList[i].Question_Order__c=qOrder;
                    order = qOrder + 1;
                }
            }
            else{
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Question_Order__c.isUpdateable()){
                	qqList[i].Question_Order__c=order;    
                }
            }
        }
        if(Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
            Update Security.stripInaccessible(AccessType.UPDATABLE, qqList).getRecords();
        }
    }
    
    /**
    * count Question Questionnaire record.
    * @param  qnaireId : Questionnaire record id
    * @param  qnaireId : Queston Group record id
    */
    public static Integer countQuestnQuestnnaireRecord(String qnaireId,String qGroupId){        
        return [SELECT count() From Question_Questionnaire__c where Questionnaire__c =:String.escapeSingleQuotes(qnaireId) AND Question_Group__c =:String.escapeSingleQuotes(qGroupId) WITH SECURITY_ENFORCED];
    }

    /**
    * save edited Question and Question Questionniare record
    * @param  oQues: Question object values.
    * @param  qnaireId: Questionnaire id.
    * @param  sectionId: Question group(Section) Id.
    */
    @AuraEnabled
    public static void saveEditQuesRecord(Question__c oQues,String qnaireId,String sectionId,Boolean isUnderBranching) {
        if (oQues != null) 
        {
            if(oQues.Help_Text_Required__c==false && Schema.SObjectType.Question__c.fields.Help_Text__c.isUpdateable()){
                oQues.Help_Text__c='';
            }
            if(Schema.SObjectType.Question__c.isUpdateable()){
                Update Security.stripInaccessible(AccessType.UPDATABLE, new List<Question__c>{oQues}).getRecords();                
            }
            
            List<Question_Questionnaire__c> lstQQnnaire=[SELECT Id,Is_Allow_Branching__c FROM Question_Questionnaire__c WHERE Question__c=:String.escapeSingleQuotes(oQues.id) and Questionnaire__c=:String.escapeSingleQuotes(qnaireId) and Question_Group__c=:String.escapeSingleQuotes(sectionId) WITH SECURITY_ENFORCED];
            if(!lstQQnnaire.isEmpty())
            {
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Allow_Attachments__c.isUpdateable()){
                    lstQQnnaire[0].Allow_Attachments__c=oQues.Allow_Attachments__c;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Allow_Comment__c.isUpdateable()){
                    lstQQnnaire[0].Allow_Comment__c=oQues.Allow_Comment__c;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Help_Text_Required__c.isUpdateable()){
                    lstQQnnaire[0].Help_Text_Required__c=oQues.Help_Text_Required__c;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Help_Text__c.isUpdateable()){
                    lstQQnnaire[0].Help_Text__c='';
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Required__c.isUpdateable()){
                    lstQQnnaire[0].Required__c=oQues.Required__c;
                }                
                if(oQues.Help_Text_Required__c==true && Schema.SObjectType.Question_Questionnaire__c.Fields.Help_Text__c.isUpdateable()){
                    lstQQnnaire[0].Help_Text__c=oQues.Help_Text__c;
                }
                if(String.isNotBlank(oQues.Currency_Symbol__c) && Schema.SObjectType.Question_Questionnaire__c.Fields.Currency_Symbol__c.isUpdateable()){
                    lstQQnnaire[0].Currency_Symbol__c=oQues.Currency_Symbol__c;
                }
                if(String.isNotBlank(oQues.lookup_Object_API_Name__c)){                    
                    lstQQnnaire[0].lookup_Object_API_Name__c =oQues.lookup_Object_API_Name__c;                    
                    lstQQnnaire[0].lookup_Object_Field_Name__c =oQues.lookup_Object_Field_Name__c;                      
                }                
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Is_Allow_Branching__c.isUpdateable()){
                    lstQQnnaire[0].Is_Allow_Branching__c =oQues.Is_Allow_Branching__c;
                }
                if(lstQQnnaire[0].Is_Allow_Branching__c==false && oQues.Type__c=='Checkbox' && isUnderBranching ==false){
                    NewCreateTemplateCtr.delQuestnDynLogic(lstQQnnaire[0].id);
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Minimum_Value__c.isUpdateable()){
                    lstQQnnaire[0].Minimum_Value__c=(oQues.Minimum_Value__c != null?oQues.Minimum_Value__c:0);
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Maximum_value__c.isUpdateable()){
                    lstQQnnaire[0].Maximum_value__c=(oQues.Maximum_value__c != null?oQues.Maximum_value__c:0);
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Step_Size__c.isUpdateable()){
                    lstQQnnaire[0].Step_Size__c=(oQues.Step_Size__c != null?oQues.Step_Size__c:0);
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Default_Value__c.isUpdateable()){
                    lstQQnnaire[0].Default_Value__c=(oQues.Default_Value__c != null?oQues.Default_Value__c:0);
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Decimal_value__c.isUpdateable()){
                    lstQQnnaire[0].Decimal_value__c =oQues.Decimal_value__c;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Allow_Currency__c.isUpdateable()){
                    lstQQnnaire[0].Allow_Currency__c =oQues.Allow_Currency__c;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Max_Char_Length__c.isUpdateable()){
                    lstQQnnaire[0].Max_Char_Length__c =(oQues.Max_Char_Length__c != null?oQues.Max_Char_Length__c:0);
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Category__c.isUpdateable()){
                    lstQQnnaire[0].Category__c=oQues.Category__c;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
                    Update Security.stripInaccessible(AccessType.UPDATABLE, lstQQnnaire).getRecords();
                }
            }        
        }
    }
    
    /**
    * fetch Question Currency Symbols picklist value
    * @return : list of Question Currency sysmbol.
    */
    @AuraEnabled
    public static List<String> getQueCurrencySymbol(){
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Question__c.Currency_Symbol__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }
        return options;
    }
    
    /**
    * fetch all sobject name in org.
    * @return : list of sobject name.
    */
    @AuraEnabled
    public static List<ObjectWrapper> getAllsObjectName(){
        List<ObjectWrapper> sObjectList = new List<ObjectWrapper>();
        
        AggregateResult[] groupedObjPermResult =[SELECT SObjectType From ObjectPermissions where SObjectType NOT IN('Question_Map_To_Object__c','FormAssignment__c','Question_And_Field__c','FB_Temp__c','Question__c','Question_Library__c','Question_Option__c','Question_Group__c','Questionnaire__c','Question_Questionnaire__c','Questionnaire_Dynamic_Logic__c','Question_Response__c','Questionnaire_Form__c','Questionnaire_Schedule__c','Questionnaire_Schedule_User__c') WITH SECURITY_ENFORCED Group By SObjectType order by SObjectType ASC];
        String objNameStr='';
        for(AggregateResult arResult : groupedObjPermResult)
        {
            if(arResult.get('SObjectType') != null && Type.forName(String.valueOf(arResult.get('SObjectType'))) != null)
            {
                objNameStr = String.valueOf(arResult.get('SObjectType'));
                if(!objNameStr.containsignorecase('history') && ! objNameStr.containsignorecase('tag')&&
                    !objNameStr.containsignorecase('share') && !objNameStr.containsignorecase('feed'))
                {
                    sObjectList.add(new ObjectWrapper(objNameStr,objNameStr));
                }
            }
        }    
        return sObjectList;
    }

    /**
    * SelcetOption for Object
    */
    public class ObjectWrapper{
        @AuraEnabled public String apiName;
        @AuraEnabled public String apiLabelName;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public Schema.DisplayType fieldType;
        ObjectWrapper(String apiName,String apiLabelName){
            this.apiName =apiName;
            this.apiLabelName =apiLabelName;
        } 
        ObjectWrapper(String apiName,String apiLabelName,Boolean isRequired){
            this.apiName =apiName;
            this.apiLabelName =apiLabelName;
            this.isRequired = isRequired;
        }
        @testVisible
        ObjectWrapper(String apiName,String apiLabelName,Boolean isRequired,Schema.DisplayType fieldType){
            this.apiName =apiName;
            this.apiLabelName =apiLabelName;
            this.isRequired = isRequired;
            this.fieldType = fieldType;
        }
    }

    /**
    * fetch all sobject name in org.
    * @return : list of sobject name.
    */
    @AuraEnabled
    public static List<ObjectWrapper> getAllsObjectFieldName(String objectName){
        System.debug('objectName: '+objectName);
        
        List<ObjectWrapper> sObjectList = new List<ObjectWrapper>();
        SObjectType objToken = ((SObject)Type.forName(objectName).newInstance()).getSObjectType();
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap();  
        for(String key:fields.keySet())
        {

            Schema.DisplayType fielddataType = fields.get(key).getDescribe().getType();
            if(fielddataType  == Schema.DisplayType.String || fielddataType == Schema.DisplayType.EMAIL || fielddataType == Schema.DisplayType.Picklist ||fielddataType == Schema.DisplayType.PHONE){
                SObjectField fieldToken = fields.get(key);
                if(fieldToken.getDescribe().isAccessible() && fieldToken.getDescribe().isUpdateable()){
                    sObjectList.add(new ObjectWrapper(fieldToken.getDescribe().getName(),fieldToken.getDescribe().getLabel(),fieldToken.getDescribe().isNillable()));                    
                }
            } 
        }
        return  sObjectList;
    }
    
    @AuraEnabled
    public static List<ObjectWrapper> getAllsObjectFieldName2(String objectName){
        System.debug('objectName: '+objectName);
        
        List<ObjectWrapper> sObjectList = new List<ObjectWrapper>();
        SObjectType objToken = ((SObject)Type.forName(objectName).newInstance()).getSObjectType();
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap();  
        for(String key:fields.keySet())
        {

            Schema.DisplayType fielddataType = fields.get(key).getDescribe().getType();
            if(fielddataType  ==  Schema.DisplayType.DOUBLE || fielddataType  == Schema.DisplayType.String || fielddataType == Schema.DisplayType.EMAIL || fielddataType == Schema.DisplayType.Picklist || fielddataType == Schema.DisplayType.URL||fielddataType == Schema.DisplayType.BOOLEAN||fielddataType == Schema.DisplayType.CURRENCY||fielddataType == Schema.DisplayType.TEXTAREA||fielddataType == Schema.DisplayType.TIME||fielddataType == Schema.DisplayType.DATE||fielddataType == Schema.DisplayType.DATETIME||fielddataType == Schema.DisplayType.INTEGER||fielddataType == Schema.DisplayType.LOCATION||fielddataType == Schema.DisplayType.PHONE||fielddataType == Schema.DisplayType.PERCENT){
                SObjectField fieldToken = fields.get(key);
                if(fieldToken.getDescribe().isAccessible() && fieldToken.getDescribe().isUpdateable()){
                    sObjectList.add(new ObjectWrapper(fieldToken.getDescribe().getName(),fieldToken.getDescribe().getLabel(),fieldToken.getDescribe().isNillable(),fielddataType));                    
                }
            } 
        }
        return  sObjectList;
    }
    @AuraEnabled
    public static String getBaseUrl()
    {
        return URL.getSalesforceBaseUrl().toExternalForm()+'__'+UserInfo.getOrganizationId();
    }
    
    @AuraEnabled
    public static DocumentWrapper getAllDocuments(Decimal pageNumber){
        DocumentWrapper dwObj = new DocumentWrapper();
        List<Document> uploadedDoc = new List<Document>();        
        Integer pageSize = 25;
        Integer offset = ((Integer)pageNumber - 1) * pageSize;
        dwObj.pageSize = pageSize;
        dwObj.page = (Integer) pageNumber;
        dwObj.total=0;
        String[] docTypes = new String[]{'png','jpg','jpeg','gif','bmp'};
        String[] devNames = new String[]{'SMS_Logo','table_icon','template_icon','dashboard_icon','add'};
        String totalQuery = 'SELECT count() from document where Type IN:docTypes AND IsInternalUseOnly=false AND IsPublic=true AND DeveloperName Not IN:devNames WITH SECURITY_ENFORCED';
        dwObj.total = Database.countQuery(totalQuery);
        uploadedDoc = [SELECT id,Name from document WHERE Type IN:docTypes AND IsInternalUseOnly=false AND IsPublic=true AND DeveloperName Not IN:devNames WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT:dwObj.pageSize OFFSET:offset];        
        dwObj.uploadedDoc = uploadedDoc;
        return dwObj;
    }

    public class DocumentWrapper {
        @AuraEnabled public Integer pageSize {get;set;}
        @AuraEnabled public Integer page {get;set;}
        @AuraEnabled public Integer total {get;set;}
        @AuraEnabled public List<Document> uploadedDoc {get;set;}
    }
}