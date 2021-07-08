({
    init: function(component, event, helper) {
        var omniAPI = component.find("omniToolkit");
        omniAPI.getServicePresenceStatusId().then(function(result) {
            console.log('Status Id is: ' + result.statusId);
            console.log('Status Name is: ' + result.statusName);
            console.log('Status APIName is: ' + result.statusApiName);
            if(result.statusName == 'Receive Inbound Calls'){
                component.set("v.isReceiveInboundCallStatus", true);
                helper.showMedssWindowAlert(event);
            } else if(result.statusName == 'Ready'){
                helper.showMedssWindowAlert(event);
            }
        }).catch(function(error) {
            console.log(error);
        });

    },
    
    openMedssWindow: function (component, event) {
        $A.get('e.force:navigateToURL')
            .setParams({
                url: $A.get("$Label.c.Home_Page_MEDSS_URL")
            })
            .fire();
    },

    onStatusChanged: function(component, event, helper) {
        var omniAPI = component.find("omniToolkit");
        omniAPI.getServicePresenceStatusId().then(function(result) {
            console.log('Status Id is: ' + result.statusId);
            console.log('Status Name is: ' + result.statusName);
            console.log('Status APIName is: ' + result.statusApiName);
            if(result.statusName == 'Receive Inbound Calls'){
                component.set("v.isReceiveInboundCallStatus", true);
                helper.showMedssWindowAlert(event);
            } else if(result.statusName == 'Ready'){
                component.set("v.isReceiveInboundCallStatus", false);
                helper.showMedssWindowAlert(event);
            } else{
                component.set("v.isReceiveInboundCallStatus", false);
            }
        }).catch(function(error) {
            console.log(error);
        });
    }
})