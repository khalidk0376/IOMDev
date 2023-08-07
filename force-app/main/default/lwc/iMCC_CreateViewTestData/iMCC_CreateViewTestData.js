import { LightningElement, wire, track, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import QuickActionPanel from "@salesforce/resourceUrl/QuickActionPanel";
import { loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import cemObj from '@salesforce/schema/Contact_Edition_Mapping__c';
import purchaseDataObj from '@salesforce/schema/Purchase_Data__c';
import userType from '@salesforce/schema/Contact_Edition_Mapping__c.Access_Type__c';
import boothType from '@salesforce/schema/Purchase_Data__c.Booth_Product_Type__c';
import getEixstingTestData from '@salesforce/apex/IMCC_CreateViewTestDataCTRL.getEixstingTestData';
import testDataCreated from '@salesforce/apex/IMCC_CreateViewTestDataCTRL.testDataCreated';
import cancelInvitation from '@salesforce/apex/IMCC_CreateViewTestDataCTRL.cancelInvitation';
import getUserLoginData from '@salesforce/apex/IMCC_LoginAsUser.getUserLoginData';
import sendEmailInvite from '@salesforce/apex/IMCC_CreateViewTestDataCTRL.sendEmailInvite';
import { handleErrors, showToast, handleUIErrors } from 'c/imcc_lwcUtility';
import LightningConfirm from 'lightning/confirm';
import NoteOnAfterSelectionTestData from '@salesforce/label/c.NoteOnAfterSelectionTestData';
import NoteOnBoothTypeOnlySelectionTestData from '@salesforce/label/c.NoteOnBoothTypeOnlySelectionTestData';
import NoteOnUserTypeOnlySelectionTestData from '@salesforce/label/c.NoteOnUserTypeOnlySelectionTestData';

export default class IMCC_CreateViewTestData extends LightningElement {

    label = {
        NoteOnAfterSelectionTestData,
        NoteOnBoothTypeOnlySelectionTestData,
        NoteOnUserTypeOnlySelectionTestData
    };


    viewTestScreen = true;
    createTestScreen = false;
    isDisable = false;
    @api className = 'IMCC_CreateViewTestData';
    @api comp_type = 'LWC';
    viewAccessTypeScreen = false;
    viewTestDataScreen = true;
    viewBoothTypeScreen = false;
    selectedCombinationScreen = false;
    @track lstOptionsUserType = [];
    //@track lstOptionsBoothType = [];
    selectedUserType = '';
    selectedBoothType = '';
    @track memberDetails = [];
    loginContactId = '';
    isSendEmailModal = false;
    @track showSpinner = false;
    isAccessSelectionBtnDisable = true;
    isBoothSelectionBtnDisable = true;
    isExecuting = false;
    noDataScreen = false;

    _recordId;
    //Public property
    @api
    get recordId(){
       return this._recordId;
    }

    set recordId(value){
        this._recordId = value;
        this.showTestData();
    }

    connectedCallback() {
        loadStyle(this, QuickActionPanel);
    }

    
    @wire(getObjectInfo, { objectApiName: cemObj }) cemObjInfo;
    @wire(getObjectInfo, { objectApiName: purchaseDataObj }) purchaseDataObjInfo;

    // Get Picklist values.
    @wire(getPicklistValues, { recordTypeId: '$cemObjInfo.data.defaultRecordTypeId', fieldApiName: userType })
    userTypes(data, error) {
        if (data && data.data && data.data.values) {
            data.data.values.forEach(objPicklist => {
                this.lstOptionsUserType.push({
                    label: objPicklist.label,
                    value: objPicklist.value
                });
            });
        } else if (error) {
            console.log(error);
        }
    };

    get lstOptionsBoothType() {
        return [
            { label: 'Space Only', value: 'Space Only' },
            { label: 'Shell Scheme', value: 'Shell Scheme' },
        ];
    }

    // // Get Picklist values.
    // @wire(getPicklistValues, { recordTypeId: '$purchaseDataObjInfo.data.defaultRecordTypeId', fieldApiName: boothType })
    // boothTypes(data, error) {
    //     if (data && data.data && data.data.values) {
    //         data.data.values.forEach(objPicklist => {
    //             this.lstOptionsBoothType.push({
    //                 label: objPicklist.label,
    //                 value: objPicklist.value
    //             });
    //         });
    //     } else if (error) {
    //         console.log(error);
    //     }
    // };

    showTestData() {
        getEixstingTestData({ editionId: this._recordId })
            .then(result => {
                console.log('result',JSON.stringify(result));
                if(result.length > 0){
                this.viewTestDataScreen = true;
                let tempCEM = result;
                tempCEM.forEach(cem => {
                    cem.Id = cem.Id;
                    cem.Name = cem.Name;
                    cem.accessType = cem.Access_Type__c;
                    cem.email = cem.Contact_Email__c;
                    cem.conId = cem.Contact__c;
                    let boothArray =[];
                    if(cem.Purchase_Data__r.length >0){
                       cem.Purchase_Data__r.forEach(pd => {
                            boothArray.push(pd.Booth_Product_Type__c);
                        });
                    }
                    let boothType = boothArray.join();
                    cem.selectedBoothType = boothType != null && boothType != ''?boothType:'';
                });
                this.memberDetails = tempCEM;
                
              }
              else{
                this.viewTestDataScreen = false;
                this.noDataScreen = true;
              }
            })
            .catch(error => {
                console.log('error', error);
                //this.startToast2('No Test Data Found');
            });
    }

    login() {
        this.showSpinner = true;
        testDataCreated({ editionId: this._recordId, userType: this.selectedUserType, boothType: this.selectedBoothType })
            .then(result => {
                this.showSpinner = false;
                if (result.error) {
                    //duplicate record found
                    let res = result.error;
                    this.loginContactId = res.split('_')[0];
                    let contName = res.split('_')[1];
                    //showToast(this, "Test User exists in system.Redirecting to its login Page", "error", "Duplicate found");
                    this.startToast2('Duplicate Found','Test User is already created : '+contName ,'Error');
                    this.loginNow();
                          
                }
                else {
                    this.loginContactId = result.success;
                    //showToast(this, 'Test user  has been created successfully', 'success', 'Success!')
                    this.startToast2('Success','Test user  has been created successfully','success');
                    this.loginNow();
                    
                }
            })
            .catch(error => {
                this.showSpinner = false;
                console.log('error', error);
                //this.showToast(this, error, 'error', 'Error!');
                this.startToast2('error',error,'error');
            })
            .finally(() => {
               this.cancel();
            })
    }

    selectAccessType() {
        this.viewAccessTypeScreen = true;
        this.viewTestDataScreen = false;
        this.viewBoothTypeScreen = false;
        this.selectedCombinationScreen = false;
        this.createTestScreen = true;
        this.viewTestScreen = false;
    }

    selectBoothType() {
        this.viewBoothTypeScreen = true;
        this.viewAccessTypeScreen = false;
        this.viewTestDataScreen = false;
        this.selectedCombinationScreen = false;
        this.isBoothSelectionBtnDisable = true;
    }

    backToBoothSelection(){
        this.viewBoothTypeScreen = true;
        this.viewAccessTypeScreen = false;
        this.viewTestDataScreen = false;
        this.selectedCombinationScreen = false;
    }

    previousScreen() {
        this.viewAccessTypeScreen = true;
        this.viewTestDataScreen = false;
        this.viewBoothTypeScreen = false;
        this.selectedBoothType = '';
        this.selectedCombinationScreen = false;
    }

    createData() {
        this.viewBoothTypeScreen = false;
        this.viewAccessTypeScreen = false;
        this.viewTestDataScreen = false;
        this.selectedCombinationScreen = true;
    }

    handleUserTypeChange(event) {
        this.selectedUserType = event.detail.value;
        this.isAccessSelectionBtnDisable = false;
        
    }

    handleBoothTypeChange(event) {
        this.selectedBoothType = event.detail.value;
        this.isBoothSelectionBtnDisable = false;
    }

    cancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
        //this.dispatchEvent(new CustomEvent('close'));
    }

    selectedMailInviteCEMId = '';
    handleSendInviteClick(event) {
        
        this.selectedMailInviteCEMId = event.target.dataset.id;
        this.isSendEmailModal = true;
    }

    async handleCancleInviteClick(event) {
        const selectedCEMId = event.target.dataset.id;
        if (selectedCEMId) {
            const result = await LightningConfirm.open({
                message: 'Are you sure, you want to cancel the Invite.',
                variant: 'headerless',
                label: 'this is the aria-label value',
            });
            if (result) {
                cancelInvitation({ cemId: selectedCEMId })
                    .then(() => {
                        this.showTestData();
                        //showToast(this, 'Invitation of this contact is canceled successfully', 'success', 'Success!');
                        this.startToast2('Success','Invitation of this contact is cancelled successfully','success');
                    })
                    .catch(error => {
                        handleErrors(this, error);
                    })
                    .finally(() => {
                        this.cancel();
                        this.spinner = false;
                    })
            }
        }
        else {
        }
    }

    handleLoginCommunityClick(event){
        const selectedCEMId = event.target.dataset.id; 
        let isUserFound = false;
        if(selectedCEMId){
            this.memberDetails.forEach(cem => {
                if(cem.Id == selectedCEMId){
                    this.loginContactId = cem.Contact__c;
                    isUserFound = true;
                }
            });
        }
        if(isUserFound){
            this.loginNow();
        }
        this.cancel();
    }

    loginNow() {
        this.isExecuting = true;
        getUserLoginData({ contactId: this.loginContactId})
            .then(data => {
                if (data.UserId == "") {
                    this.startToast2('Error','Community User Not Found.','Error');
                    //showToast(this,"Community User Not Found.","error","Error");
                }
                else {
                    let url = data.BaseURL + '/servlet/servlet.su?oid=' + data.OrgId + '&retURL= ' + '&sunetworkid=' + data.NetworkId + '&sunetworkuserid=' + data.UserId;
                    setTimeout(function(){
                        window.open(url, "_blank");
                    },500);
                }
                this.isExecuting = false;
            })
            .catch(error => {

                this.isExecuting = false;
                handleUIErrors(this, error);
            });
        //await this.sleep(2000);
    }

    sleep(ms) {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    closeModal() {
        this.isSendEmailModal = false;
    }

    emailId = '';
    handleEmailChange(event){
        this.emailId = event.target.value;
    }

    sendEmail(){
        let emailpattern = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,15})+$/;
        let isEmailValid = emailpattern.test(this.emailId);
        let isvalid = true;
        if(!isEmailValid && !this.isDisable){
            //showToast(this,"Please enter valid email address.","error","Validation Error");
            this.startToast2('Error','Please enter valid email address.','Error');
            isvalid = false;
        }
        if(isvalid){
            sendEmailInvite({cemId:this.selectedMailInviteCEMId, emailAddress : this.emailId})
            .then(() => {
                this.showTestData();
                //showToast(this, 'Invitation of this contact is send successfully', 'success', 'Success!');
                this.startToast2('Success','Invitation of this contact is send successfully','success');
            })
            .catch(error => {
                handleErrors(this, error);
            })
            .finally(() => {
                this.selectedMailInviteCEMId = '';
                this.isSendEmailModal = false;
                this.cancel();
            })
        }        
    }

    get isRequired(){
        return this.isDisable?false:true;
    } 

    startToast2(title,msg,variant){
        let event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}