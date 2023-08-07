import { LightningElement,api,track, wire } from 'lwc';
import {handleErrors, showToast} from 'c/lWCUtility';
import getRejectionOptions from '@salesforce/apex/SSCDashboardLtngCtrl.getRejectionOptions';
import getRecordDetail from '@salesforce/apex/CommonTableController.getRecordDetail';
import getRecordCount from '@salesforce/apex/CommonTableController.getRecordCount';
import isSSCBrazilRole from '@salesforce/apex/SSCDashboardLtngCtrl.isSSCBrazilUser';
import approveContract from '@salesforce/apex/SSCDashboardLtngCtrl.approveContract';
import createApiItems from '@salesforce/apex/APISynchronizationHelper.createOppTransactionRequests';
import IOMsendEmail from '@salesforce/apex/SendIOMEmails.sendEmailTemplateWithTemplate';
import userId from '@salesforce/user/Id';

export default class PendingContractModal extends LightningElement {

    @api isOpenActionModal;
    @api recordId;    
    @api objectName;
    @api showApproveReject;

    @track chatterAppUrl;
    @track oppName;
    @track accountId;
    @track isDisabled;
    @track isSSCBrazilUser;
    @track rejectionOptions;
    @track rejectionResponses='';
    @track spinner;
    @track iOpportunityCount;
    @track bOpportunityCount;

    @wire(getRejectionOptions,{})
    wireRejectionOptions(result){
        

        if(result.data){
            this.rejectionOptions = JSON.parse(JSON.stringify(result.data.Rejection_Reason.FieldPicklist));
            // this.rejectionOptions.splice(0,1,{label:'--None--',value:''});
        }
        else if(result.error){
            handleErrors(this,result.error);
        }
    }

    getData(){
        isSSCBrazilRole()
        .then(result=>{
            this.isSSCBrazilUser = result;            
        })
        .catch(error=>{
            handleErrors(this,error)
        })
    }

    @api
    getOppDetail(recordId){      
        // eslint-disable-next-line no-alert
        //alert('recordId: '+recordId);
        console.log('showApproveReject ' +this.showApproveReject);  
        this.recordId = recordId;
        this.chatterAppUrl = '/apex/SSCChatter?Id='+this.recordId;
        getRecordDetail({objectName:'Opportunity',allFields:'Name,AccountId',recordId:recordId})
        .then(data=>{
            if(data.length>0){
                this.oppName = data[0].Name;
                this.accountId = data[0].AccountId;
                this.getOpportunityCount(this.accountId);
            }
            this.getData();
        })
        .catch(error=>{
            handleErrors(this,error);
        });
    }

    getOpportunityCount(accountId){
        /**
         * @description: Get Count of opportunity on the basis of account id of the selected opportunity.
         */
        let accountOppCond = '(AccountId=\''+accountId+'\' AND Status__c =\'Pending Accounting Approval\'   AND SBQQ__Contracted__c = true AND Main_Contract__c != NULL AND Do_not_activate_Billing__c = false AND IsAmendContractOpp__c = false)';
        getRecordCount({objectName:'Opportunity',allFields:'Id',condition:accountOppCond})
        .then(result=>{
            //alert(result);
                if(result>1){
                    this.iOpportunityCount = result;
                    if (this.iOpportunityCount > 0 ){
                        this.bOpportunityCount = true;
                    }
                }
                else {
                    this.bOpportunityCount= false;
                }
        })
        .catch(error=>{
            handleErrors(this,error);
        });
    }

    @track openRejectModal;
    openRejectConfirmationModal(){
        this.rejectionResponses = '';
        this.openRejectModal = true;
    }
    /**
     * Fire whenever user click Reject button of confirmation modal
     */
    yesReject(){

    }

    handleSubmit(event){
        event.preventDefault();
        const fields = event.detail.fields;
        
        if(this.rejectionResponses==='Opportunity Rejected'){
            fields.Rejection_Notes__c = this.template.querySelector(".ssc-notes-field").value;
            if(fields.Rejection_Notes__c.trim()===''){
                this.template.querySelector(".ssc-notes-field").showHelpMessageIfInvalid();
                showToast(this,'SSC Note field must not empty','error','Error');
                return;
            }
            else if(fields.Rejection_Notes__c.length>131072){
                this.template.querySelector(".ssc-notes-field").showHelpMessageIfInvalid();
                showToast(this,'A maximum of 131072 characters are allowed in a SSC Note.','error','Error');
                return;
            }
        }

        let dateTimeNow = new Date().toISOString();
        
        // fields.StageName = 'Customize';
        fields.Approved_Rejected_By__c = userId;
        fields.Status__c = 'Accounting Rejected';
        fields.Rejection_Reason__c = this.rejectionResponses;
        fields.Approved_Rejected_At__c = dateTimeNow;

        
        this.template.querySelector(".reject-form").submit(fields);
        this.spinner = true;
    }
    handleSuccess(){
        showToast(this,'Contract was rejected','success','Success');
        this.spinner = false;
        this.openRejectModal = undefined;
        this.isOpenActionModal = undefined;
        //Create API Item
        this.createApiItemsRecords();
        //fire event to refresh Pending Contract tab
        this.dispatchEvent(new CustomEvent('refreshpendingcontract'));
        this.sendEmail(this.recordId);//IOMsendEmail
    }
    sendEmail(crRecID){
        debugger;
        console.log('crRecID==>',crRecID);
       IOMsendEmail({
            crrecordId: crRecID,
            emailTemplate: 'Opportunity_Custom_Billing_Rejection'
        })
        .then(result=>{
             console.log('Email Sent Succesfully! '+result);
        })
        .catch(error=>{            
            console.log('error in email'+error);
        })
    }
    handleError(event){
        handleErrors(this,event.detail);
    }

    closeRejectModal(){
        this.openRejectModal = undefined;        
    }

    @track openApprovModal;
    openApproveConfirmationModal(){
        this.openApprovModal = true;
    }
    /**
     * Fire whenever user click Approve button of confirmation modal
     */
    yesApprove(){
        this.spinner = true;
        let oppObj = {Status__c:'Awaiting Payment',Manual_Contract_Approved__c:true,Approved_Rejected_By__c:userId,sobjectType:'Opportunity',Id:this.recordId};
        approveContract({oppObj:oppObj})
        .then(()=>{
            showToast(this,'Contract Approved','success','Success');
            this.spinner = false;
            this.openApprovModal = undefined;
            this.isOpenActionModal = undefined;
            //fire event to refresh Pending Contract tab
            this.dispatchEvent(new CustomEvent('refreshpendingcontract'));
        })
        .catch(error=>{
            this.spinner = false;            
            handleErrors(this,error);
        })
    }
    closeApproveModal(){
        this.openApprovModal = undefined;
    }

    handleRejectionResponse(event){
        this.rejectionResponses = event.detail.value;
        if(this.rejectionResponses!==''){
            this.template.querySelector(".ssc-note-box").classList.remove('slds-hide');
        }
        else{
            this.template.querySelector(".ssc-note-box").classList.add('slds-hide');
        }

        if(this.rejectionResponses==='Opportunity Rejected'){            
            this.template.querySelector(".ssc_note_2").classList.remove('slds-show');
            this.template.querySelector(".ssc_note_2").classList.add('slds-hide');
            this.template.querySelector(".ssc_note_1").classList.remove('slds-hide');
            this.template.querySelector(".ssc_note_1").classList.add('slds-show');
        }
        else{
            this.template.querySelector(".ssc_note_2").classList.remove('slds-hide');
            this.template.querySelector(".ssc_note_2").classList.add('slds-show');
            this.template.querySelector(".ssc_note_1").classList.remove('slds-show');
            this.template.querySelector(".ssc_note_1").classList.add('slds-hide');
        }
    }

    /**
     * fire after user form submit
     */
    handleAfterFormSubmission(){
        this.isOpenActionModal = false;
        this.dispatchEvent(new CustomEvent('refreshpendingcontract'));
    }

    /*
    * @description [This method is used to close the model]
    */
    closeModal() {
        this.isOpenActionModal = false;
    }
    /**
     * @description - Create API Sync Items if Opportunity is rejected [IOM-775]
     * @param objList 
     */
    createApiItemsRecords()
    {
        let objList = [{Id:this.recordId}]
        createApiItems({oppList:objList})
        .then(result=>{
            console.log('API Trans Id '+result);
        })
        .catch(error=>{            
            console.log('error in createApiItems'+error);
        })
    }
}