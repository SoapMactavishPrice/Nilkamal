import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveSignatureToRecord from '@salesforce/apex/InstallationReportController.saveSignature';
import { CurrentPageReference } from 'lightning/navigation';
import getInstallationReport from '@salesforce/apex/InstallationReportController.getInstallationReport';
import getWorkOrderDetails from '@salesforce/apex/InstallationReportController.getWorkOrderDetails';
import getServiceReport from '@salesforce/apex/InstallationReportController.getServiceReport';
import { disablePullToRefresh, navigateToFilePreview } from 'c/utilJS';
import { NavigationMixin } from 'lightning/navigation';
import generatePdf from '@salesforce/apex/InstallationReportController.generatePdf';


export default class FieldServiceCaptureSignature extends NavigationMixin(LightningElement) {
    @track recordId;

    @track clickedButtonName;

    imgSrc;
    renderedCallback() {
        document.fonts.forEach((font) => {
            if (font.family === "Great Vibes" && font.status === "unloaded") {
                font.load();
            }
        });
    }


    // saveSignature() {
    //     const pad = this.template.querySelector("c-signature-pad");
    //     if (pad) {
    //         const dataURL = pad.getSignature();
    //         const text = pad.getInputText();
    //         console.log('Input Text:', text);
    //         console.log('dataURL:', dataURL);
    //         if (!text || !dataURL) {
    //             let errorMessage = '';
    //             if (!text) {
    //                 errorMessage += 'Please enter your name or text.\n';
    //             }
    //             if (!dataURL) {
    //                 errorMessage += 'Please provide a signature.';
    //             }

    //             this.dispatchEvent(new ShowToastEvent({
    //                 title: 'Error',
    //                 message: errorMessage,
    //                 variant: 'error',
    //             }));
    //             return; 
    //         }
    //         if (dataURL) {
    //             this.imgSrc = dataURL;
    //         }
    //         pad.clearSignature();
    //     }
    // }
    clearSignature() {
        const pad = this.template.querySelector("c-signature-pad");
        if (pad) {
            pad.clearSignature();
        }
        this.imgSrc = null;
    }
    // 
    @track isReasonForHoldVisible = false;
    @track formData = {};
    @track signatureData = null;
    @track workOrderId;
    @track mode;
    @track caseId;
    // @track itemMasterId;
    // @track installationReportId;
    @track isInstallationReport = false;
    @track isServiceReport = false;
    @track objectApiName;
    @track showSpinner = false;


    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.workOrderId = currentPageReference.state.c__id;
            this.mode = currentPageReference.state.c__mode;
            this.isInstallationReport = this.mode === 'InstallationReport';
            this.isServiceReport = this.mode === 'ServiceReport';
            if (this.isInstallationReport) {
                this.objectApiName = 'Installation_Report__c';
            } else if (this.isServiceReport) {
                this.objectApiName = 'Service_Report__c';
            }
        }
    }

    connectedCallback() {
        if (this.isInstallationReport) {
            this.fetchInstallationReport();
        } else if (this.isServiceReport) {
            this.fetchServiceReport();
        }
        // navigateToFilePreview(this, 'a0HF3000009DiicMAC');
        disablePullToRefresh(this);
    }

    fetchInstallationReport() {
        this.showSpinner = true;
        if (this.isInstallationReport && this.workOrderId) {
            getInstallationReport({ workOrderId: this.workOrderId })
                .then((data) => {
                    console.log('Installation data', data);
                    let tdata = '';
                    if (data == '') {
                        this.fetchWorkOrderDetails();
                    } else {
                        tdata = JSON.parse(data);
                        console.log('tdata', tdata);
                        console.log('previewDocId-->>', this.previewDocId);

                        this.recordId = tdata.recordId;
                        let status = tdata.status;
                        if (status === 'Completed') {
                            generatePdf({ recordId: this.recordId, mode: 'InstallationReport', isPreview: false, previewDocId: this.previewDocId })
                                .then(fileId => {
                                    if (fileId) {
                                        this.navigateToFilePreview(fileId);
                                    } else {
                                        this.showToast('Error', 'Failed to generate PDF.', 'error');
                                    }
                                })
                                .catch(error => {
                                    console.error('PDF Generation Error:', error);
                                    this.showToast('Error', 'Error generating PDF', 'error');
                                });
                            this.showSpinner = false;
                        } else {
                            this.showSpinner = false;
                            console.log('Working normally, status not completed.');
                        }
                        console.log(this.recordId);
                    }
                })
                .catch((error) => {
                    this.showSpinner = false;
                    console.error('Error fetching Installation Report:', error);
                });
        }
    }
    fetchWorkOrderDetails() {
        this.showSpinner = true;
        if (this.workOrderId) {
            getWorkOrderDetails({ workOrderId: this.workOrderId })
                .then((result) => {
                    if (result) {
                        this.caseId = result.Case__c;
                        this.itemMasterId = result.Case__r.Asset.Product2Id;
                    }
                })
                .catch((error) => {
                    // console.error('Error fetching Work Order details:', error);
                    console.error('Error fetching Work Order details:', error.body ? error.body.message : error.message || error);
                    this.showSpinner = false;
                });
            this.showSpinner = false;
        }
    }

    fetchServiceReport() {
        this.showSpinner = true;
        if (this.isServiceReport && this.workOrderId) {
            getServiceReport({ workOrderId: this.workOrderId })
                .then((data) => {
                    console.log('service data', data);
                    let tdata = '';
                    if (data == '') {
                        this.fetchWorkOrderDetails();
                    } else {
                        tdata = JSON.parse(data);
                        console.log('service tdata', tdata);
                        this.recordId = tdata.recordId;
                        let status = tdata.status;
                        if (status === 'Completed') {
                            generatePdf({ recordId: this.recordId, mode: 'ServiceReport', isPreview: false, previewDocId: this.previewDocId })
                                .then(fileId => {
                                    if (fileId) {
                                        this.navigateToFilePreview(fileId);
                                    } else {
                                        this.showToast('Error', 'Failed to generate PDF.', 'error');
                                    }
                                })
                                .catch(error => {
                                    console.error('PDF Generation Error:', error);
                                    this.showToast('Error', 'Error generating PDF', 'error');
                                });
                            this.showSpinner = false;
                        } else {
                            console.log('Working normally, status not completed.');
                            this.showSpinner = false;
                        }
                    }
                    console.log(this.recordId);
                })
                .catch((error) => {
                    console.error('Error fetching Service Report:', error);
                    this.showSpinner = false;
                });
        }
    }



    handleChange(event) {
        const fieldName = event.target.fieldName;
        const fieldValue = event.target.value;
        console.log('fieldName', fieldName);
        console.log('fieldValue', fieldValue);
        this.formData[fieldName] = fieldValue;

        if (fieldName === 'Installation_Status__c') {
            this.isReasonForHoldVisible = fieldValue === 'On Hold';
        }
        if (fieldName === 'SR_Status__c') {
            this.isReasonForHoldVisible = fieldValue === 'On Hold';
        }
    }
    handleSuccess(event) {
        this.recordId = event.detail.id;

        const fieldInput = this.template.querySelector('.StatusConfirmation');

        if (this.clickedButtonName === 'Save') {
            const evt = new ShowToastEvent({ title: "Success", message: "Record saved successfully!", variant: "success" });
            this.dispatchEvent(evt);

            const mode = this.mode;
            const previewDocId = this.previewDocId;
            if (fieldInput.value === 'Completed') {
                generatePdf({ recordId: this.recordId, mode: mode, isPreview: false, previewDocId: previewDocId })
                    .then(fileId => {
                        if (fileId) {
                            this.navigateToFilePreview(fileId);
                        } else {
                            this.showToast('Error', 'Failed to generate PDF.', 'error');
                        }
                    })
                    .catch(error => {
                        console.error('PDF Generation Error:', error);
                        this.showToast('Error', 'Error generating PDF', 'error');
                    });
            }
        }
        else if (this.clickedButtonName === 'Preview') {
            const mode = this.mode;
            const isPreview = true;
            console.log('mode', mode, this.recordId);
            console.log('this.previewDocId', this.previewDocId);

            generatePdf({ recordId: this.recordId, mode: mode, isPreview: isPreview, previewDocId: this.previewDocId })
                .then(fileId => {
                    if (fileId) {
                        this.previewDocId = fileId;
                        this.navigateToFilePreview(fileId);
                    } else {
                        this.showToast('Error', 'Failed to generate PDF.', 'error');
                    }
                })
                .catch(error => {
                    console.error('PDF Generation Error:', error);
                    this.showToast('Error', 'Error generating PDF', 'error');
                });
        }
    }

    handleError(event) {
        const errorMessage = event?.detail?.message || 'An unexpected error occurred.';

        console.error('Error details:', errorMessage);

        const evt = new ShowToastEvent({
            title: "Error",
            message: "An error occurred while saving the Installation Report.",
            variant: "error",
        });
        this.dispatchEvent(evt);
    }

    // handleFormSubmit(event) {
    //     const skipValidation = event.skipValidation || false;


    //     if (skipValidation) {
    //         console.log('this.skipValidation', skipValidation);
    //         console.log('Skipping validation, directly saving the data...');
    //         this.template.querySelector('lightning-record-edit-form').submit(fields);
    //     }
    //     const pad = this.template.querySelector("c-signature-pad");
    //     if (pad) {
    //         const dataURL = pad.getSignature();
    //         const text = pad.getInputText();
    //         console.log('Input Text:', text);
    //         console.log('dataURL', dataURL);

    //         if (dataURL && dataURL != null) {
    //             this.signatureData = dataURL.split(',')[1];
    //         }
    //         if (text) {
    //             this.signatureBy = text;
    //         }
    //     }


    //     if (!this.signatureData) {
    //         this.showToast('Error', 'Signature is required!', 'error');
    //         return;
    //     }

    //     if (!this.signatureBy) {
    //         this.showToast('Error', 'Signer name is required!', 'error');
    //         return;
    //     }

    //     // if (!this.signatureData && !this.signatureBy) {
    //     //     this.showToast('Error', 'Either signature or signer name is required!', 'error');
    //     //     return;
    //     // }

    //     const fields = event.detail.fields;

    //     if (!this.recordId) {
    //         fields.Work_Order__c = this.workOrderId;
    //         fields.Case__c = this.caseId;
    //         if (this.isInstallationReport) {
    //             fields.Item_Master__c = this.itemMasterId;
    //         } else if (this.isServiceReport) {
    //             fields.Product__c = this.itemMasterId;
    //         }
    //     }
    //     if (this.isInstallationReport) {
    //         if (fields.Installation_Status__c === 'Completed') {

    //             let errorMessage = '';

    //             if (!fields.Installation_End_Date__c) {
    //                 errorMessage += 'Installation End Date is required. ';

    //             } if (!fields.Warranty_Start_Date__c) {
    //                 errorMessage += 'Warranty Start Date is required. ';

    //             } if (!fields.Installation_Asset_Serial_Number__c) {
    //                 errorMessage += 'Installation Asset Serial Number is required. ';
    //             }
    //             if (errorMessage) {
    //                 this.showToast('Error', errorMessage, 'error');
    //                 return;
    //             }
    //         }
    //     }
    //     else if (this.isServiceReport) {
    //         if (fields.SR_Status__c === 'Completed') {
    //             let errorMessage = '';

    //             if (!fields.SR_End_Date__c) {
    //                 errorMessage += 'Service End Date is required. ';

    //             } if (!fields.Asset_Serial_Number__c) {
    //                 errorMessage += 'Service Asset Serial Number is required. ';
    //             }
    //             if (errorMessage) {
    //                 this.showToast('Error', errorMessage, 'error');
    //                 return;
    //             }
    //         }

    //     }

    //     // if (!this.handleSubmit(fields)) return;


    //     const imageTag = '<img src="data:image/png;base64,' + this.signatureData + '" />';

    //     fields.Signature__c = imageTag;
    //     fields.Signature_by__c = this.signatureBy;

    //     this.template.querySelector('lightning-record-edit-form').submit(fields);
    // }

    handleFormSubmit(event) {
        event.preventDefault();

        const fields = event.detail.fields;

        if (this.clickedButtonName === 'Save') {
            const pad = this.template.querySelector("c-signature-pad");
            if (pad) {
                const dataURL = pad.getSignature();
                const text = pad.getInputText();
                console.log('Input Text:', text);
                console.log('dataURL', dataURL);

                if (dataURL && dataURL != null) {
                    this.signatureData = dataURL.split(',')[1];
                }
                if (text) {
                    this.signatureBy = text;
                }
            }

            if (!this.signatureData) {
                this.showToast('Error', 'Signature is required!', 'error');
                return;
            }

            if (!this.signatureBy) {
                this.showToast('Error', 'Signer name is required!', 'error');
                return;
            }

            const imageTag = '<img src="data:image/png;base64,' + this.signatureData + '" />';
            fields.Signature__c = imageTag;
        }

        if (!this.recordId) {
            fields.Work_Order__c = this.workOrderId;
            fields.Case__c = this.caseId;
            if (this.isInstallationReport) {
                fields.Item_Master__c = this.itemMasterId;
            } else if (this.isServiceReport) {
                fields.Product__c = this.itemMasterId;
            }
        }

        if (this.isInstallationReport) {
            if (fields.Installation_Status__c === 'Completed') {
                let errorMessage = '';

                if (!fields.Installation_End_Date__c) {
                    errorMessage += 'Installation End Date is required. ';
                }
                if (!fields.Warranty_Start_Date__c) {
                    errorMessage += 'Warranty Start Date is required. ';
                }
                if (!fields.Installation_Asset_Serial_Number__c) {
                    errorMessage += 'Installation Asset Serial Number is required. ';
                }
                if (errorMessage) {
                    this.showToast('Error', errorMessage, 'error');
                    return;
                }
            }
        }
        else if (this.isServiceReport) {
            if (fields.SR_Status__c === 'Completed') {
                let errorMessage = '';

                if (!fields.SR_End_Date__c) {
                    errorMessage += 'Service End Date is required. ';
                }
                if (!fields.Asset_Serial_Number__c) {
                    errorMessage += 'Service Asset Serial Number is required. ';
                }
                if (errorMessage) {
                    this.showToast('Error', errorMessage, 'error');
                    return;
                }
            }
        }

        fields.Signature_by__c = this.signatureBy;

        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    navigateToFilePreview(fileId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: fileId
            }
        });
    }

    // saveSignatureToRecord({ recordId: this.recordId, base64Data: this.signatureData })
    //     .then(() => {
    //         this.showToast('Success', 'Signature saved successfully!', 'success');
    //     })
    //     .catch(error => {
    //         const msg = error.body ? error.body.message : error;
    //         this.showToast('Error', msg, 'error');
    //     });

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    handleSubmit(fields) {
        let isValid = true;

        const requiredFields = [
            { id: "Installation_End_Date__c", message: "Installation End Date is required." },
            { id: "Warranty_Start_Date__c", message: "Warranty Start Date is required." },
            { id: "Installation_Asset_Serial_Number__c", message: "Installation Asset Serial Number is required." }
        ];

        if (this.isInstallationReport && fields.Installation_Status__c === 'Completed') {
            requiredFields.forEach(({ id, message }) => {
                const field = this.template.querySelector(`[data-id="${id}"]`);
                if (field) {
                    const value = field.value?.trim() || "";

                    if (!value) {
                        field.setCustomValidity(message);
                        isValid = false;
                    } else {
                        field.setCustomValidity("");
                    }
                    field.reportValidity();
                }
            });
        }

        return isValid;
    }

    @track previewDocId = '';
    handlePreviewClick(event) {
        this.clickedButtonName = 'Preview';
        const previewButton = this.template.querySelector('[data-button="Preview"]');
        if (previewButton) {
            // Report the validity of the field
            previewButton.click();
        }
    }

    handleSaveClick(event) {
        // Return the isValid flag
        this.clickedButtonName = 'Save';
        const saveButton = this.template.querySelector('[data-button="Save"]');
        if (saveButton) {
            saveButton.click();
        }
    }

}