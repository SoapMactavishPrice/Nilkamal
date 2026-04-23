import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { RefreshEvent } from 'lightning/refresh';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import { showToast, disablePullToRefresh, navigateBackInHistory, navigateToLWC, navigateToObjectPage, navigateToRecord, navigateToRelatedList } from 'c/utilJS';

import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';

import getServiceRequestsByWorkOrder from '@salesforce/apex/FieldServiceEditServiceRequestController.getServiceRequestsByWorkOrder';
import deleteServiceRequest from '@salesforce/apex/FieldServiceEditServiceRequestController.deleteServiceRequest';
import saveServiceRequests from '@salesforce/apex/FieldServiceEditServiceRequestController.saveServiceRequests';
import raiseOppAndQuote from '@salesforce/apex/RaiseOppAndQuoteController.raiseOppAndQuote';
import getWarrantyMapping from '@salesforce/apex/FieldServiceEditServiceRequestController.getWarrantyMapping';

import SERVICE_REQUEST_OBJECT from '@salesforce/schema/Service_Request__c';
import WARRANTY_FIELD from '@salesforce/schema/Service_Request__c.Warranty_Period__c';





export default class FieldServiceEditServiceRequest extends NavigationMixin(LightningElement) {

    @track workOrderId;
    @track caseId;
    @track serviceAppointmentId;

    @track serviceRequests = [];
    @track showSpinner = false;
    @track hasNoServiceRequests = false;
    @track showDeleteModal = false;
    @track recordToDeleteId = null;
    @track warrantyOptions = [];

    @wire(getObjectInfo, { objectApiName: SERVICE_REQUEST_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: WARRANTY_FIELD })
    wiredWarrantyOptions({ data, error }) {
        if (data) {
            this.warrantyOptions = data.values.map(option => ({
                label: option.label,
                value: option.value
            }));
        } else if (error) {
            console.error('Error loading Warranty_Period__c picklist values:', error);
        }
    }



    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.workOrderId = currentPageReference.state.c__workOrderId;
        this.caseId = currentPageReference.state.c__caseId;
        this.serviceAppointmentId = currentPageReference.state.c__serviceAppointmentId;
        console.log('workOrderId', this.workOrderId);
        this.fetchServiceRequests();
    }


    @track warrantyData = [];
    connectedCallback() {
        // this.fetchServiceRequests();
        disablePullToRefresh(this);
        this.fetchWarrantyMapping(); // onload
    }

    @track warrantyMap = {};
    fetchWarrantyMapping() {
        getWarrantyMapping()
            .then(result => {
                this.warrantyMap = result;
            })
            .catch(error => {
                console.error('Error fetching warranty mapping:', error);
            });
    }

    fetchServiceRequests() {
        this.showSpinner = true;
        this.hasNoServiceRequests = false;
        console.log('this.workOrderId', this.workOrderId);
        getServiceRequestsByWorkOrder({ workOrderId: this.workOrderId })
            .then(result => {
                // this.serviceRequests = JSON.parse(JSON.stringify(result));

                let recs = [];
                for (var i = 0; i < result.length; i++) {

                    let opp = Object.assign({}, result[i]);
                    opp.isEditable = opp.Name.includes('AMC') ? true : false
                    opp.currency = opp.CurrencyIsoCode // Default to USD if currency is missing
                    recs.push(opp);
                }
                this.serviceRequests = recs;


                console.log('Fetched Service Requests:', this.serviceRequests);
                this.hasNoServiceRequests = !this.serviceRequests || this.serviceRequests.length === 0;
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
                this.hasNoServiceRequests = true;
                console.error('Error fetching spare requests:', error);
            });
    }

    handleBack() {
        navigateBackInHistory(this);
    }

    handleCancel() {
        navigateBackInHistory(this);
    }

    handleDeleteClick(event) {
        const recordId = event.currentTarget.dataset.id;
        this.recordToDeleteId = recordId;
        this.showDeleteModal = true;
    }

    handleDeleteClick(event) {
        this.recordToDeleteId = event.target.dataset.id;
        this.showDeleteModal = true;
    }

    closeDeleteModal() {
        this.showDeleteModal = false;
        this.recordToDeleteId = null;
    }

    handleFieldChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.dataset.field;
        const value = event.target.value;
        console.log('handleFieldChange', 'index', index, 'field', field, 'value', value);

        this.serviceRequests[index][field] = value;

        if (field === 'Price__c' || field === 'Quantity__c') {
            const price = parseFloat(this.serviceRequests[index].Price__c) || 0;
            const quantity = parseFloat(this.serviceRequests[index].Quantity__c) || 0;
            this.serviceRequests[index].Total_Value__c = price * quantity;
        }

        this.checkForChanges();
    }

    checkForChanges() {
        this.hasChanges = JSON.stringify(this.serviceRequests) !==
            JSON.stringify(this.originalServiceRequests);
    }


    confirmDelete() {
        this.showSpinner = true;
        console.log(
            'recordToDeleteId',
            this.recordToDeleteId);

        deleteServiceRequest({ recordId: this.recordToDeleteId })
            .then(() => {
                showToast(this, 'Success', 'Service request deleted successfully.', 'success');
                this.fetchServiceRequests();
            })
            .catch(error => {
                showToast(this, 'Error', error.body?.message || 'Failed to delete service request', 'error');
            })
            .finally(() => {
                this.showSpinner = false;
                this.closeDeleteModal();
            });
    }

    handleSave() {
        // this.showSpinner = true;
        console.log('serviceRequests', this.serviceRequests);
        saveServiceRequests({ serviceRequests: this.serviceRequests })
            .then(() => {
                showToast(this, 'Success', 'Service requests updated successfully.', 'success');
                this.fetchServiceRequests();
            })
            .catch(error => {
                showToast(this, 'Error', error.body?.message || 'Failed to save changes.', 'error');
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleQuantityButtonClick(event) {
        const index = event.currentTarget.dataset.index;
        const delta = parseInt(event.currentTarget.dataset.delta);
        const currentValue = parseInt(this.serviceRequests[index].Quantity__c) || 0;
        const newValue = Math.max(0, currentValue + delta);

        this.serviceRequests[index].Quantity__c = newValue;
        this.recalculateTotalValue(index);

        // Force template update
        this.serviceRequests = [...this.serviceRequests];
    }

    recalculateTotalValue(index) {
        const price = parseFloat(this.serviceRequests[index].Price__c) || 0;
        const quantity = parseFloat(this.serviceRequests[index].Quantity__c) || 0;
        this.serviceRequests[index].Total_Value__c = (price * quantity).toFixed(2);

        if (this.template.querySelector(`[data-index="${index}"][data-field="Quantity__c"]`)) {
            this.template.querySelector(`[data-index="${index}"][data-field="Quantity__c"]`).value = quantity;
        }
        if (this.template.querySelector(`[data-index="${index}"][data-field="Price__c"]`)) {
            this.template.querySelector(`[data-index="${index}"][data-field="Price__c"]`).value = price;
        }
    }

    handleCreateQuoteClick(event) {
        console.log('handleCreateQuoteClick', 'event', event);

        this.showSpinner = true;
        raiseOppAndQuote({ recordId: this.workOrderId, serviceAppointmentId: this.serviceAppointmentId, type: 'service' })
            .then(result => {
                console.log('result', result);
                console.log('caseId ', this.caseId);
                try {
                    this.dispatchEvent(new RefreshEvent());
                    notifyRecordUpdateAvailable([{ recordId: this.caseId }]);
                } catch (error) { }
                navigateToRelatedList(this, this.caseId, 'Case', 'Quotes__r');

            })
            .catch(error => {
                console.log(error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleChange(event) {
        const index = event.target.dataset.index;
        this.serviceRequests[index].Warranty_Period__c = event.detail.value;
        const selectedWarranty = event.detail.value;
        // Get PM and BD values from warrantyMap
        console.log('this.warrantyMap[selectedWarranty] ', this.warrantyMap[selectedWarranty]);

        if (this.warrantyMap && this.warrantyMap[selectedWarranty]) {
            const mapping = this.warrantyMap[selectedWarranty];
            this.serviceRequests[index].Number_of_PM_Visit__c = mapping.PM;
            this.serviceRequests[index].Number_of_Breakdown_Visit__c = mapping.BD;
        } else {
            // If no mapping found, optionally reset or clear values
            this.serviceRequests[index].Number_of_PM_Visit__c = '';
            this.serviceRequests[index].Number_of_Breakdown_Visit__c = '';
        }
        console.log(JSON.stringify(this.serviceRequests));

    }
    handlePmChange(event) {
        const index = event.target.dataset.index;
        this.serviceRequests[index].Number_of_PM_Visit__c = event.target.value;
        console.log(JSON.stringify(this.serviceRequests));

    }
    handlebreakChange(event) {
        const index = event.target.dataset.index;
        this.serviceRequests[index].Number_of_Breakdown_Visit__cs = event.target.value;
        console.log(JSON.stringify(this.serviceRequests));

    }


}