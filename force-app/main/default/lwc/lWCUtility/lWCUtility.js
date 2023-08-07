/*
Created By	 : Girikon(Sachin)(IML2R-742)
Created On	 : ‎Feb ‎19, ‎2020
@description : To create a lib in LWC there is no need of html file so removed girikonUtils.html file. 
There is no need to extends LightningElement class. Now creating a simple method to calculate simple interest.

Modification log --
Modified By	: 
*/
/* eslint-disable no-console */
import getRecordDetail from '@salesforce/apex/CommonTableController.getRecordDetail';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

/**
 * Handle error that is thrown by Apex action and show Error in toast(ShowToastEvent)
 * 
 * @param that pass this object of lwc component
 * @param error pass error object return by apex AuraEnabled action  
 */
const handleErrors = (that,error)=>{
    console.error(JSON.stringify(error));
    let message = 'Unknown Error';
    if (error) {

        if (error.body!==undefined && Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } 
        else if (error.body!==undefined && typeof error.body.message === 'string') {
            message = error.body.message;
        }
        else if(error.detail!==undefined && error.detail!==''){
            message = error.detail;
        }
        else if(error.message!==undefined && error.message!==''){
            message = error.message;
        }
    }    
    return that.dispatchEvent(new ShowToastEvent({
        variant:'error',
        title:'Error',
        message : message
    }));        
}

/**
 * Show toast message in Lightning Experience and Lightning community only.
 * 
 * @param that pass this object of lwc component
 * @param message pass message text body 
 * @param type toast type
 * @param title toast title
 */
const showToast = (that,message,type,title)=>{    
    return that.dispatchEvent(new ShowToastEvent({
        variant:type,
        title:title,
        message : message
    }));    
}

/**
 * Export JSON data in CSV format. We need to pass Array of json object and required key
 * 
 * @param recordList All JSON List data like [{'key1':'value1'},{'key2':'value2'}]
 * @param requiredlabels pass array of key like ['key1','key1']
 * @param fileName toast type
 */
const exportCSV = (recordList,requiredlabels,fileName)=>{
    let rowEnd = '\n';
    let csvString = '';
    // this set elminates the duplicates if have any duplicate keys
    let rowData = new Set();
    //let requiredlabels = ['ExhibitorId', 'BoothNumber', 'Dimensions', 'Area', 'DisplayNameOverride', 'IsRented'];
    // getting keys from data
    recordList.forEach(function (record) {
        Object.keys(record).forEach(function (key) {
            if(requiredlabels.indexOf(key)>=0){
                rowData.add(key);
            }
        });
    });
    // Array.from() method returns an Array object from any object with a length property or an iterable object.
    rowData = Array.from(rowData);
    // splitting using ','
    csvString += rowData.join(',');
    csvString += rowEnd;
    // main for loop to get the data based on key value
    for (let i = 0; i < recordList.length; i++) {
        let colValue = 0;
        // validating keys in data
        for (let key in rowData) {
            if (rowData.hasOwnProperty(key)) {
                let rowKey = rowData[key];
                
                // add , after every value except the first.
                if (colValue > 0) {
                    csvString += ',';
                }
                // If the column is undefined, it as blank in the CSV file.
                if (requiredlabels.indexOf(rowKey)>=0) {
                    let value = recordList[i][rowKey] === undefined ? '' : recordList[i][rowKey];
                    csvString += '"' + value + '"';
                    colValue++;
                }
            }
        }
        csvString += rowEnd;
    }
    // Creating anchor element to download
    let downloadElement = document.createElement('a');
    // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
    downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
    downloadElement.target = '_self';
    
    downloadElement.download = fileName + '.csv';
    // below statement is required if you are using firefox browser
    document.body.appendChild(downloadElement);
    // click() Javascript function to download CSV file
    downloadElement.click();
    return true;        
}

/**
 * Return record based on object and recordid.
 * 
 * @param that pass this object of lwc component
 * @param objectName Object Api Name
 * @param fieldsName Pass all fields by comma seperated
 * @param recordId pass record id to get single record
 */
const getRecord = (that,objectName,fieldsName,recordId) =>{
    let result;
    getRecordDetail({objectName:objectName,allFields:fieldsName,recordId:recordId})
    .then(data=>{
        if(data.length>0){
            result = data[0];
        }
        return result;
    })
    .catch(error=>{
        this.handleErrors(that,error);
    });
    return result;
}

const groupJSONByValue = (xs, key) =>{
    return xs.reduce(function(rv, x) {
        (rv[x[key]] = rv[x[key]] || []).push(x);
        return rv;
      }, {});
}

export {handleErrors,showToast,getRecord,exportCSV,groupJSONByValue}