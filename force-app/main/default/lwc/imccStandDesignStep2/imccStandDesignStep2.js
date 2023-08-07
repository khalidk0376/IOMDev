import { api, LightningElement, track } from 'lwc';
//apex action
import saveStandDetail from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.saveStandDetail';
import getManualPermission from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.getManualPermission';
import getManualStatus from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.getManualStatus';
//custom label
import heading from '@salesforce/label/c.Read_and_agree_to_the_manual_guide';
import step from '@salesforce/label/c.Step';
import manual from '@salesforce/label/c.manuals';
import freetext from '@salesforce/label/c.Text_for_the_team';
import { showToast,handleErrors,isFieldLocked } from 'c/imcc_lwcUtility';
import userId from '@salesforce/user/Id';

export default class ImccStandDesignStep2 extends LightningElement {
    
    //custom labels
    stepLabel = step;
    headingLabel = heading;
    manualsLable = manual;
    freetextLabel = freetext;

    //pubic vaiables
    @api standDetails; //we can not modify this variable
    @api detailObj;
    @api editionCode;
    @api accountId;
    @api type;
    
    @track standDetail;
    @track qryConditionMan;
    @track conEdMapId;
    @track isPermissionFound;
    @track isManualValid;
    @track isInReview; 
    @track spinner;
    @track qstListToHide = '';
    @track utype;
    connectedCallback(){
        this.utype = this.type?true:false;
        console.log('this.utype::'+this.utype);
        this.isManualValid = true;
        console.log('this.standDetails::'+JSON.stringify(this.standDetails));
        this.standDetail = JSON.parse(JSON.stringify(this.standDetails));
        let status = this.standDetail.Stand_Detail_Status__c?this.standDetail.Stand_Detail_Status__c:'In Progress';
        
        this.isInReview = isFieldLocked(status);
        console.log('this.isInReview::'+this.isInReview);
        if(!this.isInReview && this.detailObj.Is_Self_Managed__c){
            this.isInReview = false;
            this.utype = false;
        }
        if(status==='Stand Design Rejected/Incomplete'){
            let rejectedSteps = this.standDetail.Rejected_Steps__c?this.standDetail.Rejected_Steps__c:'';
            if(rejectedSteps.indexOf('Step 2')>=0){
                this.isInReview = false;
            }
            else{
                this.isInReview = true;
            }
        }

        //read view for other contractor
        if(this.standDetail.CreatedById!==userId && this.type  && !this.detailObj.Is_Self_Managed__c){
            this.isInReview = true;
        }
        this.qstListToHide = this.detailObj.Edition__r.Stand_Setting__r && this.detailObj.Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c?this.detailObj.Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c:'';
        this.qstListToHide = ';'+this.qstListToHide+';';

        this.doInit();
    }

    doInit(){
        try{
            let ac = this.type?this.detailObj.Account__c:this.accountId;
            console.log('this.editionCode::'+this.editionCode);
            console.log('this.ac::'+ac);
            console.log('this.detailObj.Contact__c::'+this.detailObj.Contact__c);
            getManualPermission({
                eventCode: this.editionCode,
                accountId : ac,
                contId:this.detailObj.Contact__c
            })
            .then(result => {
                console.log('this.resuly::'+JSON.stringify(result));
                let data = JSON.parse(JSON.stringify(result));
                this.conEdMapId = data.cemIds[data.cemIds.length-1];         
                let permission = JSON.parse(JSON.stringify(data.manualPermission));
                const p = [];
                permission.forEach(item=>{
                    p.push(item.Id);
                });
                this.isPermissionFound = p && p.length>0?true:false;
                this.qryConditionMan = 'Contact_Edition_Mapping__c IN(\'' + data.cemIds.join('\',\'') + '\') AND Forms_Permission__c IN  (\'' + p.join('\',\'') + '\') AND Forms_Permission__r.Form_Allocation__r.Is_Required_For_Stand_Design__c=true AND Is_Active__c=true ';
                this.getManualStatus();
            })
            .catch(error => {
                window.console.error('error...!' + JSON.stringify(error));
                this.error = error;
            });
        }
        catch(e){
            console.error(e);
        }
    };

    handleChange(event){
        try{
            this.standDetail.Free_Text_for_the_team_to_customize_base__c = event.target.value;
        }
        catch(error){
            console.error(error);
        }
    };

    @api saveStep2Data(){
        if(this.isInReview){
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:3,status:"success"}}));
            return false;
        }

        if(!this.isManualValid){
            showToast(this,'Please open each manauls to read and agree to the contents of all manuals.','error','Manual Validation Error!');
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:3,status:"error"}}));
            return false;
        }

        if(this.valid()){
            try{
                this.spinner = true;
                console.log(JSON.stringify(this.standDetail));                
                this.standDetail.Current_Step__c = '2';
                //this.standDetail.Stand_Detail_Status__c='In Progress';
                console.log(JSON.stringify(this.standDetail));

                saveStandDetail({standDetail:this.standDetail})
                .then(res=>{
                    this.spinner = false;
                    showToast(this,'Step 2:- Stand detail have been update.','success','Success!');
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:3,status:"success"}}));
                })
                .catch(error=>{
                    this.spinner = false;
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:3,status:"error"}}));
                    handleErrors(this,error);
                });
            }
            catch(error){
                this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:3,status:"error"}}));
                console.error(error);
            }
        }
        else{
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:3,status:"error"}}));
            showToast(this,'Please update the invalid form entries and try again.','error','Validation Error');
        }
    };
    
    valid(){
        return true;
        /*let allValid = false;        
        if(this.isShowQ1===false){
            allValid = true;
        }
        else{
            allValid = [
                ...this.template.querySelectorAll('lightning-textarea'),
            ].reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        }*/

        return allValid;
    };

    getManualStatus(){        
        getManualStatus({condition:this.qryConditionMan})
        .then(res=>{            
            const data = JSON.parse(JSON.stringify(res));
            console.log('data::'+JSON.stringify(res));
            console.log('isManualValid1: '+this.isManualValid+'');
            //set manual default agreement status false            
            const result = data.filter(item => !(item.Is_Viewed__c && item.Is_Agreed__c));            
            this.isManualValid = result.length===0?true:false;            
            console.log('isManualValid2: '+this.isManualValid+'');
        })
        .catch(error=>{
            handleErrors(this,error);
        });        
    };

    get isShowQ1(){
        return !(this.qstListToHide.indexOf(';Free Text for the team to customize based on show requirement;')>=0);
    };
}