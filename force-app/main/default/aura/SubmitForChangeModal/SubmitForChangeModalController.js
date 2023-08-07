({
    doInit : function(component, event, helper) {
        component.set("v.statelist",[]);
        component.set("v.countrylist",[]);
        component.set("v.sObjectName",'Change_Request__c');
        component.set("v.fieldName",'New_Payment_Schedule__c');
        helper.getOppDetail(component);
    },
    showRequiredFields: function(component, event, helper){
        $A.util.removeClass(component.find("Type_of_Change"), "none"); 
    },
    handleTypeChange : function(component, event, helper) {        
        component.set("v.selectedType",event.getSource().get("v.value"));
    },
    handleTypeOfChange : function(component, event, helper) 
    {    
        component.set("v.newOrderId","");
        component.set("v.newInvoiceId","");
        component.set("v.newBillToContactId","");
        component.set("v.newAccountTaxNumber","");
        component.set("v.newProductId","");
        component.set("v.selectedTypeofChange",event.getSource().get("v.value"));
    },
    closeModal : function(component, event, helper) {
        component.set("v.isOpenModal",false);
        // event.preventDefault();
        // component.set("v.isOpenModal",flase);
        // alert('closed!');
        // $A.get("e.force:closeQuickAction").fire();
    },
    handleError:function(component, event, helper) {
        component.set("v.spinner",false);
    },
    handleSubmit: function(component, event, helper) {
        event.preventDefault();       // stop the form from submitting
        var fields = event.getParam('fields');

        fields.Change_Request_Status__c = 'Approval Required'; // Default value ;
        if(fields.Type_of_Change__c=='Payment Schedule')
        {
            var opp = component.get("v.oppObj");
            fields.Old_Payment_Schedule__c = (opp.Payment_Schedule__c==null || opp.Payment_Schedule__c=='')?opp.Event_Payment_ScheduleFor__c:opp.Payment_Schedule__c;
            fields.New_Payment_Schedule__c = component.find("paymentOptions").get("v.value");
        }
        if(fields.Type_of_Change__c=='Incorrect Account details with Tax impact Amendment')
        {
            fields.New_Order__c = component.get("v.newOrderId") ;
            fields.Old_Billing_Country__c = component.get("v.accountRecord.BillingCountryCode") ;
            fields.Old_Billing_Street__c = component.get("v.accountRecord.BillingStreet") ;
            fields.Old_Billing_City__c = component.get("v.accountRecord.BillingCity") ;
            fields.Old_Billing_State__c = component.get("v.accountRecord.BillingStateCode") ;
            fields.Old_Billing_Postal_Code__c = component.get("v.accountRecord.BillingPostalCode") ;
            fields.New_Billing_State__c = component.find("NewBillingState").get("v.value");
            fields.New_Billing_Country__c = component.find("NewBillingCountry").get("v.value");
        }

        if(fields.Type_of_Change__c=='Updated VAT number Amendment')
        {
            fields.Old_Account_Tax_Number__c = component.find("updatedVATOldAccountTaxNumber").get("v.value");
            if(!$A.util.isEmpty(component.get("v.newAccountTaxNumber")))
            {
                fields.New_Account_Tax_Number__c = component.get("v.newAccountTaxNumber");
            }
            if(!$A.util.isEmpty(component.get("v.newOrderId")))
            {
                fields.New_Order__c = component.get("v.newOrderId");
            }
        }

        if(fields.Type_of_Change__c=='Incorrect Product Tax amendment')
        {
            if(!$A.util.isEmpty(component.get("v.newProductId")))
            {
                fields.Product__c =  component.get("v.newProductId");
            }
            if(!$A.util.isEmpty(component.get("v.newOrderId")))
            {
                fields.New_Order__c = component.get("v.newOrderId");
            }
            if(!$A.util.isEmpty(component.get("v.productRecord.Event_Product_Type__c")))
            {
                fields.Old_Event_Product_Type__c = component.get("v.productRecord.Event_Product_Type__c") ;
            }
        }

        if(fields.Type_of_Change__c=='Update Bill to Contact')
        {
            if(!$A.util.isEmpty(component.get("v.newInvoiceId")))
            {
                fields.Invoice__c = component.get("v.newInvoiceId") ;
            }
            if(!$A.util.isEmpty(component.get("v.newBillToContactId")))
            {
                fields.New_Billing_Contact__c = component.get("v.newBillToContactId");
            }
            if(!$A.util.isEmpty(component.get("v.invoiceRecord.blng__BillToContact__c")))
            {
                fields.Old_Bill_To_Contact__c = component.get("v.invoiceRecord.blng__BillToContact__c");
            }
        }   
        if(fields.Type_of_Change__c=='Product Upgrade' || fields.Type_of_Change__c=='Cancellation' || fields.Type_of_Change__c=='Product Downgrade')
        {
            if(!$A.util.isEmpty(component.get("v.changeRequestObj.Contract__c")))
            {
                fields.Contract__c = component.get("v.changeRequestObj.Contract__c") ; 
                fields.Change_Request_Status__c = 'New';               
            }            
        }     
        console.log('fields : ' + JSON.stringify(fields));
        if(helper.validate(component,fields)){
            component.find('Change_Request_Form').submit(fields);
        }
    },
    handleSuccess: function(component, event,helper) {
        var payload = event.getParams().response;
        component.set("v.spinner",false);

        var navService = component.find("navService");
        // Uses the pageReference definition in the init handler
        var pageReference = {
            type: "standard__recordPage",
            attributes: {
                objectApiName: "Change_Request__c",
                recordId: payload.id,
                actionName: "view"
            }
        };
        var defaultUrl = "#";
        navService.generateUrl(pageReference)
        .then($A.getCallback(function(url) {
            defaultUrl= url ? url : defaultUrl;
            window.location = defaultUrl;
        }), $A.getCallback(function(error) {
            window.location = defaultUrl;
        }));
    },
    CountryChange: function(component, event,helper) { 
        var counValue = component.find("NewBillingCountry").get("v.value");
        if(counValue != null){
            var countryStateMap = component.get("v.countryStateMap");
            if(countryStateMap.hasOwnProperty(counValue)){
                var stateOptions = countryStateMap[counValue];
                var statelist = [];
                for(var i=0;i<stateOptions.length;i++){
                    var opt = stateOptions[i].split("__$__");
                    var obj = {
                        label:opt[0],
                        value:opt[1]
                    }
                    statelist.push(obj);
                }
                component.set("v.statelist",statelist);
            }
        }
    }
})