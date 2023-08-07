import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import READY_FOR_ORDERING_FIELD from '@salesforce/schema/Opportunity.IOM_Ready_For_Ordering__c';
import REJECTION_NOTES_FIELD from '@salesforce/schema/Opportunity.IOM_Rejection_Notes__c';
import REJECTION_REASON_FIELD from '@salesforce/schema/Opportunity.IOM_Rejection_Reason__c';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';


export default class QuickActionComponent extends LightningElement {

    @api recordId;

    updateField() {

        console.log( "Inside Invoke Method" );
        console.log( "Record Id is " + this.recordId );

        const fields = {};
        fields[ ID_FIELD.fieldApiName ] = this.recordId;
        fields[ READY_FOR_ORDERING_FIELD.fieldApiName] = 'Yes';
        fields[ REJECTION_NOTES_FIELD.fieldApiName] = '';
        fields[ REJECTION_REASON_FIELD.fieldApiName] = null;

        const recordInput = {fields};

        updateRecord( recordInput )
        .then( () => {
            this.dispatchEvent(
                new ShowToastEvent( {
                    title: 'Success',
                    message: 'Opportunity updated',
                    variant: 'success'
                } )
                
            );
            this.closeModal();
        }).catch( error => {
            this.dispatchEvent(
                new ShowToastEvent( {
                    title: 'Error updating or reloading record',
                    message: error.body.message,
                    variant: 'error'
                } )
            );
        });

    }

    closeModal() {

        this.dispatchEvent(new CloseActionScreenEvent());
        
        }

}