import { LightningElement,api,wire} from 'lwc';
// import apex method from salesforce module 
import fetchLookupData from '@salesforce/apex/CustomLookupLwcCtrl.fetchLookupData';
import fetchDefaultRecord from '@salesforce/apex/CustomLookupLwcCtrl.fetchDefaultRecord';
const DELAY = 100; // dealy apex callout timing in miliseconds  

export default class SObjectLookUpInput extends LightningElement {

    // public properties with initial default values 
    @api label = 'custom lookup label';
    @api placeholder = 'search...'; 
    @api iconName = 'standard:account';
    @api sObjectApiName = 'Account';
    @api cmpId = '';
    @api labelFieldAPI = 'Name';
    @api subTextHelpFields = '';
    @api otherFields = '';
    @api otherSearchFields = '';
    @api defaultRecordId = '';
    @api filterCondition = '';
    @api isRquired = false;

    @api addErrorMeesage(errorMsg){
        var inputCmp = this.template.querySelector('.inputCmp');
        inputCmp.setCustomValidity(errorMsg);
        inputCmp.reportValidity();
    }

    @api refreshData(){
        this.getFilterOptions();
    }

    // private properties 
    lstResult = []; // to store list of returned records   
    hasRecords = true; 
    searchKey=''; // to store input field value    
    isSearchLoading = false; // to control loading spinner  
    delayTimeout;
    selectedRecord = {}; // to store selected lookup record in object formate 
   // initial function to populate default selected lookup record if defaultRecordId provided  
    connectedCallback(){   
        this.getFilterOptions();     
         if(this.defaultRecordId != ''){
            fetchDefaultRecord({ recordId: this.defaultRecordId , 'sObjectApiName' : this.sObjectApiName })
            .then((result) => {
                if(result != null){
                    this.selectedRecord = result;
                    this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
                }
            })
            .catch((error) => {
                this.error = error;
                this.selectedRecord = {};
            });
         }
    } // get LookUp Options


    // wire function property to fetch search record based on user input
    getFilterOptions(){
        // console.log('getFilterOptions - '+this.sObjectApiName+ ' Where '+this.filterCondition);
        let objInput = {'sObjectApiName':this.sObjectApiName,'labelFieldAPI':this.labelFieldAPI,'filterCondition':this.filterCondition,'otherFields':this.otherFields,'otherSearchFields':this.otherSearchFields};
        fetchLookupData( { searchKey: this.searchKey , inputJSON : JSON.stringify(objInput)})
        .then((data) => {
                this.hasRecords = data.length == 0 ? false : true; 
                //this.lstResult = JSON.parse(JSON.stringify(data)); 
                this.lstResult = this.setDisplayNodes(JSON.parse(JSON.stringify(data))); 
            })
        .catch((error) => {
            console.log('(error---> ' + JSON.stringify(error));
        });
    }

    setDisplayNodes(results)
    {
        let subHelpTextNodes = this.subTextHelpFields ?this.subTextHelpFields.split(',') :[];
        if(results && Array.isArray(results) && results.length>0)
        {
            // console.log('Results '+JSON.stringify(results));
            results.forEach((row) => {
                row.LabelValue = row[this.labelFieldAPI];
                row.HelpValue = '';
                // console.log('row '+JSON.stringify(row));
                if(subHelpTextNodes && Array.isArray(subHelpTextNodes) && subHelpTextNodes.length>0)
                {
                    subHelpTextNodes.forEach((row2,n) => {
                        if(n===0){
                            row.HelpValue += (row[row2] ?row[row2]:'');
                        }else{
                            row.HelpValue += (row[row2] ?' • '+row[row2]:'');
                        }
                    });
                }
                // console.log('row2 '+JSON.stringify(row));
            });
        }        
        return results;
    }

    /**
     * 
      // wire function property to fetch search record based on user input
        @wire(fetchLookupData, { searchKey: '$searchKey' , sObjectApiName : '$sObjectApiName' })
        searchResult(value) {
            const { data, error } = value; // destructure the provisioned value
            this.isSearchLoading = false;
            if (data) {
                this.hasRecords = data.length == 0 ? false : true; 
                this.lstResult = JSON.parse(JSON.stringify(data)); 
            }
            else if (error) {
                console.log('(error---> ' + JSON.stringify(error));
            }
        };
     */
       
  // update searchKey property on input field change  
    handleKeyChange(event) {
        // Debouncing this method: Do not update the reactive property as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.searchKey = searchKey;
        this.delayTimeout = setTimeout(() => {
            this.getFilterOptions();
        }, DELAY);
    }
    // method to toggle lookup result section on UI 
    toggleResult(event){
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch(whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
               break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');    
            break;                    
           }
    }
   // method to clear selected lookup record  
   handleRemove(){
        this.searchKey = '';    
        this.selectedRecord = {};
        this.lookupUpdatehandler(undefined); // update value on parent component as well from helper function 
        
        // remove selected pill and display input field again 
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-hide');
        searchBoxWrapper.classList.add('slds-show');
        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-show');
        pillDiv.classList.add('slds-hide');
    }
  // method to update selected record from search result 
    handelSelectedRecord(event){   
        var objId = event.target.getAttribute('data-recid'); // get selected record Id 
        this.selectedRecord = this.lstResult.find(data => data.Id === objId); // find selected record from list 
        this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function 
        this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
    }
    /*COMMON HELPER METHOD STARTED*/
    handelSelectRecordHelper(){
        this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-show');
        searchBoxWrapper.classList.add('slds-hide');
        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-hide');
        pillDiv.classList.add('slds-show');     
    }
    // send selected lookup record to parent component using custom event
    lookupUpdatehandler(value){    
        const oEvent = new CustomEvent('lookupupdate',
        {
            'detail': {selectedRecord: value}
        }
    );
    this.dispatchEvent(oEvent);
    }
}