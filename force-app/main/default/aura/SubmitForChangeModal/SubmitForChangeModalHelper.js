({
    validate:function(component,fields){
        var isvalid = true;
        var missingFields = [];
        if(fields.Type_of_Change__c=='Product Upgrade' || fields.Type_of_Change__c=='Cancellation' || fields.Type_of_Change__c=='Product Downgrade')
        {
            if(fields.Contract__c == null || fields.Contract__c == ''){
                isvalid = false;
                missingFields.push("Contract");
            }
        }
        if(fields.Type_of_Change__c=='Payment Schedule')
        {
            if(fields.New_Payment_Schedule__c == null || fields.New_Payment_Schedule__c == ''){
                isvalid = false;
                missingFields.push("New Payment Schedule");
            }
        }
        if(fields.Type_of_Change__c=='Incorrect Account details with Tax impact Amendment')
        {
            if(fields.New_Order__c == null || fields.New_Order__c == ''){
                isvalid = false;
                missingFields.push("Order");
            }
            if(fields.New_Billing_Country__c == null || fields.New_Billing_Country__c == ''){
                isvalid = false;
                missingFields.push("New Billing Country");
            }
            if(fields.New_Billing_Street__c == null || fields.New_Billing_Street__c == ''){
                isvalid = false;
                missingFields.push("New Billing Street");
            }
            if(fields.New_Billing_City__c == null || fields.New_Billing_City__c == ''){
                isvalid = false;
                missingFields.push("New Billing City");
            }
        }

        if(fields.Type_of_Change__c=='Updated VAT number Amendment')
        {
            if(fields.New_Order__c == null || fields.New_Order__c == ''){
                isvalid = false;
                missingFields.push("Order");
            }
            if(fields.New_Account_Tax_Number__c == null || fields.New_Account_Tax_Number__c == ''){
                isvalid = false;
                missingFields.push("New Account Tax Number");
            }
        }

        if(fields.Type_of_Change__c=='Incorrect Product Tax amendment')
        {
            if(fields.New_Order__c == null || fields.New_Order__c == ''){
                isvalid = false;
                missingFields.push("Order");
            }
            if(fields.Product__c == null || fields.Product__c == ''){
                isvalid = false;
                missingFields.push("Product");
            }
            if(fields.New_Event_Product_Type__c == null || fields.New_Event_Product_Type__c == ''){
                isvalid = false;
                missingFields.push("New Event Product Type");
            }
        }

        if(fields.Type_of_Change__c=='Update Bill to Contact')
        {
            if(fields.Invoice__c == null || fields.Invoice__c == ''){
                isvalid = false;
                missingFields.push("Invoice");
            }
            if(fields.New_Billing_Contact__c == null || fields.New_Billing_Contact__c == ''){
                isvalid = false;
                missingFields.push("New Billing Contact");
            }
        }
        if(!isvalid){
            var fieldsList = missingFields.join(",");
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Required field(s) missing "+ fieldsList,
                "type":"error"
            });
            toastEvent.fire();
        }
        return isvalid; 
    },
    getOppDetail : function(component) {		
		let param = JSON.stringify({oppId: component.get("v.oppObj.Id"),recordId: component.get("v.oppObj.Id")});
        console.log('Action Prams'+param);
		var action = component.get("c.invoke");
        action.setParams({action:'get_opportunity',parameters:param});
        action.setCallback(this, function(res) {            
            var state = res.getState();
            if (state === "SUCCESS"){                
                component.set("v.oppObj",res.getReturnValue().opp_obj);
                component.set("v.orderObj",res.getReturnValue().order_obj);
                component.set("v.changeRequestObj",{
                    Account__c:component.get("v.oppObj.AccountId"),
                    Opportunity__c:component.get("v.oppObj.Id"),
                    Edition__c:component.get("v.oppObj.Default_Edition__c"),
                    Order__c : component.get("v.orderObj.Id"),
                    Contract__c : component.get("v.oppObj.Main_Contract__c"),
                });
                
                var action3 = component.get("c.getDependentMap");
                action3.setParams({parameters:JSON.stringify({objApi:"Account",contrfieldApiName:"billingCountryCode",depfieldApiName:"billingStateCode"})});
                action3.setCallback(this, function(response3) {
                    var state3 = response3.getState();
                    if (state3 === "SUCCESS") {
                        var storeResponse3 = response3.getReturnValue();
                        component.set("v.countryStateMap",storeResponse3);
                    }
                });
                $A.enqueueAction(action3);
                
                var action4 = component.get("c.getAccountCountryPicklistOptions");
                action4.setCallback(this, function(response4) {
                    var state4 = response4.getState();
                    if (state4 === "SUCCESS") {
                        var storeResponse4 = response4.getReturnValue();
                        var countrylist = [];
                        for (var key in storeResponse4) {
                            // check if the property/key is defined in the object itself, not in parent
                            if (storeResponse4.hasOwnProperty(key)) {           
                                var obj = {
                                    label:storeResponse4[key],
                                    value:key
                                }
                                countrylist.push(obj);
                            }
                        }
                        component.set("v.countrylist",countrylist);
                    }
                });
                $A.enqueueAction(action4);

                var action5 = component.get("c.getOptions");
                action5.setParams({
                    objName: component.get("v.sObjectName"),
                    fieldName: component.get("v.fieldName")
                });
                action5.setCallback(this, function(response) {
                    var listOpt =[];
                    var list = response.getReturnValue();
                    console.log('list ' +JSON.stringify(list));
                    for(var i=0;i<list.length;i++)
                    {
                        if(list[i] != 'Custom')
                        {
                            listOpt.push(list[i]);
                        }
                    }
                    component.set("v.picklistValues", listOpt);
                })
                $A.enqueueAction(action5);
            } 
            else {
                window._LtngUtility.handleErrors(res.getError());
            }
        });
        $A.enqueueAction(action);
	}
})