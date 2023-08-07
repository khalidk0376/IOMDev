({
    doInit : function(component, event, helper) {
        var record = component.get("v.recordId");
        var action = component.get('c.getAccRecord');
        action.setParams({
            recId : record
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                var returnData = response.getReturnValue();
                console.log('returnData==>'+returnData);
                if(returnData != null && returnData.hasOwnProperty('Address_Status__c')){
                    /*if(returnData.Address_Status__c == 'Valid'){
                        component.set("v.SAPBannerMsg",component.get("v.BannerAddressValid"));
                    }*/
                    if(returnData.Address_Status__c == 'Invalid'){
                        component.set("v.isSAPBanner",true);
                        component.set("v.SAPBannerMsg",component.get("v.BannerAddressNotValid"));
                    }
                    if(returnData.Address_Status__c == 'Error'){
                        component.set("v.isSAPBanner",true);
                        component.set("v.SAPBannerMsg",component.get("v.BannerAddressError"));
                    }
                }
                if(returnData != null && returnData.hasOwnProperty('Accounting_Credit_Hold__c') && returnData.Accounting_Credit_Hold__c == 'Hold' ){
                    component.set("v.isCreditBanner",true);
                    component.set("v.CreditBannerMsg",component.get("v.BannerCreditHold"));
                }
                if(returnData != null && returnData.hasOwnProperty('Accounting_Credit_Hold__c') && returnData.Accounting_Credit_Hold__c == 'Warning' ){
                    component.set("v.isCreditBanner",true);
                    component.set("v.CreditBannerMsg",component.get("v.BannerCreditWarning"));
                }
            }
        });
        $A.enqueueAction(action);
    }
})