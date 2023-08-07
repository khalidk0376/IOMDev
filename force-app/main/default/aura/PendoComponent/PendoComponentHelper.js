({
    getMetadata: function (component) {
        var action = component.get("c.getMetadata");
        var edcode = this.getParameterByName('edcode');
        var accId = this.getParameterByName('accId');
        console.log('edcode### : ',edcode);
        console.log('accId### : ',accId);
        action.setParams({editionCode:edcode,accountId:accId});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS") {
                var metadata = response.getReturnValue();
                console.log('metadata### : ',JSON.stringify(metadata));
                var listCEM = metadata.listCEM;
                if(listCEM.length > 0){
                    if(listCEM[0].Role__c != null && listCEM[0].Role__c != ''){
                        metadata.visitor.cem_role = listCEM[0].Role__c;
                    }
                    if(listCEM[0].Edition__c != null){
                        if(listCEM[0].Edition__r.Name != null && listCEM[0].Edition__r.Name != ''){
                            metadata.visitor.event_edition_name = listCEM[0].Edition__r.Name;
                        }
                        if(metadata.editionYear != 0){
                            metadata.visitor.event_edition_year = metadata.editionYear;
                        }
                    }
                }
                window.pendo.initialize({
                    visitor: metadata.visitor,
                    account: metadata.account
                })
                console.log('visitor### : ',JSON.stringify(metadata.visitor));
                console.log('account### : ',JSON.stringify(metadata.account));
                component.set('v.isPendoInitialized', true);
            }
            else {
                console.log('Aura pendo comp failed: ', state, response)
            }
        });
        $A.enqueueAction(action);
    },
    initPendo: function(component) {
        var isPendoInitialized = component.get('v.isPendoInitialized');
		console.log('Aura pendo doInit 1: ',isPendoInitialized);
		console.log('Aura pendo doInit 2: ',window.pendo);
        if(!isPendoInitialized && window.pendo) {
            console.log('Aura pendo doInit 3: ',window.pendo);
            this.getMetadata(component)
        }
    },
    getParameterByName: function (name) {
        name = name.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    }
})