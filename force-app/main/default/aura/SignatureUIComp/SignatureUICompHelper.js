({
    MAX_FILE_SIZE: 750000,    
    doInit: function(component, event, helper) {
        var canvas, ctx, flag = false,
            prevX = 0,
            currX = 0,
            prevY = 0,
            currY = 0,
            dot_flag = false;
        
        var x = "black",
            y = 2,
            w, h;
        
        var wrapper = component.find('modal-content-id-1').getElement();
        canvas = wrapper.querySelector('canvas')

        var ratio = Math.max(window.devicePixelRatio || 1, 1);
        w = canvas.width*ratio;
        h = canvas.height*ratio;
        ctx = canvas.getContext("2d");
        //set bg
        //ctx.fillStyle = "rgb(255,255,255)";
        //ctx.fillRect(0,0,20,20);
        
        ctx.lineWidth = "5";
        ctx.strokeStyle = "green"; // Green path
        ctx.stroke(); // Draw it
        canvas.addEventListener("mousemove", function(e) {
            findxy('move', e)
        }, false);
        canvas.addEventListener("mousedown", function(e) {
            findxy('down', e)
        }, false);
        canvas.addEventListener("mouseup", function(e) {
            findxy('up', e)
        }, false);
        canvas.addEventListener("mouseout", function(e) {
            findxy('out', e)
        }, false);
        // Set up touch events for mobile, etc
        canvas.addEventListener("touchstart", function(e) {
            var touch = e.touches[0];
            var mouseEvent = new MouseEvent("mousedown", {
                clientX: touch.clientX,
                clientY: touch.clientY
            });
            canvas.dispatchEvent(mouseEvent);
            e.preventDefault();
        }, false);
        canvas.addEventListener("touchend", function(e) {
            var mouseEvent = new MouseEvent("mouseup", {});
            canvas.dispatchEvent(mouseEvent);
        }, false);
        canvas.addEventListener("touchmove", function(e) {
            var touch = e.touches[0];
            var mouseEvent = new MouseEvent("mousemove", {
                clientX: touch.clientX,
                clientY: touch.clientY
            });
            canvas.dispatchEvent(mouseEvent);
            e.preventDefault();
            
        }, false);
        
        // Get the position of a touch relative to the canvas
        function getTouchPos(canvasDom, touchEvent) {
            var rect = canvasDom.getBoundingClientRect();
            return {
                x: touchEvent.touches[0].clientX - rect.left,
                y: touchEvent.touches[0].clientY - rect.top
            };
        }
        
        function findxy(res, e) {
            var rect = canvas.getBoundingClientRect();
            if (res === 'down') {
                prevX = currX;
                prevY = currY;
                currX = e.clientX - rect.left ;//canvas.offsetLeft;
                currY = e.clientY -  rect.top;//canvas.offsetTop;
                flag = true;
                dot_flag = true;
                if (dot_flag) {
                    ctx.beginPath();
                    ctx.fillStyle = x;
                    ctx.fillRect(currX, currY, 2, 2);
                    ctx.strokeStyle = "green";
                    ctx.closePath();
                    dot_flag = false;
                }
            }
            if (res === 'up' || res === "out") {
                flag = false;
            }
            if (res === 'move') {
                if (flag) {
                    prevX = currX;
                    prevY = currY;
                    currX = e.clientX -  rect.left;
                    currY = e.clientY - rect.top;
                    draw(component, ctx);
                }
            }
        }
        
        function draw() {
            ctx.beginPath();
            ctx.moveTo(prevX, prevY);
            ctx.lineTo(currX, currY);
            ctx.strokeStyle = "black";
            ctx.lineWidth = y;
            ctx.stroke();
            ctx.closePath();
            ctx.minWidth=0.5;
            ctx.maxWidth=2;
        }
        
    },
    eraseHelper: function(component) {
        var wrapper = component.find('modal-content-id-1').getElement();
        var canvas = wrapper.querySelector('canvas')
        var ctx = canvas.getContext("2d");
        var w = canvas.width;
        var h = canvas.height;
        ctx.clearRect(0, 0, w, h);
        
    },
    saveHelper: function(component, event, closeModel, isUpdateRecord) {
        try{
            var wrapper = component.find('modal-content-id-1').getElement();
            var canvas = wrapper.querySelector('canvas')
            var vDragId = 'Signature';
            var formResponseEntryId = component.get("v.formResponseEntryId");
            if(canvas.toDataURL("image/png").length>6866 ){
                if(formResponseEntryId != null && formResponseEntryId != ""){
            	    this.uploadSignature(component,vDragId,closeModel,isUpdateRecord,canvas.toDataURL("image/png")); 
                }   
            }
            else{
                this.showToastHelper(component,"Error :","error","Please sign to save.");
            }
        }
        catch(e)
        {
            console.log(e);
        }
    },
    getCookie : function(cname) {
        var name = cname + "=";
        var decodedCookie = decodeURIComponent(document.cookie);
        var ca = decodedCookie.split(';');
        for(var i = 0; i <ca.length; i++) {
            var c = ca[i];
            while (c.charAt(0) == ' ') {
                c = c.substring(1);
            }
            if (c.indexOf(name) == 0) {
                return c.substring(name.length, c.length);
            }
        }
        return "";  
    },

    getParameterByName: function(name) {
        name = name.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    },

    uploadSignature:function(component,vDragId,closeModel,isUpdateRecord,signData){
        var fileContents = signData;
        var base64Mark = 'base64,';
        var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
        fileContents = fileContents.substring(dataStart);
        console.log(fileContents);
        var url = window.location.href;
		url = url.replace("/s/",'/');
        var url2 = url.split('/');        
        url2.pop();
        let siteUrl = url2.join('/');
        
        component.set("v.spinner", true);
        var self = this;
        //var userDetail = self.getCookie('FBUserSessionID');
        var action = component.get("c.saveSignatureResponse"); //Calling Apex class controller 'getTemplateRecrod' method
        var conEdMapId = this.getParameterByName('ceid');
        var boothId = this.getParameterByName('b');
        boothId = boothId?boothId:null;
        let isNewEntry = component.get("v.isNewEntry");
        let formResponseEntryId = component.get("v.formResponseEntryId");

        action.setParams({
            conEdMapId:conEdMapId,
            formResponseEntryId: formResponseEntryId,
            boothId:boothId,
            questionId: component.get("v.questionId"),
            questionerId:component.get("v.questionerId"),
            questionQuestionnairesId:component.get("v.questionQuestionnairesId"),
            base64Data: encodeURIComponent(fileContents),
            siteUrl:siteUrl,
            version:component.get("v.version")
        });
        action.setCallback(this, function(res) {
            component.set("v.spinner", false);
            var state = res.getState();
            if (state === "SUCCESS") {
                var obj = JSON.parse(res.getReturnValue());
                if(obj.isSuccess==true){
                    self.showToastHelper(component,"SUCCESS :","success",'Your sign have been uploaded');
                }else{
                    self.showToastHelper(component,"Error :","error",obj.message);
                }
                var appEvent = $A.get("e.c:FBCloseEvent");
                appEvent.setParams({ "closeModel": closeModel, "isUpdateRecord": isUpdateRecord, "modelName": vDragId, "signData":signData, "Successstatus":state});                
                appEvent.fire();
            } else {
                self.showToastHelper(component,"Error :","error",res.getError()[0].message);
                var appEvent = $A.get("e.c:FBCloseEvent");
                appEvent.setParams({ "closeModel": closeModel, "isUpdateRecord": isUpdateRecord, "modelName": vDragId, "signData":signData, "Successstatus":state});                
                appEvent.fire();
            }
            
        });
        $A.enqueueAction(action);
    },
    crudModalEvent: function(component, event, closeModel, isUpdateRecord) {
        var vDragId = 'Signature';
        var appEvent = $A.get("e.c:FBCloseEvent");
        appEvent.setParams({ "closeModel": closeModel, "isUpdateRecord": isUpdateRecord, "modelName": vDragId, "signData":"" });
        appEvent.fire();
    },
    showToastHelper:function(component,title,type,message){        
        var toastEvent = $A.get("e.force:showToast");
        if(toastEvent!=undefined && toastEvent!=null){
            toastEvent.setParams({
                title: title,
                message: message,
                duration: ' 5000',
                type: type,
                mode: 'dismissible'
            });
            toastEvent.fire();    
        }
        else{
            $A.createComponent("c:FBToast",{"msgbody": message,"msgtype": type},function(newToast, status, errorMessage){                
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newToast);
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            });
        }
    
    }

})