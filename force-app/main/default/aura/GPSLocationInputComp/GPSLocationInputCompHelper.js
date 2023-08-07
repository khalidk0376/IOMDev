({
    showToast: function(component, type, message) {
        $A.createComponent("c:FBToast",{"msgbody": message,"msgtype": type},function(newToast, status, errorMessage){
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
        });
    },
    SaveQuestion: function(component, event) {
        var isEdit = component.get("v.isEditQue");
        var vQues = component.get("v.objCrteQues");
        vQues.Type__c = component.get("v.modalHeader");
        vQues.Label__c = vQues.Label__c.trim();
        vQues.Label__c = this.removePTag(component, event, vQues.Label__c);
        var vQnaireName = component.get("v.QnaireName");
        var vQuesOrder = component.get("v.questOrderNum");

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
        if (isEdit) {
            action = component.get("c.saveEditQuesRecord"); //Calling Apex class controller 'saveEditQuesRecord' method
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
                this.showToast(component,'error',res.getError()[0].message);
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
        var text = labelText.split("<p>");
        var myString ="";
        if(text !== undefined && text.length>0){
            for(var index=0 ;index<text.length;index++){
                myString = myString + text[index].replace("<p>", "");
                myString = myString.replace("</p>", "<br/>");
            }
            var strBr = myString.substr(myString.length - 5, myString.length);
            if(strBr ==='<br/>'){
                return myString.slice(0, -5);
            }
            return myString;
            
        }
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
    }
})