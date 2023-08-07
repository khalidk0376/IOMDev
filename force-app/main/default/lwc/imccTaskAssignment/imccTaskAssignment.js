import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import InformaMarketsCSS from '@salesforce/resourceUrl/InformaMarketsCSS';
import assignFormToTeam from '@salesforce/apex/IMCC_ManageTaskAssignmentCtrl.assignFormToTeam';
import { showToast,handleUIErrors,handleErrors } from 'c/imcc_lwcUtility';


export default class ImccTaskAssignment extends LightningElement {
    @api taskTitle;
    @api option1;
    @api option2;
    @api option3;
    @api enabledPagination;
    @api platformAdminCemId;
    @api tabId;
    @api userInfo;

    //filter1
    filterField1Options;
    filter1Label = 'Assignee';
    filterField1 = 'Assign_To__c';    
    filterField1Value = '';

    //filter 2
    filterField2Options;
    filter2Label = 'Form Provider';
    filterField2 = 'Form_Provider__c';    
    filterField2Value = '';
    
    //filter 3
    filterField3Options;
    filter3Label = 'Status';
    filterField3 = 'Overall_Status__c';    
    filterField3Value = '';

    //search
    searchValue = '';

    @api filter1Label;
    @api filter2Label;
    @api filter3Label;
    @api formData;
    @api isManual;

    // variable that use in getData 
    @track methodName;
    sortByName = 'formName';
    sortType = 'asc';
    filterFormDatas = [];
    
    @track allTableData;
    @track tableData;
    
    mapPDFD = {}
    mapFDExpand = {};
    @api formtype = '';
    isUploadEnable = true
    @api nodata = false;
    entryId;
    formType;
    progressPercent = 0;    
    isMultiEntry = 0;
    updatedRows = [];
    showfooter = false;
    @track totalTask;

    connectedCallback() {
        this.totalTask = 0;
        this.allTableData = JSON.parse(JSON.stringify(this.formData));
        this.filterField1Options = JSON.parse(JSON.stringify(this.option1));
        this.filterField2Options = JSON.parse(JSON.stringify(this.option2));
        this.filterField3Options = JSON.parse(JSON.stringify(this.option3));
        
        this.filterFormDatas = JSON.parse(JSON.stringify(this.formData));
        
        loadScript(this, InformaMarketsCSS + '/CustomerCenterWS11/js/jquery-1.7.1.min.js')
        .then(() => {
            let that = this;
            window.jQuery("body").click(function (event) {
                that.closeFilterOption(null);
            });
        })
        .catch(errors => {
            console.log(errors);
        });
        
        this.getData();
    };

    openFilterOption(event) {
        event.stopPropagation();
        event.currentTarget.classList.toggle('active');
        var classList = "," + event.currentTarget.className.split(" ").join(",") + ",";
        var className = '';
        if (classList.indexOf(',filter1,') != -1) {
            className = 'filter1';
        }
        if (classList.indexOf(',filter2,') != -1) {
            className = 'filter2';
        }
        if (classList.indexOf(',filter3,') != -1) {
            className = 'filter3';
        }
        this.closeFilterOption(className);
    };

    @track isDropdownOpen;
    closeFilterOption(className) {
        this.isDropdownOpen = false;
        if (className == null) {
            const filter1 = this.template.querySelector('.filter1');
            if (filter1) {
                filter1.classList.remove('active');
            }
            const filter2 = this.template.querySelector('.filter2');
            if (filter2) {
                filter2.classList.remove('active');
            }
            const filter3 = this.template.querySelector('.filter3');
            if (filter3) {
                filter3.classList.remove('active');
            }
        }
        else {
            if (className != 'filter1') {
                const filter1 = this.template.querySelector('.filter1');
                if (filter1) {
                    filter1.classList.remove('active');
                }
            }
            if (className != 'filter2') {
                const filter2 = this.template.querySelector('.filter2');
                if (filter2) {
                    filter2.classList.remove('active');
                }
            }
            if (className != 'filter3') {
                const filter3 = this.template.querySelector('.filter3');
                if (filter3) {
                    filter3.classList.remove('active');
                }
            }
        }
    };

    onTopClick(event) {
        event.stopPropagation();
    }
    
    //#region Form Data Related Methods
    //Get Form Data And Entries
    getData(isLoadAgain=true) {
        this.methodName = 'getData';
        let f = this.sortByName;
        let d = this.sortType;
        this.filterFormDatas.sort(function (a, b) {
            var ret = ((a[f] < b[f]) ? (-1) : ((a[f] > b[f]) ? (1) : (0)));
            return (d == "asc" ? ret : (0 - ret));
        });

        if (this.filterFormDatas.length === 0) {
            this.error = 'No record found';
            this.tableData = undefined;
        }
        else {
            this.tableData = JSON.parse(JSON.stringify(this.filterFormDatas));
            this.error = undefined;                   
            //Code to Show Only Unique Form Datas : Start
            let uniqueformAllocs = {};
            let mapFormAllocsListFD = {};
            this.mapPDFD = {};
            let fdIndex = -1;
            this.totalTask = 0;            
            this.tableData.forEach(row => {
                row.isShowFormData = true;
                this.totalTask = this.totalTask + 1;
                let fAllocId = row.Forms_Permission__r.Form_Allocation__c;
                fdIndex++;
                mapFormAllocsListFD[fAllocId] = mapFormAllocsListFD.hasOwnProperty(fAllocId) ? mapFormAllocsListFD[fAllocId] : [];
                mapFormAllocsListFD[fAllocId].push(row);
                if (!uniqueformAllocs.hasOwnProperty(fAllocId)) {
                    uniqueformAllocs[fAllocId] = fdIndex;
                    row.isShowFormData = true;
                    if (row.Purchase_Data__c != null) {
                        this.mapPDFD[row.Purchase_Data__c + '_' + fAllocId] = row;
                    }                    
                }
                else {
                    let firstFDIndex = uniqueformAllocs[fAllocId];

                    this.tableData[firstFDIndex].Form_Response_Entries__r = this.tableData[firstFDIndex].Form_Response_Entries__r == null ? [] : this.tableData[firstFDIndex].Form_Response_Entries__r;

                    if (row.Form_Response_Entries__r != null) {
                        Array.prototype.push.apply(this.tableData[firstFDIndex].Form_Response_Entries__r, row.Form_Response_Entries__r);
                    }
                    if (row.Purchase_Data__c != null) {
                        this.mapPDFD[row.Purchase_Data__c + '_' + fAllocId] = row;
                    }
                }
            });

            //Code to Show Only Unique Form Datas : End
            let date2;
            let today = new Date().setHours(0, 0, 0, 0);
            
            this.tableData.forEach(row => {
                let deadline = row.Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c;
                if (deadline) {
                    date2 = new Date(deadline).setHours(0, 0, 0, 0);
                    let prev7Days = new Date(new Date().getTime() - (7 * 24 * 60 * 60 * 1000)).setHours(0, 0, 0, 0);
                    let next7Days = new Date(new Date().getTime() + (7 * 24 * 60 * 60 * 1000)).setHours(0, 0, 0, 0);
                    row.statusClass = 's';
                    row.statusClassDate = 's slds-truncate para paragraph-d-small paragraph-m-small';

                    if (row.Overall_Status__c === 'Submitted' || row.Overall_Status__c === 'Resubmitted' || row.Overall_Status__c === 'Approved' || row.Overall_Status__c === 'Agreed') {
                        row.statusClass = 's s-green';
                        row.statusClassDate += ' s-green';
                        row.isCompleted = true;
                    }
                    else {
                        if (date2 < today) {
                            row.statusClass = 's s-red';
                            row.statusClassDate += ' s-red';
                        }
                        else if (date2 > next7Days) {
                            row.statusClass = 's s-gray';
                            row.statusClassDate += ' s-gray';
                        }
                        else if (date2 >= prev7Days || date2 == today) {
                            row.statusClass = 's s-purple';
                            row.statusClassDate += ' s-purple';
                        }
                    }
                } 
            });            

            if(isLoadAgain && this.enabledPagination && this.template.querySelector('c-imcc-pagination')){
                console.log('c-imcc-pagination');
                this.template.querySelector('c-imcc-pagination').setRecordDatas(this.tableData);
            }
        }        
    }

    getMonth(month) {
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

    handleFilterChange(event) {
        if (event) {
            let index = parseInt(event.target.dataset.index, 10);
            let filterName = event.target.dataset.filter;            
            if (filterName == "1") {
                this.filterField1Options[index].isChecked = event.target.checked;
            }
            else if (filterName == "2") {
                this.filterField2Options[index].isChecked = event.target.checked;
            }
            else if (filterName == "3") {
                this.filterField3Options[index].isChecked = event.target.checked;
            }
        }
        console.log(JSON.stringify(this.filterField1Options));
        this.filterFormData();
        this.getData();
    };

    //Used to filter list using all three filters value and fields
    filterFormData() {
        if (this.filterField1Options) {
            let str = "";
            this.filterField1Options.forEach(item => {
                str += (item.isChecked ? ((str === "" ? "" : "','") + item.value) : "");
            });
            this.filterField1Value = str;
        }

        if (this.filterField2Options) {
            let str = '';
            this.filterField2Options.forEach(item => {
                str += (item.isChecked ? ((str === "" ? "" : "','") + item.value) : "");
            });
            this.filterField2Value = str;
        }

        if (this.filterField3Options) {
            let str = '';
            this.filterField3Options.forEach(item => {
                str += (item.isChecked ? ((str === "" ? "" : "','") + item.value) : "");
            });
            this.filterField3Value = str;
        }

        const selectedValue1 = this.filterField1Value ? this.filterField1Value : '';
        const selectedValue2 = this.filterField2Value ? this.filterField2Value : '';
        const selectedValue3 = this.filterField3Value ? this.filterField3Value : '';
        console.log(selectedValue1+':'+selectedValue2+':'+selectedValue3);
        this.filterFormDatas = [];
        let formDatas = JSON.parse(JSON.stringify(this.formData));
        let formDatasTemp = [];
        formDatas.forEach(row => {
            let f1 = this.filterField1;
            let f2 = this.filterField2;
            let f3 = this.filterField3;
            let val1 = "'" + (row[f1] == null ? "NULL" : row[f1]) + "'";
            let val2 = "'" + (row[f2] == null ? "NULL" : row[f2]) + "'";
            let val3 = "'" + (row[f3] == null ? "NULL" : row[f3]) + "'";
            let include1 = true;
            let include2 = true;
            let include3 = true;
            if (selectedValue1 !== '') {
                if (("'" + selectedValue1 + "'").indexOf(val1) == -1) {
                    include1 = false;
                }
            }
            if (selectedValue2 !== '') {
                if (("'" + selectedValue2 + "'").indexOf(val2) == -1) {
                    include2 = false;
                }
            }
            if (selectedValue3 !== '') {
                if (("'" + selectedValue3 + "'").indexOf(val3) == -1) {
                    include3 = false;
                }
            }
            if (include1 && include2 && include3) {
                formDatasTemp.push(row);
            }
        });

        if (this.searchValue != null && this.searchValue.trim() != '') {
            let searchValue = this.searchValue.trim();
            formDatasTemp.forEach(row => {
                if ((row.Form_Category__c != null && row.Form_Category__c.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)
                    || (row.Form_Provider__c != null && row.Form_Provider__c.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)
                    || (row.formName != null && row.formName.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)
                    || (row.Form_Type__c != null && row.Form_Type__c.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)
                    || (row.Form_Entry__c != null && row.Form_Entry__c.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)
                    || (row.Overall_Status__c != null && row.Overall_Status__c.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)
                    || (row.AssignToName != null && row.AssignToName.toLowerCase().indexOf(searchValue.toLowerCase()) != -1)) {
                    this.filterFormDatas.push(row);
                }
            });
        }
        else {
            formDatasTemp.forEach(row => {
                this.filterFormDatas.push(row);
            });
        }
    }
    
    //#region Filter/Sorting Methods
    clearFilter() {
        let option1 = this.filterField1Options;
        option1.forEach(item => {
            item.isChecked = false;
        });
        this.filterField1Options = option1;

        let option2 = this.filterField2Options;
        option2.forEach(item => {
            item.isChecked = false;
        });
        this.filterField2Options = option2;

        let option3 = this.filterField3Options;
        option3.forEach(item => {
            item.isChecked = false;
        });
        this.filterField3Options = option3;

        this.filterFormData();

        if (this.isMoboFilterApplied) {
            this.closeMobileMenu();
            this.isMoboFilterApplied = false;
        }
        this.getData();
    };

    openMobileMenu(event) {
        event.stopPropagation();
        let height = screen.height - 160;
        this.template.querySelector(".mobile-menu-body").style = "height:" + height + "px";
        let progress = 480;
        this._interval = setInterval(() => {
            progress = progress - 100;
            if (progress <= 0) {
                progress = 0;
                clearInterval(this._interval);
                this.template.querySelector(".modal-overlay").classList.add("active");
            }
            this.template.querySelector(".mobile-menu").style = "display: block;transform-style: preserve-3d;-webkit-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
        }, 10);
    };

    closeMobileMenu() {
        /* working good, don't remove comment before ticket assign*/
        let progress = 0;
        this._interval = setInterval(() => {
            progress = progress + 100;
            if (progress >= 480) {
                progress = 480;
                clearInterval(this._interval);
                this.template.querySelector(".modal-overlay").classList.remove("active");
                this.template.querySelector(".mobile-menu").style = "display: none;transform-style: preserve-3d;-webkit-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
            }
            this.template.querySelector(".mobile-menu").style = "transform-style: preserve-3d;-webkit-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-moz-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);-ms-transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);transform:translate3d(" + progress + "px, 0, 0px) scale3d(1, 1, 1) rotateX(0) rotateY(0) rotateZ(0) skew(0, 0);";
        }, 10);
    };

    toggleMoboFilter(event) {
        let className = event.currentTarget.dataset.filter;
        if (className === 'filter1') {
            this.template.querySelector('.mob-filter2').classList.remove("active");
            this.template.querySelector('.mob-filter3').classList.remove("active");
            this.template.querySelector('.mob-' + className).classList.toggle("active");
        }
        if (className === 'filter2') {
            this.template.querySelector('.mob-filter1').classList.remove("active");
            this.template.querySelector('.mob-filter3').classList.remove("active");
            this.template.querySelector('.mob-' + className).classList.toggle("active");
        }
        if (className === 'filter3') {
            this.template.querySelector('.mob-filter1').classList.remove("active");
            this.template.querySelector('.mob-filter2').classList.remove("active");
            this.template.querySelector('.mob-' + className).classList.toggle("active");
        }
    };

    moboFilterChange(event) {
        let index = parseInt(event.target.dataset.index, 10);
        let filterName = event.target.dataset.filter;
        if (filterName == "1") {
            this.isMoboFilterApplied = true;
            this.filterField1Options[index].isChecked = event.target.checked;
        }
        else if (filterName == "2") {
            this.isMoboFilterApplied = true;
            this.filterField2Options[index].isChecked = event.target.checked;
        }
        else if (filterName == "3") {
            this.isMoboFilterApplied = true;
            this.filterField3Options[index].isChecked = event.target.checked;
        }
        console.log(JSON.stringify(this.filterField3Options));
    };

    applyMobileFilter() {
        if (this.isMoboFilterApplied) {
            this.closeMobileMenu();
            this.filterFormData();
            this.getData();
        }
        else {
            showToast(this, 'Please select filter before apply', 'error', 'Validation Error');
        }
    };

    //Fire whenever user type in search box, but data load if search field empty
    searchForm(event) {
        let searchValue = event.detail.value;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.searchValue = searchValue;
            this.filterFormData();
            this.getData();
        }, 750);
    };

    handleSorting(event) {
        let prevSortDir = this.sortType;
        let prevSortedBy = this.sortByName;
        this.sortByName = event.currentTarget.id.split("-")[0];
        let iconName = 'utility:up';

        if (this.sortByName === prevSortedBy && prevSortDir === 'asc') {
            this.sortType = 'desc';
            iconName = 'utility:down';
        }
        else if (this.sortByName === prevSortedBy && prevSortDir === 'desc') {
            this.sortType = 'asc';
        }
        else if (this.sortByName !== prevSortedBy) {
            this.sortType = 'asc';
        }
        event.currentTarget.querySelector('lightning-icon').iconName = iconName;
        this.filterFormData();
        this.getData();
    };

    //pagination handler
    paginationHandler(event){
        this.filterFormDatas = event.detail.records;        
        //console.log('Pagination Data-1: '+JSON.stringify(this.filterFormDatas))
        this.getData(false);
        //console.log('Pagination Data-2: '+JSON.stringify(this.filterFormDatas))
    };

    get isFilterApplied() {
        return this.filterField1Value || this.filterField2Value || this.filterField3Value;
    };

    handleAssignment(event){
        let index = parseInt(event.target.dataset.itemIndex,10);
        console.log('index '+index);
    };

    previousHandler(event){
        const selectedvalue = event.target.value;
        let selectedIndex = event.target.dataset.index;        
        console.log(JSON.stringify(this.tableData[selectedIndex]));
        if(selectedvalue){
            this.saveChanges({"Id":this.tableData[selectedIndex].Id,"Assign_To__c":selectedvalue},selectedIndex);
        }
    };

    saveChanges(updatedRows,selectedIndex){        
        let url = this.getPageUrlByType('Standard', 'Manage My Task');        
        assignFormToTeam({formDataToUpdate:[updatedRows], tabId:this.tabId, tabName:url})    
        .then(fd =>{
            let index = -1;
            this.allTableData.forEach((i,ind)=>{
                if(i.Id==updatedRows.Id){
                    index = ind;                    
                }
            });
            if(index>-1){
                this.allTableData[index].AssignToId = updatedRows.Assign_To__c;
                this.allTableData[index].AssignToName = fd.Assign_To__r.Contact__r.Name; 
                this.tableData[selectedIndex].AssignToId = updatedRows.Assign_To__c;
                this.tableData[selectedIndex].AssignToName = fd.Assign_To__r.Contact__r.Name;

                let tempTeamMember = JSON.parse(JSON.stringify(this.allTableData[index].memberList));    
                //set value to dropdown                
                if(tempTeamMember[0].value==''){//remove Select Option from drop down if already assiged task
                    tempTeamMember.splice(0,1);
                }
                tempTeamMember.forEach(opt=>{
                    opt.selected = opt.value==this.allTableData[index].AssignToId?true:false;
                });
                this.allTableData[index].memberList = tempTeamMember;
                this.tableData[selectedIndex].memberList = tempTeamMember;
                console.log(JSON.stringify(this.allTableData[index]));
            }                       
            showToast(this,'Task have been assigned successfully','success','Success');
        })
        .catch(error => {		
            handleErrors(this,error);
        });
    };

    getPageUrlByType(tabType, stndrdTabType) {
        let urlStr = '';
        if (tabType == 'Custom') {
            if (stndrdTabType == 'HTML') {
                urlStr = '/IMCC/s/custom-html';
            }
            else {
                urlStr = '/IMCC/s/custompages';
            }
        }
        if (tabType == 'Standard') {
            if (stndrdTabType == 'Floorplan') {
                urlStr = '/IMCC/s/floorplan';
            }
            if (stndrdTabType == 'FAQ') {
                urlStr = '/IMCC/s/faqs';
            }
            if (stndrdTabType == 'Forms') {
                urlStr = '/IMCC/s/forms';
            }
            if (stndrdTabType == 'Manuals') {
                urlStr = '/IMCC/s/manuals';
            }
            if (stndrdTabType == 'Badges') {
                urlStr = '/IMCC/s/badges';
            }
            if (stndrdTabType == 'Stand Contractors') {
                urlStr = '/IMCC/s/stand-contractors';
            }
            if (stndrdTabType == 'Stand Design') {
                urlStr = '/IMCC/s/stand-design';
            }
            if (stndrdTabType == 'Lead Retrieval') {
                urlStr = '/IMCC/s/lead-retrieval';
            }
            if (stndrdTabType == 'Virtual Event') {
                urlStr = '/IMCC/s/virtual-event';
            }
            if (stndrdTabType == 'Badge Registration') {
                urlStr = '/IMCC/s/badge-registration';
            }
            if (stndrdTabType == 'Manage Team') {
                urlStr = '/IMCC/s/teams-manager';
            }
            if (stndrdTabType == 'Manage My Task') {
                urlStr = '/IMCC/s/manage-my-task';
            }
        }
        return urlStr;
    };

    get isDisableToAssignTask(){
        let ret = true;
        if(this.userInfo){
            ret = !(this.userInfo.Role__c=='Platform Admin' || this.userInfo.Role__c=='Secondary Admin');
        }
        return ret;
    }
}