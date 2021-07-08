({
    showMedssWindowAlert : function(component, event) {

        //Fire a toast message to alert users that they should log out of any open MEDSS tabs
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Alert!",
            "type": "Warning",
            "mode": "sticky",
            "message": $A.get("$Label.c.Log_out_of_Medss_Reminder")
        });
        toastEvent.fire();
    }
})