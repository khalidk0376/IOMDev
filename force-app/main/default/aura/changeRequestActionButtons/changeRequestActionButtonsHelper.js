({	
	getChangeRequestData : function(component)
	{
		var action = component.get("c.getChangeRequest");
		action.setParams({ 
			changeRequestId : component.get("v.recordId")
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
			if (state === "SUCCESS") 
			{
				var data = action.getReturnValue();
				component.set("v.changeRequestObject",data);
				this.setButtonVisiblity(component);
            } 
            else 
			{
				console.log('Unknown problem, state: ' + state + ', error: ' + JSON.stringify(response.getError()));
                this.toastMessage("Some error occured", "Please contact your System Admin","error");
			}
        });
	 	$A.enqueueAction(action);
	},
	invokeFullCancel: function(component,invList)
	{
		component.set("v.spinner",true);		
		var obj = component.get("v.changeRequestObject") ;
		obj.Current_Processing_Step__c= 'Step 1';
		var action = component.get("c.executeFullCancelRebill");
		action.setParams({ 
			changeReqobj : obj,
			listtoCancelInvId:invList
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
			if (state === "SUCCESS") 
			{
				this.toastMessage("Cancel & Rebill Complete","Full Cancel & Rebill completed successfully!",'success');
				/* $A.get('e.force:refreshView').fire();
				var resultsToast = $A.get("e.force:showToast");
				resultsToast.setParams({
					"title": "Cancel & Rebill Complete",
					"type":"success",
					"mode":"dismissible",
					"message": "Full Cancel & Rebill Completed successfully!"
				});
				resultsToast.fire();*/
				// this.updateChangeRequestStatus(component)
            } else 
			{
				console.log('Unknown problem, state: ' + state + ', error: ' + JSON.stringify(response.getError()));
                this.toastMessage("Some error occured", "Please contact your System Admin","error");
			}
			component.set("v.spinner",false);
        });
	 	$A.enqueueAction(action);
	},
	unholdOrder: function(component)
	{
		component.set("v.spinner",true);
		var obj = component.get("v.changeRequestObject") ;
		var action = component.get("c.executeUnHoldOrder");
		action.setParams({ 
			changeReqobj : obj
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
			if (state === "SUCCESS") 
			{
				this.toastMessage("Re-Queue Order process Complete","Re-Queue Order process completed successfully!","success");
				/*$A.get('e.force:refreshView').fire();
				var resultsToast = $A.get("e.force:showToast");
				resultsToast.setParams({
					"title": "Re-Queue Order process Complete",
					"type":"success",
					"mode":"dismissible",
					"message": "Re-Queue Order process Completed successfully!"
				});
				resultsToast.fire();*/
				// this.updateChangeRequestStatus(component)
            } else 
			{
				console.log('Unknown problem, state: ' + state + ', error: ' + JSON.stringify(response.getError()));
                this.toastMessage("Some error occured", "Please contact your System Admin","error");
			}
			component.set("v.spinner",false);
        });
	 	$A.enqueueAction(action);
	},
	updateChangeRequestStatus: function(component,status,errorMsg){		
		var obj = component.get("v.changeRequestObject") ;		
		obj.Change_Request_Status__c = 'Completed';		
		var action = component.get("c.updateChangeRequest");
		action.setParams({ 
			changeReqobj : obj
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
			if (state === "SUCCESS") 
			{
				this.toastMessage("Update","Execution Completed successfully!","success");
               /* $A.get('e.force:refreshView').fire();
				var resultsToast = $A.get("e.force:showToast");
				resultsToast.setParams({
					"title": "update",
					"message": "Execution Completed successfully!"
				});
				resultsToast.fire();*/
            } else 
			{
				console.log('Unknown problem, state: ' + state + ', error: ' + JSON.stringify(response.getError()));
                this.toastMessage("Some error occured", "Please contact your System Admin","error");
			}
        });
	 $A.enqueueAction(action);
    },
	/*updateOrderTaxAddress: function(component)
	{
		component.set("v.spinner",true);
		var obj = component.get("v.changeRequestObject") ;
		var action = component.get("c.executeOrderTaxAddressUpdate");
		action.setParams({ 
			changeReqobj : obj
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
			if (state === "SUCCESS") 
			{
				this.toastMessage("Order tax address update process Complete","Order tax address update process Complete!","success");
            } else 
			{
				console.log('Unknown problem, state: ' + state + ', error: ' + JSON.stringify(response.getError()));
			}
			component.set("v.spinner",false);
        });
	 	$A.enqueueAction(action);
	},	*/
	executeAmendOpportunity: function(component)
	{
		component.set("v.spinner",true);
		var obj = component.get("v.changeRequestObject") ;
		var action = component.get("c.amendOpportunity");
		action.setParams({ 
			changeReqobj : obj
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
			if (state === "SUCCESS") 
			{
				var quoteId = action.getReturnValue();
				obj.Amended_Quote_Id__c = quoteId;
				component.set("v.changeRequestObject",obj);
				this.toastMessage("Amendment Opportunity Complete","Amendment Opportunity and Quote process complete!","success");									
				this.navigatetoQLE(component,quoteId);
            } else 
			{
				console.log('Unknown problem, state: ' + state + ', error: ' + JSON.stringify(response.getError()));
                this.toastMessage("Some error occured", "Please contact your System Admin","error");
			}
			component.set("v.spinner",false);
        });
	 	$A.enqueueAction(action);
	},
	executePC_AI: function(component)
	{
		component.set("v.spinner",true);
		var obj = component.get("v.changeRequestObject") ;
		var action = component.get("c.executePartialCreditORAddtionalInvoiceQuote");
		action.setParams({ 
			changeReqobj : obj
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
			if (state === "SUCCESS") 
			{
				this.toastMessage("Partial Credit or addtional Invoice Complete","Partial Credit or addtional Invoice process complete!","success");
                /*$A.get('e.force:refreshView').fire();
				var resultsToast = $A.get("e.force:showToast");
				resultsToast.setParams({
					"title": "PartialCredit OR AddtionalInvoice Complete",
					"type":"success",
					"mode":"dismissible",
					"message": "PartialCredit OR AddtionalInvoice Complete process Complete!"
				});
				resultsToast.fire();*/
				// this.updateChangeRequestStatus(component)
            } else 
			{
				console.log('Unknown problem, state: ' + state + ', error: ' + JSON.stringify(response.getError()));
				this.toastMessage("Some error occured", "Please contact your System Admin","error");			}
			component.set("v.spinner",false);
        });
	 	$A.enqueueAction(action);
	},
	executeFCRQuote: function(component)
	{
		component.set("v.spinner",true);
		var obj = component.get("v.changeRequestObject") ;
		var action = component.get("c.executeFullCancelRebillQuote");
		action.setParams({ 
			changeReqobj : obj
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
			if (state === "SUCCESS") 
			{
				this.toastMessage("FCR Complete","FCR process Complete!","success");
                /*$A.get('e.force:refreshView').fire();
				var resultsToast = $A.get("e.force:showToast");
				resultsToast.setParams({
					"title": "Order tax address update process Complete",
					"type":"success",
					"mode":"dismissible",
					"message": "Order tax address update process Complete!"
				});
				resultsToast.fire();*/
				// this.updateChangeRequestStatus(component)
            } else 
			{
				console.log('Unknown problem, state: ' + state + ', error: ' + JSON.stringify(response.getError()));
                this.toastMessage("Some error occured", "Please contact your System Admin","error");
			}
			component.set("v.spinner",false);
        });
	 	$A.enqueueAction(action);
	},
	navigatetoQLE :function(component,quoteId)
	{
		if(quoteId)
		{
			setTimeout(function(){
				console.log('navigate.....');
				var url = '/apex/SBQQ__sb?id=' + quoteId + '#quote/le?qId=' + quoteId;
				// window.open(url, "_self");
				var urlEvent = $A.get("e.force:navigateToURL");
				urlEvent.setParams({
					"url":url
				});
				urlEvent.fire();
			}, 1500);
		}
	},
	toastMessage: function(tilte,message,msgType)
	{
		$A.get('e.force:refreshView').fire();
		var resultsToast = $A.get("e.force:showToast");
		resultsToast.setParams({
			"title": tilte,
			"type":msgType,
			"mode":"dismissible",
			"message": message
		});
		resultsToast.fire();
	},
	setButtonVisiblity: function(component)
	{
		// Amendment Type with only Reprint invoice with updated Changes
		const noPriceChangeTypes = ["PO number change", "Account Name Change", "VAT Registration Number Change", "Bill to Contact Details Change","Shipping Address Change","Billing Address Change"];

		// Amendment Type with new Amnedment Opportunity and Rebill
		const fullCancelRebillChangeTypes = ["Product Upgrade", "Product Downgrade", "Billing Schedule Change", "Number of Impressions Amendment"];

		// Amendment Type with Full Cancel without Subscription
		const fullCancelOnlyChangeTypes = ["Cancellation"];

		var obj = component.get("v.changeRequestObject");
		this.setDefaultButtonVisiblity(component);
		var butnObj = component.get("v.buttonAccessObject");

		if(fullCancelRebillChangeTypes.includes(obj.Type_of_Change__c))
		{
			butnObj.set1 = false;
			butnObj.set2 = true;  // Show new Amendment Opp Process -			
			butnObj.set3 = false;
		}
		// For Only Full Cancel
		if(fullCancelOnlyChangeTypes.includes(obj.Type_of_Change__c))
		{
			butnObj.set1 = false;
			butnObj.set2 = false;  			
			butnObj.set3 = true; // Cancel All Invoices & Hold all Orders 
		}

		if(obj.Change_Request_Status__c ==='Approved' && obj.Current_Processing_Step__c === 'Step 0' && !noPriceChangeTypes.includes(obj.Type_of_Change__c))
		{
			if(fullCancelRebillChangeTypes.includes(obj.Type_of_Change__c))
			{
				butnObj.cAopp = false;
			}else
			{
				butnObj.fcr = false;
			}
		}

		// if(obj.Change_Request_Status__c ==='Amend Data Complete' && !noPriceChangeTypes.includes(obj.Type_of_Change__c))
		if(obj.Change_Request_Status__c ==='Approved'&& obj.Current_Processing_Step__c=== 'Step 1' && !noPriceChangeTypes.includes(obj.Type_of_Change__c))
		{
			if(fullCancelRebillChangeTypes.includes(obj.Type_of_Change__c))
			{
				butnObj.fcrpc = false;
				butnObj.pCAI = false;
			}else
			{
				butnObj.rqo = false;
			}
		}
		console.log('butnObj - '+ JSON.stringify(butnObj));
		component.set("v.buttonAccessObject",butnObj);
	},
	setDefaultButtonVisiblity: function(component)
	{
		var btnvisobj = {fcr:true, rqo:true,updAdd:true,cAopp:true,fcrpc:true,pCAI:true,set1:true,set2:false,set3:false};
		component.set("v.buttonAccessObject",btnvisobj);
	},
	fetchInvs: function(component)
	{
		component.set("v.spinner",true);
		var crObj = component.get("v.changeRequestObject") ;
		var action = component.get("c.getAllInvoices");
		action.setParams({ 
			changeReqobj: crObj
		});
		action.setCallback(this, function(response)
		{
            var state = response.getState();
			if (state === "SUCCESS") 
			{				
				let listsObj = JSON.parse(action.getReturnValue());
				// console.log('listsObj -'+action.getReturnValue());
				let InvTableData = [];
				listsObj.Invoices.forEach((row,i) => {
					InvTableData.push({Id:row.Id,name:row.Name, ERPRefNo:row.ERP_Reference__c, dueDate:row.blng__DueDate__c, amount:row.blng__TotalAmount__c,status:row.blng__InvoiceStatus__c,type:"Invoice"});
				});
				if(InvTableData.length<1)
				{component.set("v.noInvMessage",'No Invoice found!');}
				component.set("v.invData",InvTableData);
            } else 
			{
				console.log('Unknown problem in fetchInvs, state: ' + state + ', error: ' + JSON.stringify(response.getError()));
                this.toastMessage("Some error occured", "Please contact your System Admin","error");
			}
			component.set("v.spinner",false);
        });
	 	$A.enqueueAction(action);
	},
})