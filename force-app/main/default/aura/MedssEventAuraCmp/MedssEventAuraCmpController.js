({
    // Read the message argument to get the values in the message payload
    handleChanged: function(cmp, message, helper) {
        console.log('handle change');
        var closeTab = message.getParam("closeTabInSalesforce");
        if (closeTab == true) {
            console.log('handle change'+closeTab);
            helper.closeFocusedTab(cmp,message,helper);
        }
    },

})
