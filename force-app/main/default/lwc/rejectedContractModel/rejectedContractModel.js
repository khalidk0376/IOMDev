import { LightningElement, track, api } from 'lwc';
import getRecordDetail from '@salesforce/apex/CommonTableController.getRecordDetail';
import {handleErrors} from 'c/lWCUtility';

export default class RejectedContractModel extends LightningElement {
    @api isOpenActionModal;
    @api recordId;    
    @api objectName;
    @track oppName;
    @track agreementCond;
    

   
    @api
    getOppDetail(recordId){
        getRecordDetail({objectName:'Opportunity',allFields:'Name',recordId:recordId})
        .then(data=>{
            if(data.length>0){
                this.oppName = data[0].Name;
            }
            this.agreementCond = "Opportunity__c = '"+recordId+"'";
        })
        .catch(error=>{
            handleErrors(this,error);
        });
    }

    /*
    * @description [This method is used to close the model]
    */
    closeModal() {
        this.isOpenActionModal = false;
    }
}