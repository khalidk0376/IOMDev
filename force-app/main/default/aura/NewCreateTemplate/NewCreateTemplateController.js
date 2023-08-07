({
    scriptsLoaded: function(c, e, h) {
        
    },
    doInit: function(component, e, helper) {        
        helper.getQuestionnaireRecord(component);
    },
    goBack: function() {
        $A.get("e.c:Go_Back_Event").fire();
    },
    openPaginationModal: function(component) {
        component.set("v.isOpenPagination",true);
    },
    createPagination : function(component, e, helper) {
        var pageObj = component.get("v.pageObj");
        var isValid = true;
        //validate form
        if(pageObj.Name.trim()==''){
            component.find("pagename").showHelpMessageIfInvalid();
            isValid=false;
        }
        if(pageObj.Total_Pages__c==''){
            component.find("totalpage").showHelpMessageIfInvalid();
            isValid=false;
        }
        pageObj.Total_Pages__c = parseInt(pageObj.Total_Pages__c,10);
        if(pageObj.Total_Pages__c<1 || pageObj.Total_Pages__c>15){
            component.find("totalpage").showHelpMessageIfInvalid();
            isValid=false;
        }

        if(!isValid){
            helper.showToast(component, 'error', 'Please enter valid data');
            return false;
        }
        
        e.getSource().set("v.disabled",true);
        component.set("v.Spinner",true);
        var action = component.get("c.createPage");
        action.setParams({
            formPage: pageObj
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            component.set("v.Spinner",false);
            component.set("v.isOpenPagination",false);
            if (state === "SUCCESS") {                
                component.set("v.pageObj", res.getReturnValue());
                helper.showToast(component, 'success', 'Pagination saved, now you can move section in respective page.');
                component.set("v.isOpenPagination2",true);
                helper.getPagination(component);
            }
            else {
                helper.showToast(component, 'error', JSON.stringify(res.getError()));
            }
        });
        $A.enqueueAction(action);        
    },
    updatePagination:function(component,e,helper){        
        var pageObj = component.get("v.pageObj");
        var isValid = true;
        //validate form
        if(pageObj.Name.trim()==''){
            component.find("pagename").showHelpMessageIfInvalid();
            isValid=false;
        }
        if(pageObj.Total_Pages__c==''){
            component.find("totalpage").showHelpMessageIfInvalid();
            isValid=false;
        }
        pageObj.Total_Pages__c = parseInt(pageObj.Total_Pages__c,10);
        if(pageObj.Total_Pages__c<1 || pageObj.Total_Pages__c>15){
            component.find("totalpage").showHelpMessageIfInvalid();
            isValid=false;
        }
        if(!isValid){
            helper.showToast(component, 'error', 'Please enter valid data');
            return false;
        }
        component.set("v.Spinner",true);
        e.getSource().set("v.disabled",true);
        var action2 = component.get("c.updatePaginationAction");
        action2.setParams({formPage: pageObj});        
        action2.setCallback(this, function(res) {
            component.set("v.Spinner",false);
            component.set("v.isOpenPagination",false);
            var state = res.getState();            
            if (state === "SUCCESS") {
                component.set("v.pageObj", res.getReturnValue());
                helper.showToast(component, 'success', 'Pagination updated.');
                helper.getPagination(component);
            }
            else {                
                helper.showToast(component, 'error', JSON.stringify(res.getError()));
            }
        });
        $A.enqueueAction(action2);
    },
    handlePageChange:function(component) {
        let selectedPageIndex = component.get("v.selectedPageIndex");
        if(selectedPageIndex!=''){
            selectedPageIndex = parseInt(selectedPageIndex,10);
            let pageObj = component.get("v.pageObj");
            component.set("v.selectedPage",pageObj.Form_Pages__r[selectedPageIndex]);
        }
    },
    openAddSectionToPage:function(component){
        let pageObj = component.get("v.pageObj");        
        let sectId = component.get("v.selTabId");
        if(pageObj.Form_Pages__r!=undefined){            
            let selectedPageIndex = '';
            pageObj.Form_Pages__r.forEach((item,ind)=>{
                if(item.Section__c!=undefined && item.Section__c.indexOf(sectId)>=0){
                    selectedPageIndex = ind+'';
                }
            });
            component.set("v.selectedPageIndex",selectedPageIndex);            
            component.set("v.selectedPage",pageObj.Form_Pages__r[selectedPageIndex]);            
            component.set("v.isOpenPagination2",true);
        }
        else{
            //open create pagination modal
            component.set("v.isOpenPagination",true);
        }                        
    },
    updatePage : function(component, e, helper) {
        let selectedPageIndex = component.get("v.selectedPageIndex");
        if(selectedPageIndex==''){
            component.find("pagelist").showHelpMessageIfInvalid();
            helper.showToast(component,'error','Please select page');
            return false;
        }

        e.getSource().set("v.disabled",true);
        component.set("v.Spinner",true);
        var page = component.get("v.selectedPage");
        page.sobjectType = 'Form_Page__c';
        var sectId = component.get("v.selTabId");
        
        var action = component.get("c.updateSelectedPage");
        action.setParams({
            pageObj: page,
            sectId: sectId
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            component.set("v.Spinner",false);
            component.set("v.isOpenPagination2",false);
            if (state === "SUCCESS") {                
                helper.showToast(component, 'success', 'Pagination saved');
                helper.getPagination(component);
            } 
            else {
                helper.showToast(component, 'error', JSON.stringify(res.getError()));
            }
        });
        $A.enqueueAction(action);        
    },
    hideModal: function(component, e, helper) {
        component.set("v.isShowModal", false);
        component.set("v.isEditQue", false);
        component.set("v.isShowSection", false);        
        component.set("v.isShowSectionEditForm", false);
        
        component.set("v.isOpenPagination",false);
        component.set("v.isOpenPagination2",false);
        
        component.set("v.isShowHelpText", false);        
        component.set("v.questionDeleteModal", false);
        component.set("v.isTemplatePublished", false);
        if(component.get("v.pageAndSection")){
            component.set("v.pageObj.Total_Pages__c",component.get("v.pageAndSection").length);
        }
        helper.closeEditor(component);
    },
    tabSelected: function(component, e, helper) {
        var old_section = component.get("v.selTabId");
        var vSectionId = e.currentTarget.id.split('_')[0];
        if(old_section==vSectionId){
            return;
        }
        var menuItems = component.find("menuItems");
        menuItems.find(function(menuItem){
            $A.util.removeClass(menuItem.getElement(),'slds-is-active');
        });
        
        var vQnaireId = component.get("v.QnaireId");        
        component.set("v.selTabId",vSectionId);
        var index = e.currentTarget.id.split('_')[1];

        e.currentTarget.setAttribute("class","slds-tabs_default__item slds-is-active")

        component.find('tab_content').getElement().setAttribute("id","tab-default-"+index);
        component.find('tab_content').getElement().setAttribute("aria-labelledby","tab-default-"+index+"__item");
        helper.getAllQuestion(component, vQnaireId, vSectionId);
        helper.setSelectedPageIndex(component,vSectionId);        
    },
    editSection: function(component, e, helper) {
        helper.openEditor(component);
        //get section id by v.selTabId attribute
        var sectionName = component.get("v.lstQQuesnnaire.col1Questions.groupName");
        var sectionColNumber = component.get("v.lstQQuesnnaire.col1Questions.sectionColNumber");
        var isShow = component.get("v.lstQQuesnnaire.col1Questions.isShow");
        component.set("v.isShowSectionEditForm", true);
        window.setTimeout($A.getCallback(function() {            
            component.find("sectionName").set("v.value",sectionName);
            component.set("v.selColumnNo",sectionColNumber);
            component.set("v.isShowOnForm",isShow);
        }), 1000);
    },
    updateSectionAction: function(component, e, helper) {
        var section = component.find('sectionName');
        var sectionName = section.get("v.value").trim();
        var vQnaireId = component.get("v.QnaireId");
        var columnNo=component.get("v.selColumnNo");
        var isShowOnForm = component.get("v.isShowOnForm");

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
            helper.updateSectionHelper(component, sectionName, vQnaireId, columnNo,isShowOnForm);    
        }
        else
        {
            helper.showToast(component,'error','Please fill all required fields!');
        }        
    },
    handleMoreTabSelect: function(component, e, helper) {
        var old_section = component.get("v.selTabId");
        //var selectedMenuItemValue = e.getParam("value");
        var vSectionId = e.getParam("value").split('_')[0];
        if(old_section==vSectionId){
            return;
        }
        
        var vQnaireId = component.get("v.QnaireId");
        component.set("v.selTabId",vSectionId);
        helper.setSelectedPageIndex(component,vSectionId);
        var index = e.getParam("value").split('_')[1];
        component.find('tab_content').getElement().setAttribute("id","tab-default-"+index);
        component.find('tab_content').getElement().setAttribute("aria-labelledby","tab-default-"+index+"__item");
        helper.getAllQuestion(component, vQnaireId, vSectionId);
        //helper.callScriptsLoaded(component);
    },
    saveQues: function(component, e, helper) {
        
        var vQnaireId = component.get("v.QnaireId");
        var vSectionId = component.get("v.selTabId");
        var dropColNumber = component.get("v.dropColNumber");
        var vDragId = component.get("v.dragId");
        var richTextId = component.find("qustNameRich");
        var qustnlabel = richTextId.get("v.value");
        var categoryId = component.find("categoryId");
        var categoryValue = categoryId.get("v.value");
        if (!categoryValue) {
            helper.showToast(component,'error','Select category');
            return false;
        } else if (!qustnlabel) {
            helper.showToast(component,'error','Write your question');
            return false;
        } else if (component.get("v.isShowHelpText") === true) {
            var helpText = component.find("helpTextInp");
            var helpTextValue = helpText.get("v.value");
            if (!helpTextValue) {
                helper.showToast(component,'error','Enter help text');
                return false;
            }
        }        
        if (qustnlabel.length <= 255) {
            helper.createQuestion(component, vQnaireId, vSectionId, vDragId, dropColNumber);
            component.set("v.isShowHelpText", false);
            
        } else {
            helper.showToast(component,'error',"character's Length should not exceed 255");
        }
    },
    delQues: function(component, e, helper) {
        if(!isNaN(e.getSource().get("v.name"))){
            var index = parseInt(e.getSource().get("v.name").split('~')[0], 10);
            var colnum = e.getSource().get("v.name").split('~')[1];
            var listquestions = component.get("v.lstQQuesnnaire."+colnum+".lstQuestn");
            var questionData = listquestions[index];
            var isAllowBranch=questionData.Question_Questionnaires__r[0].Is_Allow_Branching__c;
            if(isAllowBranch){
                //component.set("v.isBranchedQuestion",true);
                helper.showToast(component,'info','You can not delete this question because it is already branched with other questions. Please remove branching then delete question.');
            }
            else{
                component.set("v.questionDeleteModal", true);                
                var vQId = e.getSource().get("v.value");
                component.set("v.deleteQuestionId", vQId); 
            }
        }
        else{
            component.set("v.questionDeleteModal", true);            
            var vMainQId = e.getSource().get("v.value");
            component.set("v.deleteQuestionId", vMainQId); 
        }
    },
    
    delQuestionRecord: function(component, e, helper) {        
        helper.deleteQuestion(component, component.get("v.deleteQuestionId"));
        component.set("v.questionDeleteModal", false);
    },
    
    getOnlyOneQuestionRecrod: function(component, e, helper) {        
        var vQId = e.getSource().get("v.value");
        helper.editQuestion(component, vQId);
    },

    getBranchingOnlyOneQuestionRecrod: function(component, e, helper) {
        var target = e.getSource();
        var vQId = target.get("v.value");
        component.set("v.is_BranchingUnder",true);
        helper.editQuestion(component, vQId);
    },
    saveEditQuesrecord: function(component, e, helper) {
        var richTextId = component.find("qustNameRich");
        var qustnlabel = richTextId.get("v.value");
        
        if (qustnlabel.length <= 255) {
            helper.helperSaveEditQues(component);
        } else {
            helper.showToast(component,"error","character's Length should not exceed 255.");
        }
    },
    showSectionModel: function(component, e, helper) {
        helper.openEditor(component);
        component.set("v.isShowSection", true);
    },
    handleMenuClick: function(component, e, helper) {
        var selectedMenuItemValue = e.getParam("value");
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
            var remaningSection = component.get("v.remaningSection");
            if(remaningSection.length>0){
                helper.showToast(component,'error','Please create pagination and assign all section to pages.')
                return false;
            }

            if(helper.isLightningExperienceOrSalesforce1()){
                //sforce.one.navigateToURL('/apex/GirikonForm?id='+id);
                window.open("/one/one.app#/alohaRedirect/apex/GirikonForm?id=" + id);
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
    saveSection: function(component, e, helper) {
        var section = component.find('sectionName');
        var sectionName = section.get("v.value").trim();
        var vQnaireId = component.get("v.QnaireId");
        var columnNo = component.get("v.selColumnNo");
        var isShowOnForm = component.get("v.isShowOnForm");
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
            helper.saveSectionHelper(component, sectionName, vQnaireId, columnNo,isShowOnForm);    
        }
        else
        {
            helper.showToast(component,'error','Please fill all required fields!');
        }        
    },
    showHelpText: function(component) {
        var helpText = component.get("v.isShowHelpText");
        if (helpText === false) {
            component.set("v.isShowHelpText", true);            
        } else {
            component.set("v.isShowHelpText", false);
        }
    },    
    minMaxCol1: function(component, e) {
        var iconName = e.getSource().get("v.iconName");
        if(iconName=='utility:back')
        {
            $A.util.addClass(component.find('box1'),'slds-size_1-of-12');
            $A.util.removeClass(component.find('box1'),'slds-size_2-of-12');

            $A.util.addClass(component.find('box2'),'slds-size_11-of-12');
            $A.util.removeClass(component.find('box2'),'slds-size_10-of-12');
            e.getSource().set("v.iconName","utility:forward");
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
            e.getSource().set("v.iconName","utility:back");
            var fieldTypeLabel = component.find("gkn-field-label");
            fieldTypeLabel.find(function(item){
                $A.util.removeClass(item,'gkn-truncate');
                $A.util.addClass(item,'gkn-field-label');
            })
        }
    },
    editForm:function(component, e, helper) {
        helper.openEditor(component);
        component.set("v.isShowEditForm", true);
    },
    handleCloseModel: function(component, e, helper) {
        var vQnaireId = component.get("v.QnaireId");
        var vSectionId = component.get("v.selTabId");
        var closeModel = e.getParam("closeModel");
        var isUpdateRecord = e.getParam("isUpdateRecord");
        var modelName = e.getParam("modelName");
        
        component.set("v.is_BranchingUnder",false);
        //close modal when click on modal close icon of date
        
        if(modelName=='formEdit'){
            component.set("v.isShowEditForm", false);
        }
        else if(modelName=='assignProfile'){            
            helper.showToast(component,'success','Form Assinged successfully!');
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
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowDateModal", false);
        }
        //close modal after save the record of URL input
        else if (isUpdateRecord === true && modelName === "URL") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowURLModal", false);
        } else if (isUpdateRecord === true && modelName === "DateTime") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowDatetimeModal", false);
        } else if (closeModel === true && (modelName === "TextPlain" || modelName === "Text (Plain)")) {
            component.set("v.isShowTextPlainModal", false);
        } else if (isUpdateRecord === true && (modelName === "TextPlain" || modelName === "Text (Plain)")) {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowTextPlainModal", false);
        } else if (closeModel === true && (modelName === "RichText" || modelName === "Text (Rich)")) {
            component.set("v.isShowRichTextModal", false);
        } else if (isUpdateRecord === true && (modelName === "RichText" || modelName === "Text (Rich)")) {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowRichTextModal", false);
        } else if (closeModel === true && modelName === "Address") {
            component.set("v.isShowAddressModal", false);
        } else if (isUpdateRecord === true && modelName === "Address") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowAddressModal", false);
        } else if (closeModel === true && modelName === "Email") {
            component.set("v.isShowEmailModal", false);
        } else if (isUpdateRecord === true && modelName === "Email") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowEmailModal", false);
        } else if (closeModel === true && modelName === "Phone") {
            component.set("v.isShowPhoneModal", false);
        } else if (isUpdateRecord === true && modelName === "Phone") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowPhoneModal", false);
        } else if (closeModel === true && (modelName === "Information" || modelName === "Information/Instruction")) {
            component.set("v.isShowInformationModal", false);
        } else if (isUpdateRecord === true && (modelName === "Information" || modelName === "Information/Instruction")) {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowInformationModal", false);
        } else if (closeModel === true && modelName === "Checkbox") {
            component.set("v.isShowCheckboxModal", false);
            helper.getAllQuestion(component, vQnaireId, vSectionId);
        }
        else if (isUpdateRecord === true && modelName === "Checkbox") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowCheckboxModal", false);
        }
        else if (closeModel === true && modelName === "Header/Footer") {
            component.set("v.isShowHeaderModal", false);
        } else if (isUpdateRecord === true && modelName === "Header/Footer") {
           helper.getAllQuestion(component, vQnaireId, vSectionId);
           component.set("v.isShowHeaderModal", false);
        }
        else if (closeModel === true && modelName === "Picklist") {
            component.set("v.isShowPicklistModal", false);
        } else if (isUpdateRecord === true && modelName === "Picklist") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowPicklistModal", false);
        } else if (closeModel === true && (modelName === "Number/Currency" || modelName === "Number")) {
            component.set("v.isShowNumberAndCurrencyModal", false);
        } else if (isUpdateRecord === true && (modelName === "Number/Currency" || modelName === "Number")) {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowNumberAndCurrencyModal", false);
        } else if (closeModel === true && modelName === "Lookup") {
            component.set("v.isShowLookupModal", false);
        } else if (isUpdateRecord === true && modelName === "Lookup") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowLookupModal", false);
        } else if (closeModel === true && modelName === "Signature") {
            component.set("v.showSign", false);
            component.set("v.isShowSignatureModal", false);
        } else if (isUpdateRecord === true && modelName === "Signature") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowSignatureModal", false);
        } else if (closeModel === true && modelName === "Switch") {
            component.set("v.isShowSwitchModal", false);
            helper.getAllQuestion(component, vQnaireId, vSectionId);
        } else if (isUpdateRecord === true && modelName === "Switch") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowSwitchModal", false);
        } else if (closeModel === true && modelName === "Slider") {
            component.set("v.isShowSliderModal", false);
        } else if (isUpdateRecord === true && modelName === "Slider") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowSliderModal", false);
        } else if (closeModel === true && modelName === "GPS Location") {
            component.set("v.isShowGPSLocationModal", false);
        } else if (isUpdateRecord === true && modelName === "GPS Location") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowGPSLocationModal", false);
        } else if (isUpdateRecord === true && modelName === "Branching") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.openBranchingModal", false);
        } else if (closeModel === true && modelName === "Branching") {
            component.set("v.openBranchingModal", false);
        } else if (closeModel === true && modelName === "AddQstnSection") {
            component.set("v.isAddQuestionInSectionModal", false);
        } else if (isUpdateRecord === true && modelName === "AddQstnSection") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isAddQuestionInSectionModal", false);
        } else if (closeModel === true && modelName === "Media") {
            component.set("v.isShowMediaModal", false);
        } else if (isUpdateRecord === true && modelName === "Media") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowMediaModal", false);
        } else if (closeModel === true && modelName === "ReorderSection") {
            component.set("v.isReorderSectionsModal", false);
        }
        else if (isUpdateRecord === true && modelName === "ReorderSection") {
            helper.getQuestionnaireRecord(component);
            component.set("v.isReorderSectionsModal", false);
        }
        else if (closeModel === true && modelName === "Radio") {
            component.set("v.isShowRadioModal", false);
        } else if (isUpdateRecord === true && modelName ==="Radio") {
            helper.getAllQuestion(component, vQnaireId, vSectionId);
            component.set("v.isShowRadioModal", false);
        }
        
        helper.closeEditor(component);
    },
    deleteSection: function(component) {
        component.set("v.openDeleteModal", true);
        component.set("v.deleteModal", true);
        component.set("v.deleteModalContent", "Do you want to delete section along with questions?");        
    },
    nullify: function(comp, ev) {
        var target = ev.getSource();
        target.set("v.value", "");
    },
    
    nullifyDate: function(comp, ev) {
        var target = ev.getSource();
        target.set("v.value", "");
    },
    validateURL: function(component) {
        var url = component.get("v.url");
    },
    
    showSpinner: function(component) {        
        component.set("v.Spinner", true);
    },
        
    hideSpinner: function(component) {        
        component.set("v.Spinner", false);
    },
    
    handleDeleteModel: function(component, e, helper) {
        var vQnaireId = component.get("v.QnaireId");
        var isCloseModal = e.getParam("closeDeleteModel");
        var isRecordDelete = e.getParam("deleteRecord");
        if (isCloseModal === true && isRecordDelete === false) {
            component.set("v.deleteModal", false);
        } else if (isCloseModal === true && isRecordDelete === true) {
            helper.getQuesGroupRecord(component, vQnaireId,"delete section");
            component.set("v.deleteModal", false);
        }
    },
    checkTextLenght: function(component, e, helper) {
        var target = e.getSource();
        var qustnlabel = target.get("v.value");
        if (qustnlabel !== undefined && qustnlabel !== "" && qustnlabel.trim().length !== 0) {
            qustnlabel = helper.onlyReturnString(qustnlabel);
            var allowTextLength = parseInt(component.get("v.richTextCharLimit"), 10);
            if (qustnlabel.trim().length > allowTextLength) {
                var message = "Character's Length should not exceed " + allowTextLength;
                helper.showToast(component,'error', message);
                return false;
            }
        }
    },
    getCharLimit: function(component, e) {
        var ctarget = e.currentTarget;
        var id_str = ctarget.dataset.value;
        component.set("v.richTextCharLimit", parseInt(id_str, 10));
    },
    onRadio: function(cmp, evt) {
        var resultCmp;
        var selected = evt.getSource().get("v.label");
        resultCmp = cmp.find("radioResult");
        resultCmp.set("v.value", selected);
    },
    openBranchingPopup: function(component,e) {
        try {
            var questionOrder = parseInt(e.getSource().get("v.name").replace("Qustn_Branching_", ""), 10);
            var index = parseInt(e.getSource().get("v.value").split('~')[0], 10);
            var colnum = e.getSource().get("v.value").split('~')[1];
            var listquestions = component.get("v.lstQQuesnnaire."+colnum+".lstQuestn");
            var lstQDynLogicOption = listquestions[index].Question_Options__r;

            component.set("v.currentCoumn",colnum.replace('Questions','').trim());
            component.set("v.questionQuestnnaireBranchingId", listquestions[index].Question_Questionnaires__r[0].Id);
            component.set("v.questionPrintOrder", questionOrder);
            component.set("v.lstQDynLogicOption", lstQDynLogicOption);
            component.set("v.openBranchingModal", true);
        }
        catch(e){
            console.error(e);
        }
    },
    
    addQuestnInSection: function(component, e) {
        var vl = e.getSource().get("v.value");        
        var index = parseInt(vl.split('~')[0], 10);
        var colnum = vl.split('~')[1];
        var listquestions = component.get("v.lstQQuesnnaire."+colnum+".lstQuestn");
        var data = listquestions[index];
        component.set("v.questionQuestnnaireInSection", data.Question_Questionnaires__r[0]);
        component.set("v.isAddQuestionInSectionModal", true);
    },    
    publishTemplate:function(component,e,helper){
        var vQnaireId = component.get("v.QnaireId");
        var action = component.get("c.setpublishStatusOnTemplate");
        action.setParams({
            templateId: vQnaireId
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                component.set("v.QnaireId","");                
            } 
            else {
                helper.showToast(component,'error',res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
})