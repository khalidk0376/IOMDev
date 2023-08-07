({
    getBaseUrlHelper:function(component){
        var action1 = component.get('c.getBaseUrl');                
        action1.setCallback(this,function(a){         
            var datas = a.getReturnValue();
            component.set('v.baseurl',datas.split('__')[0]);
            component.set('v.orgId',datas.split('__')[1]);
        })
        $A.enqueueAction(action1);
    },
    showMoadalHelper:function(cmp){        
        $A.util.addClass(cmp.find('mms_selection'),'slds-fade-in-open')
        $A.util.removeClass(cmp.find('mms_selection'),'slds-fade-in-close')
        $A.util.addClass(cmp.find('mms_selection_backdrop'),'slds-backdrop_open')
        $A.util.removeClass(cmp.find('mms_selection_backdrop'),'slds-backdrop_close')
    },
    closeMoadalHelper:function(cmp){        
        $A.util.removeClass(cmp.find('mms_selection'),'slds-fade-in-open')
        $A.util.addClass(cmp.find('mms_selection'),'slds-fade-in-close')
        $A.util.removeClass(cmp.find('mms_selection_backdrop'),'slds-backdrop_open')
        $A.util.addClass(cmp.find('mms_selection_backdrop'),'slds-backdrop_close')
    },
    getAllDocumentsHelper:function(component,pageNum){
        var action1 = component.get('c.getAllDocuments');               
        var self = this;
        action1.setParams({"pageNumber":pageNum})
        action1.setCallback(this,function(a){            
            self.getBaseUrlHelper(component);
            var result = a.getReturnValue();
            component.set('v.uploadedDoc',result.uploadedDoc);
            component.set("v.page", result.page);
            component.set("v.total", result.total);
        })
        $A.enqueueAction(action1);
    },
    SaveQuestion: function(component, event) {
        var isEdit = component.get("v.isEditQue");
        var vQues = component.get("v.objCrteQues");
        vQues.Type__c = component.get("v.modalHeader");
        vQues.Label__c = vQues.Label__c.trim();
        vQues.Label__c = this.removePTag(component, event, vQues.Label__c);
        var vQnaireName = component.get("v.QnaireName");
        var vQuesOrder = component.get("v.questOrderNum");//'2';

        //Calling Apex class controller 'createQueQnaire' method
        var action = component.get("c.createQuestnAndQuestnQnaire");
        action.setParams({
            qnaireId: component.get("v.QnaireId"),
            qGroupId: component.get("v.QuestnGroupId"),
            question: vQues,
            qnaireName: vQnaireName,
            qOrder: vQuesOrder,
            colNumber: component.get("v.dropColNumber")
        });
        if(isEdit) 
        {
            //Calling Apex class controller 'saveEditQuesRecord' method
            action = component.get("c.saveEditQuesRecord");
            action.setParams({
                oQues: vQues,
                qnaireId: component.get("v.QnaireId"),
                sectionId: component.get("v.QuestnGroupId"),
                isUnderBranching : false
            });
        }
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                this.crudModalEvent(component, event, false, true);
            } else {
                this.showToast(component,'Error!','error',res.getError()[0].message);
                component.set("v.isShowbutton", false);
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
    onlyReturnString: function(component, event, valueWithHtmlTag) {
        var regex = /(<([^>]+)>)/ig
        return valueWithHtmlTag.replace(regex, "");
    },
    removePTag: function(component, event, labelText) {
        // var text = labelText.split("<p>");
        // var myString ="";
        // if(text !== undefined && text.length>0){
        //     for(var index=0 ;index<text.length;index++){
        //         myString = myString + text[index].replace("<p>", "");
        //         myString = myString.replace("</p>", "<br/>");
        //     }
        //     var strBr = myString.substr(myString.length - 5, myString.length);
        //     if(strBr ==='<br/>'){
        //         return myString.slice(0, -5);
        //     }
        //     return myString;
            
        // }
        return labelText;
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
        //component.set("v.description", "");
    },
    showToast: function(component,title, type, message) {
        $A.createComponent(
            "c:FBToast",
            {
                "msgbody": message,
                "msgtype": type
            },
            function(newToast, status, errorMessage){                
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newToast);
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                }
            }
        );
    }
})