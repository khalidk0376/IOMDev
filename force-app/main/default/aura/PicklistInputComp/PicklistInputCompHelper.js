({
    showToast: function(component, type, message) {
        $A.createComponent("c:FBToast", { "msgbody": message, "msgtype": type }, function(newToast, status, errorMessage) {
            if (status === "SUCCESS") {
                var body = component.get("v.body");
                body.push(newToast);
                component.set("v.body", body);
            } else if (status === "INCOMPLETE") {
                console.log("No response from server or client is offline.")
            } else if (status === "ERROR") {
                console.log("Error: " + errorMessage);
            }
        });
    },
    createQuestion: function(component, event, vQnaireId, vSectionId, vDragId, colNumber, lstQuestionOptions) {
        var vQues = component.get("v.objCrteQues");
        
        if(vQues.Is_Allow_Branching__c){
            vQues.Is_MultiSelect__c = false;
        }

        vQues.Type__c = vDragId;
        vQues.Label__c = vQues.Label__c.trim();
        vQues.Label__c = this.removePTag(component, event, vQues.Label__c.trim());
        var vQnaireName = component.get("v.QnaireName");
        var action = component.get("c.createQuestnAndQuestnQnaireWithOptions"); //Calling Apex class controller 'createQueQnaire' method
        var vQuesOrder = component.get("v.questOrderNum");
        action.setParams({
            qnaireId: vQnaireId,
            qGroupId: vSectionId,
            question: vQues,
            qnaireName: vQnaireName,
            qOrder: vQuesOrder,
            colNumber: colNumber,
            questnOptns: JSON.stringify(lstQuestionOptions)
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                this.crudModalEvent(component, event, false, true);
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    helperSaveEditQues: function(component, event) {
        var vQnaireId = component.get("v.QnaireId");
        var vSectionId = component.get("v.QuestnGroupId");
        var vDesc = component.get("v.description");
        component.set("v.objeditQues.Label__c", vDesc);
        var vQues = component.get("v.objeditQues");
        // console.error(JSON.stringify(vQues));
        if(vQues.Is_Allow_Branching__c){
            vQues.Is_MultiSelect__c = false;
        }
        vQues.Label__c = vQues.Label__c.trim();
        vQues.Label__c = this.removePTag(component, event, vQues.Label__c.trim());
        var action = component.get("c.saveEditQuesRecord"); //Calling Apex class controller 'saveEditQuesRecord' method
        action.setParams({
            oQues: vQues,
            qnaireId: vQnaireId,
            sectionId: vSectionId,
            isUnderBranching: component.get("v.isUnderBranching")
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                this.crudModalEvent(component, event, false, true);
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    crudModalEvent: function(component, event, closeModel, isUpdateRecord) {
        var vDragId = component.get("v.modalHeader");
        var appEvent = $A.get("e.c:FBCloseEvent");
        // Optional: set some data for the event (also known as event shape)
        // A parameter’s name must match the name attribute
        // of one of the event’s <aura:attribute> tags
        appEvent.setParams({ "closeModel": closeModel, "isUpdateRecord": isUpdateRecord, "modelName": vDragId });
        appEvent.fire();
    },
    saveEditOption: function(component, event, name, alias) {
        var oQues = component.get("v.objeditQues");
        var action = component.get("c.saveQuestionEditOption");
        action.setParams({
            oQues: oQues,
            name: name,
            alias: alias,
            score: ''
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var data = res.getReturnValue();
                if (data.Question_Options__r != null) {
                    for (var i = 0; i < data.Question_Options__r.length; i++) {
                        data.Question_Options__r[i].isEditOption = false;
                    }
                }
                component.set("v.objeditQues", data);
                component.set("v.description", component.get("v.objeditQues.Label__c"));
                component.find("optnEditName").set("v.value", "");
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    removePTag: function(component, event, labelText) {
        var text = labelText.split("<p>");
        var myString = "";
        if (text !== undefined && text.length > 0) {
            for (var index = 0; index < text.length; index++) {
                myString = myString + text[index].replace("<p>", "");
                myString = myString.replace("</p>", "<br/>");
            }
            var strBr = myString.substr(myString.length - 5, myString.length);
            if (strBr === '<br/>') {
                return myString.slice(0, -5);
            }
            return myString;

        }
        return labelText;
    },
    onlyReturnString: function(valueWithHtmlTag) {
        var regex = /(<([^>]+)>)/ig
        let str = '';
        if(valueWithHtmlTag!=undefined){
            str = valueWithHtmlTag.replace(regex, "");
        }
        return str;
    },
    deleteOptionInEdit: function(component, event, optionId) {
        var oQues = component.get("v.objeditQues");
        var action = component.get("c.deleteQuestionOptionInEdit");
        action.setParams({
            oQues: oQues,
            qstnOptionId: optionId,
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var data = res.getReturnValue();
                if (data.Question_Options__r != null) {
                    for (var i = 0; i < data.Question_Options__r.length; i++) {
                        data.Question_Options__r[i].isEditOption = false;
                    }
                }
                component.set("v.objeditQues", data);
                component.set("v.description", component.get("v.objeditQues.Label__c"));
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    updateIndexOptionInEdit: function(component, lstOptions) {
        var action = component.get("c.sortEditOption");
        action.setParams({
            lstQOption: lstOptions
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                this.showToast(component, 'success', 'Successfully updated sort order.');
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    setSortOptions: function(lstOptions, component) {
        var that = this;
        lstOptions.sort(function(a, b) {
            if (a.index < b.index)
                return -1;
            if (a.index > b.index)
                return 1;
            return 0;
        });
        if (component.get("v.isEditQue") === false) {
            var lstMainOptin = [];
            for (var indexOption = 0; indexOption < lstOptions.length; indexOption++) {
                lstOptions[indexOption].Index__c = indexOption;
            }
            // console.error(JSON.stringify(lstOptions));
            this.showToast(component, 'INFO', 'Successfully updated sort order.');
            component.set("v.productList", lstOptions);
        } else {
            component.set("v.objeditQues.Question_Options__r", lstOptions);
            if (lstOptions) {
                var lstMainOptin = [];
                for (var indexOption = 0; indexOption < lstOptions.length > 0; indexOption++) {
                    var option = {
                        'sobjectType': 'Question_Option__c',
                        'Id': lstOptions[indexOption].Id,
                        'Index__c': indexOption
                    }
                    lstMainOptin.push(option);
                }
                that.updateIndexOptionInEdit(component, lstMainOptin);
            }


        }


    },
    refreshSortOptions: function(component) {
        $('#sortableoptions').sortable("refresh");
    },
    doSortOptions: function(component) {
        try {
            var that = this;
            $('#sortableoptions').sortable({
                scroll: false,
                cancel: ".nosort",
                cursor: "move",
                axis: "y",
                containment: "parent",
                start: function(event, ui) {
                    // creates a temporary attribute on the element with the old index
                    ui.item.attr('data-previndex', ui.item.index());
                    ui.item.attr('data-id', ui.item.attr('id'));
                },
                update: function(event, ui) {
                    if (component.get("v.isEditQue") === false) {
                        var lstOptions = component.get("v.productList");
                    } else {
                        var lstOptions = component.get("v.objeditQues.Question_Options__r");
                    }
                    var newIndex = ui.item.index();
                    var oldIndex = parseInt(ui.item.attr('data-previndex'), 10);
                    var upQOrder = newIndex;

                    if (oldIndex < newIndex) {
                        //down to up sorting code..
                        // console.log('downtoup' + oldIndex + '-----' + newIndex);
                        lstOptions[oldIndex].index = newIndex;
                        lstOptions[oldIndex].isEditOption = true;

                        for (var i = upQOrder; i >= oldIndex; i--) {
                            if (lstOptions[i].isEditOption === false) {
                                upQOrder--;
                                lstOptions[i].index = upQOrder;
                            }
                            if (i === oldIndex) {
                                lstOptions[oldIndex].isEditOption = false;
                                that.setSortOptions(lstOptions, component);
                            }
                        }

                    } else {
                        //up to down sorting code..
                        // console.log('uptodown' + oldIndex + '-----' + newIndex);
                        lstOptions[oldIndex].index = newIndex;
                        lstOptions[oldIndex].isEditOption = true;
                        for (var j = upQOrder; j <= oldIndex; j++) {
                            if (lstOptions[j].isEditOption === false) {
                                upQOrder++;
                                lstOptions[j].index = upQOrder;
                            }
                            if (j === oldIndex) {
                                lstOptions[oldIndex].isEditOption = false;
                                that.setSortOptions(lstOptions, component);
                            }
                        }

                    }
                }
            });
        } catch (e) {
            console.error(e.message());
        }

    },
    updateOptionInEdit: function(component, event, oQustnOptions) {
        var oQues = component.get("v.objeditQues");
        var action = component.get("c.editQuestionOptionInEdit");
        action.setParams({
            oQuesOption: oQustnOptions,
            oQues: oQues
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var data = res.getReturnValue();
                if (data.Question_Options__r != null) {
                    for (var i = 0; i < data.Question_Options__r.length; i++) {
                        data.Question_Options__r[i].isEditOption = false;
                    }
                }
                component.set("v.objeditQues", data);
                component.set("v.description", component.get("v.objeditQues.Label__c"));
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    }
})