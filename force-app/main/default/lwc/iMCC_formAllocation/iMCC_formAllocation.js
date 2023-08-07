import { LightningElement,track,wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import getFormSubmissions from '@salesforce/apex/IMCC_FormAllocationCtrl.getFormSubmissions';
import { handleUIErrors } from 'c/imcc_lwcUtility';

export default class IMCC_formAllocation extends LightningElement {

    tableData;
    recordId;
    className='iMCC_formAllocation';
    comp_type='LWC';
    @track methodName;
    
    @track columns=[
        {label: 'Submission Number', fieldName:'Name', type: 'text' },
        {label: 'Status', fieldName:'Status', type: 'text' },
        {label: 'Approval Status', fieldName:'ApprovalStatus', type: 'text' },
        {label: 'Name of the User', fieldName:'User', type: 'text' }
    ];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    @wire (getFormSubmissions, {formAllocId: '$recordId'}) 
    fetchFormSubmissions({data,error}){
       if(data){
           console.log(data);
           let formSubmissions=[];
            data.forEach((row) => {            
                let form = {};
                form.Id=row.Id;
                form.Name = row.Name;
                form.Status = row.Status__c;
                form.User = row.User__r.Name;
                form.ApprovalStatus = row.Approval_Status__c;
                formSubmissions.push(form);     
        });
        this.tableData = formSubmissions;
       }
       if(error){
            this.methodName='getFormSubmissions';
           console.error(error);
           handleUIErrors(this,error);
       }
   }
}