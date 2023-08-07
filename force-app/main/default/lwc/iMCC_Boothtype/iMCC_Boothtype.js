import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
export default class IMCC_Boothtype extends LightningElement {
    @api recordId;
    @api field;
    @api objectApiName;
    @track recordFields;
    boothTypes = [];
    titleWithCount;

    connectedCallback() {
        this.recordFields = [(this.objectApiName+"."+this.field)];
        this.boothTypes = [];
        this.titleWithCount = "Booth/Product Types (" + 0 + ")";
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$recordFields' })
    wiredData({ error, data }) {
        if (data) {
            var boothProductType = data.fields[this.field].value;
            if(boothProductType == "" || boothProductType == null || boothProductType == ";"){
                this.boothTypes = [];
                this.titleWithCount = "Booth/Product Types (" + 0 + ")";
            }
            else{
                let boothTypesArray = boothProductType.split(";");
                let index = 0;
                let lst = [];
                boothTypesArray.forEach(row => {
                    index++;
                    lst.push({boothType:row,number:index});
                });
                this.titleWithCount = "Booth/Product Types (" + lst.length + ")";
                this.boothTypes = lst;
            }
        }
        if (error) {
            console.error("wiredData===",error);
        }
    }
}