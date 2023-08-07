({
	getOppDetail : function(component) {		
		let param = JSON.stringify({oppId: component.get("v.recordId"),recordId: component.get("v.recordId")});
		var action = component.get("c.invoke");
        action.setParams({action:'get_opportunity',parameters:param});
        action.setCallback(this, function(res) {            
            var state = res.getState();
            if (state === "SUCCESS"){                
                component.set("v.oppObj",res.getReturnValue().opp_obj);
                //alert(res.getReturnValue().is_allow);

                component.set("v.isEnableProfile",res.getReturnValue().is_allow);
                component.set("v.isOppLineItem",res.getReturnValue().lstOpportunityLineItem);
                component.set("v.isCheckProfile",res.getReturnValue().isCheckProfile);
                if(res.getReturnValue().access!=undefined && res.getReturnValue().access.length>0){
                    component.set("v.accessObj",res.getReturnValue().access[0]);    
                }
                this.getAmendTeamMember(component);
            } 
            else {
                window._LtngUtility.handleErrors(res.getError());
            }
        });
        $A.enqueueAction(action);
	},

    closeWonToZeroAmountHelper : function(component) {
        component.set("v.spinner",true);
        var obj = component.get("v.oppObj");
        var param = JSON.stringify({opp_obj: {sobjectType:'Opportunity',Id:obj.Id,Status__c:'Awaiting Payment',StageName:'Closed Won',Do_not_activate_Billing__c:true}});
        var action = component.get("c.invokeInsertOrUpdate");
        action.setParams({action:'set_opp',parameters:param});
        action.setCallback(this, function(res) {            
            var state = res.getState();
            component.set("v.spinner",false);            
            if (state === "SUCCESS"){
                obj.StageName='Closed Won';
                component.set("v.oppObj",obj);
                window._LtngUtility.toast('Success','success','Updated');
                $A.get('e.force:refreshView').fire();
            } 
            else {
                window._LtngUtility.handleErrors(res.getError());
            }
        });
        $A.enqueueAction(action);
    },
    cancelOpps : function(component) {
        component.set("v.spinner",true);
        var obj = component.get("v.oppObj");
        var param = JSON.stringify({opp_obj: {sobjectType:'Opportunity',Id:obj.Id,Reason_Lost__c:'AR Cancel / Re-bill',StageName:'Closed Lost'}});
        var action = component.get("c.invokeInsertOrUpdate");
        action.setParams({action:'set_opp',parameters:param});
        action.setCallback(this, function(res) {            
            component.set("v.spinner",false);
            var state = res.getState();
            component.set("v.isResubmitForAccApprovalModal",false);            
            if (state === "SUCCESS"){
                obj.StageName='Closed Won';
                obj.Status__c='Pending Accounting Approval';
                component.set("v.oppObj",obj);
                window._LtngUtility.toast('Success','success','Updated');
            } 
            else {
                window._LtngUtility.handleErrors(res.getError());
            }
        });
        $A.enqueueAction(action);
    },
    reSubmitHelper : function(component) {
        component.set("v.spinner",true);
        var obj = component.get("v.oppObj");
        var param = JSON.stringify({opp_obj: {sobjectType:'Opportunity',Id:obj.Id,Status__c:'Pending Accounting Approval',StageName:'Closed Won'}});
        var action = component.get("c.invokeInsertOrUpdate");
        action.setParams({action:'set_opp',parameters:param});
        action.setCallback(this, function(res) {            
            component.set("v.spinner",false);
            var state = res.getState();
            component.set("v.isResubmitForAccApprovalModal",false);            
            if (state === "SUCCESS"){
                obj.StageName='Closed Won';
                obj.Status__c='Pending Accounting Approval';
                component.set("v.oppObj",obj);
                window._LtngUtility.toast('Success','success','Updated');
            } 
            else {
                window._LtngUtility.handleErrors(res.getError());
            }
        });
        $A.enqueueAction(action);
    },

    getAmendTeamMember : function(component) {        
        let param = JSON.stringify({recordId: component.get("v.oppObj.Event_Series__c")});
        var action = component.get("c.invoke");
        action.setParams({action:'get_amend_team_member',parameters:param});
        action.setCallback(this, function(res) {            
            var state = res.getState();
            if (state === "SUCCESS"){                   
                if(res.getReturnValue().length>0){
                    component.set("v.isAmendTeamMember",true);
                }
                else{
                    component.set("v.isAmendTeamMember",false);   
                }
            } 
            else {
                window._LtngUtility.handleErrors(res.getError());
            }
        });
        $A.enqueueAction(action);
    },
    
})