/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-alert */
import { LightningElement, track } from 'lwc';
import getdata from '@salesforce/apex/SSCDashboardLtngCtrl.getSSCTeamMember';
import getRecordDetail from '@salesforce/apex/CommonTableController.getRecordDetail';
import strUserId from '@salesforce/user/Id';
import {handleErrors} from 'c/lWCUtility';
const DELAY=300;

//Retrieve Custom Labels
//import Account_Name from '@salesforce/label/c.Account_Name';
//import Submission_Date from '@salesforce/label/c.Submission_Date';
//import Rejection_Reason from '@salesforce/label/c.Rejection_Reason';

export default class PendingContractDashboard extends LightningElement {

    @track openActionModal=false;
    @track recordId='';
    @track error;
    @track pendingContractCond;
    @track oppFields = '';
    @track oppFieldsLabels = '';

    /**
    * Description: This method will call at the time of load.
    */
    connectedCallback(){
        this.getUserDetail();
        this.getSSCTeamMember();
    }
    
    /**
    * Description: This method will fetch the list of event series from ssc team member.
    */
    getSSCTeamMember(){
        getdata()
        .then(data=>{
            let ids = [];
            let datas = JSON.parse(JSON.stringify(data));
            for(let i=0; i<datas.length; i++){
                if(datas[i].Action_Team__r.Series__c!==undefined){
                    ids.push(datas[i].Action_Team__r.Series__c);
                }                
            }           
            this.pendingContractCond = "(Status__c=\'Pending Accounting Approval\' AND Default_Edition__r.Part_of_Series__c IN ('"+ids.join("','")+"'))";
        })
        .catch(error=>{
           handleErrors(this,error);
        });
    }

    /**
    * Description: This method will fetch the list of userrole from user based on login user id.
    */
    getUserDetail(){
        getRecordDetail({objectName:'User',allFields:'UserRole.Name',recordId:strUserId})
        .then(res=>{
            if(res.length > 0){               
                    this.oppFields = 'Name,Amount_Custom__c,CloseDate,StageName,Status__c,Default_Edition__r.Name';                
                    this.oppFieldsLabels = 'Opportunity Name,Contract Total,Close Date,Stage,Status, Edition';              
            } 
        })
        .catch(error=>{
            handleErrors(this,error);
        })
    }

    /**
    * Description: This method will call once user click on popup icon.
    */
    handleActionModal(event){
        this.recordId = event.detail;
        window.clearTimeout(this.delayTimeout);        
        this.openActionModal = false;
        this.delayTimeout = setTimeout(()=>{
            this.recordId = event.detail;
            this.openActionModal = true; 
            this.template.querySelector('c-pending-contract-modal').getOppDetail(this.recordId);           
        },DELAY);
    }

    /*
        * @description [This method is used to refresh this table while click on tab]
    */   
   handleRefreshPendingContract(){
        this.template.querySelector('c-common-table').refreshTable();
   }
}