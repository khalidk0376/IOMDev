({
    getParameterByName: function (name) {
        name = name.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    },
    setFormStatusHelper: function (component, param, pageObj) {
        var methodName;
        var compName = component.get("v.compName");
        var UiMessage = $A.get('$Label.c.IMCC_Custom_UI_Error_Message');
        if(param.formDataId == null || param.formDataId == ''){
            component.set("v.hideSaveAndClearButtons",false);
            this.setFormStatusHelper4(component, null,this,pageObj);
        }
        else{
            if(component.get("v.formResponseEntryId") != ""){
                var action2 = component.get("c.getFormResponseEntry");
                var self = this;
                action2.setParams({ "entryId": component.get("v.formResponseEntryId")});
                action2.setCallback(this, function (res2) {
                    let obj2 = res2.getReturnValue();
                    var state2 = res2.getState();
                    if (state2 !== "SUCCESS") {
                        component.set("v.spinner", false);
                        methodName = 'getFormResponseEntry';
                        var cmpError = component.find('imcc_lwcUtility');
                        cmpError.handleAuraErrors(compName,methodName,res2.getError());
                        self.showNewToast(component, "Error: ", 'error',UiMessage);
                    }
                    else {
                        if(obj2.Status__c != "Viewed"){
                            self.setFormStatusHelper3(component, null, true,obj2,self,pageObj);
                            component.set("v.spinner", false);
                        }
                        else{
                            self.setFormStatusHelper2(component,obj2,true,param,self,pageObj);
                        }
                    }
                });
                $A.enqueueAction(action2);
            }
            else{
                this.setFormStatusHelper2(component,null,false,param,this,pageObj);
            }
        }
    },
    setFormStatusHelper2: function (component, obj2, isShowClearAllButton,param,self,pageObj) {
        var methodName;
        var compName = component.get("v.compName");
        var UiMessage = $A.get('$Label.c.IMCC_Custom_UI_Error_Message');
        var action = component.get("c.setFormStatus");
        var qid = component.get("v.recordId");
        param.entryId = component.get("v.formResponseEntryId");
        action.setParams({ "qid": qid, "param": JSON.stringify(param)});
        action.setCallback(this, function (res) {
            let obj = res.getReturnValue();
            var state = res.getState();
            component.set("v.spinner", false);
            if (state !== "SUCCESS") {
                methodName = 'setFormStatus';
                var cmpError = component.find('imcc_lwcUtility');
                cmpError.handleAuraErrors(compName,methodName,res.getError());
                self.showNewToast(component, "Error: ", 'error',UiMessage);
            }
            else {
                self.setFormStatusHelper3(component, obj2, isShowClearAllButton,obj,self,pageObj);
            }
        });
        $A.enqueueAction(action);
    },
    setFormStatusHelper3: function (component, obj2, isShowClearAllButton,obj,self,pageObj) {
        var profileName = component.get("v.userProfile");
        component.set("v.formResponseEntry",obj);
        component.set("v.formResponseEntryId",obj.Id);
        if(obj2 != null){
            component.set("v.formResponseEntryVerson",(obj2.Version__c+""));
            component.set("v.sendResponseToCustomer",obj2.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_Response_to_Customer__c);
        }
        else{
            component.set("v.formResponseEntryVerson",(obj.Version__c+""));
            component.set("v.sendResponseToCustomer",obj.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_Response_to_Customer__c);
        }
        component.set("v.hideSaveAndClearButtons",true);
        if(isShowClearAllButton){
            component.set("v.ShowClearAllButton",true);
        }
        var hideSaveAndClearButtons = true;
        if(obj.Approval_Status__c == null){
            obj.Approval_Status__c = "";
        }
        let deadline = obj.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c;
        let date2;
        let today = new Date().setHours(0, 0, 0, 0);
        if(profileName != 'IM Customer Community Login User'){
            hideSaveAndClearButtons = false;
        }
        else{
            if (obj.Form_Unlock__c == true) {
                hideSaveAndClearButtons = false;
            }
            else {
                if (deadline == null || deadline == '') {
                    if ((obj.Approval_Status__c == 'Approved' || obj.Approval_Status__c == 'In Review' || obj.Approval_Status__c == 'Resubmitted') &&obj.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c == true) {
                        hideSaveAndClearButtons = true;
                    }
                    else {
                        hideSaveAndClearButtons = false;
                        if(obj.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c == false && obj.Status__c =='Submitted'){
                            component.set("v.ShowClearAllButton",false);
                        }
                    }
                }
                else {
                    date2 = new Date(deadline).setHours(0, 0, 0, 0);
                    if (obj.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c != true) {
                        if (date2 >= today) {
                            if ((obj.Approval_Status__c == 'Approved' || obj.Approval_Status__c == 'In Review' || obj.Approval_Status__c == 'Resubmitted') && obj.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c == true) {
                                hideSaveAndClearButtons = true;
                            }
                            else {
                                hideSaveAndClearButtons = false;
                                if(obj.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c == false && obj.Status__c =='Submitted'){
                                    component.set("v.ShowClearAllButton",false);
                                }
                            }
                        }
                        else {
                            hideSaveAndClearButtons = true;
                        }
                    }
                    else {
                        if ((obj.Approval_Status__c == 'Approved' || obj.Approval_Status__c == 'In Review' || obj.Approval_Status__c == 'Resubmitted') && obj.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c == true) {
                            hideSaveAndClearButtons = true;
                        }
                        else {
                            hideSaveAndClearButtons = false;
                            if(obj.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c == false && obj.Status__c =='Submitted'){
                                component.set("v.ShowClearAllButton",false);
                            }
                        }

                    }
                }
            }
        }
        
        component.set("v.hideSaveAndClearButtons",hideSaveAndClearButtons);
        
        self.setFormStatusHelper4(component, null,self,pageObj);
    },
    setFormStatusHelper4: function (component, obj,self,pageObj) {
        var qid = component.get("v.recordId");
        let currentPageNo = (obj==null?(0):obj.Current_Page_No__c);
        if (currentPageNo >= pageObj.Form_Pages__r.length) {
            currentPageNo = pageObj.Form_Pages__r.length - 1;
        }
        let currentPage = pageObj.Form_Pages__r[currentPageNo];
        let totalPages = pageObj.Form_Pages__r.length - 1;
        if(obj != null){
            if((obj.Status__c.toLowerCase()=='submitted' || obj.Approval_Status__c.toLowerCase()=='rejected') && component.get("v.isNewEntry")){
                currentPageNo = 0;                    
                currentPage = pageObj.Form_Pages__r[currentPageNo];                    
            }
        }
        
        component.set("v.currentPageNo", currentPageNo);
        component.set("v.currentPage", currentPage);
        //button render logic
        //show previous btn
        if (currentPageNo > 0) {
            component.set("v.showPrevBtn", true);
        }
        
        //show next btn
        component.set("v.showNextBtn", false);
        if (currentPageNo < totalPages) {
            let nextPage = pageObj.Form_Pages__r[currentPageNo + 1];
            if (nextPage && nextPage.Section__c != undefined && nextPage.Section__c != '') {
                component.set("v.showNextBtn", true);
            }
        }
        
        if (currentPage) {
                                               
            self.getAllQuestion(component, qid, currentPage.Section__c);
        }
    },
    getAllQuestion: function (component, vQnaireId, vSectionId) {
        var self = this;
        var methodName;
        var compName = component.get("v.compName");
        var UiMessage = $A.get('$Label.c.IMCC_Custom_UI_Error_Message');
        var action = component.get("c.getQuestnsForAllQuesGroup");
        action.setParams({
            qnaireId: vQnaireId,
            sectionIds: vSectionId,
        });
        action.setCallback(this, function (res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                component.set("v.QnaireName", res.getReturnValue().questionnaire.Name);
                component.set("v.isShowMainTitle", res.getReturnValue().questionnaire.Show_Main_Title_to_User__c);
                component.set("v.objQnaire", res.getReturnValue().questionnaire);              
                self.getQuestionResponsesHelper(component, res.getReturnValue(), vSectionId);
            }
            else {
                //self.showNewToast(component, "Error: ", 'error', res.getError()[0].message);
                methodName = 'getQuestnsForAllQuesGroup';
                var cmpError = component.find('imcc_lwcUtility');
                cmpError.handleAuraErrors(compName,methodName,res.getError());
                self.showNewToast(component, "Error: ", 'error',UiMessage);
            }
        });
        $A.enqueueAction(action);
    },
    getQuestionResponsesHelper: function (component, lstQQuesnnaire, vSectionId) {
        component.set("v.spinner", true);
        var self = this;
        var methodName;
        var compName = component.get("v.compName");
        var UiMessage = $A.get('$Label.c.IMCC_Custom_UI_Error_Message');
        var action = component.get("c.getQuestionResponses");
        let params = { 
            "questionnaireId": component.get("v.recordId"), 
            "sectionId": vSectionId, 
            "conEdMapId": component.get("v.conEdMapId"),
            "entryId" : component.get("v.formResponseEntryId"),
            'isReopenEntry':component.get("v.reOpenEditMode")
        };
        action.setParams(params);
        action.setCallback(this, function (res) {
            component.set("v.spinner", false);
            component.set("v.firstTime", false);

            var state = res.getState();
            if (state === "SUCCESS") {
                try {
                    var obj = JSON.parse(res.getReturnValue().responses);
                    var lstQDynLogic = res.getReturnValue().lstQDynLogic;
                    component.set("v.lstQDynLogicMain", lstQDynLogic);

                    var res_and_ques = [];
                    lstQQuesnnaire.sectionList.forEach((sec,i) => {
                        if (sec.sectionColNumber == '0' || sec.sectionColNumber == '1') {
                            if (sec.col1Questions.lstQuestn != undefined) {

                                res_and_ques = self.testHelper(obj, sec.col1Questions);
                                sec.col1Questions = res_and_ques[0];
                                lstQQuesnnaire = self.setQuestionBranching(component, lstQQuesnnaire, vSectionId, 'col1', i, res_and_ques[1]);
                            }
                        }

                        if (sec.sectionColNumber == '2') {
                            if (sec.col1Questions.lstQuestn && sec.col1Questions.lstQuestn.length > 0) {
                                res_and_ques = self.testHelper(obj, sec.col1Questions);
                                sec.col1Questions = res_and_ques[0];
                                lstQQuesnnaire = self.setQuestionBranching(component, lstQQuesnnaire, vSectionId, 'col1', i, res_and_ques[1]);
                            }

                            if (sec.col2Questions.lstQuestn && sec.col2Questions.lstQuestn.length > 0) {
                                res_and_ques = self.testHelper(obj, sec.col2Questions);
                                sec.col2Questions = res_and_ques[0];
                                lstQQuesnnaire = self.setQuestionBranching(component, lstQQuesnnaire, vSectionId, 'col2', i, res_and_ques[1]);
                            }
                        }
                    });
                    self.updateLinksAndOtherData(component, lstQQuesnnaire);
                } catch (e) {
                    console.log(e);
                }
            } else {
                methodName = 'getQuestionResponses';
                var cmpError = component.find('imcc_lwcUtility');
                cmpError.handleAuraErrors(compName,methodName,res.getError());
                self.showNewToast(component, "Error: ", 'error',UiMessage);
            }
        });
        $A.enqueueAction(action);
    },
    updateLinksAndOtherData : function(component, lstQQuesnnaire2){
        let lstQQuesnnaire = JSON.parse(JSON.stringify(lstQQuesnnaire2));
        let cem = component.get("v.cemList");
        let tabs = component.get("v.eventTabList");
        let eventCode;
        let accountId;

        lstQQuesnnaire.sectionList.forEach((sec,sectionIndex)=>{
            if(sec.sectionColNumber=='0' || sec.sectionColNumber=='1'){
                sec.mainDivCssClass = 'slds-p-horizontal_x-small slds-size--12-of-12 slds-small-size--12-of-12 slds-medium-size--12-of-12 slds-large-size--12-of-12';
            }
            if(sec.sectionColNumber=='2'){
                sec.mainDivCssClass = 'slds-p-horizontal_x-small slds-size--6-of-12 slds-small-size--12-of-12 slds-medium-size--6-of-12 slds-large-size--6-of-12';
            }
            try{
                //col1Questions
                sec.col1Questions.lstQuestn.forEach((item,QuesIndex)=>{   
                    item.Question_Questionnaires__r.forEach(qqr => {
                        let data = qqr.Question__r.Label__c;  

                        //replace feathr link
                        if(cem.length>0){
                            eventCode = cem[0].Edition__r.Edition_Code__c;
                            accountId = cem[0].Account__c;
                            cem[0].Feathr_Unique_Link__c = cem[0].Feathr_Unique_Link__c?cem[0].Feathr_Unique_Link__c:'#';
                            data = data.replaceAll('href="feathr-link"','href="'+cem[0].Feathr_Unique_Link__c+'" target="_blank"');
                        }

                        //replace internal tab links
                        if(tabs.length>0){
                            tabs.forEach(tab=>{
                                let url = this.getPageUrlByType(tab.Tab_Type__c,tab.Standard_Tab_Type__c);                            
                                data = data.replaceAll('"tabId='+tab.ExtTabId__c+'"', '"'+url+'?edcode='+eventCode+'&tabId='+tab.Tab_Code__c+'&accId='+accountId+'" target="_blank" ');
                            });
                        }

                        //replace missing link with home page
                        data = data.replaceAll('"tabId=','"/IMCC/s/overview?edcode='+eventCode+'&accId='+accountId+'" target="_blank" ');
                        qqr.Question__r.Label__c = data;
                        item.Label__c = data;

                        qqr.isShowInColumn = false;
                        if(sec.sectionColNumber=='0' || sec.sectionColNumber=='1'){
                            qqr.isShowInColumn = (qqr.Related_To_Column__c=='col0' || qqr.Related_To_Column__c=='col1');
                        }
                        if(sec.sectionColNumber=='2'){
                            qqr.isShowInColumn = (qqr.Related_To_Column__c=='col1');
                        }

                        qqr.GeoBtnName = 'GeoBtn_'+QuesIndex+'_0_col1Questions_'+sectionIndex;
                        qqr.labelBranchingRadio = 'name_'+QuesIndex+'_col1Questions_'+sectionIndex;
                        qqr.labelBranchingChk = 'name_'+QuesIndex+'_col1Questions_'+sectionIndex;
                        qqr.labelBranchingPick = 'sel_'+QuesIndex+'_col1Questions_'+sectionIndex;
                    });
                });
                
                //col2Questions
                sec.col2Questions.lstQuestn.forEach((item,QuesIndex)=>{
                    item.Question_Questionnaires__r.forEach(qqr => {
                        let data = qqr.Question__r.Label__c;
                    
                        //replace feathr link
                        if(cem.length>0){
                            eventCode = cem[0].Edition__r.Edition_Code__c;
                            accountId = cem[0].Account__c;
                            cem[0].Feathr_Unique_Link__c = cem[0].Feathr_Unique_Link__c?cem[0].Feathr_Unique_Link__c:'#';
                            data = data.replaceAll('href="feathr-link"','href="'+cem[0].Feathr_Unique_Link__c+'" target="_blank"');
                        }

                        //replace internal tab links
                        if(tabs.length>0){
                            tabs.forEach(tab=>{
                                let url = this.getPageUrlByType(tab.Tab_Type__c,tab.Standard_Tab_Type__c);                
                                data = data.replaceAll('"tabId='+tab.ExtTabId__c+'"', '"'+url+'?edcode='+eventCode+'&tabId='+tab.Tab_Code__c+'&accId='+accountId+'" target="_blank" ');
                            });
                        }

                        //replace missing link with home page
                        data = data.replaceAll('"tabId=','"/IMCC/s/overview?edcode='+eventCode+'&accId='+accountId+'" target="_blank" ');
                        qqr.Question__r.Label__c = data;
                        item.Label__c = data;

                        qqr.isShowInColumn = false;
                        if(sec.sectionColNumber=='2'){
                            qqr.isShowInColumn = (qqr.Related_To_Column__c=='col2');
                        }

                        qqr.GeoBtnName = 'GeoBtn_'+QuesIndex+'_0_col2Questions_'+sectionIndex;
                        qqr.labelBranchingRadio = 'name_'+QuesIndex+'_col2Questions_'+sectionIndex;
                        qqr.labelBranchingChk = 'name_'+QuesIndex+'_col2Questions_'+sectionIndex;
                        qqr.labelBranchingPick = 'sel_'+QuesIndex+'_col2Questions_'+sectionIndex;
                    });
                });
                
                //update link of col1Questions's branch questions
                sec.col1Questions.lstQuestn.forEach((branch,QuesIndex)=>{    
                    branch.Question_Questionnaires__r[0].branchingQuestnQuetnnaire.forEach((item,branchingIndex)=>{
                        let data = item.Question__r.Label__c;
                        
                        //replace feathr link
                        if(cem.length>0){
                            eventCode = cem[0].Edition__r.Edition_Code__c;
                            accountId = cem[0].Account__c;
                            cem[0].Feathr_Unique_Link__c = cem[0].Feathr_Unique_Link__c?cem[0].Feathr_Unique_Link__c:'#';
                            data = data.replaceAll('href="feathr-link"','href="'+cem[0].Feathr_Unique_Link__c+'" target="_blank"');
                        }
                        //replace internal tab links
                        if(tabs.length>0){
                            tabs.forEach(tab=>{
                                let url = this.getPageUrlByType(tab.Tab_Type__c,tab.Standard_Tab_Type__c);                            
                                data = data.replaceAll('"tabId='+tab.ExtTabId__c+'"', '"'+url+'?edcode='+eventCode+'&tabId='+tab.Tab_Code__c+'&accId='+accountId+'" target="_blank" ');
                            });
                        }

                        //replace missing link with home page
                        data = data.replaceAll('"tabId=','"/IMCC/s/overview?edcode='+eventCode+'&accId='+accountId+'" target="_blank" ');
                        item.Question__r.Label__c = data;
                        item.GeoBtnName = 'GeoBtn_'+QuesIndex+'_'+branchingIndex+'_col1Questions_'+sectionIndex;
                        item.labelBranchingChk = 'name_'+QuesIndex+'_col1Questions_'+sectionIndex+'_'+branchingIndex;
                    });
                });
                
                //update link of col2Questions's branch questions
                sec.col2Questions.lstQuestn.forEach((branch,QuesIndex)=>{ 
                    branch.Question_Questionnaires__r[0].branchingQuestnQuetnnaire.forEach((item,branchingIndex)=>{
                        let data = item.Question__r.Label__c;
                        
                        //replace feathr link
                        if(cem.length>0){
                            eventCode = cem[0].Edition__r.Edition_Code__c;
                            accountId = cem[0].Account__c;
                            cem[0].Feathr_Unique_Link__c = cem[0].Feathr_Unique_Link__c?cem[0].Feathr_Unique_Link__c:'#';
                            data = data.replaceAll('href="feathr-link"','href="'+cem[0].Feathr_Unique_Link__c+'" target="_blank"');
                        }
                        //replace internal tab links
                        if(tabs.length>0){
                            tabs.forEach(tab=>{
                                let url = this.getPageUrlByType(tab.Tab_Type__c,tab.Standard_Tab_Type__c);                            
                                data = data.replaceAll('"tabId='+tab.ExtTabId__c+'"', '"'+url+'?edcode='+eventCode+'&tabId='+tab.Tab_Code__c+'&accId='+accountId+'" target="_blank" ');
                            });
                        }
                        //replace missing link with home page
                        data = data.replaceAll('"tabId=','"/IMCC/s/overview?edcode='+eventCode+'&accId='+accountId+'" target="_blank" ');
                        item.Question__r.Label__c = data;
                        item.GeoBtnName = 'GeoBtn_'+QuesIndex+'_'+branchingIndex+'_col2Questions_'+sectionIndex;
                        item.labelBranchingChk = 'name_'+QuesIndex+'_col2Questions_'+sectionIndex+'_'+branchingIndex;
                    });
                });

                sec.colList = [];
                sec.colList.push(sec.col1Questions);
                if(sec.sectionColNumber=='2'){
                    sec.colList.push(sec.col2Questions);
                }
            }
            catch(e){console.error(e);}
        });

        component.set("v.lstQQuesnnaire", lstQQuesnnaire);
    },
    getPageUrlByType: function(tabType,stndrdTabType){
        let urlStr = '';
        if (tabType == 'Custom') {
            if(stndrdTabType == 'HTML'){                
                urlStr ='/IMCC/s/custom-html';                
            }
            else{
                urlStr ='/IMCC/s/custompages';
            }
        }
        if (tabType == 'Standard') {
            if(stndrdTabType == 'Floorplan'){            
                urlStr ='/IMCC/s/floorplan';
            }
            if(stndrdTabType == 'FAQ'){
                urlStr ='/IMCC/s/faqs';
            }
            if(stndrdTabType == 'Forms'){
                urlStr ='/IMCC/s/forms';                               
            }
            if(stndrdTabType == 'Manuals'){
                urlStr ='/IMCC/s/manuals';
            }
            if(stndrdTabType == 'Badges'){
                urlStr ='/IMCC/s/badges';
            }
            if(stndrdTabType == 'Stand Contractors'){
                urlStr ='/IMCC/s/stand-contractors';
            }
            if(stndrdTabType == 'Stand Design'){
                urlStr ='/IMCC/s/stand-design';
            }
            if(stndrdTabType == 'Lead Retrieval'){                
                urlStr ='/IMCC/s/lead-retrieval';
            }
            if(stndrdTabType == 'Virtual Event'){
                urlStr ='/IMCC/s/virtual-event';
            }
            if(stndrdTabType == 'Badge Registration'){
                urlStr ='/IMCC/s/badge-registration';
            }
            if (stndrdTabType == 'Manage Team') {
                urlStr = '/IMCC/s/teams-manager';
            }
            if (stndrdTabType == 'Manage My Task') {
                urlStr = '/IMCC/s/manage-my-task';
            }
        }
        return urlStr;
    },
    setQuestionBranching: function (component, lstQQuesnnaire, vSectionId, col, i, lstUnderbranchingResponseOption) {
        //console.log('Helper Is Called');
        var lstQDynLogic = component.get("v.lstQDynLogicMain");
        var lst_Question_Questionnaires = [];
        var Obj_Question_Questionnaires = component.get("v.Obj_Question_Questionnaires");
        var isRemove = false;
        var lstQuestnOption = lstUnderbranchingResponseOption;

        if (lstQQuesnnaire !== undefined && lstQQuesnnaire !== null && lstQQuesnnaire.sectionList != undefined && lstQQuesnnaire.sectionList.length > 0) {
            var question = [];
            try {
                if (col == 'col1') {
                    question = lstQQuesnnaire.sectionList[i].col1Questions.lstQuestn;
                }
                else if (col == 'col2') {
                    question = lstQQuesnnaire.sectionList[i].col2Questions.lstQuestn;
                }
                
                question.forEach(item => {
                    item.Question_Questionnaires__r[0].branchingQuestnQuetnnaire = [];
                });

                if (lstQDynLogic !== undefined && lstQDynLogic !== null && lstQDynLogic.length > 0) {
                    lstQDynLogic.forEach(qdl => {
                        question.forEach((qes,indexQue) => {
                            var questionQuestnnnaire = qes.Question_Questionnaires__r;
                            questionQuestnnnaire.forEach(qqr => {
                                if(qdl.Show_Question_Questionnaire__c === qqr.Id) {
                                    isRemove = true;
                                    Obj_Question_Questionnaires = qqr;
                                    var qType = qdl.Question_Questionnaire__r.Question__r.Type__c;
                                    if (qes.Question_Options__r !== undefined) {
                                        Obj_Question_Questionnaires.QuestionOptions = qes.Question_Options__r;
                                    } else {
                                        Obj_Question_Questionnaires.QuestionOptions = [];
                                    }

                                    if(qType === 'Picklist' || qType === 'Switch' || qType === 'Checkbox' || qType === 'Radio'){
                                        qdl.Question_Questionnaire__r.Question__r.Name_Long = qdl.Question_Questionnaire__r.Question__r.Name_Long__c; // Changes Here for Long
                                        qdl.Question_Questionnaire__r.Question__r.Name_Long__c = qdl.Question_Questionnaire__r.Question__r.Name_Long__c; // Changes Here for Long
                                        Obj_Question_Questionnaires.isShowQuestion = false;
                                    } 
                                    else {
                                        Obj_Question_Questionnaires.isShowQuestion = true;
                                    }
                                    Obj_Question_Questionnaires.MainQuestionId = qdl.Question_Questionnaire__r.Question__c;
                                    question.splice(indexQue, 1);
                                }
                            });
                        });

                        lst_Question_Questionnaires.push(Obj_Question_Questionnaires);
                    });
                    //Default setting for switch and checkbox question.  
                    if (lstQuestnOption !== undefined && lstQuestnOption.length > 0) {
                        lstQDynLogic.forEach(qdl => {
                            if(lstQuestnOption.indexOf(qdl.Question_Option__c) !== -1) {
                                lst_Question_Questionnaires.forEach(item => {
                                    if (item.Id === qdl.Show_Question_Questionnaire__c) {
                                        item.isShowQuestion = true;
                                    }
                                });
                            }
                        });
                    }

                    var lstQuestionsId = [];
                    if(isRemove === true) {
                        question.forEach(qes => {
                            lst_Question_Questionnaires.forEach(item => {
                                if (item.MainQuestionId === qes.Id) {
                                    var branchingQuestionQuestnnnaire = qes.Question_Questionnaires__r[0].branchingQuestnQuetnnaire;
                                    if (lstQuestionsId.indexOf(item.Id) === -1) {
                                        branchingQuestionQuestnnnaire.push(item);
                                    }
                                    lstQuestionsId.push(item.Id);
                                    qes.Question_Questionnaires__r[0].branchingQuestnQuetnnaire = branchingQuestionQuestnnnaire;
                                }
                            });

                            //sort branch questions
                            qes.Question_Questionnaires__r[0].branchingQuestnQuetnnaire.sort(function(a, b) {
                                var keyA = a.Question_Order__c,
                                keyB = b.Question_Order__c;
                                // Compare the 2 dates
                                if (keyA < keyB) return -1;
                                if (keyA > keyB) return 1;
                                return 0;
                            }); 
                        });
                    }
                }

                if (col == 'col1') {
                    lstQQuesnnaire.sectionList[i].col1Questions.lstQuestn = this.sortListQuestionQuestionnaire(question);
                } else if (col == 'col2') {
                    lstQQuesnnaire.sectionList[i].col2Questions.lstQuestn = this.sortListQuestionQuestionnaire(question);
                }
            } 
            catch (e) {
                console.error(e);
            }
        }
        return lstQQuesnnaire;
    },
    testHelper: function (resObj, lstQuestion) {
        var return_arr = [];
        var data;
        var lstUnderbranchingResponseOption = [];
        var lstUnderbranchingResponseOption2 = [];

        if (lstQuestion !== undefined && lstQuestion !== null && lstQuestion.lstQuestn != undefined && lstQuestion.lstQuestn.length > 0) {
            //start response code//
            lstQuestion.lstQuestn.forEach(qes => {
                qes.Question_Questionnaires__r.forEach(qqr => {
                    qqr.responseValue1 = '';
                    qqr.responseValue2 = '';
                    qqr.comment = '';
                    qqr.attachment = '';

                    if (qes.Type__c == 'Number') {
                        if (qes.Decimal_value__c == 0) {
                            qqr.patterns = '^[0-9]*$';
                            qqr.messages = 'Please enter valid format in number and not accept decimal point';
                        }
                        if (qes.Decimal_value__c == 1) {
                            qqr.patterns = '^(?!0\\d|$)\\d*(\\.\\d{1,1})?$';
                            qqr.messages = 'Please enter valid format in number and accept only 1 decimal point';
                        }
                        if (qes.Decimal_value__c == 2) {
                            qqr.patterns = '^(?!0\\d|$)\\d*(\\.\\d{1,2})?$';
                            qqr.messages = 'Please enter valid format in number and accept only 2 decimal points';
                        }
                        if (qes.Decimal_value__c == 3) {
                            qqr.patterns = '^(?!0\\d|$)\\d*(\\.\\d{1,3})?$';
                            qqr.messages = 'Please enter valid format in number and accept only 3 decimal points';
                        }
                        if (qes.Decimal_value__c == 4) {
                            qqr.patterns = '^(?!0\\d|$)\\d*(\\.\\d{1,4})?$';
                            qqr.messages = 'Please enter valid format in number and accept only 4 decimal point';
                        }
                    }

                    if (qes.Type__c == 'Switch') {
                        qqr.responseValue1 = qes.Question_Options__r[1].Value__c;
                        lstUnderbranchingResponseOption2.push(qes.Question_Options__r[1].Id);
                    }

                    if (qes.Type__c == 'Slider') {
                        qqr.responseValue1 = qqr.Default_Value__c;
                    }

                    if (qes.Type__c == 'Checkbox') {
                        qqr.responseValue1 = 'false';
                        lstUnderbranchingResponseOption2.push(qes.Question_Options__r[1].Id);
                    }

                    if (qes.Question_Options__r != undefined) {
                        qes.Question_Options__r.forEach(qOpt => {
                            qOpt.label = qOpt.Name_Long__c;
                            qOpt.value = qOpt.Id;
                        });
                    }
                });
            });

            // Set responses to questions
            resObj.forEach(res => {
                data = res.Answer_Long__c;
                lstQuestion.lstQuestn.forEach(qes => {
                    if(qes.Id == res.Question__c) {
                        qes.Question_Questionnaires__r.forEach(qqr => {
                            if (qqr.Question__r.Type__c == 'GPS Location') {
                                if (res.Answer_Long__c != undefined) {
                                    qqr.responseValue1 = res.Answer_Long__c.split(' ')[0];
                                    qqr.responseValue2 = res.Answer_Long__c.split(' ')[1];
                                }
                                else {
                                    qqr.responseValue1 = '';
                                    qqr.responseValue2 = '';
                                }
                            }
                            else if (qqr.Question__r.Type__c == 'Switch') {
                                qqr.responseValue1 = data;
                                if (data === 'true') {
                                    lstUnderbranchingResponseOption.push(qes.Question_Options__r[0].Id);
                                } else {
                                    lstUnderbranchingResponseOption.push(qes.Question_Options__r[1].Id);
                                }
                            }
                            else if (qqr.Question__r.Type__c == 'Checkbox') {
                                qqr.responseValue1 = data;
                                if (data === 'true') {
                                    lstUnderbranchingResponseOption.push(qes.Question_Options__r[0].Id);
                                } else {
                                    lstUnderbranchingResponseOption.push(qes.Question_Options__r[1].Id);
                                }
                            }
                            else if (qqr.Question__r.Type__c == 'Picklist') {
                                qqr.responseValue1 = data;
                                var lstQuestionOptions = qes.Question_Options__r;
                                if(lstQuestionOptions !== undefined && lstQuestionOptions.length > 0) {
                                    lstQuestionOptions.forEach(qOpt => {
                                        if (data === qOpt.Id) {
                                            lstUnderbranchingResponseOption.push(qOpt.Id);
                                        }
                                    });
                                }
                            }
                            else if (qqr.Question__r.Type__c == 'Radio') {
                                if (qes.Is_MultiSelect__c) {
                                    qqr.responseValue1 = this.splitString(res.Answer_Long__c);
                                } else {
                                    qqr.responseValue1 = res.Answer_Long__c;
                                }
                                var lstQuestionOptions = qes.Question_Options__r;
                                if (lstQuestionOptions !== undefined && lstQuestionOptions.length > 0) {
                                    lstQuestionOptions.forEach(qOpt => {
                                        if (data === qOpt.Id) {
                                            lstUnderbranchingResponseOption.push(qOpt.Id);
                                        }
                                    });
                                }
                            }
                            else {
                                qqr.responseValue1 = res.Answer_Long__c;
                                qqr.responseValue2 = '';
                            }
    
                            if(res.Comment__c != undefined){
                                qqr.comment = res.Comment__c;
                            }
    
                            // set Attachment response
                            if(res.Attachments != undefined){
                                for (var i = 0; i < res.Attachments.totalSize; i++) {
                                    if (qqr.attachment == '') {
                                        qqr.attachment = res.Attachments.records[i].Name;
                                    } else {
                                        qqr.attachment = qqr.attachment + ', ' + res.Attachments.records[i].Name;
                                    }
                                }
                            }
                        });
                    }
                });
            });
        }

        if (lstUnderbranchingResponseOption.length == 0) {
            lstUnderbranchingResponseOption = lstUnderbranchingResponseOption2
        }

        return_arr[0] = lstQuestion;
        return_arr[1] = lstUnderbranchingResponseOption;
        return return_arr;
    },
    sortListQuestionQuestionnaire: function (arrayQQuesnnaire) {
        var done = false;
        while (!done) {
            done = true;
            for (var i = 1; i < arrayQQuesnnaire.length; i += 1) {
                if (arrayQQuesnnaire[i - 1].Question_Questionnaires__r[0].Question_Order__c > arrayQQuesnnaire[i].Question_Questionnaires__r[0].Question_Order__c) {
                    done = false;
                    var tmp = arrayQQuesnnaire[i - 1];
                    arrayQQuesnnaire[i - 1] = arrayQQuesnnaire[i];
                    arrayQQuesnnaire[i] = tmp;
                }
            }
        }
        return arrayQQuesnnaire;
    },
    setOptionBranching: function (component, selctedOptionId, index, col, sectionIndex) {
        try {
            var listsect = component.get("v.lstQQuesnnaire.sectionList");
            var mainQuestion = [];
            if (col == "col1Questions") {
                mainQuestion = listsect[sectionIndex].colList[0].lstQuestn;
            } else if (col == "col2Questions") {
                mainQuestion = listsect[sectionIndex].colList[1].lstQuestn;
            }

            var mainQuestionBranching = mainQuestion[index].Question_Questionnaires__r[0].branchingQuestnQuetnnaire;

            if(mainQuestionBranching !== undefined) {
                mainQuestionBranching.forEach(item => {
                    item.isShowQuestion = false;
                });
                mainQuestion[index].Question_Questionnaires__r[0].branchingQuestnQuetnnaire = mainQuestionBranching;

                if(selctedOptionId !== undefined && selctedOptionId !== null && selctedOptionId.length > 0) {
                    var lstQDynLogic = component.get("v.lstQDynLogicMain");
                    var questnniareId = mainQuestion[index].Question_Questionnaires__r[0].Id;

                    //remove question which is not set in Question option
                    var dynamicLogic = {};
                    lstQDynLogic.forEach(qdl => {
                        if(qdl.Question_Questionnaire__c === questnniareId && selctedOptionId === qdl.Question_Option__c){
                            dynamicLogic[qdl.Show_Question_Questionnaire__c] = true;
                        }
                    });
                    
                    mainQuestionBranching.forEach(item => {
                        if(dynamicLogic.hasOwnProperty(item.Id)){
                            //set default value as empty array for multi picklist    
                            if(item.Question__r.Is_MultiSelect__c){
                                item.responseValue1 = item.responseValue1?item.responseValue1:[];
                            }
                            item.isShowQuestion = true; 
                        }
                    });
                    mainQuestion[index].Question_Questionnaires__r[0].branchingQuestnQuetnnaire = mainQuestionBranching;
                }
                
                if (col == "col1Questions") {
                    listsect[sectionIndex].colList[0].lstQuestn = mainQuestion;
                } else if (col == "col2Questions") {
                    listsect[sectionIndex].colList[1].lstQuestn = mainQuestion;
                }
                let lstQQuesnnaire2 = component.get("v.lstQQuesnnaire");
                lstQQuesnnaire2.sectionList = listsect;
                component.set("v.lstQQuesnnaire", lstQQuesnnaire2);
            }
        } catch (e) {
            console.error('Error: '+e);
        }
    },
    showNewToast: function (component, title, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent != undefined && toastEvent != null) {
            toastEvent.setParams({
                title: title,
                message: message,
                duration: ' 5000',
                type: type,
                mode: 'dismissible'
            });
            toastEvent.fire();
        } else {
            $A.createComponent(
                "c:FBToast", {
                "msgbody": message,
                "msgtype": type
            },
            function (newToast, status, errorMessage) {
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newToast);
                    component.set("v.body", body);
                } else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                } else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            });
        }
    },
    nextSectionHelper: function(component) {
        let currentPageNo = component.get("v.currentPageNo");
        let currentPage = component.get("v.currentPage");
        let pageObj = component.get("v.pages");

        var totalPages = pageObj.Form_Pages__r.length-1;
        if(currentPageNo < totalPages){
            currentPageNo = currentPageNo + 1;
        }
        component.set("v.showNextBtn",false);
        
        if(currentPageNo < totalPages){
            let nextpage = pageObj.Form_Pages__r[currentPageNo+1];
            if(nextpage.Section__c!=undefined && nextpage.Section__c!=''){
                component.set("v.showNextBtn",true);
            }     
        }
        
        currentPage = pageObj.Form_Pages__r[currentPageNo];
        component.set("v.currentPageNo",currentPageNo);
        component.set("v.currentPage",currentPage);
        var vQnaireId = component.get("v.QnaireId");
        this.getAllQuestion(component, vQnaireId, currentPage.Section__c); 
    },
    previousSectionHelper: function(component) {
        component.set("v.showNextBtn", true);
        var vQnaireId = component.get("v.QnaireId");
        
        let currentPageNo = component.get("v.currentPageNo"); 
        let pageObj = component.get("v.pages");
        currentPageNo = currentPageNo - 1;
        if(currentPageNo < 0){
            currentPageNo = 0;
        }
        
        let currentPage = pageObj.Form_Pages__r[currentPageNo];
        component.set("v.currentPageNo",currentPageNo);
        component.set("v.currentPage",currentPage);
        //hide previous btn if current page no less than 1
        if(currentPageNo < 1){
            component.set("v.showPrevBtn",false);
        }
        this.getAllQuestion(component, vQnaireId, currentPage.Section__c);
    },
    saveQuestionResponseHelper: function (component, param, isDraft) {
        var methodName;
        var compName = component.get("v.compName");
        var UiMessage = $A.get('$Label.c.IMCC_Custom_UI_Error_Message');
        param.boothId = component.get("v.boothId");
        param.boothId = param.boothId?param.boothId:null;
        param.formDataId = this.getParameterByName('formDataId');
        
        var self = this;
        component.set("v.spinner", true);
        let isLastPage = component.get("v.isLastPage");
        
        var action = component.get("c.saveQuestionResponse");
        param.entryId = component.get("v.formResponseEntryId");
        param.version = component.get("v.formResponseEntry").Version__c;
        if(!isDraft){
            param.recieveEmailCopy = component.get("v.recieveCopyToCustomer");
            param.additionalEmails = component.get("v.fREAdditionalEmailAddress");
        }
        
        action.setParams({ 
            "jsonResponse": self.getResponseAsJSONString(component), 
            "questionaryId": component.get("v.recordId"), 
            "param": JSON.stringify(param) 
        });
        action.setCallback(this, function (res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                component.set("v.isNewEntry",false);
                if(isLastPage && !isDraft) {
                    self.saveResponseAsPdf(component);
                }
                else {
                    self.showNewToast(component, 'SUCCESS : ', 'success', 'Your response have been saved as draft!');
                    component.set("v.spinner", false);
                }  
                component.set("v.isErrorinSave", false);
            } else {
                component.set("v.spinner", false);
                component.set("v.isErrorinSave", true); 
                methodName = 'saveQuestionResponse';
                var cmpError = component.find('imcc_lwcUtility');
                cmpError.handleAuraErrors(compName,methodName,res.getError());
                self.showNewToast(component, "Error: ", 'error',UiMessage);
            }
            if(!isDraft) {
                if(component.get("v.isErrorinSave") == false){
                    //code to get next section questions
                    this.nextSectionHelper(component);
                }   
                else{
                    this.previousSectionHelper(component);
                }
            }
        });
        $A.enqueueAction(action);
    },
    saveResponseAsPdf: function (component) {
        var methodName;
        var compName = component.get("v.compName");
        var UiMessage = $A.get('$Label.c.IMCC_Custom_UI_Error_Message');
        let accountId = this.getParameterByName('accId');
        let eventcode = this.getParameterByName('edcode');
        let tabId = this.getParameterByName('tabId');
        var action = component.get("c.saveQuestionResponseAsPDF");
        action.setParams({ "qid": component.get("v.recordId"),"ceid":component.get("v.conEdMapId"),"entryId":component.get("v.formResponseEntryId"),"fdId":this.getParameterByName('formDataId') });
        
        var self = this;
        action.setCallback(this, function (res) {
            component.set("v.spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                self.showNewToast(component, 'Success!', 'success', 'Form have been submitted');
                component.find("navigationService").navigate({
                    type:'comm__namedPage',
                    attributes: {  
                        name:'forms__c'
                    },
                    state: {
                        accId:accountId,
                        edcode:eventcode,
                        tabId:tabId
                    }
                });
            }
            else {
                //self.showNewToast(component, 'ERROR : ', 'error', JSON.stringify(res.getError()));
                component.set("v.spinner", false);
                methodName = 'saveQuestionResponseAsPDF';
                var cmpError = component.find('imcc_lwcUtility');
                cmpError.handleAuraErrors(compName,methodName,res.getError());
                self.showNewToast(component, "Error: ", 'error',UiMessage);
            }
        });
        $A.enqueueAction(action);
    },
    getResponseAsJSONString : function(component){
        var resp = [];
        var sectionList = component.get("v.lstQQuesnnaire.sectionList");
        
        sectionList.forEach(sec => {
            if(sec.colList.length > 0) {
                sec.colList.forEach(item => {
                    if(item.lstQuestn != undefined) {
                        resp = resp.concat(item.lstQuestn);
                    }
                });
            }
        });
        
        var respStr = JSON.stringify(resp);
        
        respStr = respStr.replace(/__c/g, "");
        respStr = respStr.replace(/__r/g, "r");
        resp = JSON.parse(respStr);
        try{
            resp.forEach(item => {
                item.Question_Questionnairesr.forEach(qqr => {
                    if (item.Type == 'Media' && qqr.attachment != undefined) {
                        qqr.responseValue1 = qqr.attachment;
                    }
                    if (item.Type == 'Radio' && item.Question_Optionsr != undefined && item.Is_MultiSelect){
                        qqr.responseValue1 = this.joinArray(qqr.responseValue1);
                    }
                    
                    if(qqr.branchingQuestnQuetnnaire.length>0){   
                        qqr.branchingQuestnQuetnnaire.forEach(bqqr => {
                            if(bqqr.Questionr.Is_MultiSelect){
                                bqqr.responseValue1 = this.joinArray(bqqr.responseValue1);
                            }
                        });
                    }
                });
            });
        }
        catch(e){
            console.error(e);
        }
        return JSON.stringify(resp);
    },
    validateForm: function (component) {
        var ele = component.find('inputFields');
        try {
            if (ele instanceof Array) {

                var allValid = component.find('inputFields').reduce(function (validSoFar, inputCmp) {

                    inputCmp.showHelpMessageIfInvalid();
                    if (inputCmp != null && inputCmp.get('v.validity') != undefined) {
                        return validSoFar && inputCmp.get('v.validity').valid;
                    } 
                    else {
                        return validSoFar;
                    }
                }, true);

                if(allValid) {
                    return true;
                } 
                else {
                    return false;
                }
            } 
            else if (ele != undefined && ele != null) {
                ele.showHelpMessageIfInvalid();
                return ele.get('v.validity').valid;
            } 
            else {
                return true;
            }
        } catch (e) {
            console.log(e);
        }
    },
    validateForm2: function (component) {
        var isValid = true;
        try {
            var ele = component.find('inputRadioFields');

            if (ele instanceof Array) {

                for (var i = 0; i < ele.length; i++) {
                    var obj = ele[i];
                    if (!obj.checkValidity()) {
                        $A.util.addClass(obj, "slds-has-error");
                        isValid = false;

                    } else {
                        $A.util.removeClass(obj, "slds-has-error");
                    }
                }
            } else if (ele != undefined) {
                if (!ele.checkValidity()) {
                    $A.util.addClass(ele, "slds-has-error");
                    isValid = false;
                } else {
                    $A.util.removeClass(ele, "slds-has-error");
                }
            }

            ele = component.find('inputRichtextFields');
            if (ele instanceof Array) {
                for (var i = 0; i < ele.length; i++) {
                    var obj = ele[i];
                    if (obj.get("v.class") == true && $A.util.isEmpty(obj.get("v.value"))) {
                        isValid = false;
                    }
                }
            } else if (ele != undefined) {
                if (ele.get("v.class") == true && ele.get("v.value") == '') {
                    isValid = false;
                }
            }
            var eve = $A.get("e.c:validateLookupFieldEvt");
            eve.fire();
            return isValid;
        } catch (e) {
            console.error(e);
        }
    },
    isRunningInCommunity: function (component) {
        return (new RegExp('.*?\/s\/', 'g')).exec(window.location.href) != null
    },
    formatPhoneNumber: function (phone) {
        var s2 = ("" + phone).replace(/\D/g, '');
        var m = s2.match(/^(\d{3})(\d{3})(\d{4})$/);
        return (!m) ? null : "(" + m[1] + ") " + m[2] + "-" + m[3];
    },
    splitString: function (value) {
        if (value == null) return null;
        if (Array.isArray(value) == true) return value;
        return value.split(';');
    },
    joinArray: function (value) {
        if (value == null) return null;
        if (Array.isArray(value) == false) return value;
        return value.join(';');
    },
    clearAllHelper: function (component, param,sectionIds) {        
        var self = this;
        var methodName;
        var compName = component.get("v.compName");
        var UiMessage = $A.get('$Label.c.IMCC_Custom_UI_Error_Message');
        component.set("v.spinner", true);
        var action = component.get("c.clearQuestionResponse");
        param.formDataId = this.getParameterByName('formDataId');
        param.entryId = component.get("v.formResponseEntryId");
        
        action.setParams({"questionaryId": component.get("v.recordId"), param: JSON.stringify(param),sectionId:sectionIds });        
        action.setCallback(this, function (res) {
            var state = res.getState();
            component.set("v.spinner", false);
            if (state === "SUCCESS") {
                self.showNewToast(component, 'SUCCESS : ', 'success', 'Your response have been cleared!');
                component.set("v.isClearFormConfirm",false);
                if(sectionIds===''){
                    let pageObj = component.get("v.pages");
                    let currentPage = pageObj.Form_Pages__r[0];
                    let currentPageNo = 0;
                    component.set("v.currentPageNo",currentPageNo);
                    component.set("v.currentPage",currentPage);
                    component.set("v.showPrevBtn",false);
                    let totalPages = parseInt(param.totalPages,10);
                    if(totalPages>1){
                        component.set("v.showNextBtn",true);
                    }
                    self.getAllQuestion(component, component.get("v.recordId"), currentPage.Section__c);
                }
                else{
                    self.getAllQuestion(component, component.get("v.recordId"), sectionIds);
                }                
            }
            else {
                component.set("v.spinner", false);
                methodName = 'clearQuestionResponse';
                var cmpError = component.find('imcc_lwcUtility');
                cmpError.handleAuraErrors(compName,methodName,res.getError());
                self.showNewToast(component, "Error: ", 'error',UiMessage);                 
            }
        });
        $A.enqueueAction(action);
    }
})