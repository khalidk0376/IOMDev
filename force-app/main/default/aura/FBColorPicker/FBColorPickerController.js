({
	doInit  : function(component, event, helper) {
		component.set("v.rcolorCode",component.get('v.colorCode'));
		var colorscode=["b85d0d","b67e11","0b6b50","0b7477","0a2399","001970","580d8c","f99221","f5bc25","3cba4c","00aea9","5ebbff",
						"5779c1","bd35bd","ffb758","ffe654","3be282","44d8be","5ebbff","86baf3","d073e0","fed49a","fff099","9df0c0",
						"9de7da","9fd6ff","c2dbf7","e3abec","000000","f9f9f9","e1e1e1","727272","ffffff","333333","f2f2f2"];
		component.set("v.colorList",colorscode);
	},
	openBox : function(component, event, helper) {
		var colorbox = component.find('colorbox');
		$A.util.toggleClass(colorbox,'slds-show');
		$A.util.toggleClass(colorbox,'slds-hide');
	},
	updateColor:function(component, event, helper) {
		try{
			var colorCode = '#'+event.target.id;
			component.set("v.colorCode",colorCode);
			var colorbox = component.find('colorbox');
			$A.util.removeClass(colorbox,'slds-show');
			$A.util.addClass(colorbox,'slds-hide');
		}
		catch(e){
			console.log(e);
		}
	},
	resetColor : function(component, event, helper) {
		var colorbox = component.find('colorbox');
		$A.util.removeClass(colorbox,'slds-show');
		$A.util.addClass(colorbox,'slds-hide');
		component.set("v.colorCode",component.get('v.rcolorCode'));
	},
	selectColor : function(component, event, helper) {
		var colorbox = component.find('colorbox');
		$A.util.removeClass(colorbox,'slds-show');
		$A.util.addClass(colorbox,'slds-hide');
	}
})