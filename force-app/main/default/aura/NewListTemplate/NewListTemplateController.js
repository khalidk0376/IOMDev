({
    doInit: function(component, event, helper) {
        helper.getQuesCategory(component, event);
        helper.getQuesLanguage(component);
        helper.getTableData(component, false, false);
    },
    handleRowAction: function(component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'preview':
                //var communityURL = row.Community_URL__c;
                if (helper.isLightningExperienceOrSalesforce1()) {
                    //sforce.one.navigateToURL('/apex/GirikonForm?id=' + row.Id);
		            window.open("/one/one.app#/alohaRedirect/apex/GirikonForm?id=" + row.Id);
                } else {
                    window.open('/apex/GirikonForm?id=' + row.Id);
                }
                break;
            case 'clone':
                helper.hideAllForm(component);
                component.set("v.isCloneTemplate", true);
                component.set("v.sidebar_title", 'Clone Form Template');
                helper.getSingleQuestnnaireRecord(component, event, row.Id);
                helper.openSidebar(component);
                break;
            case 'edit':
                if (row.is_Published__c) {
                    helper.showToast(component, 'Error', 'error', 'You can not edit published form!');
                    return;
                }
                component.set("v.isQuestionMapEnabled", false);
                console.log(JSON.stringify(row));
                component.set("v.QnaireId", row.Id);
                break;
            case 'delete':
                break;
        }
    },
    mapFormWithObject: function(component, event, helper) {
        component.set("v.isQuestionMapEnabled", true);
    },    
    updateColumnSorting: function(component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');

        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        //component.set("v.currentPageNumber", 1);
        helper.getTableData(component, false, false, 0);
    },
    nextDatas: function(component, event, helper) {
        var next = true;
        var prev = false;
        var offset = component.get("v.offset");
        helper.getTableData(component, next, prev, offset);
    },
    previousDatas: function(component, event, helper) {
        var next = false;
        var prev = true;
        var offset = component.get("v.offset");
        helper.getTableData(component, next, prev, offset);
    },    
    checkTextLength: function(component, event, helper) {
        var target = event.getSource();
        var qustnlabel = target.get("v.value");
        qustnlabel = helper.onlyReturnString(component, event, qustnlabel);
        if (!qustnlabel) {
            if (qustnlabel.length > 10000) {
                var message = "Character's Length should not exceed 10000";
                helper.showToast(component, 'error', message);
                component.find('templatedesc').focus();
                return false;
            }
        }
    },
    saveQQuesnaireRecrod: function(component, event, helper) {
        var allValid = component.find('fieldId').reduce(function(validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && !inputCmp.get('v.validity').valueMissing;
        }, true);
        if (allValid) {
            var template = component.get("v.objQuesnaire");
            var templateName = template.Name.trim();
            templateName = helper.onlyReturnString(component, event, templateName);
            if (!templateName || templateName.trim().length === 0) {
                message = "Please Give a name to template";
                helper.showToast(component, 'error', message);
                component.find('templatename').focus();
                return false;
            } else {                
                component.set("v.objQuesnaire.isMerge__c", false);
                component.set("v.objQuesnaire.Show_Main_Title_to_User__c", component.find("showtitleuser").get("v.checked"));
                helper.createNewTemplate(component, event);
            }
        } else {
            helper.showToast(component, 'ERROR:', 'error', 'Please update the invalid form entries and try again.');
        }
    },
    cloneFormTemplate: function(component, event, helper) {
        var allValid = component.find('fieldId').reduce(function(validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && !inputCmp.get('v.validity').valueMissing;
        }, true);
        if (allValid) {
            component.set("v.objQuesnaire.isMerge__c", false);
            helper.cloneTemplateHelper(component, event);
        } else {
            helper.showToast(component, 'ERROR:', 'error', 'Please update the invalid form entries and try again.');
        }
    },
    createNewForm: function(component, event, helper) {
        component.set("v.objQuesnaire", { 'sobjectType': 'Questionnaire__c' });
        helper.hideAllForm(component);
        if (component.find('new_btn').get('v.variant') == 'brand') {
            component.find('new_btn').set("v.variant", "neutral");
            helper.closeSidebar(component);
        } else {
            component.find('new_btn').set("v.variant", "brand");
            component.set("v.isShowCreateModal", true);
            component.set("v.sidebar_title", "Create new form");
            helper.openSidebar(component);
        }
    },
    showFilter: function(component, event, helper) {
        helper.hideAllForm(component);
        if (component.find('filter_btn').get("v.variant") == "brand") {
            component.find('filter_btn').set("v.variant", "base");
            helper.closeSidebar(component);
        } else {
            component.set("v.isFilter", true);
            component.set("v.sidebar_title", "Filter");
            component.find('filter_btn').set("v.variant", "brand");
            helper.openSidebar(component);
        }
    },
    hideFilter: function(component, event, helper) {
        component.find('filter_btn').set("v.variant", "base");
        helper.hideAllForm(component);
        //slds-backdrop_close
        helper.closeSidebar(component);
    },
    filterDataTable: function(component, event, helper) {
        helper.getTableData(component, false, false);
    },
    sidebarHandler: function(component, event, helper) {
        var modelName = event.getParam("modelName");
        if (modelName === 'shareTemp') {
            helper.hideAllForm(component);
            helper.closeSidebar(component);
        }
    },
    goBackHandler: function(component, event, helper) {
        component.set("v.QnaireId", "");
    }
})