import { LightningElement,api,wire} from 'lwc';
import { getRecord} from 'lightning/uiRecordApi';

import IOM_REJECTION_REASON from '@salesforce/schema/Opportunity.IOM_Rejection_Reason__c';

export default class Iom_opportunityRejectCard extends LightningElement {
    @api recordId;
    
    rejectionReason;
    
   @wire(getRecord, { recordId: '$recordId', fields: [IOM_REJECTION_REASON] })
   accountData({ error, data }) {
       if (data) {
           console.log("Opp data ==",JSON.stringify(data));            
           this.rejectionReason            = data.fields.IOM_Rejection_Reason__c.value;                 
       } else if (error) {            
           this.error = error;
       }
   };

   get showcard()
   {
       return (this.rejectionReason && this.rejectionReason != null)?true:false;
   }
}