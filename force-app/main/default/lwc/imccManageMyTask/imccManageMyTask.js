import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { handleUIErrors } from 'c/imcc_lwcUtility';
import getTasksForAssignment from '@salesforce/apex/IMCC_ManageTaskAssignmentCtrl.getTasksForAssignment';
import getLoggedInUserInfo from "@salesforce/apex/IMCC_ManageTaskAssignmentCtrl.getLoggedInUserInfo";

export default class ImccManageMyTask extends LightningElement {
    className = 'imccManageMyTask';
    comp_type = 'LWC';
    @track conEdMapId;
    @track contactId;
    @track showTabContextIN = '';
    @track stanTabType;
    @track listPD = [];
    @track contactData = [];
    @track formsTypes = [];
    @track spinner = true;
    @track nodata = true;
    @track methodName;
    @track statusOpt = [];
    @track statusOptMandat = [];
    @track statusOptRules = [];
    @track statusOptOptional = [];
    @track memberOpt = [];
    @track providerOptMandat = [];
    @track providerOptRules = [];
    @track providerOptOptional = [];
    @track providerOpt = [];
    @track mandatoryTasks;
    @track rulesAndRegulations;
    @track optionalTasks;
    @track platformAdminCEMId;
    @track isContractor = false;
    @track contractorId;
    @track currentUserRole;
    eventCode
    accountId;
    tabId;
    @track userInfo;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.methodName = 'imccManageMyTask';
            this.eventCode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            this.init();
        }
    };

    getFormData() {
        getTasksForAssignment({
            eventCode: this.eventCode,
            accountId: this.accountId,
            tabId: this.tabId
        })
            .then(result => {
                let tempOpt = [{ label: '--Select One', value: '', isShow: false }];

                result.teamMembers.forEach(i => {
                    if (i.Role__c == 'Platform Admin') {
                        this.platformAdminCEMId = i.Id;
                    }

                    tempOpt.push({ label: i.Contact__r.Name + ' - ' + i.Role__c, value: i.Id, isShow: true });
                });
                //this.memberOpt = tempOpt;

                let data = JSON.parse(JSON.stringify(result));
                this.conEdMapId = data.conEdMapId;
                this.contactId = data.contactId;
                this.stanTabType = data.stanTabType;
                this.listPD = data.listPD;
                this.contactData = data.contactData;
                this.currentUserRole = data.myRole;
                let mandatoryTask = [];
                let ruleAndRegulation = [];
                let optionalTask = [];
                let mandatoryTaskContractor = [];
                let ruleAndRegulationContractor = [];
                let optionalTaskContractor = [];
                const formProviderMandatoryContractor = new Set();
                const formProvider = new Set();
                const formProviderRegulationContractor = new Set();
                const formProvideroptionalContractor = new Set();
                const formStatusMandatoryContractor = new Set();
                const formStatus = new Set();
                const formStatusRegulationContractor = new Set();
                const formStatusoptionalContractor = new Set();

                if (this.currentUserRole == 'Contractor') {
                    this.isContractor = true;
                    this.contractorId = this.userInfo.Id;
                }

                if(!this.isContractor){
                    this.memberOpt = tempOpt;
                }
                else{
                    tempOpt = [];
                    tempOpt.push({ label: this.userInfo.Contact__r.Name , value: this.userInfo.Id, isShow: true });
                    this.memberOpt = tempOpt;
                }
                
                data.listFormData.forEach(row => {

                    this.nodata = false;
                    row.Form_Response_Entries__r = [];
                    row.expand = false;
                    row.Form_Category__c = row.Forms_Permission__r.Form_Allocation__r.Form_Category__c;
                    row.Form_Provider__c = row.Forms_Permission__r.Form_Allocation__r.Form_Provider__c;
                    row.AssignToId = row.Assign_To__c;
                    //console.log('row.Assign_To__r: '+row.Assign_To__r);
                    if (row.Assign_To__c && row.Assign_To__r && row.Assign_To__r.Contact__r) {
                        row.AssignToName = row.Assign_To__r.Contact__r.Name;
                    }
                    else {
                        row.AssignToName = '';
                    }
                    let tempTeamMember = JSON.parse(JSON.stringify(tempOpt));
                    //set value to dropdown
                    if (row.AssignToId) { //remove Select Option from drop down if already assiged task
                        tempTeamMember.splice(0, 1);
                    }
                    tempTeamMember.forEach(opt => {
                        opt.selected = opt.value == row.AssignToId ? true : false;
                    });
                    row.memberList = tempTeamMember;
                    //console.log('row.memberList: '+JSON.stringify(row.memberList));


                    row.formName = row.Forms_Permission__r.Form_Allocation__r.Name;
                    row.formName = row.Forms_Permission__r.Form_Allocation__r.Name;
                    row.Submission_Deadline__c = row.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c
                    row.Form_Type__c = row.Forms_Permission__r.Form_Allocation__r.Form_Type__c;

                    row.isOnline = row.Form_Type__c == 'Online';
                    row.isLink = row.Form_Type__c == 'Link';
                    row.isPdf = row.Form_Type__c == 'PDF';

                    row.Form_Entry__c = row.Forms_Permission__r.Form_Allocation__r.Form_Entry__c;
                    if (data.mapEntries[row.Id] != null) {
                        let entries = data.mapEntries[row.Id];
                        entries.forEach(entry => {
                            row.Form_Response_Entries__r.push(entry);
                        });
                    }
                    //mandatory task (form)
                    if (row.Feature_Category__c == 'Form' && row.Forms_Permission__r.Form_Allocation__r.Form_Heading__c == 'Mandatory') {
                        if (this.isContractor && row.Assign_To__c == this.contractorId) {
                            mandatoryTaskContractor.push(row);
                            formProviderMandatoryContractor.add(row.Form_Provider__c);
                            formStatusMandatoryContractor.add(row.Overall_Status__c);
                        }
                        else {
                            mandatoryTask.push(row);
                            formProvider.add(row.Form_Provider__c);
                            formStatus.add(row.Overall_Status__c);
                        }
                    }

                    //Rules and Regulations (manual)
                    if (row.Feature_Category__c == 'Manual' && row.Forms_Permission__r.Form_Allocation__r.Form_Heading__c == 'Mandatory') {
                        if (this.isContractor && row.Assign_To__c == this.contractorId) {
                            ruleAndRegulationContractor.push(row);
                            formProviderRegulationContractor.add(row.Form_Provider__c);
                            formStatusRegulationContractor.add(row.Overall_Status__c);
                        }
                        else {
                            ruleAndRegulation.push(row);
                            formProvider.add(row.Form_Provider__c);
                            formStatus.add(row.Overall_Status__c);
                        }
                    }

                    //optional task(forms and manuals)
                    if (row.Forms_Permission__r.Form_Allocation__r.Form_Heading__c == 'Additional' || row.Forms_Permission__r.Form_Allocation__r.Form_Heading__c == 'Optional') {
                        if (this.isContractor && row.Assign_To__c == this.contractorId) {
                            optionalTaskContractor.push(row);
                            formProvideroptionalContractor.add(row.Form_Provider__c);
                            formStatusoptionalContractor.add(row.Overall_Status__c);
                        }
                        else {
                            optionalTask.push(row);
                            formProvider.add(row.Form_Provider__c);
                            formStatus.add(row.Overall_Status__c);
                        }
                    }
                });


                let tempOpt1 = [{ label: '--Select One', value: '', isShow: false }];
                let tempOpt2 = [{ label: '--Select One', value: '', isShow: false }];
                let tempOpt3 = [{ label: '--Select One', value: '', isShow: false }];

                if (formProvider) {
                    tempOpt = [];
                    for (const item of formProvider) {
                        tempOpt.push({ label: item, value: item });
                    }
                }

                if (formStatus) {
                    tempOpt3 = [];
                    for (const item of formStatus) {
                        tempOpt3.push({ label: item, value: item });
                    }
                }

                if (mandatoryTaskContractor) {
                    tempOpt1 = [];
                    tempOpt2 = [];
                    for (const item of formProviderMandatoryContractor) {
                        tempOpt1.push({ label: item, value: item });
                    }

                    for (const item of formStatusMandatoryContractor) {
                        tempOpt2.push({ label: item, value: item });
                    }
                }
                this.providerOptMandat = this.isContractor ? tempOpt1 : tempOpt;
                this.statusOptMandat = this.isContractor ? tempOpt2 : tempOpt3;

                if (ruleAndRegulationContractor) {
                    tempOpt1 = [];
                    tempOpt2 = [];
                    for (const item of formProviderRegulationContractor) {
                        tempOpt1.push({ label: item, value: item });
                    }

                    for (const item of formStatusRegulationContractor) {
                        tempOpt2.push({ label: item, value: item });
                    }
                }
                this.providerOptRules = this.isContractor ? tempOpt1 : tempOpt;
                this.statusOptRules = this.isContractor ? tempOpt2 : tempOpt3;

                if (optionalTaskContractor) {
                    tempOpt1 = [];
                    tempOpt2 = [];
                    for (const item of formProvideroptionalContractor) {
                        tempOpt1.push({ label: item, value: item });
                    }

                    for (const item of formStatusoptionalContractor) {
                        tempOpt2.push({ label: item, value: item });
                    }
                }
                this.providerOptOptional = this.isContractor ? tempOpt1 : tempOpt;
                this.statusOptOptional = this.isContractor ? tempOpt2 : tempOpt3;

                this.mandatoryTasks = this.isContractor ? mandatoryTaskContractor : mandatoryTask;
                this.rulesAndRegulations = this.isContractor ? ruleAndRegulationContractor : ruleAndRegulation;
                this.optionalTasks = this.isContractor ? optionalTaskContractor : optionalTask;
            })
            .catch(error => {
                console.error(error.message);
                handleUIErrors(this, error);
            })
            .finally(() => {
                this.spinner = false;
            });
    }

    init() {
        getLoggedInUserInfo({ eventCode: this.eventCode, accountId: this.accountId })
            .then(userInfo => {
                this.userInfo = userInfo;
                //console.log('userInfo: '+JSON.stringify(userInfo));            
                this.getFormData();
            })
            .catch(error => {
                handleUIErrors(this, error);
            });
    }
}