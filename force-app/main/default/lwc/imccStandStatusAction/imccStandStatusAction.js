import { api, LightningElement, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
//1. import the methods getRecord and getFieldValue
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

//2. Import reference to the object and the fields
import Status_Field from "@salesforce/schema/Stand_Detail__c.Stand_Detail_Status__c";
import Rejected_Steps from "@salesforce/schema/Stand_Detail__c.Rejected_Steps__c";
import Rejection_Reason from "@salesforce/schema/Stand_Detail__c.Rejection_Reason__c";
import { showToast } from 'c/imcc_lwcUtility';
const fields = [Status_Field,Rejected_Steps,Rejection_Reason];
export default class ImccStandStatusAction extends LightningElement {
    @api recordId;
    @track status;
    @track approvalDate;
    @track spinner;
    @track step;
    @track rejectionReason;

    @wire(getRecord, {recordId: "$recordId",fields})
    standObj;

    handleSuccess(event){
        this.spinner = false;
        this.closeModal();
        showToast(this,'Status was updated','success','Success');
        this.refreshPage();
    };

    handleSubmit(){        
        if(!this.status){
            showToast(this,'Please fill all required fields','error','Warning');
        }
        else if(this.status===this.previousStatus){
            showToast(this,'Nothing will be change','error','Warning');
        }
        else if(this.status==='Stand Design Rejected/Incomplete' && !this.step){
            showToast(this,'Rejection step must be select','error','Warning');
        }
        else if(this.status==='Stand Design Rejected/Incomplete' && !this.rejectionReason){
            showToast(this,'Rejection reason must not empty','error','Warning');
        }
        else{
            this.spinner = true;
            this.template.querySelector('lightning-record-edit-form').submit();
        }        
    };    

    handleStatusChange(event){
        this.status = event.target.value;
        this.step = getFieldValue(this.standObj.data, Rejected_Steps);
        this.rejectionReason = getFieldValue(this.standObj.data, Rejection_Reason);
        
        if(this.status==='Tentative Approval'){
            const dt = new Intl.DateTimeFormat('en', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit'
            });
            const [{value: mo}, , {value: da}, , {value: ye}] = dt.formatToParts(new Date());
            this.approvalDate = `${ye}-${mo}-${da}`;
        }
        else{
            this.approvalDate = undefined;
        }
    };    

    handleStepChange(event){        
        this.step = event.target.value;
    };
    
    handleRejectionReasonChange(event){
        this.rejectionReason = event.target.value;
    };

    closeModal(){
        this.dispatchEvent(new CloseActionScreenEvent());
    };

    refreshPage(){
        eval("$A.get('e.force:refreshView').fire();");
    };

    get isStatusChanged(){
        return this.status && this.status!=this.previousStatus;
    };

    get previousStatus(){
        return getFieldValue(this.standObj.data, Status_Field);
    };

    get isRejectedStepShow(){
        return this.status && this.status==='Stand Design Rejected/Incomplete';
    }
}