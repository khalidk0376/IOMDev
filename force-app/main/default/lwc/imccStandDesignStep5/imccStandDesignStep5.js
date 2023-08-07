import { api, LightningElement, track, wire } from 'lwc';
//apex action
import saveStandDetail from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.saveStandDetail';
import { getPicklistValuesByRecordType,getObjectInfo } from 'lightning/uiObjectInfoApi';
import { handleErrors, showToast,isFieldLocked } from 'c/imcc_lwcUtility';
import userId from '@salesforce/user/Id';
import StandDetail_OBJECT from '@salesforce/schema/Stand_Detail__c';

export default class ImccStandDesignStep5 extends LightningElement {
    @api standDetails;
    @api cm;
    @api type;

    @track standDetail;        
    @track buildUpOpt;
    @track breakDownOpt;
    @track spinner;
    @track isInReview;
    @track qstListToHide = '';
    connectedCallback(){
        this.standDetail = JSON.parse(JSON.stringify(this.standDetails));
        let status = this.standDetail.Stand_Detail_Status__c?this.standDetail.Stand_Detail_Status__c:'In Progress';
        this.isInReview = isFieldLocked(status);
        if(!this.isInReview && this.cm.Is_Self_Managed__c){	
            this.isInReview = false;	
        }
        if(status==='Stand Design Rejected/Incomplete'){
            let rejectedSteps = this.standDetail.Rejected_Steps__c?this.standDetail.Rejected_Steps__c:'';
            if(rejectedSteps.indexOf('Step 5')>=0){
                this.isInReview = false;
            }
            else{
                this.isInReview = true;
            }
        }

        //read view for other contractor
        if(this.standDetail.CreatedById!==userId && this.type && !this.cm.Is_Self_Managed__c){	
            this.isInReview = true;	
        }	
    }

    @wire(getObjectInfo, { objectApiName: StandDetail_OBJECT })
    standDetailObject;

    @wire(getPicklistValuesByRecordType, {objectApiName:StandDetail_OBJECT, recordTypeId: '$standDetailObject.data.defaultRecordTypeId'})
    wiredata(result,error){
        if(result){
            const obj = JSON.parse(JSON.stringify(result));
            
            this.qstListToHide = this.cm && this.cm.Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c?this.cm.Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c:'';
            this.qstListToHide = ';'+this.qstListToHide+';';
            console.log(this.qstListToHide);
            
            if(obj.data){
                let selectedBuildUp = this.standDetail.Equipment_Required_for_Build_up__c;
                console.log('selectedBuildUp: '+selectedBuildUp);
                this.standDetail.Equipment_Required_for_Build_up__c = selectedBuildUp?selectedBuildUp.split(';'):[];
                const opt1 = obj.data.picklistFieldValues.Equipment_Required_for_Build_up__c.values;
                const opt11 = [];
                opt1.forEach((i,ind) => {
                    if(this.qstListToHide.indexOf(';'+i.value+';')<0){
                        opt11.push(i);
                    }
                });

                opt11.forEach((i,ind) => {                    
                    i.name = 'buildup'+ind;
                    if(this.standDetail.Equipment_Required_for_Build_up__c.indexOf(i.value)>=0){
                        i.selectedValue='Yes';
                    }
                    else if(this.standDetail.Equipment_Required_for_Build_up__c.length>0 || this.standDetail.Is_BuildUp_Equipment_Required__c===false){
                        i.selectedValue='No';
                    }
                });
                this.buildUpOpt = JSON.parse(JSON.stringify(opt11));
                
                let selectedBreakDown = this.standDetail.Equipment_Required_for_Breakdown__c;
                console.log('selectedBreakDown: '+selectedBreakDown);
                this.standDetail.Equipment_Required_for_Breakdown__c = selectedBreakDown?selectedBreakDown.split(';'):[];
                const opt2 = obj.data.picklistFieldValues.Equipment_Required_for_Breakdown__c.values;
                const opt22 = [];
                opt2.forEach((i,ind) => {
                    if(this.qstListToHide.indexOf(';'+i.value+';')<0){
                        opt22.push(i);
                    }
                });

                opt22.forEach((i,ind) => {                    
                    i.name = 'breakdown'+ind;
                    if(this.standDetail.Equipment_Required_for_Breakdown__c.indexOf(i.value)>=0){
                        i.selectedValue='Yes';
                    }
                    else if(this.standDetail.Equipment_Required_for_Breakdown__c.length>0 || this.standDetail.Is_Breakdown_Equipment_Required__c===false){
                        i.selectedValue='No';
                    }
                });
                this.breakDownOpt = JSON.parse(JSON.stringify(opt22));
                
            }
        }
        else if(error){
            console.error(error);
        }
    };

    handleChange(event){
        try{
            let selected = this.standDetail.Equipment_Required_for_Build_up__c?this.standDetail.Equipment_Required_for_Build_up__c:[];
            let index = event.target.dataset.index;
            let option = event.target.dataset.selectedOption;
            let obj = this.buildUpOpt[index];
            
            if(event.target.value==='Yes'){
                if(selected.indexOf(obj.value)<0){
                    selected.push(obj.value);
                }
            }
            else{
                if(selected.indexOf(option)>=0){
                    selected.splice(selected.indexOf(option),1);
                }            
            }
            console.log('Test: '+selected);
            this.standDetail.Equipment_Required_for_Build_up__c = selected;
        }
        catch(error){
            console.error(error);
        }
    };

    handleChange2(event){
        try{
            
            let selected = this.standDetail.Equipment_Required_for_Breakdown__c?this.standDetail.Equipment_Required_for_Breakdown__c:[];
            let index = event.target.dataset.index;
            let option = event.target.dataset.selectedOption;
            let obj = this.breakDownOpt[index];
            if(event.target.value==='Yes'){
                if(selected.indexOf(obj.value)<0){
                    selected.push(obj.value);    
                }
            }
            else{
                if(selected.indexOf(option)>=0){
                    selected.splice(selected.indexOf(option),1);
                }
            }
            console.log('Test: '+selected);
            this.standDetail.Equipment_Required_for_Breakdown__c = selected;
        }
        catch(error){
            console.error(error);
        }
    };

    @api saveStep5Data(){

        if(this.isInReview && this.standDetail.Stand_Detail_Status__c!=='Stand Design Rejected/Incomplete'){
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:6,status:"success"}}));
            return false;
        }

        if(this.valid()){
            try{
                this.spinner = true;
                this.standDetail.Current_Step__c = '5';
                if(this.standDetail.Stand_Detail_Status__c!=='Stand Design Rejected/Incomplete' && this.standDetail.Stand_Detail_Status__c!='Cancelled'){
                    this.standDetail.Stand_Detail_Status__c='In Review';
                }
                else{
                    this.standDetail.Stand_Detail_Status__c='Stand Design Resubmitted';
                }                
                //alert(this.standDetail.Equipment_Required_for_Build_up__c);
                this.standDetail.Is_BuildUp_Equipment_Required__c = this.standDetail.Equipment_Required_for_Build_up__c.length>0?true:false;
                this.standDetail.Is_Breakdown_Equipment_Required__c = this.standDetail.Equipment_Required_for_Breakdown__c.length>0?true:false;

                saveStandDetail({standDetail:this.standDetail})
                .then(res=>{
                    this.spinner = false;
                    showToast(this,'Step 5:- Stand detail have been update.','success','Success!');
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:6,status:"success"}}));
                })
                .catch(error=>{
                    this.spinner = false;
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:6,status:"error"}}));
                    handleErrors(this,error);
                });
            }
            catch(error){
                this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:6,status:"error"}}));
                console.error(error);
            }
        }
        else{
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:6,status:"error"}}));
            showToast(this,'Please update the invalid form entries and try again.','error','Validation Error');
        }
    };

    valid(){
        const allValid = [
            ...this.template.querySelectorAll('lightning-radio-group'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        
        return allValid;
    };

    get yesNoOption(){
        return [{label:'Yes',value:'Yes'},{label:'No',value:'No'}];
    };
}