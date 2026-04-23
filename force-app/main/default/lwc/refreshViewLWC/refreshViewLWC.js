import { LightningElement, track, api, wire } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import RefreshEventMessageChannel from '@salesforce/messageChannel/RefreshEvent__c';
import { RefreshEvent } from 'lightning/refresh';
import { disablePullToRefresh } from 'c/utilJS';

export default class RefreshViewLWC extends LightningElement {

    @api recordId;

    @track subscription;



    @wire(MessageContext)
    messageContext;


    connectedCallback() {
        this.subscription = subscribe(
            this.messageContext,
            RefreshEventMessageChannel,
            () => {
                this.dispatchEvent(new RefreshEvent());
                notifyRecordUpdateAvailable([this.recordId]);
            }
        );
        disablePullToRefresh(this);
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

}