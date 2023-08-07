({
    formatPhone: function(component, event, helper) {
        var phone = event.getSource().get("v.value");
        if (!$A.util.isEmpty(phone) && phone.length == 10) {
            event.getSource().set("v.value", helper.formatPhoneNumber(phone));
        }
    },
    doInit: function(component, event, helper) {
        var methodName;
        var compName = component.get("v.compName");
        var UiMessage = $A.get('$Label.c.IMCC_Custom_UI_Error_Message');
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var action = component.get("c.getUserDetail");
        action.setParams({
            userId: userId
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                component.set("v.userProfile", res.getReturnValue().Profile.Name); 
            }
            else {
                
                methodName = 'getUserDetail';
                var cmpError = component.find('imcc_lwcUtility');
                cmpError.handleAuraErrors(compName,methodName,res.getError());
                helper.showNewToast(component, "Error: ", 'error',UiMessage);
                
            }
        });
        $A.enqueueAction(action);
        
        var formDataId = helper.getParameterByName('formDataId');
        if(formDataId == null || formDataId == ""){
            component.set("v.isPreview", true);
        }
        var vQnaireId = helper.getParameterByName('id');
        var conEdMapId = helper.getParameterByName('ceid');
        var booth = helper.getParameterByName('b');//booth
        var newEntry = helper.getParameterByName('ref');//ref if found then form load first page
        var responseEntryId = helper.getParameterByName('entryId');//entry Id, this param found only when user re-open form for edit form data 
        component.set("v.boothId",booth);
        component.set("v.conEdMapId", conEdMapId);
        
        newEntry = newEntry?true:false;
        component.set("v.isNewEntry", newEntry);
        
        if(responseEntryId != null && responseEntryId != ""){
            component.set("v.reOpenEditMode",true);
            component.set("v.formResponseEntryId",responseEntryId);
        }
        else{
            component.set("v.formResponseEntryId","");
        }
                
        var recordId = component.get("v.recordId");
        if ((vQnaireId == undefined || vQnaireId == null || vQnaireId == 'null' || vQnaireId == '') && (recordId == undefined || recordId == null || recordId == 'null' || recordId == '')) {
            component.set("v.spinner", false);
            //console.log('form not found');
            return;
        }
        
        if (vQnaireId != undefined && vQnaireId != null && vQnaireId != 'null' && vQnaireId != '') {
            component.set("v.recordId", vQnaireId);
            component.set("v.QnaireId", vQnaireId);
        } else {
            component.set("v.QnaireId", component.get("v.recordId"));
        }
        
        var action2 = component.get("c.getFormPreviewDetail");
        action2.setParams({
            qid: component.get("v.recordId"),
            cmid: component.get("v.conEdMapId")
        });
        action2.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                try{
                    let pageObj = res.getReturnValue().page;
                    component.set("v.cemList",res.getReturnValue().cem);
                    component.set("v.eventTabList",res.getReturnValue().tab);
                    //return if no page found
                    if(pageObj.Form_Pages__r==undefined){
                        helper.showNewToast(component,'Error','warning','No page found');
                        return;
                    }
                    else if(pageObj.Form_Pages__r.length===0){
                        helper.showNewToast(component,'Error','warning','No questions are found.');
                        return;
                    }
                    else{
                        let currentPageNo = 0;
                        let currentPage = pageObj.Form_Pages__r[currentPageNo];
                        component.set("v.currentPageNo",currentPageNo);
                        component.set("v.currentPage",currentPage);
                        component.set("v.pages",pageObj);
                        let param = {
                            status:'Viewed',
                            pageId:currentPage.Id, //current page id
                            currentPageNo:'0',
                            totalPages:pageObj.Total_Pages__c+'',
                            conEdMapId: conEdMapId,
                            formDataId: formDataId,
                            boothId: booth
                        };
                        helper.setFormStatusHelper(component,param,pageObj);
                    }
                }
                catch(e){
                    console.error(e);   
                }
            }
            else {
                //helper.showNewToast(component, "Error: ", 'error', res.getError()[0].message);
                methodName = 'getFormPreviewDetail';
                var cmpError = component.find('imcc_lwcUtility');
                cmpError.handleAuraErrors(compName,methodName,res.getError());
                helper.showNewToast(component, "Error: ", 'error',UiMessage);
            }
        });
        $A.enqueueAction(action2);
    },
    saveAsDraft:function(component, event, helper){
        let currentPageNo = component.get("v.currentPageNo");
        let currentPage = component.get("v.currentPage");
        let pageObj = component.get("v.pages");
        var conEdMapId = component.get("v.conEdMapId");
        
        let param = {
            status:'In Progress',
            pageId:currentPage.Id, //current page id
            currentPageNo:currentPageNo+'',
            totalPages:pageObj.Total_Pages__c+'',
            conEdMapId:conEdMapId,
            isSaveAsDraft:true
        };
            
        if(!component.get("v.isPreview")){
            component.set("v.spinner", true);
            helper.saveQuestionResponseHelper(component,param,true);
        }
    },
    nextSection: function(component, event, helper) {
        var isValid1 = helper.validateForm(component);
        var isValid2 = helper.validateForm2(component);
        var isValidLookupField = component.get("v.isLookupFiledValid");
        var conEdMapId = component.get("v.conEdMapId");
        
        if (isValid1 && isValid2 && isValidLookupField) {
            //enable previous btn
            component.set("v.showPrevBtn",true);
            component.set("v.fREAdditionalEmailAddress","");
            component.set("v.showText",false);
            let currentPageNo = component.get("v.currentPageNo");
            let currentPage = component.get("v.currentPage");
            let pageObj = component.get("v.pages");
            let param = {
                status:'In Progress',
                pageId:currentPage.Id, //current page id
                currentPageNo:currentPageNo+'',
                totalPages:pageObj.Form_Pages__r.length+'',
                conEdMapId:conEdMapId,
            };
            //Save filled form value
            if(!component.get("v.isPreview")){
                let formResponseEntry = component.get("v.formResponseEntry");
                let approvalRequired = formResponseEntry.Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c;
                if((approvalRequired && ((formResponseEntry.Approval_Status__c != "Approved" && formResponseEntry.Approval_Status__c != "In Review") || formResponseEntry.Form_Unlock__c)) || !approvalRequired){
                    helper.saveQuestionResponseHelper(component,param,false);
                }
                else{
                    helper.nextSectionHelper(component);
                }
            }
            else{
                helper.showNewToast(component, 'SUCCESS : ', 'success', 'Your response have been saved as draft!');
                helper.nextSectionHelper(component);
            }
        } 
        else {         
            helper.showNewToast(component, 'ERROR : ', 'error', 'Please update the invalid form entries and try again.');
        }
    },
    previousSection: function(component, event ,helper) {
        helper.previousSectionHelper(component);
    },
    saveResponseClick: function(component, event, helper) {
        component.set("v.spinner", true);
        var isValid1 = helper.validateForm(component);
        var isValid2 = helper.validateForm2(component);
        var isValidLookupField = component.get("v.isLookupFiledValid");
        var conEdMapId = component.get("v.conEdMapId");
        
        //page form status
        let currentPageNo = component.get("v.currentPageNo");
        let currentPage = component.get("v.currentPage");
        let pageObj = component.get("v.pages");
        let param = {
            status:'Submitted',
            pageId:currentPage.Id, //current page id
            currentPageNo:currentPageNo+'',
            totalPages:pageObj.Total_Pages__c+'',
            conEdMapId:conEdMapId,
        };
        
        if (isValid1 && isValid2 && isValidLookupField) {
            component.set("v.isLastPage", true);
            if(!component.get("v.isPreview")){
                helper.saveQuestionResponseHelper(component,param,false);
            }
            else{
                helper.showNewToast(component, 'Success!', 'success', 'Form have been submitted');
            }
        } else {
            helper.showNewToast(component, 'ERROR : ', 'error', 'Please update the invalid form entries and try again.');
            component.set("v.spinner", false);
        }
    },
    disableFields: function(component, event, helper){
        var val = component.find("checkboxOfSendResponse").get("v.checked");
        component.set("v.recieveCopyToCustomer",val);
        component.set('v.showText' , val);
    },
    openClearFormConfirmation:function(component, event, helper){
        component.set("v.isClearFormConfirm",true);
    },
    closeClearFormConfirmation:function(component, event, helper){
        component.set("v.isClearFormConfirm",false);
    },
    clearAll: function(component, event, helper){
        let currentPageNo = component.get("v.currentPageNo");
        let currentPage = component.get("v.currentPage");
        let pageObj = component.get("v.pages");
        var conEdMapId = component.get("v.conEdMapId");
        
        let param = {
            status:'In Progress',
            pageId:currentPage.Id, //current page id
            currentPageNo:currentPageNo+'',
            totalPages:pageObj.Total_Pages__c+'',
            conEdMapId:conEdMapId
        };
        let section = component.get("v.clearPageType")=='all'?'':currentPage.Section__c;
        
        if(!component.get("v.isPreview")){
            helper.clearAllHelper(component, param,section);
        }
        else{
            component.set("v.isClearFormConfirm",false);
            if(section===''){
                currentPage = pageObj.Form_Pages__r[0];
                currentPageNo = 0;
                component.set("v.currentPageNo",currentPageNo);
                component.set("v.currentPage",currentPage);
                component.set("v.showPrevBtn",false);
                let totalPages = parseInt(param.totalPages,10);
                if(totalPages>1){
                    component.set("v.showNextBtn",true);
                }
                helper.getAllQuestion(component, component.get("v.recordId"), currentPage.Section__c);
            }
            else{
                helper.getAllQuestion(component, component.get("v.recordId"), section);
            }    
        }
    },
    handleLookupValidationInfoEvent: function(component, event, helper) {
        component.set("v.isLookupFiledValid", true);
        var lookupValues = component.get("v.lookupValues");
        var isValid = event.getParam("isValid");
        var questionId = event.getParam("questionId");
        for (var i = 0; i < lookupValues.length; i++) {
            if (lookupValues[i].questionId == questionId) {
                lookupValues.splice(i, 1);
            }
        }
        lookupValues.push({ questionId: questionId, isValid: isValid });
        component.set("v.lookupValues", lookupValues);
        for (var i = 0; i < lookupValues.length; i++) {
            if (!lookupValues[i].isValid) {
                component.set("v.isLookupFiledValid", false);
            }
        }
    },
    handleLookupValueEvent: function(component, event, helper) {
        var qid = event.getParam("questionId"),
        fval = event.getParam("responseText");
        var sectionList = component.get("v.lstQQuesnnaire.sectionList");
        if (sectionList !== undefined && sectionList.length > 0) {
            //section looping
            for (var i = 0; i < sectionList.length; i++) {
                if (sectionList[i].colList.length > 0) {
                    for (var j = 0; j < sectionList[i].colList.length; j++) {
                        if(sectionList[i].colList[j].lstQuestn.length > 0) {
                            for (var k = 0; k < sectionList[i].colList[j].lstQuestn.length; k++) {
                                if (sectionList[i].colList[j].lstQuestn[k].Type__c === 'Lookup' && sectionList[i].colList[j].lstQuestn[k].Id == qid) {
                                    sectionList[i].colList[j].lstQuestn[k].Question_Questionnaires__r[0].responseValue1 = fval;
                                }
                            }
                        }
                    }
                }
            }
        }
        
    },
    getCurrentLocation: function(component, event, helper){
        try {
            var arr = event.getSource().get("v.name").split("_");
            var index = parseInt(arr[1], 10);
            var branchingIndex = parseInt(arr[2], 10);
            var sectionIndex = parseInt(arr[4], 10);
            var col = arr[3];
            var colIndex = 0;
            
            var listsect = component.get("v.lstQQuesnnaire.sectionList");
            if (col == "col2Questions") {
                colIndex = 1;
            }
            var listquestions = listsect[sectionIndex].colList[colIndex];
            
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(function(position) {
                    if (listquestions.lstQuestn[index].Question_Questionnaires__r[0].branchingQuestnQuetnnaire.length > 0) {
                        listquestions.lstQuestn[index].Question_Questionnaires__r[0].branchingQuestnQuetnnaire[branchingIndex].responseValue1 = position.coords.latitude;
                        listquestions.lstQuestn[index].Question_Questionnaires__r[0].branchingQuestnQuetnnaire[branchingIndex].responseValue2 = position.coords.longitude;
                    } 
                    else {
                        listquestions.lstQuestn[index].Question_Questionnaires__r[0].responseValue1 = position.coords.latitude;
                        listquestions.lstQuestn[index].Question_Questionnaires__r[0].responseValue2 = position.coords.longitude;
                    }
                    
                    listsect[sectionIndex].colList[colIndex] = listquestions;
                    component.set("v.lstQQuesnnaire.sectionList", listsect);
                });
            } else {
                helper.showNewToast(component, 'Error: ', 'error', 'Geo Location is not supported');
            }
        } catch (e) {
            console.error(e);
        }
    },
    radioBranching: function(component, event, helper){
        try {
            var mainQuestionOptionId = "";
            var arr = event.getSource().get("v.label").split("_");
            var index = parseInt(arr[1], 10);
            var col = arr[2];
            var sectionIndex = parseInt(arr[3], 10);
            var colIndex = 0;
            
            var listsect = component.get("v.lstQQuesnnaire.sectionList");
            
            if(col == "col2Questions") {
                colIndex = 1;
            } 
            var listquestions = listsect[sectionIndex].colList[colIndex];
            
            var isbranchAllow = listquestions.lstQuestn[index].Question_Questionnaires__r[0].Is_Allow_Branching__c;
            if (arr.length == 4) {               
                mainQuestionOptionId = event.getSource().get("v.value");
                if (isbranchAllow == true) {
                    helper.setOptionBranching(component, mainQuestionOptionId, index, col, sectionIndex);
                }
            }
        } 
        catch (e) {
            console.erro(e);
        }
    },
    checkboxOption: function(component, event, helper) {
        try {
            var mainQuestionOptionId = "";
            var arr = event.getSource().get("v.label").split("_");
            var index = parseInt(arr[1], 10);
            var col = arr[2];
            var sectionIndex = parseInt(arr[3], 10);
            var branchingIndex = -1;
            var colIndex = 0;
            
            if (arr.length > 4) {
                branchingIndex = parseInt(arr[4], 10);
            }
            var listsect = component.get("v.lstQQuesnnaire.sectionList");
            
            if(col == "col2Questions") {
                colIndex = 1;
            } 
            var listquestions = listsect[sectionIndex].colList[colIndex];
            var qstnOptionData;
            
            if (arr.length == 4) {
                qstnOptionData = listquestions.lstQuestn[index].Question_Options__r;
                if (event.getSource().get("v.checked")) {
                    mainQuestionOptionId = qstnOptionData[0].Id;
                    listquestions.lstQuestn[index].Question_Questionnaires__r[0].responseValue1 = 'true';
                }
                if (!event.getSource().get("v.checked")) {
                    mainQuestionOptionId = qstnOptionData[1].Id;
                    listquestions.lstQuestn[index].Question_Questionnaires__r[0].responseValue1 = 'false';
                }
                if (listquestions.lstQuestn[index].Question_Questionnaires__r[0].Is_Allow_Branching__c === true) {
                    helper.setOptionBranching(component, mainQuestionOptionId, index, col, sectionIndex);
                }
            } 
            else {
                if (event.getSource().get("v.checked")) {
                    listquestions.lstQuestn[index].Question_Questionnaires__r[0].branchingQuestnQuetnnaire[branchingIndex].responseValue1 = 'true';
                }
                if (!event.getSource().get("v.checked")) {
                    listquestions.lstQuestn[index].Question_Questionnaires__r[0].branchingQuestnQuetnnaire[branchingIndex].responseValue1 = 'false';
                }                
            }
        } 
        catch (e) {
            console.error(e);
        }
    },
    setPicklistScore: function(component, event, helper) {
        try {
            var selctedOptionId = event.getSource().get("v.value");
            var index = parseInt(event.getSource().get("v.label").split("_")[1], 10);
            var col = event.getSource().get("v.label").split("_")[2];
            var sectionIndex = event.getSource().get("v.label").split("_")[3];
            var colIndex = 0;
            
            var listsect = component.get("v.lstQQuesnnaire.sectionList");
            
            if (col == "col2Questions") {
                colIndex = 1;
            }
            var listquestions = listsect[sectionIndex].colList[colIndex];

            if (listquestions.lstQuestn[index].Question_Questionnaires__r[0].Is_Allow_Branching__c === true) {
                helper.setOptionBranching(component, selctedOptionId, index, col, sectionIndex);
            }
        } 
        catch (e) {
            console.error(e);
        }
    },
    checkURL: function(component, event, helper) {
        var string = event.getSource().get("v.value");
        if (string !== '') {
            if (!~string.indexOf("http")) {
                string = "https://" + string;
            }
            if (!~string.indexOf(".")) {
                string = string + ".com";
            }
            event.getSource().set("v.value", string)
            event.getSource().set('v.validity', { valid: true });
            event.getSource().reportValidity();
        }
    },
    handleCloseModelEvent: function(component, event, helper) {
        var vQnaireId = component.get("v.QnaireId");        
        var closeModel = event.getParam("closeModel");
        var isUpdateRecord = event.getParam("isUpdateRecord");
        var modelName = event.getParam("modelName");
        var isSuccessStatus = event.getParam("Successstatus");
        
        var signData = event.getParam("signData");
        if (signData != undefined && signData != "") {
            var image = new Image();
            image.id = "pic" + component.get("v.questionId");
            image.src = signData;
            image.width = 200;
            let node = document.getElementById("sig_" + component.get("v.questionId"));
            if(node){
                node.querySelectorAll('*').forEach(n => n.remove());
            }
            node.appendChild(image);
        }
        
        //close modal when click on modal close icon of date
        if (closeModel === true && modelName === "Signature") {
            component.set("v.showSign", false);
            component.set("v.isShowSignatureModal", false);
        }
        else if (isUpdateRecord === true && modelName === "Signature") {
            helper.getAllQuestion(component, vQnaireId, '');
            component.set("v.isShowSignatureModal", false);
        }
        else if(isSuccessStatus == 'ERROR' && modelName === "Signature"){
            component.set("v.isShowSignatureModal", false);
        }
    },
    // this function automatic call by aura:waiting event  
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for display loading spinner 
        component.set("v.spinner", true);
    },
    // this function automatic call by aura:doneWaiting event 
    hideSpinner: function(component, event, helper) {
        // make Spinner attribute to false for hide loading spinner    
        component.set("v.spinner", false);
    },
    getCharLimit: function(component, event, helper) {
        var ctarget = event.currentTarget;
        var id_str = ctarget.dataset.value;
        component.set("v.richTextCharLimit", parseInt(id_str, 10));
    },
    showSignModel: function(component, event, helper) {
        var questionId = event.getSource().get("v.value").split('_')[0];
        var QuestionQuestionnaires = event.getSource().get("v.value").split('_')[1];
        component.set("v.signHelpText",event.getSource().get("v.title"));
        component.set("v.QuestionQuestionnairesId", QuestionQuestionnaires);
        component.set("v.questionId", questionId);
        component.set('v.showSign', true);
    },
    goBack: function(component, event, helper) {
        let accountId = helper.getParameterByName('accId');
        let eventcode = helper.getParameterByName('edcode');
        let tabId = helper.getParameterByName('tabId');
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
})