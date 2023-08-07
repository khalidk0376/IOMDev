({
    doInit: function(component, event, helper) {
        var isEditQue = component.get("v.isEditQue");
        if (isEditQue === false) {
            helper.removeQuesValue(component, event);
        }
        window.setTimeout($A.getCallback(function() {
            if(component.find('qustNameRich')!=null){
                component.find('qustNameRich').focus();
            }
        }), 500);
        helper.getBaseUrlHelper(component);
        var page = component.get("v.page") || 1;
        helper.getAllDocumentsHelper(component,page);
    },
    showModal2: function(component,event,helper){
        helper.showMoadalHelper(component);
    },
    reloadDoc:function(component,event,helper){
        helper.getAllDocumentsHelper(component,1);
    },
    hideModal2: function(component,event,helper){
        helper.closeMoadalHelper(component);
    },
    paginate : function(component, event, helper) {     
        var page = component.get("v.page") || 1;
        var direction = event.getSource().get("v.iconName");        
        page = direction === "utility:chevronleft" ? (page - 1) : (page + 1);
        helper.getAllDocumentsHelper(component, page);
    },
    selectedURL:function(component,event,helper){
        var ele = document.getElementsByClassName("radiobutton");   
        var docId = '';
        for(var i=0;i<ele.length;i++){            
            if(ele[i].checked){
                docId = ele[i].getAttribute('value');
            }
        }
        if(docId!=''){
            var mediaUrl = component.get("v.baseurl")+'/servlet/servlet.ImageServer?id='+docId+'&oid='+component.get("v.orgId");
            component.set("v.objCrteQues.Label__c",component.get("v.objCrteQues.Label__c")+'<img src="'+mediaUrl+'" width="100%"/>');

        }
        helper.closeMoadalHelper(component);
    },
    hideModal: function(component, event, helper) {
        helper.crudModalEvent(component, event, true, false);
    },
    uploadDocPage:function(component,event,helper){
        window.open('/015/o','_blank');
    },
    saveQues: function(component, event, helper) {        
        
        component.set("v.isShowbutton", true);
        var qes = component.get("v.objCrteQues");
        var vQnaireId = component.get("v.QnaireId");
        var vSectionId = component.get("v.QuestnGroupId");
        var dropColNumber = component.get("v.dropColNumber");
        var vDragId = component.get("v.fieldType");
        var qustnlabel = qes.Label__c.trim();
        if (!qustnlabel) {
            helper.showToast(component,'Alert!', 'error', "Add some content or images");
            component.set("v.isShowbutton", false);
            component.find('qustNameRich').focus();
            return false;
        } else if (component.get("v.objCrteQues.Help_Text_Required__c") === true) {            
            var helpTextValue = component.find("helpTextInp").get("v.value");
            if (!helpTextValue) {
                helper.showToast(component,'Alert!', 'error', "Enter help text.");
                component.set("v.isShowbutton", false);
                component.find('qustNameRich').focus();
                return false;
            }
        }

        if (qustnlabel.trim().length <= 10000 && qustnlabel.trim().length !==0) {
            helper.SaveQuestion(component, event);
        } else {            
            helper.showToast(component,'Alert!', 'error', "Character's Length should not exceed 10000.");
            component.set("v.isShowbutton", false);
            component.find('qustNameRich').focus();
        }
        
    },
    checkTextLength: function(component, event, helper) {
        var target = event.getSource();
        var qustnlabel = target.get("v.value");
        qustnlabel = helper.onlyReturnString(component, event, qustnlabel);
        if (!qustnlabel) {
            if (qustnlabel.length > 10000) {                
                helper.showToast(component,'Alert!', 'error', "Character's Length should not exceed 10000");
                component.find('qustNameRich').focus();
                return false;
            }
        }
    }
})