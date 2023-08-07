({
	doInit : function(component, event, helper) {		
		var firstDay = new Date();
  		var lastDay = new Date();
        // As per the new Kaban ticket GGCKB - 140 , I made changes 7 to 30 days.
        lastDay.setDate(firstDay.getDate()+30);
		component.set("v.quoteObj",{
			SBQQ__Account__c:component.get("v.accountId"),
			SBQQ__Opportunity2__c:component.get("v.oppId"),
			SBQQ__SalesRep__c:component.get("v.repId"),
			SBQQ__PrimaryContact__c:component.get("v.primaryContId"),//component.get("v.accountId"),
			Billing_Contact__c:component.get("v.billingContId"),
			SBQQ__StartDate__c:firstDay.getFullYear()+'-'+(firstDay.getMonth()+1)+'-'+firstDay.getDate(),
			SBQQ__ExpirationDate__c:lastDay.getFullYear()+'-'+(lastDay.getMonth()+1)+'-'+lastDay.getDate()
		});

		helper.getQuoteDetail(component);		
	},
	closeModal : function(component, event, helper) {
		component.set("v.isOpenModal",false);
	},
	handleSubmit: function(component, event, helper) {
        if (event.which == 13){
            alert(0);
        }
        event.preventDefault();       // stop the form from submitting
        var fields = event.getParam('fields');
        var isQuoteExist = component.get("v.isQuoteExist");
        if(!isQuoteExist){
        	fields.SBQQ__Primary__c = true;	
        }
        component.set("v.spinner",true);
        component.find('editForm2').submit(fields);
    },
    handleSuccess: function(component, event) {
    	component.set("v.spinner",false);
        var payload = event.getParams().response;
        window._LtngUtility.toast('Success','success','New Quote has been created');        
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": payload.id,
          "slideDevName": "detail"
        });
        navEvt.fire();
    }
})