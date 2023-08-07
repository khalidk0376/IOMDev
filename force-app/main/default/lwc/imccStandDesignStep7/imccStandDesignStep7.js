import { api, LightningElement, track } from 'lwc';
import saveStandDetail from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.saveStandDetail';
import saveSign from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.saveSignature';

import { handleErrors, showToast} from 'c/imcc_lwcUtility';
import userId from '@salesforce/user/Id';

//get custom labels
import Step_7_1_L from '@salesforce/label/c.Step_7_1';
import Step7_Top_Header from '@salesforce/label/c.Step7_Top_Header';
import Step7_Top_Header_and from '@salesforce/label/c.Step7_Top_Header_and';
import Step7_Top_Header2 from '@salesforce/label/c.Step7_Top_Header2';

import IT_IS_AGREED_AS_FOLLOWS_L from '@salesforce/label/c.IT_IS_AGREED_AS_FOLLOWS';
import Agree_As_Follow_1 from '@salesforce/label/c.Agree_As_Follow_1';
import Agree_As_Follow_2 from '@salesforce/label/c.Agree_As_Follow_2';
import Agree_As_Follow_2_a from '@salesforce/label/c.Agree_As_Follow_2_a';
import Agree_As_Follow_2_b from '@salesforce/label/c.Agree_As_Follow_2_b';
import Agree_As_Follow_2_c from '@salesforce/label/c.Agree_As_Follow_2_c';
import Agree_As_Follow_2_d from '@salesforce/label/c.Agree_As_Follow_2_d';
import Agree_As_Follow_2_e from '@salesforce/label/c.Agree_As_Follow_2_e';
import Agree_As_Follow_2_f from '@salesforce/label/c.Agree_As_Follow_2_f';
import Agree_As_Follow_2_g from '@salesforce/label/c.Agree_As_Follow_2_g';
import Agree_As_Follow_3 from '@salesforce/label/c.Agree_As_Follow_3';
import Agree_As_Follow_4 from '@salesforce/label/c.Agree_As_Follow_4';
import Agree_As_Follow_5 from '@salesforce/label/c.Agree_As_Follow_5';
import Agree_As_Follow_6 from '@salesforce/label/c.Agree_As_Follow_6';
import This_Agreement_is_accepted from '@salesforce/label/c.This_Agreement_is_accepted';

//signature variables
let isDownFlag,
isDotFlag = false,
prevX = 0,
currX = 0,
prevY = 0,
currY = 0;

let x = "#0000A0"; //blue color
let y = 1.5; //weight of line width and dot.

let canvasElement, ctx; //storing canvas context
let dataURL,convertedDataURI; //holds image data

export default class ImccStandDesignStep7 extends LightningElement {
    @api standDetails;
    @api cm; //contract mapping
    @api type;

    @track spinner;
    @track standDetail;
    @track isOpenSignModal;
    @track docId;
    @track docUrl = '';
    @track isInReview;
    @track byOpsUser = false;

    //custom label variable
    Step_7_1_Label = Step_7_1_L;
    Step7_Top_HeaderLabel = Step7_Top_Header;
    Step7_Top_Header_andLabel = Step7_Top_Header_and;
    Step7_Top_Header2Label = Step7_Top_Header2;
    IT_IS_AGREED_AS_FOLLOWS_Label  = IT_IS_AGREED_AS_FOLLOWS_L;
    Agree_As_Follow_1Label = Agree_As_Follow_1;
    Agree_As_Follow_2Label = Agree_As_Follow_2;
    Agree_As_Follow_3Label = Agree_As_Follow_3;
    Agree_As_Follow_4Label = Agree_As_Follow_4;
    Agree_As_Follow_5Label = Agree_As_Follow_5;
    Agree_As_Follow_6Label = Agree_As_Follow_6;
    Agree_As_Follow_2_aLabel = Agree_As_Follow_2_a;
    Agree_As_Follow_2_bLabel = Agree_As_Follow_2_b;
    Agree_As_Follow_2_cLabel = Agree_As_Follow_2_c;
    Agree_As_Follow_2_dLabel = Agree_As_Follow_2_d;
    Agree_As_Follow_2_eLabel = Agree_As_Follow_2_e;
    Agree_As_Follow_2_fLabel = Agree_As_Follow_2_f;
    Agree_As_Follow_2_gLabel = Agree_As_Follow_2_g;
    This_Agreement_is_acceptedLabel = This_Agreement_is_accepted;        

    @track qstListToHide='';

    connectedCallback(){
        if(!window.location.href.includes('IMCC')){
            this.byOpsUser = true;
        }
        let companyName = this.cm.exhibitorName;
        let editionName = this.cm.Edition__r?this.cm.Edition__r.Name:'';
        this.Step_7_1_Label = this.Step_7_1_Label.replace('[EXHIBITOR LEGAL ENTITY NAME]','['+companyName+']');
        this.Step_7_1_Label = this.Step_7_1_Label.replace('[NAME OF EVENT]','['+editionName+']');

        this.standDetail = JSON.parse(JSON.stringify(this.standDetails));
        this.standDetail.Signature_ContentId__c = this.standDetail.Signature_ContentId__c?this.standDetail.Signature_ContentId__c:'';

        this.docId = this.standDetail.Signature_ContentId__c?this.standDetail.Signature_ContentId__c:'';
        if(this.byOpsUser){
            this.docUrl = '/servlet/servlet.FileDownload?file='+this.docId; 
        }
        else{
            this.docUrl = '../servlet/servlet.FileDownload?file='+this.docId;         
        }
        
        let status = this.standDetail.Stand_Detail_Status__c?this.standDetail.Stand_Detail_Status__c:'In Progress';
        this.isInReview = status.toLowerCase()==='permission to build';
        if(!this.isInReview && this.cm.Is_Self_Managed__c){
            this.isInReview = false;
        }
        //read view for other contractor
        if(this.standDetail.CreatedById!==userId && this.type && !this.cm.Is_Self_Managed__c){
            this.isInReview = true;
        }

        this.qstListToHide = this.cm.Edition__r.Stand_Setting__r && this.cm.Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c?this.cm.Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c:'';
        this.qstListToHide = ';'+this.qstListToHide+';';
    };

    //event listeners added for drawing the signature within shadow boundary
    doInit() {        
        this.template.addEventListener('mousemove', this.handleMouseMove.bind(this));
        this.template.addEventListener('mousedown', this.handleMouseDown.bind(this));
        this.template.addEventListener('mouseup', this.handleMouseUp.bind(this));
        this.template.addEventListener('mouseout', this.handleMouseOut.bind(this));
    };

    unbind(){
        this.template.removeEventListener('mousemove', this.handleMouseMove.bind(this));
        this.template.removeEventListener('mousedown', this.handleMouseDown.bind(this));
        this.template.removeEventListener('mouseup', this.handleMouseUp.bind(this));
        this.template.removeEventListener('mouseout', this.handleMouseOut.bind(this));
    };

    //retrieve canvase and context
    renderedCallback(){
        canvasElement = this.template.querySelector('canvas');
        if(canvasElement){            
            ctx = canvasElement.getContext("2d");
        }
    };

    //handler for mouse move operation
    handleMouseMove(event){
        this.searchCoordinatesForEvent('move', event);
    };

    //handler for mouse down operation
    handleMouseDown(event){
        this.searchCoordinatesForEvent('down', event);
    };

    //handler for mouse up operation
    handleMouseUp(event){
        this.searchCoordinatesForEvent('up', event);
    };

    //handler for mouse out operation
    handleMouseOut(event){
        this.searchCoordinatesForEvent('out', event);
    };
    
    openModal(){
        this.isOpenSignModal = true; 
        this.doInit();       
    };

    closeModal(){
        this.unbind();
        this.isOpenSignModal = false;
    };

    handleChange(event){
        let name = event.target.name;
        let val = event.target.value;
        
        if(name==='Print_Name'){
            this.standDetail.Print_Name__c = val;
        }
        else if(name==='Job_Title'){
            this.standDetail.Job_Title__c = val;
        }
        else if(name==='Date'){
            this.standDetail.Date__c = val;
        }        
    };

    @api saveStep7Data(){
        if(this.standDetail.Signature_ContentId__c===''){
            showToast(this,'Signature field is required, please sign before submit stand detail.','error','Signature Required');
            return false;
        }

        if(this.valid()){
            try{
                this.spinner = true;
                this.standDetail.Current_Step__c = '7';                
                this.standDetail.Stand_Detail_Status__c = 'Permission to Build';                
                saveStandDetail({standDetail:this.standDetail})
                .then(res=>{
                    this.spinner = false;
                    showToast(this,'Step 7:- Stand detail have been update.','success','Success!');                    
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:8,status:"success"}}));
                })
                .catch(error=>{
                    this.spinner = false;
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:8,status:"error"}}));
                    handleErrors(this,error);
                });
            }
            catch(error){
                this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:8,status:"error"}}));
                console.error(error);
            }
        }
        else{
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:8,status:"error"}}));
            showToast(this,'Please update the invalid form entries and try again.','error','Validation Error');
        }
    };

    valid(){
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        return allValid;
    };

    searchCoordinatesForEvent(requestedEvent, event){
        event.preventDefault();
        if (requestedEvent === 'down') {
            this.setupCoordinate(event);
            isDownFlag = true;
            isDotFlag = true;
            if (isDotFlag) {
                this.drawDot();
                isDotFlag = false;
            }
        }
        if (requestedEvent === 'up' || requestedEvent === "out") {
            isDownFlag = false;
        }
        if (requestedEvent === 'move') {
            if (isDownFlag) {
                this.setupCoordinate(event);
                this.redraw();
            }
        }
    };

    setupCoordinate(eventParam){
        const clientRect = canvasElement.getBoundingClientRect();
        prevX = currX;
        prevY = currY;
        currX = eventParam.clientX -  clientRect.left;
        currY = eventParam.clientY - clientRect.top;
    };

    redraw() {
        ctx.beginPath();
        ctx.moveTo(prevX, prevY);
        ctx.lineTo(currX, currY);
        ctx.strokeStyle = x; //sets the color, gradient and pattern of stroke
        ctx.lineWidth = y;
        ctx.closePath(); //create a path from current point to starting point
        ctx.stroke(); //draws the path
    };

    //this draws the dot
    drawDot(){
        ctx.beginPath();
        ctx.fillStyle = x; //blue color
        ctx.fillRect(currX, currY, y, y); //fill rectrangle with coordinates
        ctx.closePath();
    };

    erase(){
        ctx.clearRect(0, 0, canvasElement.width, canvasElement.height);
    };

    saveSignatureModal(){
        //set to draw behind current content
        ctx.globalCompositeOperation = "destination-over";
        ctx.fillStyle = "#FFF"; //white
        ctx.fillRect(0,0,canvasElement.width, canvasElement.height);

        //convert to png image as dataURL
        dataURL = canvasElement.toDataURL("image/png");
        //convert that as base64 encoding
        convertedDataURI = dataURL.replace(/^data:image\/(png|jpg);base64,/, "");
        this.ContentVersionData = convertedDataURI;
        //call Apex method imperatively and use promise for handling sucess & failure
        this.spinner = true;
        saveSign({
            contentVersionData: convertedDataURI,
            recordId : this.standDetail.Id
        })
        .then(result => {
            this.docId='';
            this.closeModal();
            this.docId = result;
            if(this.byOpsUser){
                this.docUrl = '/servlet/servlet.FileDownload?file='+this.docId; 
            }
            else{
                this.docUrl = '../servlet/servlet.FileDownload?file='+this.docId;         
            }
            this.standDetail.Signature_ContentId__c = this.docId;
            showToast(this,'Signature was save.','success','Success');
        })
        .catch(error => {
            handleErrors(this,error);
        })
        .finally(() => {
            this.spinner = false;
        });
    };

    handleClick(event){
        event.stopPropagation();
        event.target.focus();
    };

    handleClick2(event){
        event.stopPropagation();
        event.currentTarget.focus();
    };

    get isShowQ1(){
        return !(this.qstListToHide.indexOf(';Step7 - Print Name;')>=0);
    };

    get isShowQ2(){
        return !(this.qstListToHide.indexOf(';Step7 - Job Title;')>=0);
    };

    get isShowQ3(){
        return !(this.qstListToHide.indexOf(';Step7 - Date;')>=0);
    };

    get isShowQ4(){
        return !(this.qstListToHide.indexOf(';Step7 - Signature;')>=0);
    };
}