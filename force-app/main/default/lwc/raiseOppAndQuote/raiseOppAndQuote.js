import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';

import { showToast, navigateToRecord, navigateToRecordWithoutHistory, navigateToObjectPageWithoutHistory, navigateBackInHistory, disablePullToRefresh } from 'c/utilJS';

import raiseOppAndQuote from '@salesforce/apex/RaiseOppAndQuoteController.raiseOppAndQuote';



export default class RaiseOppAndQuote extends NavigationMixin(LightningElement) {

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (value && this.type) {
            this.handleRaiseOppAndQuote();
        }
    }

    @api
    get type() {
        return this._type;
    }
    set type(value) {
        this._type = value;
        if (this.recordId && value) {
            this.handleRaiseOppAndQuote();
        }
    }


    @track showSpinner = true;


    @wire(CurrentPageReference)
    currentPageReference({ state }) {
        const { c__recordId, c__type } = state;
        if (c__recordId) this.recordId = c__recordId;
        if (c__type) this.type = c__type;
    }


    connectedCallback() {
        console.log('connectedCallback from RaiseOppAndQuote');
        disablePullToRefresh(this);
    }

    handleRaiseOppAndQuote() {
        debugger;
        this.showSpinner = true;
        raiseOppAndQuote({
            recordId: this.recordId,
            type: this.type
        })
            .then(result => {
                console.log(result);
                if (result && Array.isArray(result)) {
                    navigateToObjectPageWithoutHistory(this, 'Quote', 'home'); // , { filterName: 'Recent' });
                } else {
                    navigateToRecordWithoutHistory(this, result);
                }
            })
            .catch(error => {
                console.log(error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
                navigateBackInHistory(this);
                // this.dispatchEvent(new CloseActionScreenEvent());
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

}