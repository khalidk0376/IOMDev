({
    modalClose : function(component, event) {
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    },
    handleDestroy:  function (component, helper) {
        $A.get('e.force:refreshView').fire();
    }
})