import { LightningElement,track } from 'lwc';
import getdata from '@salesforce/apex/SSCDashboardLtngCtrl.getSSCTeamMember';
import getRecord from '@salesforce/apex/CommonTableController.getRecordDetail';
import {handleErrors} from 'c/lWCUtility';

//Retrieve Custom Labels
//import Event_Edition_Name from '@salesforce/label/c.Event_Edition_Name';
//import Source_Invoice from '@salesforce/label/c.Source_Invoice';
// import Due_Date from '@salesforce/label/c.Due_Date';
// import Account1 from '@salesforce/label/c.Account1';
// import Invoice_Date from '@salesforce/label/c.Invoice_Date';
// import Created_Date from '@salesforce/label/c.Created_Date';


export default class DashboardInvoiceSubtabs extends LightningElement {
    @track notPostedCond;
    @track notPaidCond;
    @track notOnSapCond;
    @track invTaxErrorCond;
    @track sentInvoiceCond;
    @track creditNoteCond;
    @track baReviewRequiredCond;
    @track spinner;
   // @track creditNoteFields = 'Credit Note Number,Sequential Number,Total Amount (With Tax),'+Event_Edition_Name+','+Source_Invoice+',Created Date';
   // @track baReviewRequiredLabels = 'Invoice Number,Sequential Number,'+Due_Date+',CustomOrderNumber,Contract Number,'+Event_Edition_Name+','+Account1+',Status,'+Invoice_Date+',BA approved,'+Created_Date+'';

    /**
     * description: This method is call at the time of load.
     */
    connectedCallback(){
        this.getSSCTeamMember();
    }
    
    /**
    * description: This method is used to fetch the list of event series of ssc team from ssc team members.
    */
    getSSCTeamMember(){
        getdata()
        .then(data=>{
            if(data.length > 0){
                this.isSSCTeamMember = true;
            }
            let ids = [];
            let datas = JSON.parse(JSON.stringify(data));
            for(let i=0; i<datas.length; i++){
                if(datas[i].Action_Team__r.Series__c!==undefined){
                    ids.push(datas[i].Action_Team__r.Series__c);
                }                
            }
            this.sentInvoiceCond = 'blng__Order__r.SBQQ__Quote__r.Edition__r.Part_of_Series__c IN (\''+ids.join('\',\'')+'\') AND blng__Order__r.OpportunityId!=Null AND blng__InvoiceStatus__c=\'Posted\' AND Email_Status__c=\'Ready to Send\' ';
            
        })
        .catch(error=>{
            handleErrors(this,error);
        });
    }

    /**
    * description: This method is used call the functionality of send email.
    */
    handleOpenlinkbutton(event){
        const data = event.detail;
        this.spinner = true;       
        getRecord({objectName:'blng__Invoice__c',allFields:'OpportunityId__c',recordId:data.Id})
        .then(res=>{        
            this.spinner = false;    
            window.open('/apex/sendInvoice?id='+data.Id+'&retUrl='+res[0].OpportunityId__c+'&accountId='+data.blng__Account__c+'&IsSSC=true');
        })
        .catch(error=>{
            this.spinner = false;    
            handleErrors(this,error);
        })
    }
}