({
    doInit : function(component, event, helper) {
        //console.log(JSON.stringify(component.get("v.contactObj")));
        helper.getAccountDetail(component);		
    },
    closeModal : function(component, event, helper) {
        component.set("v.contactObj",{});
        component.set("v.isOpenModal",false);
    },
    saveModalData:function(component, event, helper) {
        
        if(window._LtngUtility.validate(component)){
            if(helper.validate(component)){
                helper.createNewContact(component);		
            }
        }
    },
    onBillingCountryChange: function(component, event, helper) {
        var val = event.getSource().get("v.value"); // get selected controller field value
        var lab = '';
        for(var i=0;i<event.getSource().get("v.options").length;i++){
            if(event.getSource().get("v.options")[i].value==val){
                lab = event.getSource().get("v.options")[i].label;
            }
        }
        var controllerValueKey = lab+'__$__'+val;        
        helper.onControllerFieldChange(component,val);	
    },
    // Google Address Auto complete Start
    handleBlur:function(component,event,helper){        
        window.setTimeout(
            $A.getCallback(function() {
                var conObj = component.get("v.contactObj");
                if(conObj){
                    conObj.MailingStreet = component.get("v.searchKey");
                }
                
                component.set("v.contactObj",conObj);
                var searchLookup = component.find("searchLookup");        
                $A.util.removeClass(searchLookup, 'slds-is-open');
                $A.util.addClass(searchLookup, 'slds-combobox-lookup');        
            }), 500
        );
    },
    handleSelect:function(component,event,helper){        
        //console.log(event.currentTarget.getAttribute("data-placeid"));
        component.set("v.searchKey",event.currentTarget.getAttribute("data-record"));
        component.set("v.contactObj.MailingStreet",event.currentTarget.getAttribute("data-record"));
        var searchLookup = component.find("searchLookup");        
        $A.util.removeClass(searchLookup, 'slds-is-open');
        $A.util.addClass(searchLookup, 'slds-combobox-lookup');
        
        helper.displayOptionDetails(component,event,event.currentTarget.getAttribute("data-placeid"));
    },
    keyPressController: function (component, event, helper) {
        event.getSource().set("v.validity",{valid:true, badInput :false});
        event.getSource().showHelpMessageIfInvalid();
        var prpActVal2 = event.getSource().get("v.value");        
        var searchKey = component.get("v.searchKey");
        if(searchKey && searchKey.length>1){
            helper.openListbox(component, searchKey);
            helper.displayOptionsLocation(component, searchKey);
        }
        else if(searchKey && searchKey.length==0){
            component.set("v.contactObj.MailingStateCode", "");
            component.set("v.contactObj.MailingCity", "");
            component.set("v.contactObj.MailingPostalCode", "");
            component.set("v.contactObj.MailingCountryCode", "");
        }
        
    }
    // Google Address Auto complete End
})