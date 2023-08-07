/**
* Project      	:   Order & Billing Plateform [IOM-519]
* Created By	: 	Ashish (Girikon)
* Created Date	: 	18 JAN 2022
* ***************************************************************************
* @description : to Show Collection Notes Data from IOM to CRM Orgs
*/
import { LightningElement, track, api } from 'lwc';
import findAllRecords from '@salesforce/apex/OppLtngOutUtils.getCollectionNotes';

export default class OppInvCollectionNotesDetails extends LightningElement 
{
    @api imOppNo;

    recordSize = 0;
    totalData = [];
    isSpiner;
    hasData;
    erMessage;
    noteMessage;
    cNote;
    isNoteModalOpen;

    // Pagination 
    page = 1; //this will initialize 1st page      
    pageData = []; //data to be display in the table
    columns; //holds column info.
    startingRecord = 1; //start record position per page
    endingRecord = 0; //end record position per page
    pageSize = 10; //default value we are assigning
    totalRecountCount = 0; //total record count received from all retrieved records
    totalPage = 0; //total number of page is needed to display all records

    connectedCallback(){
        this.isSpiner = false;
        console.log('IOM Opportunity No - '+this.imOppNo);
        this.getAllCNotes();
        this.hasData = true;
    }

    getAllCNotes() //get all Collection Note
    {
        this.isSpiner = true;
        findAllRecords({
            imOppNumber : this.imOppNo
        })
        .then(result => {
            if(result)
            {
                this.totalData = JSON.parse(JSON.stringify(result));
                if(result && Array.isArray(result) && result.length>0)
                {
                    this.getPageData();
                }else{
                    this.hasData = false;
                    this.erMessage = 'No data available';
                }
            }            
            this.isSpiner = false;
        })
        .catch(error => {            
            this.error = error;
            this.records = undefined;
            this.isSpiner = false;
        });
    }

    getPageData()
    {
        let pgData = [];
        this.totalData.forEach((row) => {
            row.InvoiceNumber = row.Invoice__r.Name;
            row.InvoiceOutStandingBalc = row.Invoice__r.Outstanding_Balance__c;
            row.InvoiceStatus = row.Invoice__r.blng__InvoiceStatus__c;
            row.hasNote = row.Note__c ? true :false;
            row.InvoiceCurrencyISOCode = row.Invoice__r.CurrencyISOCode
            pgData.push(row);
        });
        this.pageData = pgData;
        this.recordSize = pgData.length;
    }

    handleNoteClick(event)
    {
        this.noteMessage = '';
        let id = event.currentTarget.dataset.id;
        this.totalData.forEach((row) => {
            if(id == row.Id)
            {
                this.cNote = row;
            }
        }); 
        this.isNoteModalOpen = true;
    }

    closeNoteModal()
    {
        this.cNote = {};
        this.isNoteModalOpen = false;
    }
}