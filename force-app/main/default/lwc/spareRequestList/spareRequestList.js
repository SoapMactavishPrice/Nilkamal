import { LightningElement, wire, track } from 'lwc';
import getSpareReturns from '@salesforce/apex/SpareRequestController.getSpareReturns';
import updateSpareReturns from '@salesforce/apex/SpareRequestController.updateSpareReturns';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const columns = [
    { label: 'Name', fieldName: 'Name', type: 'text', editable: true },
    { label: 'Item Description', fieldName: 'Item_Description__c', type: 'text', editable: true },
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
];

export default class SpareReturnList extends LightningElement {
    @track spareReturns = [];
    @track draftValues = [];
    columns = columns;
    wiredRecords;

    @wire(getSpareReturns)
    wiredSpareReturns(result) {
        this.wiredRecords = result;
        if (result.data) {
            this.spareReturns = result.data;
        } else if (result.error) {
            console.error('Error fetching data:', result.error);
        }
    }

    handleSave(event) {
        const updatedFields = event.detail.draftValues;

        updateSpareReturns({ spareReturns: updatedFields })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Records updated successfully',
                        variant: 'success'
                    })
                );

                return refreshApex(this.wiredRecords);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error updating records',
                        variant: 'error'
                    })
                );
                console.error(error);
            })
            .finally(() => {
                this.draftValues = [];
            });
    }
}