/**
* Project      	:   Order & Billing Plateform [IOM-519]
* Created By	: 	Ashish (Girikon)
* Created Date	: 	18 JAN 2022
* ***************************************************************************
* @description : to Show Collection Notes Data from IOM to CRM Orgs
*/
import { api,LightningElement,wire} from 'lwc';
// import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord} from 'lightning/uiRecordApi';
// import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import 	IOMOpportunityNumber from '@salesforce/schema/Opportunity.IOM_Opportunity_No__c';
import getAllowIOMCallout from '@salesforce/apex/IOM_ConnectionCallbackCtrl.isReadyForIOMCallout';

export default class Iom_OppCollectionNotesTab extends LightningElement 
{
    @api recordId;

    iomCallBackURL;
    showSpinner;
    iomOpportunityNumber;
    error;
    errrorMsg;
    isAllowCallout;

    @wire(getRecord, { recordId: '$recordId', fields: [IOMOpportunityNumber] })
    oppData({ error, data }) {
        if (data) {
            console.log("Opp data ==",JSON.stringify(data));            
            this.iomOpportunityNumber     = data.fields.IOM_Opportunity_No__c.value;
            
            this.error = undefined;
            this.isShow = true;
            if(this.iomOpportunityNumber)
            {   
                this.iomCallBackURL = '/apex/IOMConnectionCallback?compCode=CND01&iomrecordNo='+this.iomOpportunityNumber;
                getAllowIOMCallout()
                .then(data2 => {
                    this.isAllowCallout = data2;
                    this.errrorMsg = data2== true?'':'Failed to connect with IOM,Please contact your System Administer';
                })
                .catch(error2 => {
                    this.isAllowCallout = false;
                });
            }else{
                this.isAllowCallout = false;
                this.errrorMsg = 'Opportunity is yet to be synced with IOM';
            }
            
        } else if (error) {            
            this.error = error;
        }
    };


}