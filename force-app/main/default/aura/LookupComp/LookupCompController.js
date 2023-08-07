({
    Selectedrecord: function(component, event, helper) {
        helper.helperSelectedrecord(component, event, helper);
    },
    recordCall: function(component, event, helper) {
    	helper.helperRecordCall(component, event, helper);
    },
    clearSelected: function(component, event, helper) {
        helper.helperclearSelected(component, event, helper);
    },
    handleSubmitButton:function(component, event, helper){
    	var ev = $A.get("e.c:getValidationInfoEvt");
        var inputCmp = component.find('inputFields');
        
        if(inputCmp!=undefined){
            if(inputCmp.get('v.validity').valid==false){
                inputCmp.showHelpMessageIfInvalid();    
            }
            ev.setParams({"isValid":inputCmp.get('v.validity').valid,"questionId":component.get("v.questionId")});
        }
        else
        {
            ev.setParams({"isValid":true,"questionId":component.get("v.questionId")});
        }
        ev.fire();
    }
})