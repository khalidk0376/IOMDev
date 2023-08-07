({
    doInit: function(component, event, helper) {
        var isEditQue = component.get("v.isEditQue");
        if (isEditQue === false) {
            helper.removeQuesValue(component, event);
        }
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

        qustnlabel = helper.onlyReturnString(component, event, qustnlabel);
        if (!qustnlabel || qustnlabel.trim().length === 0) {
            message = "write your question";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            component.find('qustNameRich').focus();
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
        if (helper.checkNumber(component, event, qes.Minimum_Value__c) === false) {
            message = "Enter minimum value (not allow decimal value).";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            return false;

        }
        if (helper.checkNumber(component, event, qes.Maximum_value__c) === false || parseInt(qes.Maximum_value__c, 10) === 0) {
            message = "Enter maximum value (not allow decimal value) .";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            return false;

        }
        if(!qes.Step_Size__c || parseFloat(qes.Step_Size__c, 10)===0.0){
            message = "Enter step size value.";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            return false;
        }
        else if(!helper.checkNumberAndDecimal(component, event, qes.Step_Size__c)) {
            message = "Please enter valid format (Only allow 2 point decimal number)";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            return false;
        }
        if (!helper.checkNumber(component, event, qes.Default_Value__c) || parseInt(qes.Default_Value__c, 10) === 0) {
            message = "Enter default value (not allow decimal value).";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            return false;

        }
        if (parseInt(qes.Minimum_Value__c,10) > parseInt(qes.Maximum_value__c,10)) {
            message = "Minimum value should be less or equal than maximum value.";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            return false;
        }
        if (parseInt(qes.Default_Value__c,10) > parseInt(qes.Maximum_value__c,10) || parseInt(qes.Default_Value__c,10) < parseInt(qes.Minimum_Value__c,10)) {
            message = "Default value should be between minimum and maximum values.";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            return false;
        }
        if (qustnlabel.trim().length <= 10000 && qustnlabel.trim().length !== 0) {
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
        if (qustnlabel.length > 10000) {
            var message = "Character's Length should not exceed 10000";
            component.find('qustNameRich').focus();
            helper.showToast(component, 'error', message);
            return false;
        }
    }
})