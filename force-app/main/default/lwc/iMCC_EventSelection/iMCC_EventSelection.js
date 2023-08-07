import { LightningElement,track,wire} from 'lwc';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import fetchEventLst from '@salesforce/apex/IMCC_AccountSelectionCtrl.fetchEventList';
import { redirect,handleUIErrors } from 'c/imcc_lwcUtility';
import communityURL from '@salesforce/label/c.CommunityURL';


export default class IMCC_EventSelection extends NavigationMixin(LightningElement) {
    
    @track evtLst;
    @track accId;
    
    @track overdueTaskCount;
    @track urgentTaskCount;
    @track completedTaskCount;
    @track pendingTaskCount;
    
    @track methodName;
    className ='iMCC_EventSelection';
    comp_type ='LWC';
    
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.overdueTaskCount = 0;
        this.urgentTaskCount = 0;
        this.completedTaskCount = 0;
        this.pendingTaskCount = 0;
        if(currentPageReference){
            if(this.accId != null && this.accId != ''){
                if(this.accId != currentPageReference.state.accId){
                    this.template.querySelectorAll(".chatWindowFrame")[0].src = this.template.querySelectorAll(".chatWindowFrame")[0].src;
                }
            }
            this.accId = currentPageReference.state.accId;
            if(this.accId != null && this.accId != ''){
            this.fetchEvt(this.accId);
        }
    }
    }

    connectedCallback() { // invoke the method when component rendered or loaded                    
        window.addEventListener( "message", this.handleVFResponse.bind(this), false );    
    };

    handleVFResponse(message){
        // check the origin match for both source and target
        if (message.origin === communityURL){
            if(message.data == "afterMaximize"){
                this.template.querySelectorAll(".chatWindowFrame")[0].height = "500px";
                this.template.querySelectorAll(".chatWindowFrame")[0].width = "300px";
            }
            if(message.data == "onSettingsCallCompleted" || message.data == "afterMinimize"  || message.data == "afterDestroy" ){
                this.template.querySelectorAll(".chatWindowFrame")[0].height = "50px";
                this.template.querySelectorAll(".chatWindowFrame")[0].width = "205px";
            }
            if(message.data == "reloadFrame"){
                this.template.querySelectorAll(".chatWindowFrame")[0].src = this.template.querySelectorAll(".chatWindowFrame")[0].src;
            }
        }
    };

    fetchEvt(accId){
        this.methodName='fetchEvt';
        fetchEventLst({accountId : accId})
        .then(result => {
            let data = JSON.parse(JSON.stringify(result.eventList)); 
            let formData = JSON.parse(JSON.stringify(result.formData));
            let cemList = JSON.parse(JSON.stringify(result.cemList));
            let pslist = JSON.parse(JSON.stringify(result.pslist));
            let listVirtualPdAggr = JSON.parse(JSON.stringify(result.listVirtualPdAggr));
            let listPdBadges = JSON.parse(JSON.stringify(result.listPdBadges));
            let tabUserTypeList = JSON.parse(JSON.stringify(result.tabUserTypeList));
            
            formData.forEach(item=>{
                item.deadline = item.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c;
                item.deadline = item.deadline?new Date(item.deadline).setHours(0,0,0,0):'';
                delete item.Forms_Permission__r;
                delete item.Forms_Permission__c;                
            });

            cemList.forEach(item=>{
                item.completedPurchaseSummary = (item.Primary_Contact_Edition_Mapping__c!='' && item.Primary_Contact_Edition_Mapping__c!=null)?item.Primary_Contact_Edition_Mapping__r.Completed_Purchase_Summaries__c:item.Completed_Purchase_Summaries__c;
                item.deadlineBadge = item.Edition__r.Due_Date__c;
                item.deadlineBadge = item.deadlineBadge?new Date(item.deadlineBadge).setHours(0,0,0,0):''; 

                item.deadlineVirtualEvent = item.Edition__r.Company_Profile_Submission_Due_Date__c;
                item.deadlineVirtualEvent = item.deadlineVirtualEvent?new Date(item.deadlineVirtualEvent).setHours(0,0,0,0):'';            
            });
            console.log('this.cemList===',JSON.stringify(cemList));          
            let prev7Days = new Date(new Date().getTime()-(7*24*60*60*1000)).setHours(0, 0, 0, 0)
            let next7Days = new Date(new Date().getTime()+(7*24*60*60*1000)).setHours(0, 0, 0, 0);
            let today = new Date().setHours(0, 0, 0, 0);
            data.forEach(row => {   
                this.overdueTaskCount = 0;
                this.urgentTaskCount = 0;
                this.completedTaskCount = 0;  
                this.pendingTaskCount = 0;

                let startDate = row.Start_Date__c;
                let endDate = row.End_Date__c;
                let startMOnth = startDate?this.formatDate(startDate):'';
                let endMOnth = endDate ? ' – ' + this.formatDate(endDate):'';                
                row.eventDate = startMOnth + endMOnth;
                row.formData = formData.filter(i=> i.Edition__c===row.Id);
                row.cemList = cemList.filter(i=> i.Edition__c===row.Id);
                row.pslist = pslist.filter(i=> i.Event_Setting__c===row.Event_Setting__c);
                row.listVirtualPdAggr = listVirtualPdAggr.filter(i=> i.Edition__c===row.Id);
                row.listPdBadges = listPdBadges.filter(i=> i.Edition__c===row.Id);
                row.tabUserTypeList = tabUserTypeList.filter(i=> i.Event_Tab__r.Event_Setting__c===row.Event_Setting__c);
                row.formData.forEach(item=>{
                    if (item.Status1__c === 'Submitted' || item.Status1__c === 'Resubmitted' || item.Status1__c === 'Approved' || item.Status1__c==='Agreed' || item.Status1__c === 'In Review') {
                        this.completedTaskCount = this.completedTaskCount + 1;
                    }
                    else if(item.deadline){
                        let date2 = new Date(item.deadline).setHours(0, 0, 0, 0);
                        if(date2 < today){
                            this.overdueTaskCount += 1;                            
                        }
                        else if(date2 > next7Days){
                            this.pendingTaskCount += 1;
                        }
                        else if(date2 >= prev7Days || date2==today){
                            this.urgentTaskCount += 1;
                        }                        
                    }
                });
                row.isCountBadgeTask = false;
                row.isCountVirtualEventTask = false;
                row.pslist.forEach(item=>{
                    if(item.Purchase_Summary_Type__c==='Badge'){
                        row.isCountBadgeTask = true;
                        if(row.listPdBadges.length===0 || !item.Is_Active__c){
                            row.isCountBadgeTask = false;
                        }
                    }
                    if(item.Purchase_Summary_Type__c==='Virtual Event'){
                        row.isCountVirtualEventTask = true;
                        if(row.listVirtualPdAggr.length===0 || !item.Is_Active__c){
                            row.isCountVirtualEventTask = false;
                        }
                    }
                });
                row.cemList.forEach(item=>{
                    row.isCountBadgeTask2 = false;
                    row.isCountVirtualEventTask2 = false;
                    row.cemRole = '';
                    row.tabUserTypeList.forEach(tut=>{
                        if(tut.User_Type__c == item.Access_Type__c && tut.Event_Tab__r.Standard_Tab_Type__c == 'Badge Registration'){
                            row.isCountBadgeTask2 = true;
                        }
                        if(tut.User_Type__c == item.Access_Type__c && tut.Event_Tab__r.Standard_Tab_Type__c == 'Virtual Event'){
                            row.isCountVirtualEventTask2 = true;
                        }
                    });
                    let badgeCompleted = false;
                    let virtualEventCompleted = false;
                    
                    row.cemRole = (item.Role__c != '' && item.Role__c != null)?item.Role__c:'';

                    if(item.completedPurchaseSummary != '' && item.completedPurchaseSummary != null && item.completedPurchaseSummary!=';') {
                        let completePurchaseSummiries = item.completedPurchaseSummary.toString().split(";");
                        if(completePurchaseSummiries.includes('Badge') && row.isCountBadgeTask && row.isCountBadgeTask2){
                            this.completedTaskCount = this.completedTaskCount + 1;
                            badgeCompleted = true;
                        }
                        if(completePurchaseSummiries.includes('Virtual Event') && row.isCountVirtualEventTask && row.isCountVirtualEventTask2 ){
                            this.completedTaskCount = this.completedTaskCount + 1;
                            virtualEventCompleted = true;
                        }
                    }
                    if(item.deadlineBadge && !badgeCompleted && row.isCountBadgeTask && row.isCountBadgeTask2){
                        let date2 = new Date(item.deadlineBadge).setHours(0, 0, 0, 0);
                        if(date2 < today){
                            this.overdueTaskCount += 1;                            
                        }
                        else if(date2 > next7Days){
                            this.pendingTaskCount += 1;
                        }
                        else if(date2 >= prev7Days || date2==today){
                            this.urgentTaskCount += 1;
                        }                        
                    }
                    if(item.deadlineVirtualEvent && !virtualEventCompleted && row.isCountVirtualEventTask && row.isCountVirtualEventTask2 ){
                        let date2 = new Date(item.deadlineVirtualEvent).setHours(0, 0, 0, 0);
                        if(date2 < today){
                            this.overdueTaskCount += 1;                            
                        }
                        else if(date2 > next7Days){
                            this.pendingTaskCount += 1;
                        }
                        else if(date2 >= prev7Days || date2==today){
                            this.urgentTaskCount += 1;
                        }                        
                    }
                    
                    });
                row.taskClass = 'card pending task-progress';
                //show task count based on priority=> overdue > urgent > pending task > completed
                if(this.overdueTaskCount > 0){
                    row.taskCount = this.overdueTaskCount+' overdue task'+(this.overdueTaskCount>1?'s':'');
                    row.taskClass = 'card overdue task-progress';
                    row.labelClass = 'task-overdue';
                }
                else if(this.urgentTaskCount > 0){
                    row.taskCount = this.urgentTaskCount+' urgent task'+(this.urgentTaskCount>1?'s':'');
                    row.taskClass = 'card urgent task-progress';
                    row.labelClass = 'task-due';
                }
                else if(this.pendingTaskCount > 0){
                    row.taskCount = this.pendingTaskCount +' pending task'+(this.pendingTaskCount>1?'s':'');
                    row.taskClass = 'card pending task-progress';
                    row.labelClass = 'task-pending';
                }
                else if(this.completedTaskCount > 0){
                    row.taskCount = 'Completed';
                    row.taskClass = 'card complete task-progress';
                    row.labelClass = 'task-complete';
                }
            });            
            this.evtLst = data;  
            console.log('this.evtLst===',JSON.stringify(this.evtLst));          
        })
        .catch(error => {
            this.error = error;
            console.log('Error ', error);
            handleUIErrors(this,error);
        });        
    };
    
    gotoEventLandingPage(event){
        var evtId = event.target.dataset.eventid;        
        this.redirect('Overview__c',{"edcode":evtId,"accId":this.accId});
    };

    formatDate(date) {
        let dt = new Date(date), month = '' + (dt.getUTCMonth() + 1), day = '' + dt.getUTCDate(), year = dt.getFullYear(), mon = '';
        if (month === '1') { mon = 'Jan,'; }
        if (month === '2') { mon = 'Feb,'; }
        if (month === '3') { mon = 'Mar,'; }
        if (month === '4') { mon = 'Apr,'; }
        if (month === '5') { mon = 'May,'; } 
        if (month === '6') { mon = 'Jun,'; }
        if (month === '7') { mon = 'Jul,'; }
        if (month === '8') { mon = 'Aug,'; }
        if (month === '9') { mon = 'Sept,'; }
        if (month === '10') { mon = 'Oct,'; }
        if (month === '11') { mon = 'Nov,'; }
        if (month === '12') { mon = 'Dec,'; }
        if (day.length < 2) day = '0' + day;
        return [day, mon, year].join(' ');
    };

    redirect(pageName,paramObj){
        redirect(this,NavigationMixin.Navigate,pageName,paramObj);        
    };
}