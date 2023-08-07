import { LightningElement,track,wire } from 'lwc';
import editions from '@salesforce/apex/IMCC_FormReportCTRL.getEditions';
import picklistOptions from '@salesforce/apex/IMCC_FormReportCTRL.formPicklistOptions';
import getFormQuestions from '@salesforce/apex/IMCC_FormReportCTRL.getFormQuestions';
import getReportData from '@salesforce/apex/IMCC_FormReportCTRL.getReportData';
import { handleErrors } from 'c/imcc_lwcUtility';
import {getEnclosingTabId,setTabLabel} from 'c/imcc_lwcWorkspaceApi';
import { CurrentPageReference } from 'lightning/navigation';
import FormReportDownloadNote from '@salesforce/label/c.IMCC_Form_Report_Download_Note';
import ShowFBReportWithViewButton from '@salesforce/label/c.IMCC_Show_FBReport_With_View_Button';
//import TIME_ZONE from '@salesforce/i18n/timeZone';

const TIME_ZONE = "GMT";

export default class ImccFormReport extends LightningElement{
		label = {
        FormReportDownloadNote
    };
		
    @track isOpenDownloadModal;
    @track isOpenSendReportModal;
    @track eId;
    @track st;
    @track formTemplateId;
    @track listEdition;
    @track editionsList;
    @track myoptions = [];
    @track formOption = [];
    @track questList = [];
    @track questAnsList = [];
    @track spinner;
    @track colDl;
    @track rowDl;
    showData = false;
    isBtnDisable = true;
    isWithViewButton = false;
    columns = [];
    purchasedDataMap = {};

    
    isFirst = true;
    isLast = false;
    reportData = [];
    maxEntry = -1;
    formResponseEntries = [];
    entryIds;
    startindex = -1;

    connectedCallback(){
        this.st='';
        this.eId='';
        this.spinner = false;
        this.isWithViewButton = (ShowFBReportWithViewButton=='true'?true:false);
        this.getEditions();
    };

    @wire(CurrentPageReference)
    async setCurrentPageReference(currentPageReference) {    
        if(currentPageReference){
            if(currentPageReference.attributes.apiName == "FB_Report_New"){
                try{
                    console.log(currentPageReference);
                    const tabId = await getEnclosingTabId(currentPageReference);
                    setTabLabel(tabId, 'FB Report', 'standard:report', 'FB Report');   
                }
                catch(e){
                    console.log(e);
                }
            }
        }
    }

    getEditions(){
        this.listEdition = [];
        let e = [{label:'Select Edition',value:''}];
        editions({})
        .then(res=>{
            console.log(JSON.stringify(res));
            this.listEdition = res;
            res.forEach(i => {
                e.push({label:i.Name,value:i.Id});
            });
            this.editionsList = e;
        })
        .catch(error=>{
            handleErrors(this,error);
        });
    };

    handleEditionChange(event){
        this.eId = event.target.value;
        console.log('eId=='+ this.eId);
        if(this.eId !== ''){
            this.selectPicklistOptions();
            this.showData = false;
            this.isBtnDisable = true;
        }
        if(this.eId === ''){
            this.st='';
            this.myoptions = [];
            this.showData = false;
            this.isBtnDisable = true;
        }
    }

    selectPicklistOptions(){
        let o = [{label:'Select Form',value:' '}];
        picklistOptions({editionId : this.eId})
        .then(res=>{
            let formAllocLst = res.formAllocLst;
            formAllocLst.forEach(i => {
                o.push({label:i.Name,value:i.Id});
            });
            this.myoptions = o;
            if(this.myoptions.length > 1){
                this.st = this.myoptions[0];
            }
            let listPD = res.listPD?JSON.parse(JSON.stringify(res.listPD)):[];
            this.purchasedDataMap = {};
            listPD.forEach(pd => {
                let purchaseDetail = "";
                if(this.purchasedDataMap.hasOwnProperty(pd.Contact_Edition_Mapping__c)){
                    purchaseDetail = this.purchasedDataMap[pd.Contact_Edition_Mapping__c];
                    purchaseDetail += ", " + pd.Booth_Number__c + " - " + pd.Booth_Product_Type__c;
                }
                else{
                    purchaseDetail = pd.Booth_Number__c + " - " + pd.Booth_Product_Type__c;
                }
                this.purchasedDataMap[pd.Contact_Edition_Mapping__c] = purchaseDetail;
            });
        })
        .catch(error=>{
            handleErrors(this,error);
        });
    }

    handleSTChange(event){
        this.st = event.target.value;
        this.showData = false;
        this.isBtnDisable = true;
        this.spinner = true;
        getFormQuestions({formAllocId : this.st})
        .then(res=>{
            let tempQuest = res?JSON.parse(JSON.stringify(res)):[];
            this.questList = tempQuest;
            if(!this.isWithViewButton){
                this.getReportData();
            }
            else{
                this.isBtnDisable = false;
            }
        })
        .catch(error=>{
            handleErrors(this,error);
        })
        .finally(()=>{
            this.spinner = false;
        });
    }

    getReportData(){
        getReportData({editionId : this.eId,formAllocId : this.st,qstIds:[],entryIds:null})
        .then(res=>{
            let tempQuestAns = res.questAns?JSON.parse(JSON.stringify(res.questAns)):[];
            let lstKeys = res.lstKeys?JSON.parse(JSON.stringify(res.lstKeys)):{};
            let optionMap = res.optionMap?JSON.parse(JSON.stringify(res.optionMap)):{};

            let index = 9;
            let indexMap = {};
            this.columns = [];
            this.columns.push({index:0,label:"Account Name",keyLabel:"Account Name"});
            this.columns.push({index:1,label:"Community User Name",keyLabel:"Community User Name"});
            this.columns.push({index:2,label:"Community Email",keyLabel:"Community Email"});
            this.columns.push({index:3,label:"Purchased Stands",keyLabel:"Purchased Stands"});
            if(tempQuestAns.length > 0 && tempQuestAns[0].Form_Response_Entry__r.Purchase_Data__c != null){
                this.columns.push({index:4,label:"Stand Number",keyLabel:"Stand Number"});
                this.columns.push({index:5,label:"Stand Type",keyLabel:"Stand Type"});
                this.columns.push({index:6,label:"Response Status",keyLabel:"Response Status"});
                this.columns.push({index:7,label:"Submissions Date",keyLabel:"Submissions Date"});
                this.columns.push({index:8,label:"Last Modified Date",keyLabel:"Last Modified Date"});
                this.columns.push({index:9,label:"Last Modified By",keyLabel:"Last Modified By"});
                index = 9;
            }
            else{
                this.columns.push({index:4,label:"Response Status",keyLabel:"Response Status"});
                this.columns.push({index:5,label:"Submissions Date",keyLabel:"Submissions Date"});
                this.columns.push({index:6,label:"Last Modified Date",keyLabel:"Last Modified Date"});
                this.columns.push({index:7,label:"Last Modified By",keyLabel:"Last Modified By"});
                index = 7;
            }
            
            for(const [key, value] of Object.entries(lstKeys)) {
                index++;
                this.columns.push({index:index,label:value,keyLabel:key});
            }
            this.columns.forEach(col => {
                indexMap[col.keyLabel] = col.index;
            });

            let entryMap = {};
            tempQuestAns.forEach(res => {
                if(res.Answer__c != null && optionMap.hasOwnProperty(res.Answer__c)){
                    res.Answer__c = optionMap[res.Answer__c].Name;
                }
                if(res.Answer__c != null && res.Question__r.Is_MultiSelect__c){
                    let temp='';
                    console.log('Is MultiSelect: '+res.Question__r.Is_MultiSelect__c);
                    res.Answer__c.split(';').forEach(item=>{
                        let ans = optionMap.hasOwnProperty(item)?optionMap[item].Name:'';
                        temp += temp?', '+ans:ans;
                    });
                    if(temp){
                        res.Answer__c = temp;
                    }
                }

                if(lstKeys.hasOwnProperty(res.Question__c)){
                    let labelName = res.Question__c;
                    let entry = [];
                    if(entryMap.hasOwnProperty(res.Form_Response_Entry__c)){
                        entry = entryMap[res.Form_Response_Entry__c];
                    }
                    else{
                        this.columns.forEach(col => {
                            entry.push("");
                        });
                        entry.splice(indexMap["Community User Name"],1,res.Form_Response_Entry__r.Contact_Edition_Mapping__r.Contact__r.Name);
                        entry.splice(indexMap["Community Email"],1,res.Form_Response_Entry__r.Contact_Edition_Mapping__r.Contact__r.Email);
                        entry.splice(indexMap["Account Name"],1,res.Form_Response_Entry__r.Contact_Edition_Mapping__r.Account__r.Name);
                        entry.splice(indexMap["Purchased Stands"],1,this.purchasedDataMap[res.Form_Response_Entry__r.Contact_Edition_Mapping__c]);
                        if(res.Form_Response_Entry__r.Purchase_Data__c != null){
                            entry.splice(indexMap["Stand Number"],1,res.Form_Response_Entry__r.Purchase_Data__r.Booth_Number__c); 
                            entry.splice(indexMap["Stand Type"],1,res.Form_Response_Entry__r.Purchase_Data__r.Booth_Product_Type__c); 
                        } 
                        entry.splice(indexMap["Response Status"],1,res.Form_Response_Entry__r.Response_Status__c); 
                        entry.splice(indexMap["Submissions Date"],1,res.Form_Response_Entry__r.Submission_Date__c); 
                        if(res.Form_Response_Entry__r.Last_Modified_Date__c != null){
                            var dateTime = res.Form_Response_Entry__r.Last_Modified_Date__c;
                            var strDateTime = new Date(dateTime).toLocaleString("en-US", {timeZone: TIME_ZONE});
                            var strdateTime1 = dateTime.split("T")[0];
                            var strdateTime2 = strDateTime.split(",")[1];
                            let strDate = strdateTime1 + strdateTime2;
                            entry.splice(indexMap["Last Modified Date"],1,strDate);
                        }
                        if(res.Form_Response_Entry__r.Last_Modified_By__c != null){
                            entry.splice(indexMap["Last Modified By"],1,res.Form_Response_Entry__r.Last_Modified_By__r.Name);
                        }
                    }
                    
                    if(res.Question__r.Type__c == 'DateTime'){
                        if(res.Answer__c != null && res.Answer__c != ""){
                            var dateTime = res.Answer__c;
                            var strDateTime = new Date(dateTime).toLocaleString("en-US", {timeZone: TIME_ZONE});
                            var strdateTime1 = dateTime.split("T")[0];
                            var strdateTime2 = strDateTime.split(",")[1];
                            //let strDate = new Date(dateTime).toLocaleString("en-US", {timeZone: TIME_ZONE}).replace(",","");
                            let strDate = strdateTime1 + strdateTime2;
                            entry.splice(indexMap[labelName],1,strDate);
                        }
                    }
                    else if(res.Question__r.Type__c == 'Switch'){
                        if(res.Answer__c != null && res.Answer__c != ""){
                            let newArray = Object.values(optionMap).filter(om => om.Question__c===res.Question__c);
                            console.log(JSON.stringify(Object.entries(optionMap)));
                            if(newArray.length==2){
                                res.Answer__c = res.Answer__c=='true'?newArray[0].Name:newArray[1].Name;
                            }
                            console.log(res.Answer__c);
                            entry.splice(indexMap[labelName],1,res.Answer__c);
                        }
                    }
                    else if(res.Question__r.Type__c != 'Media'){
                        if(res.Question__r.Type__c == 'Signature'){
                            let ans = "";
                            if(res.Answer__c != null && res.Answer__c != ""){
                                if(res.Answer__c.indexOf("../servlet/") != -1){
                                    if(res.Answer__c.split("../servlet/").length == 2){
                                        ans = '<a href="/servlet/'+res.Answer__c.split("../servlet/")[1]+'" target="_blank">Signature</a>';
                                    }
                                }
                            }
                            entry.splice(indexMap[labelName],1,ans);
                        }
                        else{
                            entry.splice(indexMap[labelName],1,res.Answer__c);
                        }
                    }
                    else{
                        if(res.Attachments != null){
                            let resAttach = '';
                            res.Attachments.forEach(attch => {
                                resAttach += (resAttach==''?'':'<br/>')+'<a href="/servlet/servlet.FileDownload?file='+attch.Id+'" target="_blank">' + attch.Name + '</a>';
                            });
                            entry.splice(indexMap[labelName],1,resAttach);
                        }
                    }
                    entryMap[res.Form_Response_Entry__c] = entry;
                }
            }); 
            //console.log('entryMap==='+ JSON.stringify(entryMap));
            let reportData = [];
            let qindex=0;
            
            for(const [key, value] of Object.entries(entryMap)) { 
                reportData.push({"value":value,"key":'item'+qindex,"cellkey":'cell'+qindex});
                qindex++;            
            }
            
            let height = window.innerHeight - (this.template.querySelector(".fbreportdiv").getBoundingClientRect().top + window.scrollY+10);
            this.template.querySelector(".fbreportdiv").style.height = height+"px";
            
            this.questAnsList = reportData;
            this.showData = true;
            this.isBtnDisable = false;
        })
        .catch(error=>{
            handleErrors(this,error);
        })
        .finally(()=>{
            this.spinner = false;
        });
    };

    openDownloadModal(){
        this.isOpenDownloadModal = true;
    };

    closeDownloadModal(){
        this.isOpenDownloadModal = false;
        this.questList.forEach(item=>{
            item.checked = false;
        });
    };

    handleCheckboxChange(event){
        let index = parseInt(event.target.dataset.index,10);
        let item = this.questList[index];
        item.checked = !item.checked; 
        this.questList[index] = item;        
    };

    getHTMLData() {
        let qst = this.colDl;
        let qstAns = this.rowDl;
        
        let table = '';

        // add header
        let line = '<tr><th>';
        for (let i = 0; i < qst.length; i++) {            
            if (line != '<tr><th>') {
                line += '</th><th>';
            }
            line += qst[i].label;                    
        }
        table += line + '</th></tr>';    

        // add data
        for (let i = 0; i < qstAns.length; i++) {
            let row = '<tr><td>';
            for (let index in qstAns[i].value) {
                if (row != '<tr><td>') {row += '</td><td>';}
                let d = qstAns[i].value[index]?qstAns[i].value[index].replace('/servlet','https://'+window.location.host+'/servlet'):'';
                row += d;
            }
            table += row + '</td></tr>';
        }
        
        return table;
    };

    @track colDl;
    @track rowDl;
    getDataToDownload(){
        let  qstIds = [];
        
        this.questList.forEach(item=>{
            if(item.checked){
                qstIds.push(item.Question__c);
            }
        });
        this.spinner = true;
        this.isFirst = true;
        this.isLast = false;
        this.reportData = [];
        this.maxEntry = -1;
        this.formResponseEntries = [];
        this.startindex = -1;
        let self = this;
        setTimeout(() => {
            self.getReportDownLoadData(qstIds);
        }, 100);
    };

    getReportDownLoadData(qstIds){
        console.log("getReportDownLoadData");
        getReportData({editionId : this.eId,formAllocId : this.st,qstIds:qstIds,entryIds:this.entryIds})
        .then(res=>{
            if(this.isFirst){
                this.maxEntry = res.maxEntry;
                this.formResponseEntries = res.formResponseEntries;
                this.isFirst = false;
                this.startindex = this.maxEntry;
            }
            else{
                this.startindex += this.maxEntry;
            }
            this.entryIds = [];
            for(let i = this.startindex;i<this.formResponseEntries.length;i++){
                if(this.entryIds.length < this.maxEntry){
                    this.entryIds.push(this.formResponseEntries[i].Id);
                }
            } 
            
            if(this.startindex >= this.formResponseEntries.length){
                this.isLast = true;
            }
            let tempQuestAns = res.questAns?JSON.parse(JSON.stringify(res.questAns)):[];
            let lstKeys = res.lstKeys?JSON.parse(JSON.stringify(res.lstKeys)):{};
            let optionMap = res.optionMap?JSON.parse(JSON.stringify(res.optionMap)):{};

            let index = 9;
            let indexMap = {};
            this.colDl = [];
            this.colDl.push({index:0,label:"Account Name",keyLabel:"Account Name"});
            this.colDl.push({index:1,label:"Community User Name",keyLabel:"Community User Name"});
            this.colDl.push({index:2,label:"Community Email",keyLabel:"Community Email"});
            this.colDl.push({index:3,label:"Purchased Stands",keyLabel:"Purchased Stands"});
            if(tempQuestAns.length > 0 && tempQuestAns[0].Form_Response_Entry__r.Purchase_Data__c != null){
                this.colDl.push({index:4,label:"Stand Number",keyLabel:"Stand Number"});
                this.colDl.push({index:5,label:"Stand Type",keyLabel:"Stand Type"});
                this.colDl.push({index:6,label:"Response Status",keyLabel:"Response Status"});
                this.colDl.push({index:7,label:"Submissions Date",keyLabel:"Submissions Date"});
                this.colDl.push({index:8,label:"Last Modified Date",keyLabel:"Last Modified Date"});
                this.colDl.push({index:9,label:"Last Modified By",keyLabel:"Last Modified By"});
                index = 9;
            }
            else{
                this.colDl.push({index:4,label:"Response Status",keyLabel:"Response Status"});
                this.colDl.push({index:5,label:"Submissions Date",keyLabel:"Submissions Date"});
                this.colDl.push({index:6,label:"Last Modified Date",keyLabel:"Last Modified Date"});
                this.colDl.push({index:7,label:"Last Modified By",keyLabel:"Last Modified By"});
                index = 7;
            }
            
            for(const [key, value] of Object.entries(lstKeys)) {
                index++;
                this.colDl.push({index:index,label:value,keyLabel:key});
            }
            this.colDl.forEach(col => {
                indexMap[col.keyLabel] = col.index;
            });

            let entryMap = {};
            tempQuestAns.forEach(res => {
                if(res.Answer__c != null && optionMap.hasOwnProperty(res.Answer__c)){
                    res.Answer__c = optionMap[res.Answer__c].Name;
                }

                if(lstKeys.hasOwnProperty(res.Question__c)){
                    let labelName = res.Question__c;
                    let entry = [];
                    if(entryMap.hasOwnProperty(res.Form_Response_Entry__c)){
                        entry = entryMap[res.Form_Response_Entry__c];
                    }
                    else{
                        this.colDl.forEach(col => {
                            entry.push("");
                        });
                        entry.splice(indexMap["Community User Name"],1,res.Form_Response_Entry__r.Contact_Edition_Mapping__r.Contact__r.Name);
                        entry.splice(indexMap["Community Email"],1,res.Form_Response_Entry__r.Contact_Edition_Mapping__r.Contact__r.Email);
                        entry.splice(indexMap["Account Name"],1,res.Form_Response_Entry__r.Contact_Edition_Mapping__r.Account__r.Name);
                        entry.splice(indexMap["Purchased Stands"],1,this.purchasedDataMap[res.Form_Response_Entry__r.Contact_Edition_Mapping__c]);
                        if(res.Form_Response_Entry__r.Purchase_Data__c != null){
                            entry.splice(indexMap["Stand Number"],1,res.Form_Response_Entry__r.Purchase_Data__r.Booth_Number__c); 
                            entry.splice(indexMap["Stand Type"],1,res.Form_Response_Entry__r.Purchase_Data__r.Booth_Product_Type__c); 
                        } 
                        entry.splice(indexMap["Response Status"],1,res.Form_Response_Entry__r.Response_Status__c); 
                        entry.splice(indexMap["Submissions Date"],1,res.Form_Response_Entry__r.Submission_Date__c); 
                        if(res.Form_Response_Entry__r.Last_Modified_Date__c != null){
                            var dateTime = res.Form_Response_Entry__r.Last_Modified_Date__c;
                            var strDateTime = new Date(dateTime).toLocaleString("en-US", {timeZone: TIME_ZONE});
                            var strdateTime1 = dateTime.split("T")[0];
                            var strdateTime2 = strDateTime.split(",")[1];
                            //let strDate = new Date(dateTime).toLocaleString("en-US", {timeZone: TIME_ZONE}).replace(",","");
                            let strDate = strdateTime1 + strdateTime2;
                            entry.splice(indexMap["Last Modified Date"],1,strDate);
                        } 
                        if(res.Form_Response_Entry__r.Last_Modified_By__c != null){
                            entry.splice(indexMap["Last Modified By"],1,res.Form_Response_Entry__r.Last_Modified_By__r.Name);
                        }
                    }
                    
                    if(res.Question__r.Type__c == 'DateTime'){
                        if(res.Answer__c != null && res.Answer__c != ""){
                            var dateTime = res.Answer__c;
                            var strDateTime = new Date(dateTime).toLocaleString("en-US", {timeZone: TIME_ZONE});
                            var strdateTime1 = dateTime.split("T")[0];
                            var strdateTime2 = strDateTime.split(",")[1];
                            let strDate = strdateTime1 + strdateTime2;
                            entry.splice(indexMap[labelName],1,strDate);
                        }
                    }
                    else if(res.Question__r.Type__c == 'Switch'){
                        if(res.Answer__c != null && res.Answer__c != ""){
                            let newArray = Object.values(optionMap).filter(om => om.Question__c===res.Question__c);
                            console.log(JSON.stringify(Object.entries(optionMap)));
                            if(newArray.length==2){
                                res.Answer__c = res.Answer__c=='true'?newArray[0].Name:newArray[1].Name;
                            }
                            console.log(res.Answer__c);
                            entry.splice(indexMap[labelName],1,res.Answer__c);
                        }
                    }
                    else if(res.Question__r.Type__c != 'Media'){
                        if(res.Question__r.Type__c == 'Signature'){
                            let ans = "";
                            if(res.Answer__c != null && res.Answer__c != ""){
                                if(res.Answer__c.indexOf("../servlet/") != -1){
                                    if(res.Answer__c.split("../servlet/").length == 2){
                                        ans = '<a href="/servlet/'+res.Answer__c.split("../servlet/")[1]+'" target="_blank">Signature</a>';
                                    }
                                }
                            }
                            entry.splice(indexMap[labelName],1,ans);
                        }
                        else{
                            entry.splice(indexMap[labelName],1,res.Answer__c);
                        }
                    }
                    else{
                        if(res.Attachments != null){
                            let resAttach = '';
                            res.Attachments.forEach(attch => {
                                resAttach += (resAttach==''?'':'<br/>')+'<a href="/servlet/servlet.FileDownload?file='+attch.Id+'" target="_blank">' + attch.Name + '</a>';
                            });
                            entry.splice(indexMap[labelName],1,resAttach);
                        }
                    }
                    entryMap[res.Form_Response_Entry__c] = entry;
                }
            });

            let qindex=0;
            for(const [key, value] of Object.entries(entryMap)) {            
                this.reportData.push({"value":value,"key":'item'+qindex,"cellkey":'cell'+qindex});
                qindex++;
            }                        
        
            this.rowDl = this.reportData;
            if(!this.isLast){
                this.getReportDownLoadData(qstIds);
            }

            if(this.isLast){
                this.downloadReport();
            }
        })
        .catch(error=>{
            handleErrors(this,error);
            this.spinner = false;
        });
        //.finally(()=>{
        //    this.spinner = false;
        //});
    }

    downloadReport(){
        var uri = 'data:application/vnd.ms-excel;base64,'
        , template = '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40"><head><!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets><x:ExcelWorksheet><x:Name>{worksheet}</x:Name><x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions></x:ExcelWorksheet></x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]--><meta http-equiv="content-type" content="text/plain; charset=UTF-8"/></head><body><table>{table}</table></body></html>'
        , base64 = function(s) { return window.btoa(unescape(encodeURIComponent(s))) }
        , format = function(s, c) { return s.replace(/{(\w+)}/g, function(m, p) { return c[p]; }) }
        
        let table = this.getHTMLData()
        
        let ctx = {worksheet: 'Online-form' || 'Worksheet', table: table}
        
        let downloadElement = document.createElement('a');
        downloadElement.href = uri + base64(format(template, ctx));
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Online Forms.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click(); 
        this.closeDownloadModal();
        this.spinner = false;       
    };

    //Send Report modal open/hide logic

    openSendReportModal(){
        this.isOpenSendReportModal = true;
    };

    hideSendReportModal(){
        this.isOpenSendReportModal = false;
    };
}