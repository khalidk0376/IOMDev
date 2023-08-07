/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-alert */
import { LightningElement, track, api } from "lwc";
import getSSCTeamMember from "@salesforce/apex/SSCDashboardLtngCtrl.getSSCTeamMember";
import getRecordDetail from '@salesforce/apex/CommonTableController.getRecordDetail';
import strUserId from '@salesforce/user/Id';
import {handleErrors} from 'c/lWCUtility';
const DELAY=300;

//Retrieve Custom Labels
//import Account_Name from '@salesforce/label/c.Account_Name';
//import Submission_Date from '@salesforce/label/c.Submission_Date';

export default class ApprovedContractDashboard extends LightningElement {

  @track showTable = false;
  @track toggleCondition = "Manual_Contract_Approved__c=true";
  @track pendingContractCond;
  @track openActionModal=false;
  @track oppFields = '';
  @track oppFieldsLabels = '';

  connectedCallback() {
    this.getUserDetail();
    this.retrieveSSCTeamMember();
  }

  /**
   * description: This method is used to fetch the list of Event_Series__c from SSC team.
   */
  retrieveSSCTeamMember() {
    getSSCTeamMember()
      .then(result => {
        if (result) {
          let ids = [];
          for (let i = 0; i < result.length; i++) {
              if(result[i].Action_Team__r.Series__c!==undefined){
                ids.push(result[i].Action_Team__r.Series__c);
              }    
          }
          //this.pendingContractCond ='(Status__c=\'Awaiting Payment\' AND EventEdition__r.Part_of_Series__c IN (\''+ids.join('\',\'')+'\') AND x_Legacy_Id__c = \'\' AND Do_not_activate_Billing__c = false) AND (No_Billing__c = false OR (EventEdition__r.No_Billing__c = true AND EventEdition__r.Event_Price_Book__r.Name = \'Brazil\'))';
          this.pendingContractCond ='(Status__c=\'Awaiting Payment\' AND Default_Edition__r.Part_of_Series__c IN (\''+ids.join('\',\'')+'\'))';
          this.showTable = true;
        }
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
                this.oppFields = 'Name,Account.Name,Default_Edition__r.Name,CloseDate,StageName,Status__c,Amount,Approved_Rejected_By__r.Name,Approved_Rejected_At__c';
                this.oppFieldsLabels = 'Opportunity Name,Account Name,Edition,Close Date,Stage,Status,Amount,Approved By,Approved At';
            
        }
    })
    .catch(error=>{
        handleErrors(this,error);
    })
}

  /**
   * description: This method is used to call the pop up model ie. approvedContractDashboardModel
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
  @api 
  refreshTableOnTabChange(){
      if(this.template.querySelector('c-common-table')){
        this.template.querySelector('c-common-table').refreshTable();
      }
  }
  handleRefreshPendingContract(){
    this.template.querySelector('c-common-table').refreshTable();
  }
}