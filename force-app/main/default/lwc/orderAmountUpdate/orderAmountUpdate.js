import { LightningElement, api, wire} from 'lwc';
import { getRecord, updateRecord} from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import IDQLI_FIELD from '@salesforce/schema/SBQQ__QuoteLine__c.Id';
import QLIUnitPrice_FIELD from '@salesforce/schema/SBQQ__QuoteLine__c.SBQQ__ListPrice__c';
import QLIStartDate_FIELD from '@salesforce/schema/SBQQ__QuoteLine__c.SBQQ__StartDate__c';
import QLIEndDate_FIELD from '@salesforce/schema/SBQQ__QuoteLine__c.SBQQ__EndDate__c';
import TargetPrice_FIELD from '@salesforce/schema/SBQQ__QuoteLine__c.Target_Price__c';
import ID_FIELD from '@salesforce/schema/OrderItem.Id';
import ORDERID_FIELD from '@salesforce/schema/OrderItem.OrderId';
import UnitPrice_FIELD from '@salesforce/schema/OrderItem.UnitPrice';
import ServiceDate_FIELD from '@salesforce/schema/OrderItem.ServiceDate';
import EndDate_FIELD from '@salesforce/schema/OrderItem.EndDate';
import NextBillingDate_FIELD from '@salesforce/schema/OrderItem.blng__NextBillingDate__c';
import QuoteLine_FIELD from '@salesforce/schema/OrderItem.SBQQ__QuoteLine__c';
import createAPISyncTransForUpdateInCRM from '@salesforce/apex/MuleSoftCRMCalloutUtils.createAPISyncTransForUpdateInCRM';

const OIFIELDS = [UnitPrice_FIELD,ServiceDate_FIELD,EndDate_FIELD,NextBillingDate_FIELD,QuoteLine_FIELD,ORDERID_FIELD];

export default class OrderAmountUpdate extends LightningElement {
    @api recordId;
    orderProduct;
    UnitPrice;
    QuoteLine;
    orderId;
    StartDate;
    EndDate;
    spinner = false;
    isButtonClick = false;

    @wire(getRecord, { recordId: '$recordId', fields: OIFIELDS })
    wiredRecord({ error, data }) {
        console.log('wiredRecord===',this.isButtonClick);
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading Data',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            if(!this.isButtonClick){
                this.orderProduct = data;
                this.UnitPrice = this.orderProduct.fields.UnitPrice.value;
                this.QuoteLine = this.orderProduct.fields.SBQQ__QuoteLine__c.value;
                this.orderId = this.orderProduct.fields.OrderId.value;
                console.log('this.QuoteLine'+this.QuoteLine);
                this.StartDate = this.orderProduct.fields.ServiceDate.value;
                this.EndDate = this.orderProduct.fields.EndDate.value;
            }
        }
    }

    handleUnitPriceChange(event){
        this.UnitPrice = event.target.value;
    }

    handleStartDateChange(event){
        this.StartDate = event.target.value;
    }

    handleEndDateChange(event){
        this.EndDate = event.target.value;
    }

    updatedata(){
        this.isButtonClick = true;
        this.spinner = true;
        console.log('updatedata');
        console.log('updatedata===',this.isButtonClick);
        let fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[QuoteLine_FIELD.fieldApiName] = null;

        let recordInput = { fields };
        console.log('updatedata',fields);
        console.log('updatedata',recordInput);

        updateRecord(recordInput)
        .then(() => {
            console.log('updatedata2');
            fields = {};
            fields[ID_FIELD.fieldApiName] = this.recordId;
            fields[UnitPrice_FIELD.fieldApiName] = this.UnitPrice;
            fields[ServiceDate_FIELD.fieldApiName] = this.StartDate;
            fields[EndDate_FIELD.fieldApiName] = this.EndDate;

            recordInput = { fields };
            console.log('updatedata2',fields);
            console.log('updatedata2',recordInput);
            updateRecord(recordInput)
            .then(() => {
                console.log('updatedata3');
                fields = {};
                fields[ID_FIELD.fieldApiName] = this.recordId;
                fields[QuoteLine_FIELD.fieldApiName] = this.QuoteLine;

                recordInput = { fields };
                console.log('updatedata3',fields);
                console.log('updatedata3',recordInput);
                updateRecord(recordInput)
                .then(() => {
                    console.log('updatedata4');
                    console.log(this.recordId);
                    fields = {};
                    //fields[ID_FIELD.fieldApiName] = this.recordId;
                    fields[IDQLI_FIELD.fieldApiName] = this.QuoteLine;
                    fields[QLIUnitPrice_FIELD.fieldApiName] = this.UnitPrice;
                    fields[TargetPrice_FIELD.fieldApiName] = this.UnitPrice;
                    fields[QLIStartDate_FIELD.fieldApiName] = this.StartDate;
                    fields[QLIEndDate_FIELD.fieldApiName] = this.EndDate;

                    recordInput = { fields };
                    console.log('updatedata4',fields);
                    console.log('updatedata4',recordInput);
                    updateRecord(recordInput)
                    .then(() => {
                        console.log('updatedata5');
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Record updated!',
                                variant: 'success'
                            })
                        );

                            createAPISyncTransForUpdateInCRM({orderId: this.orderId}).then(result=>{
                                console.log(result);
                            }).catch(error=>{
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error updating quote line',
                                        message: error,
                                        variant: 'error'
                                    })
                                );
                            })
                        
                        this.spinner = false;
                    })
                    .catch(error4 => {
                        console.log(error4);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error updating quote line',
                                message: error4,
                                variant: 'error'
                            })
                        );
                        this.spinner = false;
                    });
                })
                .catch(error3 => {
                    console.log(error3);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error adding quote line id',
                            message: error3,
                            variant: 'error'
                        })
                    );
                    this.spinner = false;
                });
            })
            .catch(error2 => {
                console.log(error2);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating unit price',
                        message: error2,
                        variant: 'error'
                    })
                );
                this.spinner = false;
            });
        })
        .catch(error1 => {
            console.log(error1);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error removing quote id',
                    message: error1,
                    variant: 'error'
                })
            );
            this.spinner = false;
        });
    }
}