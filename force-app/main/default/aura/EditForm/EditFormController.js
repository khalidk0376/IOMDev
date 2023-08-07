({
    doInit: function(component, event, helper) {
        helper.getSingleQuestnnaireRecord(component);
        helper.getQuesCategory(component);
        helper.getQuesLanguage(component);
    },
    closeForm: function(component, event, helper) {
        var appEvent = $A.get("e.c:FBCloseEvent");
        appEvent.setParams({ "modelName": 'formEdit' });
        appEvent.fire();
    },
    communityChange: function(component, event, helper) {
        /*var opts =  component.get("v.lstCommunity");
        for(var i=0;i<opts.length;i++)
        {
            if(event.getSource().get("v.value")==opts[i].value){
                component.set("v.objQuesnaire.NetworkId__c",opts[i].class);
            }
        }*/
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
    updateQQuesnaireRecrod: function(component, event, helper) {
        try{
        var allValid = component.find('formedit').reduce(function(validSoFar, inputCmp) {
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
                helper.updateTemplateHelper(component);
            }
        } else {
            helper.showToast(component, 'ERROR:', 'error', 'Please update the invalid form entries and try again.');
        }
        }
        catch(e){
            console.error(e);
        }
    },
    handleSuccess: function(component, event, helper) {
        var payload = event.getParams().response;
        var appEvent = $A.get("e.c:FBCloseEvent");
        appEvent.setParams({ "modelName": 'formEdit' });
        appEvent.fire();
    },

})