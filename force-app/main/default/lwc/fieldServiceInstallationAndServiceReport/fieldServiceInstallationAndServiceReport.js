import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

import LightningAlert from 'lightning/alert';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import getReportDetails from '@salesforce/apex/FieldServiceInstallationAndServiceReport.getReportDetails';
import previewReport from '@salesforce/apex/FieldServiceInstallationAndServiceReport.previewReport';
import saveReport from '@salesforce/apex/FieldServiceInstallationAndServiceReport.saveReport';
import deleteRecord from '@salesforce/apex/FieldServiceInstallationAndServiceReport.deleteRecord';

import getDocumentId from '@salesforce/apex/FieldServiceInstallationAndServiceReport.getDocumentId';


import getChecklistData from '@salesforce/apex/FieldServiceCaptureInteraction.getChecklistData';
import saveChecklistData from '@salesforce/apex/FieldServiceCaptureInteraction.saveChecklistData';

import { showToast, analyzeFormFactor, getNameAndValueOnChange, navigateToLWC, navigateToFilePreview } from 'c/utilJS';



export default class FieldServiceInstallationAndServiceReport extends NavigationMixin(LightningElement) {
    @track showSpinner;

    @api workOrderId;
    @api serviceAppointmentId;

    @api reportType;


    @track isMobile;
    @track isTablet;
    @track isDesktop;



    @track workOrderRecord = {};
    @track serviceAppointmentRecord = {};
    @track installationReportRecord = {};
    @track serviceReportRecord = {};
    @track causeSubCauseList = [];
    @track causeOptions = [];

    @track toEmailAddresses;


    @track Service_Report_Observation;




    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        if (currentPageReference && currentPageReference.state) {
            this.workOrderId = currentPageReference.state.c__workOrderId;
            this.serviceAppointmentId = currentPageReference.state.c__serviceAppointmentId;
            this.reportType = currentPageReference.state.c__reportType;

            this.handleGetReportDetails();
            this.loadChecklistData();
        }
    }


    connectedCallback() {
        analyzeFormFactor(this);
    }

    renderedCallback() {
        console.log('renderedCallback from FieldServiceInstallationAndServiceReport');
    }

    disconnectedCallback() { }


    @track isRemoteSupport = false;
    @track oemSerialNumber = '';
    @track hourMeterRequired = false;

    handleGetReportDetails() {
        this.showSpinner = true;
        getReportDetails({ workOrderId: this.workOrderId, serviceAppointmentId: this.serviceAppointmentId, reportType: this.reportType })
            .then(result => {
                if (!result) return;
                console.log(JSON.stringify(result));

                this.mapReportDetails(result);
            })
            .catch(error => {
                console.log('error', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    mapReportDetails(result) {
        const { workOrder, serviceAppointment, installationReport, serviceReport, email, causeSubCauseList, sroList, hourMeterRequired } = result;

        this.hourMeterRequired = hourMeterRequired;

        this.workOrderRecord = workOrder;

        if (this.workOrderRecord.Case__r?.Asset?.OEM_Serial_Number__c) {
            this.oemSerialNumber = true;
        }

        this.serviceAppointmentRecord = serviceAppointment;

        const isRS = serviceAppointment.Remote_Support__c;
        this.isRemoteSupport = !isRS;

        this.installationReportRecord = installationReport;
        this.serviceReportRecord = serviceReport;
        this.toEmailAddresses = email;
        this.causeSubCauseList = causeSubCauseList;

        this.customerRemark = this.serviceReportRecord?.Customer_Remark__c ?? this.installationReportRecord?.Customer_Remark__c;
        this.customerFeedback = this.serviceReportRecord?.Customer_Feedback__c ?? this.installationReportRecord?.Customer_Feedback__c;


        const uniqueCauses = [...new Set((this.causeSubCauseList || []).map(doc => doc.Cause__c))];
        this.causeOptions = uniqueCauses.map(cause => ({ label: cause, value: cause }));

        /*
        this.causeOptions = (this.causeSubCauseList || [])
            ?.map(doc => doc.Cause__c)
            ?.filter((value, index, self) => self.indexOf(value) === index)
            ?.map(doc => ({ label: doc, value: doc }));
        */

        if (this.causeOptions && this.causeOptions.length > 0) {
            this.causeOptions.push({ label: 'Other', value: 'Other' });
        } else {
            this.causeOptions = [{ label: 'Other', value: 'Other' }];
        }

        const causeToSubCauseOptions = causeSubCauseList?.reduce((acc, { Cause__c, Sub_Cause__c }) => {
            (acc[Cause__c] ||= []).push({ label: Sub_Cause__c, value: Sub_Cause__c });
            return acc;
        }, {});

        if (sroList && sroList.length > 0) {
            this.Service_Report_Observation = sroList.map(doc => ({
                Id: doc.Id,
                key: this.generateKey(),
                Cause__c: doc.Cause__c,
                Sub_Cause__c: doc.Sub_Cause__c,
                Actual_Observation_by_Engineer__c: doc.Actual_Observation_by_Engineer__c,
                Correction__c: doc.Correction__c,
                subCauseOptions: causeToSubCauseOptions[doc.Cause__c] || [],
                isCauseOther: doc.Cause__c === 'Other'
            }));
        }
        else {
            this.Service_Report_Observation = [{ key: this.generateKey() }];
        }
    }

    generateKey() {
        return Math.floor(Math.random() * 1000000);
    }



    handleChange(event) {
        const { name, value } = getNameAndValueOnChange(this, event);

        if (this.isInstallationReport) {
            this.installationReportRecord = { ...this.installationReportRecord, [name]: value };
        }
        else if (this.isServiceReport) {
            this.serviceReportRecord = { ...this.serviceReportRecord, [name]: value };
        }

        if (name === 'Installation_Asset_Serial_Number__c') {
            this.installationReportRecord.isSerialNumberEdited = true;
        }

        try {
            event.target.setCustomValidity('');
            event.target.reportValidity();
        } catch (error) { }
    }


    handlePreviewReport() {
        this.showSpinner = true;
        previewReport({
            installationReportRecord: this.installationReportRecord,
            serviceReportRecord: this.serviceReportRecord,
            reportType: this.reportType
        })
            .then(result => {
                if (result) {
                    navigateToFilePreview(this, result);
                }
            })
            .catch(error => {
                console.log('error', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }


    async handleSave(event) {
        let isValid = true;

        this.template.querySelectorAll('lightning-input-field')?.forEach(field => field.reportValidity());

        const reportRecord = this.isInstallationReport ? this.installationReportRecord : this.serviceReportRecord;

        if (this.isRemoteSupport) {
            if (!reportRecord.Signature__c) {
                showToast(this, 'Error', 'Signature and signer details are required.', 'error');
                isValid = false;
            }
        }

        if (this.hourMeterRequired) {
            if (!reportRecord.Hour_Meter__c) {
                showToast(this, 'Error', 'Hour Meter is required.', 'error');
                isValid = false;
            }
        }

        if (this.isInstallationReport && this.isTempSerialNumber && !reportRecord.isSerialNumberEdited) {
            isValid = false;
            await LightningAlert.open({
                message: 'Kindly contact your respective Coordinator, you will be able to proceed only after proper Serial Number is maintained in Asset.',
                theme: 'theme',
                label: 'Error!'
            });
            return;
        }

        if (this.isServiceReport) {
            let isServiceReportObservationValid = true;

            for (let ele of this.Service_Report_Observation) {
                if (ele.Cause__c && !ele.Actual_Observation_by_Engineer__c) {
                    const key = ele.key.toString();
                    const element = this.template.querySelector(`lightning-input[data-name="Actual_Observation_by_Engineer__c"][data-key="${key}"]`);
                    if (element) {
                        element.setCustomValidity('Please fill Actual Observation by Engineer');
                        element.reportValidity();
                    } else {
                        showToast(this, 'Error', 'Please fill Actual Observation by Engineer', 'error');
                        break;
                    }
                    isValid = false;
                    isServiceReportObservationValid = false;
                }
            }
            if (!isServiceReportObservationValid) {
                showToast(this, 'Error', 'Please fill Actual Observation by Engineer', 'error');
            }
        }

        if (isValid) {
            this.handleSaveAfterConfirmation();
        }
    }


    @track customerRemark;
    @track customerFeedback;

    get isRemarkFilled() {
        return this.customerRemark;
    }

    get isCustomerFeedback() {
        return this.customerFeedback;
    }





    async handleSaveAfterConfirmation() {
        this.showSpinner = true;
        const workOrderChecklist = [];
        this.checklistItems?.forEach(category => {
            category.checkpoints
                .filter(checkpoint => checkpoint.isModified)
                .forEach(checkpoint => {
                    workOrderChecklist.push(checkpoint);
                });
        });

        saveReport({
            installationReportRecord: this.installationReportRecord,
            serviceReportRecord: this.serviceReportRecord,
            reportType: this.reportType,
            serviceReportObservations: (this.Service_Report_Observation || []).filter(obs => obs.Cause__c && obs.Sub_Cause__c),
            workOrderChecklist: workOrderChecklist,
            serviceAppointmentId: this.serviceAppointmentId
        })
            .then(result => {
                if (!result) return;

                const reportRecord = this.isInstallationReport ? this.installationReportRecord : this.serviceReportRecord;
                reportRecord.IsSavedByUser__c = true;

                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

                this.handleGetReportDetails();
                this.loadChecklistData();
                showToast(this, 'Success', 'Report saved successfully', 'success');
            })
            .catch(error => {
                console.log('error', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }


    handleSendEmail() {
        navigateToLWC(this, 'fieldServiceSendDocument', { c__id: this.recordId, c__attachmentIds: this.docIds, c__toEmailAddresses: this.toEmailAddresses });
    }


    handlePreviewPDF() {
        this.showSpinner = true;
        getDocumentId({ recordId: this.recordId, reportType: this.reportType })
            .then(result => {
                if (!result) {
                    showToast(this, 'Error', 'Something went wrong, please get in touch with your administrator', 'error');
                }
                navigateToFilePreview(this, result);
            })
            .catch(error => {
                console.log('error', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }









    handleOnLoad(event) {
        if (this.isInstallationReport) {
            this.installationReportRecord.isRecordEditFormLoaded = true;

            // this.customerRemark = this.installationReportRecord.Customer_Remark__c;
            // this.customerFeedback = this.installationReportRecord.Customer_Feedback__c;
        }
        else if (this.isServiceReport) {
            this.serviceReportRecord.isRecordEditFormLoaded = true;

            // this.customerRemark = this.serviceReportRecord.Customer_Remark__c;
            // this.customerFeedback = this.serviceReportRecord.Customer_Feedback__c;
        }
    }




    get recordId() {
        return this.isInstallationReport ? this.installationReportRecord?.Id : this.serviceReportRecord?.Id;
    }


    get isInstallationReport() {
        return this.reportType === 'InstallationReport';
    }

    get isInstallationReportCompleted() {
        return this.isInstallationReport && this.installationReportRecord?.Installation_Status__c === 'Completed';
    }

    get isTempSerialNumber() {
        return this.workOrderRecord?.Case__r?.Asset?.Is_Temp_Serial_Number__c;
        // return false;
    }

    get isServiceReport() {
        return this.reportType === 'ServiceReport';
    }


    get isPreviewAndSendDisabled() {
        const reportRecord = this.isInstallationReport ? this.installationReportRecord : this.serviceReportRecord;
        return !reportRecord.IsSavedByUser__c;

    }



    handleServiceReportChange(event) {
        const { name, value } = getNameAndValueOnChange(this, event);
        const { key } = event.currentTarget.dataset;

        const index = this.Service_Report_Observation.findIndex(x => x.key == key);
        const row = this.Service_Report_Observation[index];

        row[name] = value;

        if (name === 'Cause__c') {
            delete row.Sub_Cause__c;

            const isOther = value === 'Other';
            row.isCauseOther = isOther;

            if (!isOther) {
                row.subCauseOptions = (this.causeSubCauseList || [])
                    .filter(x => x.Cause__c === value)
                    .map(x => ({ label: x.Sub_Cause__c, value: x.Sub_Cause__c }));
            }
        }

        try {
            event.target.setCustomValidity('');
            event.target.reportValidity();
        } catch (error) { }
    }


    handleAdd() {
        const newRow = { key: this.generateKey(), get isCauseOther() { return this.Cause__c === 'Other' } };
        this.Service_Report_Observation.push(newRow);
    }

    handleRemove(event) {
        if (this.Service_Report_Observation.length === 1) {
            showToast(this, 'Warning', 'You can\'t remove last observation', 'warning');
            return;
        }
        const eveId = event.target.dataset.key;
        const index = this.Service_Report_Observation.findIndex(x => x.key == eveId);
        if (index !== -1) {
            const observation = this.Service_Report_Observation[index];
            if (observation.Id) {
                this.handleDelete(observation.Id);
            }
            this.Service_Report_Observation.splice(index, 1);
            this.Service_Report_Observation = [...this.Service_Report_Observation];
        }
    }

    handleDelete(serObserveId) {
        deleteRecord({ recordId: serObserveId })
            .then(result => {
                showToast(this, 'Success', 'Removed', 'success');
            })
            .catch(error => {
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            });
    }

    // loadChecklistData() {
    //     getChecklistData({ workOrderId: this.workOrderId })
    //         .then(result => {
    //             // console.log('getChecklistData', result);
    //             if (result && Array.isArray(result) && result.length > 0) {
    //                 const groupedData = result.reduce((acc, item) => {
    //                     const category = item.Checklist_Category__c;
    //                     if (!acc[category]) {
    //                         acc[category] = [];
    //                     }
    //                     acc[category].push(item);
    //                     return acc;
    //                 }, {});

    //                 this.checklistItems = Object.entries(groupedData).map(([category, checkpoints]) => ({
    //                     Checklist_Category__c: category,
    //                     checkpoints: checkpoints
    //                 }));
    //                 // console.log('this.checklistItems', this.checklistItems);
    //             }
    //         })
    //         .catch(error => {
    //             console.log('Error fetching checklist data', error);
    //             showToast(this, 'Error', 'Something went wrong', 'error', error);
    //         });
    // }

    loadChecklistData() {
    if (!this.workOrderId) {
        console.warn('loadChecklistData: workOrderId is not available yet');
        return;
    }
    
    getChecklistData({ workOrderId: this.workOrderId })
        .then(result => {
            console.log('getChecklistData result:', result);
            if (result && Array.isArray(result) && result.length > 0) {
                const groupedData = result.reduce((acc, item) => {
                    const category = item.Checklist_Category__c;
                    if (!acc[category]) {
                        acc[category] = [];
                    }
                    acc[category].push(item);
                    return acc;
                }, {});

                this.checklistItems = Object.entries(groupedData).map(([category, checkpoints]) => ({
                    Checklist_Category__c: category,
                    checkpoints: checkpoints
                }));
                console.log('checklistItems set:', this.checklistItems);
            } else {
                console.warn('No checklist data returned');
                this.checklistItems = undefined;
            }
        })
        .catch(error => {
            console.error('Error fetching checklist data:', error);
            showToast(this, 'Error', 'Failed to load checklist data: ' + (error.body?.message || error.message), 'error');
            this.checklistItems = undefined;
        });
}


    get observationOptions() {
        return [{ label: 'Ok', value: 'Ok' }, { label: 'Not Ok', value: 'Not Ok' }, { label: 'Not Applicable', value: 'Not Applicable' }];
    }

    handleChecklistChange(event) {
        const { name, value, dataset: { checklistCategory, checklistMasterId } } = event.target;

        const category = this.checklistItems.find(item => item.Checklist_Category__c === checklistCategory);
        if (category) {
            const checkpoint = category.checkpoints.find(checkpoint => checkpoint.Checklist_Master__c === checklistMasterId);
            if (checkpoint) {
                checkpoint.Observation__c = value;
                checkpoint.isModified = true;
            }
        }
    }



    @track isSignatureModalOpen = false;

    handleOpenCaptureSignatureClick() {
        const reportRecord = this.isInstallationReport ? this.installationReportRecord : this.serviceReportRecord;
        reportRecord.Signature__c = undefined;
        reportRecord.Signature_by__c = undefined;
        reportRecord.Customer_Email__c = undefined;
        reportRecord.Customer_Contact_Number__c = undefined;
        reportRecord.Customer_Designation__c = undefined;

        this.isSignatureModalOpen = true;

        if (window.innerWidth <= 768) {
            this.scrollToHeight(0);
            document.documentElement.style.overflow = 'hidden';
        }
    }



    handleSignatureModalCaptureClick() {
        const reportRecord = this.isInstallationReport ? this.installationReportRecord : this.serviceReportRecord;

        const pad = this.template.querySelector("c-signature-pad");
        if (pad && reportRecord) {
            const dataURL = pad.getSignature();
            const text = pad.getInputText();

            reportRecord.Signature__c = dataURL ? `<img src="data:image/png;base64,${dataURL.split(',')[1]}" />` : null;
            reportRecord.Signature_by__c = text || '';
        }
        if (this.isRemoteSupport && reportRecord.Customer_Contact_Number__c) {
            const phoneRegex = /^[0-9]{10}$/;
            if (!phoneRegex.test(reportRecord.Customer_Contact_Number__c)) {
                showToast(this, 'Error', 'Please enter a valid 10-digit mobile number', 'error');
                return;
            }
        }

        if (this.isRemoteSupport) {
            if (!reportRecord.Signature__c || !reportRecord.Signature_by__c || !reportRecord.Customer_Email__c || !reportRecord.Customer_Contact_Number__c || !reportRecord.Customer_Designation__c) {
                showToast(this, 'Error', 'Signature and signer details are required.', 'error');
                return;
            }
        }

        this.isSignatureModalOpen = false;

        if (window.innerWidth <= 768) {
            setTimeout(() => {
                this.scrollToHeight(document.documentElement.scrollHeight);
                document.documentElement.style.overflow = 'auto';
            }, 100);
        }
    }


    handleSignatureModalCancelClick() {
        this.handleSignatureModalClearClick();
        this.isSignatureModalOpen = false;

        if (window.innerWidth <= 768) {
            setTimeout(() => {
                this.scrollToHeight(document.documentElement.scrollHeight);
                document.documentElement.style.overflow = 'auto';
            }, 100);
        }
    }


    handleSignatureModalClearClick() {
        const reportRecord = this.isInstallationReport ? this.installationReportRecord : this.serviceReportRecord;
        reportRecord.Signature__c = undefined;
        reportRecord.Signature_by__c = undefined;
        reportRecord.Customer_Email__c = undefined;
        reportRecord.Customer_Contact_Number__c = undefined;
        reportRecord.Customer_Designation__c = undefined;

        const pad = this.template.querySelector('c-signature-pad');
        if (pad) {
            pad.clearSignature();
        }
    }


    scrollToHeight(height) {
        window.scrollTo({
            top: height,
            // behavior: 'smooth'
        });
    }


}