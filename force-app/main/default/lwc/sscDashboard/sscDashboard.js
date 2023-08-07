/* eslint-disable no-console */
import { LightningElement, track, } from 'lwc';
import getdata from '@salesforce/apex/SSCDashboardLtngCtrl.getSSCTeamMember';
import getRecordDetail from '@salesforce/apex/CommonTableController.getRecordDetail';
import {handleErrors} from 'c/lWCUtility';
import userId from '@salesforce/user/Id';

export default class SscDashboard extends LightningElement {
    @track isActionTeamMember;
    @track noActionTeamMember;
    @track customerCreationError;
    @track taxErrorCount;
    @track successDraft;
    @track cancelOrders;
    @track customerError;
    @track taxError;
    @track invoiceError;
    @track noContactOpy;
    @track amendRequestCondition;
    @track isActionProfile = false;

    connectedCallback(){
        this.getActionTeamMember();
        getRecordDetail({objectName:'User',allFields:'Profile.Name',recordId:userId})
        .then(res=>{
            if(res.length>0){
                if(res[0].Profile.Name!=='SSC Finance-Accounting' && res[0].Profile.Name!=='SSC-R2R Accounting'){
                    this.isActionProfile = true;
                }
            }
        })
        .catch(error=>{
            handleErrors(this,error);
        })
    }
    
    /**
     * description : This method will fetch the data from Action team also it contains different conditions.
     */
    getActionTeamMember(){
        getdata()
        .then(data=>{
            if(data.length > 0){
                this.isActionTeamMember = true;
            }
            else{
                this.noActionTeamMember = true;
            }
            let ids = [];
            let datas = JSON.parse(JSON.stringify(data));            
            for(let i=0; i<datas.length; i++){
                if(datas[i].Action_Team__r.Series__c!==undefined){
                    ids.push(datas[i].Action_Team__r.Series__c);
                }                
            }
            // (Status__c='Pending Change' AND EventEdition__r.Part_of_Series__c IN ('a1T50000005eT4JEAU') AND Do_not_activate_Billing__c=false) AND (No_Billing__c=false OR (EventEdition__r.No_Billing__c=true AND EventEdition__r.Event_Price_Book__r.Name='Brazil'))
            this.amendRequestCondition = "(Open_Amendment_Requests__c>0 AND Default_Edition__r.Part_of_Series__c IN ('"+ids.join("','")+"'))";
            this.customerCreationError = 'Create_Customer_Result__c!=\'Success\'';
            this.taxErrorCount = 'Tax_Error_Count__c!=0';
            this.successDraft = 'Status!=\'Activated\' AND Create_Customer_Result__c = \'Success\' AND Cancelled__c = false AND Tax_Error_Count__c = 0.0';
            this.cancelOrders = '\'Cancelled__c = true\'';
            this.customerError = 'Source_Name__c IN (\'CUSTOMER\',\'VALIDATE_CUSTOMER\')';
            this.taxError = 'Source_Name__c = \'TAX_CALCULATION\'';
            this.invoiceError= 'Source_Name__c = \'INVOICE_TO_ORDER\'';
            this.noContactOpy = 'Status__c = \'Pending Accounting Approval\' AND Default_Edition__r.Part_of_Series__c IN (\''+ids.join('\',\'')+'\') AND x_Legacy_Id__c = \'\' AND SBQQ__Contracted__c = true AND Main_Contract__c = NULL';
        })
        .catch(error=>{
           handleErrors(this,error);
        });
    }

    /**
     * description : This method is used to refresh table once the tab is changed.
     */
    handleTabClick(event){
        if(event.target.label==='Approved Contracts'){            
            if(this.template.querySelector('c-approved-contract-dashboard')!==null){
                this.template.querySelector('c-approved-contract-dashboard').refreshTableOnTabChange();
            }
        }
        if(event.target.label==='Rejected Contracts'){
            if(this.template.querySelector('c-rejected-contract-dashboard')!==null){
                this.template.querySelector('c-rejected-contract-dashboard').refreshTableOnTabChange();
            }
        }
    }
}