import {LightningElement, track,wire } from 'lwc';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import getEventSummary from '@salesforce/apex/IMCC_HomeCtrl.getEventSummary';
// import getActivePHDatas from "@salesforce/apex/IMCCStandDesignCTRL.getActivePHDatas";
import congratulation from '@salesforce/label/c.congratulation';
import Badge_registration_and_Lead_Retrieval from '@salesforce/label/c.Badge_registration_and_Lead_Retrieval';
import LOCALE from '@salesforce/i18n/locale';

import {handleUIErrors,redirect } from 'c/imcc_lwcUtility';

export default class ImccEventSummary extends NavigationMixin(LightningElement) {

    @track openHowItWorkModal;
    @track eventcode;
    @track accountId;
    @track taskList;
    @track totalProgress;
    @track isTaskNotFound;
    @track userType;
    isShowSummaryData = false;

    @track otc; //overdue task count
    @track utc; // urgent task count
    @track ctc; // completed task count
    @track ptc; // pending task count

    message = congratulation;
    label = { Badge_registration_and_Lead_Retrieval };

    taskStatus;//completed task with comma separated 
    @track methodName;
    className ='imccEventSummary';
    comp_type ='LWC';

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if(currentPageReference && currentPageReference.type == "comm__namedPage" && currentPageReference.attributes.name == "Overview__c"){
            this.isShowSummaryData = false;
            this.otc = 0;
            this.utc = 0;
            this.ctc = 0;
            this.ptc = 0;

            this.taskStatus = '';
            this.isTaskNotFound = true;
            this.totalProgress = 0.0;
            const data = [
                {label:'Complete your company profile',page:'VirtualEvent__c',psType:'Virtual Event',tabType:'Virtual Event',isEnabled:true,weight:0,isCompleted:true,total:1,completed:0},
                {label:'Fill in the required forms',page:'forms__c',psType:'Forms',tabType:'Forms',isEnabled:true,weight:0,isCompleted:false,total:1,completed:0},
                {label:'Read & agree important info',page:'manuals__c',psType:'Manuals',tabType:'Manuals',isEnabled:true,weight:0,isCompleted:false,total:1,completed:0},
                {label:'Submit stand designs',page:'StandDesign__c',psType:'Stand Design',tabType:'Stand Design',isEnabled:true,weight:0,isCompleted:false,total:2,completed:0},            
                {label:Badge_registration_and_Lead_Retrieval,page:'badgeRegistration__c',psType:'Badge',tabType:'Badge Registration',isEnabled:true,weight:0,isCompleted:false,total:1,completed:0}
            ];
            
            data.forEach((item,index)=>{
                item.Id='item-'+index;
                item.weight = 100/data.length;
            });   
            
            this.taskList = data;
            
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;                        
            if(this.eventcode != null && this.eventcode != ''){
                this.fetchEventSummary(this.eventcode,this.accountId);
            }
        }
    };
    
    fetchEventSummary(eventcode,accountId){
        console.log('called');
        this.methodName = 'fetchEventSummary';
        getEventSummary({eventCode:eventcode,accountId:accountId})
        .then(res=>{
            this.userType = res.cem.Access_Type__c;
            //alert(this.userType);
            this.taskStatus = res.taskStatus?';'+res.taskStatus+';':'';
            let task = res.task;//enabled task for user
            let badges = res.badges;
            let virtualEvents = res.ve;
            this.totalProgress = 0;

            const data = JSON.parse(JSON.stringify(this.taskList));
            let totalEnabled = 0;

            data.forEach(item=>{
                if(item.label==='Submit stand designs'){
                    if(this.userType==='Contractor'){
                        item.page = 'StandDesign__c';
                        item.tabType='Stand Design';
                    }
                    else{
                        item.page = 'StandContractors__c';
                        item.tabType='Stand Contractors';
                    }
                }

                let t = task.filter(o=>o.Event_Tab__r.Standard_Tab_Type__c===item.tabType)
                console.log(JSON.stringify(t));
                item.tabId = t && t.length>0 ? t[0].Event_Tab__r.Tab_Code__c:'';
                if(item.tabType==='Badge Registration'){
                    item.isEnabled = t.length>0 && badges.length>0;                    
                }
                else if(item.tabType==='Virtual Event'){
                    item.isEnabled = t.length>0 && virtualEvents.length>0;                    
                }
                else if(item.tabType==='Forms'){                    
                    console.log('forms: '+JSON.stringify(res.form));
                    let obj = this.calculate(JSON.parse(JSON.stringify(res.form)));
                    item.color = obj;
                    item.forms = res.form;
                    item.isCompleted = obj.total===obj.completed?true:false;
                    item.completed = obj.completed;
                    item.total = obj.total;
                    item.order = obj.order;
                    item.isEnabled = t.length>0 && obj.total>0;
                }
                else if(item.tabType==='Manuals'){                         
                    let obj = this.calculate(JSON.parse(JSON.stringify(res.manual)));
                    console.log('manuals: '+obj.total+'==='+obj.completed);
                    item.color = obj;
                    item.manuals = res.manual;
                    item.isCompleted = obj.total == obj.completed?true:false;
                    item.completed = obj.completed;
                    item.total = obj.total;
                    item.order = obj.order;
                    item.isEnabled = t.length>0 && obj.total>0;
                }
                else if((item.tabType==='Stand Design' || item.tabType==='Stand Contractors') ){
                    let standData = JSON.parse(JSON.stringify(res.sd));
                    console.log('standData: '+JSON.stringify(res.sd));
                    if(res.cem && res.cem.Edition__r && res.cem.Edition__r.Stand_Design_Completion_Due_Date__c)
                    {                      
                     item.deadline = res.cem.Edition__r.Stand_Design_Completion_Due_Date__c;
                    }                 
                    let obj = this.calculateStandSub(standData,item.deadline,item.tabId,item.tabType,item.page);
                    item.standDesigns = obj.td;
                    item.isCompleted = obj.total == obj.completed?true:false;
                    item.completed = obj.completed;                    
                    item.total = obj.total;
                    item.isEnabled = t.length>0 && item.total>0;                
                }
                if(item.isEnabled){
                    totalEnabled = totalEnabled + 1;
                }
            });
            this.isTaskNotFound = totalEnabled===0?true:false;

            //set weight and calculate totalProgress
            data.forEach(item=>{
                if(totalEnabled>0){
                    item.weight = 100/totalEnabled;
                }                
                if(item.tabType=='Virtual Event' && item.isEnabled){                    
                    item.isCompleted = this.taskStatus.indexOf(';'+item.psType+';')>=0;
                    if(res.pcem.length>0){
                        item.deadline = res.pcem[0].Edition__r.Company_Profile_Submission_Due_Date__c;
                    }
                    else{
                        item.deadline = res.cem.Edition__r.Company_Profile_Submission_Due_Date__c;                        
                    }                    
                    item.deadline = item.deadline?new Date(item.deadline).setHours(0, 0, 0, 0):'';                    
                    item.completed = item.isCompleted?1:0;
                    item.color = this.getColorClass(item.deadline,item.isCompleted);
                    
                    item.order = item.color.order;
                }
                if(item.tabType=='Badge Registration' && item.isEnabled){
                    item.isCompleted = this.taskStatus.indexOf(';'+item.psType+';')>=0;
                    item.completed = item.isCompleted?1:0;
                    if(res.pcem.length>0){
                        item.deadline = res.pcem[0].Edition__r.Due_Date__c;
                    }
                    else{
                        item.deadline = res.cem.Edition__r.Due_Date__c;
                    }

                    item.deadline = item.deadline?new Date(item.deadline).setHours(0, 0, 0, 0):'';
                    item.color = this.getColorClass(item.deadline,item.isCompleted);
                    console.log('color'+JSON.stringify(item.color));
                    item.order = item.color.order;
                }
                
                if(item.isEnabled && item.isCompleted && (item.tabType=='Badge Registration' || item.tabType=='Virtual Event')){
                    this.totalProgress = (this.totalProgress + item.weight);
                }
                else if(item.isEnabled && (item.tabType==='Stand Design' || item.tabType==='Stand Contractors')){
                    //set Stand partial progress
                    if(item.total>0){
                        this.totalProgress = this.totalProgress + ((item.weight * item.completed)/item.total);
                    }
                }
                else if(item.isEnabled && (item.tabType=='Forms' || item.tabType=='Manuals')){
                    //set form and manual partial progress
                    if(item.total>0){
                        this.totalProgress = this.totalProgress + ((item.weight * item.completed)/item.total);
                    }
                }                                                               
            });
            this.totalProgress = Math.round(this.totalProgress);
            this.taskList = data;
            this.isShowSummaryData = true;
            //console.log(JSON.stringify(data));
            this.dispatchEvent(new CustomEvent('afterload',{detail:{task:this.taskList,dueDate:res.cem}}));
        })
        .catch(error=>{
            handleUIErrors(this,error); 
        });
    };
    
    calculate(data){
        let obj = {status:'pending',total:data.length,completed:0,mainClass:'card urgent task-progress',childClass:'task-due',label:'Urgent',order:10};
        
        let prev7Days = new Date(new Date().getTime()-(7*24*60*60*1000)).setHours(0, 0, 0, 0)
        let next7Days = new Date(new Date().getTime()+(7*24*60*60*1000)).setHours(0, 0, 0, 0);
        let today = new Date().setHours(0, 0, 0, 0);
        let overdueTaskCount = 0;
        let urgentTaskCount = 0;
        let completedTaskCount = 0;
        let pendingTaskCount = 0;
        data.forEach(item=>{
            item.deadline = item.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c;
            item.deadline = item.deadline?new Date(item.deadline).setHours(0,0,0,0):'';

            if (item.Status1__c === 'Submitted' || item.Status1__c === 'Resubmitted' || item.Status1__c === 'Approved' || item.Status1__c === 'Agreed' || item.Status1__c === 'In Review') {
                completedTaskCount += 1;
            }
            else if(item.deadline){
                let date2 = new Date(item.deadline).setHours(0, 0, 0, 0);
                if(date2 < today){
                    overdueTaskCount += 1;
                }
                else if(date2 > next7Days){
                    pendingTaskCount += 1;
                }
                else if(date2 >= prev7Days || date2==today){
                    urgentTaskCount += 1;
                }
            }
        });
        
        if(overdueTaskCount > 0){            
            obj.status = 'overdue';
            obj.mainClass='card overdue task-progress';
            obj.childClass='task-overdue';
            obj.label='Overdue';
            obj.order=1;
            this.otc = this.otc + overdueTaskCount;
        }
        else if(urgentTaskCount > 0){
            obj.status = 'urgent';
            obj.mainClass='card urgent task-progress';
            obj.childClass='task-due';
            obj.label='Urgent';
            obj.order=2;
            this.utc = this.utc + urgentTaskCount;
        }
        else if(pendingTaskCount > 0){
            obj.status = 'pending';
            obj.mainClass='card upcoming task-progress';
            obj.childClass='task-upcoming';
            obj.label='Upcoming';
            obj.order=3;
            this.ptc = this.ptc + pendingTaskCount;
        }
        else if(completedTaskCount > 0){
            obj.status = 'completed';
            obj.mainClass='card completed task-progress';
            obj.childClass='task-completed';
            obj.label='Completed';
            obj.order=4
            this.ctc = this.ctc + pendingTaskCount;
        }
        obj.completed = completedTaskCount;
        return obj;
    };

    openTask(event){
        let index = parseInt(event.currentTarget.dataset.index,10);
        const selectedTask = this.taskList[index];
        console.log(JSON.stringify(selectedTask));        
        this.redirect(selectedTask.page,{"accId":this.accountId,"edcode":this.eventcode,"tabId":selectedTask.tabId});
    };

    calculateStandSub(tempData,deadline,tabId,tabType,page){
        let obj = {status:'pending',td:[],total:tempData.length,completed:0,mainClass:'card urgent task-progress',childClass:'task-due',label:'Urgent',order:10};      
        let total = 0;
        let comppleted = 0;
        let prev7Days = new Date(new Date().getTime()-(7*24*60*60*1000)).setHours(0, 0, 0, 0)
        let next7Days = new Date(new Date().getTime()+(7*24*60*60*1000)).setHours(0, 0, 0, 0);
        let today = new Date().setHours(0, 0, 0, 0);
        let tomorrow = new Date(new Date().getTime()+(1*24*60*60*1000)).setHours(0, 0, 0, 0);
        let overdueTaskCount = 0;
        let urgentTaskCount = 0;
        let completedTaskCount = 0;
        let pendingTaskCount = 0;

        tempData.forEach(item => {
            item.deadline = deadline?new Date(deadline).setHours(0,0,0,0):'';
            let status = item.standDetailLength == 1?item.standDetail.Stand_Detail_Status__c:'';
            comppleted += status.toLowerCase()==='permission to build'?1:0;
            total += 1;


            item.tabId = tabId;
            item.label = 'Submit stand designs';
            item.page = page;
            item.psType = tabType;
            item.tabType = tabType;
            item.isEnabled=true;
            item.isCompleted=false;
            item.total=1;
            item.completed=0;
            if (status.toLowerCase()==='permission to build'){
                completedTaskCount += 1;
            }
            else if(item.deadline){
                item.color = {};
                let date2 = new Date(item.deadline).setHours(0, 0, 0, 0);
                if(date2 < today){
                    overdueTaskCount += 1;
                    item.color.order=1;
                    item.color.mainClass = 'card overdue task-progress';
                    item.color.childClass = 'task-overdue';
                    item.color.label = 'Overdue';
                    item.order=1;
                }
                else if(date2 > next7Days){
                    pendingTaskCount += 1;
                    item.color.order=3;
                    item.color.mainClass = 'card upcoming task-progress';
                    item.color.childClass = 'task-upcoming';
                    //let d = tomorrow===date2?'Tomorrow':today===date2?'Today':new Intl.DateTimeFormat(LOCALE).format(new Date(item.deadline).setHours(0, 0, 0, 0));
                    //IMCC-4506
                    let d = tomorrow===date2?'Tomorrow':today===date2?'Today':new Intl.DateTimeFormat('en-GB', { dateStyle: 'medium' }).format(item.deadline);
                    item.color.label = 'Pending: '+d;
                    item.order=3;
                }
                else if(date2 >= prev7Days || date2==today){
                    urgentTaskCount += 1;
                    item.color.order=2;
                    item.color.mainClass = 'card urgent task-progress';
                    item.color.childClass = 'task-due';
                    //let d = tomorrow===date2?'Tomorrow':today===date2?'Today':new Intl.DateTimeFormat(LOCALE).format(new Date(item.deadline).setHours(0, 0, 0, 0));
                    //IMCC-4506
                    let d = tomorrow===date2?'Tomorrow':today===date2?'Today':new Intl.DateTimeFormat('en-GB', { dateStyle: 'medium' }).format(item.deadline);
                    item.color.label = 'Urgent: '+d;
                    item.order=2;
                }
            }
        });
        if(overdueTaskCount > 0){            
            obj.status = 'overdue';
            obj.mainClass='card overdue task-progress';
            obj.childClass='task-overdue';
            obj.label='Overdue';
            obj.order=1;
            this.otc = this.otc + overdueTaskCount;
        }
        else if(urgentTaskCount > 0){
            obj.status = 'urgent';
            obj.mainClass='card urgent task-progress';
            obj.childClass='task-due';
            obj.label='Urgent';
            obj.order=2;
            this.utc = this.utc + urgentTaskCount;
        }
        else if(pendingTaskCount > 0){
            obj.status = 'pending';
            obj.mainClass='card upcoming task-progress';
            obj.childClass='task-upcoming';
            obj.label='Upcoming';
            obj.order=3;
            this.ptc = this.ptc + pendingTaskCount;
        }
        else if(completedTaskCount > 0){
            obj.status = 'completed';
            obj.mainClass='card completed task-progress';
            obj.childClass='task-completed';
            obj.label='Completed';
            obj.order=4
            this.ctc = this.ctc + pendingTaskCount;
        }
        obj.td = tempData;
        obj.total = total;
        obj.completed = comppleted;        
        return obj;
    };

    getColorClass(deadline,isCompleted){
        
        let today = new Date(new Date().getTime()).setHours(0, 0, 0, 0);
        let prev7Days = new Date(new Date().getTime() - (7 * 24 * 60 * 60 * 1000)).setHours(0, 0, 0, 0);
        let next7Days = new Date(new Date().getTime() + (7 * 24 * 60 * 60 * 1000)).setHours(0, 0, 0, 0);        
        let tomorrow = new Date(new Date().getTime()+(1*24*60*60*1000)).setHours(0, 0, 0, 0);

        deadline = deadline?deadline:today;
        let dueDate = new Date(deadline).setHours(0, 0, 0, 0);
        
        let obj = {mainClass:'card urgent task-progress',childClass:'task-due',label:'Urgent',order:10};
        if (isCompleted) {
            obj.mainClass = 'card completed task-progress';
            obj.childClass = 'task-completed';
            obj.label = 'Completed';
            obj.order = 4;
            this.ctc = this.ctc + 1;
        }
        else {
            if(dueDate < today){
                obj.mainClass = 'card overdue task-progress';
                obj.childClass = 'task-overdue';
                obj.label = 'Overdue';
                obj.order = 1;
                this.otc = this.otc + 1;                
            }
            else if(dueDate > next7Days){
                obj.mainClass = 'card upcoming task-progress';
                obj.childClass = 'task-upcoming';
                //let d = tomorrow===dueDate?'Tomorrow':today===dueDate?'Today':new Intl.DateTimeFormat(LOCALE).format(new Date(dueDate).setHours(0, 0, 0, 0));
                //IMCC-4506
                let d = tomorrow===dueDate?'Tomorrow':today===dueDate?'Today':new Intl.DateTimeFormat('en-GB', { dateStyle: 'medium' }).format(dueDate);
                obj.label = 'Pending: '+d;
                obj.order = 3;
                this.ptc = this.ptc + 1;
            }
            else if(dueDate >= prev7Days || dueDate==today){
                obj.mainClass = 'card urgent task-progress';
                obj.childClass = 'task-due';
                //let d = tomorrow===dueDate?'Tomorrow':today===dueDate?'Today':new Intl.DateTimeFormat(LOCALE).format(new Date(dueDate).setHours(0, 0, 0, 0));
                //IMCC-4506
                let d = tomorrow===dueDate?'Tomorrow':today===dueDate?'Today':new Intl.DateTimeFormat('en-GB', { dateStyle: 'medium' }).format(dueDate);
                obj.label = 'Urgent: '+d;
                obj.order = 2;
                this.utc = this.utc + 1;
            }            
        }
        return obj;        
    };

    get progressColor(){
        let color = '';
        if(this.otc > 0){
            color = 'overdue';
        }
        else if(this.utc > 0){
            color = 'urgent';
        }
        else if(this.ptc > 0){
            color = 'pending';
        }
        else if(this.ctc > 0){
            color = 'completed';
        }
        return color;
    };

    get isAllTaskCompleted(){
        return this.totalProgress===100;
    };

    cancelModal(){                
        this.openHowItWorkModal = false;        
    };

    openHowTo(){
        this.openHowItWorkModal = true;
    };

    redirect(pageName,paramObj){
        redirect(this,NavigationMixin.Navigate,pageName,paramObj);        
    };

}