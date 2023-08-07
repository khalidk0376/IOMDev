({
    openEditor: function(component) {
        window.setTimeout($A.getCallback(function() {
            var fieldTypeLabel = component.find("gkn-field-label");
            fieldTypeLabel.find(function(item) {
                $A.util.addClass(item, 'gkn-truncate');
                $A.util.removeClass(item, 'gkn-field-label');
            });
            $A.util.removeClass(component.find('box3'), 'slds-hide');
            $A.util.addClass(component.find('box3'), 'slds-show');
        }, 200));
        component.find('box1').set("v.size", 1);
        component.find('box2').set("v.size", 7);
        component.find('box3').set("v.size", 4);
    },
    closeEditor: function(component) {
        $A.util.addClass(component.find('box3'), 'slds-hide');
        $A.util.removeClass(component.find('box3'), 'slds-show');
        if (component.find('articleOne').get('v.iconName') == 'utility:forward')
            component.find('articleOne').set('v.iconName', 'utility:back');
        component.find('box1').set("v.size", 2);
        component.find('box2').set("v.size", 10);
        component.find('box3').set("v.size", 2);
        window.setTimeout($A.getCallback(function() {
            var fieldTypeLabel = component.find("gkn-field-label");
            fieldTypeLabel.find(function(item) {
                $A.util.removeClass(item, 'gkn-truncate');
                $A.util.addClass(item, 'gkn-field-label');
            });
        }, 200));
    },
    callScriptsLoaded: function(component, event) {
        var self = this;
        var qqid = '',
            qid = '',
            isRecive = false,
            inputField = 'No';
        var lstQuestn = [];
        var lstQuestion_Questionnaires = [];

        $(".fields-type").draggable({
            helper: 'clone',
            revert: "invalid",
            tolerance: "fit",
            connectToSortable: '#sortableArea1,#sortableArea2,#sortableArea3',
            zIndex: 10000,
            start: function(event, ui) {
                $(ui.helper).addClass("ui-draggable-helper");
                $(ui.helper).width($('.fields-type').width());
                if ($(".field-type-box").hasClass("slds-is-fixed")) {} else {
                    //$(ui.helper).css('margin-top', '-180px');
                    $(ui.helper).css('margin-top', '0px');
                }
            }
        });

        //Start sorting code
        $("#sortableArea1,#sortableArea2,#sortableArea3").sortable({
            placeholder: "ui-state-highlight",
            scroll: false,
            connectWith: ".sortableArea",
            cursor: "move",
            start: function(e, ui) {
                // creates a temporary attribute on the element with the old index
                ui.item.attr('data-previndex', ui.item.index());
                ui.item.attr('data-id', ui.item.parent().attr('id'));
                isRecive = false;
                inputField = 'No'
            },
            update: function(e, ui) {
                //alert('update: '+ui.item.index());
                //isRecive=false;
            },
            receive: function(event, ui) {
                if (ui.sender[0].id == 'sortableArea1' || ui.sender[0].id == 'sortableArea2' || ui.sender[0].id == 'sortableArea3') {
                    isRecive == false;
                } else {
                    isRecive = true;
                    inputField = ui.sender[0].id;
                    component.set("v.dropColNumber", $(this).parent().attr("id"));
                    component.set("v.dragId", ui.sender[0].id);
                    component.set("v.modalHeader", ui.sender[0].id);
                    component.set("v.isEditQue", false);
                }
            },
            stop: function(e, ui) {
                if (isRecive == true) {
                    //alert(ui.item.index());
                    component.set("v.quesDropOrderNumber", ui.item.index() + '');
                    self.openQuestionEditor(component, inputField);
                    self.openEditor(component);
                    ui.item.remove();
                } else {
                    try {
                        // gets the new and old index then removes the temporary attribute
                        var newIndex = ui.item.index();
                        var oldIndex = parseInt(ui.item.attr('data-previndex'), 10);
                        var colNum = ui.item.parent().attr("id").replace('sortableArea', '');
                        component.set("v.Spinner", true);
                        lstQuestn = [];
                        lstQuestion_Questionnaires = [];

                        qqid = ui.item.data('qqid');
                        qid = ui.item.data('qid');

                        if (ui.item.parent().attr("id") != ui.item.attr('data-id')) {
                            self.updateColumn(component, qqid, qid, 'col' + colNum, newIndex + '', event);
                        } else if (newIndex == oldIndex) {
                            component.set("v.Spinner", false);
                        } else {
                            lstQuestn = component.get("v.lstQQuesnnaire." + 'col' + colNum + "Questions.lstQuestn");
                            if (oldIndex > newIndex) {

                                //down to up sorting code..
                                var Obj_Question_QuestionnairesDown = {
                                    sobjectType: 'Question_Questionnaire__c',
                                    Id: lstQuestn[oldIndex].Question_Questionnaires__r[0].Id,
                                    Question_Order__c: newIndex
                                };
                                var qOrder = newIndex;
                                lstQuestion_Questionnaires.push(Obj_Question_QuestionnairesDown);
                                //checking this question has branching

                                if (lstQuestn[oldIndex].Question_Questionnaires__r[0].branchingQuestnQuetnnaire !== undefined) {
                                    var branchingQuestnQuetnnaireOldIndex = lstQuestn[oldIndex].Question_Questionnaires__r[0].branchingQuestnQuetnnaire;
                                    for (var indexSortbranchingQuestnQuetnnaireOld = 0; indexSortbranchingQuestnQuetnnaireOld < branchingQuestnQuetnnaireOldIndex.length; indexSortbranchingQuestnQuetnnaireOld++) {

                                        qOrder = qOrder + 1;
                                        var Obj_Question_QuestionnairesOldNew = {
                                            sobjectType: 'Question_Questionnaire__c',
                                            Id: branchingQuestnQuetnnaireOldIndex[indexSortbranchingQuestnQuetnnaireOld].Id,
                                            Question_Order__c: qOrder
                                        };
                                        lstQuestion_Questionnaires.push(Obj_Question_QuestionnairesOldNew);
                                    }
                                }

                                for (var varQuestn = newIndex; varQuestn < lstQuestn.length; varQuestn++) {

                                    if (lstQuestn[oldIndex].Question_Questionnaires__r[0].Id !== lstQuestn[varQuestn].Question_Questionnaires__r[0].Id) {
                                        qOrder = qOrder + 1;
                                        var Obj_Question_QuestionnairesNew = {
                                            sobjectType: 'Question_Questionnaire__c',
                                            Id: lstQuestn[varQuestn].Question_Questionnaires__r[0].Id,
                                            Question_Order__c: qOrder
                                        };

                                        lstQuestion_Questionnaires.push(Obj_Question_QuestionnairesNew);
                                        var branchingQuestnQuetnnaire = lstQuestn[varQuestn].Question_Questionnaires__r[0].branchingQuestnQuetnnaire;
                                        if (branchingQuestnQuetnnaire !== undefined && branchingQuestnQuetnnaire.length > 0) {
                                            for (var indexSortbranchingQuestnQuetnnaire = 0; indexSortbranchingQuestnQuetnnaire < branchingQuestnQuetnnaire.length; indexSortbranchingQuestnQuetnnaire++) {
                                                qOrder = qOrder + 1;
                                                var Obj_QQuestionnairesOld = {
                                                    sobjectType: 'Question_Questionnaire__c',
                                                    Id: branchingQuestnQuetnnaire[indexSortbranchingQuestnQuetnnaire].Id,
                                                    Question_Order__c: qOrder
                                                };
                                                lstQuestion_Questionnaires.push(Obj_QQuestionnairesOld);
                                            }
                                        }
                                    }
                                }
                            } else {
                                //up to down sorting code..
                                var upQOrder = oldIndex;
                                for (var varUpQuestn = upQOrder; varUpQuestn < lstQuestn.length; varUpQuestn++) {
                                    if (lstQuestn[oldIndex].Question_Questionnaires__r[0].Id !== lstQuestn[varUpQuestn].Question_Questionnaires__r[0].Id) {

                                        var Obj_Question_QuestionnairesUp = {
                                            sobjectType: 'Question_Questionnaire__c',
                                            Id: lstQuestn[varUpQuestn].Question_Questionnaires__r[0].Id,
                                            Question_Order__c: upQOrder
                                        };
                                        lstQuestion_Questionnaires.push(Obj_Question_QuestionnairesUp);
                                        upQOrder++;
                                        var branchingQuestnQuetnnaireUpAndDown = lstQuestn[varUpQuestn].Question_Questionnaires__r[0].branchingQuestnQuetnnaire;
                                        if (branchingQuestnQuetnnaireUpAndDown !== undefined && branchingQuestnQuetnnaireUpAndDown.length > 0) {
                                            for (var indexSortbranchingQQnnaire = 0; indexSortbranchingQQnnaire < branchingQuestnQuetnnaireUpAndDown.length; indexSortbranchingQQnnaire++) {

                                                var Obj_Question_QuestionnairesUpDown = {
                                                    sobjectType: 'Question_Questionnaire__c',
                                                    Id: branchingQuestnQuetnnaireUpAndDown[indexSortbranchingQQnnaire].Id,
                                                    Question_Order__c: upQOrder
                                                };
                                                lstQuestion_Questionnaires.push(Obj_Question_QuestionnairesUpDown);
                                                upQOrder++;
                                            }
                                        }
                                    }

                                    if (lstQuestn[varUpQuestn].Question_Questionnaires__r[0].Id === lstQuestn[newIndex].Question_Questionnaires__r[0].Id) {

                                        var Obj_Question_QuestionnairesUpDownLast = {
                                            sobjectType: 'Question_Questionnaire__c',
                                            Id: lstQuestn[oldIndex].Question_Questionnaires__r[0].Id,
                                            Question_Order__c: upQOrder
                                        };
                                        lstQuestion_Questionnaires.push(Obj_Question_QuestionnairesUpDownLast);
                                        upQOrder++;
                                        var mainBranchingQQnnaire = lstQuestn[oldIndex].Question_Questionnaires__r[0].branchingQuestnQuetnnaire;
                                        if (mainBranchingQQnnaire !== undefined && mainBranchingQQnnaire.length > 0) {
                                            for (var pointSortbranchingQQnnaire = 0; pointSortbranchingQQnnaire < mainBranchingQQnnaire.length; pointSortbranchingQQnnaire++) {
                                                var Obj_Question_QuestionnairesChild = {
                                                    sobjectType: 'Question_Questionnaire__c',
                                                    Id: mainBranchingQQnnaire[pointSortbranchingQQnnaire].Id,
                                                    Question_Order__c: upQOrder
                                                };
                                                lstQuestion_Questionnaires.push(Obj_Question_QuestionnairesChild);
                                                upQOrder++;
                                            }
                                        }
                                    }
                                }
                            }
                            if (lstQuestion_Questionnaires !== undefined && lstQuestion_Questionnaires !== null && lstQuestion_Questionnaires.length > 0) {
                                self.shortColumn(component, lstQuestion_Questionnaires, lstQuestn, oldIndex, newIndex, colNum);
                            }
                        }
                    } catch (e) {
                        console.log(e);
                    }
                }
            }
        });
        $("#sortableArea1,#sortableArea2,#sortableArea3").disableSelection();
        //End sorting code
        if (self.isLightningExperienceOrSalesforce1()) {
            $(".field-type-container").height($(window).height() - 177);
            $(".slds-tabs_default__content").height($(window).height() - 177);
        } else {
            $(".field-type-container").height($(window).height() - 200);
            $(".slds-tabs_default__content").height($(window).height() - 229);
        }


        var win_height = $(window).height();
        if (!self.isLightningExperienceOrSalesforce1()) {
            win_height = win_height - 80;
            //component.set("v.questionBuilderleftbox", 'height:590px');
        } else {
            win_height = win_height + 17;
        }
        /*window.onscroll = function() {
            if (component.find('fields_type_box_1') == undefined) {
                return;
            }

            var _top = 35;
            if (self.isLightningExperienceOrSalesforce1()) {
                _top = 9;
            }
            if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
                var questnLfPanel = component.get("v.questnLfPanel");
                if (!questnLfPanel) {
                    var LftWidth = component.find('fields_type_box_1').getElement().offsetWidth;
                    var styleVal = '';                    
                    styleVal = styleVal + ' height :' + (win_height - 180) + 'px;';                    
                    styleVal = styleVal + ' transform: translate3d(0px, -29px, 0px);background:#fafaf9;z-index:100;';                    
                    component.set("v.questnLfPanelStyleValue", styleVal);
                    component.find("fields_type_box_1").getElement().setAttribute("style",styleVal);
                    component.set("v.questnLfPanel", " slds-is-fixed");                    
                }
            } else {
                var questnLfPanelVal = component.get("v.questnLfPanel");
                if (questnLfPanelVal === " slds-is-fixed") {
                    component.set("v.questnLfPanel", "");
                    component.set("v.questnLfPanelStyleValue", "background-color:#fafaf9;transform: translate3d(0px, 0px, 0px);");
                    if (self.isLightningExperienceOrSalesforce1()) {
                        component.set("v.questionBuilderleftbox", 'height :' + (win_height - 160) + 'px;');
                    } else {
                        component.set("v.questionBuilderleftbox", 'height :' + (win_height - 117) + 'px;');
                    }
                    component.find("fields_container").getElement().setAttribute("style",component.get("v.questionBuilderleftbox"));
                }
            }
        }*/
    },

    openQuestionEditor: function(component, fieldType) {
        if (fieldType === "Date") {
            component.set("v.isShowDateModal", true);
        } else if (fieldType === "URL") {
            component.set("v.isShowURLModal", true);
        } else if (fieldType === "Header/Footer") {
            component.set("v.isShowHeaderModal", true);
        } else if (fieldType === "DateTime") {
            component.set("v.isShowDatetimeModal", true);
        } else if (fieldType === "Time") {
            component.set("v.isShowDatetimeModal", true);
        } else if (fieldType === "TextPlain") {
            component.set("v.isShowTextPlainModal", true);
        } else if (fieldType === "RichText") {
            component.set("v.isShowRichTextModal", true);
        } else if (fieldType === "Address") {
            component.set("v.isShowAddressModal", true);
        } else if (fieldType === "Email") {
            component.set("v.isShowEmailModal", true);
        } else if (fieldType === "Phone") {
            component.set("v.isShowPhoneModal", true);
        } else if (fieldType === "Information") {
            component.set("v.isShowInformationModal", true);
        } else if (fieldType === "Checkbox") {
            component.set("v.isShowCheckboxModal", true);
        } else if (fieldType === "Radio") {
            component.set("v.isShowRadioModal", true);
        } else if (fieldType === "Picklist") {
            component.set("v.isShowPicklistModal", true);
        } else if (fieldType === "Number") {
            component.set("v.isShowNumberAndCurrencyModal", true);
        } else if (fieldType === "Lookup") {
            component.set("v.isShowLookupModal", true);
        } else if (fieldType === "Signature") {
            component.set("v.isShowSignatureModal", true);
        } else if (fieldType === "Switch") {
            component.set("v.isShowSwitchModal", true);
        } else if (fieldType === "Slider") {
            component.set("v.isShowSliderModal", true);
        } else if (fieldType === "GPS Location") {
            component.set("v.isShowGPSLocationModal", true);
        } else if (fieldType === "Media") {
            component.set("v.isShowMediaModal", true);
        } else {
            self.showToast(component, "Error!", 'error', '"' + fieldType + '" field type not supported!');
        }
    },

    shortColumn: function(component, lstQuestion_Questionnaires, lstQuestn, oldIndex, newIndex, colNum) {
        var self = this;
        var action = component.get("c.setQuestnQnniareOrder");
        action.setParams({
            lstOrderOfQQniare: lstQuestion_Questionnaires
        });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            console.log('266::::' + new Date());
            var state = res.getState();
            if (state === "SUCCESS") {
                self.showToast(component, "Success ", 'success', 'Successfully re-order question');
                var oldQues = lstQuestn[oldIndex];
                lstQuestn.splice(oldIndex, 1);
                lstQuestn.splice(newIndex, 0, oldQues);
                component.set("v.lstQQuesnnaire." + 'col' + colNum + "Questions.lstQuestn", lstQuestn);
                //component.set("v.lstQQuesnnaire.lstQuestn",lstQuestn);

            } else {
                self.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.getCallback(function() {
            $A.enqueueAction(action);
        })();
    },
    updateColumn: function(component, questionaryId, questionId, colNum, dropedIndex, event) {
        //console.log('326::'+new Date());
        var vQnaireId = component.get("v.QnaireId");
        var vSectionId = component.get("v.selTabId");
        var action = component.get("c.updateColumn"); //Calling Apex class controller 'getTemplateRecrod' method
        action.setParams({
            vQnaireId: vQnaireId,
            questionaryId: questionaryId,
            questionId: questionId,
            colNum: colNum,
            selectedSectionId: vSectionId,
            newIndex: dropedIndex
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                this.showToast(component, "Success", 'success', 'Column changed!');
                this.getAllQuestion(component, event, vQnaireId, vSectionId);
            } else {
                this.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.getCallback(function() {
            $A.enqueueAction(action);
        })();
    },

    getQuestionnaireRecord: function(component, event) {
        var self = this;
        self.getQuesCategory(component, event);
        window.setTimeout($A.getCallback(function() {
            self.getTempRecord(component, event, component.get("v.QnaireId"));
        }, 2500));
    },
    getQuesCategory: function(component, event) {
        var action = component.get("c.getQueCategory");
        var self = this;
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                component.set("v.lstQuesCategory", res.getReturnValue());
            } else {
                self.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    getTempRecord: function(component, event, vQnaireId) {
        var action = component.get("c.getTemplateRecord");
        action.setParams({
            qnaireId: vQnaireId
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var obj = res.getReturnValue();
                component.set("v.totalQuest", obj.totalQuest);

                if (obj.questionnaire.is_Published__c === true) {
                    var appEvent = $A.get("e.c:FBActiveHeaderEvent");
                    appEvent.setParams({ "compName": "search" });
                    appEvent.fire();
                } else {
                    component.set("v.objQnaire", obj.questionnaire);
                    component.set("v.QnaireName", component.get("v.objQnaire.Name"));
                }
                this.getQuesGroupRecord(component, event, vQnaireId, "");
            } else {
                this.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    getQuesGroupRecord: function(component, event, vQnaireId, type) {
        component.set("v.Spinner", true);
        var action = component.get("c.getAllQuestnGrpNameForQuesnnaire"); //Calling Apex class controller 'getAllQuestnGrpNameForQuesnnaire' method
        action.setParams({
            sQnaireId: vQnaireId
        });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                component.set("v.lstQuesGroup", res.getReturnValue());
                var sectionOptions = [];
                var sectionOptions2 = [];
                var lstQGroup = component.get("v.lstQuesGroup");
                for (var i = 0; i < lstQGroup.length; i++) {
                    if (sectionOptions2.indexOf(lstQGroup[i].Question_Group__c) <= -1) {
                        sectionOptions2.push(lstQGroup[i].Question_Group__c);
                        if(lstQGroup[i].Question_Group__r){
                            sectionOptions.push({ label: lstQGroup[i].Question_Group__r.Name, value: lstQGroup[i].Question_Group__c });
                        }
                    }
                }
                component.set("v.sectionOptions", sectionOptions);

                if (type === "delete section") {
                    component.set("v.selTabId", lstQGroup[0].Question_Group__c);
                    this.getAllQuestion(component, event, vQnaireId, component.get("v.selTabId"));
                } else if (type === "change") {
                    this.getAllQuestion(component, event, vQnaireId, component.get("v.selTabId"));
                } else {
                    component.set("v.selTabId", lstQGroup[0].Question_Group__c);
                    this.getAllQuestion(component, event, vQnaireId, component.get("v.selTabId"));
                }

            } else {
                this.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    getAllQuestion: function(component, event, vQnaireId, vSectionId) {
        var action = component.get("c.getQuestnsForQuesGroup"); //Calling Apex class controller 'getQuestnForQuesGroup' method
        action.setParams({
            qnaireId: vQnaireId,
            sectionId: vSectionId,
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                //component.set('v.lstQQuesnnaire',res.getReturnValue());
                this.branchingOnCol(component, event, res.getReturnValue(), vSectionId);
            } else {
                this.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    branchingOnCol: function(component, event, lstQuestion, vSectionId) {
        var that = this;
        component.set("v.Spinner", true);
        var action = component.get("c.getBranchingQuestn");
        action.setParams({
            sectionId: vSectionId,
        });

        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                try {
                    /*  Add:  Changes Here for Long
                        var lstQDynLogic = res.getReturnValue();
                        component.set("v.lstQDynLogicMain", lstQDynLogic);

                        if(lstQuestion.col1Questions.lstQuestn.length>0){
                            this.setQuestionBranching(component,event,lstQuestion,vSectionId,'col1');
                        }
                        if(lstQuestion.col2Questions.lstQuestn.length>0){
                            this.setQuestionBranching(component,event,lstQuestion,vSectionId,'col2');
                        }                                         
                        if(lstQuestion.col1Questions.lstQuestn.length==0){
                            component.set('v.lstQQuesnnaire',lstQuestion);    
                        }
                        */
                    // Add:  Changes Here for Long
                    new Promise($A.getCallback(function(resolve, reject) {
                        var resLstQDynLogic = res.getReturnValue();
                        try {
                            resLstQDynLogic.map(function(o) {
                                o.Name__c = o.Name_Long__c;
                                o.Name = o.Name_Long__c;
                            });
                            resolve(resLstQDynLogic);
                        } catch (e) {
                            resolve(resLstQDynLogic);
                        }
                    })).then($A.getCallback(function(lstQDynLogic) {
                        component.set("v.lstQDynLogicMain", lstQDynLogic);

                        if (lstQuestion.col1Questions.lstQuestn.length > 0) {
                            that.setQuestionBranching(component, event, lstQuestion, vSectionId, 'col1');
                        }
                        if (lstQuestion.col2Questions.lstQuestn.length > 0) {
                            that.setQuestionBranching(component, event, lstQuestion, vSectionId, 'col2');
                        }
                        
                        if (lstQuestion.col1Questions.lstQuestn.length == 0) {
                            component.set('v.lstQQuesnnaire', lstQuestion);
                        }
                    }));

                } catch (e) {
                    console.log(e);
                }
            } else {
                this.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    setQuestionBranching: function(component, event, lstQuestion, vSectionId, col) {

        var question = [];
        if (col == 'col1') {
            question = lstQuestion.col1Questions.lstQuestn;
        } else if (col == 'col2') {
            question = lstQuestion.col2Questions.lstQuestn;
        }

        var lst_Question_Questionnaires = component.get("v.lst_Question_Questionnaires");
        var Obj_Question_Questionnaires = component.get("v.Obj_Question_Questionnaires");
        var isRemove = false;
        lst_Question_Questionnaires = [];
        var lstQDynLogic = component.get("v.lstQDynLogicMain");
        if (lstQDynLogic !== undefined && lstQDynLogic !== null && lstQDynLogic.length > 0) {
            for (var indexQDynLogic = 0; indexQDynLogic < lstQDynLogic.length; indexQDynLogic++) {
                for (var indexQue = 0; indexQue < question.length; indexQue++) {
                    var questionQuestnnnaire = question[indexQue].Question_Questionnaires__r;
                    question[indexQue].Question_Questionnaires__r[0].branchingQuestnQuetnnaire = [];
                    for (var indeQQnnaire = 0; indeQQnnaire < questionQuestnnnaire.length; indeQQnnaire++) {
                        if (lstQDynLogic[indexQDynLogic].Show_Question_Questionnaire__c === questionQuestnnnaire[indeQQnnaire].Id) {
                            isRemove = true;
                            Obj_Question_Questionnaires = questionQuestnnnaire[indeQQnnaire];
                            if (question[indexQue].Question_Options__r !== undefined) {
                                Obj_Question_Questionnaires.QuestionOptions = question[indexQue].Question_Options__r;
                            } else {
                                Obj_Question_Questionnaires.QuestionOptions = [];
                            }
                            Obj_Question_Questionnaires.isShowQuestion = true;
                            Obj_Question_Questionnaires.MainQuestionId = lstQDynLogic[indexQDynLogic].Question_Questionnaire__r.Question__c;
                            question.splice(indexQue, 1);
                        }
                    }
                }
                lst_Question_Questionnaires.push(Obj_Question_Questionnaires);

            }
            var lstQuestionsId = [];
            if (isRemove === true) {
                for (var indexQueResult = 0; indexQueResult < question.length; indexQueResult++) {
                    var questnId = question[indexQueResult].Id;
                    for (var indexQQnnaire = 0; indexQQnnaire < lst_Question_Questionnaires.length; indexQQnnaire++) {
                        if (lst_Question_Questionnaires[indexQQnnaire].MainQuestionId === questnId) {
                            if (question[indexQueResult].Question_Questionnaires__r[0].branchingQuestnQuetnnaire !== undefined) {
                                var branchingQuestionQuestnnnaire = question[indexQueResult].Question_Questionnaires__r[0].branchingQuestnQuetnnaire;

                                if (lstQuestionsId.indexOf(lst_Question_Questionnaires[indexQQnnaire].Id) === -1) {
                                    branchingQuestionQuestnnnaire.push(lst_Question_Questionnaires[indexQQnnaire]);
                                }
                                lstQuestionsId.push(lst_Question_Questionnaires[indexQQnnaire].Id);
                                question[indexQueResult].Question_Questionnaires__r[0].branchingQuestnQuetnnaire = branchingQuestionQuestnnnaire;
                            } else {
                                var branchingQuestionQuestnnnaireNew = [];
                                if (lstQuestionsId.indexOf(lst_Question_Questionnaires[indexQQnnaire].Id) === -1) {
                                    branchingQuestionQuestnnnaireNew.push(lst_Question_Questionnaires[indexQQnnaire]);
                                }
                                lstQuestionsId.push(lst_Question_Questionnaires[indexQQnnaire].Id);
                                question[indexQueResult].Question_Questionnaires__r[0].branchingQuestnQuetnnaire = branchingQuestionQuestnnnaireNew;
                            }
                        }
                    }
                }
            }
        }

        var doneReuslt = false;
        while (!doneReuslt) {
            doneReuslt = true;
            for (var point = 1; point < question.length; point += 1) {
                if (question[point - 1].Question_Questionnaires__r[0].Question_Order__c > question[point].Question_Questionnaires__r[0].Question_Order__c) {
                    doneReuslt = false;
                    var tmpQuestn = question[point - 1];
                    question[point - 1] = question[point];
                    question[point] = tmpQuestn;
                }
            }
        }

        if (col == 'col1') {
            lstQuestion.col1Questions.lstQuestn = question;
        } else if (col == 'col2') {
            lstQuestion.col2Questions.lstQuestn = question;
        }
        component.set('v.lstQQuesnnaire', lstQuestion);
    },
    createQuestion: function(component, event, vQnaireId, vSectionId, vDragId, colNumber) {
        component.set("v.Spinner", true);
        var vQues = component.get("v.objCrteQues");
        vQues.Type__c = vDragId;
        var vQnaireName = component.get("v.QnaireName");
        var action = component.get("c.createQuestnAndQuestnQnaire"); //Calling Apex class controller 'createQueQnaire' method
        var vQuesOrder = '2';
        action.setParams({
            qnaireId: vQnaireId,
            qGroupId: vSectionId,
            question: vQues,
            qnaireName: vQnaireName,
            qOrder: vQuesOrder,
            colNumber: colNumber
        });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                component.set("v.isShowModal", false);
                this.getAllQuestion(component, event, vQnaireId, vSectionId);
                this.removeQuesValue(component, event);
            } else {
                this.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);

    },
    removeQuesValue: function(component, event) {
        var data = {
            'sobjectType': 'Question__c',
            'Label__c': '',
            'Type__c': '',
            'Help_Text__c': '',
            'Allow_Comment__c': false,
            'Allow_Attachments__c': false,
            'Category__c': '',
            'Required__c': false
        }

        component.set("v.objCrteQues", data);
        component.set("v.description", "");
    },
    deleteQuestion: function(component, event, vQuestnQuestnnaireId) {
        component.set("v.Spinner", true);
        var vQnaireId = component.get("v.QnaireId");
        var vSectionId = component.get("v.selTabId");
        var action = component.get("c.delQuestion"); //Calling Apex class controller 'delQuestion' method
        action.setParams({
            questnQuestnnaireId: vQuestnQuestnnaireId
        });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                this.getAllQuestion(component, event, vQnaireId, vSectionId);

            } else {
                this.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    editQuestion: function(component, event, vQuesId) {
        component.set("v.Spinner", true);
        this.openEditor(component);
        var action = component.get("c.getQuesDetail"); //Calling Apex class controller 'getQuesDetail' method
        action.setParams({
            quesId: vQuesId
        });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                var data = res.getReturnValue();
                if (data.Question_Options__r != null) {
                    for (var i = 0; i < data.Question_Options__r.length; i++) {
                        data.Question_Options__r[i].isEditOption = false;
                        data.Question_Options__r[i].Name = data.Question_Options__r[i].Name_Long__c;
                        data.Question_Options__r[i].Name__c = data.Question_Options__r[i].Name_Long__c;
                    }
                }
                component.set("v.objQues", data);
                component.set("v.description", component.get("v.objQues.Label__c"));
                component.set("v.isEditQue", true);
                component.set("v.modalHeader", component.get("v.objQues.Type__c"));
                if (component.get("v.objQues.Type__c") === "Date") {
                    component.set("v.isShowDateModal", true);
                } else if (component.get("v.objQues.Type__c") === "URL") {
                    component.set("v.isShowURLModal", true);
                } else if (component.get("v.objQues.Type__c") === "DateTime") {
                    component.set("v.isShowDatetimeModal", true);
                } else if (component.get("v.objQues.Type__c") === "TextPlain") {
                    component.set("v.isShowTextPlainModal", true);
                } else if (component.get("v.objQues.Type__c") === "RichText") {
                    component.set("v.isShowRichTextModal", true);
                } else if (component.get("v.objQues.Type__c") === "Address") {
                    component.set("v.isShowAddressModal", true);
                } else if (component.get("v.objQues.Type__c") === "Email") {
                    component.set("v.isShowEmailModal", true);
                } else if (component.get("v.objQues.Type__c") === "Phone") {
                    component.set("v.isShowPhoneModal", true);
                } else if (component.get("v.objQues.Type__c") === "Information") {
                    component.set("v.isShowInformationModal", true);
                } else if (component.get("v.objQues.Type__c") === "Checkbox") {
                    component.set("v.isShowCheckboxModal", true);
                } else if (component.get("v.objQues.Type__c") === "Radio") {
                    component.set("v.isShowRadioModal", true);
                } else if (component.get("v.objQues.Type__c") === "Number") {
                    component.set("v.isShowNumberAndCurrencyModal", true);
                } else if (component.get("v.objQues.Type__c") === "Picklist") {
                    component.set("v.isShowPicklistModal", true);
                } else if (component.get("v.objQues.Type__c") === "Lookup") {
                    component.set("v.isShowLookupModal", true);
                } else if (component.get("v.objQues.Type__c") === "Switch") {
                    component.set("v.isShowSwitchModal", true);
                } else if (component.get("v.objQues.Type__c") === "Slider") {
                    component.set("v.isShowSliderModal", true);
                } else if (component.get("v.objQues.Type__c") === "GPS Location") {
                    component.set("v.isShowGPSLocationModal", true);
                } else if (component.get("v.objQues.Type__c") === "Media") {
                    component.set("v.isShowMediaModal", true);
                } else if (component.get("v.objQues.Type__c") === "Signature") {
                    component.set("v.isShowSignatureModal", true);
                } else if (component.get("v.objQues.Type__c") === "Header/Footer") {
                    component.set("v.isShowHeaderModal", true);
                } else {
                    component.set("v.isShowModal", true);
                }

            } else {
                this.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    helperSaveEditQues: function(component, event) {
        component.set("v.Spinner", true);
        var vQnaireId = component.get("v.QnaireId");
        var vSectionId = component.get("v.selTabId");
        var vDesc = component.get("v.description");
        component.set("v.objQues.Label__c", vDesc);
        var vQues = component.get("v.objQues");
        var action = component.get("c.saveEditQuesRecord"); //Calling Apex class controller 'saveEditQuesRecord' method
        action.setParams({
            oQues: vQues
        });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                this.getAllQuestion(component, event, vQnaireId, vSectionId);
                component.set("v.isShowModal", false);
            } else {
                this.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    updateSectionHelper: function(component, event, sectionName, questionaryId, columnNo) {
        component.set("v.Spinner", true);
        var action = component.get("c.updateSection");
        action.setParams({
            sectionName: sectionName,
            sectionId: component.get("v.selTabId"),
            questionaryId: questionaryId,
            columnNumber: columnNo
        });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                this.closeEditor(component);
                component.set("v.isShowSection", false);
                component.set("v.isShowSectionEditForm", false);
                component.set("v.lstQQuesnnaire.col1Questions.groupName", sectionName);
                component.set("v.lstQQuesnnaire.col1Questions.sectionColNumber", columnNo);
                this.getAllQuestion(component, event, questionaryId, component.get("v.selTabId"));
            } else {
                this.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    saveSectionHelper: function(component, event, sectionName, questionaryId, columnNo) {
        component.set("v.Spinner", true);
        var action = component.get("c.createSection");
        action.setParams({
            sectionName: sectionName,
            questionaryId: questionaryId,
            columnNumber: columnNo
        });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                this.closeEditor(component);
                var response = res.getReturnValue();
                component.set("v.isShowSection", false);
                component.set("v.isShowSectionEditForm", false);
                var secList = component.get("v.sectionOptions");
                secList.push({ label: sectionName, value: response.Id });
                component.set("v.sectionOptions", secList);
                //component.set("v.selTabId", response.Id);
                //this.getQuesGroupRecord(component, event, questionaryId, "change");
            } else {
                this.showToast(component, "Error: ", 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
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
    onlyReturnString: function(component, event, valueWithHtmlTag) {
        var regex = /(<([^>]+)>)/ig
        return valueWithHtmlTag.replace(regex, "");
    },
    isLightningExperienceOrSalesforce1: function() {
        return ((typeof sforce != 'undefined') && sforce && (!!sforce.one));
    }
})