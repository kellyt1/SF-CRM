({
    init: function (component, event, helper) {
        $A.get('e.force:navigateToURL')
            .setParams({
                url: component.get('v.urlString')
            })
            .fire();
    }
});
