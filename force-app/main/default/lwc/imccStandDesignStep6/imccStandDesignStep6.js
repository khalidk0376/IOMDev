import { api, LightningElement, track } from 'lwc';
import saveStandDetail from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.saveStandDetail';
import { handleErrors, showToast} from 'c/imcc_lwcUtility';
import userId from '@salesforce/user/Id';

export default class ImccStandDesignStep6 extends LightningElement {
    @api standDetails;
    @api cm; //contract mapping
    @api type;

    @track standDetail;

    @track hoursOpt;
    @track crewOpt;
    @track workingOtherStand1;
    @track workingOtherStand2;    
    @track spinner;
    @track qstListToHide = '';
    @track isInReview;
    connectedCallback(){
        this.standDetail = JSON.parse(JSON.stringify(this.standDetails));
        
        let status = this.standDetail.Stand_Detail_Status__c?this.standDetail.Stand_Detail_Status__c:'In Progress';
        this.isInReview = status.toLowerCase()==='permission to build';
        if(!this.isInReview && this.cm.Is_Self_Managed__c){
            this.isInReview = false;
        }
        //read view for other contractor
        if(this.standDetail.CreatedById!==userId && this.type && !this.cm.Is_Self_Managed__c){
            this.isInReview = true;
        }

        let val1 = this.standDetail.Build_crew_working_on_other_stands__c;
        this.workingOtherStand1 = val1==='Yes'?true:false;

        let val2 = this.standDetail.Breakdown_crew_working_on_other_stands__c;
        this.workingOtherStand2 = val2==='Yes'?true:false;

        this.qstListToHide = this.cm.Edition__r.Stand_Setting__r && this.cm.Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c?this.cm.Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c:'';
        this.qstListToHide = ';'+this.qstListToHide+';';

        let hr = this.cm.Edition__r.Stand_Setting__r.Maximum_Hours__c?parseInt(this.cm.Edition__r.Stand_Setting__r.Maximum_Hours__c,10):0;
        const opt1 = [];
        if(hr>6){
            for(let i=6;i<=hr;i=i+6){
                opt1.push({label:i+'H',value:i+'H'});
            }
        }

        this.hoursOpt = opt1;
        let crew = this.cm.Edition__r.Stand_Setting__r.Maximum_Size_of_Crew__c?parseInt(this.cm.Edition__r.Stand_Setting__r.Maximum_Size_of_Crew__c,10):0;
        const opt2 = [];
        if(crew>0){
            for(let i=1;i<crew;i=i+5){
                let j = i+4;
                opt2.push({label:i+' - '+j,value:i+' - '+j});
            }
        }
        this.crewOpt = opt2;
    };

    handleChange(event){
        let name = event.target.name;
        let val = event.target.value;
        if(name==='const_time1'){
            this.standDetail.Build_Construction_Time__c = val;
        }
        else if(name==='arrival_time1'){
            this.standDetail.Build_Crew_Onsite_Arrival_Time__c = val;
        }
        else if(name==='size_of_crew1'){
            this.standDetail.Build_Size_of_Crew__c = val;
        }
        else if(name==='other_stand1'){
            this.standDetail.Build_crew_working_on_other_stands__c = val;
            this.workingOtherStand1 = val==='Yes'?true:false;
        }
        else if(name==='stand_number1'){
            this.standDetail.Build_list_Stands_Numbers__c = val;
        }        
        else if(name==='const_time2'){
            this.standDetail.Breakdown_Construction_Time__c = val;
        }
        else if(name==='arrival_time2'){
            this.standDetail.Breakdown_Crew_Onsite_Arrival_Time__c = val;
        }
        else if(name==='size_of_crew2'){
            this.standDetail.Breakdown_Size_of_Crew__c = val;
        }
        else if(name==='other_stand2'){
            this.standDetail.Breakdown_crew_working_on_other_stands__c = val;
            this.workingOtherStand2 = val==='Yes'?true:false;
        }
        else if(name==='stand_number2'){
            this.standDetail.Breakdown_Please_list_the_Stands_Numbers__c = val;
        }
    };


    @api saveStep6Data(){
        if(this.valid()){
            try{
                this.spinner = true;
                this.standDetail.Current_Step__c = '6';
                if(!this.workingOtherStand1){
                    this.standDetail.Build_list_Stands_Numbers__c = '';
                }
                if(!this.workingOtherStand2){
                    this.standDetail.Breakdown_Please_list_the_Stands_Numbers__c = '';
                }

                saveStandDetail({standDetail:this.standDetail})
                .then(res=>{
                    this.spinner = false;
                    showToast(this,'Step 6:- Stand detail have been update.','success','Success!');
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:7,status:"success"}}));
                })
                .catch(error=>{
                    this.spinner = false;
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:7,status:"error"}}));
                    handleErrors(this,error);
                });
            }
            catch(error){
                this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:7,status:"error"}}));
                console.error(error);
            }
        }
        else{
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:7,status:"error"}}));
            showToast(this,'Please update the invalid form entries and try again.','error','Validation Error');
        }
    };

    valid(){
        const allValid1 = [
            ...this.template.querySelectorAll('lightning-radio-group'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        const allValid2 = [
            ...this.template.querySelectorAll('lightning-combobox'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        const allValid3 = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        
        return allValid1 && allValid2 && allValid3;
    };

    get yesNoOption(){
        return [{label:'Yes',value:'Yes'},{label:'No',value:'No'}];
    };

    get isShowQ1(){
        return !(this.qstListToHide.indexOf(';Crew Onsite Arrival Time;')>=0);
    };
    get isShowQ2(){
        return !(this.qstListToHide.indexOf(';Construction Time (Hours);')>=0);
    };
    get isShowQ3(){
        return !(this.qstListToHide.indexOf(';Size of Crew;')>=0);
    };
    get isShowQ4(){
        return !(this.qstListToHide.indexOf(';Contractor working on other stands;')>=0);
    };
    get isShowQ5(){
        return !(this.qstListToHide.indexOf(';Please list the Stands Numbers;')>=0);
    };
}