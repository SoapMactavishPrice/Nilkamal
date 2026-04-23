import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { RefreshEvent } from 'lightning/refresh';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import { showToast, disablePullToRefresh, navigateToLWC, navigateBackInHistory, navigateToObjectPage, navigateToRecord, navigateToRelatedList } from 'c/utilJS';

// import { isSalesforce1 } from 'lightning/clientSupport';

import getSpareRequestsByWorkOrder from '@salesforce/apex/FieldsServiceEditSpareRequest.getSpareRequestsByWorkOrder';
import getStatusList from '@salesforce/apex/FieldsServiceEditSpareRequest.getStatusList';
import saveSpareRequests from '@salesforce/apex/FieldsServiceEditSpareRequest.saveSpareRequestChanges';
import deleteSpareRequest from '@salesforce/apex/FieldsServiceEditSpareRequest.deleteSpareRequest';
import raiseOppAndQuote from '@salesforce/apex/RaiseOppAndQuoteController.raiseOppAndQuote';

import SERVICE_REQUEST_OBJECT from '@salesforce/schema/Spare_Request__c';
import WARRANTY_FIELD from '@salesforce/schema/Spare_Request__c.Warranty_Period__c';





export default class FieldServiceEditSpareRequest extends NavigationMixin(LightningElement) {

    @track workOrderId;
    @track caseId;
    @track serviceAppointmentId;

    @track spareRequests = [];
    @track activeSections = [];
    @track statusOptions = [];
    @track firstSpareId = '';
    @track isEmptySpareRequests = false;
    @track showDeleteModal = false;
    @track recordToDeleteId = null;
    @track warrantyOptions = [];


    @wire(getObjectInfo, { objectApiName: SERVICE_REQUEST_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: WARRANTY_FIELD })
    wiredWarrantyOptions({ data, error }) {
        if (data) {
            this.warrantyOptions = data.values.map(opt => ({
                label: opt.label,
                value: opt.value
            }));
        } else if (error) {
            console.error('Error loading warranty picklist values:', error);
        }
    }



    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.workOrderId = currentPageReference.state.c__workOrderId;
        this.caseId = currentPageReference.state.c__caseId;
        this.serviceAppointmentId = currentPageReference.state.c__serviceAppointmentId;
        this.fetchSpareRequests();
    }

    connectedCallback() {
        // this.fetchSpareRequests();
        // this.loadPicklistValues();
        disablePullToRefresh(this);
    }

    loadPicklistValues() {
        getStatusList()
            .then((result) => {
                console.log('getStatusList : ', JSON.parse(result));
                this.statusOptions = JSON.parse(result);
            })
    }

    fetchSpareRequests() {
        getSpareRequestsByWorkOrder({ workOrderId: this.workOrderId })
            .then(result => {
                // this.spareRequests = JSON.parse(JSON.stringify(result));
                let recs = [];
                for (var i = 0; i < result.length; i++) {

                    let opp = Object.assign({}, result[i]);
                    // opp.isEditable = opp.Name.includes('AMC') ? true : false
                    // var warValue = opp.Item_Master__r.Warranty__c;
                    var warValue = opp.Warranty_Period__c;
                    // opp.isEditable = warValue != null && warValue == 'Y' ? true : false
                    opp.isEditable = warValue != null ? true : false
                    opp.currency = opp.CurrencyIsoCode // Default to USD if currency is missing
                    recs.push(opp);
                }
                this.spareRequests = recs;
                console.log('Fetched Spare Requests:', this.spareRequests);
                if (this.spareRequests && this.spareRequests.length > 0) {
                    this.firstSpareId = this.spareRequests[0].Id;
                    this.activeSections = this.spareRequests.map(item => item.Id);
                    this.isEmptySpareRequests = false;
                }
                else {
                    this.isEmptySpareRequests = true;
                }
            })
            .catch(error => {
                console.error('Error fetching spare requests:', error);
                this.isEmptySpareRequests = true;
            });
    }

    handleChange(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        console.log('Field changed:', fieldName, 'New value:', fieldValue);


        // Find the specific record that was updated and update the corresponding field
        const recordId = event.target.dataset.id;
        console.log('Record ID:', recordId);

        const record = this.spareRequests.find(spare => spare.Id === recordId);
        if (record) {
            console.log('Before update:', record);
            record[fieldName] = fieldValue;
            console.log('After update:', record);
        } else {
            console.log('Record not found for ID:', recordId);
        }
    }

    handleBack() {
        navigateBackInHistory(this);
    }

    handleCancel() {
        navigateBackInHistory(this);
    }

    get isMobile() {
        return navigator.userAgent.includes('SalesforceMobileSDK') ||
            window.innerWidth <= 768;
    }


    @track showSpinner;
    handleCreateQuoteClick() {
        this.showSpinner = true;
        raiseOppAndQuote({ recordId: this.workOrderId, serviceAppointmentId: this.serviceAppointmentId, type: 'spare' })
            .then(result => {
                console.log(result);
                if (result && Array.isArray(result)) {
                    console.log('caseId ', this.caseId);
                    try {
                        this.dispatchEvent(new RefreshEvent());
                        notifyRecordUpdateAvailable([{ recordId: this.caseId }]);
                    } catch (error) { }
                    navigateToRelatedList(this, this.caseId, 'Case', 'Quotes__r');
                }
                else {
                    navigateToRecord(this, result);
                }
            })
            .catch(error => {
                console.log(error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }


    handleQuantityButtonClick(event) {
        const index = event.currentTarget.dataset.index;
        const delta = parseInt(event.currentTarget.dataset.delta);
        const currentValue = parseInt(this.spareRequests[index].Quantity_Required__c) || 0;
        const newValue = Math.max(0, currentValue + delta);

        if (newValue != 0) {
            this.spareRequests[index].Quantity_Required__c = newValue;
            this.recalculateTotalValue(index);
            this.checkForChanges();

            this.spareRequests = [...this.spareRequests];
        }
    }


    handleFieldChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.dataset.field;
        let value = event.target.value;

        // Special handling for quantity field
        if (field === 'Quantity_Required__c') {
            value = Math.max(0, Math.floor(parseFloat(value) || 0));
            event.target.value = value;
        }
        // Special handling for billed value (currency)
        else if (field === 'Billed_Value__c') {
            value = parseFloat(value) || 0;
        }

        this.spareRequests[index][field] = value;

        // Recalculate total if quantity or billed value changes
        if (field === 'Quantity_Required__c' || field === 'Billed_Value__c') {
            this.recalculateTotalValue(index);
        }

        this.checkForChanges();
    }

    recalculateTotalValue(index) {
        const quantity = parseFloat(this.spareRequests[index].Quantity_Required__c) || 0;
        const billedValue = parseFloat(this.spareRequests[index].Billed_Value__c) || 0;
        this.spareRequests[index].Total_Value__c = (quantity * billedValue).toFixed(2);
    }

    handleKeyDown(event) {
        // Prevent non-numeric input for quantity field
        if (!/^\d$/.test(event.key) &&
            !['Backspace', 'Tab', 'ArrowLeft', 'ArrowRight', 'Delete'].includes(event.key)) {
            event.preventDefault();
        }

        // Prevent negative numbers
        if (event.key === '-' || event.key === '+' || event.key === 'e') {
            event.preventDefault();
        }
    }

    checkForChanges() {
        this.hasChanges = JSON.stringify(this.spareRequests) !==
            JSON.stringify(this.originalSpareRequests);
    }

    handleSave() {
        this.showSpinner = true;
        saveSpareRequests({ spareRequests: this.spareRequests })
            .then(() => {
                showToast(this, 'Success', 'Spare request saved successfully.', 'success');
                // this.showToast('Success', 'Spare requests saved successfully', 'success');
                // this.fetchSpareRequests(); // Refresh data

            })
            .catch(error => {
                showToast(this, 'Error', error.body?.message || 'Error saving spare requests.', 'error');
                // this.showToast('Error', error.body?.message || 'Error saving spare requests.', 'error');
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleDeleteClick(event) {
        console.log(
            'handleDeleteClick',
            'index',
            event.currentTarget.dataset.index,
            'id',
            event.currentTarget.dataset.id);

        this.recordToDeleteId = event.currentTarget.dataset.id;
        this.showDeleteModal = true;
    }

    confirmDelete() {
        this.showSpinner = true;
        console.log(
            'recordToDeleteId',
            this.recordToDeleteId);

        deleteSpareRequest({ recordId: this.recordToDeleteId })
            .then(() => {
                showToast(this, 'Success', 'Spare request deleted successfully.', 'success');
                // this.showToast('Success', 'Spare request deleted successfully', 'success');
                this.fetchSpareRequests(); // Refresh data
            })
            .catch(error => {
                showToast(this, 'Error', error.body?.message || 'Failed to delete Spare request', 'error');
                // this.showToast('Error', error.body?.message || 'Error deleting spare request', 'error');
            })
            .finally(() => {
                this.showSpinner = false;
                this.showDeleteModal = false;
                this.recordToDeleteId = null;
            });
    }

    closeDeleteModal() {
        this.showDeleteModal = false;
        this.recordToDeleteId = null;
    }

    handleChange(event) {
        const index = event.target.dataset.index;
        this.spareRequests[index].Warranty_Period__c = event.target.value;
        // console.log(JSON.stringify(this.serviceRequests));

    }
    handlePmChange(event) {
        const index = event.target.dataset.index;
        this.spareRequests[index].Number_of_PM_Visit__c = event.target.value;
        // console.log(JSON.stringify(this.serviceRequests));

    }
    handlebreakChange(event) {
        const index = event.target.dataset.index;
        this.spareRequests[index].Number_of_Breakdown_Visit__c = event.target.value;
        // console.log(JSON.stringify(this.serviceRequests));

    }




}