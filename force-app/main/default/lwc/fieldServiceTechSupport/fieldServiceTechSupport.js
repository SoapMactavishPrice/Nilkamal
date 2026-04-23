import { LightningElement, api, wire, track } from 'lwc';
import submitSupportComment from '@salesforce/apex/FieldServiceOpenQueue2.submitSupportComment';
import checkUserPermission from '@salesforce/apex/FieldServiceOpenQueue2.checkUserPermission';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

export default class FieldServiceTechSupport extends LightningElement {
    @api caseId;
    @track isTechSupportModalOpen = false;
    @track technicalSupportComments = '';
    @track showSpinner = false;
    @track isSubmitting = false;
    charCount = 0;
    maxCharCount = 254;


    // Handle page reference changes
    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (pageRef && pageRef.state) {
            const state = pageRef.state;
            if (state.c__openTechSupportModal === 'true' && state.c__caseId) {
                this.caseId = state.c__caseId;
                this.checkPermissionsAndOpenModal();
            }
        }
    }

    // Open modal from parent component
    @api
    openTechSupportModal() {
        this.checkPermissionsAndOpenModal();
    }

    checkPermissionsAndOpenModal() {
        if (!this.caseId) {
            this.showErrorToast('Case ID is missing');
            return;
        }

        this.showSpinner = true;
        checkUserPermission({ caseId: this.caseId })
            .then(hasPermission => {
                if (hasPermission) {
                    this.isTechSupportModalOpen = true;
                } else {
                    this.showErrorToast('You are not authorized to submit technical support comments for this case');
                }
            })
            .catch(error => {
                console.error('Error checking permissions:', error);
                this.showErrorToast('Error checking permissions: ' + this.getErrorMessage(error));
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    closeTechSupportModal() {
        this.isTechSupportModalOpen = false;
        this.technicalSupportComments = '';
    }

    handleCommentChange(event) {
        this.technicalSupportComments = event.target.value;
        this.charCount = this.technicalSupportComments.length;
    }

    submitTechSupport() {
        if (!this.validateComment()) return;

        this.isSubmitting = true;
        this.showSpinner = true;

        submitSupportComment({
            caseId: this.caseId,
            comment: this.technicalSupportComments
        })
            .then(() => {
                this.showSuccessToast('Success', 'Technical Support comment submitted successfully');
                this.closeTechSupportModal();
                this.dispatchEvent(new CustomEvent('success'));
            })
            .catch(error => {
                console.error('Error submitting comment:', error);
                this.showErrorToast(this.getErrorMessage(error));
            })
            .finally(() => {
                this.isSubmitting = false;
                this.showSpinner = false;
            });
    }

    validateComment() {
        const commentField = this.template.querySelector('.technical-support-comment');
        if (!this.technicalSupportComments || this.technicalSupportComments.trim() === '') {
            commentField.setCustomValidity('Comment cannot be empty');
            commentField.reportValidity();
            return false;
        }
        // if (this.technicalSupportComments.length < 5) {
        //     commentField.setCustomValidity('Comment must be at least 5 characters long');
        //     commentField.reportValidity();
        //     return false;
        // }

        if (this.technicalSupportComments.length > 254) {
            commentField.setCustomValidity('Comment cannot exceed 254 characters');
            commentField.reportValidity();
            return false;
        }
        commentField.setCustomValidity('');
        commentField.reportValidity();
        return true;
    }

    showSuccessToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success'
        }));
    }

    showErrorToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        }));
    }

    getErrorMessage(error) {
        let message = 'An error occurred';
        if (error.body) {
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
        } else if (typeof error.message === 'string') {
            message = error.message;
        }
        return message;
    }
}