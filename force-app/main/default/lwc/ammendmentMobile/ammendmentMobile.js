import { LightningElement, track, api, wire } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { RefreshEvent } from 'lightning/refresh';

import { showToast } from 'c/utilJS';

import createQuoteAndRelated from '@salesforce/apex/createVersionController.createQuoteAndRelated';


export default class AmmendmentMobile extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track showSpinner = false;
    @track ResponseMessage = '';
    @track quoteName = '';
    @track quoteId = '';
    @track errorResponseMessage = '';

    connectedCallback() {
        // this.showSpinner=true;
        // setTimeout(() => {
        //     console.log('this.recordId ',this.recordId);
        //     createQuoteAndRelated({quoteId:this.recordId})
        // .then((result)=>{
        //     console.log('result ',result);
        //     this.showSpinner=false;
        //     if(result.includes('true')){
        //         var after_ = result.slice(result.indexOf(',') + 1);
        //         this.quoteId='/lightning/r/Quote/'+after_+'/view';
        //         // console.log('this.quoteId '+this.quoteId);
        //         // this.ResponseMessage='Quote cloned successfully';

        //         //this.dispatchEvent(new CloseActionScreenEvent());
        //         // location.reload(true);
        //         // navigateToRecord(this, this.quoteId);
        //         //window.location.href='/lightning/r/Quote/'+after_+'/view'

        //     }else{
        //         this.errorResponseMessage=result;
        //     }
        //     console.log('ResponseMessage',this.ResponseMessage);
        //     console.log('errorResponseMessage',this.errorResponseMessage);
        // })
        // .catch((error) =>{
        //     console.log('= erorr',error);
        //     this.showSpinner=false;
        // })
        // }, 2000);

    }

    closeModal(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleClick() {
        this.showSpinner = true;
        setTimeout(() => {
            console.log('this.recordId ', this.recordId);
            createQuoteAndRelated({ quoteId: this.recordId })
                .then((result) => {
                    console.log('result ', result);
                    this.showSpinner = false;
                    if (result.includes('true')) {
                        try {
                            this.dispatchEvent(new RefreshEvent());
                            notifyRecordUpdateAvailable([this.recordId]);
                        } catch (error) { }

                        var after_ = result.slice(result.indexOf(',') + 1);
                        this.quoteId = '/lightning/r/Quote/' + after_ + '/view';
                        // console.log('this.quoteId '+this.quoteId);
                        // this.ResponseMessage='Quote cloned successfully';

                        //this.dispatchEvent(new CloseActionScreenEvent());
                        // location.reload(true);
                        // navigateToRecord(this, this.quoteId);
                        //window.location.href='/lightning/r/Quote/'+after_+'/view'

                    }
                    else {
                        this.errorResponseMessage = result;
                    }
                    console.log('ResponseMessage', this.ResponseMessage);
                    console.log('errorResponseMessage', this.errorResponseMessage);
                })
                .catch((error) => {
                    console.log('Error', error);
                    showToast(this, 'Error', 'Something went wrong', 'error', error);
                    try {
                        this.errorResponseMessage = error.body.message;
                    } catch (error) { }
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }, 2000);

    }
}