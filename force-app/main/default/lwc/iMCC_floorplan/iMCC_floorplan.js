import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import fetchBoothLst from '@salesforce/apex/IMCC_FloorplanCtrl.fetchBoothDetails';
import expocadBaseUrl from '@salesforce/label/c.Expocad_Base_Url';
import fileDownloadUrl from '@salesforce/label/c.File_Download_URL';
import fetchManualPdfs from '@salesforce/apex/IMCC_FloorplanCtrl.fetchManualPdfDetails';
//import fetchHowToDetails from '@salesforce/apex/IMCC_FAQCtrl.fetchHowToDetails';
//import fetchContVerId from '@salesforce/apex/IMCC_FAQCtrl.fetchContentVerId';

import {handleUIErrors} from 'c/imcc_lwcUtility';

export default class IMCC_floorplan extends LightningElement {

    label = {
        expocadBaseUrl, fileDownloadUrl
    };

    @track eventcode;
    @track accountId;
    @track tabId;
    @track boothDtls;
    @track tabHeader;
    @track floorplanMsg;
    @track wrapLstPdf;
    @track downloadModal = false;
    @track showPdf;
    @track showBoothDtls = false;
    @track showPdfloorplan = false;
    @track showfloorplanMsg = false;

    @track methodName;
    className ='iMCC_floorplan';
    comp_type ='LWC';
    
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.eventcode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            this.tabId = currentPageReference.state.tabId;
            console.log('Tab Code floorplan ' + this.tabId);
            this.doInit();
        }
    }

    doInit() {
        this.methodName = 'doInit';
        fetchBoothLst({ eventCode: this.eventcode, accountId: this.accountId, tabId: this.tabId })
            .then(result => { 
                this.tabHeader = '';
                if (result.tabContext) {
                    this.tabHeader = result.tabContext.Header__c;
                }
                if (result.evntTab) {

                        this.floorplanMsg = result.evntTab.Floorplan_Blank_Msg__c;
                }
                let expocadEventCode;
                if(result.expocadEventCode){
                    expocadEventCode = result.expocadEventCode;
                }
                let data = result.purchaseDtls;
                let boothDataLst = [];
                if (data) {
                    data.forEach((row) => {
                        let boothDetailLst = {};
                        boothDetailLst.BoothNumber = row.Booth_Number__c;
                        boothDetailLst.BoothType = row.Booth_Product_Type__c;
                        boothDetailLst.BoothSize = row.Quantity_Area__c;
                        boothDetailLst.UnitMeasurement = row.Unit_of_Measurement__c;
                        boothDetailLst.ViewBoothLink = expocadBaseUrl + expocadEventCode + '/exfx.html?zoomto=' + row.Booth_Number__c;

                        boothDataLst.push(boothDetailLst);

                    });

                    this.boothDtls = boothDataLst;
                    if(this.boothDtls.length > 0){
                        this.showBoothDtls = true;
                    }
                    this.showPdfloorplan = false;
                    console.log('Booth Data 1' + this.boothDtls);
                }
                else{
                    this.showfloorplanMsg = true;
                }
                if (result.lstPdf) {
                    this.wrapLstPdf = result.lstPdf;
                    this.showPdfloorplan = true;
                    this.showBoothDtls = false;
                    this.showfloorplanMsg = false;
                    console.log('this.wrapLstPdf ' + this.wrapLstPdf);
                }

            })
            .catch(error => {
                window.console.log('error...12' + JSON.stringify(error));
                handleUIErrors(this,error);
            });

    }
    ViewedPdf(event) {
        this.methodName = 'ViewedPdf';
        let pdfFlrplanId = event.currentTarget.dataset.id;
        console.log('Pdf Id  ' + pdfFlrplanId);
        fetchManualPdfs({ linkEntId: pdfFlrplanId })
            .then(result => {

                let pdfId = result;
                if (pdfId) {
                    this.showPdf = fileDownloadUrl + pdfId;
                    this.downloadModal = true;
                }


            })
            .catch(error => {
                window.console.log('error...12' + JSON.stringify(error));
                handleUIErrors(this,error);
            });
    };

    ClosePopup() {
        this.downloadModal = false;
    };

    openMobileMenu(event){
        event.stopPropagation();
        let height = screen.height - 160;
        this.template.querySelector(".mobile-menu-body").style="height:"+height+"px";        
        let progress = 480;
        this._interval = setInterval(() => {
            progress = progress - 100;              
            if ( progress <= 0 ) {  
                progress = 0;
                clearInterval(this._interval);  
                this.template.querySelector(".modal-overlay").classList.add("active");
            }
            this.template.querySelector(".mobile-menu").style = "display: block;transform-style: preserve-3d;-webkit-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
        }, 10);
    };

    closeMobileMenu(){  
        /* working good, don't remove comment before ticket assign*/
        //event.stopPropagation();        
        let progress = 0;
        this._interval = setInterval(() => {  
            progress = progress + 100;              
            if ( progress >= 480 ) {  
                progress = 480;
                clearInterval(this._interval);  
                this.template.querySelector(".modal-overlay").classList.remove("active");
                this.template.querySelector(".mobile-menu").style = "display: none;transform-style: preserve-3d;-webkit-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
            }
            this.template.querySelector(".mobile-menu").style = "transform-style: preserve-3d;-webkit-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d("+progress+"px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
        }, 10);
    };
}