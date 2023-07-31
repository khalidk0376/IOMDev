/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 14 Sept, 2021
* @description           : Use to download form response
* Test Class             : DownloadResonsePDFCtrTest 
* Code Coverage          : 79%
* Modified by            : Girikon(Mukesh),[Aishwarya IMCC-4506 08 Sep 2022]
**/
public with sharing class DownloadResonsePDFCtr {
  /**
  * fetch Questionnaire form record behelf of current login user and questionnaire form id and questionnaire id.
  * @return [a questionniare form information]
  */
  String entryId;
  String contId; //contact id
  String ceid; //contact edition mapping id
  String questnnaireId; // template id
  public List<Question_Option__c> qOptions{get;set;}
  public DownloadResonsePDFCtr() {
    contId = UserInfo.getUserId();
    questnnaireId = ApexPages.currentPage().getParameters().get('qnaireId');
    questnnaireId = questnnaireId!=null?questnnaireId.escapeHtml4():'';
    ceid = ApexPages.currentPage().getParameters().get('ceid');
    ceid = ceid!=null?ceid.escapeHtml4():'';
    entryId = ApexPages.currentPage().getParameters().get('e');//e param for entry number
    entryId = entryId!=null?entryId.escapeHtml4():'';
    DateTime dateTimeObj = System.now();        
  }
  
    public Questionnaire__c getTemplateRecord() {        
        Questionnaire__c objQForm = new Questionnaire__c();
        if(String.isNotBlank(contId) && String.isNotBlank(questnnaireId)){
            objQForm = [SELECT id,Name,Description__c FROM Questionnaire__c WHERE Id=:String.escapeSingleQuotes(questnnaireId) WITH SECURITY_ENFORCED];
        }
        return objQForm; 
    }
    
    /**
     * Fetch user respone with question and question group
     * Apply questinnaire dynamic logic for question options.
     * Apply sorting under the Question group.
     * @return [list for QuestionGroupWithQuestionsWrap class]
     */
    public List<QuestionGroupWithQuestionsWrap> getQuestnsForQuesGroup() {
        System.debug('lstQuesQuestionnaire');
    List<QuestionGroupWithQuestionsWrap> lstQGWQuesWrap = new List<QuestionGroupWithQuestionsWrap>();
        Map<Id,QuestionGroupWithQuestionsWrap> mapQGWQuesWrap = new Map<Id,QuestionGroupWithQuestionsWrap>();         
        Map<id,List<Question_Questionnaire__c>> mapSectionQuestn = new Map<id,List<Question_Questionnaire__c>>();
        Map<String,String> optMap = new Map<String,String>();
        try{
          if(String.isNotBlank(contId) && String.isNotBlank(questnnaireId)){            
            Map<Id,List<Question_Questionnaire__c>> mapGroupQuestn =  new Map<id,List<Question_Questionnaire__c>>();
        Map<Id,String> mapGroupName = new Map<Id,String>();
        List<Question_Questionnaire__c> lstQuesQuestionnaire = new List<Question_Questionnaire__c>();
        
        lstQuesQuestionnaire.addAll([SELECT id,Question_Group__c,Question__r.background_Color__c,Question__r.Metadata__c,Allow_Attachments__c,
                    Allow_Comment__c,Question__c,Question__r.Type__c,Metadata__c,Question__r.Label__c,Question_Order__c,Question_Group__r.Name,
                    Question_Group__r.No_Of_Columns__c FROM Question_Questionnaire__c WHERE (Question__r.Related_To_Column__c='col1' OR Question__r.Related_To_Column__c='col2') AND is_Delete__c=false AND Questionnaire__c =:String.escapeSingleQuotes(questnnaireId) WITH SECURITY_ENFORCED
                    ORDER by Question_Group__r.Sort_Order__c,Question__r.Related_To_Column__c, Question_Order__c asc]);
                
                //System.debug(lstQuesQuestionnaire);
                Map<Id,Id> mapQuestnId = new Map<Id,Id>();
        //variable to store QuestionId of checkbox,radio,picklist and switch type question        
        List<String> qstOption = new List<String>();
        
        //Set Question Questionnnaire record behalf of Question Group.
        for(Question_Questionnaire__c objQQuestnnaire:lstQuesQuestionnaire){
            if(objQQuestnnaire.Question__c != null){
            // picklist and
            if(objQQuestnnaire.Question__r.Type__c=='Picklist' || objQQuestnnaire.Question__r.Type__c=='Radio'){
              qstOption.add(objQQuestnnaire.Question__c);
            }
              //System.debug(objQQuestnnaire.Question__r.Label__c);
              mapQuestnId.put(objQQuestnnaire.Question__c,objQQuestnnaire.id);              
              if(mapGroupQuestn.containsKey(objQQuestnnaire.Question_Group__c)) {
                  List<Question_Questionnaire__c> lstQuesQuestionnaire1 = mapGroupQuestn.get(objQQuestnnaire.Question_Group__c);
                  lstQuesQuestionnaire1.add(objQQuestnnaire);
                  mapGroupQuestn.put(objQQuestnnaire.Question_Group__c,lstQuesQuestionnaire1);                  
              }
              else{                  
                  List<Question_Questionnaire__c> lstQuesQuestionnaire1 = new List<Question_Questionnaire__c>();
                  lstQuesQuestionnaire1.add(objQQuestnnaire);
                  mapGroupQuestn.put(objQQuestnnaire.Question_Group__c,lstQuesQuestionnaire1);
              }
              mapGroupName.put(objQQuestnnaire.Question_Group__c,objQQuestnnaire.Question_Group__r.Name);          
          }
        }
        
        qOptions = [SELECT Id, Name_Long__c FROM Question_Option__c WHERE Question__c IN:qstOption WITH SECURITY_ENFORCED];
        for(Question_Option__c op : qOptions){
          optMap.put(op.Id,op.Name_Long__c);
        }
        //Filter the Question questionnaire record with question group.
        for(Id keyGroupId : mapGroupQuestn.keySet()){
          QuestionGroupWithQuestionsWrap oQGWQuesWrap = new QuestionGroupWithQuestionsWrap();
          oQGWQuesWrap.groupName = mapGroupName.get(keyGroupId);
          oQGWQuesWrap.groupId = keyGroupId;          
          oQGWQuesWrap.mapQuestnRespWithBranch = new Map<id,QuestionWithResponse>();
          for(Question_Questionnaire__c oGQQnaire :mapGroupQuestn.get(keyGroupId)){
            QuestionWithResponse objQWithResp = new QuestionWithResponse();
            objQWithResp.objQQnaire = oGQQnaire;
            objQWithResp.objQResp = new Question_Response__c();

            objQWithResp.lstBranchingQQnaire = new List<QuestionWithResponse>();
            oQGWQuesWrap.mapQuestnRespWithBranch.put(oGQQnaire.id,objQWithResp);
          }
          mapQGWQuesWrap.put(keyGroupId,oQGWQuesWrap);
        }
        //fetching Questinnaire Dynamic logic record for Question options.
            Map<Id,List<Id>> mapOptionWithDyloigc = new Map<Id,List<Id>>();
            List<Questionnaire_Dynamic_Logic__c>  lstQDyLoic = getBranchingQuestn(mapGroupQuestn.keySet());
            for(Questionnaire_Dynamic_Logic__c oQDl :lstQDyLoic){
                    List<Id> lstQWithDyLoicId = (mapOptionWithDyloigc.containsKey(oQDl.Question_Option__c)?mapOptionWithDyloigc.get(oQDl.Question_Option__c):(new List<Id>()));
              lstQWithDyLoicId.add(oQDl.Show_Question_Questionnaire__c);mapOptionWithDyloigc.put(oQDl.Question_Option__c,lstQWithDyLoicId);
            }
                
            //fetching question options and question questionnaire record of Question.
            Map<Id,List<Question_Option__c>> mapQOption = new Map<Id,List<Question_Option__c>>();
            Map<Id,Id> mapNotAnsBranchingQue =new Map<Id,Id>();
            List<Question__c> lstQuestn = new List<Question__c>();
                // Changes Here for Long
        lstQuestn = [SELECT id,background_Color__c,(SELECT id, Name,Value__c,Name__c,Name_Long__c,Question__r.Type__c,Question__c FROM Question_Options__r ORDER BY Index__c asc LIMIT 20),(SELECT id,Question__r.Type__c,Question__c FROM Question_Questionnaires__r LIMIT 1) FROM Question__c WHERE Id IN :mapQuestnId.keySet() WITH SECURITY_ENFORCED];
        
        for(Question__c oQuestn : lstQuestn){
          IF(oQuestn.Question_Questionnaires__r != null){
            mapQOption.put(oQuestn.Question_Questionnaires__r[0].id,oQuestn.Question_Options__r);
            for(Question_Option__c objMapOption: oQuestn.Question_Options__r){
              objMapOption.Name = objMapOption.Name_Long__c;// Add: Changes Here for Long
              objMapOption.Name__c = objMapOption.Name_Long__c;// Add: Changes Here for Long
              mapNotAnsBranchingQue.put(objMapOption.Id,oQuestn.Question_Questionnaires__r[0].id);
            }
          }
        }
        //find question which are setting question of under branching record.
        //mapping of the branching question on Question Questionnaire behalf.
        Map<Id,List<Id>> mapBranching = new Map<Id,List<Id>>();
        List<Question_Response__c> lstQuestnResponse = new List<Question_Response__c>();
        
        List<AggregateResult> arList = [SELECT Question__c,count(id) FROM Question_Response__c WHERE Questionnaire__c=:String.escapeSingleQuotes(questnnaireId) AND Contact_Edition_Mapping__c=:ceid WITH SECURITY_ENFORCED GROUP BY Question__c];
        Integer resultSize = arList.size();
        lstQuestnResponse = [SELECT Id,Answer_Long__c,(Select id,Name,Description from Attachments),Comment__c,User__c,Question_Questionnaire__r.Question_Group__r.Name,Questionnaire__c,
          Question_Questionnaire__r.Question_Group__c,Question_Questionnaire__c,Question__r.Is_MultiSelect__c FROM Question_Response__c
          WHERE Questionnaire__c=:String.escapeSingleQuotes(questnnaireId) AND Form_Response_Entry__c=:entryId AND Contact_Edition_Mapping__c =:String.escapeSingleQuotes(ceid) AND Question_Questionnaire__c IN :lstQuesQuestionnaire WITH SECURITY_ENFORCED Order BY Form_Response_Entry__r.Entry_Number__c DESC LIMIT :resultSize];

            for(Question_Response__c obQResp :lstQuestnResponse) {

              if(mapQGWQuesWrap.containsKey(obQResp.Question_Questionnaire__r.Question_Group__c) ){
                QuestionGroupWithQuestionsWrap oQGWQuesWrap = mapQGWQuesWrap.get(obQResp.Question_Questionnaire__r.Question_Group__c) ;
                if(oQGWQuesWrap.mapQuestnRespWithBranch.containsKey(obQResp.Question_Questionnaire__c)) {
                  QuestionWithResponse objQWithResp = oQGWQuesWrap.mapQuestnRespWithBranch.get(obQResp.Question_Questionnaire__c);
                  objQWithResp.objQResp =obQResp;                            
                          String answer = obQResp.Answer_Long__c;   
              if(String.isNotBlank(answer) && objQWithResp.objQQnaire.Question__r.Type__c =='DateTime'){
                  obQResp.Answer_Long__c = ((DateTime)JSON.deserialize('"'+answer+'"', DateTime.class)).format('dd MMM yyyy HH:mm:ss', 'GMT')+''; //IMCC-4506
              } 
              if(String.isNotBlank(answer) && objQWithResp.objQQnaire.Question__r.Type__c =='Date'){
                  obQResp.Answer_Long__c = ((DateTime)JSON.deserialize('"'+answer+'T00:00:00.000Z"', DateTime.class)).format('dd MMM yyyy', 'GMT')+''; //IMCC-4506
              }                        
                            if(String.isNotBlank(answer) && (objQWithResp.objQQnaire.Question__r.Type__c =='Picklist' || objQWithResp.objQQnaire.Question__r.Type__c =='Radio')){
                                if(mapQOption.containsKey(obQResp.Question_Questionnaire__c)){
                                    for(Question_Option__c objOption :mapQOption.get(obQResp.Question_Questionnaire__c)){
                                        //system.debug(objOption.Name__c +'=='+ answer+',');                                            
                                        String temp = String.valueOf(objOption.Id);
                    if(answer!='' && temp == answer && mapOptionWithDyloigc.containsKey(temp)){
                                            mapBranching.put(obQResp.Question_Questionnaire__c,mapOptionWithDyloigc.get(objOption.Id));
                                            mapNotAnsBranchingQue.remove(objOption.Id);
                                            //obQResp.Answer__c = objOption.Name__c;//Comment: Changes Here for Long
                                            obQResp.Answer_Long__c = objOption.Id;//Add: Changes Here for Long
                                            System.debug(mapBranching.keySet());
                                        }                      
                                    }
                                }
              }
                            else if(String.isNotBlank(answer) && (objQWithResp.objQQnaire.Question__r.Type__c =='Checkbox' || objQWithResp.objQQnaire.Question__r.Type__c =='Switch')){
                                answer = Boolean.valueOf(answer)?'Checked':'Unchecked';
                                for(Question_Option__c objOption :mapQOption.get(obQResp.Question_Questionnaire__c)){                                        
                                    //if(objOption.Name__c == answer && mapOptionWithDyloigc.containsKey(objOption.Id)){  //Comment: Changes Here for Long                                          
                                    if(objOption.Name_Long__c == answer && mapOptionWithDyloigc.containsKey(objOption.Id)){                                            
                                        mapBranching.put(obQResp.Question_Questionnaire__c,mapOptionWithDyloigc.get(objOption.Id));
                                        mapNotAnsBranchingQue.remove(objOption.Id);
                                    }
                                }
                            }                            
                  oQGWQuesWrap.mapQuestnRespWithBranch.put(obQResp.Question_Questionnaire__c,objQWithResp);
                }
                mapQGWQuesWrap.put(obQResp.Question_Questionnaire__r.Question_Group__c,oQGWQuesWrap);
              }
            }
            
            lstQGWQuesWrap = mapQGWQuesWrap.values();                
        //remove under branching question for picklist record.
            //the user does not answer the questions  
            List<Id> allChildQst = new List<Id>();
                for(List<Id> i : mapBranching.values()){allChildQst.addAll(i);}
                    
                for(QuestionGroupWithQuestionsWrap objQGQWrap :lstQGWQuesWrap){
          for(Id keyDylId : mapNotAnsBranchingQue.keyset()){
            if(mapOptionWithDyloigc.containsKey(keyDylId)){
              for(Id keyNotRespQId : mapOptionWithDyloigc.get(keyDylId)){if(objQGQWrap.mapQuestnRespWithBranch.containsKey(keyNotRespQId) && allChildQst.indexOf(keyNotRespQId)<0){objQGQWrap.mapQuestnRespWithBranch.remove(keyNotRespQId);}
              }
            }
            
          }
        }
        //find question which are setting question of under branching record.
        Map<id,List<QuestionWithResponse>> mapQwithBranching  = new Map<id,List<QuestionWithResponse>>();
        for(QuestionGroupWithQuestionsWrap objQGQWrap :lstQGWQuesWrap){
          for(Id idQQnaire :objQGQWrap.mapQuestnRespWithBranch.keyset()){
            if(mapBranching.containsKey(idQQnaire)){
              for(Id obId: mapBranching.get(idQQnaire)){List<QuestionWithResponse> lstQR = (mapQwithBranching.containsKey(idQQnaire)?mapQwithBranching.get(idQQnaire):(new List<QuestionWithResponse>()));
                lstQR.add(objQGQWrap.mapQuestnRespWithBranch.get(obId));mapQwithBranching.put(idQQnaire,lstQR);
                objQGQWrap.mapQuestnRespWithBranch.remove(obId);
              }
            }
          }
        }
        //combining branching record with a question. 
        for(QuestionGroupWithQuestionsWrap objQGQWrap :lstQGWQuesWrap){
          for(Id keyBrnhId :mapQwithBranching.keySet()){
            if(objQGQWrap.mapQuestnRespWithBranch.containsKey(keyBrnhId)){QuestionWithResponse objQR= objQGQWrap.mapQuestnRespWithBranch.get(keyBrnhId);
                          objQR.lstBranchingQQnaire = mapQwithBranching.get(keyBrnhId);objQGQWrap.mapQuestnRespWithBranch.put(keyBrnhId,objQR);
            }
          }
        }
        
        //call sorting Method for reorder the questions. 
        for(QuestionGroupWithQuestionsWrap objQGQWrap :lstQGWQuesWrap){
          objQGQWrap.lstQuestnRespWithBranch = sortQuestionOrder(objQGQWrap.mapQuestnRespWithBranch.values());
          objQGQWrap.mapQuestnRespWithBranch.clear();
        }
        System.debug(JSON.serialize(lstQGWQuesWrap));
          }
      
      //Replace option id by option label
      for(QuestionGroupWithQuestionsWrap objQGQWrap :lstQGWQuesWrap){
        for(QuestionWithResponse qQnnaire : objQGQWrap.lstQuestnRespWithBranch){          
          if(!qQnnaire.objQResp.Question__r.Is_MultiSelect__c && qQnnaire.objQResp.Answer_Long__c!=null && qQnnaire.objQResp.Answer_Long__c!='' && optMap.containsKey(qQnnaire.objQResp.Answer_Long__c))
          {
            qQnnaire.objQResp.Answer_Long__c = optMap.get(qQnnaire.objQResp.Answer_Long__c);
          }
          else if(qQnnaire.objQResp.Question__r.Is_MultiSelect__c && qQnnaire.objQResp.Answer_Long__c!=null && qQnnaire.objQResp.Answer_Long__c!=''){
            String temp = '';
            for(String str : qQnnaire.objQResp.Answer_Long__c.split(';')){
              if(optMap.containsKey(str)){
                temp += temp!=''?','+optMap.get(str):optMap.get(str);
              }
            }
            qQnnaire.objQResp.Answer_Long__c = temp;
          }
          for(QuestionWithResponse bqQnnaire : qQnnaire.lstBranchingQQnaire){
            if(!bqQnnaire.objQResp.Question__r.Is_MultiSelect__c && bqQnnaire.objQResp.Answer_Long__c!=null && bqQnnaire.objQResp.Answer_Long__c!='' && optMap.containsKey(qQnnaire.objQResp.Answer_Long__c))
            {
              bqQnnaire.objQResp.Answer_Long__c = optMap.get(bqQnnaire.objQResp.Answer_Long__c);
            }
            else if(bqQnnaire.objQResp.Question__r.Is_MultiSelect__c && bqQnnaire.objQResp.Answer_Long__c!=null && bqQnnaire.objQResp.Answer_Long__c!=''){
              String temp = '';
              for(String str : bqQnnaire.objQResp.Answer_Long__c.split(';')){
                if(optMap.containsKey(str)){
                  temp += temp!=''?','+optMap.get(str):optMap.get(str);
                }
              }
              bqQnnaire.objQResp.Answer_Long__c = temp;
            }
          }          
        }        
      }
        }
    catch(Exception ex){
      system.debug('error message'+ex.getmessage()+' line number'+ex.getlinenumber());
    }
        //system.debug(JSON.serialize(lstQGWQuesWrap));
        return lstQGWQuesWrap;
    }
    /**
     * Apply sorting under the question group's questions.
     * @param  listQuestion [set list of QuestionWithResponse wrapper class]
     * @return              [list of QuestionWithResponse wrapper class]
     */
   private List<QuestionWithResponse> sortQuestionOrder(List<QuestionWithResponse> listQuestion){
      if(listQuestion != null && !listQuestion.isEmpty()){
          // ASCENDING ORDER
          for(Integer i = 0 ; i < listQuestion.size() ; i ++) {
              for(integer j = i+1 ; j <= listQuestion.size() -1 ; j ++ ){
                  System.debug(LoggingLevel.debug, '@@@@@@@@@@@@'+listQuestion[i].objQQnaire.Question__r.Type__c);                    
              }
          }
      }
      return listQuestion;
    }
    
    /**
     * [fetch Questionnaire dynamic logic record behelf of section id]
     * @param  lstSectionId [set the list of question group id]
     * @return              [list of Questionnaire dynamic logic]
     */
    private List<Questionnaire_Dynamic_Logic__c> getBranchingQuestn(Set<Id> lstSectionId){
        return [Select Id,Question_Questionnaire__c,Question_Questionnaire__r.Question__r.Type__c,Question_Questionnaire__r.Question__c,Question_Option__c,Question_Option__r.Name__c,Question_Option__r.Name_Long__c,Show_Question_Questionnaire__c from 
          Questionnaire_Dynamic_Logic__c where Question_Group__c IN :lstSectionId WITH SECURITY_ENFORCED];        
    }

    /**wrapper class for Question Group **/
    public class QuestionGroupWithQuestionsWrap{
        public String groupName{get;set;}
        public String groupId{get;set;}        
        public Map<id,QuestionWithResponse> mapQuestnRespWithBranch{get;set;}
        public List<QuestionWithResponse> lstQuestnRespWithBranch{get;set;}
    }

    /**wrapper class for Question with response and branching record.**/
    public class QuestionWithResponse{
      public Question_Questionnaire__c objQQnaire{get;set;}
      public Question_Response__c objQResp{get;set;}
      public List<QuestionWithResponse> lstBranchingQQnaire{get;set;}
    }
}