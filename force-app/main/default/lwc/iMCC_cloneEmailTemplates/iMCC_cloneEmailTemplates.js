import { LightningElement, wire, track, api } from 'lwc';
import cloneEmailTemplates from '@salesforce/apex/IMCC_EditionPopupHandler.cloneGlobalTemplates';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class IMCC_cloneEmailTemplates extends LightningElement {
    @api recordId;
    
    CloneTemplates() {
        console.log('eeId'+this.recordId);
            cloneEmailTemplates({
                recordId: this.recordId
            })
            .then(result => {
                this.startToast();
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.startToast2('An Error occured during adding badges'+error.body.message);
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    startToast(){
        let event = new ShowToastEvent({
            title: 'Success',
            message: 'Email Templates have been cloned successfully!',
            variant: 'success'
        });
        this.dispatchEvent(event);
    }

    startToast2(msg){
        let event = new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error'
        });
        this.dispatchEvent(event);
    }

    cancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}