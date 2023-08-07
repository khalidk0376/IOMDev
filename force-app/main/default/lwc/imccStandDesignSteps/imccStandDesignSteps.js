import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getExhibitorDetail from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.getExhibitorDetail';
import Go_to_Step from '@salesforce/label/c.Go_to_Step';
import step from '@salesforce/label/c.Step';
import { handleErrors,redirect,isFieldLocked } from 'c/imcc_lwcUtility';
import userId from '@salesforce/user/Id';

//import get
export default class ImccStandDesignSteps extends NavigationMixin(LightningElement) {
    //url param
    cmId; //contract mapping id
    tabId;
    accountId;
    editionCode;
    @api contactormapId;
    @api accId;
    @api eventCode;
    @api byOpsUser;

    //progress step variables
    @track currentStep;
    @track savedStep;    
    steps = [{label: step +' 1', value: '1' },{ label: step +' 2', value: '2', isActive:true },
        { label: step +' 3', value: '3' },{ label: step +' 4', value: '4' },
        { label: step +' 5', value: '5' },{ label: step +' 6', value: '6' },
        { label: step +' 7', value: '7' }];
    
    @track exhDetail;
    @track standDetail;
    @track isNextBtnDisabled;//boolean
    @track isInReview;//boolean
    @track currentStatus;
    @track isTentativeApproval;//boolean
    @track confirmModal;
    @track type;
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.selectedBooth = '';
        
        if (currentPageReference) {
            this.editionCode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            this.cmId = currentPageReference.state.b;
            this.type = currentPageReference.state.type;
            if(this.cmId){
                this.doInit(true);
            }
        }
    }

    //business logic variable
    @api 
    doInit(isSetStep,cs){
        console.log('isSetStep:: '+isSetStep);
        console.log('cs:: '+cs);
        console.log('byOpsUser:: '+this.byOpsUser);
        let isCon = this.type?true:false;
        if(this.byOpsUser){
            this.cmId = this.contactormapId
            this.editionCode = this.eventCode;
            this.accountId = this.accId;
        };
        getExhibitorDetail({cmId:this.cmId,isCon:isCon})
        .then(res=>{
            console.log('res:: '+JSON.stringify(res));
            const result = JSON.parse(JSON.stringify(res));
            const d = JSON.parse(JSON.stringify(result.cmList));
            const pdList = JSON.parse(JSON.stringify(result.listPD));
            d[0].Purchase_Data__c = pdList[0].Id;
            d[0].Purchase_Data__r = pdList[0];
            this.standDetail = result.sdList.length>0?result.sdList[0]:{sobjectType:'Stand_Detail__c'};
            
            this.standDetail.Current_Step__c = this.standDetail  && this.standDetail.Current_Step__c ? this.standDetail.Current_Step__c:'1';

            this.exhDetail = d && d.length>0?d[0]:undefined;
            this.exhDetail.exhibitorName = this.exhDetail.Purchase_Data__r && this.exhDetail.Purchase_Data__r.Contact_Edition_Mapping__r.Account__r?this.exhDetail.Purchase_Data__r.Contact_Edition_Mapping__r.Account__r.Name:'';

            this.currentStatus = this.standDetail.Stand_Detail_Status__c?this.standDetail.Stand_Detail_Status__c:'In Progress';
            
            this.isInReview = isFieldLocked(this.currentStatus);
            if(!this.isInReview && this.exhDetail.Is_Self_Managed__c){
                this.isInReview = false;
            }
            console.log('currentStep0:: '+cs);
            if(isSetStep){
                this.currentStep = this.standDetail?this.standDetail.Current_Step__c:'1';
            }
            else if(cs && !this.isInReview){
                this.currentStep = cs;
            }
            else if(cs==='7'){
                this.currentStep = cs;
            }
            this.savedStep = this.standDetail?this.standDetail.Current_Step__c:'1';
            console.log('currentStep1:: '+this.currentStep);
            if(this.savedStep==='5' && this.currentStatus.toLowerCase()==='tentative approval'){
                this.savedStep='6';
                this.currentStep='6';
            }
            if((this.currentStep==='6' || this.currentStep==='7') && this.currentStatus.toLowerCase()==='tentative approval'){
                this.isTentativeApproval = true;
            }
            console.log('check: '+this.standDetail.CreatedById+'!=='+userId+', '+this.type);
            //if stand detail created by id not match with loggedin user
            if(this.standDetail.CreatedById!==userId && this.type  && !this.exhDetail.Is_Self_Managed__c){
                this.isInReview = true;
                this.isTentativeApproval = false;
            }

            console.log('currentStep2:: '+this.currentStep);
        })
        .catch(e=>{
            handleErrors(this,e);
        })
    }

    handleStepChange(event){
        
        let selectedStep = parseInt(event.target.value,10);
        //disable click while saving step data
        if(this.isInReview && this.currentStatus.toLowerCase()!='tentative approval' && this.currentStatus.toLowerCase()!='permission to build' && selectedStep>5){
            return false;
        }
        if(!this.isNextBtnDisabled && this.savedStep >= selectedStep){            
            this.currentStep = event.target.value+'';            
            console.log(event.target.value);
        }
        else{
            return false;
        }
    }

    //progress bar navigation
    saveCurrentStepData(event){
        console.log('this.currentStatus11==='+ this.currentStatus);
        let stepcount = parseInt(this.currentStep,10);
        if(stepcount===1){
            this.isNextBtnDisabled = true;
            this.template.querySelector('c-imcc-stand-design-step1').saveStep1Data();
        }
        else if(stepcount===2){
            this.isNextBtnDisabled = true;
            this.template.querySelector('c-imcc-stand-design-step2').saveStep2Data();
        }
        else if(stepcount===3){
            this.isNextBtnDisabled = true;
            this.template.querySelector('c-imcc-stand-design-step3').saveStep3Data();
        }
        else if(stepcount===4){
            this.isNextBtnDisabled = true;
            this.template.querySelector('c-imcc-stand-design-step4').saveStep4Data();
        }
        else if(stepcount===5 && 'pending sales approval,pending venue approval,tentative approval,permission to build'.indexOf(this.currentStatus.toLowerCase())<0){
            console.log('this.currentStatus22==='+ this.currentStatus); 
            this.confirmModal = true;            
        }
        else if(stepcount===5 && 'pending sales approval,pending venue approval,tentative approval,permission to build'.indexOf(this.currentStatus.toLowerCase())>=0){
            this.currentStep = '6';    
            this.savedStep = '6';        
        }
        else if(stepcount===6){
            this.isNextBtnDisabled = true;
            this.template.querySelector('c-imcc-stand-design-step6').saveStep6Data();
        }
        else if(stepcount===7){
            this.isNextBtnDisabled = true;
            this.template.querySelector('c-imcc-stand-design-step7').saveStep7Data();
        }
    };

    closeConfirmModal(){
        this.confirmModal = false;
    };

    submitForApproval(){
        this.confirmModal = false;
        this.isNextBtnDisabled = true;
        this.template.querySelector('c-imcc-stand-design-step5').saveStep5Data();
    }

    gotoNextStep(event){
        this.isNextBtnDisabled = false;
        const obj = event.detail;
        console.log('currentStep:'+obj.nextStep);
        if(obj.status==='success' && obj.nextStep<8){            
            this.doInit(false,obj.nextStep+'');
            this.scrollOnTop();
        }
        else if(obj.status==='success' && obj.nextStep===8){
            if(this.byOpsUser){
                this.dispatchEvent(new CustomEvent('closestandpages'));
            }
            else{
                if(this.isCon){
                    this.redirect('StandDesign__c',{"accId":this.accountId,"edcode":this.editionCode,"tabId":this.tabId});
                }
               else{
                this.redirect('StandContractors__c',{"accId":this.accountId,"edcode":this.editionCode,"tabId":this.tabId});
               }
            }
        }
    }

    backStep(){
        let stepcount = parseInt(this.currentStep,10);
        if(stepcount===1){
            //do nothing
        }
        else if(stepcount>1){
            stepcount = stepcount - 1;
            this.currentStep = stepcount+'';
        }
        this.scrollOnTop();
        console.log('currentStep: '+this.currentStep)
    }

    scrollOnTop(){
        const scrollOptions = {left: 0,top: 362,behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
    }

    //Get current step to show active step component 
    get isStep1(){
        return this.exhDetail && this.currentStep === '1';
    };

    get isStep2(){
        return this.exhDetail && this.standDetail && this.standDetail.Id && this.currentStep === '2';
    };

    get isStep3(){
        return this.exhDetail && this.currentStep === '3';
    };

    get isStep4(){
        return this.exhDetail && this.currentStep === '4';
    };

    get isStep5(){
        return this.exhDetail && this.currentStep === '5';
    };

    get isStep6(){
        return this.exhDetail && this.currentStep === '6';
    };

    get isStep7(){
        return this.exhDetail && this.currentStep === '7';
    };

    get currentButtonLabel(){
        let label = '';
        if(this.currentStep==='5' && this.currentStatus!='Tentative Approval'){
            label = 'Submit For Approval';
        }
        else if(this.currentStep==='7'){
            label = 'Submit';
        }
        else{
            label = Go_to_Step + ' '+(this.currentStep?parseInt(this.currentStep)+1:'1');
        }
        return label;
    }

    //community navigation
    redirect(pageName, paramObj) {
        redirect(this, NavigationMixin.Navigate, pageName, paramObj);
    };

    backToStandSubmissionPage(){
        this.dispatchEvent(new CustomEvent('closestandpages'));
    }
}