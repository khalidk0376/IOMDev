import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import fetchAccountLst from '@salesforce/apex/IMCC_AccountSelectionCtrl.fetchAccounts';
import IMCCNoAccountAccess from '@salesforce/label/c.IMCCNoAccountAccess';
import getEditionName from '@salesforce/apex/IMCC_AccountSelectionCtrl.getEditionName';

import { handleUIErrors, redirect } from 'c/imcc_lwcUtility';
import communityURL from '@salesforce/label/c.CommunityURL';
export default class IMCC_AccountSelection extends NavigationMixin(LightningElement) {

    @track selectedValue;
    @track accLst;
    @track eventcode;
    @track showAccountPage = false;
    @track noActiAccError = false;
    @track noActiAccErrorEdition = false;
    @track editionName;
    label = IMCCNoAccountAccess;

    @track methodName;
    className = 'iMCC_AccountSelection';
    comp_type = 'LWC';

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.eventcode = currentPageReference.state.edcode;
        }
        this.doInit();
    };

    doInit() {
        this.fetchAccount(this.eventcode);
    }

    connectedCallback() { // invoke the method when component rendered or loaded                    
        window.addEventListener("message", this.handleVFResponse.bind(this), false);
    };

    handleVFResponse(message) {
        // check the origin match for both source and target
        //if (message.origin === "https://servcloud-globalexhibitions.cs24.force.com") {
        if (message.origin === communityURL) {
            if (message.data == "afterMaximize") {
                this.template.querySelectorAll(".chatWindowFrame")[0].height = "500px";
                this.template.querySelectorAll(".chatWindowFrame")[0].width = "300px";
            }
            if (message.data == "onSettingsCallCompleted" || message.data == "afterMinimize" || message.data == "afterDestroy") {
                this.template.querySelectorAll(".chatWindowFrame")[0].height = "50px";
                this.template.querySelectorAll(".chatWindowFrame")[0].width = "205px";
            }
            if (message.data == "reloadFrame") {
                this.template.querySelectorAll(".chatWindowFrame")[0].src = this.template.querySelectorAll(".chatWindowFrame")[0].src;
            }
        }
    };

    openTooltip(event) {
        let accId = event.currentTarget.dataset.accId;

        const el2 = this.template.querySelectorAll("div[id^='001']");
        if (el2.length > 0) {
            el2.forEach(item => {
                if (item.id.indexOf(accId) < 0) {
                    item.classList.add("slds-fall-into-ground");
                }
            });
        }

        const el = this.template.querySelector("div[id^='" + accId + "']");
        if (el && el.classList) {
            el.classList.toggle("slds-fall-into-ground");
        }
    }

    fetchAccount(eventcode) {
        this.methodName = 'fetchAccount';
        fetchAccountLst({ eventcode: eventcode })
            .then(result => {
                let data = JSON.parse(JSON.stringify(result.acc));
                if (data.length == 0) {
                    if (eventcode == '' || eventcode == undefined) {
                        this.noActiAccError = true;
                    }
                    else {
                        this.fetchEditionName(this.eventcode);
                        this.noActiAccErrorEdition = true;
                    }
                }
                else if (data.length == 1) {
                    var accountId = data[0].Id;
                    if (eventcode == '' || eventcode == undefined) {
                        this.redirect('editionselection__c', { "accId": accountId });
                    }
                    else {
                        this.redirect('Overview__c', { "accId": accountId, "edcode": eventcode });
                    }
                }
                else {
                    this.showAccountPage = true;
                    let contactEditionMap = JSON.parse(JSON.stringify(result.cem));
                    contactEditionMap = contactEditionMap.reduce((r, a) => {
                        r[a.Account__c] = [...r[a.Account__c] || [], a];
                        return r;
                    }, {});
                    data = [];
                    for (let key in contactEditionMap) {
                        let d = contactEditionMap[key];
                        let editions = [];
                        d.forEach(item2 => {
                            if (item2.Edition__r) {
                                if (item2.Edition__r.Customer_Center_Status__c == 'Active' || (item2.Edition__r.Customer_Center_Status__c == 'In Progress' && item2.isTestUser__c == true)) {
                                    editions.push({ Id: item2.Edition__c, Name: item2.Edition__r.Name, Code: item2.Edition__r.Edition_Code__c });
                                }

                            }
                        });

                        if (d.length > 0 && d[0].Account__r) {
                            data.push({
                                Id: d[0].Account__c,
                                Name: d[0].Account__r.Name,
                                eventList: editions,
                                eventCount: editions.length,
                                isMoreThanOne: editions.length > 1 ? true : false
                            });
                        }
                    }
                    this.accLst = data;
                }
            })
            .catch(error => {
                this.error = error;
                console.error('Error ', error);
                handleUIErrors(this, error);
            });
    };

    logOut() {
        localStorage.removeItem('UserSession');
        let url = location.host;
        if (this.eventcode == '' || this.eventcode == undefined || this.eventcode == null) {
            location.href = '../secur/logout.jsp?retUrl=https://' + url + '/IMCC/IMCC_UserLogin';
        }
        else {
            location.href = '../secur/logout.jsp?retUrl=https://' + url + '/IMCC/IMCC_UserLogin?edcode=' + this.eventcode;
        }
    };

    selectedRec(event) {
        var accountId = event.target.dataset.accId;
        if (this.eventcode == null || this.eventcode == undefined) {
            this.redirect('editionselection__c', { "accId": accountId });
        }
        else {
            this.redirect('Overview__c', { "accId": accountId, "edcode": this.eventcode });
        }
    };

    handleDialogClose() {
        this.noActiAccError = false;
        this.logOut();
    };

    handleDialogClose2() {
        this.noActiAccErrorEdition = false;
        this.logOut();
    };

    fetchEditionName(eventcode) {
        this.methodName = 'fetchEditionName';
        getEditionName({ eventcode: eventcode })
            .then(result => {
                this.editionName = result;
            })
            .catch(error => {
                this.error = error;
                console.error('Error ', error);
                handleUIErrors(this, error);
            });
    };

    redirect(pageName, paramObj) {
        redirect(this, NavigationMixin.Navigate, pageName, paramObj);
    };

}