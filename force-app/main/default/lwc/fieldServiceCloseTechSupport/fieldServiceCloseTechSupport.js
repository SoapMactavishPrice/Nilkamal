import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { MessageContext } from 'lightning/messageService';

import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, navigateToRecord, publishRefreshEvent, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, disablePullToRefresh, scrollToElement } from 'c/utilJS';


import closeTechSupport from '@salesforce/apex/FieldServiceCloseTechSupportController.closeTechSupport';



export default class FieldServiceCloseTechSupport extends NavigationMixin(LightningElement) {

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        console.log('recordId', this._recordId);
        this.handleCloseTechSupport();
    }
    @api objectApiName;


    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.recordId = currentPageReference?.state?.c__recordId;
        }
        if (currentPageReference?.state?.c__objectApiName) {
            this.objectApiName = currentPageReference?.state?.c__objectApiName;
        }
    }

    @wire(MessageContext)
    messageContext;



    handleCloseTechSupport() {
        console.log('handleCloseTechSupport');
        closeTechSupport({ recordId: this.recordId })
            .then((result) => {
                console.log('result', result);
                if (result.includes('Success')) {
                    showToast(this, 'Success', 'Technical support request has been closed successfully. If the Service Engineer adds a comment or creates a new post, the request will be reopened automatically.', 'success');
                }
                else {
                    showToast(this, 'Info', result, 'info');
                }
            })
            .catch((error) => {
                console.log('error', error);
                showToast(this, 'Error', error, 'error', error);
            })
            .finally(() => {
                publishRefreshEvent(this);
                navigateToRecord(this, this.recordId, this.objectApiName);
            });
    }


}