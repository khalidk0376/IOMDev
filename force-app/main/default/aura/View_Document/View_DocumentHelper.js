({
    navigateToLC : function(component) {
        let finalURL = "/apex/View_Document?RecordID=" + component.get("v.recordId");
        let pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__TabComponent'
            },
            state: {
                c__refRecordId: component.get("v.recordId")
            }
        };
        const navService = component.find('navService');
        const handleUrl = (url) => {
            window.open(finalURL);
        };
        const handleError = (error) => {
            console.log(error);
        };
        navService.generateUrl(pageReference).then(handleUrl, handleError);

        // Close the action panel
        $A.get("e.force:closeQuickAction").fire();
    } 
})