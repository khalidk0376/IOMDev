/**
* Project      	:   Order & Billing Plateform [IOM-519]
* Created By	: 	Ashish (Girikon)
* Created Date	: 	18 JAN 2022
* ***************************************************************************
* @description : to Show Collection Notes Data from IOM to CRM Orgs
*/
import { LightningElement,track,wire,api } from 'lwc';
import sheetJS from '@salesforce/resourceUrl/IOM_sheetJS';
import {loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import updateBulkMetadata from '@salesforce/apex/IOM_BulkUploadMetadata.updateBulkMetadata'
import getCustomMetaDataList from '@salesforce/apex/IOM_BulkUploadMetadata.getCustomMetaDataList'

export default class IomfileuploadercompLWC extends LightningElement {
    @track dataList = [];
    @track showSpinner = true;
    @track customMetaDataList = [];
    selectedMetaDataApiName;
    selectedMetaDataLabel;
    @track fieldsInfo = {};
    @track fieldsList = [];
    @track columnsList = [];
    @track columnsMap = {};
    @api objectName;
    @track showFileUpload = true;
    @track showMetataSelection = false;
    @track showMapping = false;
    devNameMappedColumnName;


    connectedCallback() {
        loadScript(this, sheetJS).then(() => {
             //console.log(' load  sheet JS complete ');
             this.fetchAllUnmangedCustomMetaDataList();
        });
    }

    fetchAllUnmangedCustomMetaDataList(){
        getCustomMetaDataList()
        .then(resultRT => {
            this.customMetaDataList = resultRT;
            this.showSpinner = false;
        }).catch(errorRT => {
            console.log('ERR fetchAllUnmangedCustomMetaDataList=='+JSON.stringify(errorRT));
            this.showSpinner = false;
        });
    }

    @wire(getObjectInfo, { objectApiName: '$objectName'})
    objectInfo({ error, data }) {
        if (data) {
            this.fieldsInfo = JSON.parse(JSON.stringify(data.fields));
            // console.log('getObjectInfo=='+JSON.stringify(this.fieldsInfo));
            var excludedFields = [];
            this.fieldsList = [];
            excludedFields.push("Id");
            excludedFields.push("Language");
            excludedFields.push("Label");
            excludedFields.push("NamespacePrefix");
            excludedFields.push("QualifiedApiName");
            let opt1 = { label: "No Mapping", value: "NA"};
            this.fieldsList.push(opt1);
            for(var fieldApiName in this.fieldsInfo){
                if(this.fieldsInfo.hasOwnProperty(fieldApiName) && excludedFields.indexOf(fieldApiName) == -1) {
                    let opt = { label: this.fieldsInfo[fieldApiName].label, value: fieldApiName};
                    this.fieldsList.push(opt);
                }
            }
            //console.log('getObjectInfo=='+JSON.stringify(this.fieldsList));
            this.showSpinner = false;

        }else if (error) {
            console.log('ERR getObjectInfo=='+JSON.stringify(error));
            this.showSpinner = false;
        }
    }

    handleChangeMetaData(event){
        this.selectedMetaDataApiName = event.detail.value;
        //console.log('this.selectedMetaDataApiName=='+this.selectedMetaDataApiName);
        this.selectedMetaDataLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
        //console.log('this.selectedMetaDataLabel=='+this.selectedMetaDataLabel);
        this.objectName = this.selectedMetaDataApiName;
        this.showSpinner = true;
    }

    handleChangeFields(event){
        var index = parseInt(event.target.dataset.index);
        var fieldname = event.detail.value;
        if(fieldname != "NA"){
            for(var i=0;i<this.columnsList.length;i++){
                if(fieldname == this.columnsList[i].fieldname && index != i){
                    this.toast('Field already mapped to Column : ' + this.columnsList[i].name +'.',"error");
                }
            }
        }
        if(fieldname == "DeveloperName"){
            this.devNameMappedColumnName = this.columnsList[index].name;
        }
        this.columnsList[index].fieldname = fieldname;
        if(fieldname != "NA"){
            this.columnsList[index].datatype = this.fieldsInfo[fieldname].dataType;
        }
        this.columnsMap[this.columnsList[index].name] = this.columnsList[index];
        //console.log('this.columnsMap=='+JSON.stringify(this.columnsMap));
    }

    excelFileToJson(event) {
        this.showSpinner = true;
        event.preventDefault();
        let files = event.target.files;
        const analysisExcel = (file) =>
            new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.readAsBinaryString(file);
                reader.onload = () => resolve(reader.result);
                reader.onerror = (error) => reject(error);
            });
        analysisExcel(files[0])
        .then((result) => {
            let datas = []; //  Store the acquired data
            let XLSX = window.XLSX;
            let workbook = XLSX.read(result, {
                type: 'binary'
            });

            for (let sheet in workbook.Sheets) {
                if (workbook.Sheets.hasOwnProperty(sheet)) {
                    datas = datas.concat(XLSX.utils.sheet_to_json(workbook.Sheets[sheet]));
                }
            }
            this.dataList = datas;
            console.log('this.dataList=='+JSON.stringify(this.dataList));
            var index = -1;
            this.columnsList = [];
            for(var columnName in this.dataList[0]){
                index++;
                var colDet = {"name":columnName,"index":index,"fieldname":"","datatype":""};
                this.columnsList.push(colDet);
                this.columnsMap[columnName] = colDet;
            }
            console.log('this.columnsList=='+JSON.stringify(this.columnsList));
            //console.log('this.columnsMap=='+JSON.stringify(this.columnsMap));
            this.toast('The file has been uploaded and parsed successfully.',"success");
            this.showSpinner = false;
            this.showMetaDataScreen();
        });

    }

    saveData() {
        this.showSpinner = true;
        var isOk = true;
        var msg = "";
        for(var i=0;i<this.columnsList.length;i++){
            if(this.columnsList[i].fieldname == "" || this.columnsList[i].fieldname == null){
                isOk = false;
                msg = 'Map All Columns.';
            }
        }
        if((this.devNameMappedColumnName == null || this.devNameMappedColumnName == "") && isOk){
            isOk = false;
            msg = 'Custom Metadata Record Name Column not mapped to any column.';
            this.showSpinner = false;
        }
        if(isOk){
            var columnMap = {};
            for(var i=0;i<this.columnsList.length;i++){
                if(this.columnsList[i].fieldname != "NA"){
                    columnMap[this.columnsList[i].index] = JSON.parse(JSON.stringify(this.columnsList[i]));
                    delete columnMap[this.columnsList[i].index].index;
                    delete columnMap[this.columnsList[i].index].name;
                }
            }
            var dataForSave = {};
            for(var i=0;i<this.dataList.length;i++){
                var data = this.dataList[i];
                var devName = data[this.devNameMappedColumnName];
                var listData = [];
                for(var columnName in data){
                    if(columnName != this.devNameMappedColumnName){
                        var mapping = this.columnsMap[columnName];
                        if(mapping.fieldname != "NA"){
                            var tempData = {
                                "index" : mapping.index+"",
                                "value": data[columnName]+""
                            };
                            listData.push(tempData);
                        }
                    }
                }
                dataForSave[devName] = listData;
            }
            console.log("columnMap===",JSON.stringify(columnMap));
            console.log("dataForSave===",JSON.stringify(dataForSave));
            
            var params = {
                jsonString : JSON.stringify(dataForSave),
                mappingString : JSON.stringify(columnMap),
                customMetaDataName : this.objectName
            };

            updateBulkMetadata(params)
            .then(result=>{
                let title = 'Records Queued For Save!!'
                this.toast(title,"success");

                this.dataList = [];
                this.selectedMetaDataApiName = null;
                this.selectedMetaDataLabel = null;
                this.fieldsInfo = {};
                this.fieldsList = [];
                this.columnsList = [];
                this.columnsMap = {};
                this.objectName = null;
                this.devNameMappedColumnName = null;

                this.showFileUpload = true;
                this.showMetataSelection = false;
                this.showMapping = false;

                this.showSpinner = false;
            }).catch(errorRT => {
                console.log('ERR updateBulkMetadata=='+JSON.stringify(errorRT));
                this.showSpinner = false;
            });
        }
        else{
            this.toast(msg,"error");
            this.showSpinner = false;
        }
    }

    showMetaDataScreen(){
        this.showFileUpload = false;
        this.showMetataSelection = true;
        this.showMapping = false;
    }
    
    showMappingScreen(){
        if(this.selectedMetaDataApiName == null || this.selectedMetaDataApiName == ''){
            this.toast('Select Custom Metadata.',"error");
        }
        else{
            this.showFileUpload = false;
            this.showMetataSelection = false;
            this.showMapping = true;
        }
    }

    toast(msg,type){
        const toastEvent = new ShowToastEvent({
            variant: type,
            message: msg
        });
        this.dispatchEvent(toastEvent);
    }
}