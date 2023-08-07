import { api, LightningElement, track, wire } from 'lwc';
import {CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import {redirect,sortBy } from 'c/imcc_lwcUtility';
import RejectedNoteOnPendingTasks from '@salesforce/label/c.Rejected_note_on_Pending_Tasks';
import LOCALE from '@salesforce/i18n/locale';

export default class ImccMyTask extends NavigationMixin(LightningElement) {

    label = {
        RejectedNoteOnPendingTasks
    };

    @api myTask;
    @api dueDates;

    @track taskList;
    @track editionObj;
    @track eventcode;
    @track accountId;
    @track loadMore;
    @track taskCount;
    @track isShowTask;
    @track selectedTask;
    @track showComp = false;
    @track cemId;
    @track contactId;
    @track allFormDatas;
    @track mapPDFD = {};
    @track mapFAFE = {};

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference && currentPageReference.type == "comm__namedPage" && currentPageReference.attributes.name == "Overview__c") {
        this.taskCount = 0;
        this.isShowTask = false;
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;            
        }
    };

    connectedCallback(){
        //deadline fields for stands
        //this.editionObj.Contractor_Nomination_Due_Date__c;
        //this.editionObj.Stand_Design_Completion_Due_Date__c;

        
        this.editionObj = JSON.parse(JSON.stringify(this.dueDates.Edition__r));
        if(this.dueDates.Primary_Contact_Edition_Mapping__c != '' && this.dueDates.Primary_Contact_Edition_Mapping__c != undefined){
            this.cemId = this.dueDates.Primary_Contact_Edition_Mapping__c;
        }
        else{
            this.cemId = this.dueDates.Id;
        }
        this.contactId = this.dueDates.Contact__c;
        let t = JSON.parse(JSON.stringify(this.myTask));
        console.log('t: '+JSON.stringify(t));
        let myTaskList = [];
        //calculate due date color
        const formSet = [];
        const manualSet = [];
        t.forEach(item=>{ 
            if(item.tabType=='Forms'){
              item.pendingForms = [];
              this.allFormDatas = item.forms;
              this.allFormDatas.forEach(fdId =>{
                  if(fdId.Purchase_Data__c != null){
                     this.mapPDFD[fdId.Purchase_Data__c+'_'+fdId.Forms_Permission__r.Form_Allocation__c] = fdId;
                   }
                });
                this.allFormDatas.forEach(fdId =>{
                     if(fdId.Status1__c !== 'Submitted' && fdId.Status1__c !== 'Resubmitted' && fdId.Status1__c !== 'Approved' && fdId.Status1__c !== 'Agreed' && fdId.Status1__c !== 'In Review'){
                        if(fdId.Forms_Permission__r.Form_Allocation__c != null){
                            if(this.mapFAFE[fdId.Forms_Permission__r.Form_Allocation__c] == null){
                               this.mapFAFE[fdId.Forms_Permission__r.Form_Allocation__c] = [];
                             }
                             if(fdId.Form_Response_Entries__r != null){
                                Array.prototype.push.apply(this.mapFAFE[fdId.Forms_Permission__r.Form_Allocation__c],fdId.Form_Response_Entries__r);
                             }
                             if(fdId.Status1__c == 'Rejected'){
                              fdId.showRejectReason = true;
                            }
                        }
                        item.pendingForms.push(fdId);
                    }
                    console.log('item.pendingForms: '+JSON.stringify(item.pendingForms));
                });
            }      
            item.color = item.color?item.color:{};     
            console.log('item.standDesigns: '+JSON.stringify(item.standDesigns));
            //Add 1-1 task from Badge Registration and Virtual Event
            if(item.isEnabled && (item.tabType=='Badge Registration' || item.tabType=='Virtual Event')){
                myTaskList.push(item);
            }
            /*commenting as part of IMCC_4506
            else if(item.isEnabled && (item.tabType==='Stand Design' || item.tabType==='Stand Contractors')){                
                myTaskList = myTaskList.concat(item.standDesigns);
            }*/
            //Add task for forms
            else if(item.isEnabled && item.tabType=='Forms'){                
                let r = this.getDataWithColors(item.pendingForms,'Forms',item.tabId);
                myTaskList = myTaskList.concat(r);    
                console.log('myTaskList: '+JSON.stringify(myTaskList));                                        
            }
            else if(item.tabType=='Manuals'){                                
                let r = this.getDataWithColors(item.manuals,'Manuals',item.tabId);
                myTaskList = myTaskList.concat(r);            
            }
        });
        
        //sort desc by deadline        
        myTaskList = myTaskList.sort((sortBy('deadline')));
        
        myTaskList.forEach(item=>{
            if(item.tabType==='Forms'){
                formSet.push(item.label);
            }
            if(item.tabType==='Manuals'){
                manualSet.push(item.label);
            }
            //hide task if completed or not active for loggedin user
            if(item.isCompleted || !(item.isEnabled)){
                item.isShow = false;                
            }
            else{
                item.isShow = true;
                this.isShowTask = true;                
            }
            if(item.isShow){                
                this.taskCount = this.taskCount + (item.total - item.completed);
            }            
        });
        formSet
        console.log('formSet#### '+formSet);
        const temp = JSON.parse(JSON.stringify(myTaskList));
        //Group forms and manuals
        myTaskList = myTaskList.filter((v,i,a)=>a.findIndex(v2=>['label','tabType'].every(k=>v2[k] ===v[k]))===i);
        
        myTaskList.forEach(item=>{
            item.color = item.color?item.color:{};
            if(item.tabType=='Manuals'){
                let all = manualSet.filter(i=>i===item.label);
                let completed = temp.filter(i=>i.label===item.label && i.isCompleted===true && i.tabType==='Manuals');
                if(all.length>1 && completed.length < all.length){                    
                    item.isShow = true;
                    item.suffix = '('+completed.length+'/'+all.length+')';
                }
            }
            else if(item.tabType=='Forms'){
                let all = formSet.filter(i=>i===item.label);
                console.log('all %%% ' +all);
                let completed = temp.filter(i=>i.label===item.label && i.isCompleted===true && i.tabType==='Forms');
                if(all.length>1 && completed.length < all.length){
                    item.isShow = true;                   
                    item.suffix = '('+completed.length+'/'+all.length+')';
                }
            }
        });        


        let index = 0;
        myTaskList.forEach(item=>{        
            //hide task if completed or not active for loggedin user
            index += item.isShow?1:0;
                         
            //add hide class if more than 3
            if(index>3){                
                item.style = 'display:none;visibility:hidden;opacity:0';
                this.loadMore = true;
            }
        });

        this.taskList = myTaskList;        
    };

    getDataWithColors(data,type,tabId){
        let prev7Days = new Date(new Date().getTime()-(7*24*60*60*1000)).setHours(0, 0, 0, 0)
        let next7Days = new Date(new Date().getTime()+(7*24*60*60*1000)).setHours(0, 0, 0, 0);
        let today = new Date().setHours(0, 0, 0, 0);
        let tomorrow = new Date(new Date().getTime()+(1*24*60*60*1000)).setHours(0, 0, 0, 0);

        data.forEach(item=>{
            item.tabId = tabId;
            item.label = item.Form_Name__c;
            item.page = type === 'Manuals'?'manuals__c':'forms__c';
            item.psType = type === 'Manuals'?'Manuals':'Forms';
            item.tabType = type === 'Manuals'?'Manuals':'Forms';
            item.isEnabled=true;
            item.isCompleted=false;
            item.total=1;
            item.completed=0;
            item.color = {};

            item.deadline = item.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c;
            item.deadline = item.deadline?new Date(item.deadline).setHours(0,0,0,0):'';

            if(item.deadline){                
                item.isShow = true;
                let date2 = new Date(item.deadline).setHours(0, 0, 0, 0);
                if(date2 < today){
                    item.color.order=1;
                    item.color.mainClass = 'card overdue task-progress';
                    item.color.childClass = 'task-overdue';
                    item.color.label = 'Overdue';
                    item.order=1;
                }
                else if(date2 > next7Days){
                    item.color.order=3;
                    item.color.mainClass = 'card upcoming task-progress';
                    item.color.childClass = 'task-upcoming';
                    let date  =  item.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c?item.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c.split("-"):[];
                    let dateFormatted = date && date.length==3?date[2]+' '+this.getMonth(date[1])+' '+date[0]:'';
                    item.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c = dateFormatted;
                    //let d = tomorrow===date2?'Tomorrow':today===date2?'Today':new Intl.DateTimeFormat(LOCALE).format(new Date(item.deadline).setHours(0, 0, 0, 0));
                    let d = tomorrow===date2?'Tomorrow':today===date2?'Today':item.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c;
                    item.color.label = 'Pending: '+d;
                    item.order=3;
                }
                else if(date2 >= prev7Days || date2==today){
                    item.color.order=2;
                    item.color.mainClass = 'card urgent task-progress';
                    item.color.childClass = 'task-due';
                    let date  =  item.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c?item.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c.split("-"):[];
                    let dateFormatted = date && date.length==3?date[2]+' '+this.getMonth(date[1])+' '+date[0]:'';
                    item.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c = dateFormatted;
                    //let d = tomorrow===date2?'Tomorrow':today===date2?'Today':new Intl.DateTimeFormat(LOCALE).format(new Date(item.deadline).setHours(0, 0, 0, 0));
                    let d = tomorrow===date2?'Tomorrow':today===date2?'Today':item.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c;
                    item.color.label = 'Urgent: '+d;
                    item.order=2;
                }
            }
            else{
                item.color.order=5;
                item.color.mainClass = 'card upcoming task-progress';
                item.color.childClass = 'task-upcoming';                
                item.color.label = 'Pending';
                item.order=5;
            }

            if (item.Status1__c === 'Submitted' || item.Status1__c === 'Resubmitted' || item.Status1__c === 'Approved' || item.Status1__c === 'Agreed') {
                item.completed=1;                
                item.isCompleted = true;
                item.isShow = false;
                item.order=5;
            }
        });

        return data;
    };

    //IMCC-4506
    getMonth(month){
        let mon;
        if (month === '01') { mon = 'Jan'; }
        if (month === '02') { mon = 'Feb'; }
        if (month === '03') { mon = 'Mar'; }
        if (month === '04') { mon = 'Apr'; }
        if (month === '05') { mon = 'May'; } 
        if (month === '06') { mon = 'Jun'; }
        if (month === '07') { mon = 'Jul'; }
        if (month === '08') { mon = 'Aug'; }
        if (month === '09') { mon = 'Sept'; }
        if (month === '10') { mon = 'Oct'; }
        if (month === '11') { mon = 'Nov'; }
        if (month === '12') { mon = 'Dec'; }
        return mon;
    };

    openTask(event){
        
        let index = parseInt(event.target.value,10);
        const selectedTask = this.taskList[index];
        if(selectedTask.tabType == 'Forms' || selectedTask.tabType == 'Manuals'){
            this.showComp = true;
            this.selectedTask = selectedTask;
        } 
        else{
            this.showComp = false;
            this.redirect(selectedTask.page,{"accId":this.accountId,"edcode":this.eventcode,"tabId":selectedTask.tabId});
        }
    };

    @track showLess;
    loadMoreData(){
        const data = JSON.parse(JSON.stringify(this.taskList));
        
        data.forEach(item=>{
            if(item.isShow){
                item.style='';
            }
        });
        this.taskList = data;
        this.loadMore = false;        
        this.showLess = true;
        
    };

    showLessData(){
        const data = JSON.parse(JSON.stringify(this.taskList));
        let index = 0;
        data.forEach(item=>{
            index += item.isShow?1:0;

            if(index>3){
                item.style = 'display:none;visibility:hidden;opacity:0';
            }
        });
        this.taskList = data;
        this.scrollOnTop();
        this.loadMore = true;
        this.showLess = false;
    };

    scrollOnTop(){
        const scrollOptions = {left: 0,top: 362,behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
    }

    /*
    get taskCount(){
        let count=0;
        if(this.taskList){
            this.taskList.forEach(i=>{
                if(i.isShow){
                    count = count + 1;
                }
            });
        }
        return count;
    };
    */    

    // sortBy(field, reverse, primer) {
    //     var key = primer
    //         ? function(x) {
    //               return primer(x[field]);
    //           }
    //         : function(x) {
    //               return x[field];
    //           };

    //     return function(a, b) {
    //         a = key(a);
    //         b = key(b);
    //         return reverse * ((a > b) - (b > a));
    //     };
    // };

    redirect(pageName,paramObj){
        redirect(this,NavigationMixin.Navigate,pageName,paramObj);        
    };

    formsubmitted(event) {
        //const formId = event.detail;
        //window.location.reload();
        this.redirect(this.selectedTask.page,{"accId":this.accountId,"edcode":this.eventcode,"tabId":this.selectedTask.tabId});
    }

    @track isReasonModal = false;
    formRejectionReason;
    openReasonModal(event) {
        this.isReasonModal = true;
        this.formRejectionReason = event.target.value;
        console.log('rejectionEntry', this.formRejectionReason);
    }

    closeModal() {
        this.isReasonModal = false;
    }
}