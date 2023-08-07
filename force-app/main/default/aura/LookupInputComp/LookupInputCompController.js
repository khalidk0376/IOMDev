({
    doInit: function(component, event, helper) {
        var isEditQue = component.get("v.isEditQue");
        if (isEditQue === false) {
            helper.removeQuesValue(component, event);
        }
        helper.helperGetAllObjectList(component, event);
        
        window.setTimeout($A.getCallback(function() {
            if(component.find('qustNameRich')!=null){
                component.find('qustNameRich').focus();
            }
        }), 500);
    },
    hideModal: function(component, event, helper) {
        helper.crudModalEvent(component, event, true, false);
    },
    saveQues: function(component, event, helper) {
        var message;
        component.set("v.isShowbutton", true);
        var qes = component.get("v.objCrteQues");
        var vQnaireId = component.get("v.QnaireId");
        var vSectionId = component.get("v.QuestnGroupId");
        var dropColNumber = component.get("v.dropColNumber");
        var vDragId = component.get("v.fieldType");
        var qustnlabel = qes.Label__c.trim();
        var sobjectName = component.get("v.objCrteQues.lookup_Object_API_Name__c");
        var sobjectFieldName = component.get("v.objCrteQues.lookup_Object_Field_Name__c");
        qustnlabel = helper.onlyReturnString(component, event, qustnlabel);
        if (!qustnlabel || qustnlabel.trim().length ===0) {
            message = "write your question";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            component.find('qustNameRich').focus();
            return false;
        } else if (!sobjectName) {
            message = "Please select object";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            return false;
        } else if (!sobjectFieldName) {
            message = "Please select object field";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            return false;
        } else if (component.get("v.objCrteQues.Help_Text_Required__c") === true) {
            var helpText = component.find("helpTextInp");
            var helpTextValue = helpText.get("v.value");
            if (!helpTextValue) {
                message = "Enter help text.";
                helper.showToast(component, 'error', message);
                component.set("v.isShowbutton", false);
                return false;
            }
        }

        if (qustnlabel.trim().length <= 10000 && qustnlabel.trim().length !==0) {
            helper.SaveQuestion(component, event);
        } else {
            message = "Character's Length should not exceed 10000.";
            helper.showToast(component, 'error', message);
            component.find('qustNameRich').focus();
            component.set("v.isShowbutton", false);
        }
    },
    checkTextLength: function(component, event, helper) {
        var target = event.getSource();
        var qustnlabel = target.get("v.value");
        qustnlabel = helper.onlyReturnString(component, event, qustnlabel);
        if (!qustnlabel) {
            if (qustnlabel.length > 10000) {
                var message = "Character's Length should not exceed 10000";
                component.find('qustNameRich').focus();
                helper.showToast(component, 'error', message);
                return false;
            }
        }
    },
    callObjectField: function(component, event, helper) {
        var vQues = component.get("v.objCrteQues");
        if (vQues.lookup_Object_API_Name__c !== undefined && vQues.lookup_Object_API_Name__c !== "" && vQues.lookup_Object_API_Name__c.length !== 0) {
            helper.helperGetSelectedObjectFields(component, event, vQues.lookup_Object_API_Name__c);
        }
    }
})