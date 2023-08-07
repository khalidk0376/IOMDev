({
    doInit:function(component, event, helper){
        $A.util.addClass(component.find('gkn_fb_toast'),'slds-fade-in-open');
        $A.util.removeClass(component.find('gkn_fb_toast'),'slds-fade-in-close');        
        window.setTimeout($A.getCallback(function() {
            $A.util.addClass(component.find('gkn_fb_toast'),'slds-fade-in-close');
            $A.util.removeClass(component.find('gkn_fb_toast'),'slds-fade-in-open');
            component.set('v.msgbody','');
            component.set('v.msgtype','');
        }), 5000);
    },
	closeToast:function(component, event, helper){
        $A.util.addClass(component.find('gkn_fb_toast'),'slds-fade-in-close');
        $A.util.removeClass(component.find('gkn_fb_toast'),'slds-fade-in-open');
        component.set('v.msgbody','');
        component.set('v.msgtype','');
    },
})