import { LightningElement, wire, track } from 'lwc';
import customerFormListWrpData from '@salesforce/apex/IMCC_FormsCtrl.customerFormListWrpData';
import { CurrentPageReference } from 'lightning/navigation';
import { handleUIErrors } from 'c/imcc_lwcUtility';

export default class Imcc_forms extends LightningElement {
	className='imcc_forms';
    comp_type='LWC';
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

	@wire(CurrentPageReference)
	setCurrentPageReference(currentPageReference){
		if(currentPageReference){
			this.methodName='customerFormListWrpData';
			customerFormListWrpData({
                eventCode: currentPageReference.state.edcode,
                accountId : currentPageReference.state.accId,
				tabId : currentPageReference.state.tabId
			})
			.then(result =>{
				console.log(JSON.stringify(result));
				let data = JSON.parse(JSON.stringify(result));
				this.conEdMapId = data.conEdMapId;
				this.contactId = data.contactId;
				this.stanTabType = data.stanTabType;
				this.listPD = data.listPD;
				this.contactData = data.contactData;
				let lstformDataMan = [];
				let lstformDataAdd = [];
				let lstformDataOpt = [];
				data.listFormData.forEach(row => {
					this.nodata = false;
					row.Form_Response_Entries__r = [];
					row.expand = false;
					row.Form_Category__c = row.Forms_Permission__r.Form_Allocation__r.Form_Category__c;
					row.Form_Provider__c = row.Forms_Permission__r.Form_Allocation__r.Form_Provider__c;
					row.formName = row.Forms_Permission__r.Form_Allocation__r.Name;
					row.Submission_Deadline__c = row.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c
                    row.Form_Type__c = row.Forms_Permission__r.Form_Allocation__r.Form_Type__c;
                    row.Form_Entry__c = row.Forms_Permission__r.Form_Allocation__r.Form_Entry__c;
					if(data.mapEntries[row.Id] != null){
						let entries = data.mapEntries[row.Id];
						entries.forEach(entry => {
							row.Form_Response_Entries__r.push(entry);
						});
					}
					if(row.Forms_Permission__r.Form_Allocation__r.Form_Heading__c == 'Mandatory'){
						lstformDataMan.push(row);
					}
					if(row.Forms_Permission__r.Form_Allocation__r.Form_Heading__c == 'Additional'){
						lstformDataAdd.push(row);
					}
					if(row.Forms_Permission__r.Form_Allocation__r.Form_Heading__c == 'Optional'){
						lstformDataOpt.push(row);
					}
				});
				this.formsTypes = [];
				let obj2 = {
					formtype : "Mandatory",
					formdata : lstformDataMan
				}
				this.formsTypes.push(obj2);
				this.showTabContextIN = 'mandatory';
				if(lstformDataAdd.length>0){
					let obj = {
						formtype : "Additional",
						formdata : lstformDataAdd
					}
					this.formsTypes.push(obj);
					if(this.showTabContextIN != 'mandatory'){
						this.showTabContextIN = 'additional';
					}
				}
				if(lstformDataOpt.length>0){
					let obj = {
						formtype : "Optional",
						formdata : lstformDataOpt
					}
					this.formsTypes.push(obj);
					if(this.showTabContextIN != 'mandatory' && this.showTabContextIN != 'additional'){
						this.showTabContextIN = 'optional';
					}
				}
				this.spinner = false;
			}) 
			.catch(error => {
				console.log("====IMCC_FORMS====setCurrentPageReference====");
				console.log(error);
				console.log("====IMCC_FORMS====setCurrentPageReference====");
				this.spinner = false;
				handleUIErrors(this,error);
			});
		}
	};
}