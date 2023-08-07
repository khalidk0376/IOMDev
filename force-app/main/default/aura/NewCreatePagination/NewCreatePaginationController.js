({
    scriptsLoaded: function(component, event, helper) {
        helper.callScriptsLoaded(component, event);
    },
    doInit: function(component, event, helper) {        
        helper.getQuestionnaireRecord(component, event);
    },
    goBack: function(component, event, helper) {
        $A.get("e.c:Go_Back_Event").fire();
    },
    hideModal: function(component, event, helper) {
        component.set("v.isShowModal", false);
        component.set("v.isEditQue", false);
        component.set("v.isShowSection", false);        
        component.set("v.isShowSectionEditForm", false);
        //component.set("v.isBranchedQuestion",false);
        
        //helper.removeQuesValue(component, event);
        component.set("v.isShowHelpText", false);        
        component.set("v.questionDeleteModal", false);
        component.set("v.isTemplatePublished", false);
        helper.closeEditor(component);
    },
    tabSelected: function(component, event, helper) {
        var old_section = component.get("v.selTabId");
        var vSectionId = event.currentTarget.id.split('_')[0];
        if(old_section==vSectionId){
            return;
        }
        var menuItems = component.find("menuItems");
        menuItems.find(function(menuItem){
            $A.util.removeClass(menuItem.getElement(),'slds-is-active');
        });
        
        var vQnaireId = component.get("v.QnaireId");        
        component.set("v.selTabId",vSectionId);
        var index = event.currentTarget.id.split('_')[1];

        event.currentTarget.setAttribute("class","slds-tabs_default__item slds-is-active")

        component.find('tab_content').getElement().setAttribute("id","tab-default-"+index);
        component.find('tab_content').getElement().setAttribute("aria-labelledby","tab-default-"+index+"__item");
        helper.getAllQuestion(component, event, vQnaireId, vSectionId);
        helper.callScriptsLoaded(component, event);
    },
    editSection: function(component, event, helper) {
        helper.openEditor(component);
        //get section id by v.selTabId attribute
        var sectionName = component.get("v.lstQQuesnnaire.col1Questions.groupName");
        var sectionColNumber = component.get("v.lstQQuesnnaire.col1Questions.sectionColNumber");
        component.set("v.isShowSectionEditForm", true);
        window.setTimeout($A.getCallback(function() {            
            component.find("sectionName").set("v.value",sectionName);
            component.set("v.selColumnNo",sectionColNumber);
        }), 1000);
    },
    updateSectionAction: function(component, event, helper) {
        var section = component.find('sectionName');
        var sectionName = section.get("v.value").trim();
        var vQnaireId = component.get("v.QnaireId");
        var columnNo=component.get("v.selColumnNo");
        var isValid = true;
        if($A.util.isEmpty(sectionName)){
            isValid = false;
            section.showHelpMessageIfInvalid();
        }
        if($A.util.isEmpty(columnNo)){
            isValid = false;
            component.find('newsectionid').showHelpMessageIfInvalid();
        }

        if(isValid){
            helper.updateSectionHelper(component, event, sectionName, vQnaireId, columnNo);    
        }
        else
        {
            helper.showToast(component,'Error!','error','Please fill all required fields!');
        }        
    },
    handleMoreTabSelect: function(component, event, helper) {
        var old_section = component.get("v.selTabId");
        var selectedMenuItemValue = event.getParam("value");
        var vSectionId = event.getParam("value").split('_')[0];
        if(old_section==vSectionId){
            return;
        }
        
        var vQnaireId = component.get("v.QnaireId");
        var moremenuItems = component.find("moremenuItems");
        var menuItems = component.find("menuItems");
        
        menuItems.find(function(menuItem) {
            $A.util.removeClass(menuItem.getElement(),'slds-is-active');
        });
        
        moremenuItems.find(function(menuItem) {
            menuItem.set("v.checked",false);
        });
        
        // Toggle the existing checked value, if it was true, it will be set to false, and vice-versa
        var menuItem = moremenuItems.find(function(menuItem) {            
            return menuItem.get("v.value") === selectedMenuItemValue;
        });
        menuItem.set("v.checked", !menuItem.get("v.checked"));

        component.set("v.selTabId",vSectionId);
        var index = event.getParam("value").split('_')[1];
        component.find('tab_content').getElement().setAttribute("id","tab-default-"+index);
        component.find('tab_content').getElement().setAttribute("aria-labelledby","tab-default-"+index+"__item");
        helper.getAllQuestion(component, event, vQnaireId, vSectionId);
        helper.callScriptsLoaded(component, event);
    },
    saveQues: function(component, event, helper) {
        
        var vQnaireId = component.get("v.QnaireId");
        var vSectionId = component.get("v.selTabId");
        var dropColNumber = component.get("v.dropColNumber");
        var vDragId = component.get("v.dragId");
        var richTextId = component.find("qustNameRich");
        var qustnlabel = richTextId.get("v.value");
        var categoryId = component.find("categoryId");
        var categoryValue = categoryId.get("v.value");
        if (!categoryValue) {
            helper.showToast(component,'Error!','error','Select category');
            return false;
        } else if (!qustnlabel) {
            helper.showToast(component,'Error!','error','Write your question');
            return false;
        } else if (component.get("v.isShowHelpText") === true) {
            var helpText = component.find("helpTextInp");
            var helpTextValue = helpText.get("v.value");
            if (!helpTextValue) {
                helper.showToast(component,'Error!','error','Enter help text');
                return false;
            }
        }        
        if (qustnlabel.length <= 255) {
            helper.createQuestion(component, event, vQnaireId, vSectionId, vDragId, dropColNumber);
            component.set("v.isShowHelpText", false);
            
        } else {
            helper.showToast(component,'Error!','error',"character's Length should not exceed 255");
        }
    },
    delQues: function(component, event, helper) {
        if(!isNaN(event.getSource().get("v.name"))){
            var index = parseInt(event.getSource().get("v.name").split('~')[0], 10);
            var colnum = event.getSource().get("v.name").split('~')[1];
            var listquestions = component.get("v.lstQQuesnnaire."+colnum+".lstQuestn");
            var questionData = listquestions[index];
            var isAllowBranch=questionData.Question_Questionnaires__r[0].Is_Allow_Branching__c;
            if(isAllowBranch){
                //component.set("v.isBranchedQuestion",true);
                helper.showToast(component,'Info','info','You can not delete this question because it is already branched with other questions. Please remove branching then delete question.');
            }
            else{
                component.set("v.questionDeleteModal", true);
                var target = event.getSource();
                var vQId = target.get("v.value");
                component.set("v.deleteQuestionId", vQId); 
            }
        }
        else{
            component.set("v.questionDeleteModal", true);
            var targetevent = event.getSource();
            var vMainQId = targetevent.get("v.value");
            component.set("v.deleteQuestionId", vMainQId); 
        }
    },
    delQuestionRecord: function(component, event, helper) {
        
        helper.deleteQuestion(component, event, component.get("v.deleteQuestionId"));
        component.set("v.questionDeleteModal", false);
    },
    getOnlyOneQuestionRecrod: function(component, event, helper) {
        var target = event.getSource();
        var vQId = target.get("v.value");
        helper.editQuestion(component, event, vQId);
    }
    ,
    getBranchingOnlyOneQuestionRecrod: function(component, event, helper) {
        var target = event.getSource();
        var vQId = target.get("v.value");
        component.set("v.is_BranchingUnder",true);
        helper.editQuestion(component, event, vQId);
    },
    saveEditQuesrecord: function(component, event, helper) {
        var richTextId = component.find("qustNameRich");
        var qustnlabel = richTextId.get("v.value");
        
        if (qustnlabel.length <= 255) {
            helper.helperSaveEditQues(component, event);
        } else {
            helper.showToast(component,"Error: ","error","character's Length should not exceed 255.");
        }
    },
    showSectionModel: function(component, event, helper) {
        helper.openEditor(component);
        component.set("v.isShowSection", true);
    },
    handleMenuClick: function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        var header_menu = component.find("header_menu");
        header_menu.find(function (menuItem) {            
            if (menuItem.get("v.checked")) {
                menuItem.set("v.checked", false);
            }            
            if (menuItem.get("v.value") === selectedMenuItemValue) {
                menuItem.set("v.checked", true);
            }
        });
        if(selectedMenuItemValue=='SectionReorder'){
            helper.openEditor(component);
            component.set("v.isReorderSectionsModal", true);    
        }
        else if(selectedMenuItemValue=='Preview'){            
            var id  = component.get("v.objQnaire.Id");
            if(helper.isLightningExperienceOrSalesforce1()){
                sforce.one.navigateToURL('/apex/GirikonForm?id='+id);
            }
            else{
                window.open('/apex/GirikonForm?id='+id);
            }
        }
        else if(selectedMenuItemValue=='Publish'){
            helper.openEditor(component);
            component.set("v.isTemplatePublished",true);
        }
    },    
    saveSection: function(component, event, helper) {
        var section = component.find('sectionName');
        var sectionName = section.get("v.value").trim();
        var vQnaireId = component.get("v.QnaireId");
        var columnNo=component.get("v.selColumnNo");
        var isValid = true;
        if($A.util.isEmpty(sectionName)){
            isValid = false;
            section.showHelpMessageIfInvalid();
        }
        if($A.util.isEmpty(columnNo)){
            isValid = false;
            component.find('newsectionid').showHelpMessageIfInvalid();
        }

        if(isValid){
            helper.saveSectionHelper(component, event, sectionName, vQnaireId, columnNo);    
        }
        else
        {
            helper.showToast(component,'Error!','error','Please fill all required fields!');
        }        
    },
    showHelpText: function(component, event, helper) {
        var helpText = component.get("v.isShowHelpText");
        if (helpText === false) {
            component.set("v.isShowHelpText", true);            
        } else {
            component.set("v.isShowHelpText", false);
        }
    },    
    minMaxCol1: function(component, event, helper) {
        var iconName = event.getSource().get("v.iconName");
        if(iconName=='utility:back')
        {
            $A.util.addClass(component.find('box1'),'slds-size_1-of-12');
            $A.util.removeClass(component.find('box1'),'slds-size_2-of-12');

            $A.util.addClass(component.find('box2'),'slds-size_11-of-12');
            $A.util.removeClass(component.find('box2'),'slds-size_10-of-12');
            event.getSource().set("v.iconName","utility:forward");
            var fieldTypeLabel = component.find("gkn-field-label");
            fieldTypeLabel.find(function(item){
                $A.util.addClass(item,'gkn-truncate');
                $A.util.removeClass(item,'gkn-field-label');
            })
        }
        else
        {
            $A.util.addClass(component.find('box1'),'slds-size_2-of-12');
            $A.util.removeClass(component.find('box1'),'slds-size_1-of-12');

            $A.util.addClass(component.find('box2'),'slds-size_10-of-12');
            $A.util.removeClass(component.find('box2'),'slds-size_11-of-12');            
            event.getSource().set("v.iconName","utility:back");
            var fieldTypeLabel = component.find("gkn-field-label");
            fieldTypeLabel.find(function(item){
                $A.util.removeClass(item,'gkn-truncate');
                $A.util.addClass(item,'gkn-field-label');
            })
        }
    },
    editForm:function(component, event, helper) {
        helper.openEditor(component);
        component.set("v.isShowEditForm", true);
    },
    handleCloseModelEvent: function(component, event, helper) {
        var vQnaireId = component.get("v.QnaireId");
        var vSectionId = component.get("v.selTabId");
        var closeModel = event.getParam("closeModel");
        var isUpdateRecord = event.getParam("isUpdateRecord");
        var modelName = event.getParam("modelName");
        
        component.set("v.is_BranchingUnder",false);
        //close modal when click on modal close icon of date
        
        if(modelName=='formEdit'){
            component.set("v.isShowEditForm", false);
        }
        else if(modelName=='assignProfile'){            
            helper.showToast(component,'Success!','success','Form Assinged successfully!');
            return;
        }
        else if (closeModel === true && modelName === "Date") {
            component.set("v.isShowDateModal", false);
        } else if (closeModel === true && modelName === "URL") {
            component.set("v.isShowURLModal", false);
        } else if (closeModel === true && modelName === "DateTime") {
            component.set("v.isShowDatetimeModal", false);
        }
        
        //close modal after save the record of date input
        else if (isUpdateRecord === true && modelName === "Date") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowDateModal", false);
        }
        //close modal after save the record of URL input
        else if (isUpdateRecord === true && modelName === "URL") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowURLModal", false);
        } else if (isUpdateRecord === true && modelName === "DateTime") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowDatetimeModal", false);
        } else if (closeModel === true && (modelName === "TextPlain" || modelName === "Text (Plain)")) {
            component.set("v.isShowTextPlainModal", false);
        } else if (isUpdateRecord === true && (modelName === "TextPlain" || modelName === "Text (Plain)")) {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowTextPlainModal", false);
        } else if (closeModel === true && (modelName === "RichText" || modelName === "Text (Rich)")) {
            component.set("v.isShowRichTextModal", false);
        } else if (isUpdateRecord === true && (modelName === "RichText" || modelName === "Text (Rich)")) {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowRichTextModal", false);
        } else if (closeModel === true && modelName === "Address") {
            component.set("v.isShowAddressModal", false);
        } else if (isUpdateRecord === true && modelName === "Address") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowAddressModal", false);
        } else if (closeModel === true && modelName === "Email") {
            component.set("v.isShowEmailModal", false);
        } else if (isUpdateRecord === true && modelName === "Email") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowEmailModal", false);
        } else if (closeModel === true && modelName === "Phone") {
            component.set("v.isShowPhoneModal", false);
        } else if (isUpdateRecord === true && modelName === "Phone") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowPhoneModal", false);
        } else if (closeModel === true && (modelName === "Information" || modelName === "Information/Instruction")) {
            component.set("v.isShowInformationModal", false);
        } else if (isUpdateRecord === true && (modelName === "Information" || modelName === "Information/Instruction")) {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowInformationModal", false);
        } else if (closeModel === true && modelName === "Checkbox") {
            component.set("v.isShowCheckboxModal", false);
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
        }
        else if (isUpdateRecord === true && modelName === "Checkbox") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowCheckboxModal", false);
        }
        else if (closeModel === true && modelName === "Header/Footer") {
            component.set("v.isShowHeaderModal", false);
        } else if (isUpdateRecord === true && modelName === "Header/Footer") {
           helper.getAllQuestion(component, event, vQnaireId, vSectionId);
           component.set("v.isShowHeaderModal", false);
        }
        else if (closeModel === true && modelName === "Picklist") {
            component.set("v.isShowPicklistModal", false);
        } else if (isUpdateRecord === true && modelName === "Picklist") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowPicklistModal", false);
        } else if (closeModel === true && (modelName === "Number/Currency" || modelName === "Number")) {
            component.set("v.isShowNumberAndCurrencyModal", false);
        } else if (isUpdateRecord === true && (modelName === "Number/Currency" || modelName === "Number")) {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowNumberAndCurrencyModal", false);
        } else if (closeModel === true && modelName === "Lookup") {
            component.set("v.isShowLookupModal", false);
        } else if (isUpdateRecord === true && modelName === "Lookup") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowLookupModal", false);
        } else if (closeModel === true && modelName === "Signature") {
            component.set("v.showSign", false);
            component.set("v.isShowSignatureModal", false);
        } else if (isUpdateRecord === true && modelName === "Signature") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowSignatureModal", false);
        } else if (closeModel === true && modelName === "Switch") {
            component.set("v.isShowSwitchModal", false);
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
        } else if (isUpdateRecord === true && modelName === "Switch") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowSwitchModal", false);
        } else if (closeModel === true && modelName === "Slider") {
            component.set("v.isShowSliderModal", false);
        } else if (isUpdateRecord === true && modelName === "Slider") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowSliderModal", false);
        } else if (closeModel === true && modelName === "GPS Location") {
            component.set("v.isShowGPSLocationModal", false);
        } else if (isUpdateRecord === true && modelName === "GPS Location") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowGPSLocationModal", false);
        } else if (isUpdateRecord === true && modelName === "Branching") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.openBranchingModal", false);
        } else if (closeModel === true && modelName === "Branching") {
            component.set("v.openBranchingModal", false);
        } else if (closeModel === true && modelName === "AddQstnSection") {
            component.set("v.isAddQuestionInSectionModal", false);
        } else if (isUpdateRecord === true && modelName === "AddQstnSection") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isAddQuestionInSectionModal", false);
        } else if (closeModel === true && modelName === "Media") {
            component.set("v.isShowMediaModal", false);
        } else if (isUpdateRecord === true && modelName === "Media") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowMediaModal", false);
        } else if (closeModel === true && modelName === "ReorderSection") {
            component.set("v.isReorderSectionsModal", false);
        }
        else if (isUpdateRecord === true && modelName === "ReorderSection") {
            helper.getQuestionnaireRecord(component, event);
            component.set("v.isReorderSectionsModal", false);
        }
        else if (closeModel === true && modelName === "Radio") {
            component.set("v.isShowRadioModal", false);
        } else if (isUpdateRecord === true && modelName ==="Radio") {
            helper.getAllQuestion(component, event, vQnaireId, vSectionId);
            component.set("v.isShowRadioModal", false);
        }
        var detailtemp = [];
        component.set("v.selectedScoreIds", detailtemp);
        component.set("v.selectedScore", detailtemp);
        component.set("v.calculatedScore", 0.0);
        component.set("v.scoreTotalValues", 0.0);
        
        helper.closeEditor(component);
    },
    deleteSection: function(component, event, helper) {
        component.set("v.openDeleteModal", true);
        component.set("v.deleteModal", true);
        component.set("v.deleteModalContent", "Do you want to delete section along with questions?");        
    },
    nullify: function(comp, ev, hel) {
        var target = ev.getSource();
        target.set("v.value", "");
    },
    
    nullifyDate: function(comp, ev, hel) {
        var target = ev.getSource();
        target.set("v.value", "");
    },
    validateURL: function(component, event, helper) {
        var url = component.get("v.url");
    },
    // this function automatic call by aura:waiting event  
    showSpinner: function(component, event, helper) {        
        component.set("v.Spinner", true);
    },
    
    // this function automatic call by aura:doneWaiting event 
    hideSpinner: function(component, event, helper) {        
        component.set("v.Spinner", false);
    },
    handleDeleteModelEvent: function(component, event, helper) {
        var vQnaireId = component.get("v.QnaireId");
        var isCloseModal = event.getParam("closeDeleteModel");
        var isRecordDelete = event.getParam("deleteRecord");
        if (isCloseModal === true && isRecordDelete === false) {
            component.set("v.deleteModal", false);
        } else if (isCloseModal === true && isRecordDelete === true) {
            helper.getQuesGroupRecord(component, event, vQnaireId,"delete section");
            component.set("v.deleteModal", false);
        }
    },
    checkTextLenght: function(component, event, helper) {
        var target = event.getSource();
        var qustnlabel = target.get("v.value");
        if (qustnlabel !== undefined && qustnlabel !== "" && qustnlabel.trim().length !== 0) {
            qustnlabel = helper.onlyReturnString(component, event, qustnlabel);
            var allowTextLength = parseInt(component.get("v.richTextCharLimit"), 10);
            if (qustnlabel.trim().length > allowTextLength) {
                var message = "Character's Length should not exceed " + allowTextLength;
                helper.showToast(component,'Error:', 'error', message);
                return false;
            }
        }
    },
    getCharLimit: function(component, event, helper) {
        var ctarget = event.currentTarget;
        var id_str = ctarget.dataset.value;
        component.set("v.richTextCharLimit", parseInt(id_str, 10));
    },
    onRadio: function(cmp, evt) {
        var resultCmp;
        var selected = evt.getSource().get("v.label");
        resultCmp = cmp.find("radioResult");
        resultCmp.set("v.value", selected);
    },
    openBranchingPopup: function(component, event, helper) {
        try
        {
            var questionOrder = parseInt(event.getSource().get("v.name").replace("Qustn_Branching_", ""), 10);
            var index = parseInt(event.getSource().get("v.value").split('~')[0], 10);
            var colnum = event.getSource().get("v.value").split('~')[1];

            var listquestions = component.get("v.lstQQuesnnaire."+colnum+".lstQuestn");
            //console.log(listquestions);
            
            component.set("v.currentCoumn",colnum.replace('Questions','').trim());

            var questionData = listquestions[index].Question_Questionnaires__r[0].Id;
            var lstQDynLogicOption = listquestions[index].Question_Options__r;
            
            component.set("v.questionQuestnnaireBranchingId", listquestions[index].Question_Questionnaires__r[0].Id);
            component.set("v.questionPrintOrder", questionOrder);
            component.set("v.lstQDynLogicOption", lstQDynLogicOption);
            component.set("v.openBranchingModal", true);
        }
        catch(e)
        {
            console.log(e);
        }
    },
    /*    
    redirectPreview: function(component, event, helper) {
        var target = event.getSource();
        var communityURL = target.get("v.value");
        if(helper.isLightningExperienceOrSalesforce1()){
            sforce.one.navigateToURL(communityURL);
        }
        else{
            window.open(communityURL);
        }
    },*/    
    addQuestnInSection: function(component, event, helper) {
        var vl = event.getSource().get("v.value");        
        var index = parseInt(vl.split('~')[0], 10);
        var colnum = vl.split('~')[1];
        var listquestions = component.get("v.lstQQuesnnaire."+colnum+".lstQuestn");
        var data = listquestions[index];
        component.set("v.questionQuestnnaireInSection", data.Question_Questionnaires__r[0]);
        component.set("v.isAddQuestionInSectionModal", true);
    },    
    publishTemplate:function(component,event,helper){
        var vQnaireId = component.get("v.QnaireId");
        var action = component.get("c.setpublishStatusOnTemplate");
        action.setParams({
            templateId: vQnaireId
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                component.set("v.QnaireId","");
                /*
                var appEvent = $A.get("e.c:FBActiveHeaderEvent");
                if(appEvent){
                	appEvent.setParams({ "compName": "search"});
                	appEvent.fire();    
                }*/
            } 
            else {
                helper.showToast(component,"Error: ",'error',res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
})