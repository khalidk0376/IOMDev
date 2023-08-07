({
    customPaymentRenderFields:function(component){
        var CustomPaymentcheck = component.get("v.CustomPayment");   
        var paymentValue = component.get('v.PaymentValue'); 
        if(paymentValue == 'Custom' || CustomPaymentcheck == 'true'){
            component.set("v.OnCustomCheckCheckBox", false);
            component.set("v.PaymentScheduleCheckBox", false);
            component.set("v.DefaultPaymentSchedule25", false);
            component.set("v.CustomPaymentCheckBox", true);
            component.set("v.PaymentSchedule", false);
            component.set("v.PaymentSchedule2", false);
            var totaNoPayment=component.get("v.TotalNoofPayment");
            if(totaNoPayment){
                this.renderInputFields(component);    
            }
        } else {
            component.set("v.OnCustomCheckCheckBox", true);
            component.set("v.PaymentScheduleCheckBox", false);
            component.set("v.DefaultPaymentSchedule25", false);
            component.set("v.CustomPaymentCheckBox", false);
            component.set("v.PaymentSchedule", false);
            component.set("v.PaymentSchedule2", false);
            component.set("v.NoofPayment1", false);
            component.set("v.NoofPayment2", false);
            component.set("v.NoofPayment3", false);
            component.set("v.NoofPayment4", false);
            component.set("v.NoofPayment5", false);
            component.set("v.NoofPayment6", false);
            component.set("v.NoofPayment7", false);
            component.set("v.NoofPayment8", false);
            component.set("v.NoofPayment9", false);
            component.set("v.NoofPayment10", false);
            component.set("v.NoofPayment11", false);
            component.set("v.NoofPayment12", false); 
        }
    },
    getOppRecordDetail:function(component){
        var action = component.get("c.getallDataRecord");
        action.setParams({"recordIdget":component.get("v.recordId")});
        action.setCallback(this,function(res){
            if(res.getState()==="SUCCESS"){
                var obj = res.getReturnValue(); 
                component.set("v.TotalNoofPayment",obj.Total_No_of_payment__c);
                component.set("v.CustomPayment",obj.Custom_Payment__c);
                component.set('v.PaymentValue', obj.Payment_Schedule__c);
                if(obj.Custom_Payment__c){
                    this.customPaymentRenderFields(component); 
                    this.renderInputFields(component);
                } else {
                    this.customPaymentRenderFields(component); 
                }
                if(obj.AccountId!=null && obj.Account.One_Invoice_Per_Contract__c){
                    component.set("v.isOneInvPerContract","true");
                } else if(obj.Default_Edition__c!=null && obj.Default_Edition__r.One_Invoice_Per_Contract__c){
                    component.set("v.isOneInvPerContract","true");
                }
                component.set("v.CustomDueDate",obj.Start_Date__c);
                component.set("v.DueDate1",obj.Milestone_1_Delivery_Date__c)
                component.set("v.DueDate2",obj.Milestone_2_Delivery_Date__c);
                component.set("v.DueDate3",obj.Milestone_3_Delivery_Date__c);
                component.set("v.DueDate4",obj.Milestone_4_Delivery_Date__c); 
                component.set("v.DueDate5",obj.Milestone_5_Delivery_Date__c);
                component.set("v.DueDate6",obj.Milestone_6_Delivery_Date__c);
                component.set("v.DueDate7",obj.Milestone_7_Delivery_Date__c);
                component.set("v.DueDate8",obj.Milestone_8_Delivery_Date__c);
                component.set("v.DueDate9",obj.Milestone_9_Delivery_Date__c);
                component.set("v.DueDate10",obj.Milestone_10_Delivery_Date__c);
                component.set("v.DueDate11",obj.Milestone_11_Delivery_Date__c);
                component.set("v.DueDate12",obj.Milestone_12_Delivery_Date__c);
                component.set("v.AmountDue1",obj.Milestone_1_Amount__c);
                component.set("v.AmountDue2",obj.Milestone_2_Amount__c);
                component.set("v.AmountDue3",obj.Milestone_3_Amount__c);
                component.set("v.AmountDue4",obj.Milestone_4_Amount__c);
                component.set("v.AmountDue5",obj.Milestone_5_Amount__c);
                component.set("v.AmountDue6",obj.Milestone_6_Amount__c);
                component.set("v.AmountDue7",obj.Milestone_7_Amount__c);
                component.set("v.AmountDue8",obj.Milestone_8_Amount__c);
                component.set("v.AmountDue9",obj.Milestone_9_Amount__c);
                component.set("v.AmountDue10",obj.Milestone_10_Amount__c);
                component.set("v.AmountDue11",obj.Milestone_11_Amount__c);
                component.set("v.AmountDue12",obj.Milestone_12_Amount__c);
                component.set("v.CurrencyCode",obj.CurrencyIsoCode);
                component.set("v.TotalAmount",obj.Amount);
            } else{
                _LtngUtility.handleErrors(res.getError());
            }
        });
        $A.enqueueAction(action);
    },
    saveRecords : function(component, event, helper){
        var CusDueDate = component.get("v.CustomDueDate");
        var TotalNoofPayment = component.get("v.TotalNoofPayment");
        var paymentValue = component.get('v.PaymentValue'); 
        if((CusDueDate == null || TotalNoofPayment == null) && paymentValue == 'Custom'){
            _LtngUtility.toast('Error','error',' "Due Date" or "Total Number of payment" can not be vacant');
        } else{
            if(paymentValue == 'Custom'){
                component.set("v.CustomPayment", true);
            } else {
                component.set("v.CustomPayment", false);
            }
            var action = component.get("c.saveData");
            var fields = {'sobjectType':'Opportunity',
                           'Id' : component.get("v.recordId") ,   
                           'Custom_Payment__c' : component.get("v.CustomPayment") ,
                           'Payment_Schedule__c' : component.get("v.PaymentValue"),
                           'Total_No_of_payment__c' : component.get("v.TotalNoofPayment") ,
                           'Start_Date__c' : component.get("v.CustomDueDate") ,
                           'Milestone_1_Delivery_Date__c' : component.get("v.DueDate1") ,
                           'Milestone_2_Delivery_Date__c' : component.get("v.DueDate2") ,
                           'Milestone_3_Delivery_Date__c' : component.get("v.DueDate3") ,
                           'Milestone_4_Delivery_Date__c' : component.get("v.DueDate4") , 
                           'Milestone_5_Delivery_Date__c' : component.get("v.DueDate5") ,
                           'Milestone_6_Delivery_Date__c' : component.get("v.DueDate6") ,
                           'Milestone_7_Delivery_Date__c' : component.get("v.DueDate7") ,
                           'Milestone_8_Delivery_Date__c' : component.get("v.DueDate8") ,
                           'Milestone_9_Delivery_Date__c' : component.get("v.DueDate9") ,
                           'Milestone_10_Delivery_Date__c' : component.get("v.DueDate10") ,
                           'Milestone_11_Delivery_Date__c' : component.get("v.DueDate11") ,
                           'Milestone_12_Delivery_Date__c' : component.get("v.DueDate12") ,
                           'Milestone_1_Amount__c' : component.get("v.AmountDue1") ,
                           'Milestone_2_Amount__c' : component.get("v.AmountDue2") ,
                           'Milestone_3_Amount__c' : component.get("v.AmountDue3") ,
                           'Milestone_4_Amount__c' : component.get("v.AmountDue4") ,
                           'Milestone_5_Amount__c' : component.get("v.AmountDue5") ,
                           'Milestone_6_Amount__c' : component.get("v.AmountDue6") ,
                           'Milestone_7_Amount__c' : component.get("v.AmountDue7") ,
                           'Milestone_8_Amount__c' : component.get("v.AmountDue8") ,
                           'Milestone_9_Amount__c' : component.get("v.AmountDue9") ,
                           'Milestone_10_Amount__c' : component.get("v.AmountDue10") ,
                           'Milestone_11_Amount__c' : component.get("v.AmountDue11") ,
                           'Milestone_12_Amount__c' : component.get("v.AmountDue12") ,
                          };
            action.setParams({
                'fields' : fields
            });
            action.setCallback(this,function(data){
                var state = data.getState();
                var response = JSON.stringify(data.getReturnValue());
                console.log("response123" +state);
                if(state==="SUCCESS"){
                    _LtngUtility.toast('Success', 'success', 'Opportunity has been Updated Successfully');
                    this.getOppRecordDetail(component);
                }
                else if(state=="ERROR"){
                    _LtngUtility.handleErrors(data.getError());
                }
            });
            $A.enqueueAction(action);
        }
    },
    renderInputFields:function(component){
        var varTotalNoofPayment = component.get("v.TotalNoofPayment");
        if(varTotalNoofPayment == 1){
            component.set("v.NoofPayment1", true);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
            component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
            component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false);
        }else if(varTotalNoofPayment == 2){
            component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", true);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
            component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
            component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false);
        }
            else if(varTotalNoofPayment == 3){
                component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", true);component.set("v.NoofPayment4", false);
                component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
                component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false);
            }
                else if(varTotalNoofPayment == 4){
                    component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", true);
                    component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
                    component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false);
                }
                    else if(varTotalNoofPayment == 5){
                        component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
                        component.set("v.NoofPayment5", true);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
                        component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false);
                    }
                        else if(varTotalNoofPayment == 6){
                            component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
                            component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", true);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
                            component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false);
                        }
                            else if(varTotalNoofPayment == 7){
                                component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
                                component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", true);component.set("v.NoofPayment8", false);
                                component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false);
                            }
                                else if(varTotalNoofPayment == 8){
                                    component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
                                    component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", true);
                                    component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false);
                                }else if(varTotalNoofPayment == 9){
                                    component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
                                    component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
                                    component.set("v.NoofPayment9", true);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false);
                                }
                                    else if(varTotalNoofPayment == 10){
                                        component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
                                        component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
                                        component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", true);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false);
                                    }else if(varTotalNoofPayment == 11){
                                        component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
                                        component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
                                        component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", true);component.set("v.NoofPayment12", false);
                                    }else if(varTotalNoofPayment == 12){
                                        component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
                                        component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
                                        component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", true);
                                    }else if(varTotalNoofPayment == 0){
                                        component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
                                        component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
                                        component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false); 
                                    }else if(varTotalNoofPayment > 12){
                                        component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
                                        component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
                                        component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false); 

                                        _LtngUtility.toast('Error','error','Total no of payment should be less than or equal to 12.');
                                    }
    },
    
    renderPaymentSchedulejs : function(component){
        var PaymentSchedulecheck = component.get("v.PaymentSchedule");
        if(PaymentSchedulecheck == true){
            component.set("v.OnCustomCheckCheckBox", true);
            component.set("v.PaymentScheduleCheckBox", true);
            component.set("v.DefaultPaymentSchedule25", false);
            component.set("v.PaymentSchedule2", false);
            component.set("v.CustomPayment", false);
            component.set("v.CustomPaymentCheckBox", false);
            component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
            component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
            component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false); 
        } else {
            component.set("v.OnCustomCheckCheckBox", true);
            component.set("v.PaymentScheduleCheckBox", false);
            component.set("v.DefaultPaymentSchedule25", false);
            component.set("v.PaymentSchedule2", false);
            component.set("v.CustomPayment", false);
            component.set("v.CustomPaymentCheckBox", false);
            component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
            component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
            component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false); 
        }  
    },
    renderPaymentSchedule2js :function(component){
        var PaymentSchedule2check = component.get("v.PaymentSchedule2");
        if(PaymentSchedule2check == true){
            component.set("v.OnCustomCheckCheckBox", true);
            component.set("v.PaymentSchedule2CheckBox", true);
            component.set("v.PaymentScheduleCheckBox", false);
            component.set("v.DefaultPaymentSchedule25", false);
            component.set("v.PaymentSchedule", false);
            component.set("v.CustomPayment", false);
            component.set("v.CustomPaymentCheckBox", false);
            component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
            component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
            component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false); 
        } else {
            component.set("v.OnCustomCheckCheckBox", true);
            component.set("v.PaymentSchedule2CheckBox", false);
            component.set("v.PaymentScheduleCheckBox", false);
            component.set("v.DefaultPaymentSchedule25", false);
            component.set("v.PaymentSchedule", false);
            component.set("v.CustomPayment", false);
            component.set("v.CustomPaymentCheckBox", false);
            component.set("v.NoofPayment1", false);component.set("v.NoofPayment2", false);component.set("v.NoofPayment3", false);component.set("v.NoofPayment4", false);
            component.set("v.NoofPayment5", false);component.set("v.NoofPayment6", false);component.set("v.NoofPayment7", false);component.set("v.NoofPayment8", false);
            component.set("v.NoofPayment9", false);component.set("v.NoofPayment10", false);component.set("v.NoofPayment11", false);component.set("v.NoofPayment12", false); 
        }
    },

    getPaymentPicklistValues :function(component){ 
        var action = component.get("c.getPaymentPicklistValues");
        action.setParams({"oppId":component.get("v.recordId")});
        action.setCallback(this,function(res){
            if(res.getState()==="SUCCESS"){
                component.set('v.PaymentValues',res.getReturnValue());
            }else {
                console.log('error');
            }
    });
        $A.enqueueAction(action);
    }
    
    /*
        getPaymentPicklistValues :function(component){ 
            var action = component.get("c.getPaymentPicklistValues");
            action.setCallback(this,function(res){
                if(res.getState()==="SUCCESS"){
                    component.set('v.PaymentValues',res.getReturnValue());
                }else {
                    console.log('error');
                }
        });
            $A.enqueueAction(action);
        }
    */
})