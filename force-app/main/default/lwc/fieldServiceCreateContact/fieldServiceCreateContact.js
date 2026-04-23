import { LightningElement, track, api, wire } from 'lwc';
import LightningModal from 'lightning/modal';

import { showToast, getNameAndValueOnChange, closeQuickActionPopup, getShowToastEvents } from 'c/utilJS';

import createContact from '@salesforce/apex/FieldServiceCreateContact.createContact';



export default class FieldServiceCreateContact extends LightningModal {

    @track showSpinner = false;

    @api accountId;

    @api assetId;
    @api caseId;
    @api serviceAppointmentId;

    @track contactRecord = {};

    @track salutation = '';

    get salutationOptions() {
        return [
            { label: 'Mr.', value: 'Mr.' },
            { label: 'Mrs.', value: 'Mrs.' }
        ];
    }



    handleChange(event) {
        const { name, value } = getNameAndValueOnChange(this, event);
        if (name === 'MobilePhone') {
            console.log('MobilePhone', value);
            const numericValue = value.replace(/\D/g, '');
            // this.contactRecord = { ...this.contactRecord, MobilePhone: numericValue };
            if (!numericValue) {
                this.contactRecord = { ...this.contactRecord, MobilePhone: '' };
            } else {
                this.contactRecord = { ...this.contactRecord, MobilePhone: numericValue };
            }
        } else {
            this.contactRecord[name] = value;
        }
        // this.contactRecord[name] = value;
    }

    // handlePhoneInput(event) {
    //     const input = event.target;
    //     const cleanedValue = input.value.replace(/\D/g, ''); // Remove non-digits

    //     input.value = cleanedValue;

    //     // Optionally update your contact record if needed
    //     if (input.fieldName === 'MobilePhone') {
    //         this.contactRecord.MobilePhone = cleanedValue;
    //     }
    // }

    handlePhoneInput(event) {
    const input = event.target;
    const cleanedValue = input.value.replace(/\D/g, ''); // Remove non-digit characters

    // Trim to 10 digits
    if (cleanedValue.length > 10) {
        input.value = cleanedValue.slice(0, 10);
        this.contactRecord.MobilePhone = cleanedValue.slice(0, 10);
    } else {
        input.value = cleanedValue;
        this.contactRecord.MobilePhone = cleanedValue;
    }

    // Live error message
    if (cleanedValue.length !== 10) {
        input.setCustomValidity('Mobile number must be exactly 10 digits.');
    } else {
        input.setCustomValidity('');
    }

    input.reportValidity();
}





   handleSave(event) {
    const requiredFields = ['Salutation', 'FirstName', 'LastName', 'Email', 'MobilePhone'];
    const missingFields = requiredFields.filter(field => !this.contactRecord[field]);

    const lightningInputFields = this.template.querySelectorAll('lightning-input-field');
    lightningInputFields.forEach(field => field.reportValidity());

    // 🔒 Check for required field values
    if (missingFields.length) {
        const toastElement = this.template.querySelector('c-toast-message');
        const toasts = getShowToastEvents(this, 'Error', 'Please complete required fields', 'error');
        (Array.isArray(toasts) ? toasts : [toasts]).forEach(toast => toastElement.showToast(toast));
        return;
    }

    // ✅ Validate Mobile number before submission
    const mobileInput = this.template.querySelector('lightning-input[data-id="mobilePhone"]');
    if (!this.contactRecord.MobilePhone || this.contactRecord.MobilePhone.length !== 10) {
        mobileInput.setCustomValidity('Please Enter 10 digit Mobile Number.');
        mobileInput.reportValidity();
        return;
    } else {
        mobileInput.setCustomValidity('');
        mobileInput.reportValidity();
    }

    // 🌀 Proceed to create contact
    this.showSpinner = true;
    createContact({
        contact: { AccountId: this.accountId, ...this.contactRecord },
        assetId: this.assetId,
        caseId: this.caseId,
        serviceAppointmentId: this.serviceAppointmentId
    })
        .then(result => {
            const toastElement = this.template.querySelector('c-toast-message');
            const toasts = getShowToastEvents(this, 'Success', 'Contact created successfully', 'success');
            (Array.isArray(toasts) ? toasts : [toasts]).forEach(toast => toastElement.showToast(toast));
            this.close(result.Id);
        })
        .catch(error => {
            console.error('createContact', error);
            const toastElement = this.template.querySelector('c-toast-message');
            const toasts = getShowToastEvents(this, 'Error', 'Something went wrong', 'error', error);
            (Array.isArray(toasts) ? toasts : [toasts]).forEach(toast => toastElement.showToast(toast));
        })
        .finally(() => {
            this.showSpinner = false;
        });
}



    handleCancel() {
        this.close();
    }

}