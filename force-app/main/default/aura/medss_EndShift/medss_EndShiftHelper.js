({
    reQueueCase : function(component, event, helper) {
        console.log(' inside requeue');
        console.log('rec id'+component.get("v.recordId"));
        var artId = component.get("v.recordId");
        console.log('art '+artId);
        var action = component.get("c.updateOwnerForCase");   
        action.setParams({
            "caseRecordId":artId
        });
        $A.enqueueAction(action);
    },

    logOutAndRequeue: function(cmp, evt, hlp) {
        var omniAPI = cmp.find("omniToolkit");
        omniAPI.logout().then(function(result) {
            if (result) {
                console.log("Logout successful");
                hlp.reQueueCase(cmp,evt,hlp);
                hlp.showToast(cmp,evt,hlp);
                
                setTimeout(hlp.closeFocusedTab(cmp,evt,hlp), 800);
            } else {
                console.log("Logout failed");
            }
        }).catch(function(error) {
            console.log(error);
        });

        
    },

    showToast : function(component, event, helper) {
        var confirmationMessage = $A.get("$Label.c.Medss_EndShift_Confirmation_Message");
        console.log(' inside toast');
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": confirmationMessage
        });
        toastEvent.fire();
    },

    closeFocusedTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        console.log("MIKE Inside close tab function!");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            if(response.tabId != null) {
                var focusedTabId = response.tabId;
                workspaceAPI.closeTab({tabId: focusedTabId});
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    }
})