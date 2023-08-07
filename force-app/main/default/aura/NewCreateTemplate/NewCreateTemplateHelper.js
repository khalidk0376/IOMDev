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
    callScriptsLoaded: function(component) {
        let self = this;
        let isRecive = false;
        let inputField = 'No';        
        
        $(".fields-type").draggable({
            helper: 'clone',
            revert: "invalid",
            tolerance: "fit",
            connectToSortable: '#sortableArea1,#sortableArea2',
            zIndex: 10000,
            start: function(e, ui) {
                $(ui.helper).addClass("ui-draggable-helper");
                $(ui.helper).width($('.fields-type').width());
                if ($(".field-type-box").hasClass("slds-is-fixed")) {} else {
                    //$(ui.helper).css('margin-top', '-180px');
                    $(ui.helper).css('margin-top', '0px');
                }
            }
        });

        $('ol.qqol').nestedSortable({
            handle: 'div',
            items: 'li',
            disableNestingClass:"ui-state-no-nesting",
            placeholder: "ui-state-highlight",
            errorClass: "ui-state-error",
            leafClass:"inner-questions",
            toleranceElement: '> div',
            opacity: 1,
            revert: 250,
            //helper:	'clone',            
            maxLevels: 3,            
            isTree: false,
            protectRoot: false,
            disableParentChange:true,
            tolerance: 'fit',      
            connectWith: ".sortableArea",
            start: function(e, ui) {
                // creates a temporary attribute on the element with the old index
                ui.item.startPos = ui.item.index();
                ui.item.attr('data-previndex', ui.item.index());                
                ui.item.attr('data-id', ui.item.closest('ol.sortableArea').attr('id'));
                isRecive = false;
                inputField = 'No';                
            },
            update: function(e, ui) {
                //console.log('update: '+ui.item.index()+'====='+ui.item.attr('data-previndex'));                
                //isRecive=false;
            },
            receive: function(e, ui) {                
                if (ui.sender[0].id == 'sortableArea1' || ui.sender[0].id == 'sortableArea2') {
                    isRecive == false;
                } else {
                    isRecive = true;
                    inputField = ui.sender[0].id;
                    component.set("v.dropColNumber", $(this).parent().attr("id"));
                    component.set("v.dragId", ui.sender[0].id);
                    component.set("v.modalHeader", ui.sender[0].id);
                    component.set("v.isEditQue", false);
                    console.log('type: '+inputField+', colnum: '+$(this).parent().attr("id"));                    
                }
            },
            stop: function(e, ui) {
                if (isRecive == true && !$A.util.isEmpty(inputField)) {                    
                    component.set("v.quesDropOrderNumber", ui.item.index() + '');
                    self.openQuestionEditor(component, inputField);
                    self.openEditor(component);
                    ui.item.remove();
                } 
                else {
                    console.log('isRecive: '+isRecive);
                    //try get get sorted list by jquery
                    let newIndex = ui.item.index(); //new index of li where it drop.
                    let prevIndex = ui.item.startPos; //this variable hold old index of li
                    
                    let newColId = ui.item.parent().attr("id");
                    let prevColId = ui.item.attr('data-id');//return sortableArea1 or sortableArea2
                    
                    console.log('prev col: '+prevColId);
                    console.log('new col: '+newColId);
                    console.log('prev index: '+prevIndex);
                    console.log('new index: '+newIndex);
                    
                    newColId = newColId?newColId:prevColId;

                    const newColNum = newColId.replace('sortableArea','col');
                    if(prevIndex!=newIndex && prevColId==newColId){
                        console.log('1 - total: '+$("ol#"+prevColId+" li").length);
                        const qqData = [];
                        const ids = [];
                        $("ol#"+prevColId+" li").each(function(i, el){                                     
                            let qqid = $(el).attr('data-qqid');                                
                            if(ids.indexOf(qqid)<0){
                                qqData.push({
                                    sobjectType: 'Question_Questionnaire__c',
                                    Id: qqid,
                                    Question_Order__c: i                                    
                                });
                                ids.push(qqid);
                            }
                        });
                        self.sortColumn(component, qqData,[]);
                    }
                    else if(newColId && prevColId!=newColId){
                        const qqData = [];
                        const qData = [];
                        const ids = [];
                        console.log('2 - total: '+$("ol#"+newColId+" li").length);
                        $("ol#"+newColId+" li").each(function(i, el){                                     
                            let qqid = $(el).attr('data-qqid');
                            let qid = $(el).attr('data-qid');
                            
                            if(ids.indexOf(qqid)<0){
                                qqData.push({
                                    sobjectType: 'Question_Questionnaire__c',
                                    Id: qqid,
                                    Question_Order__c: i,
                                    Related_To_Column__c:newColNum
                                });
                                qData.push({
                                    sobjectType: 'Question__c',
                                    Id: qid,                                        
                                    Related_To_Column__c:newColNum
                                });
                                ids.push(qqid);
                            }
                        });
                        self.sortColumn(component, qqData,qData);
                    }
                }
            }
        }).disableSelection();
     
        //End sorting code
        if (self.isLightningExperienceOrSalesforce1()) {
            $(".field-type-container").height($(window).height() - 135);
            $(".slds-tabs_default__content").height($(window).height() - 177);
            console.log('LTNG');
        } else {
            $(".field-type-container").height($(window).height()-294);
            $(".slds-tabs_default__content").height($(window).height()-233);
        }
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
            this.showToast(component,  'error', '"' + fieldType + '" field type not supported!');
        }
    },

    sortColumn: function(component, lstQQ,lstQ) {
        var self = this;
        var vQnaireId = component.get("v.QnaireId");        
        var vSectionId = component.get("v.selTabId");
        var action = component.get("c.setQuestnQnniareOrder");        
        action.setParams({
            lstOrderOfQQniare: lstQQ,
            lstOrderOfQst:lstQ
        });
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);            
            var state = res.getState();
            if (state === "SUCCESS") {
                self.showToast(component,  'success', 'Successfully re-order question');                
                self.getAllQuestion(component, vQnaireId, vSectionId);                
            } else {
                self.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.getCallback(function() {
            $A.enqueueAction(action);
        })();
    },
    updateColumn: function(component, questionaryId, questionId, colNum, dropedIndex) {
        
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
                this.showToast(component, 'success', 'Column changed!');
                this.getAllQuestion(component, vQnaireId, vSectionId);
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.getCallback(function() {
            $A.enqueueAction(action);
        })();
    },

    getQuestionnaireRecord: function(component) {
        var self = this;
        self.getQuesCategory(component);
        window.setTimeout($A.getCallback(function() {
            self.getTempRecord(component, component.get("v.QnaireId"));
        }, 2500));
    },
    getQuesCategory: function(component) {
        var action = component.get("c.getQueCategory");
        var self = this;
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                component.set("v.lstQuesCategory", res.getReturnValue());
            } else {
                self.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    getPagination: function(component) {
        var action = component.get("c.getPage");
        action.setParams({
            qid: component.get("v.QnaireId")
        });
        var self = this;
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {                
                component.set("v.pageObj", res.getReturnValue());
                let pageObj = res.getReturnValue();
                
                var sectId = component.get("v.selTabId");
                let selectedPageIndex = '';
                if(pageObj.Form_Pages__r!=undefined && pageObj.Form_Pages__r.length>0){
                    pageObj.Form_Pages__r.forEach((item,ind)=>{
                        if(item.Section__c!=undefined && item.Section__c.indexOf(sectId)>=0){
                            selectedPageIndex = ind+'';
                        }
                    });
                    component.set("v.selectedPageIndex",selectedPageIndex);                
                    component.set("v.selectedPage",pageObj.Form_Pages__r[selectedPageIndex]);
                }
                this.setPageWithSection(component,pageObj);
            } else {
                self.showToast(component, 'error', JSON.stringify(res.getError()));
            }
        });
        $A.enqueueAction(action);
    },
    
    setPageWithSection:function(component,page){
        var pageObj = JSON.parse(JSON.stringify(page));
        var sections = component.get("v.sectionOptions");
        var assignedSect = [];
        var remaningSect = [];
        if(pageObj.Form_Pages__r!=undefined && pageObj.Form_Pages__r.length>0){
            pageObj.Form_Pages__r.forEach((item,ind)=>{
                item.sectionList = sections.filter(s=>item.Section__c!=undefined && item.Section__c.indexOf(s.value)>=0);                
            });
            pageObj.Form_Pages__r.forEach(item=>{
                item.sectionList.forEach(sec=>{
                    assignedSect.push(sec.value);
                });
            });

            remaningSect = sections.filter(s=>assignedSect.indexOf(s.value)<0);
            component.set("v.remaningSection",remaningSect);
        }
        component.set("v.pageAndSection",pageObj.Form_Pages__r);        
    },
    setSelectedPageIndex:function(component,sectId){
        let pageObj = component.get("v.pageObj");        
        let selectedPageIndex = '';

        if(pageObj.Form_Pages__r!=undefined && pageObj.Form_Pages__r.length>0){
            pageObj.Form_Pages__r.forEach((item,ind)=>{
                if(item.Section__c!=undefined && item.Section__c.indexOf(sectId)>=0){
                    selectedPageIndex = ind+'';
                }
            });
            component.set("v.selectedPageIndex",selectedPageIndex);        
            component.set("v.selectedPage",pageObj.Form_Pages__r[selectedPageIndex]);
        }
    },
    getTempRecord: function(component, vQnaireId) {
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
                    var e = $A.get("e.c:FBActiveHeaderEvent");
                    e.setParams({ "compName": "search" });
                    e.fire();
                } else {
                    component.set("v.objQnaire", obj.questionnaire);
                    component.set("v.objQnaire", obj.questionnaire);
                    component.set("v.QnaireName", component.get("v.objQnaire.Name"));
                }
                this.getQuesGroupRecord(component, vQnaireId, "");
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    getQuesGroupRecord: function(component, vQnaireId, type) {
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
                    this.getAllQuestion(component, vQnaireId, component.get("v.selTabId"));
                } else if (type === "change") {
                    this.getAllQuestion(component, vQnaireId, component.get("v.selTabId"));
                } else {
                    component.set("v.selTabId", lstQGroup[0].Question_Group__c);
                    this.getAllQuestion(component, vQnaireId, component.get("v.selTabId"));
                }
                this.getPagination(component);
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    getAllQuestion: function(component, vQnaireId, vSectionId) {
        var action = component.get("c.getQuestnsForQuesGroup"); //Calling Apex class controller 'getQuestnForQuesGroup' method
        action.setParams({
            qnaireId: vQnaireId,
            sectionId: vSectionId,
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {                
                this.branchingOnCol(component, res.getReturnValue(), vSectionId);
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    branchingOnCol: function(component, lstQuestion, vSectionId) {
        var that = this;
        component.set("v.Spinner", true);
        var action = component.get("c.getBranchingQuestn");
        action.setParams({
            sectionId: vSectionId,
        });

        action.setCallback(this, function(res) {            
            var state = res.getState();
            if (state === "SUCCESS") {
                try {                    
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
                            console.error(e);
                            resolve(resLstQDynLogic);                            
                        }
                    })).then($A.getCallback(function(lstQDynLogic) {
                        component.set("v.lstQDynLogicMain", lstQDynLogic);
                        
                        if (lstQuestion.col1Questions.lstQuestn.length > 0) {
                            that.setQuestionBranching(component, lstQuestion, 'col1');
                        }
                        if (lstQuestion.col2Questions.lstQuestn.length > 0) {
                            that.setQuestionBranching(component, lstQuestion, 'col2');
                        }
                        if (lstQuestion.col1Questions.lstQuestn.length == 0 || lstQuestion.col2Questions.lstQuestn.length == 0) {
                            component.set('v.lstQQuesnnaire', lstQuestion);
                            console.log("lstQuestion=====",JSON.stringify(lstQuestion));
                            //initiate drag and sorting if no question found
                            window.setTimeout($A.getCallback(function() {
                                that.callScriptsLoaded(component);
                                component.set("v.Spinner", false);
                            }), 1000);                            
                        }
                    }));
                } catch (e) {
                    console.error(e);
                }                                
            } 
            else {                
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    setQuestionBranching: function(component, lstQuestion, col,col2DataQstFound) {

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
                    if(question[indexQueResult].Question_Questionnaires__r[0].branchingQuestnQuetnnaire){
                    	question[indexQueResult].Question_Questionnaires__r[0].isBranch = question[indexQueResult].Question_Questionnaires__r[0].branchingQuestnQuetnnaire.length>0?true:false;
                        
                        //sort branch questions
                        question[indexQueResult].Question_Questionnaires__r[0].branchingQuestnQuetnnaire.sort(function(a, b) {
                            var keyA = a.Question_Order__c,
                                keyB = b.Question_Order__c;
                            // Compare the 2 dates
                            if (keyA < keyB) return -1;
                            if (keyA > keyB) return 1;
                            return 0;
                        }); 
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

        component.set('v.lstQQuesnnaire', {}); 
        var self = this;   
        window.setTimeout($A.getCallback(function() {
            component.set('v.lstQQuesnnaire', lstQuestion);            
            window.setTimeout($A.getCallback(function() {                
                self.callScriptsLoaded(component);
                component.set("v.Spinner", false);
            }), 2000);
        }), 500);
    },
    createQuestion: function(component, vQnaireId, vSectionId, vDragId, colNumber) {
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
                this.getAllQuestion(component, vQnaireId, vSectionId);
                this.removeQuesValue(component);
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);

    },
    removeQuesValue: function(component) {
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
    deleteQuestion: function(component, vQuestnQuestnnaireId) {
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
                this.getAllQuestion(component, vQnaireId, vSectionId);

            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    editQuestion: function(component, vQuesId) {
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
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    helperSaveEditQues: function(component) {
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
                this.getAllQuestion(component, vQnaireId, vSectionId);
                component.set("v.isShowModal", false);
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    updateSectionHelper: function(component, sectionName, questionaryId, columnNo,isShowOnForm) {
        component.set("v.Spinner", true);
        var action = component.get("c.updateSection");
        var sectObj = {
            'sobjectType':'Question_Group__c',
            'Id':component.get("v.selTabId"),
            'Name':sectionName,
            'No_Of_Columns__c':columnNo,
            'Is_Show_On_From__c':isShowOnForm
        };
        action.setParams({sectionObj: sectObj,questionaryId: questionaryId});
        action.setCallback(this, function(res) {
            component.set("v.Spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                this.closeEditor(component);
                component.set("v.isShowSection", false);
                component.set("v.isShowSectionEditForm", false);
                component.set("v.lstQQuesnnaire.col1Questions.groupName", sectionName);
                component.set("v.lstQQuesnnaire.col1Questions.sectionColNumber", columnNo);
                this.getAllQuestion(component, questionaryId, component.get("v.selTabId"));
            } else {
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    saveSectionHelper: function(component, sectionName, questionaryId, columnNo,isShowOnForm) {
        component.set("v.Spinner", true);
        var action = component.get("c.createSection");
        var sectObj = {
            'sobjectType':'Question_Group__c',
            'Name': sectionName,
            'No_Of_Columns__c': columnNo,
            'Is_Show_On_From__c':isShowOnForm
        };
        action.setParams({
            sectionObj: sectObj,
            questionaryId: questionaryId
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                this.closeEditor(component);
                var response = res.getReturnValue();
                component.set("v.isShowSection", false);
                component.set("v.isShowSectionEditForm", false);
                var secList = component.get("v.sectionOptions");
                secList.push({ label: sectionName, value: response.Id });
                component.set("v.sectionOptions", secList);
                component.set("v.selTabId", response.Id);
                var self = this;
                setTimeout(function(){
                    var vSectionId = component.get("v.selTabId");
                    var vQnaireId = component.get("v.QnaireId");
                    self.setSelectedPageIndex(component,vSectionId);
                    var index = secList.length-1
                    var menuItems = component.find("menuItems");
                    menuItems.find(function(menuItem){
                        $A.util.removeClass(menuItem.getElement(),'slds-is-active');
                    });
                    if(index<=8){
                        var menuItems2 = component.find("menuItems");
                        var tempindex = 0;
                        menuItems2.find(function(menuItem2){
                            if(tempindex == index){
                                $A.util.addClass(menuItem2.getElement(),'slds-is-active');
                            }
                            tempindex++;
                        });                        
                    }
                    component.find('tab_content').getElement().setAttribute("id","tab-default-"+index);
                    component.find('tab_content').getElement().setAttribute("aria-labelledby","tab-default-"+index+"__item");
                    self.getAllQuestion(component, vQnaireId, vSectionId);                    
                    self.getPagination(component);
                    component.set("v.Spinner", false);
                },500);
                
            } else {
                component.set("v.Spinner", false);
                this.showToast(component, 'error', res.getError()[0].message);
            }
        });
        $A.enqueueAction(action);
    },

    showToast: function(component, type, message) {
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
                    console.error("No response from server or client is offline.")
                        // Show offline error
                } else if (status === "ERROR") {
                    console.error("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
    },
    onlyReturnString: function(valueWithHtmlTag) {
        var regex = /(<([^>]+)>)/ig
        return valueWithHtmlTag.replace(regex, "");
    },
    isLightningExperienceOrSalesforce1: function() {
        return ((typeof sforce != 'undefined') && sforce && (!!sforce.one));
    }
})