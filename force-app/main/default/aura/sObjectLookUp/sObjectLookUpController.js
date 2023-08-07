({
    // To prepopulate the seleted value pill if value attribute is filled
	doInit : function( component, event, helper ) {
    	$A.util.toggleClass(component.find('resultsDiv'),'slds-is-open');		
        //helper.searchRecordsHelper(component, event,'','');
	},

    // When a keyword is entered in search box
	searchRecords : function( component, event, helper ) {
        if( !$A.util.isEmpty(component.get('v.searchString')) ) {
		    helper.searchRecordsHelper( component, event, '', component.get('v.searchString'));
        } else {
            $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
        }
	},

    // When an item is selected
	selectItem : function( component, event, helper )
	{
		if(!$A.util.isEmpty(event.currentTarget.id)) 
		{
            var recordsList = component.get('v.recordsList');
            var selectedid = event.currentTarget.id;
    		var index = recordsList.findIndex(x => x.value === selectedid)
            if(index != -1) 
            {
                var selectedRecord = recordsList[index];
                component.set('v.selectedRecord',selectedRecord);
                component.set('v.selectedRecordId',selectedRecord.value);  
            }
            $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
        }
	},

    // To remove the selected item.
	removeItem : function( component, event, helper )
	{
        component.set('v.selectedRecord','');
        component.set('v.selectedRecordId','');
        component.set('v.searchString','');
        setTimeout( function() {
            component.find( 'inputLookup' ).focus();
        }, 250);
    },

    // To close the dropdown if clicked outside the dropdown.
    blurEvent : function( component, event, helper ){
    	$A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
    },
    onFocusEvent : function( component, event, helper ){
       $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
        helper.searchRecordsHelper(component, event,'','');
    }
})