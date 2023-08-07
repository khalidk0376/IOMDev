import { LightningElement, track, wire} from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import InformaMarketsCSS from '@salesforce/resourceUrl/InformaMarketsCSS';
import { CurrentPageReference } from 'lightning/navigation';
import fecthEvent from "@salesforce/apex/IMCC_AccountSelectionCtrl.getEditionDetails";

export default class IMCC_headerAccountSelection extends LightningElement {
    @track eventDtls;
    @track eventLocation;
    @track eventcode;
    @track eventLogo;
    
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.eventcode = currentPageReference.state.edcode;
            }
    }

    connectedCallback() {
        this.fetchEditionDetails(this.eventcode);
        Promise.all([
            loadScript(this, InformaMarketsCSS + '/CustomerCenterWS11/js/jquery-1.7.1.min.js'),
            loadStyle(this, InformaMarketsCSS + '/CustomerCenterWS11/css/style.css'),
            loadStyle(this, InformaMarketsCSS + '/CustomerCenterWS11/css/font-awesome.min.css'),
        ])
            .then(() => {
                // Call back function if scripts loaded successfully
                this.showSuccessMessage();
                alert('Hii');
            })
            .catch(errors => {
                window.console.log(errors);
            });
    }
    fetchEditionDetails(eventcode){
        fecthEvent({eventcode : eventcode})
        .then(result => {
            this.eventDtls = result.event;
            if(this.eventDtls){
                this.formatEventDtls(this.eventDtls);
                this.eventLogo = '/IMCC/servlet/servlet.FileDownload?file=' + this.eventDtls.Edition_Image_URL__c;
            }
            
        })
        .catch(error => {
            window.console.log('error...' + JSON.stringify(error));
        });   
    }


    formatEventDtls(eventDtls) {
        let Venue;
        if (eventDtls.Venue__c) {
            Venue = ' | ' + eventDtls.Venue__c;
        }
        else {
            Venue = '';
        }
        let startDate = eventDtls.Start_Date__c;
        let endDate = eventDtls.End_Date__c;
        let startMOnth;
        let endMOnth;
        if (startDate) {
            startMOnth = this.formatDate(startDate);
        }
        else {
            startMOnth = '';
        }

        if (endDate) {
            endMOnth = ' - ' + this.formatDate(endDate);
        }
        else {
            endMOnth = '';
        }
        this.eventLocation = startMOnth + endMOnth + Venue;
    }
    formatDate(date) {
        let dt = new Date(date), month = '' + (dt.getUTCMonth() + 1), day = '' + dt.getUTCDate(), year = dt.getFullYear(), mon = '';
        if (month === '1') { mon = 'Jan'; }
        if (month === '2') { mon = 'Feb'; }
        if (month === '3') { mon = 'Mar'; }
        if (month === '4') { mon = 'Apr'; }
        if (month === '5') { mon = 'May'; }
        if (month === '6') { mon = 'Jun'; }
        if (month === '7') { mon = 'Jul'; }
        if (month === '8') { mon = 'Aug'; }
        if (month === '9') { mon = 'Sept'; }
        if (month === '10') { mon = 'Oct'; }
        if (month === '11') { mon = 'Nov'; }
        if (month === '12') { mon = 'Dec'; }
        if (day.length < 2) day = '0' + day;
        return [day, mon, year].join(' ');
    }
    logOut() {
        localStorage.removeItem('UserSession');
        let url = location.host;
        if(this.eventcode == '' || this.eventcode == undefined || this.eventcode == null){
            console.log('Block 1');
            location.href = '../secur/logout.jsp?retUrl=https://' + url + '/IMCC/IMCC_UserLogin';
            
        }
        else{
            location.href = '../secur/logout.jsp?retUrl=https://' + url + '/IMCC/IMCC_UserLogin?edcode=' + this.eventcode;
            
        }
        
    }
    
    get utilityBarBranding() {
        return 'background-color:' + this.eventDtls.Background_Colour__c + ';color:' + this.eventDtls.Text_Colour__c;
    }
    
   
}