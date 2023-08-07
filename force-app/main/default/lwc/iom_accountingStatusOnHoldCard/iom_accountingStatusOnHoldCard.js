import { LightningElement,api,wire} from 'lwc';
import { getRecord, updateRecord} from 'lightning/uiRecordApi';

import ACCOUNTING_CREDIT_STATUS from '@salesforce/schema/Account.IOM_Accounting_Credit_Hold__c';

export default class Iom_accountingStatusOnHoldCard extends LightningElement {
    @api recordId;
    
    creditStatus;
    
   @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNTING_CREDIT_STATUS] })
   accountData({ error, data }) {
       if (data) {
           console.log("Acc data ==",JSON.stringify(data));            
           this.creditStatus            = data.fields.IOM_Accounting_Credit_Hold__c.value;                 
       } else if (error) {            
           this.error = error;
       }
   };

   get showcard()
   {
       return (this.creditStatus == 'Hold' )?true:false;
   }
}