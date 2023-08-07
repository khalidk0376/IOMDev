import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getContact from '@salesforce/apex/IMCC_ManageTeamMembersCEM.getContact';
import matchedContact from '@salesforce/apex/IMCC_ManageTeamMembersCEM.matchedContact';
import contactToBeCreated from '@salesforce/apex/IMCC_ManageTeamMembersCEM.contactToBeCreated';
import teamMemberList from '@salesforce/apex/IMCC_ManageTeamMembersCEM.teamMemberList';
import cancelInvitation from '@salesforce/apex/IMCC_ManageTeamMembersCEM.cancelInvitation';
import reSendInvitation from '@salesforce/apex/IMCC_ManageTeamMembersCEM.reSendInvitation';
import checkPrimaryCEM from '@salesforce/apex/IMCC_ManageTeamMembersCEM.checkPrimaryCEM';
import cancelInvitationIfPrimary from '@salesforce/apex/IMCC_ManageTeamMembersCEM.cancelInvitationIfPrimary';
import checkCurrentUser from '@salesforce/apex/IMCC_ManageTeamMembersCEM.checkCurrentUser';
import { handleErrors, showToast, redirect } from 'c/imcc_lwcUtility';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import Role_FIELD from '@salesforce/schema/Contact_Edition_Mapping__c.Role__c';
import ContactEditionMapping_OBJECT from '@salesforce/schema/Contact_Edition_Mapping__c';
import LightningConfirm from 'lightning/confirm';
import Alert_Primary_CEM from '@salesforce/label/c.Alert_Primary_CEM';
import Cancel_Invite from '@salesforce/label/c.Cancel_Invite';
import Accepted_Logged_in from '@salesforce/label/c.Accepted_Logged_in';
import ExistingEmailIdUser from '@salesforce/label/c.ExistingEmailIdUser';
import AddingTeamMemberText from '@salesforce/label/c.Adding_Team_Member_Text';

export default class ImccTeamsManager extends LightningElement {
    eventCode;
    accountId;
    tabId;
    value = 'inProgress';
    @track spinner;
    @track roleOptions = [];
    @track searchConList = [];
    @track memberList = [];
    @track memberDetails;
    @track isOpenNewTeamMemberModal;
    @track isNewInvitationSent;
    @track selectedRecord;
    @track isPrimary = false;
    disbleResend = false;
    memberDataFound = false;
    isOpenViewTeamMemberModal = false;
    isDisable = false;
    isSecondaryAdmin = false;
    showRemoveTeamMemberPopup = false;
    showConfirmationPopup = false;
    selectedCEMToRemove;
    currentLoginUser;

    label = { Alert_Primary_CEM, Cancel_Invite, Accepted_Logged_in, ExistingEmailIdUser, AddingTeamMemberText };

    // @wire(getObjectInfo,{objectApiName:ContactEditionMapping_OBJECT}) 
    // objectInfo;

    // @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: Role_FIELD })
    // handleResp(result,error){
    //     if(result){
    //         console.log('Field Info: ');
    //         console.log(JSON.stringify(result));
    //         if(result.data){
    //               this.roleOptions = result.data.values;
    //         }
    //     }
    //     else if(error){
    //         handleErrors(this,error);
    //     }
    // };

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.eventCode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            this.checkCurrentCEM();
            this.teamList();
        }
    };

    handleEmailSearch(event) {
        let searchTerm = event.target.value;
        //if(searchTerm.length>2 || searchTerm.length==0){
        console.log('searchTerm===', searchTerm);
        this.fetchContact(searchTerm);
        //}
    };

    fetchContact(searchText) {
        this.selectedRecord = {};
        this.searchConList = [];
        getContact({ searchText: searchText })
            .then(res => {
                const data = res;
                if (searchText != '' && data.length > 0) {
                    this.searchConList = data;
                }
                // else if(searchText!='' && data.length==0){
                //     showToast(this,"No contact found","error","Error")                
                // }      
            })
            .catch(error => {
                handleErrors(this, error);
            });
    };

    selectContact(event) {
        let index = parseInt(event.currentTarget.dataset.index, 10);
        this.selectedRecord = this.searchConList[index];
        this.searchConList = [];
        console.log(JSON.stringify(this.selectedRecord));
    };

    async handleConfirmClick() {
        if (this.selectedRecord && this.selectedRecord.Id) {
            const result = await LightningConfirm.open({
                message: 'Are you sure, you want to invite selected contact?',
                variant: 'headerless',
                label: 'this is the aria-label value',
            });
            if (result) {
                this.addExistingContactToMyMeam();
            }
        }
        else {
            this.addNewTeamMember();
        }
    }

    selectedCEMId2 = '';
    async handleCancleInviteClick(event) {
        this.selectedCEMId2 = event.currentTarget.dataset.id;
        this.selectedCEMToRemove = event.currentTarget.dataset.name;
        this.isPrimary = false;
        checkPrimaryCEM({ cemId: this.selectedCEMId2 })
            .then((res) => {
                console.log('===checkPrimaryCEM', res);
                if (res.length > 0) {
                    this.isPrimary = true;
                    console.log('@@@@1' + this.isPrimary);
                }
                this.checkingPrimary();
            })
            .catch(error => {
                handleErrors(this, error);
            });
    }

    async checkingPrimary() {
         this.showRemoveTeamMemberPopup = true;
    }

    onNoClick(){
        this.showRemoveTeamMemberPopup = false;
        this.selectedCEMToRemove = '';
    }

    onYesClick(){
        this.showConfirmationPopup = true;
        this.showRemoveTeamMemberPopup = false;
    }

    onUndo(){
        this.showRemoveTeamMemberPopup = false;
        this.showConfirmationPopup = false;
    }

    onkeepChange(){
        if (this.selectedCEMId2 && this.isPrimary) {

               cancelInvitationIfPrimary({ cemId: this.selectedCEMId2, eventCode: this.eventCode, accountId: this.accountId })
                    .then(() => {
                        this.teamList();
                        //showToast(this, 'Invitation of this contact is canceled successfully', 'success', 'Success!');
                    })
                    .catch(error => {
                        handleErrors(this, error);
                    })
                    .finally(() => {
                        this.spinner = false;
                        this.showConfirmationPopup = false;
                    })
        }
        else if (this.selectedCEMId2 && this.isPrimary == false) {
            console.log('@@@@111111111' + this.isPrimary);

            cancelInvitation({ cemId: this.selectedCEMId2, eventCode: this.eventCode, accountId: this.accountId  })
            .then(() => {
                this.teamList();
                //showToast(this, 'Invitation of this contact is canceled successfully', 'success', 'Success!');
            })
            .catch(error => {
                handleErrors(this, error);
            })
            .finally(() => {
                this.spinner = false;
                this.showConfirmationPopup = false;
            })
        }
        
    }


    async handleReSendInviteClick(event) {
        const selectedCEMId = event.currentTarget.dataset.id;
        if (selectedCEMId) {
            const result = await LightningConfirm.open({
                message: 'Are you sure, you want to Re-send the invite of selected contact',
                variant: 'headerless',
                label: 'this is the aria-label value',
            });
            if (result) {
                reSendInvitation({ cemId: selectedCEMId, eventCode: this.eventCode, accountId: this.accountId  })
                    .then(result => {
                        showToast(this, 'Invitation send to this contact successfully', 'success', 'Success!');
                        this.spinner = false;
                    })
                    .catch(error => {
                        this.spinner = false;
                        handleErrors(this, error);
                    })
            }
        }

    }

    checkCurrentCEM(){
        checkCurrentUser({ eventCode: this.eventCode, accountId: this.accountId })
            .then(res => {
                console.log('res===', JSON.stringify(res));
               if (res !== undefined) {
                this.roleOptions = [];
                    let userData = res.currentUser;
                    let roleValues = res.currentRole[0].Customer_Role__c;
                    let secondaryAdmin = res.secondaryUser;
                    let roleArray = roleValues.includes(',') ? roleValues.split(',') : roleValues;
                    console.log('roleArray===', roleArray);
                    if(userData.length > 0){
                        this.currentLoginUser = userData[0];
                        this.isSecondaryAdmin = userData[0].Role__c == 'Secondary Admin'?true:false;
                    }
                    if (userData[0].Role__c == 'Platform Admin') {
                        if(secondaryAdmin.length > 0){
                            roleArray = roleArray.filter(e => e !== 'Secondary Admin');
                            roleArray.forEach(i => {
                                this.roleOptions.push({label: i,
                                    value: i});
                                    
                            });
                        }
                        else{
                            roleArray.forEach(i => {
                                this.roleOptions.push({label: i,
                                    value: i});
                                    
                            });
                        }
                    }
                    else if (userData[0].Role__c == 'Secondary Admin') {
                        roleArray.forEach(i => {
                            this.roleOptions.push({label: i,
                                value: i});
                                
                        });
                    }
                    console.log('roleOptions===', this.roleOptions);
                }
            })
            .catch(error => {
                handleErrors(this, error);
            })
    }


    addNewTeamMember() {
        this.isNewInvitationSent = false;
        this.checkCurrentCEM();
        this.isOpenNewTeamMemberModal = true;
    };

    closeNewTeamMemberModal() {
        this.isOpenNewTeamMemberModal = false;
       // this.roleOptions.clear();
    };

    sendNewTeamMemberInvitation() {
        let emailpattern = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,15})+$/;
        let isEmailValid = emailpattern.test(this.emailId);
        this.firstName = this.firstName.trim();
        let isvalid = true;
        if (!this.firstName) {
            showToast(this, "Please enter first name.", "error", "Validation Error");
            isvalid = false;
        }
        else if (!this.lastName) {
            showToast(this, "Please enter last name.", "error", "Validation Error");
            isvalid = false;
        }
        else if (!isEmailValid && !this.isDisable) {
            showToast(this, "Please enter valid email address.", "error", "Validation Error");
            isvalid = false;
        }
        else if (!this.accessType && !this.isDisable) {
            showToast(this, "Please enter valid role.", "error", "Validation Error");
            isvalid = false;
        }
        if (isvalid) {
            this.addTeamMember();
        }
    };

    handleChange(event) {
        this.value = event.detail.value;
    };

    addExistingContactToMyMeam() {
        this.spinner = true;
        matchedContact({
            contactId: this.selectedRecord.Id,
            eventCode: this.eventCode,
            accountId: this.selectedRecord.AccountId
        })
            .then(result => {
                showToast(this, 'An invitation email will be sent to the email "' + this.selectedRecord.Email + '"', 'success', 'Success!');
                this.selectedRecord = {};
                this.spinner = false;
            })
            .catch(error => {
                this.spinner = false;
                handleErrors(this, error);
            })
    }

    addTeamMember() {
        this.spinner = true;
        let isActiveUserEmailExist = false;
        if(this.currentLoginUser !== undefined){
           isActiveUserEmailExist = (this.currentLoginUser.Contact_Email__c == this.emailId)?true:false;
        }
        if(this.memberList !== undefined){
            this.memberList.forEach(i => {
                if(i.Contact_Email__c == this.emailId){
                    isActiveUserEmailExist = true;
                }
            });
        }
        if(isActiveUserEmailExist){
            this.spinner = false;
            showToast(this, ExistingEmailIdUser, 'error', 'Error!');
            this.isOpenNewTeamMemberModal = false;
        }
        else{
            contactToBeCreated({
                firstName: this.firstName,
                lastName: this.lastName,
                emailId: this.emailId,
                role: this.accessType,
                eventCode: this.eventCode,   
                accountId: this.accountId
            })
                .then(result => {
                    this.firstName = '';
                    this.lastName = '';
                    this.emailId = '';
                    this.roleOptions = [];
                    this.teamList();
                    this.isNewInvitationSent = true;
                })
                .catch(error => {
                    handleErrors(this, error);
                })
                .finally(() => {
                    this.spinner = false;
                })
        }
        isActiveUserEmailExist = false;
    };

    get isDataFound() {
        return this.searchConList && this.searchConList.length > 0 ? true : false;
    };

    teamList() {
        teamMemberList({ eventCode: this.eventCode, accountId: this.accountId })
            .then(res => {
                if (res.length > 0) {
                const data = JSON.parse(JSON.stringify(res));
                this.memberList = [];
                data.forEach(i => {
                    if(i.Id !== this.currentLoginUser.Id){
                        let sentDate = i.Email_Sent__c ? i.Email_Sent__c.split("T")[0].split('-') : [];
                        i.Email_Sent__c = sentDate && sentDate.length == 3 ? sentDate[2] + ' ' + this.getMonth(sentDate[1]) + ' ' + sentDate[0] : '';
                        sentDate = i.First_Login_Date_Time__c ? i.First_Login_Date_Time__c.split("T")[0].split('-') : [];
                        i.First_Login_Date_Time__c = sentDate && sentDate.length == 3 ? sentDate[2] + ' ' + this.getMonth(sentDate[1]) + ' ' + sentDate[0] : '';
                        i.isActionVisible = (this.isSecondaryAdmin && (!i.isSecondary__c || i.Role__c == 'Platform Admin'))?false:true;
                        this.memberList.push(i);
                    }
                    
                })
                
                    this.memberDataFound = true;
                    
                    console.log('memberList===', JSON.stringify(this.memberList));
                }
            })
    };

    getMonth(month) {
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

    viewMemberDetails(event) {
        const selectedCEMId = event.currentTarget.dataset.id;
        const tempCEM = [];
        console.log('selectedCEMId===', JSON.stringify(selectedCEMId));
        console.log('this.memberList===', JSON.stringify(this.memberList));
        this.memberList.forEach(cem => {
            if (cem.Id == selectedCEMId) {
                if (cem.Email_Sent__c && cem.Relationship_Status__c == 'Active') {
                    this.disbleResend = true;
                }
                tempCEM.Name = cem.Contact__r.Name;
                tempCEM.Job = cem.Contact__r.Title;
                tempCEM.Role = cem.Contact__r.Contact_Type__c;
                tempCEM.AdminPrivilage = cem.Role__c;
                tempCEM.Email = cem.Contact_Email__c;
                tempCEM.Phone = cem.Contact__r.MobilePhone;
                //tempCEM.workingHrs = cem.Contact.Email;
                tempCEM.AddedOn = cem.Email_Sent__c;
                tempCEM.Location = cem.Contact__r.MailingCountry;
                console.log('tempCEM===', JSON.stringify(tempCEM));
            }

        });
        this.memberDetails = tempCEM;
        this.isOpenViewTeamMemberModal = true;
    }

    closeTeamMemberDetailModal() {
        this.isOpenViewTeamMemberModal = false;
    };

    firstName = '';
    lastName = '';
    emailId = '';
    accessType = '';
    tempEmail = '';
    handleContactFieldChange(event) {
        let fieldName = event.target.name;
        if (fieldName == 'firstname') {
            this.firstName = event.target.value;
        }
        if (fieldName == 'lastname') {
            this.lastName = event.target.value;
        }
        if (fieldName == 'email') {
            this.emailId = event.target.value;
            this.tempEmail = event.target.value;
        }
        if (fieldName == 'role') {
            this.accessType = event.target.value;
        }
        console.log('firstName===', this.firstName);
        console.log('lastName===', this.lastName);
        console.log('emailId===', this.emailId);
    };

    get isRequired() {
        return this.isDisable ? false : true;
    }
}