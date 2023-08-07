import { api,LightningElement,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {updateRecord} from 'lightning/uiRecordApi';
import hasReadyOnlyPermission from '@salesforce/customPermission/IOM_Read_Only_User';

import fetchOpportunityRecord from '@salesforce/apex/IOM_CustomComponentsCtrl.getOpportunityRecord';
import {publish, MessageContext} from 'lightning/messageService'
import iomLWCMS from "@salesforce/messageChannel/IOM_LWCMessageService__c";

export default class Iom_OppCustomPaymentSchedule extends LightningElement {

    @api recordId;
    @api editionField1API; // Edition Start Date
    @api editionField2API; // invoice To Be Issued Before In Days
    @api isDynamic;

    opp; // Opportunity Record.
    invoiceToBeIssuedBeforeInDays = 30;
    eventEditionStartDate;
    dueDate;
    showCustomBillingScreen = false;
    showResetPaymentsConfirmationModal = false;
    errorMsg = '';
    showSpinner = false;
    oppQueryFields = 'Id,Name,IOM_Opportunity_No__c,IOM_Sync_Status__c,IOM_Custom_Billing_Info__c,Amount';
    isReadOnly=false;
    customBillingList = [];
    oppTotal = 0;
    totalNoOfPayment = 0;

    connectedCallback(){
        this.oppQueryFields = this.oppQueryFields+(this.editionField1API?','+this.editionField1API:'')+(this.editionField2API?','+this.editionField2API:''); 
        //this.eventEditionStartDate = new Date(new Date().setMonth(new Date().getMonth()+5));
        this.dueDate = new Date();  
        this.isReadOnly= hasReadyOnlyPermission; //[GECI-940]
        this.getOppDetails();
    }


    handleDataChange(event){
        let fieldName =event.target.name
        let value = event.target.value;
        let index = event.target.dataset.index;
        // console.log('fieldName - '+fieldName+' | value '+value+' | index - '+index);
        if(fieldName === 'totalNoOfPayment')
        {
            this.totalNoOfPayment = value;
            this.setCustomBillingList();
        }else if(fieldName === 'paymentPercent')
        {            
            this.validateAndResetPercent(parseInt(index),value);
        }else if(fieldName === 'paymentDate')
        {
            this.validateAndResetDate(parseInt(index),value);
        }
        // console.log('customBillingList - '+JSON.stringify(this.customBillingList));
    }

    handleSave(){
        this.showSpinner = true;
        this.setJSONAndSave();
    }

    closeModal(){
        this.showResetPaymentsConfirmationModal = false;
    }    

    // get
    get showCustomBillingInput(){
        return this.customBillingList.length >0 ? true:false;
    }

   /* get formatedDueDate(){
        return new Date().toISOString();
    }*/

    // --- 
    setCustomBillingList()
    {
        let tempCustomBillingList = [];
        if(this.validateNoOfpaymentChange() == true && this.totalNoOfPayment > 0)
        {            
            let equalPercent = this.totalNoOfPayment && this.totalNoOfPayment>0? parseFloat(100/this.totalNoOfPayment).toFixed(2):100;        
            for(let i=0;i<this.totalNoOfPayment;i++)
            {
                let paymentObj = { 
                    index :i,isLast:false,datelabel:"Date "+(i+1),percentageLabel:"Percentage "+(i+1),
                    amountlabel:"Amount "+(i+1),date:new Date()
                }            
                paymentObj.date.setDate(this.dueDate.getDate() + (i*this.invoiceToBeIssuedBeforeInDays));
                paymentObj.date = paymentObj.date.toISOString().split('T')[0];
                paymentObj.percent = equalPercent;
                // console.log('C Index'+(i+1)+' & '+this.totalNoOfPayment);
                if((i+1) == this.totalNoOfPayment) // Last Index
                {
                    // console.log('Last % '+equalPercent);
                    // console.log('Last '+(equalPercent*i));
                    paymentObj.isLast = true;
                    paymentObj.percent = parseFloat(100 - (equalPercent*i)).toFixed(2);
                }
                paymentObj.formatedPercent = paymentObj.percent/100;
                tempCustomBillingList.push(paymentObj);
            }           
        }
        // console.log('tempCustomBillingList - '+JSON.stringify(tempCustomBillingList));
        this.customBillingList = tempCustomBillingList;
    }

    validateNoOfpaymentChange(){
        let allValid = true;
        if(this.totalNoOfPayment && this.totalNoOfPayment >12)
        {   
            allValid = false;
            this.showNotification('Error','Number of payments cannot be greater than 12','Error');
            // Add Error -
        }
        else if(this.totalNoOfPayment && this.totalNoOfPayment < 0)
        {   
            allValid = false;
            this.showNotification('Error','Number of payments cannot be less than 0','Error');
            // Add Error -
        }
        /*else
        {
            let totalAvilableDays =  this.invoiceToBeIssuedBeforeInDays*(this.totalNoOfPayment-1);
            let lastPaymentDate = new Date().setDate(this.dueDate.getDate() +totalAvilableDays);
            if(lastPaymentDate >= this.eventEditionStartDate ){
                allValid = false; 
                this.showNotification('Error','Please, select less number of payments, as the final payment date becomes greater than the edition start date','Error');
                // Add Error -
            }
        }*/
        return allValid;
    }

    validateAndResetPercent(index,value){
        if((value )>100)
        {   
            // Show Error ---
            // alert('Error....');
            this.showNotification('Error','Total percent cannot exceed 100%','Error');
        }
        else{   
            // this.customBillingList[index].percent = value*100;
            // this.customBillingList[index].formatedPercent = value;
            this.customBillingList[index].percent = value;

            let tempCustomBillingList = JSON.parse(JSON.stringify(this.customBillingList));
            let PrevoiusPercents = 0;
            let remainingPercent = 100;
            let remainingIndexs = this.totalNoOfPayment - parseInt(index+1);
            // console.log(this.totalNoOfPayment+' n : '+index+' remainingIndexs '+remainingIndexs);
            for(let i=0;i<this.totalNoOfPayment;i++)
            {
                if(i<=index)
                {
                    PrevoiusPercents = parseFloat(PrevoiusPercents) + parseFloat(tempCustomBillingList[i].percent);
                    // console.log(i+' PrevoiusPercents '+PrevoiusPercents);
                }else{ // Future payments                    
                    tempCustomBillingList[i].percent = parseFloat(((100 - PrevoiusPercents)/remainingIndexs).toFixed(2)).toFixed(2);
                    // console.log(i+' New Percents '+tempCustomBillingList[i].percent);
                    if((i+1) == this.totalNoOfPayment) // Last Index
                    {
                        tempCustomBillingList[i].percent = parseFloat(remainingPercent.toFixed(2)).toFixed(2);
                    }
                }
                tempCustomBillingList[i].formatedPercent = tempCustomBillingList[i].percent/100;
                remainingPercent = remainingPercent - (tempCustomBillingList[i].percent);
            }
            // console.log('tempCustomBillingList 2 - '+JSON.stringify(tempCustomBillingList));
            this.customBillingList = tempCustomBillingList;
        }
        
    }

    validateAndResetDate(index,value){
        this.customBillingList[index].date = value;
        /*
        if(value<this.eventEditionStartDate)
        {
            this.customBillingList[index].date = value;
        }else
        {
            this.showNotification('Error','Selected date cannot be greater than Edition start date','Error');
            // Add Error - date to be less than Edition Start date
        }*/
    }

    setValuesOnLoad(billingInfo){
        // console.log('setValuesOnLoad');
        let tempCustomBillingList = [];
        let customBillingObj = JSON.parse(billingInfo);
        this.totalNoOfPayment = customBillingObj.length;
        customBillingObj.forEach((payment,i)=>{
            let paymentObj = { 
                index :i,isLast:false,datelabel:"Date "+(i+1),percentageLabel:"Percentage "+(i+1),
                amountlabel:"Amount "+(i+1),date:payment.Date,percent:payment.Percent,formatedPercent:payment.Percent/100
            }
            if((i+1) == this.totalNoOfPayment) // Last Index
            {
                // console.log('Last % '+equalPercent);
                // console.log('Last '+(equalPercent*i));
                paymentObj.isLast = true;                
            }
            tempCustomBillingList.push(paymentObj);
        });
        // console.log('Load tempCustomBillingList - '+JSON.stringify(tempCustomBillingList));
        this.customBillingList = tempCustomBillingList;
    }
    
    getValue(obj,nodeName)
    {
        // console.log('Get val '+nodeName+' in '+JSON.stringify(obj));
        let val;
        if(nodeName.includes('.')){
           val = this.getValue(obj[nodeName.split('.')[0]],nodeName.split('.').slice(1).join('.'));
        }else{
            val = obj[nodeName];
        }
        return val;
    }

    // Apex Calls 
    setJSONAndSave(){
        let isInvalidDate = false;
        let totalPercent =0;
        let payments = [];
        let oppTotal = this.opp.Amount?this.opp.Amount:0;
        this.customBillingList.forEach((payment)=>{
            // console.log('Check '+payment.index + ' - '+JSON.stringify(payment));
            payments.push({
                "Date":payment.date,
                "Percent":parseFloat(payment.percent).toFixed(2),
                "Amount":parseFloat(oppTotal*payment.formatedPercent).toFixed(2),
                "PaymentNumber":payment.index+1
            });
            totalPercent = (parseFloat(totalPercent) + parseFloat(payment.percent)).toFixed(2);
        });
        let paymentInfo = JSON.stringify(payments);
        console.log('paymentInfo - '+paymentInfo);
        if(this.totalNoOfPayment > 0){
            if(totalPercent == 100 && isInvalidDate == false){
                let updateOBJ={};
                updateOBJ['Id'] = this.recordId;
                updateOBJ['IOM_Custom_Billing_Info__c'] = paymentInfo;        
                this.updateOpportunity(updateOBJ);
            }
            /*
            else if(isInvalidDate == true){
                this.showSpinner = false;
                this.showNotification('Error','Date can not be greater than edition start date','Error');
            }*/
            else
            {
                this.showSpinner = false;
                this.showNotification('Error','Please update all percent fields to get 100% as aggregate','Error');
            }  
        }
        else{
            this.showSpinner = false;
            this.showResetPaymentsConfirmationModal = true;
            // let updateOBJ={};
            // updateOBJ['Id'] = this.recordId;
            // updateOBJ['IOM_Custom_Billing_Info__c'] = null;        
            // this.updateOpportunity(updateOBJ);
        }      
    }

    resetPayments()
    {
        let updateOBJ={};
        updateOBJ['Id'] = this.recordId;
        updateOBJ['IOM_Custom_Billing_Info__c'] = null;  
        this.showSpinner = true;      
        this.updateOpportunity(updateOBJ);
        this.showResetPaymentsConfirmationModal = false;
    }

    updateOpportunity(updateOBJ) {
        updateRecord({fields:updateOBJ})
            .then(() => {                
                this.showNotification('Success','Custom Billing updated','Success');
                this.showSpinner = false;
                this.publishMC("opportunity custotom billing updated.")
            })
            .catch(error => {
                console.log(error);
                this.showNotification('Error','Error updating record '+error.body.message,'Error');
                this.showSpinner = false;              
            });
    }


    // Get Global Constant values
    getOppDetails()
    {      
        fetchOpportunityRecord({fields:this.oppQueryFields,recordId:this.recordId})
        .then(data=>{
            // console.log('data - '+JSON.stringify(data));
            this.opp = data;
            if(data.IOM_Custom_Billing_Info__c){                
                this.setValuesOnLoad(data.IOM_Custom_Billing_Info__c);
            }
             //GECI-926
            if(data.IOM_Sync_Status__c != 'undefined' && data.IOM_Opportunity_No__c != 'undefined'){
                if(data.IOM_Sync_Status__c=='Complete' && data.IOM_Opportunity_No__c!=''){
                    this.isReadOnly=true;
                    this.showNotification('Info','IOM Sync is completed and Record is not editable!','Record is Read Only!');
                   this.showSpinner = false;
               }
           }
            if(this.isDynamic === true)
            {
                this.eventEditionStartDate = this.getValue(data,this.editionField1API);
                this.invoiceToBeIssuedBeforeInDays = this.getValue(data,this.editionField2API);                
            }else{
                this.eventEditionStartDate = this.editionField1API;
                this.invoiceToBeIssuedBeforeInDays = this.editionField2API;                
            }

            // console.log(' OP '+this.eventEditionStartDate+' & '+this.invoiceToBeIssuedBeforeInDays);
            if(this.eventEditionStartDate && this.invoiceToBeIssuedBeforeInDays)   
            {
                this.showCustomBillingScreen = true;
            }else{
                // Error - Missing Dates & Payment Term
                this.errorMsg = 'Edition Start date or Invoice to be issued before days/payment term is blank';
            }
        })
        .catch(error=>{            
            console.log('error in getOppDetails '+error);
        })        
    }

    //#region ******** Notification/Toast ********/
    showNotification(title,message,variant)
    {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant?variant:'success'
        });
        this.dispatchEvent(evt);        
    }
    //#endregion

    @wire(MessageContext)
    messageContext;

    publishMC(messageForChannel) {
        const message = {
            iomLWCMessage: messageForChannel,
            sourceLWC: "iom_OppCustomPaymentSchedule"
        };
        publish(this.messageContext, iomLWCMS, message);
    }

    // [{"Date":"","Percent":"50","Amount":0,"PaymentNumber":1},{"Date":"","Percent":"50","Amount":0,"PaymentNumber":2}]

}