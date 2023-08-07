({
    getSingleQuestnnaireRecord: function(component) {
        //component.set("v.Spinner", true);
        var action = component.get("c.getQnaireRecord");
        action.setParams({ qnaireId: component.get("v.recordId") });
        action.setCallback(this, function(res) {
            //component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                // console.log(res.getReturnValue());
                component.set("v.objQuesnaire", res.getReturnValue());
            } else {
                this.showToast(component, 'ERROR:', 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    getQuesCategory: function(component) {
        var action = component.get("c.getQuenaireCategory");
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var opts = [];
                var res = res.getReturnValue();
                for (var i = 0; i < res.length; i++) {
                    if (res[i] != '')
                        opts.push({ label: res[i], value: res[i] })
                }
                component.set("v.lstQuenaireCategory", opts);
            } else {
                this.showToast(component, 'ERROR:', 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    getQuesLanguage: function(component) {
        var action = component.get("c.getQuenaireLanguage");
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var result = res.getReturnValue();                
                component.set("v.lstLanguage", result);
            } else {
                this.showToast(component, 'ERROR:', 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    getAllCommunity: function(component) {
        /*var action = component.get("c.getCommunities");
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var opts =[];
                var res = res.getReturnValue();
                for(var i=0;i<res.length;i++)
                {
                    if(res[i]!='')
                    opts.push({class:res[i].networkId,label:res[i].label,value:res[i].value})
                }
                component.set("v.lstCommunity", opts);
            } else {
                this.showToast(component,'ERROR:','error',res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);*/
    },
    updateTemplateHelper: function(component) {
        component.set("v.Spinner", true);
        var action = component.get("c.updateQnaire");
        var vQuesnaire = component.get("v.objQuesnaire");
        var arr = [];
        arr.push(vQuesnaire);
        action.setParams({ oQnaire: arr });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                this.showToast(component, 'SUCCESS:', 'success', 'Form has been updated');
                window.setTimeout($A.getCallback(function() {
                    var appEvent = $A.get("e.c:FBCloseEvent");
                    appEvent.setParams({ "modelName": 'formEdit' });
                    appEvent.fire();
                }, 3000));
            } else {
                this.showToast(component, 'ERROR:', 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    onlyReturnString: function(component, event, valueWithHtmlTag) {
        var regex = /(<([^>]+)>)/ig
        return valueWithHtmlTag.replace(regex, "");
    },
    showToast: function(component, title, type, message) {
        $A.createComponent("c:FBToast", { "msgbody": message, "msgtype": type }, function(newToast, status, errorMessage) {
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

    },
})