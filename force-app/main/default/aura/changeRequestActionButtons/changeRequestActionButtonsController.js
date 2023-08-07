({
	onLoad : function(component, event, helper) 
	{		
		let invcolumns = [
            { label: 'Name', fieldName: 'name' },
			{ label: 'Status', fieldName: 'status'},
            { label: 'ERP Ref No', fieldName: 'ERPRefNo'},        
            { label: 'Amount', fieldName: 'amount', type: 'currency', cellAttributes: { alignment: 'left' } },
            { label: 'Due Date', fieldName: 'dueDate', type: 'date' },
        ];
		component.set("v.invCrcolumns",invcolumns);
		helper.getChangeRequestData(component);		
	},
	forceRefreshViewHandler : function(component, event, helper) 
	{		
		helper.getChangeRequestData(component);
	},
	execute1 : function(component, event, helper) 
	{
		component.set("v.showInvoiceSelectionModal",true);
		helper.fetchInvs(component);
		//helper.invokeFullCancel(component);
	},
	execute2 : function(component, event, helper) 
	{
		helper.unholdOrder(component);
	},
	execute3 : function(component, event, helper)
	{
		// helper.updateOrderTaxAddress(component);
	},
	execute4 : function(component, event, helper) 
	{
        var butnObj = component.get("v.buttonAccessObject");
        butnObj.cAopp = false;
		if(component.get("v.changeRequestObject.Contract__c") ||component.get("v.changeRequestObject.Opportunity__r.Main_Contract__c")){
			helper.executeAmendOpportunity(component);
		}else{
			helper.toastMessage("Error","No contract found to create a new amendment opportunity!",'error');
		}
		
	},
	execute5 : function(component, event, helper) 
	{
		helper.executeFCRQuote(component);
	},
	execute6 : function(component, event, helper)
	{		
		helper.executePC_AI(component);
	},
	execute7 : function(component, event, helper) 
	{
		//helper.updateOrderTaxAddress(component);
	},
	closeInvModal :function(component, event, helper) 
	{
		component.set("v.reqErrorMessage",'');
		component.set("v.showRequiredInvMessage",false);
		component.set("v.selectedInvIds",[]);
		component.set("v.showInvoiceSelectionModal",false);
	},
	handleInvSelection :function(component, event, helper) 
	{
		var selectedRows = event.getParam('selectedRows');
		// console.log('selectedRows -'+ JSON.stringify(selectedRows));
		let invIds=[];		
        if(selectedRows && Array.isArray(selectedRows))
        {
            selectedRows.forEach((item)=>{
                
                if(item.type=="Invoice" && item.Id){
                    invIds.push(item.Id);
                }                
            });
			component.set("v.selectedInvIds",invIds);
			component.set("v.isNextDisabled",true);
            if(selectedRows.length > 0)
            {
				component.set("v.isNextDisabled",false);
            }
        }
	},
	invoiceSelectionModalNext :function(component, event, helper) 
	{		
		component.set("v.reqErrorMessage",'');
		component.set("v.showRequiredInvMessage",false);
		let invList = component.get("v.selectedInvIds");		
		if(Array.isArray(invList) && invList.length>0)
		{
			helper.invokeFullCancel(component,invList);
			component.set("v.showInvoiceSelectionModal",false);
		}else{			
			component.set("v.reqErrorMessage",'Please select at least one invoice to cancel.');
			component.set("v.showRequiredInvMessage",true);
		}		
	}
})