import { LightningElement, track, api } from 'lwc';
import sendMails from "@salesforce/apex/IMCC_FormReportCTRL.sendMail";
import fetchEmailContent from "@salesforce/apex/FormReportCtrl.fetchEmailSubBody";
import saveChunk from '@salesforce/apex/IMCC_FormReportCTRL.saveChunk';
import getReportData from '@salesforce/apex/IMCC_FormReportCTRL.getReportData';
import { handleErrors,showToast } from 'c/imcc_lwcUtility';
import Send_Report_Message from '@salesforce/label/c.send_form_report_file_size_exceeded';
const MAX_FILE_SIZE= 4500000; //Max file size 4500000(4.5 MB), 20971520 (20.0 MB)
const CHUNK_SIZE= 750000;      //Chunk Max size 750Kb 

const TIME_ZONE = "GMT";

export default class SendFormReportPopup extends LightningElement {
    @api qid; // form allocation id
    @api editionId; // edition id
    @api purchasedDataMap;

    @track emailSub;
    @track emailBody;    
    @track isOpenReportModal;
    @track inputVal='';
    @track disableBtn = true;
    @track subVal='';
    @track bodyVal='';
    @track spinner;
    
    colDl;//table columns
    rowDl;//table row data

    isFirst = true;
    isLast = false;
    maxEntry = -1;
    formResponseEntries = [];
    entryIds;
    startindex = -1;

    connectedCallback(){        
        this.isOpenReportModal = true;
        fetchEmailContent({formId : this.qid, editionId : this.editionId})
        .then(result => {
            if(result){
                this.emailSub = result.emailSub;
                this.emailBody = result.emailBody;
            }
        })
        .catch(error => {
            handleErrors(this,error);            
        });
        this.spinner = true;
        this.isFirst = true;
        this.isLast = false;
        this.rowDl = [];
        this.maxEntry = -1;
        this.formResponseEntries = [];
        this.startindex = -1;
        let self = this;
        setTimeout(() => {
            self.getFormDataToSendMail();
        }, 100);    
    };

    getFormDataToSendMail(){
        try{
            getReportData({editionId : this.editionId,formAllocId : this.qid,qstIds:[],entryIds:this.entryIds})
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

                let qindex=0;
                
                for(const [key, value] of Object.entries(entryMap)) {                                
                    this.rowDl.push(value);
                    qindex++;                    
                } 
                if(!this.isLast){
                    this.getFormDataToSendMail();
                }

                if(this.isLast){       
                    this.spinner = false;
                }                               
            })
            .catch(error=>{
                this.spinner = false;
                console.error(error);
                handleErrors(this,error);
            })
        }
        catch(e){
            console.error('e'+e);
        }
    };

    hideModal(){
        this.isOpenReportModal = false;
        this.dispatchEvent(new CustomEvent('closemodal'));
    };        
    
    changeInput(event){
        this.inputVal = event.detail.value;
        if(this.inputVal == null || this.inputVal == '' ){
            this.disableBtn = true;
        }
        else{
            this.disableBtn = false;
        }        
    };

    changeSubInput(event){
        this.subVal = event.detail.value;
        if(this.subVal == null || this.subVal == '' ){
            this.disableBtn = true;
        }
        else{
            this.disableBtn = false;
        }
    };

    changeBodyInput(event){
        this.bodyVal = event.detail.value;
        if(this.bodyVal == null || this.bodyVal == ''){
            this.disableBtn = true;
        }
        else{
            this.disableBtn = false;
        }
    };        

    // upload excel file edition record
    getHTMLData() {
        let qst = this.colDl;                
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
        for (let i = 0; i < this.rowDl.length; i++) {
            let row = '<tr><td>';
            for (let index in this.rowDl[i]) {
                if (row != '<tr><td>') {row += '</td><td>';}
                let d = this.rowDl[i][index]?this.rowDl[i][index].replace('/servlet','https://'+window.location.host+'/servlet'):'';
                row += d;
            }
            table += row + '</td></tr>';
        }
        //console.log(table);
        return table;
    };

    convertToExcel(){        
        let self = this;
        let table = this.getHTMLData();
        var template = '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40"><head><!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets><x:ExcelWorksheet><x:Name>{worksheet}</x:Name><x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions></x:ExcelWorksheet></x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]--><meta http-equiv="content-type" content="text/plain; charset=UTF-8"/></head><body><table>{table}</table></body></html>'
        , base64 = function(s) { return window.btoa(unescape(encodeURIComponent(s))) }
        , format = function(s, c) { return s.replace(/{(\w+)}/g, function(m, p) { return c[p]; }) }            
        let ctx = {worksheet: 'Online-form' || 'Worksheet', table: table};
        table='';
        return base64(format(template, ctx));        
    };

    uploadFirst(event){
        event.target.disabled = true;        
        this.spinner = true;
        const fileContents = this.convertToExcel();        
        
        if(fileContents.length<MAX_FILE_SIZE){            
            let fromIndex = 0;
            let toIndex = Math.min(fileContents.length, fromIndex + CHUNK_SIZE);                                
            this.uploadChunk(fileContents, fromIndex, toIndex, '');
        }
        else{
            console.log('file size: '+fileContents.length+' byte');
            event.target.disabled = false;
            this.spinner = false;
            let filezise = parseInt(fileContents.length/1000000);
            showToast(this,Send_Report_Message,'error','Error');
        }            
    };

    uploadChunk(fileContents, fromIndex, toIndex, fileId){
        
        let chunk = fileContents.substring(fromIndex, toIndex);
        let self = this;
        saveChunk({ 
            parentId: this.editionId,
            base64Data: encodeURIComponent(chunk),
            fileId: fileId
        }).then(result => {
            try
            {
                fileId = result;
                fromIndex = toIndex;
                toIndex = Math.min(fileContents.length, fromIndex + CHUNK_SIZE);            
                if (fromIndex < toIndex) {
                    this.uploadChunk(fileContents, fromIndex, toIndex, fileId);  
                } 
                else {
                    this.sendNow(fileId);         
                }
            }
            catch(e){
                console.error('error: '+e);
            }
        })
        .catch(error => {
            handleErrors(this,error);
        })
        .finally(()=>{
            console.log('uploaded');
        });
        
    };


    sendNow(fileId){
        var emailId = this.inputVal.replaceAll('\\s+','').replace(';',',').split(',');
        var emailSub;
        var emailBody;
        if(this.subVal == '' || this.subVal == null){
            emailSub = this.emailSub;
        }
        else{
            emailSub = this.subVal;
        }
        if(this.bodyVal == '' || this.bodyVal == null){
            emailBody = this.emailBody;
        }
        else{
            emailBody = this.bodyVal;
        }
        
        sendMails({ emails : emailId,emailSub : emailSub, emailBody : emailBody,attId:fileId})
        .then(() => {            
            showToast(this,'Report has been sent!','success','Success');
            this.hideModal();
        })
        .catch(error => {            
            handleErrors(this,error);
        })
        .finally(()=>{
            this.spinner = false;
        });                
    };
}