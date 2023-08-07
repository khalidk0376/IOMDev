import { LightningElement, track, wire, api } from 'lwc';
import fetchEventTabDetail from "@salesforce/apex/IMCC_HeaderCtrl.fetchUserTabDetails";
import getTabId from '@salesforce/apex/IMCC_HomeCtrl.getTabId';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { handleErrors, handleUIErrors, showToast, gotoPage } from 'c/imcc_lwcUtility';
import { loadScript } from 'lightning/platformResourceLoader';
import jquery from '@salesforce/resourceUrl/Imcc_jquery';

export default class IMCC_customTabs extends LightningElement {

    @track tabId;
    @track tabContext = [];
    @track tabLayout;
    @track tabHeader;
    @track tabSection1;
    @track tabSection2;
    @track tabSection3;
    @track showHeader2Column = false;
    @track showHeader3Column = false;
    @track show3Column = false;

    @track methodName;
    className = 'iMCC_customTabs';
    comp_type = 'LWC';

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            console.log('Tab Code Custom ' + this.tabId);
            var self=this;
            loadScript(this, jquery)
            .then(()=>{                
                self.doInit();
            })
            .catch(error => {
                showToast(this, error, 'error', 'Error');
            })           
        }
    }

    doInit() {
        this.fetchTabDetails(this.eventcode, this.accountId, this.tabId);
    }
    fetchTabDetails(eventCode, accountId, tabId) {
        this.methodName = 'fetchTabDetails';
        fetchEventTabDetail({ eventCode: eventCode, accountId: accountId, tabId: tabId })
            .then(result => {
                if (result.tabContextLst) {
                    this.tabContext = result.tabContextLst;
                    console.log('Result111 ', JSON.stringify(result.tabContextLst));
                    if(this.tabContext != null){
                        if(this.tabContext.length > 0){
                            if(this.tabContext[0] != null){
                                if(this.tabContext[0].Event_Tab__r != null){
                                    this.tabLayout = this.tabContext[0].Event_Tab__r.Layout_Type__c;
                                }
                            }
                        }
                    }
                    console.log('Layout ', this.tabLayout);

                    if (this.tabLayout == '3 Column') {
                        this.show3Column = true;
                        this.showHeader2Column = false;
                        this.showHeader3Column = false;
                        console.log('3 column');
                    }
                    if (this.tabLayout == 'Header and 2 Column') {
                        this.show3Column = false;
                        this.showHeader2Column = true;
                        this.showHeader3Column = false;
                        console.log('Header 2 column');
                    }
                    if (this.tabLayout == 'Header and 3 Column') {
                        this.show3Column = false;
                        this.showHeader2Column = false;
                        this.showHeader3Column = true;
                        console.log('Header 3 column');
                    }
                    this.getTabIds();
                }


            })
            .catch(error => {
                window.console.log('error...@@@@' + JSON.stringify(error));
                handleUIErrors(this, error);
            });
    }


    getTabIds() {
        this.methodName = 'getTabIds';
        getTabId({ edcode: this.eventcode, accountId: this.accountId })
            .then(res => {
                const tabIds = res.tab;
                const cem = res.cem;
                //alert('11');
                let data = '';
                this.tabContext.forEach(tabItem => {

                    if (this.show3Column) {
                        if (tabItem.Section_1__c && tabItem.Section_1__c.includes('https://tabId=')) {
                            let url = '';
                            tabIds.forEach(item => {
                                url = this.getPageUrlByType(item.Tab_Type__c, item.Standard_Tab_Type__c);
                                tabItem.Section_1__c = tabItem.Section_1__c.split('"https://tabId=' + item.ExtTabId__c + '"').join('"' + url + '?edcode=' + this.eventcode + '&tabId=' + item.Tab_Code__c + '&accId=' + this.accountId + '" data-tabid="' + item.Tab_Code__c + '" data-tabtype="' + item.Tab_Type__c + '" data-stdtabtype="' + item.Standard_Tab_Type__c + '"');
                            });
                            tabItem.Section_1__c = tabItem.Section_1__c.split('"https://tabId=').join('"/IMCC/s/?edcode=' + this.eventcode + '&accId=' + this.accountId + '" data-tabid="home"');
                        }

                        if (tabItem.Section_2__c && tabItem.Section_2__c.includes('https://tabId=')) {
                            let url = '';
                            tabIds.forEach(item => {
                                url = this.getPageUrlByType(item.Tab_Type__c, item.Standard_Tab_Type__c);
                                tabItem.Section_2__c = tabItem.Section_2__c.split('"https://tabId=' + item.ExtTabId__c + '"').join('"' + url + '?edcode=' + this.eventcode + '&tabId=' + item.Tab_Code__c + '&accId=' + this.accountId + '" data-tabid="' + item.Tab_Code__c + '" data-tabtype="' + item.Tab_Type__c + '" data-stdtabtype="' + item.Standard_Tab_Type__c + '"');
                            });
                            tabItem.Section_2__c = tabItem.Section_2__c.split('"https://tabId=').join('"/IMCC/s/?edcode=' + this.eventcode + '&accId=' + this.accountId + '" data-tabid="home"');
                        }

                        if (tabItem.Section_3__c && tabItem.Section_3__c.includes('https://tabId=')) {
                            let url = '';
                            tabIds.forEach(item => {
                                url = this.getPageUrlByType(item.Tab_Type__c, item.Standard_Tab_Type__c);
                                tabItem.Section_3__c = tabItem.Section_3__c.split('"https://tabId=' + item.ExtTabId__c + '"').join('"' + url + '?edcode=' + this.eventcode + '&tabId=' + item.Tab_Code__c + '&accId=' + this.accountId + '" data-tabid="' + item.Tab_Code__c + '" data-tabtype="' + item.Tab_Type__c + '" data-stdtabtype="' + item.Standard_Tab_Type__c + '"');
                            });
                            tabItem.Section_3__c = tabItem.Section_3__c.split('"https://tabId=').join('"/IMCC/s/?edcode=' + this.eventcode + '&accId=' + this.accountId + '" data-tabid="home"');
                        }
                    }

                    if (this.showHeader2Column) {
                        if (tabItem.Header__c && tabItem.Header__c.includes('https://tabId=')) {
                            let url = '';
                            tabIds.forEach(item => {
                                url = this.getPageUrlByType(item.Tab_Type__c, item.Standard_Tab_Type__c);
                                tabItem.Header__c = tabItem.Header__c.split('"https://tabId=' + item.ExtTabId__c + '"').join('"' + url + '?edcode=' + this.eventcode + '&tabId=' + item.Tab_Code__c + '&accId=' + this.accountId + '" data-tabid="' + item.Tab_Code__c + '" data-tabtype="' + item.Tab_Type__c + '" data-stdtabtype="' + item.Standard_Tab_Type__c + '"');
                            });
                            tabItem.Header__c = tabItem.Header__c.split('"https://tabId=').join('"/IMCC/s/?edcode=' + this.eventcode + '&accId=' + this.accountId + '" data-tabid="home"');
                        }

                        if (tabItem.Section_1__c && tabItem.Section_1__c.includes('https://tabId=')) {
                            let url = '';
                            tabIds.forEach(item => {
                                url = this.getPageUrlByType(item.Tab_Type__c, item.Standard_Tab_Type__c);
                                tabItem.Section_1__c = tabItem.Section_1__c.split('"https://tabId=' + item.ExtTabId__c + '"').join('"' + url + '?edcode=' + this.eventcode + '&tabId=' + item.Tab_Code__c + '&accId=' + this.accountId + '" data-tabid="' + item.Tab_Code__c + '" data-tabtype="' + item.Tab_Type__c + '" data-stdtabtype="' + item.Standard_Tab_Type__c + '"');
                            });
                            tabItem.Section_1__c = tabItem.Section_1__c.split('"https://tabId=').join('"/IMCC/s/?edcode=' + this.eventcode + '&accId=' + this.accountId + '" data-tabid="home"');
                        }

                        if (tabItem.Section_2__c && tabItem.Section_2__c.includes('https://tabId=')) {
                            let url = '';
                            tabIds.forEach(item => {
                                url = this.getPageUrlByType(item.Tab_Type__c, item.Standard_Tab_Type__c);
                                tabItem.Section_2__c = tabItem.Section_2__c.split('"https://tabId=' + item.ExtTabId__c + '"').join('"' + url + '?edcode=' + this.eventcode + '&tabId=' + item.Tab_Code__c + '&accId=' + this.accountId + '" data-tabid="' + item.Tab_Code__c + '" data-tabtype="' + item.Tab_Type__c + '" data-stdtabtype="' + item.Standard_Tab_Type__c + '"');
                            });
                            tabItem.Section_2__c = tabItem.Section_2__c.split('"https://tabId=').join('"/IMCC/s/?edcode=' + this.eventcode + '&accId=' + this.accountId + '" data-tabid="home"');
                        }
                    }

                    if (this.showHeader3Column) {
                        if (tabItem.Header__c && tabItem.Header__c.includes('https://tabId=')) {
                            let url = '';
                            tabIds.forEach(item => {
                                url = this.getPageUrlByType(item.Tab_Type__c, item.Standard_Tab_Type__c);
                                tabItem.Header__c = tabItem.Header__c.split('"https://tabId=' + item.ExtTabId__c + '"').join('"' + url + '?edcode=' + this.eventcode + '&tabId=' + item.Tab_Code__c + '&accId=' + this.accountId + '" data-tabid="' + item.Tab_Code__c + '" data-tabtype="' + item.Tab_Type__c + '" data-stdtabtype="' + item.Standard_Tab_Type__c + '"');
                            });
                            tabItem.Header__c = tabItem.Header__c.split('"https://tabId=').join('"/IMCC/s/?edcode=' + this.eventcode + '&accId=' + this.accountId + '" data-tabid="home"');
                        }

                        if (tabItem.Section_1__c && tabItem.Section_1__c.includes('https://tabId=')) {
                            let url = '';
                            tabIds.forEach(item => {
                                url = this.getPageUrlByType(item.Tab_Type__c, item.Standard_Tab_Type__c);
                                tabItem.Section_1__c = tabItem.Section_1__c.split('"https://tabId=' + item.ExtTabId__c + '"').join('"' + url + '?edcode=' + this.eventcode + '&tabId=' + item.Tab_Code__c + '&accId=' + this.accountId + '" data-tabid="' + item.Tab_Code__c + '" data-tabtype="' + item.Tab_Type__c + '" data-stdtabtype="' + item.Standard_Tab_Type__c + '"');
                            });
                            tabItem.Section_1__c = tabItem.Section_1__c.split('"https://tabId=').join('"/IMCC/s/?edcode=' + this.eventcode + '&accId=' + this.accountId + '" data-tabid="home"');
                        }

                        if (tabItem.Section_2__c && tabItem.Section_2__c.includes('https://tabId=')) {
                            let url = '';
                            tabIds.forEach(item => {
                                url = this.getPageUrlByType(item.Tab_Type__c, item.Standard_Tab_Type__c);
                                tabItem.Section_2__c = tabItem.Section_2__c.split('"https://tabId=' + item.ExtTabId__c + '"').join('"' + url + '?edcode=' + this.eventcode + '&tabId=' + item.Tab_Code__c + '&accId=' + this.accountId + '" data-tabid="' + item.Tab_Code__c + '" data-tabtype="' + item.Tab_Type__c + '" data-stdtabtype="' + item.Standard_Tab_Type__c + '"');
                            });
                            tabItem.Section_2__c = tabItem.Section_2__c.split('"https://tabId=').join('"/IMCC/s/?edcode=' + this.eventcode + '&accId=' + this.accountId + '" data-tabid="home"');
                        }

                        if (tabItem.Section_3__c && tabItem.Section_3__c.includes('https://tabId=')) {
                            let url = '';
                            tabIds.forEach(item => {
                                url = this.getPageUrlByType(item.Tab_Type__c, item.Standard_Tab_Type__c);
                                tabItem.Section_3__c = tabItem.Section_3__c.split('"https://tabId=' + item.ExtTabId__c + '"').join('"' + url + '?edcode=' + this.eventcode + '&tabId=' + item.Tab_Code__c + '&accId=' + this.accountId + '" data-tabid="' + item.Tab_Code__c + '" data-tabtype="' + item.Tab_Type__c + '" data-stdtabtype="' + item.Standard_Tab_Type__c + '"');
                            });
                            tabItem.Section_3__c = tabItem.Section_3__c.split('"https://tabId=').join('"/IMCC/s/?edcode=' + this.eventcode + '&accId=' + this.accountId + '" data-tabid="home"');
                        }

                        // tabIds.forEach(item => {
                        //     if (tabItem.Header__c.includes('https://tabId=')) {
                        //         url = this.getPageUrlByType(item.Tab_Type__c, item.Standard_Tab_Type__c);
                        //         if (url) {
                        //             tabItem.Header__c = tabItem.Header__c.split('"https://tabId=' + item.ExtTabId__c + '"').join('"' + url + '?edcode=' + this.eventcode + '&tabId=' + item.Tab_Code__c + '&accId=' + this.accountId + '" data-tabid="' + item.Tab_Code__c + '" data-tabtype="' + item.Tab_Type__c + '" data-stdtabtype="' + item.Standard_Tab_Type__c + '"');
                        //         }
                        //         else {
                        //             tabItem.Header__c = tabItem.Header__c.split('"https://tabId=').join('"/IMCC/s/?edcode=' + this.eventcode + '&accId=' + this.accountId + '" data-tabid="home"');
                        //         }
                        //     }

                        // });

                    }
                    //console.log('data33===', tabItem);
                });
                //console.log('this.tabContext===', JSON.stringify(this.tabContext));
                if(window.jQuery){
                window.jQuery('a[href*="/IMCC/s"]').click(function (event) {
                    event.preventDefault();
                    let tabId = $(this).data('tabid');
                    let tabType = $(this).data('tabtype');
                    let stdtabtype = $(this).data('stdtabtype');
                    if ($(this).data('tabid') == 'home') {
                        redirect(self, NavigationMixin.Navigate, 'Home', { "accId": self.accountId, "edcode": self.eventcode });
                    }
                    else {
                        gotoPage(self, NavigationMixin.Navigate, { "tabType": tabType, "stdtabtype": stdtabtype, "accId": self.accountId, "edcode": self.eventcode, "tabId": tabId });
                    }
                });
                }

            })
            .catch(error => {
                handleUIErrors(this, error);
            });
    }

    getPageUrlByType(tabType, stndrdTabType) {
        let urlStr = '';
        if (tabType == 'Custom') {
            if (stndrdTabType == 'HTML') {
                urlStr = '/IMCC/s/custom-html';
            }
            else {
                urlStr = '/IMCC/s/custompages';
            }
        }
        if (tabType == 'Standard') {
            if (stndrdTabType == 'Floorplan') {
                urlStr = '/IMCC/s/floorplan';
            }
            if (stndrdTabType == 'FAQ') {
                urlStr = '/IMCC/s/faqs';
            }
            if (stndrdTabType == 'Forms') {
                urlStr = '/IMCC/s/forms';
            }
            if (stndrdTabType == 'Manuals') {
                urlStr = '/IMCC/s/manuals';
            }
            if (stndrdTabType == 'Badges') {
                urlStr = '/IMCC/s/badges';
            }
            if (stndrdTabType == 'Stand Contractors') {
                urlStr = '/IMCC/s/stand-contractors';
            }
            if (stndrdTabType == 'Stand Design') {
                urlStr = '/IMCC/s/stand-design';
            }
            if (stndrdTabType == 'Lead Retrieval') {
                urlStr = '/IMCC/s/lead-retrieval';
            }
            if (stndrdTabType == 'Virtual Event') {
                urlStr = '/IMCC/s/virtual-event';
            }
            if (stndrdTabType == 'Badge Registration') {
                urlStr = '/IMCC/s/badge-registration';
            }
            if (stndrdTabType == 'Manage Team') {
                urlStr = '/IMCC/s/teams-manager';
            }
            // if (stndrdTabType == 'Manage My Task') {
            //     urlStr = '/IMCC/s/manage-my-task';
            // }
        }
        return urlStr;
    };

}