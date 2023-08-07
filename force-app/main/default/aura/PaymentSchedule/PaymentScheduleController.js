({
    doInit: function(component, event ,helper) {
        helper.getPaymentPicklistValues(component);
        helper.getOppRecordDetail(component);
        
    },
    Paymentjs : function(component, event ,helper){
        var paymentValue = component.get('v.PaymentValue');
        helper.customPaymentRenderFields(component);
    },
    
    PaymentSchedulejs : function(component, event ,helper) {
        helper.renderPaymentSchedulejs(component);
    },
    PaymentSchedule2js : function(component, event ,helper) {
        helper.renderPaymentSchedule2js(component);
    },
    CustomPaymentjs : function(component, event ,helper) {
        helper.customPaymentRenderFields(component);
    },
    
    TotalNoofPaymentjs : function(component, event ,helper) {
        helper.renderInputFields(component);
    },
    saveJS : function(component , event ,helper){
        component.get("v.recordId");
        helper.saveRecords(component , event ,helper);
    },
    cancelRec : function(component, event ,helper){
        helper.getOppRecordDetail(component);
    }
})