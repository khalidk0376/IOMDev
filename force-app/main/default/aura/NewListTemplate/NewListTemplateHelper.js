({
    /*************** Datatable Start **************/
    getTableData: function(component, next, prev, offset) {
        offset = offset || 0;
        var sColumn = component.get("v.fields");
        var sObject = component.get("v.object");
        var pagesize = component.get("v.pagesize");

        var sortBy = component.get("v.sortedBy");
        component.set("v.Spinner", true);
        var action = component.get("c.getGenericObjectRecord");
        action.setParams({
            ObjectName: sObject,
            fieldstoget: sColumn,
            pagesize: pagesize,
            next: next,
            prev: prev,
            off: offset,
            selectCategory: component.get("v.selectCategory"),
            searchValue: component.get("v.searchValue"),
            sortBy: sortBy,
            sortType: component.get("v.sortedDirection")
        });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state == "SUCCESS") {
                var result = res.getReturnValue();
                var qc = result.questionCount;
                var actions = [
                    { label: 'Clone', 'iconName': 'utility:copy', name: 'clone' },
                    { label: 'Edit', 'iconName': 'utility:edit', name: 'edit' },
                    { label: 'Preview', 'iconName': 'utility:preview', name: 'preview' }
                ];
                
                result.ltngTabWrap.tableColumn.push({ label: 'Created Date', fieldName: 'CreatedDate', sortable: true, type: 'date' });
                result.ltngTabWrap.tableColumn.push({ label: 'Question Count', fieldName: 'questionCount', sortable: false, type: 'number', initialWidth: { minColumnWidth: '80px', maxColumnWidth: '120px' }, cellAttributes: { alignment: 'center' } });
                result.ltngTabWrap.tableColumn.push({ label: 'Actions', type: 'action', typeAttributes: { rowActions: actions } });
                component.set("v.mycolumn", result.ltngTabWrap.tableColumn);

                if (result.ltngTabWrap != undefined && result.ltngTabWrap.tableRecord != undefined) {
                    for (var i = 0; i < result.ltngTabWrap.tableRecord.length; i++) {
                        for (var j = 0; j < qc.length; j++) {
                            if (qc[j].Questionnaire__c === result.ltngTabWrap.tableRecord[i].Id) {
                                result.ltngTabWrap.tableRecord[i].questionCount = qc[j].expr0;
                            }
                        }
                    }
                }

                component.set("v.mydata", result.ltngTabWrap.tableRecord);
                component.set('v.offset', result.offst);
                component.set('v.next', result.hasnext);
                component.set('v.prev', result.hasprev);
                component.set("v.totalrows", result.total);
                var totalItems = result.total;

                if (result.offst + pagesize > result.total) {
                    totalItems = result.total;
                } else {
                    totalItems = result.offst + pagesize;
                }

                component.set("v.show_page_view", 'Shows: ' + parseInt(result.offst + 1) + '-' + totalItems);
            }
        });
        $A.enqueueAction(action);
    },
    sortData: function(component, fieldName, sortDirection) {
        var data = component.get("v.mydata");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.mydata", data);
    },
    sortBy: function(field, reverse, primer) {
        var key = primer ?
            function(x) { return primer(x[field]) } :
            function(x) { return x[field] };
        reverse = !reverse ? 1 : -1;
        return function(a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    /*************** Datatable end **************/
    openSidebar: function(component) {
        //window.setTimeout($A.getCallback(function() {            
        component.find('left_box').set("v.size", 8);
        component.find('right_box').set("v.size", 4);
        $A.util.removeClass(component.find('right_box'), 'slds-hide');
        //},100));
    },
    closeSidebar: function(component) {
        component.find('left_box').set("v.size", 12);
        component.find('right_box').set("v.size", 4);
        $A.util.addClass(component.find('right_box'), 'slds-hide');
    },
    hideAllForm: function(component) {
        component.find('new_btn').set("v.variant", "neutral");
        component.find('filter_btn').set("v.variant", "neutral");
        component.set("v.isFilter", false);
        component.set("v.isShowCreateModal", false);
        component.set("v.isCloneTemplate", false);
    },
    getQuesCategory: function(component, event) {
        var action = component.get("c.getQuenaireCategory"); //Calling Apex class controller 'getQuenaireCategory' method
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var opts = [];
                opts.push({ label: 'Select Category', value: '' })
                var res = res.getReturnValue();
                for (var i = 0; i < res.length; i++) {
                    if (res[i] != '')
                        opts.push({ label: res[i], value: res[i] })
                }
                component.set("v.lstQuenaireCategory", opts);
            } else {
                this.showToast(component, 'ERROR:', 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    getQuesLanguage: function(component) {
        var action = component.get("c.getQuenaireLanguage");
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var result = res.getReturnValue();
                console.log(JSON.stringify(result));
                component.set("v.objQuesnaire.Language__c",result[0].value);
                component.set("v.lstLanguage", result);
            } else {
                this.showToast(component, 'ERROR:', 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    
    createNewTemplate: function(component, event) {
        component.set("v.Spinner", true);
        var selColumnNo = component.get("v.selColumnNo");
        var sectionName = component.get("v.sectionName");
        var action = component.get("c.createQnaire");
        var vQuesnaire = component.get("v.objQuesnaire");
        action.setParams({ oQnaire: vQuesnaire, sectionName: sectionName, colnum: selColumnNo });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                component.set("v.QnaireId", res.getReturnValue());
                var vQnaireId = component.get("v.QnaireId");
                if (vQnaireId !== undefined && vQnaireId !== "" && vQnaireId.length !== 0) {
                    this.showToast(component, 'SUCCESS:', 'success', 'Form has been created, now you can add questions in form by drag and drop field.');
                    component.set("v.QnaireId", vQnaireId);
                }
            } else {
                this.showToast(component, 'ERROR:', 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    
    getSingleQuestnnaireRecord: function(component, event, questnnaireRecordId) {
        component.set("v.Spinner", true);
        var action = component.get("c.getQnaireRecord");
        action.setParams({ qnaireId: questnnaireRecordId });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                var questnIre = res.getReturnValue();
                questnIre.Name = questnIre.Name + '_clone';
                component.set("v.objQuesnaire", questnIre);
            } else {
                this.showToast(component, 'ERROR:', 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    cloneTemplateHelper: function(component, event) {
        component.set("v.Spinner", true);
        var oQuesnaire = component.get("v.objQuesnaire");
        var action = component.get("c.saveQnaireCloneRecord");
        action.setParams({ oQnaire: oQuesnaire });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                component.set("v.QnaireId", res.getReturnValue());
                component.set("v.isCloneTemplate", false);
            } else {
                this.showToast(component, 'ERROR:', 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    searchTemplateRecord: function(component, event, page) {
        this.getQuestnnaireRecord(component, event, page);
    },
    showToast: function(component, title, type, message) {
        $A.createComponent(
            "c:FBToast", {
                "msgbody": message,
                "msgtype": type
            },
            function(newToast, status, errorMessage) {
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newToast);
                    component.set("v.body", body);
                } else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                        // Show offline error
                } else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
    },
    isLightningExperienceOrSalesforce1: function() {
        return ((typeof sforce != 'undefined') && sforce && (!!sforce.one));
    },
    onlyReturnString: function(component, event, valueWithHtmlTag) {
        var regex = /(<([^>]+)>)/ig
        return valueWithHtmlTag.replace(regex, "");
    },
    
    copyTextHelper: function(component, event, text) {
        // Create an hidden input
        var hiddenInput = document.createElement("input");
        // passed text into the input
        hiddenInput.setAttribute("value", text);
        // Append the hiddenInput input to the body
        document.body.appendChild(hiddenInput);
        // select the content
        hiddenInput.select();
        // Execute the copy command
        document.execCommand("copy");
        // Remove the input from the body after copy text
        document.body.removeChild(hiddenInput);

        this.showToast(component, 'SUCCESS', 'success', 'The Public URL has been copied to your clipboard');
    }
})