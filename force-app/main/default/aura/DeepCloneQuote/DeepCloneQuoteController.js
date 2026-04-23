({
    cloneQuote: function (component, event, helper) {
        const recordId = component.get("v.recordId");
        console.log('recordId', recordId);

        const action = component.get("c.deepCloneQuote");
        action.setParams({ quoteId: recordId });

        action.setCallback(this, response => {
            const state = response.getState();
            if (state === "SUCCESS") {
                const clonedQuoteId = response.getReturnValue();
                const pageReference = {
                    type: "standard__recordPage",
                    attributes: {
                        recordId: clonedQuoteId,
                        objectApiName: "Quote",
                        actionName: "view"
                    }
                };
                console.log('PARENT -> ', pageReference);
                component.find("navService").navigate(pageReference);
            }
            else {
                const errors = response.getError();
                console.error("Failed to clone quote: ", errors);

                const toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "Error",
                    message: "Failed to clone quote: " + (errors && errors[0] ? errors[0].message : ''),
                    type: "error"
                });
                toastEvent.fire();

                const dismissActionPanel = $A.get("e.force:closeQuickAction");
                if (dismissActionPanel) {
                    dismissActionPanel.fire();
                }
            }
        });

        $A.enqueueAction(action);
    }
})