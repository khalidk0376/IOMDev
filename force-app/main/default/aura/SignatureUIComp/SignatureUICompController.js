({
    Init: function(component, event, helper) {
        //component.set('v.openBranchingModal', true);
        helper.doInit(component, event, helper);
    },
    erase: function(component, event, helper) {
        helper.eraseHelper(component);
    },
    save: function(component, event, helper) {
        helper.saveHelper(component, event, helper);
    },    
	saveSignatureModal:function(component, event, helper){
        helper.saveHelper(component, event, true, false);    
    },
    hideModal:function(component, event, helper){
        helper.crudModalEvent(component, event, true, false);    
    }
})