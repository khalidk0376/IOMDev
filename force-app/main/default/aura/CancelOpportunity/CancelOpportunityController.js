({
    doInit : function(component, event, helper) {
	   component.set("v.spinner",true);
       //helper.fetchAllowedProfiles(component);
		component.set("v.Cancel_Reason","");
        component.set("v.Reason_Lost","");
	},
    handleSubmit: function(component, event, helper) {
        event.preventDefault();// stop the form from submitting.
        var fields = event.getParam('fields');
        console.log('fields---'+JSON.stringify(fields));
        if(!fields.Reason_Lost__c){
            window._LtngUtility.toast('Error','error','Please select lost reason');
        }
        else if(!fields.Cancel_Reason__c){
            window._LtngUtility.toast('Error','error','Please enter cancel reason');
        } 
 		else
        { 
            fields.StageName='Closed Lost';
            fields.Status__c='--None--';
            /*
             * Reason Lost: AR Cancel / Re-bill = Status: AR Cancel / Re-bill
             * Reason Lost: Booth/Sponsorship Cancellation = Status: Opportunity Cancelled
             * Reason Lost: Digital / Print Cancellation = Status: Opportunity Cancelled
             */
            if(fields.Reason_Lost__c=='AR Cancel / Re-bill'){
                fields.Status__c='AR Cancel / Re-bill';
            }
            else if(fields.Reason_Lost__c=='Booth/Sponsorship Cancellation'){
                fields.Status__c='Opportunity Cancelled';
            }
            else if(fields.Reason_Lost__c=='Digital / Print Cancellation'){
                fields.Status__c='Opportunity Cancelled';
            }
			component.set("v.spinner",true);            
            component.find("submitbtn").set("v.disabled",true);
         	component.find('editFormCancelOpp').submit(fields); 
        }
    },
    handleSuccess: function(component, event) {
    	component.set("v.spinner",false);
        component.set("v.isOpenModal",false);        
        $A.get('e.force:refreshView').fire();
    },
    handleError: function(component, event) {
        component.find("submitbtn").set("v.disabled",false);
        component.set("v.spinner",false);
        
        var strError =event.getParams().error;
        //console.log('error.body.errorCode---'+JSON.stringify(strError.error.body.errorCode)); 
        if(strError.error)
        {
            if(strError.error.body.errorCode=='QUERY_TOO_COMPLICATED')
            {
                window.location='/lightning/r/Opportunity/'+component.get("v.recordId")+'/view'
            }  
            else
            {
               window._LtngUtility.handleError(event.getParams().error); 
            }   
        } 
        else
        {
            window._LtngUtility.handleError(event.getParams().error); 
        } 
    },
	closeModal : function(component, event, helper) {
		component.set("v.isOpenModal",false);  
	},
    handleLoad: function(component, event, helper) {
        component.set("v.spinner",false);
    },
})