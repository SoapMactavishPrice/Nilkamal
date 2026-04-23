import { LightningElement, track, api, wire } from 'lwc';
import ToastContainer from 'lightning/toastContainer';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningModal from 'lightning/modal';
import { getNameAndValueOnChange } from 'c/utilJS';
import { showToast } from 'c/utilJS';
import { disablePullToRefresh } from 'c/utilJS';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import submitLeaveApplication from '@salesforce/apex/MarkLeaveController.submitLeaveApplication';

export default class FieldServiceMarkLeave extends NavigationMixin(LightningElement) {

    @track formData = {
        LeaveFrom: '',
        LeaveTo: '',
        Remark: ''
    };
    @track approver;
    @track fileData;
    @track todayDate = new Date().toISOString().split('T')[0];
    @track leaveToDate;
    @track showSpinner = true;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.resetForm();
        }
    }

    connectedCallback() {
        this.resetForm();
        disablePullToRefresh(this);
        this.showSpinner = false;
    }


    handleChange(event) {
        const fieldName = event.target.name;
        const value = event.target.value;
        this.formData[fieldName] = value;
        if (fieldName === 'LeaveFrom' && this.formData.LeaveFrom) {
            this.leaveToDate = this.formData.LeaveFrom;
        }
    }



    handleApply() {
        if (!this.formData.LeaveFrom || !this.formData.LeaveTo) {
            showToast(this, 'Error', 'Please fill in all required fields.', 'error');
            return;
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const leaveFromDate = new Date(this.formData.LeaveFrom);
        const leaveToDate = new Date(this.formData.LeaveTo);

        if (leaveFromDate <= today) {
            showToast(this, 'Error', 'Leave From date must be today or later.', 'error');
            return;
        }

        if (leaveToDate < leaveFromDate) {
            showToast(this, 'Error', 'Leave To date must be after Leave From.', 'error');
            return;
        }

        console.log('this.formData', this.formData);
        this.showSpinner = true;
        submitLeaveApplication({ leaveData: this.formData })
            .then(() => {
                showToast(this, 'Success', 'Leave application submitted successfully.', 'success');
                this.resetForm();
                this.navigateToLWC();
            })
            .catch((error) => {
                console.error('Error submitting leave application:', error);
                showToast(this, 'Error', 'Failed to submit leave application.', 'error');
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    resetForm() {
        this.formData = {
            LeaveFrom: '',
            LeaveTo: '',
            Remark: ''
        };
        this.fileData = null;
        this.leaveToDate = '';
    }

    navigateToLWC() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__fieldServiceHome'
            }
        });
    }
}