({
	doInit : function(component, event, helper) {		
		helper.getOppDetail(component);
	},
	refreshButton:function(component, event, helper) {		
		console.log('Refresh action button.');
		helper.getOppDetail(component);
	},
	runCancelOppScript:function(component, event, helper) {
		helper.cancelOpps(component);
	},
	sendFloorPlanInfo:function(component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
	    urlEvent.setParams({
	      "url": "/apex/SendBoothLinkVF?Id="+component.get("v.recordId")
	    });
	    urlEvent.fire();
	},
	openAmendContractLink:function(component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
	    urlEvent.setParams({
	      "url": "/apex/vf_amendContract?oppId="+component.get("v.recordId")
	    });
	    urlEvent.fire();
	},
	openResubmitForAccApprovalModal:function(component, event, helper) {
		component.set("v.isResubmitForAccApprovalModal",true);
	},
	closeWonToZeroAmount :function(component, event, helper) {		
		helper.closeWonToZeroAmountHelper(component);
	},
	openNewContactModal : function(component, event, helper) {
		component.set("v.isOpenNewContactModal",true);
	},
	openOppCloneModal: function(component, event, helper) {		
        component.set("v.isOpenOppCloneModal",true);
	},
	openNewQuoteModal : function(component, event, helper) {
		component.set("v.isOpenCreateNewQuoteModal",true);
	},
	openSubmitForChangeModal:function(component, event, helper) {
		component.set("v.isOpenSubmitForChangeModal",true);
	},
    openCancelOppModal:function(component, event, helper) {
    	var accessObj = component.get("v.accessObj");
        if(!accessObj.HasEditAccess){
            window._LtngUtility.toast('Warning','warning','You did not have permission to cancel this opportunity');
            return;
        }
		component.set("v.isOpenCancelOppModal",true);
	},
	closeModal : function(component, event, helper) {
		component.set("v.isResubmitForAccApprovalModal",false);
	},
	reSubmitOpp:function(component, event, helper) {
		//Update two fields
		//StageName = Closed Won
		//Status__c = Pending Accounting Approval
		helper.reSubmitHelper(component);
	},
	isCancelOppChange:function(component, event, helper) {
		if(!component.get("v.isOpenCancelOppModal"))
		{
			helper.getOppDetail(component);
		}
	},
})