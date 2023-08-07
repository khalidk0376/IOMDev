import { api, LightningElement, track, wire } from 'lwc';
//apex action
import saveStandDetail from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.saveStandDetail';
import getOptions from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.getOptions';
//custom label
import step from '@salesforce/label/c.Step';
import Basic from '@salesforce/label/c.Basic';
import Contractor from '@salesforce/label/c.Contractor';
import Health_Safety_Contact from '@salesforce/label/c.Health_Safety_Contact';
import General from '@salesforce/label/c.General';
import Information from '@salesforce/label/c.Information';
import Subcontractor from '@salesforce/label/c.Subcontractor';
import Stand  from '@salesforce/label/c.Stand';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import BillingCountryCode_FIELD from '@salesforce/schema/Account.BillingCountryCode';

import { showToast,handleErrors,isFieldLocked } from 'c/imcc_lwcUtility';
import userId from '@salesforce/user/Id';

export default class ImccStandDesignStep1 extends LightningElement {
    @api detailObj;
    @api standDetails;
    @api type;
    basicInfo = step + ' 1: '+ Basic+' '+Information;
    
    contractorInfo = Contractor+' '+Information;
    standInfo = Stand+' '+Information;
    generalIfo = General+' '+Information;
    subcontractorInfo = Subcontractor+' '+Information;
    Health_Safety_Contact_L = Health_Safety_Contact;
    generalInfo = General+' '+Information;

    @track spinner;
    @track countryList;
    @track taskActivityOptions;
    @track isShowSubContractor;
    @track standDetail;    
    @track isInReview;

    @track qstListToHide = '';
    connectedCallback(){
         this.standDetail = JSON.parse(JSON.stringify(this.standDetails?this.standDetails:{sobjectType:'Stand_Detail__c'}));
        this.standDetail.Task_Activity__c = this.standDetail.Task_Activity__c?this.standDetail.Task_Activity__c.split(';'):undefined;
        this.isShowSubContractor = this.standDetail.Subcontractor_Name__c?true:false;
        
        this.qstListToHide = this.detailObj.Edition__r.Stand_Setting__r && this.detailObj.Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c?this.detailObj.Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c:'';
        this.qstListToHide = ';'+this.qstListToHide+';';
        let status = this.standDetail.Stand_Detail_Status__c?this.standDetail.Stand_Detail_Status__c:'In Progress';
        this.isInReview = isFieldLocked(status);
        console.log('this.isInReview: '+this.isInReview);
        console.log('this.detailObj.Is_Self_Managed__c:=== '+this.detailObj.Is_Self_Managed__c);
        if(!this.isInReview && this.detailObj.Is_Self_Managed__c){
            this.isInReview = false;
        }

        if(status==='Stand Design Rejected/Incomplete'){
            let rejectedSteps = this.standDetail.Rejected_Steps__c?this.standDetail.Rejected_Steps__c:'';
            if(rejectedSteps.indexOf('Step 1')>=0){
                this.isInReview = false;
            }
            else{
                this.isInReview = true;
            }
        }

        console.log('this.detailObj.Is_Self_Managed__c: '+this.detailObj.Is_Self_Managed__c);
        console.log('User: '+this.standDetail.CreatedById+'!=='+userId+','+this.type);
        //read view for other contractor
        if(this.standDetail.CreatedById!==userId && this.type && !this.detailObj.Is_Self_Managed__c){
            this.isInReview = true;
        }
        getOptions({objectName:'Stand_Detail__c',fieldName:'Task_Activity__c'})
        .then(res=>{
            this.taskActivityOptions = res;
        })
        .catch(error=>{
            handleErrors(this,error);
        })
    }  

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountObject;
    
    @wire(getPicklistValues, { recordTypeId: '$accountObject.data.defaultRecordTypeId', fieldApiName: BillingCountryCode_FIELD})
    wiredata(result,error){
        if(result){            
            const obj = JSON.parse(JSON.stringify(result));
            if(obj.data){
                this.countryList = JSON.parse(JSON.stringify(obj.data.values));                
            }            
        }
        else if(error){
            console.error(error);
        }
    };

    addSubContractor(){
        this.isShowSubContractor = true;
    };

    removeSubContractor(){
        this.isShowSubContractor = false;
    };

    handleChange(event){
        try{
            let name = event.target.name;
            let val = event.target.value;            
            if(name==='safety_con_name'){
                this.standDetail.Onsite_Health_and_Safety_Contact_Name__c = val;
            }
            else if(name==='safety_con_number'){
                this.standDetail.Onsite_Health_and_Safety_Contact_Number__c = val;
            }
            else if(name==='safety_con_email'){
                this.standDetail.Onsite_Health_and_Safety_Contact_Email__c = val;
            }
            else if(name==='sub_company'){
                this.standDetail.Subcontractor_Company__c = val;
            }
            else if(name==='sub_name'){
                this.standDetail.Subcontractor_Name__c = val;
            }
            else if(name==='sub_email'){
                this.standDetail.Subcontractor_Email__c = val;
            }
            else if(name==='sub_number'){
                this.standDetail.Subcontractor_Number__c = val;
            }
            else if(name==='sub_country'){
                this.standDetail.Subcontractor_Country__c = val;
            }
            else if(name==='sub_task'){
                this.standDetail.Task_Activity__c = val;
            }
            else if(name==='radioGroup1'){
                this.standDetail.Does_the_contractor_hold_adequate_public__c = val;
            }
            else if(name==='radioGroup2'){
                this.standDetail.Are_you_aware_of_the_onsite_welfare__c = val;
            }
            else if(name==='radioGroup3'){
                this.standDetail.Is_the_appointed_contractor_travelling__c = val;
            }
            console.log(JSON.stringify(this.standDetail));
        }
        catch(error){
            console.error(error);
        }
    }

    @api saveStep1Data(){
        if(this.isInReview){
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:2,status:"success"}}));
            return false;
        }

        if(this.valid()){
            try{
                this.spinner = true;
                console.log(JSON.stringify(this.standDetail));
                this.standDetail.Contractor_Mapping__c = this.detailObj.Id;
                this.standDetail.Current_Step__c = '1';
                if(this.standDetail.Stand_Detail_Status__c!=='Stand Design Rejected/Incomplete' && this.standDetail.Stand_Detail_Status__c!='Cancelled'){
                    this.standDetail.Stand_Detail_Status__c='In Progress';
                }

                console.log(JSON.stringify(this.standDetail));

                //if subcontractor disable then clear subcontractor fields
                if(this.isShowSubContractor === false){
                    this.standDetail.Subcontractor_Company__c='';
                    this.standDetail.Subcontractor_Name__c='';
                    this.standDetail.Subcontractor_Email__c='';
                    this.standDetail.Subcontractor_Number__c='';
                    this.standDetail.Subcontractor_Country__c='';
                    this.standDetail.Task_Activity__c='';
                }

                saveStandDetail({standDetail:this.standDetail})
                .then(res=>{
                    this.spinner = false;
                    showToast(this,'Step 1:- Stand detail have been update.','success','Success!');
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:2,status:"success"}}));
                })
                .catch(error=>{
                    this.spinner = false;
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:2,status:"error"}}));
                    handleErrors(this,error);
                });
            }
            catch(error){
                this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:2,status:"error"}}));
                console.error(error);
            }
        }
        else{
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:2,status:"error"}}));
            showToast(this,'Please update the invalid form entries and try again.','error','Validation Error');
        }
    }

    valid(){
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        const allValid2 = [
            ...this.template.querySelectorAll('lightning-radio-group'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
                
        return allValid && allValid2;
    }

    get yesNoOption(){
        return [{label:'Yes',value:'Yes'},{label:'No',value:'No'}];
    };

    //question hide logic
    get isShowQ1(){
        return !(this.qstListToHide.indexOf(';Exhibitor Name;')>=0);
    };
    get isShowQ2(){        
        return !(this.qstListToHide.indexOf(';Dimension;')>=0);
    };
    get isShowQ3(){        
        return !(this.qstListToHide.indexOf(';Stand No.;')>=0);
    };
    get isShowQ4(){        
        return !(this.qstListToHide.indexOf(';Area;')>=0);
    };
    get isShowQ5(){        
        return !(this.qstListToHide.indexOf(';Hall;')>=0);
    };
    get isShowQ6(){        
        return !(this.qstListToHide.indexOf(';Contractor Company;')>=0);
    };
    get isShowQ7(){        
        return !(this.qstListToHide.indexOf(';Contractor Contact Name;')>=0);
    };
    get isShowQ8(){
        return !(this.qstListToHide.indexOf(';Contractor Contact Email;')>=0);
    };
    get isShowQ9(){
        return !(this.qstListToHide.indexOf(';Contractor Contact Number;')>=0);
    };
    get isShowQ10(){
        return !(this.qstListToHide.indexOf(';Contractor Country;')>=0);
    };
    get isShowAddSubContractorBtn(){
        return !(this.qstListToHide.indexOf(';Are you going to use Subcontractor?;')>=0);
    };
    get isShowQ11(){
        return !(this.qstListToHide.indexOf(';Subcontractor Company;')>=0);
    };
    get isShowQ12(){
        return !(this.qstListToHide.indexOf(';Subcontractor Contact Name;')>=0);
    };
    get isShowQ13(){
        return !(this.qstListToHide.indexOf(';Subcontractor Contact Email;')>=0);
    };
    get isShowQ14(){
        return !(this.qstListToHide.indexOf(';Subcontractor Contact Number;')>=0);
    };
    get isShowQ15(){
        return !(this.qstListToHide.indexOf(';Subcontractor Country;')>=0);
    };
    get isShowQ16(){
        return !(this.qstListToHide.indexOf(';Task/Activity;')>=0);
    };
    get isShowQ17(){
        return !(this.qstListToHide.indexOf(';Onsite Health and Safety Contact Name;')>=0);
    };
    get isShowQ18(){
        return !(this.qstListToHide.indexOf(';Onsite Health and Safety Contact Number;')>=0);
    };
    get isShowQ19(){
        return !(this.qstListToHide.indexOf(';Onsite Health and Safety Contact Email;')>=0);
    };
    get isShowQ20(){
        return !(this.qstListToHide.indexOf(';Hold Public liability insurance;')>=0);
    };
    get isShowQ21(){
        return !(this.qstListToHide.indexOf(';Onsite welfare facilities awareness;')>=0);
    };
    get isShowQ22(){
        return !(this.qstListToHide.indexOf(';Contractor Travel less than 80km;')>=0);
    };

    get isShowHealth(){
        return (this.isShowQ17 || this.isShowQ18 || this.isShowQ19);
    }

    get isShowGeneralInformation(){
        return (this.isShowQ20 || this.isShowQ21 || this.isShowQ22);
    }
}