import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { refreshApex } from 'lightning/refresh';
import { getRecord, getFieldValue, createRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, navigateToFilePreview, navigateToFilePreviewWithoutHistory, navigateBackInHistory, openLightningModal, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh, scrollToTop, publishRefreshEvent } from 'c/utilJS';

import isQuoteValid from '@salesforce/apex/FieldServiceSendDocument.isQuoteValid';
import getDefaultEmailIds from '@salesforce/apex/FieldServiceSendDocument.getDefaultEmailIds';
import getAttachmentId from '@salesforce/apex/FieldServiceSendDocument.getAttachmentId';
import sendEmail from '@salesforce/apex/FieldServiceSendDocument.sendEmail';
import { MessageContext } from 'lightning/messageService';



export default class FieldServiceSendDocument extends NavigationMixin(LightningElement) {

    @track showSpinner = false;

    @api recordId;

    @track isMobile;
    @track isTablet;
    @track isDesktop;

    get device() {
        return this.isMobile ? 'mobile' : this.isTablet ? 'tablet' : this.isDesktop ? 'desktop' : 'unknown';
    }



    @track pdfUrl;


    @track toAddresses = [];
    @track ccAddresses = [];

    @track toAddress = '';
    @track ccAddress = '';

    @track subject;
    @track body;


    @track contacts = [];


    @track attachmentIds;





    @track isFirstTime = true;
    renderedCallback() {
        analyzeFormFactor(this);
        analyzeUserAgent(this);

        if (this.isFirstTime) {
            this.isFirstTime = false;

            const emailContainers = this.template.querySelectorAll('.email-container');
            emailContainers.forEach(emailContainer => {
                const inputElement = emailContainer.querySelector('input');
                const datalistElement = emailContainer.querySelector('datalist');
                const datalistId = datalistElement.id;
                inputElement.setAttribute('list', datalistId);
            });
        }
    }



    mapRecipient(value, isDefault) {
        const trimmedAddress = value.trim();
        const contact = this.contacts?.find(contact => contact.Email === trimmedAddress);
        if (contact) {
            contact.isAdded = true;
            const { FirstName = '', LastName = '' } = contact;
            const initials = `${FirstName[0] || ''}${LastName[0] || ''}`;
            return { type: 'avatar', label: `${FirstName} ${LastName}`, value: trimmedAddress, initials, isDefault }
        }

        return { type: 'avatar', label: trimmedAddress, value: trimmedAddress, isDefault };
    }



    @wire(CurrentPageReference)
    getCurrentPageReference({ state }) {
        if (state) {
            const { c__id, c__docType, c__toEmailAddresses, c__attachmentIds } = state;
            this.recordId = c__id;
            this.docType = c__docType;
            this.toEmailAddresses = c__toEmailAddresses;
            this.attachmentIds = c__attachmentIds;
            console.log('this.recordId', this.recordId, 'c__docType', c__docType, 'this.attachmentIds', this.attachmentIds);

            if (!this.recordId) {
                navigateBackInHistory(this);
                return;
            }

            isQuoteValid({ recordId: this.recordId })
                .then(result => {
                    if (result === false) {
                        showToast(this, 'Error', 'For details, please refer to the Approval Reason(s).', 'error');
                        showToast(this, 'Error', 'The quote is not yet approved. Please submit the quote for approval.', 'error');
                        navigateToRecord(this, this.recordId, 'Quote');
                    }
                })
                .catch(error => {
                    console.log('error', error);
                    showToast(this, 'Error', 'Something went wrong validating the quote.', 'error', error);
                    navigateToRecord(this, this.recordId, 'Quote');
                });

            this.showSpinner = true;
            getDefaultEmailIds({ recordId: this.recordId, docType: this.docType })
                .then(result => {
                    this.contacts = result.contacts || [];
                    this.toAddresses = result.defaultTo?.map(item => this.mapRecipient(item, true)) || [];
                    this.ccAddresses = result.defaultCC?.map(item => this.mapRecipient(item, true)) || [];
                    this.subject = result.subject;
                    this.body = result.body;


                    this.pdfUrl = result.pdfUrl;
                })
                .catch(error => {
                    console.log('error', error);
                    showToast(this, 'Error', 'Something went wrong getting the default email addresses.', 'error', error);
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }
    }



    handleRemoveRecipient(event) {
        event.preventDefault();
        const { index, type } = event.currentTarget.dataset;
        const addressList = type === 'to' ? this.toAddresses : type === 'cc' ? this.ccAddresses : [];
        const address = addressList[index];
        if (address.isDefault) {
            showToast(this, 'Warning', 'Default recipients cannot be removed.', 'warn');
        }
        else {
            address.isAdded = false;
            addressList.splice(index, 1);
        }
    }


    handleKeyUp(event) {
        console.log('event.key', event.key);
        if (event.key === 'Enter' || event.key === undefined) {
            this.handleInputChange(event);
        }
    }


    handleInputChange(event) {
        console.log('handleInputChange');
        const { name, value } = getNameAndValueOnChange(this, event);
        const trimmedValue = value.trim();
        if (!trimmedValue) return;

        const isValidEmail = email => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
        event.target.setCustomValidity(isValidEmail(trimmedValue) ? '' : 'Please enter a valid email address.');

        if (isValidEmail(trimmedValue)) {
            const recipientList = name === 'toAddress' ? 'toAddresses' : name === 'ccAddress' ? 'ccAddresses' : '';
            this[recipientList] = [...this[recipientList], this.mapRecipient(trimmedValue, false)];
            this[name] = '';
        }

        event.target.reportValidity();
    }





    handleChange(event) {
        const { name, value } = getNameAndValueOnChange(this, event);
        this[name] = value;

        const dataName = event.currentTarget.dataset.name;
        if (dataName !== 'body') {
            event.target.setCustomValidity('');
            event.target.reportValidity();
        }
    }




    validateEmailFields() {
        const fields = [
            { name: 'subject', message: 'Please enter a subject.' },
            { name: 'body', message: 'Please enter a body.' }
        ];

        let isValid = true;

        for (const field of fields) {
            const element = this.template.querySelector(`lightning-input[data-name="${field.name}"]`);
            if (!this[field.name]) {
                if (element) {
                    element.setCustomValidity(field.message);
                    element.reportValidity();
                } else {
                    showToast(this, 'Error', field.message, 'error');
                }
                isValid = false;
            }
        }

        return isValid;
    }

    @wire(MessageContext)
    messageContext;


    handleSendEmail() {
        if (!this.validateEmailFields()) return;

        const attachmentIds = this.attachmentIds?.split(/[:;,]/) || [];

        this.showSpinner = true;
        sendEmail({
            recordId: this.recordId,
            toAddresses: this.toAddresses.map(item => item.value),
            ccAddresses: this.ccAddresses.map(item => item.value),
            subject: this.subject,
            body: this.body,
            attachmentIds,
            docType: this.docType
        })
            .then(() => {
                showToast(this, 'Success', 'Email sent successfully.', 'success');
                publishRefreshEvent(this);
                navigateBackInHistory(this);
            })
            .catch(error => {
                console.log('error', error);
                showToast(this, 'Error', 'Something went wrong sending the email.', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }


    handlePreviewFile() {
        if (!this.attachmentIds) {
            this.showSpinner = true;
            getAttachmentId({ recordId: this.recordId, docType: this.docType })
                .then(result => {
                    this.attachmentIds = result;
                    console.log('this.attachmentIds', this.attachmentIds);
                    const attachmentIds = this.attachmentIds?.split(/[:;,]/) || [];
                    navigateToFilePreview(this, attachmentIds[0]);
                })
                .catch(error => {
                    console.log('error', error);
                    showToast(this, 'Error', 'Something went wrong getting the attachment ID.', 'error', error);
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        } else {
            const attachmentIds = this.attachmentIds?.split(/[:;,]/) || [];
            navigateToFilePreview(this, attachmentIds[0]);
        }
    }


    handleCancel() {
        navigateBackInHistory(this);
    }





    get isPreviewButtonDisabled() {
        return this.attachmentIds?.split(/[:;,]/).length > 1;
    }

}