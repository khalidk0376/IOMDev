import { LightningElement,api,wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
// import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
// import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STAGE_NAME from '@salesforce/schema/Opportunity.StageName';
import ACCOUNT_ID from '@salesforce/schema/Opportunity.AccountId';
import IOM_IM_NUMBER from '@salesforce/schema/Opportunity.IOM_Opportunity_No__c';
import getAmdDetails from '@salesforce/apex/IOM_AmendmentRequestUtils.fetchIOMAmdCatDetails';

export default class IomAmendmentRequest extends LightningElement {
    @api recordId;

    disableSubmit = false;
    isShowSubmit4ChangeForm;
    errorMsg ='';
    showAmedmentCategoryDescriptionAlert = false;
    amedmentCategoryDescriptionMsg = '';
    showmultiAmedmentCategoryDescriptionAlert = false;
    multiamedmentCategoryDescriptionMsg = [];
    listMetaData = [];
    showlostreason = false;


    defaultRecordTypeId;
    opportunityStage;
    opportunutyIOM_Number;
    opportunutyAccountId;

   objectApiName = 'IOM_Amendment_Request__c';

   connectedCallback()
   {
        this.getAllMetaData();
        console.log('connectedCallback',window.location.origin);
   }

   getAllMetaData(){
       this.disableSubmit = false;
        getAmdDetails()
            .then(data => {
                this.listMetaData = data;
                console.log("listMetaData data ==",JSON.stringify(data));
            })
            .catch(error2 => {
                console.log('Some Error Occured in getAllMetaData');
            });
   }
   handleSuccess(e) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'New Amendment Request submited successfully!',
                variant: 'success'
            })
        );
        
        this.closeQuickAction();
        //getRecordNotifyChange([{recordId: this.recordId}]);
        console.log(window.location.origin);
        let url = window.location.origin+'/'+this.recordId;
        location.href = url;
        
   }
   closeQuickAction ()
   {
        this.dispatchEvent(new CloseActionScreenEvent());
   }

   @wire(getRecord, { recordId: '$recordId', fields: [IOM_IM_NUMBER,STAGE_NAME,ACCOUNT_ID] })
   accountData({ error, data }) {
       if (data) {
        console.log("OPP data ==",JSON.stringify(data));           
           this.opportunityStage        = data.fields.StageName.value;
           this.opportunutyIOM_Number   = data.fields.IOM_Opportunity_No__c.value;
           this.opportunutyAccountId    = data.fields.AccountId.value;

           this.geterrorMsg();
       } else if (error) {            
           this.error = error;
       }
   };

   geterrorMsg() 
   {   this.isShowSubmit4ChangeForm = false;
       if(this.opportunityStage != 'Closed Won')
       {
            this.errorMsg = 'Amendment Request can not be raised until the opportunity is closed won';
       }else if (!this.opportunutyIOM_Number)
       {
            this.errorMsg = 'The opportunity is yet to be synced with IOM, Please try after some time';
       }else 
       {
            this.isShowSubmit4ChangeForm = true;
       }       
   }

   reqCagChange(event)
   {
       if(this.listMetaData)
       {
            let typeOfChg = event.target.value;
            this.amedmentCategoryDescriptionMsg = '';
            this.showAmedmentCategoryDescriptionAlert = false;
            this.showmultiAmedmentCategoryDescriptionAlert = false;
            this.multiamedmentCategoryDescriptionMsg = [];
            this.listMetaData.forEach((row) => {
                if(!typeOfChg.includes(';')){
                    if(typeOfChg == 'Cancellation'){
                        this.showlostreason = true;
                    }else{
                        this.showlostreason = false;
                    }
                    if(row.MasterLabel === typeOfChg){
                        this.amedmentCategoryDescriptionMsg = row.IOM_Description__c;
                        this.showAmedmentCategoryDescriptionAlert = true;
                    }
                }else{
                    for(var a of typeOfChg.split(';')){
                        if(a == 'Cancellation'){
                            this.showlostreason = true;
                        }else{
                            this.showlostreason = false;
                        }
                        if(row.MasterLabel === a){
                            this.showAmedmentCategoryDescriptionAlert = false;
                            var data = {
                                Id:a , value: row.IOM_Description__c
                            };
                            console.log('data',JSON.stringify(data));
                            if(!this.multiamedmentCategoryDescriptionMsg.includes(data)){
                                this.multiamedmentCategoryDescriptionMsg.push(data);
                            }
                            this.showmultiAmedmentCategoryDescriptionAlert = true;
                        }
                    }
                }
                
            });
       }       
       //alert('REQ CH');       
   }

   closeAlert()
   {
        this.amedmentCategoryDescriptionMsg = '';
        this.showAmedmentCategoryDescriptionAlert = false;
        this.showmultiAmedmentCategoryDescriptionAlert = false;
        this.multiamedmentCategoryDescriptionMsg = [];
   }

   onSubmit()
   {       
       
   }

   handleSubmit(event){        
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        if(this.isInputValid(fields))
        {
            this.disableSubmit = true;
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }        
     };

   isInputValid(fields){
        let isValid = true;
        if(!fields.IOM_Amendment_Type__c )
        {
            this.showNotification('Error','At least one amendment type needs to be selected','error');   
            isValid = false;       
        }
        if(!fields.IOM_Request_Instruction__c )
        {
            this.showNotification('Error','Request Instruction can not be blank','error');
            isValid = false;
        }
       if(!fields.IOM_Lost_Reason__c && this.showlostreason){
            this.showNotification('Error','Lost Reason can not be blank','error');
           isValid = false;
       }
        return isValid;
    }

    showNotification(title,message,variant)
    {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant?variant:'success'
        });
        this.dispatchEvent(evt);        
    }

    // /// get Object Default Record ID    
    // @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    // objectInfo({ error, data }) {
    //     if (data) {
    //         this.defaultRecordTypeId = data.defaultRecordTypeId;
    //     } else if (error) {
    //         this.error = error;
    //     }
    // };
}