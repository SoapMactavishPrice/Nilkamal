// ({
//     myAction : function(component, event, helper) {

//     }
// })
({
    init: function (component, event, helper) {
        var pageReference = component.get("v.pageReference");
        component.set("v.refRecordId", pageReference.state.c__refRecordId);
        component.set("v.sObjectName", pageReference.state.c__refsObjectName);
    },
    reInit: function (component, event, helper) {
        console.log('This is fire');
        // $A.get('e.force:refreshView').fire();
        component.set("v.refRecordId", component.get("v.refRecordId"));
        component.set("v.sObjectName", component.get("v.sObjectName"));
    }
})