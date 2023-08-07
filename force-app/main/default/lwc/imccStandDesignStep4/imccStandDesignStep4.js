import { api, LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
//apex action
import saveStandDetail from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.saveStandDetail';
import updateDocumentName from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.updateDocumentName';
import getStandFileTypes from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.getStandFileTypes';
import getFiles from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.getFiles';
import deleteFile from '@salesforce/apex/IMCC_StandDesignSubmissionCtrl.deleteFile';
import { handleErrors, showToast,isFieldLocked} from 'c/imcc_lwcUtility';
import fileDownloadUrl from '@salesforce/label/c.File_Download_URL';
import userId from '@salesforce/user/Id';

export default class ImccStandDesignStep4 extends NavigationMixin(LightningElement) {
    @api cm;//contractor mapping
    @api standDetails;
    @api type;

    @track infoLabel = '';
    @track standDetail;
    @track attType;
    @track fileTypes;
    @track isFileFound;
    @track isAllFileUploaded;
    @track selectedDocId;
    @track spinner;
    @track isInReview;
    @track qstListToHide = '';
    connectedCallback(){        

        let standSetting = JSON.parse(JSON.stringify(this.cm.Edition__r.Stand_Setting__r)); 
        this.standDetail = JSON.parse(JSON.stringify(this.standDetails));
        
        this.qstListToHide = this.cm.Edition__r.Stand_Setting__r && this.cm.Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c?this.cm.Edition__r.Stand_Setting__r.Hide_Stand_Design_Questions__c:'';
        this.qstListToHide = ';'+this.qstListToHide+';';

        let status = this.standDetail.Stand_Detail_Status__c?this.standDetail.Stand_Detail_Status__c:'In Progress';
        this.isInReview = isFieldLocked(status);
        if(!this.isInReview && this.cm.Is_Self_Managed__c){
            this.isInReview = false;
        }
        if(status==='Stand Design Rejected/Incomplete'){
            let rejectedSteps = this.standDetail.Rejected_Steps__c?this.standDetail.Rejected_Steps__c:'';
            if(rejectedSteps.indexOf('Step 4')>=0){
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

        this.infoLabel = this.cm.Edition__r.Stand_Setting__r.Non_Complex_Stand_Instructions__c;
        let type='Non Complex';
        if(this.standDetail.Is_Complex_Structure__c==='Yes'){
            type = 'Complex';
            this.infoLabel = this.cm.Edition__r.Stand_Setting__r.Complex_Stand_Instructions__c;            
        }
        const tempData = [];

        getStandFileTypes({standSettingId:this.cm.Edition__r.Stand_Setting__c,type:type})
        .then(res=>{
            console.log('data: '+res);
            for(let i=0;i<res.length;i++){
                tempData.push({label:res[i].Name,value:res[i].Name,id:'upload-'+i});
            }
            this.fileTypes = tempData;
        })
        .catch(error=>{
            handleErrors(this,error);
        });
        //get files and merge in type
        this.getUploadedFiles();        
    };

    handleChange(event){            
        this.standDetail.Uploaded_Document_Description__c = event.target.value;            
    };

    @api saveStep4Data(){
        if(this.isInReview){
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:5,status:"success"}}));
            return false;
        }

        if(!this.isAllFileUploaded){
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:5,status:"error"}}));
            showToast(this,'Please upload document for each type.','error','Document Validation Error');
            return false;
        }

        if(this.valid()){
            try{
                this.spinner = true;
                this.standDetail.Current_Step__c = '4';
                //this.standDetail.Stand_Detail_Status__c='In Progress';
                saveStandDetail({standDetail:this.standDetail})
                .then(res=>{
                    this.spinner = false;
                    showToast(this,'Step 4:- Stand detail have been update.','success','Success!');
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:5,status:"success"}}));
                })
                .catch(error=>{
                    this.spinner = false;
                    this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:5,status:"error"}}));
                    handleErrors(this,error);
                });
            }
            catch(error){
                this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:5,status:"error"}}));
                console.error(error);
            }
        }
        else{
            this.dispatchEvent(new CustomEvent('aftersave',{detail:{nextStep:5,status:"error"}}));
            showToast(this,'Please update the invalid form entries and try again.','error','Validation Error');
        }
    };

    valid(){
        let allValid = true;
        /*if(this.isShowQ1){
            allValid = [
                ...this.template.querySelectorAll('lightning-textarea'),
            ].reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        }*/
        return allValid;
    };

    currentType;
    chooseFile(event){
        this.currentType = event.currentTarget.dataset.type;        
    };

    handleUploadFinished(event) {
        // Get the list of uploaded files
        console.log(JSON.stringify(event.detail));
        const uploadedFiles = event.detail.files;        
        console.log(JSON.stringify(uploadedFiles[0]));
        let boothNo = this.cm.Purchase_Data__r.Booth_Number__c;
        let exhibitor = this.cm.exhibitorName;
        updateDocumentName({
            docId:uploadedFiles[0].documentId,
            fileName:boothNo+'_'+exhibitor+'_'+this.currentType,
            parentId:this.standDetail.Id
        })
        .then(res=>{
            this.currentType = '';
            this.addFileForType(res);
        })
        .catch(error=>{
            handleErrors(this,error);
        });
        console.log('No. of files uploaded : ' + uploadedFiles.length);
    };

    getUploadedFiles(){
        getFiles({parentId:this.standDetail.Id})
        .then(res=>{
            console.log('Files: '+JSON.stringify(res));
            this.addFileForType(res);
        })
        .catch(error=>{
            handleErrors(this,error);
        });
    };

    addFileForType(res){
        const files = JSON.parse(JSON.stringify(res));
        const oldData = JSON.parse(JSON.stringify(this.fileTypes));
        oldData.forEach(item=>{
            //console.log(item.value);
            item.child = files.filter(i=> {return i.ContentDocument.Title.indexOf(item.value)>=0;});
        });
        console.log(oldData);
        this.fileTypes = oldData;
        this.checkIsFileFound();
    };

    checkIsFileFound(){
        this.isAllFileUploaded = true;
        this.standDetail.Is_Required_Document_Uploaded__c = true;
        this.isFileFound = false;
        const oldData = JSON.parse(JSON.stringify(this.fileTypes));
        oldData.forEach(item=>{
            if(item.child && item.child.length>0){
                this.isFileFound = true;
            }
            else{
                this.isAllFileUploaded = false;
                this.standDetail.Is_Required_Document_Uploaded__c = false;
            }
        });
        console.log(JSON.stringify(oldData))        
    };
    
    handleDelete(event){        
        this.selectedDocId = event.target.dataset.docId;                
    };

    yesDelete(){
        this.spinner = true;
        deleteFile({parentId: this.standDetail.Id,documentId:this.selectedDocId})
        .then(res=>{
            this.spinner = false;
            this.selectedDocId = '';
            this.addFileForType(res);           
        })
        .catch(error=>{
            this.spinner = false;
            handleErrors(this,error);
        })
    };

    noDelete(){
        this.selectedDocId = '';
    };
    
    closeModal(){
        this.showPdf = '';
    };
    @track showPdf;
    handleDocPreview(event){
        this.showPdf = fileDownloadUrl+event.target.dataset.docId;       
    };

    get yesNoOption(){
        return [{label:'Yes',value:'Yes'},{label:'No',value:'No'}];
    };

    get acceptedFormats() {
        return ['.pdf'];
    };

    get isShowQ1(){
        return !(this.qstListToHide.indexOf(';Customized Text;')>=0);
    };
}