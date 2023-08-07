import { LightningElement, track, api, wire } from 'lwc';
import { handleErrors,showToast } from 'c/imcc_lwcUtility';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import sendWelcomeEmailCEM from '@salesforce/apex/IMCC_EditionWelcomeEmail.sendWelcomeEmail';
import sendEmailConfirmMsg from '@salesforce/label/c.IMCC_Confirm_Msg_Send_Welcome_Email';
import { getRecord } from 'lightning/uiRecordApi';
import CC_Status_FIELD from '@salesforce/schema/Contact_Edition_Mapping__c.CC_Status__c';

export default class Imcc_SendWelcomeEmail extends LightningElement {
    @api recordId;
    label = {
        sendEmailConfirmMsg
    };

    @wire(getRecord, { recordId: '$recordId', fields: [CC_Status_FIELD] })
    wiredCEM({ error, data }) {
        if (data) {
            let ccstatus = data.fields.CC_Status__c.value;
            if(ccstatus != 'Active'){
                this.startToast2('Customer center status is not Active.');
                this.dispatchEvent(new CloseActionScreenEvent());
                this.dispatchEvent(new CustomEvent('close'));
            }
        }
    }

    sendWelcomeEmail() {
        console.log('CEMID'+this.recordId);
        let cem = {'sobjectType': 'Contact_Edition_Mapping__c', Id: this.recordId};
        let cemList = [];
        cemList.push(cem);
        sendWelcomeEmailCEM({
            cemList: cemList
        })
        .then(result => {
            let cem = result[0];
            if(cem.IsEmailSent__c){
                this.startToast();
            }
            else{
                this.startToast2(cem.Error_Message__c);
            }
            this.dispatchEvent(new CloseActionScreenEvent());
            this.dispatchEvent(new CustomEvent('close'));
        })
        .catch(error => {
            this.startToast2('An Error occured during sending Email '+error.body.message);
            this.dispatchEvent(new CloseActionScreenEvent());
        });
    }

    cancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new CustomEvent('close'));
    }

    startToast(){
        let event = new ShowToastEvent({
            title: 'Success',
            message: 'Email has been sent successfully!',
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
}