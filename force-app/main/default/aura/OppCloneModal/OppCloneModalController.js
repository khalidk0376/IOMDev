({
	doInit : function(component, event, helper) {		
		//helper.getQuoteDetail(component);		
	},
	closeModal : function(component, event, helper) {
        //alert(0);
		component.set("v.isOpenModal",false);
	},
    handleError:function(component, event, helper) {
        component.set("v.spinner",false);
    },
	handleSubmit: function(component, event, helper) {
        event.preventDefault();       // stop the form from submitting
        var fields = event.getParam('fields');        
        if(!$A.util.isEmpty(component.get("v.oppObj.Opportunity_Contact__c"))){
            fields.Opportunity_Contact__c = component.get("v.oppObj.Opportunity_Contact__c");
        }
        if(!$A.util.isEmpty(component.get("v.oppObj.Billing_Contact__c"))){
            fields.Billing_Contact__c     = component.get("v.oppObj.Billing_Contact__c");    
        }
        if(!$A.util.isEmpty(component.get("v.oppObj.CurrencyIsoCode"))){
            fields.CurrencyIsoCode     = component.get("v.oppObj.CurrencyIsoCode");    
        }
        component.set("v.spinner",true);
        component.find('editForm2').submit(fields);
    },
    handleSuccess: function(component, event,helper) {    	
        var payload = event.getParams().response;
        helper.oppCloneRelated(component,payload.id);
    }
})