({
	doInit : function(component, event, helper) {
        component.set("v.selectedItem",{id:'',Name:''});        
        if(!$A.util.isEmpty(component.get("v.selectedItemId"))){
            var action = component.get("c.getRecord");
            action.setParams({recordId:component.get("v.selectedItemId"),objectName: component.get("v.objectName"),fields:''});
            action.setCallback(this, function(res) {            
                var state = res.getState();
                if (state === "SUCCESS"){
                    var obj = res.getReturnValue();
                    //Update by Yash Gupta(01 July,2019)
                    if(Array.isArray(obj) && obj.length>0){
                    	component.set("v.selectedItem",{id:obj[0].Id,Name:obj[0].Name});    
                    }
                } 
                else {
                    window._LtngUtility.handleErrors(res.getError());
                }
            });
            $A.enqueueAction(action);
        }
    },
    searchDatas : function(component,event,helper) {
        var prpActVal2 = event.getSource().get("v.value");
        if(prpActVal2.length>1){
            event.getSource().set("v.validity",{valid:true, badInput :false});
            event.getSource().showHelpMessageIfInvalid();

            var searchLookup = component.find("searchLookup");
            $A.util.addClass(searchLookup, 'slds-is-open');
            $A.util.removeClass(searchLookup, 'slds-combobox-lookup');

            var action = component.get("c.getLookupDatas");
            action.setParams({
                objectName: component.get("v.objectName"),
                nameFieldApi: component.get("v.nameFieldApi"),
                searchKey:prpActVal2,
                accId: component.get("v.accountId"),
                partnerAccId:component.get("v.parterAccId"),
                isBilling:component.get("v.isBilling"),
                pageNumber:1,
                pageSize:10
            });
            action.setCallback(this, function(res) {
                
                var state = res.getState();
                if (state === "SUCCESS"){
                    console.log(res.getReturnValue());                
                    component.set("v.lookupData", res.getReturnValue().recordList);
                } 
                else {
                    window._LtngUtility.handleErrors(res.getError());
                }
            });
            $A.enqueueAction(action);
        }
    },     
    // Custom Lookup Auto complete Start
    handleBlur:function(component,event,helper){        
        window.setTimeout(
            $A.getCallback(function() {
                var searchLookup = component.find("searchLookup");        
                $A.util.removeClass(searchLookup, 'slds-is-open');
                $A.util.addClass(searchLookup, 'slds-combobox-lookup');                 
            }), 500
        );
        component.find("lookupField").set("v.value","");
    },
    handleSelect:function(component,event,helper){        
        //console.log(event.currentTarget.getAttribute("data-placeid"));        
        var searchLookup = component.find("searchLookup");        
        $A.util.removeClass(searchLookup, 'slds-is-open');
        $A.util.addClass(searchLookup, 'slds-combobox-lookup');
        component.set("v.selectedItem",{id:event.currentTarget.getAttribute("data-value"),Name:event.currentTarget.getAttribute("data-name")});
        component.set("v.selectedItemId",event.currentTarget.getAttribute("data-value"));
    },
    // Custom Lookup Auto complete End
	openModal : function(component, event, helper) {
		component.set("v.isOpenModal",true);
	},
    clearSelected : function(component, event, helper) {
        component.set("v.selectedItem",{id:'',Name:''});
        component.set("v.selectedItemId",'');
        //component.set("v.isOpenModal",true);
	},
    handleValidation:function(component, event, helper) {
        if(!event.getParam("isValid")){
            if(component.find("lookupField")!=undefined){
            	component.find("lookupField").showHelpMessageIfInvalid();       
            }
        }
    }
})