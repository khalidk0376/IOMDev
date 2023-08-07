import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference,NavigationMixin } from 'lightning/navigation';
import getAnnouncements from "@salesforce/apex/IMCC_HomeCtrl.getAnnouncements";
import { handleErrors,handleUIErrors,gotoPage,redirect } from 'c/imcc_lwcUtility';

export default class ImccAnnouncements extends NavigationMixin(LightningElement) {
    eventCode;
    accountId;  
    contactId;  
    conEdMapId;
    @track methodName;
    @track announcements; 
    @track only4;
    @track activeAnnouncement;    
    @track isOpenDetailModal;
    @track isOpenMoreModal;
    @track isExternalPageButton = false;
    @track isInternalPageButton = false;
    @api className='imccAnnouncements';
    @api comp_type='LWC';
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.eventCode = currentPageReference.state.edcode;
            this.accountId = currentPageReference.state.accId;
            console.log('edcode4==='+this.eventCode);
            if(this.eventCode && this.accountId){
                this.getActiveAnnouncement();
            } 
        }
    };

    getActiveAnnouncement(){
        this.methodName='getActiveAnnouncement';
        getAnnouncements({eventCode:this.eventCode,accountId:this.accountId})
        .then(res=>{            
            console.log('Hello');
            console.log('edcode3==='+this.eventCode);
            this.contactId = res.contactCEMId.split('_')[0];
            console.log('ContactId==='+res.contactCEMId.split('_')[0]);
            console.log('ContactId1==='+this.contactId);
            this.conEdMapId = res.contactCEMId.split('_')[1];
            let data = JSON.parse(JSON.stringify(res.announcementList));
            const a4 = [];
            var regex = /(<([^>]+)>)/ig
            data.forEach((item,index)=>{
                let date  =  item.Announcement_Date__c?item.Announcement_Date__c.split("-"):[];
                let announcementDate = date && date.length==3?date[2]+' '+this.getMonth(date[1])+' '+date[0]:'';
                item.Announcement_Date__c = announcementDate;
                item.Title = item.Title__c && item.Title__c.length>40?item.Title__c.substring(0,40)+'...':item.Title__c;
                item.shortDescription = item.Sub_Header_Text__c?item.Sub_Header_Text__c.replace(regex, ""):"";
                item.shortDescription = item.shortDescription && item.shortDescription.length>150?item.shortDescription.substring(0,150)+'...':item.Sub_Header_Text__c;
                item.class="announcements slds-col slds-small-size_1-of-1 slds-medium-size_12-of-12 slds-large-size_6-of-12";
                //item.shortDescription = item.Sub_Header_Text__c?item.Sub_Header_Text__c.replace(regex, ""):"";
                if(data.length===1){
                    item.class="announcements onlyone slds-p-right_none slds-col";
                }
                if(data.length===3 && index==2){
                    item.class="announcements onlyone slds-p-right_none slds-col slds-size_1-of-1";
                }
                if(index<4){
                    a4.push(item);
                }
                this.only4 = a4;
            });

            console.log('edcode2==='+this.eventCode);
            this.announcements = data;
            console.log('announcements==='+JSON.stringify(this.announcements));
        })
        .catch(error=>{
            //handleErrors(this,error);
            handleUIErrors(this,error);  
        })
    };
    
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

    openDetail(event){        
        let index = parseInt(event.currentTarget.dataset.index,10);
        const activeAnnouncement = this.announcements[index];
        console.log('edcode1==='+this.eventcode);
        if (activeAnnouncement.Link_Type__c == 'Internal' && activeAnnouncement.Event_Tab__c != null) {
            activeAnnouncement.URL_Label__c = (activeAnnouncement.URL_Label__c != null && activeAnnouncement.URL_Label__c != '') ? activeAnnouncement.URL_Label__c : 'Learn more...';
            this.isExternalPageButton = false;
            this.isInternalPageButton = true;
        }
        else if (activeAnnouncement.Link_Type__c == 'External' && activeAnnouncement.URL__c != null) {
            activeAnnouncement.URL_Label__c = (activeAnnouncement.URL_Label__c != null && activeAnnouncement.URL_Label__c != '') ? activeAnnouncement.URL_Label__c : 'Learn more...';
            this.isInternalPageButton = false;
            this.isExternalPageButton = true;
        }
        this.activeAnnouncement = activeAnnouncement;
        console.log(JSON.stringify(this.activeAnnouncement));
        this.isOpenMoreModal = false;
        this.isOpenDetailModal = true;
    };

    closeModal(){
        this.isOpenDetailModal = false;
        this.isOpenMoreModal = false;
        this.isInternalPageButton = false;
        this.isExternalPageButton = false;
    };

    loadMore(){
        this.isOpenMoreModal = true;
    }

    openInernalPage() {   
        const eventTabs = this.activeAnnouncement.Event_Tab__r;
        let tabType = eventTabs.Tab_Type__c;
        let stndrdTabType = eventTabs.Standard_Tab_Type__c;
        let tabName = eventTabs.Tab_Code__c;      

        console.log('edcode==='+this.eventCode);
        gotoPage(this,NavigationMixin.Navigate,{"tabType":tabType,"stdtabtype":stndrdTabType,"accId":this.accountId,"edcode":this.eventCode,"tabId":tabName});        
    }

    handleButtonClick(){
        window.open(this.makeSecureUrl(this.activeAnnouncement.URL__c),'_blank');
    };

    makeSecureUrl(url) {
        let finalUrl;
        if (!url.includes("http:") && !url.includes("https:")) {
            finalUrl = "https://" + url + '?accId=' + this.accountId + '&edcode=' + this.eventCode + '&conId=' + this.contactId + '&ceid=' + this.conEdMapId;
        } else {
            finalUrl = url + '?accId=' + this.accountId + '&edcode=' + this.eventCode + '&conId=' + this.contactId + '&ceid=' + this.conEdMapId;
        }
        return finalUrl;
    }

    redirect(pageName,paramObj){
        redirect(this,NavigationMixin.Navigate,pageName,paramObj);        
    };

    get isShowAnnouncement(){
        return this.announcements && this.announcements.length>0?true:false;
    };

    get isLoadMore(){
        return this.announcements && this.announcements.length>4?true:false;
    };
}