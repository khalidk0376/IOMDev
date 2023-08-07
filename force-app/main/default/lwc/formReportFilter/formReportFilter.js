import { api, LightningElement, track } from 'lwc';
import getAllQuestions from '@salesforce/apex/FormReportCtrl.getAllQuestions';
import getGirikonForm from '@salesforce/apex/FormReportCtrl.getGirikonForm';

export default class FormReportFilter extends LightningElement {
    @api formAllocId;
    @api editionId;
    @track isOpenDownloadModal;
    @track questionList;
    @track qid;

    @track selectedQuestions;
    @track inputVal='';
    
    connectedCallback(){
        this.isOpenDownloadModal = true; 
        console.log('formAllocId@@ ' +this.formAllocId);
        getGirikonForm({formAllocId:this.formAllocId})
        .then(res=>{
            this.qid = res;
            //console.log('Form Id ++ ' +this.qid);
            this.getAllQuestion(this.qid);
        })
        .catch(error=>{
            console.error(error);
        }) 
         
    }

    getAllQuestion(qid){
        //console.log('Form Id ## ' +qid);
        getAllQuestions({qid:qid})
        .then(res=>{
            this.questionList = JSON.parse(JSON.stringify(res));
            console.log('this.questionList ' +this.questionList);
            this.questionList.forEach(item=>{
                item.checked=false;
            })
        })
        .catch(error=>{
            console.error(error);
        })
    }

    hideModal(){
        this.isOpenDownloadModal = false;
    }

    handleCheckboxChange(event){
        let index = parseInt(event.target.dataset.index,10);
        let item = this.questionList[index];
        item.checked = !item.checked; 
        this.questionList[index] = item;     
        console.log(JSON.stringify(this.questionList[index]));   
    }

    downloadReport(){
        
        let param = 'param='+this.inputVal;
        let q='';
        this.questionList.forEach(item=>{            
            if(item.checked==true){
                q += q===''?item.Question__c:','+item.Question__c;
            }
        });
        if(q!=''){
            param = param+'&q='+q;
        }
        //console.log('Form Id ++ ' +this.qid);
        console.log(param);
        window.open('/apex/downloadFormReport?download=true&formId='+this.formAllocId+'&eid='+this.editionId+'&type=community-user&'+param,true);
        this.isOpenDownloadModal = false;
    }

    changeInput(event){
        this.inputVal = event.detail.value;
    }
}