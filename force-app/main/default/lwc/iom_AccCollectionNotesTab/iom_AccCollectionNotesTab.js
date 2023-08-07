/**
* Project      	:   Order & Billing Plateform [IOM-519]
* Created By	: 	Ansh (Girikon)
* Created Date	: 	7 Mar 2022
* ***************************************************************************
* @description : to Show Collection Notes Data from IOM to CRM Orgs
*/
import { api,LightningElement,track,wire} from 'lwc';
// import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord} from 'lightning/uiRecordApi';
// import OPPORTUNITY_OBJECT from '@salesforce/schema/Account';
import 	IOMAccountNumber from '@salesforce/schema/Account.IOM_Account_No__c';
import getAllowIOMCallout from '@salesforce/apex/IOM_ConnectionCallbackCtrl.isReadyForIOMCallout';

export default class Iom_AccCollectionNotesTab extends LightningElement 
{
    @api recordId;

    iomCallBackURL;
    showSpinner;
    iomAccountNumber;
    error;
    errrorMsg;
    isAllowCallout;

    @wire(getRecord, { recordId: '$recordId', fields: [IOMAccountNumber] })
    accountData({ error, data }) {
        if (data) {
            this.iomAccountNumber = data.fields.IOM_Account_No__c.value;
            
            this.error = undefined;
            this.isShow = true;
            if(this.iomAccountNumber)
            {   
                this.iomCallBackURL = '/apex/IOMConnectionCallback?compCode=CND02&iomrecordNo='+this.iomAccountNumber;
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
                this.errrorMsg = 'Account is yet to be synced with IOM';
            }
            
        } else if (error) {            
            this.error = error;
        }
    };


}