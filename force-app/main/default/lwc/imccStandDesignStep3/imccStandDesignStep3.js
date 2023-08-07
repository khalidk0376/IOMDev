import { api, LightningElement, track, wire } from 'lwc';
import { getPicklistValuesByRecordType,getObjectInfo } from 'lightning/uiObjectInfoApi';
//apex action
import saveStandDetail from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.saveStandDetail';
import StandDetail_OBJECT from '@salesforce/schema/Stand_Detail__c';
import userId from '@salesforce/user/Id';
import { handleErrors, showToast,isFieldLocked} from 'c/imcc_lwcUtility';

export default class ImccStandDesignStep3 extends LightningElement {
    @api standDetails;
    @api detailObj;
    @api type;
    
    @track spinner;
    @track openSideOption;
    @track riggingOpttion;
    @track hangingStruOption;
    @track showRigging;
    @track isFrameAndFabric;
    @track standDetail;
    @track selectedStandHight='';
    @track selectedStandHightDecimal='.0';

    @wire(getObjectInfo, { objectApiName: StandDetail_OBJECT })
    standDetailObject;

    @wire(getPicklistValuesByRecordType, {objectApiName:StandDetail_OBJECT, recordTypeId: '$standDetailObject.data.defaultRecordTypeId'})
    wiredata(result,error){
        if(result){
            console.log('result'+JSON.stringify(result));
            const obj = JSON.parse(JSON.stringify(result));            
            if(obj.data){
                this.openSideOption = obj.data.picklistFieldValues.Open_Side__c?.values;
                this.riggingOpttion = obj.data.picklistFieldValues.Type_of_rigging__c.values;
                this.hangingStruOption = obj.data.picklistFieldValues.Are_any_other_hanging_structure__c.values;
            }
        }
        else if(error){
            console.error(error);
        }
    };    

    @track shandHeightOptions;
    @track shandHeightDecimalOptions;
    @track isInReview;
    @track qstListToHide = '';
    @track unit;
    connectedCallback(){
        this.standDetail = JSON.parse(JSON.stringify(this.standDetails));
        let status = this.standDetail.Stand_Detail_Status__c?this.standDetail.Stand_Detail_Status__c:'In Progress';
        this.isInReview = isFieldLocked(status);
        if(!this.isInReview && this.detailObj.Is_Self_Managed__c){
            this.isInReview = false;
        }
        if(status==='Stand Design Rejected/Incomplete'){
            let rejectedSteps = this.standDetail.Rejected_Steps__c?this.standDetail.Rejected_Steps__c:'';
            if(rejectedSteps.indexOf('Step 3')>=0){
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

        let standHeight = this.standDetail.Stand_Height__c?this.standDetail.Stand_Height__c+'':'';
        this.selectedStandHight = standHeight.split('.')[0];
        if(standHeight.split('.').length>1){
            this.selectedStandHightDecimal = '.'+standHeight.split('.')[1];
        }
        
        this.unit = this.detailObj.Edition__r.Stand_Setting__r.Unit_of_measurement__c?this.detailObj.Edition__r.Stand_Setting__r.Unit_of_measurement__c:'m';
        //set variable to show/hide rigging dropdown (Are you planning on including rigging in the design?)
        this.showRigging = this.standDetail.Including_rigging_in_the_design__c === 'Yes' ? true : false;
        
        let standHeightOpt = [];
        let sh = this.detailObj.Edition__r.Stand_Setting__r.Maximum_Stand_Height__c?this.detailObj.Edition__r.Stand_Setting__r.Maximum_Stand_Height__c:0;
        for(let i=0;i<=sh;i++){
            standHeightOpt.push({label:i+this.unit,value:i+''});
        }
        this.shandHeightOptions = standHeightOpt;

        let standHeightDecimalOpt = [];        
        for(let i=0;i<=9;i++){
            standHeightDecimalOpt.push({label:'.'+i+this.unit,value:'.'+i});
        }
        this.shandHeightDecimalOptions = standHeightDecimalOpt;

        this.standDetail.Sustainable_frame_and_fabric__c = this.standDetail.Sustainable_frame_and_fabric__c?this.standDetail.Sustainable_frame_and_fabric__c:'';
        this.isFrameAndFabric = this.standDetail.Sustainable_frame_and_fabric__c==='Yes'?true:false;

        //cast percent to string
        this.standDetail.MDF_Panels_or_similar__c = this.standDetail.MDF_Panels_or_similar__c?this.standDetail.MDF_Panels_or_similar__c+'':'0';
        this.standDetail.Reusable_Materials__c = this.standDetail.Reusable_Materials__c?this.standDetail.Reusable_Materials__c+'':'0';
        this.standDetail.Raw_Materials__c = this.standDetail.Raw_Materials__c?this.standDetail.Raw_Materials__c+'':'0';
        this.standDetail.Prefabricated_Offsite__c = this.standDetail.Prefabricated_Offsite__c?this.standDetail.Prefabricated_Offsite__c+'':'0';            
    };
    
    handleChange(event){
        try{
            let name = event.target.name;
            let val = event.target.value;
            if(name==='openside'){
                this.standDetail.Open_Side__c = val;
            }
            else if(name==='shinteger'){
                this.selectedStandHight = val;
            }
            else if(name==='shdecimal'){
                this.selectedStandHightDecimal = val;
            }
            else if(name==='riggingtype'){
                this.standDetail.Type_of_rigging__c = val;
            }
            else if(name==='hangingstructure'){
                this.standDetail.Are_any_other_hanging_structure__c = val;
            }            
            else if(name==='isfabric'){
                this.standDetail.Sustainable_frame_and_fabric__c = val;
                this.isFrameAndFabric = this.standDetail.Sustainable_frame_and_fabric__c==='Yes'?true:false;
            }
            else if(name==='doubledecker'){
                this.standDetail.Double_Decker__c = val;
            }
            else if(name==='riggingindesign'){
                this.standDetail.Including_rigging_in_the_design__c = val;
                this.showRigging = val === 'Yes' ? true : false;           
            }
            else if(name==='radio4'){
                this.standDetail.Incorporate_any_water_feature__c = val;
            }
            else if(name==='radio5'){
                this.standDetail.Build_a_food_preparation_area__c = val;
            }
            else if(name==='radio6'){
                this.standDetail.Dose_design_include_glass_walls__c = val;
            }
            else if(name==='radio7'){
                this.standDetail.Over_600mm_within_the_design__c = val;
            }
            else if(name==='radio8'){
                this.standDetail.Staircases_built_into_the_design__c = val;
            }
            else if(name==='radio9'){
                this.standDetail.Require_high_value_product_storage__c = val;
            }
            else if(name==='mdfpanel'){
                this.standDetail.MDF_Panels_or_similar__c = val;
            }
            else if(name==='rawmaterial'){
                this.standDetail.Raw_Materials__c = val;
            }
            else if(name==='reusablematerial'){
                this.standDetail.Reusable_Materials__c = val;
            }
            else if(name==='prefabricated'){
                this.standDetail.Prefabricated_Offsite__c = val;
            }
            else if(name==='material1'){
                this.standDetail.LED_Lighting__c = val;
            }
            else if(name==='material2'){
                this.standDetail.Flame_retarded_material__c = val;
            }
            else if(name==='heavymachine1'){
                this.standDetail.Heavy_machinery_equipment_lift_require__c = val;
            }
            else if(name==='heavymachine2'){
                this.standDetail.Large_machinery_on_the_stand_area__c = val;
            }
            else if(name==='heavymachine3'){
                this.standDetail.Display_vehicles_requirement_on_stand__c = val;
            }
        }
        catch(error){
            console.error(error);
        }
    };

    @api saveStep3Data(){
        if(this.isInReview){
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:4,status:"success"}}));
            return false;
        }
        //validate stand height
        this.standDetail.Stand_Height__c = parseFloat(this.selectedStandHight+this.selectedStandHightDecimal,10);
        let sh = this.detailObj.Edition__r.Stand_Setting__r.Maximum_Stand_Height__c?this.detailObj.Edition__r.Stand_Setting__r.Maximum_Stand_Height__c:0;
        //alert(this.standDetail.Stand_Height__c+'@@'+sh);
        if(this.standDetail.Stand_Height__c > sh){
            showToast(this,'Stand Height should be less than or equal to '+sh+' '+this.unit,'error','Validation Error');
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:4,status:"error"}}));
            return false;
        }

        if(this.valid()){
            try{
                this.spinner = true;
                //set empty value if No option selected for rigging in design
                if(!this.showRigging){
                    this.standDetail.Type_of_rigging__c = '';
                    this.standDetail.Are_any_other_hanging_structure__c = '';
                }
                if(this.isFrameAndFabric){
                    this.standDetail.Double_Decker__c='';
                }
                
                //check is complex structure
                if(this.standDetail.Double_Decker__c==='Yes' || this.standDetail.Including_rigging_in_the_design__c==='Yes' || this.standDetail.Over_600mm_within_the_design__c==='Yes'){
                    this.standDetail.Is_Complex_Structure__c = 'Yes';
                }
                else{
                    this.standDetail.Is_Complex_Structure__c = 'No';
                }

                this.standDetail.Stand_Height__c = parseFloat(this.selectedStandHight+this.selectedStandHightDecimal,10);

                this.standDetail.MDF_Panels_or_similar__c = this.standDetail.MDF_Panels_or_similar__c?parseInt(this.standDetail.MDF_Panels_or_similar__c,10):0;
                this.standDetail.Reusable_Materials__c = this.standDetail.Reusable_Materials__c?parseInt(this.standDetail.Reusable_Materials__c,10):0;
                this.standDetail.Raw_Materials__c = this.standDetail.Raw_Materials__c?parseInt(this.standDetail.Raw_Materials__c,10):0;
                this.standDetail.Prefabricated_Offsite__c = this.standDetail.Prefabricated_Offsite__c?parseInt(this.standDetail.Prefabricated_Offsite__c,10):0;

                console.log('Test: '+this.standDetail.MDF_Panels_or_similar__c);
                this.standDetail.Current_Step__c = '3';
                //this.standDetail.Stand_Detail_Status__c='In Progress';
                saveStandDetail({standDetail:this.standDetail})
                .then(res=>{
                    this.spinner = false;
                    showToast(this,'Step 3:- Stand detail have been update.','success','Success!');
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:4,status:"success"}}));
                })
                .catch(error=>{
                    this.spinner = false;
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:4,status:"error"}}));
                    handleErrors(this,error);
                });
            }
            catch(error){
                this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:4,status:"error"}}));
                console.error(error);
            }
        }
        else{
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:4,status:"error"}}));
            showToast(this,'Please update the invalid form entries and try again.','error','Validation Error');
        }
    };

    valid(){
        const allValid = [
            ...this.template.querySelectorAll('lightning-combobox'),
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
    };

    get yesNoOption(){
        return [{label:'Yes',value:'Yes'},{label:'No',value:'No'}];
    };

    get percentOpt(){
        return [
            {label:'0%',value:'0'},
            {label:'10%',value:'10'},
            {label:'20%',value:'20'},
            {label:'30%',value:'30'},
            {label:'40%',value:'40'},
            {label:'50%',value:'50'},
            {label:'60%',value:'60'},
            {label:'70%',value:'70'},
            {label:'80%',value:'80'},
            {label:'90%',value:'90'},
            {label:'100%',value:'100'}
        ]
    };

    //Hide/Show question logic
    get isShowQ1(){
        return !(this.qstListToHide.indexOf(';Stand Number;')>=0);
    };
    get isShowQ2(){
        return !(this.qstListToHide.indexOf(';Step 3 - Dimensions;')>=0);
    };
    get isShowQ3(){
        return !(this.qstListToHide.indexOf(';Step 3 - Area;')>=0);
    };
    get isShowQ4(){
        return !(this.qstListToHide.indexOf(';Number of open sides?;')>=0);
    };
    get isShowQ5(){
        return !(this.qstListToHide.indexOf(';Sustainable Stand;')>=0);
    };
    get isShowQ6(){
        return !(this.qstListToHide.indexOf(';Double Decker Stand;')>=0);
    };
    get isShowQ7(){
        return !(this.qstListToHide.indexOf(';Include rigging in the design;')>=0);
    };
    get isShowQ8(){
        return !(this.qstListToHide.indexOf(';Type of rigging;')>=0);
    };
    get isShowQ9(){
        return !(this.qstListToHide.indexOf(';Other Hanging Structure;')>=0);
    };
    get isShowQ10(){
        return !(this.qstListToHide.indexOf(';Stand Height?;')>=0);
    };
    get isShowQ11(){
        return !(this.qstListToHide.indexOf(';Water Feature;')>=0);
    };
    get isShowQ12(){
        return !(this.qstListToHide.indexOf(';Food preparation area;')>=0);
    };
    get isShowQ13(){
        return !(this.qstListToHide.indexOf(';Glass walls;')>=0);
    };
    get isShowQ14(){
        return !(this.qstListToHide.indexOf(';Platform over 600mm;')>=0);
    };
    get isShowQ15(){
        return !(this.qstListToHide.indexOf(';Staircases;')>=0);
    };
    get isShowQ16(){
        return !(this.qstListToHide.indexOf(';High value product storage;')>=0);
    };
    get isShowQ17(){
        return !(this.qstListToHide.indexOf(';MDF Panels or similar?;')>=0);
    };
    get isShowQ18(){
        return !(this.qstListToHide.indexOf(';Reusable Materials?;')>=0);
    };
    get isShowQ19(){
        return !(this.qstListToHide.indexOf(';LED Lighting?')>=0);
    };
    get isShowQ20(){
        return !(this.qstListToHide.indexOf(';Raw Materials (others)')>=0);
    };
    get isShowQ21(){
        return !(this.qstListToHide.indexOf(';Prefabricated (Offsite)')>=0);
    };
    get isShowQ22(){
        return !(this.qstListToHide.indexOf(';Flame retarded material;')>=0);
    };
    get isShowQ23(){
        return !(this.qstListToHide.indexOf(';Heavy machinery/equipment lift required;')>=0);
    };
    get isShowQ24(){
        return !(this.qstListToHide.indexOf(';Include Large machinery/equipment;')>=0);
    };
    get isShowQ25(){
        return !(this.qstListToHide.indexOf(';Include Display vehicles/Craft;')>=0);
    };

    get isShowMachine(){
        return (this.isShowQ23 || this.isShowQ24 || this.isShowQ25);
    }
}