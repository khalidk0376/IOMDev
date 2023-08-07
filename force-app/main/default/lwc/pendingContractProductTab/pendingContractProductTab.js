import { LightningElement, api, track } from 'lwc';
import getRecord from '@salesforce/apex/CommonTableController.getRecordDetail';
import { handleErrors } from 'c/lWCUtility';

//Retrieve Custom Labels
//import Product_Name1 from '@salesforce/label/c.Product_Name1';

export default class PendingContractProductTab extends LightningElement {

    @api recordId;
    @track condition;
    @track totalAmount;
    @track isoCode;
    @track fieldsLabels;

    /**
     * description: This method is used to call at the time of load.
     */
    connectedCallback(){
        this.condition = "SBQQ__Quote__r.SBQQ__Opportunity2__c='"+this.recordId+"' AND SBQQ__Quote__r.SBQQ__Primary__c=true";
        this.fieldsLabels = 'Product Name,Quantity,Start Date,End Date,Total Price,Line Description';
        this.getAmount();
    }

    /**
     * description: This method is used to fetch the opportunity record.
     */
    getAmount(){
        getRecord({objectName:'Opportunity',allFields:'Amount_Custom__c',recordId:this.recordId})
        .then(res=>{
            if(res.length>0){
                this.isoCode = res[0].ISO_Code__c;
                this.totalAmount = res[0].Amount_Custom__c;
            }
        })
        .catch(error=>{
            handleErrors(this,error);
        })
    }

}