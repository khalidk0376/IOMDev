({
    helperSelectedrecord: function(component, event, helper) {
        var ev = $A.get("e.c:LookupValueEvent");
        if(ev==undefined){
            return;
        }

        var target = event.target;
        var SelIndex = helper.getIndexFrmParent(target, helper, "data-selectedIndex");
        if (SelIndex) {
            var serverResult = component.get("v.record_result");
            var selItem = serverResult[SelIndex];
            if (selItem.val) {
                component.set("v.selrecord", selItem);                
                component.set("v.response", selItem.text);
                component.set("v.last_ServerResult", serverResult);                
                ev.setParams({"questionId":component.get("v.questionId"),"responseText":selItem.text});
            }
            //ev.setParams({"questionId":component.get("v.questionId"),"responseText":''});
            component.set("v.record_result", null);
            ev.fire();
        }

        if($A.util.isEmpty(component.get("v.selrecord"))){
            component.find("inputFields").set("v.value","");
            component.set("v.response", "");
        }
    },
    helperRecordCall: function(component, event, helper) 
    {
        var searchText = event.getSource().get("v.value");
        var last_SearchText = component.get("v.last_SearchText");
        //Escape button pressed 
        if (event.keyCode === 27 || !searchText.trim()) {
            helper.helperclearSelected(component, event, helper);
        } else if (searchText.trim() !== last_SearchText) {
            //Save server call, if last text not changed

            var sobjectName = component.get("v.sobjectName");
            var field_API_Name = component.get("v.field_API_Name");
            var field_ID = component.get("v.field_ID");

            var action = component.get('c.searchDB');
            action.setParams({
                sobjectName: sobjectName,
                field_API_Name: field_API_Name,
                field_ID: field_ID,
                searchText: searchText
            });

            action.setCallback(this, function(a) {
                this.handleResponse(a, component, helper);
            });

            component.set("v.last_SearchText", searchText.trim());
            $A.enqueueAction(action);
        } else if (searchText && last_SearchText && searchText.trim() === last_SearchText.trim()) {
            component.set("v.record_result", component.get("v.last_ServerResult"));

        }
    },
    handleResponse: function(res, component, helper) {
        var methodName;
        var compName = component.get("v.compName");
        var UiMessage = $A.get('$Label.c.IMCC_Custom_UI_Error_Message');
        if (res.getState() === 'SUCCESS') {
            var retObj = JSON.parse(res.getReturnValue());
            if (retObj.length <= 0) {
                var noResult = JSON.parse('[{"text":"No Results Found"}]');
                component.set("v.record_result", noResult);
                component.set("v.last_ServerResult", noResult);
            } else {
                component.set("v.record_result", retObj);
                component.set("v.last_ServerResult", retObj);
            }
        } else {
            //var errors = res.getError();
            //this.showToast(component, errors[0].message);
            methodName = 'searchDB';
            var cmpError = component.find('imcc_lwcUtility');
            cmpError.handleAuraErrors(compName,methodName,res.getError());
            helper.showNewToast(component, "Error: ", 'error',UiMessage);
        }
    },
    getIndexFrmParent: function(target, helper, attributeToFind) {
        //User can click on any child element, so traverse till intended parent found
        var SelIndex = target.getAttribute(attributeToFind);
        while (!SelIndex) {
            target = target.parentNode;
            SelIndex = helper.getIndexFrmParent(target, helper, attributeToFind);
        }
        return SelIndex;
    },
    helperclearSelected: function(component, event, helper) {
        component.set("v.selrecord", null);
        component.set("v.record_result", null);
    },
    showToast: function(component, message) {
        var toastEvent = $A.get("e.force:showToast");
        if(toastEvent){
            toastEvent.setParams({
                title: 'Alert',
                message: message,
                duration: ' 5000',
                key: 'info_alt',
                type: 'error',
                mode: 'dismissible'
            });
            toastEvent.fire();
        }
        else{
            console.error('FB Warning: '+message);
        }
    }
})