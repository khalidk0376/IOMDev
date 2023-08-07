({
    doInit: function(component, event, helper) {
        var isEditQue = component.get("v.isEditQue");
        if (isEditQue === false) {
            helper.removeQuesValue(component, event);
        } else {
            var qes = component.get("v.objCrteQues");
            component.set("v.lstSwitchQuestionOptions", qes.Question_Options__r);
            var QOption = component.get("v.lstSwitchQuestionOptions");
            for (var index = 0; index < QOption.length; index++) {
                if (index === 0) {
                    component.set("v.optionFirstName", QOption[index].Name__c);                    
                } else if (index === 1) {
                    component.set("v.optionSecondName", QOption[index].Name__c);                    
                }
            }
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
        try{
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
            message = "Write your question";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            component.find('qustNameRich').focus();
            return false;
        } else if (component.get("v.objCrteQues").Help_Text_Required__c === true) {
            var helpText = component.find("helpTextInp");
            var helpTextValue = helpText.get("v.value");
            if (!helpTextValue) {
                message = "Enter help text.";
                helper.showToast(component, 'error', message);
                component.set("v.isShowbutton", false);
                return false;
            }
        }
        
        var optionFirstName = component.get("v.optionFirstName");        
        var optionSecondName = component.get("v.optionSecondName");
        
        if (!optionFirstName) {
            message = "Enter first option name.";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            return false;
        }
        
        if (!optionSecondName) {
            message = "Enter second option name.";
            helper.showToast(component, 'error', message);
            component.set("v.isShowbutton", false);
            return false;
        }

        if (qustnlabel.trim().length <= 10000 && qustnlabel.trim().length !== 0) {
            var isEditQue = component.get("v.isEditQue");
            if (isEditQue === false) {                
                helper.addOptionVal(component, optionFirstName);
                helper.addOptionVal(component, optionSecondName);
            } else {
                helper.updateValues(component, event);
            }
            helper.SaveQuestion(component, event);
        } else {
            message = "Character's Length should not exceed 10000.";
            helper.showToast(component, 'error', message);
            component.find('qustNameRich').focus();
            component.set("v.isShowbutton", false);
        }
        }
        catch(e){
            console.error(e);
        }
    },
    checkTextLength: function(component, event, helper) {
        var target = event.getSource();        
        var qustnlabel = target.get("v.value");        
        if (!qustnlabel) {
            if (qustnlabel.length > 10000) {
                var message = "Character's Length should not exceed 10000";
                helper.showToast(component, 'error', message);
                return false;
            }
        }
    }
})