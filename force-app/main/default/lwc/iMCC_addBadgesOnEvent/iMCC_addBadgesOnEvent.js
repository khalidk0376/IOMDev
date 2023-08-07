import { LightningElement,api,wire,track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

//Start - Importing of Apex classes required in this component
import getEditionData from '@salesforce/apex/IMCC_AdditionBAdgesOnEvent.getEditionData';
//End - Importing of Apex Class

export default class IMCC_addBadgesOnEvent extends LightningElement {
    @api recordId;
    disableAddNow = true;
    numberFieldValue;

    @api invoke() {
       this.addNow();
    }

    handleNumberChange(event){
        this.numberFieldValue = event.target.value;
        this.disableAddNow = false;
    }

    addNow(){
        getEditionData({editionId: this.recordId, additionBadges: this.numberFieldValue})
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
            message: 'Purchase Data related to this Edition is Updated',
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