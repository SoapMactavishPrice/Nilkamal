import { LightningElement, api, track } from 'lwc';
import { showToast } from 'c/utilJS';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import processSalesOrder from '@salesforce/apex/IntegrationHandler.sendSalesOrderRequest';
import validateQuoteItems from '@salesforce/apex/IntegrationHandler.validateQuoteItems';

export default class SendSalesOrder extends LightningElement {
    @api recordId;
    @track isLoading = false;
    // handleClick() {
    //     this.isLoading = true
    //     //let quoteId = this.recordId; // Replace with dynamic Quote Id
    //     console.log('OUTPUT : ', this.recordId);


    //     processSalesOrder({ quoteId: this.recordId })
    //         .then(result => {
    //             this.responseMessage = result;
    //             this.isLoading = false;
    //             notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
    //         })
    //         .catch(error => {
    //             this.responseMessage = 'Error: ' + error.body.message;
    //             showToast(this, 'Error', 'Error:', 'error', error);
    //             this.isLoading = false;
    //         });
    // }

    handleClick() {
        this.isLoading = true;
        console.log('Record ID: ', this.recordId);

        // Step 1: Validate quote service items first
        validateQuoteItems({ quoteId: this.recordId })
            .then(isValid => {
                if (!isValid) {
                    this.isLoading = false;
                    // showToast(this, 'Error', 'Error: AMC Start Date and AMC Period are required for AMC/CAMC items.', 'error', error);
                    showToast(this, 'Error', 'Error: AMC Start Date and AMC Period are required for AMC/CAMC items.', 'error');
                    return;
                }
                processSalesOrder({ quoteId: this.recordId })
                    .then(result => {
                        this.responseMessage = result;
                        this.isLoading = false;
                        notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                    })
                    .catch(error => {
                        this.responseMessage = 'Error: ' + error.body.message;
                        showToast(this, 'Error', 'Error:', 'error', error);
                        this.isLoading = false;
                    });
            })
    }
}