({
    afterPendoLoaded : function (component, event, helper) {
        var imccLoadPendo = $A.get("$Label.c.IMCC_Load_Pendo");
        if(imccLoadPendo == "true"){
            console.log('pendo afterPendoLoaded : ',imccLoadPendo);
            helper.initPendo(component);
        }
    }
})