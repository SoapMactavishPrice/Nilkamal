import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToLWCWithReload, navigateToLWCEncoded, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh, navigateToFilePreview, handleGetGeoLocation } from 'c/utilJS';
import { getLocationService } from 'lightning/mobileCapabilities';
import { deleteRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';

import addNewContactModal from 'c/fieldServiceCreateContact';
import fieldServiceServiceAppCheckOut from 'c/fieldServiceServiceAppCheckOut';

import { subscribe, unsubscribe, onError } from 'lightning/empApi';

// import getGeoLocation from 'c/getGeoLocation';

import getServiceAppointmentDetails from '@salesforce/apex/FieldServiceWorkOrderServiceAppInfo.getServiceAppointmentDetails';
// import getCheckInStatus from '@salesforce/apex/FieldServiceWorkOrderServiceAppInfo.getCheckInStatus';
import updateCheckInLocation from '@salesforce/apex/FieldServiceWorkOrderServiceAppInfo.updateCheckInLocation';
import updateRescheduleDate from '@salesforce/apex/FieldServiceWorkOrderServiceAppInfo.updateRescheduleDate';

import reassignCase from '@salesforce/apex/FieldServiceOpenQueue2.reassignCase';
import updateCaseResource from '@salesforce/apex/FieldServiceOpenQueue2.updateCaseResource';
import submitTechnicalSupport from '@salesforce/apex/FieldServiceOpenQueue2.submitTechnicalSupport';
import updateTechSupport from '@salesforce/apex/FieldServiceOpenQueue2.updateTechSupport';
import uploadFileToServer from '@salesforce/apex/FieldServiceOpenQueue2.uploadFileToServer';



export default class FieldServiceWorkOrderServiceAppInfo extends NavigationMixin(LightningElement) {

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.handleGetServiceAppointmentDetails();
    }

    @api objectApiName;

    @track showSpinner = true;

    @track isMobile;
    @track isTablet;
    @track isDesktop;

    @track serviceAppointment = {};

    @track commentOptions = [
        { label: 'Critical PM, Installation OR Maintenance to be carried out.', value: 'Critical PM, Installation OR Maintenance to be carried out.' },
        { label: 'On Field Technical Support Require.', value: 'On Field Technical Support Require.' }
    ];

    @track reAssignmentCommentOptions = [
        { label: 'Leave', value: 'Leave' },
        { label: 'Busy with pre - committed customers', value: 'Busy with pre - committed customers' },
        { label: 'Not compatible with this product', value: 'Not compatible with this product' },
        { label: 'Not belongs to my territory', value: 'Not belongs to my territory' }
    ];
    get showCaseSubject() {
        return (
            this.serviceAppointment &&
            this.serviceAppointment.subject &&
            this.serviceAppointment.caseType !== 'Installation'
        );
    }



    get isCheckedIn() {
        const [checkIn] = this.serviceAppointment?.checkInsAndOuts || [];
        if (checkIn) {
            const { Check_In_Date_Time__c, Is_auto_checked_out_by_system__c, IsCheckedOut__c } = checkIn;
            return Boolean(Check_In_Date_Time__c && !IsCheckedOut__c);
        }
        return false;
    }

    @wire(CurrentPageReference)
    currentPageReference({ state }) {
        const { c__recordId, c__objectApiName } = state;
        if (c__recordId) this.recordId = c__recordId;
        if (c__objectApiName) this.objectApiName = c__objectApiName;
    }


    connectedCallback() {
        console.log('connectedCallback from FieldServiceWorkOrderServiceAppInfo');

        analyzeFormFactor(this);
        analyzeUserAgent(this);
        if (this.isTablet || this.isDesktop) {
            loadQuickActionPopupStyle(this, 65);
        }
        disablePullToRefresh(this);
        console.log('Division', this.serviceAppointment.division);
    }

    renderedCallback() {
        console.log('renderedCallback from FieldServiceWorkOrderServiceAppInfo');
        analyzeFormFactor(this);
    }

    disconnectedCallback() {
        console.log('disconnectedCallback from FieldServiceWorkOrderServiceAppInfo');
        // this.unsubscribeToChangeDataCapture();
        this.unsubscribeToPlatformEvent();
        if (this.getServiceAppointmentDetailsInterval) {
            clearInterval(this.getServiceAppointmentDetailsInterval);
            this.getServiceAppointmentDetailsInterval = null;
        }
        unloadQuickActionPopupStyle(this);
    }


    @track getServiceAppointmentDetailsInterval;
    @track serviceAppointmentChangeEventSubscription;
    async subscribeToChangeDataCapture() {
        if (this.serviceAppointmentChangeEventSubscription) {
            await unsubscribe(this.serviceAppointmentChangeEventSubscription);
        }

        subscribe('/data/Service_Appointment__ChangeEvent', -1, (response) => {
            console.log('CDC event received 1 : ', response, JSON.stringify(response, null, 2));
            const changedFields = response.data.payload.ChangeEventHeader.changedFields;
            const recordIds = response.data.payload.ChangeEventHeader.recordIds;
            if (recordIds.includes(this.recordId)) {
                if (['Check_In_Date_Time__c', 'Check_Out_Date_Time__c', 'Check_Out_Address_Error__c', 'Count_of_Check_In_and_Out_Iterations__c'].some(field => changedFields.includes(field))) {
                    this.handleGetServiceAppointmentDetails();
                }
            }
        })
            .then(response => {
                console.log('Subscribed to CDC channel', response.channel);
                this.serviceAppointmentChangeEventSubscription = response;
            })
            .catch(error => {
                console.log('Error subscribing to CDC channel', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            });
    }

    async unsubscribeToChangeDataCapture() {
        if (this.serviceAppointmentChangeEventSubscription) {
            await new Promise((resolve, reject) => {
                unsubscribe(this.serviceAppointmentChangeEventSubscription, (response) => {
                    console.log('Unsubscribed from CDC channel:', response, JSON.stringify(response, null, 2));
                    this.serviceAppointmentChangeEventSubscription = null;
                    resolve(response);
                });
            });
        } else {
            this.serviceAppointmentChangeEventSubscription = null;
        }
    }


    @track serviceAppointmentPlatformEventSubscription;
    async subscribeToPlatformEvent() {
        if (this.serviceAppointmentPlatformEventSubscription) {
            await this.unsubscribeToPlatformEvent();
        }
        subscribe('/event/ServiceAppointmentUpdate__e', -1, (response) => {
            console.log('Platform Event received:', response, JSON.stringify(response, null, 2));

            const eventRecordId = response.data.payload.RecordId__c;
            if (eventRecordId === this.recordId) {
                this.handleGetServiceAppointmentDetails();
            }
        })
            .then(response => {
                console.log('Subscribed to PE channel', response.channel);
                this.serviceAppointmentPlatformEventSubscription = response;
            })
            .catch(error => {
                console.log('Error subscribing to PE channel', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            });
    }

    async unsubscribeToPlatformEvent() {
        if (this.serviceAppointmentPlatformEventSubscription) {
            await new Promise((resolve, reject) => {
                unsubscribe(this.serviceAppointmentPlatformEventSubscription, response => {
                    console.log('Unsubscribed from PE channel', response);
                    this.serviceAppointmentPlatformEventSubscription = null;
                    resolve(response);
                });
            });
        }
    }


    @track isAlreadyCheckin;
    /*
    getCheckInStatusJs() {
        getCheckInStatus({ recordId: this.recordId })
            .then((res) => {
                console.log('res ', res);

                if (res) {
                    this.isAlreadyCheckin = true;
                } else {
                    this.isAlreadyCheckin = false;
                }
            });
    }
    */



    handleGetServiceAppointmentDetails() {
        // this.showSpinner = true;
        getServiceAppointmentDetails({ recordId: this.recordId })
            .then(result => {
                this.mapRetrievedServiceAppointment(result);
            })
            .catch(error => {
                console.log('Error fetching service appointment details:', error);
                if (error && error.body && error.body.message && error.body.message === 'List has no rows for assignment to SObject') {
                    this.dispatchEvent(new CustomEvent('close'));
                    return;
                }
                showToast(this, 'Error', 'Something went wrong', 'error', error);
                this.dispatchEvent(new CustomEvent('close'));
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }



    mapRetrievedServiceAppointment(serviceAppointment) {
        const {
            OwnerId: saOwnerId,
            Is_Additional_Resource__c: isAdditionalResource,
            Check_In_Date_Time__c,
            Case__r: {
                Id: caseId,
                CaseNumber: caseNumber,
                Type: caseType,
                Subject: subject,
                Status: caseStatus,
                IsClosed: isClosed,
                Description: description,
                OwnerId: ownerId,
                Case_Sub_Type__c: caseSubType,
                Approval_Status__c: approvalStatus,
                Region__c: territory,
                Division__c: division,
                Additional_Resource_Request__c: additionalResourceRequest,
                Additional_Resource_Request_Date_Time__c: additionalResourceRequestDateTime,
                Additional_Resource_Request_Comment__c: additionalResourceRequestComment,
                Additional_Resource_Request_RSM_Comment__c: additionalResourceRequestRSMComment,
                Reassignment_Request__c: reassignmentRequest,
                Reassignment_Request_Date_Time__c: reassignmentRequestDateTime,
                Reassignment_Request_Comment__c: reassignmentRequestComment,
                Reassignment_Request_RSM_Comment__c: reassignmentRequestRSMComment,
                Asset: {
                    Id: assetId,
                    Name: serialNumber,
                    Ship_to_Address__c,
                    Ship_To_City__c,
                    Ship_To_Region__c,
                    Ship_to_Pin__c,
                    Ship_to_Country__c,
                    Product2: {
                        Material_Group_5__c: materialGroup5
                    } = {}
                } = {},
                Case_Pincode__r: { Name: pincode } = {},
                Contact: contactFromCase = {},
                Account: accountFromCase = {},
                Case_Notified_By__c: caseNotifiedById,
                Case_Notified_By__r: caseNotifiedBy = {},
            } = {},
            Work_Order__c: workOrderId = '',
            ContentDocumentLinks: contentDocumentLinks = [],
            Service_Appointment_Check_Ins_and_Outs__r: checkInsAndOuts = []
        } = serviceAppointment;

        const addressComponents = [
            Ship_to_Address__c,
            Ship_To_City__c,
            Ship_To_Region__c,
            Ship_to_Country__c,
            Ship_to_Pin__c
        ].filter(Boolean).join(' ');

        this.serviceAppointment = {
            accountId: accountFromCase.Id,
            customerName: accountFromCase.Name,
            Check_In_Date_Time__c,
            isCustomerBlocked: accountFromCase.Customer_Blocked__c,
            approvalStatus,
            contactId: contactFromCase.Id,
            contactName: contactFromCase.Name,
            email: contactFromCase.Email,
            phone: contactFromCase.MobilePhone,
            caseNotifiedById,
            caseNotifiedByName: caseNotifiedBy.Name,
            caseNotifiedByEmail: caseNotifiedBy.Email,
            caseNotifiedByPhone: caseNotifiedBy.MobilePhone,
            caseNumber,
            ownerId,
            saOwnerId,
            address: addressComponents,
            caseType,
            caseSubType,
            caseStatus,
            isClosed,
            subject,
            description,
            territory,
            pincode,
            division,
            id: this.recordId,
            caseId,
            workOrderId,
            assetId,
            serialNumber,
            materialGroup5: materialGroup5 || '',
            // checkInGeoLocation,
            // checkOutGeoLocation,
            isAdditionalResource,
            additionalResourceRequest,
            additionalResourceRequestDateTime,
            additionalResourceRequestComment,
            additionalResourceRequestRSMComment,
            reassignmentRequest,
            reassignmentRequestDateTime,
            reassignmentRequestComment,
            reassignmentRequestRSMComment,
            get isAdditionalResourceRequestRequested() {
                return this.additionalResourceRequest === 'Requested';
            },
            get isReassignmentRequestRequested() {
                return this.reassignmentRequest === 'Requested';
            },
            contentDocumentLinks: contentDocumentLinks.map(link => ({
                ...link,
                get title() {
                    return link?.ContentDocument?.LatestPublishedVersion?.Title;
                },
                get url() {
                    return link?.ContentDocument?.LatestPublishedVersion?.VersionDataUrl + '?thumb=THUMB720BY480';
                }
            })),
            get isCaseOwnerAndUserSame() {
                return this.ownerId === Id;
            },
            checkInsAndOuts
        };


        if (this.serviceAppointment.saOwnerId != this.serviceAppointment.ownerId) {
            if (!this.serviceAppointment.isAdditionalResource) {
                this.dispatchEvent(new CustomEvent('close'));
            }
        }

        this.isAlreadyCheckin = !(!!serviceAppointment.Check_In_Date_Time__c);

        if (this.serviceAppointment.isCustomerBlocked) {
            const division = this.serviceAppointment.division;
            const approvalStatus = this.serviceAppointment.approvalStatus;
            if (['MHE', 'CNPL', 'Hanel'].includes(division)) {
                showToast(this, 'Error', 'Customer is blocked, please contact your manager.', 'error');
                this.dispatchEvent(new CustomEvent('close'));
            }
            else if (division === 'Printer') {
                if (approvalStatus === 'Submitted') {
                    showToast(this, 'Error', 'Customer is blocked. Case is already submitted to Vertical Head for approval.', 'error');
                    this.dispatchEvent(new CustomEvent('close'));
                }
                else if (approvalStatus === 'Rejected') {
                    showToast(this, 'Error', 'Customer is blocked. Case is already rejected by Vertical Head.', 'error');
                    this.dispatchEvent(new CustomEvent('close'));
                }
            }
        }

        if (this.serviceAppointment.isClosed) {
            this.dispatchEvent(new CustomEvent('close'));
        }

        if (this.isDesktop) {
            // this.subscribeToChangeDataCapture();
            this.subscribeToPlatformEvent();
        }
        else {
            if (this.getServiceAppointmentDetailsInterval) {
                clearInterval(this.getServiceAppointmentDetailsInterval);
            }
            this.getServiceAppointmentDetailsInterval = setInterval(() => {
                console.log('getServiceAppointmentDetailsInterval', new Date().toISOString());
                this.handleGetServiceAppointmentDetails();
            }, 30000);
        }
    }



    toggleDescription(event) {
        const textElement = event.target;

        // Toggle between showing and hiding the overflow by adjusting the class
        if (textElement.classList.contains('truncate')) {
            textElement.classList.remove('truncate');
            textElement.classList.add('expanded');
        } else {
            textElement.classList.remove('expanded');
            textElement.classList.add('truncate');
        }
    }



    async handleCheckInClick() {
        this.showSpinner = true;
        try {
            const myLocation = await handleGetGeoLocation(this);
            console.log('myLocation', myLocation);
            updateCheckInLocation({
                recordId: this.recordId,
                latitude: myLocation.latitude,
                longitude: myLocation.longitude,
                deviceType: this.deviceType
            })
                .then((result) => {
                    console.log('result', result);
                    showToast(this, 'Success', 'Checked In Successfully', 'success');
                    this.mapRetrievedServiceAppointment(result);
                })
                .catch((error) => {
                    console.log('error', error);
                    showToast(this, 'Error', 'Something went wrong', 'error', error);
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }
        catch (error) {
            console.log('error', error);
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
        finally {
            this.showSpinner = false;
        }
    }



    async handleCheckOutClick() {
        openLightningModal(this, fieldServiceServiceAppCheckOut, {
            serviceAppointmentId: this.serviceAppointment.id
        },
            (result) => {
                console.log('result', result);
                if (result) {
                    if (result.action) {
                        if (result.action === 'checkout-and-close-case') {
                            console.log('handleCloseCaseClick with checkout-and-close-case');
                            navigateToLWC(this, 'fieldServiceCloseCase', { c__id: this.serviceAppointment.caseId, c__serviceAppointmentId: this.recordId });
                        }
                        if (result.action === 'location-disabled') {

                        }
                        else {
                            this.dispatchEvent(new CustomEvent('close'));
                        }
                    }
                    else {
                        this.handleGetServiceAppointmentDetails();
                    }
                }
            });
    }





    @track isRequestAdditionalResourceModalOpen = false;
    @track isRequestReAssignmentModalOpen = false;
    @track requestAdditionResourceComment = '';
    @track requestReAssignmentComment = '';
    @track proposedDate = '';
    @track minDate = new Date().toISOString().split('T')[0];

    handleCommentsChange(event) {
        const comment = event.target.value;
        if (this.isRequestAdditionalResourceModalOpen) {
            this.requestAdditionResourceComment = comment;
            console.log('requestAdditionResourceComment', this.requestAdditionResourceComment);

        } else if (this.isRequestReAssignmentModalOpen) {
            this.requestReAssignmentComment = comment;
            console.log('requestReAssignmentComment', this.requestReAssignmentComment);

        }
    }

    handleDateChange(event) {
        this.proposedDate = event.target.value;
    }

    handleCloseModal() {
        this.isRequestAdditionalResourceModalOpen = false;
        this.isRequestReAssignmentModalOpen = false;
        this.requestAdditionResourceComment = '';
        this.requestReAssignmentComment = '';
        this.proposedDate = '';
    }

    // handleAdditionalResourceRequestSubmit() {
    //     console.log('handleAdditionalResourceRequestSubmit');
    //     if (!this.requestAdditionResourceComment) {
    //         const element = this.template.querySelector('.request-additional-resource-comment');
    //         if (element) {
    //             element.setCustomValidity('This field is required');
    //             element.reportValidity();
    //         } else {
    //             showToast(this, 'Error', 'Comment is required to request additional resource.', 'error');
    //         }
    //     }
    //     else {
    //         this.showSpinner = true;
    //         updateCaseResource({ caseId: this.serviceAppointment.caseId, comment: this.requestAdditionResourceComment })
    //             .then(result => {
    //                 console.log('result', result);
    //                 this.handleGetServiceAppointmentDetails();
    //                 this.handleCloseModal();
    //             })
    //             .catch(error => {
    //                 console.error('Error updating resource request:', error);
    //                 showToast(this, 'Error', 'Something went wrong', 'error', error);
    //             })
    //             .finally(() => {
    //                 this.showSpinner = false;
    //             });
    //     }
    // }

    handleRequestReAssignmentSubmit() {
        console.log('handleRequestReAssignmentSubmit');
        if (!this.requestReAssignmentComment) {
            const element = this.template.querySelector('.request-re-assignment-comment');
            if (element) {
                element.setCustomValidity('This field is required');
                element.reportValidity();
            } else {
                showToast(this, 'Error', 'Comment is required to request re-assignment.', 'error');
            }
        } else {
            this.showSpinner = true;
            reassignCase({ caseId: this.serviceAppointment.caseId, comment: this.requestReAssignmentComment })
                .then(result => {
                    console.log('result', result);
                    this.handleGetServiceAppointmentDetails();
                    this.handleCloseModal();
                })
                .catch(error => {
                    console.error('Error reassigning case:', error);
                    showToast(this, 'Error', 'Something went wrong', 'error', error);
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }
    }


    handleAdditionalResourceRequestSubmit() {
        this.showSpinner = true;

        if (!this.proposedDate || !this.requestAdditionResourceComment?.trim()) {
            showToast(this, 'Error', 'Please fill required fields', 'error');
            this.showSpinner = false;
            return;
        }

        const selectedDate = new Date(this.proposedDate);
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        if (selectedDate < today) {
            showToast(this, 'Error', 'Proposed date cannot be in the past', 'error');
            this.showSpinner = false;
            return;
        }

        updateCaseResource({
            caseId: this.serviceAppointment.caseId,
            comment: this.requestAdditionResourceComment,
            proposedDate: this.proposedDate
        })
            .then(result => {
                console.log('result', result);
                this.handleGetServiceAppointmentDetails();
                this.handleCloseModal();
                showToast(this, 'Success', 'Resource request submitted successfully', 'success');
            })
            .catch(error => {
                console.error('Error updating resource request:', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }





    @track isFileUploadModalOpen = false;

    handleCloseFileUploadModal() {
        this.isFileUploadModalOpen = false;
    }

    handleNavigateToFilePreview(event) {
        event.preventDefault();
        const { id } = event.currentTarget.dataset;
        navigateToFilePreview(this, id);
    }





    handleRequestAdditionalResourceClick() {
        console.log('handleRequestAdditionalResourceClick');

        if (this.serviceAppointment.reassignmentRequest) {
            showToast(this, 'Error', 'Case already has re-assignment request pending, cannot raise additional resource request', 'error');
            return;
        }

        if (this.serviceAppointment.additionalResourceRequest === 'Requested') {
            showToast(this, 'Additional Resource Request', 'Additional resource request has already been submitted ' + (this.serviceAppointment.additionalResourceRequestComment ? ' with comment - ' + this.serviceAppointment.additionalResourceRequestComment : ''), 'warning');
        }
        // else if (this.serviceAppointment.additionalResourceRequest === 'Approved') {
        //     showToast(this, 'Additional Resource Request', 'Additional resource request has been approved' + (this.serviceAppointment.additionalResourceRequestRSMComment ? ' with comment - ' + this.serviceAppointment.additionalResourceRequestRSMComment : ''), 'success');
        // }
        else if (this.serviceAppointment.additionalResourceRequest === 'Rejected') {
            showToast(this, 'Additional Resource Request', 'Additional resource request has been rejected ' + (this.serviceAppointment.additionalResourceRequestRSMComment ? ' with comment - ' + this.serviceAppointment.additionalResourceRequestRSMComment : ''), 'error');
        }
        else {
            this.isRequestAdditionalResourceModalOpen = true;
        }
    }

    handleRequestReAssignmentClick() {
        console.log('handleRequestReAssignmentClick');

        if (this.serviceAppointment.isAdditionalResourceRequestRequested) {
            showToast(this, 'Error', 'Case already has additional resource request pending, cannot raise re-assignment request', 'error');
            return;
        }

        if (this.serviceAppointment.reassignmentRequest === 'Requested') {
            showToast(this, 'Re-Assignment Request', 'Re-assignment request has been submitted ' + (this.serviceAppointment.reassignmentRequestComment ? ' with comment - ' + this.serviceAppointment.reassignmentRequestComment : ''), 'warning');
        }
        else if (this.serviceAppointment.reassignmentRequest === 'Rejected') {
            showToast(this, 'Re-Assignment Request', 'Re-assignment request has been rejected ' + (this.serviceAppointment.reassignmentRequestRSMComment ? ' with comment - ' + this.serviceAppointment.reassignmentRequestRSMComment : ''), 'error');
        }
        else {
            this.isRequestReAssignmentModalOpen = true;
        }
    }

    handleAddNewContactClick() {
        console.log('handleAddNewContactClick');
        /*
        const defaultValues = encodeDefaultFieldValues({
            AccountId: this.serviceAppointment.accountId
        });
        navigateToObjectPage(this, 'Contact', 'new', { defaultFieldValues: defaultValues });
        */
        openLightningModal(this, addNewContactModal,
            { accountId: this.serviceAppointment.accountId, assetId: this.serviceAppointment.assetId, caseId: this.serviceAppointment.caseId, serviceAppointmentId: this.serviceAppointment.id },
            (result) => {
                console.log('result', result);
                this.handleGetServiceAppointmentDetails();
            });
    }

    @track uploaderClass = 'slds-hide';
    handleUploadFileClick() {
        this.isFileUploadModalOpen = true;
    }

    filesToUpload = [];
    uploadedCount = 0;
    handleFileSelect(event) {
        const files = event.target.files;
        let newFilesSize = 0;
        let existingSizeBytes = 0;

        if (this.serviceAppointment.contentDocumentLinks.length > 0) {
            this.serviceAppointment.contentDocumentLinks.forEach(element => {
                existingSizeBytes += element.ContentDocument.LatestPublishedVersion.ContentSize;
            });
        }

        for (let i = 0; i < files.length; i++) {
            newFilesSize += files[i].size;
        }

        const totalSize = existingSizeBytes + newFilesSize;
        const maxSizeBytes = 2 * 1024 * 1024;

        if (totalSize > maxSizeBytes) {
            // alert('Total file size exceeds 2MB. Please remove some files.');
            showToast(this, '', 'Total file size exceeds 2MB.', 'info');
        } else {
            this.filesToUpload = Array.from(files);
            this.uploadedCount = 0;

            if (this.filesToUpload.length === 0) return;

            this.filesToUpload.forEach((file, index) => {
                const reader = new FileReader();
                reader.onloadend = () => {
                    const base64 = reader.result.split(',')[1];
                    this.handlerUploadFile(file.name, base64, file.type);
                };
                reader.readAsDataURL(file);
            });
        }
    }

    handleDeleteFile(event) {
        event.preventDefault();
        const { id: recordId } = event.currentTarget.dataset;
        this.showSpinner = true;
        deleteRecord(recordId)
            .then(() => {
                this.handleGetServiceAppointmentDetails();
            })
            .catch(error => {
                console.error('Error deleting file', error);
                showToast(this, '', 'Error deleting file', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handlerUploadFile(fileName, base64Data, fileType) {
        this.showSpinner = true;
        console.log('IN UPLOAD METHOD:>> ');
        showToast(this, '', 'Uploading File, Please wait', 'info');
        uploadFileToServer({ // Apex method
            fileName: fileName,
            base64Data: base64Data,
            contentType: fileType,
            recordId: this.recordId
        }).then(() => {
            console.log('File uploaded successfully');
            this.uploadedCount++;
            if (this.uploadedCount === this.filesToUpload.length) {
                // All files uploaded
                console.log('LAST FILE UPLOADED');
                this.handleGetServiceAppointmentDetails();
                showToast(this, '', 'Files are Uploaded', 'success');
                this.showSpinner = false;
            }
        }).catch(error => {
            this.showSpinner = false;
            console.error('Upload failed', error);
        });
    }

    handleTroubleshootingClick() {
        console.log('handleTroubleshootingClick');
        console.log('Division:', this.serviceAppointment.division);
        // navigateToLWC(this, 'fieldServiceTroubleshooting', { c__id: this.serviceAppointment.workOrderId, c__serviceAppointmentId: this.recordId });
        if (this.serviceAppointment.division === 'MHE' || this.serviceAppointment.division === 'Printer') {
            navigateToUrl(this, 'https://nilkamal-my.sharepoint.com/:f:/p/shital_jadhav/En5WiHb6htZAjlfJvqQb1xcBhLuqBeMh-HS7bMTIcv0Iiw');
        }
    }

    handleActivityChecklistClick() {
        console.log('handleActivityChecklistClick');
        navigateToLWC(this, 'fieldServiceActivityChecklist', { c__id: this.serviceAppointment.workOrderId, c__serviceAppointmentId: this.recordId });
    }

    handlePMChecklistClick() {
        console.log('handlePMChecklistClick');
        navigateToLWC(this, 'fieldServicePMChecklist', { c__id: this.serviceAppointment.workOrderId, c__serviceAppointmentId: this.recordId });
    }

    handleAssetHistoryClick() {
        console.log('handleAssetHistoryClick');
        // navigateToLWC(this, 'caseHistory', { c__id: this.serviceAppointment.caseId });
        navigateToLWC(this, 'fieldServiceAssetHistory', { c__id: this.serviceAppointment.assetId });
    }

    handleActivityLoggingClick() {
        console.log('handleActivityLoggingClick');
        navigateToLWC(this, 'activityLogging', { c__workOrderId: this.serviceAppointment.workOrderId, c__serviceAppointmentId: this.recordId });
    }

    handleSpareRequestClick() {
        console.log('handleSpareRequestClick');
        navigateToLWC(this, 'fieldServiceSpareRequest', { c__id: this.serviceAppointment.workOrderId, c__serviceAppointmentId: this.recordId, c__caseId: this.serviceAppointment.caseId, c__assetId: this.serviceAppointment.assetId });
    }

    handleEditSpareClick() {
        console.log('handleEditSpareClick');
        navigateToLWC(this, 'fieldServiceEditSpareRequest', { c__workOrderId: this.serviceAppointment.workOrderId, c__serviceAppointmentId: this.recordId });
    }

    handleCreateEnquiryClick() {
        console.log('handleCreateEnquiryClick');
        navigateToLWC(this, 'raiseOppAndQuote', { c__recordId: this.serviceAppointment.workOrderId });
    }

    handleInstallationReportClick() {
        console.log('handleInstallationReportClick');
        console.log('division', this.serviceAppointment.division);
        const division = this.serviceAppointment.division;
        if (['MHE', 'CNPL', 'Hanel'].includes(division)) {
            console.log('division', division);
            // navigateToLWC(this, 'fieldServiceCaptureSignature', { c__id: this.serviceAppointment.workOrderId, c__mode: 'InstallationReport' });
            navigateToLWCWithReload(this, 'fieldServiceInstallationAndServiceReport', { c__workOrderId: this.serviceAppointment.workOrderId, c__serviceAppointmentId: this.recordId, c__reportType: 'InstallationReport' });
        }
        else if (division === 'Printer') {
            console.log('division', division);
            navigateToLWC(this, 'fieldServicePrinterInstallationAndServiceReport', { c__workOrderId: this.serviceAppointment.workOrderId, c__serviceAppointmentId: this.recordId, c__reportType: 'InstallationReport' });
        }
    }

    handleServiceReportClick() {
        console.log('handleServiceReportClick');
        const division = this.serviceAppointment.division;
        if (['MHE', 'CNPL', 'Hanel'].includes(division)) {
            console.log('division', division);
            // navigateToLWC(this, 'fieldServiceCaptureSignature', { c__id: this.serviceAppointment.workOrderId, c__mode: 'ServiceReport' });
            navigateToLWCWithReload(this, 'fieldServiceInstallationAndServiceReport', { c__workOrderId: this.serviceAppointment.workOrderId, c__serviceAppointmentId: this.recordId, c__reportType: 'ServiceReport' });
        }
        else if (division === 'Printer') {
            console.log('division', division);
            navigateToLWC(this, 'fieldServicePrinterInstallationAndServiceReport', { c__workOrderId: this.serviceAppointment.workOrderId, c__serviceAppointmentId: this.recordId, c__reportType: 'ServiceReport' });
        }
    }

    handleSpareReturnClick() {
        console.log('handleSpareReturnClick');
        navigateToLWC(this, 'fieldServiceSpareReturn', { c__id: this.serviceAppointment.workOrderId });
    }

    handleServiceRequestClick() {
        console.log('handleServiceRequestClick');
        navigateToLWC(this, 'fieldServiceRequest', { c__id: this.serviceAppointment.workOrderId, c__serviceAppointmentId: this.recordId, c__caseId: this.serviceAppointment.caseId });
    }

    handleCloseCaseClick() {
        console.log('handleCloseCaseClick');
        navigateToLWC(this, 'fieldServiceCloseCase', { c__id: this.serviceAppointment.caseId, c__serviceAppointmentId: this.recordId, c__workOrderId: this.serviceAppointment.workOrderId, c__doCheckOutAlso: false });
    }





    get acceptedFormats() {
        return ['.png', '.jpg', '.jpeg', '.heic', '.PNG', '.JPG', '.JPEG', '.HEIC'];
    }





    get isAddContactVisible() {
        if (this.serviceAppointment.division === 'MHE') {
            return true;
        }
        return true;
    }

    get isTroubleshootingVisible() {
        if (this.serviceAppointment.division === 'MHE') {
            if (['Payment Collection', 'AMC Business'].includes(this.serviceAppointment.caseSubType)) {
                return false;
            }
            return true;
        }
        return true;
    }

    get isChecklistVisible() {
        if (this.serviceAppointment.division === 'MHE') {
            if (['Payment Collection', 'AMC Business'].includes(this.serviceAppointment.caseSubType)) {
                return false;
            }
            return true;
        }
        return true;
    }

    get isPMChecklistVisible() {
        // PM Checklist is only visible for CIJ (P01) printers
        const mg5 = this.serviceAppointment.materialGroup5;
        if (mg5 && mg5.toUpperCase().includes('P01')) {
            return true;
        }
        return false;
    }

    get isHistoryVisible() {
        if (this.serviceAppointment.division === 'MHE') {
            return true;
        }
        return true;
    }

    get isInstallationReportVisible() {
        if (this.serviceAppointment.division === 'MHE') {
            if (['Installation & Commissioning', 'DEMO', 'Re-installation'].includes(this.serviceAppointment.caseSubType)) {
                if (!this.serviceAppointment.isAdditionalResource) {
                    return true;
                }
                return false;
            }
            return false;
        }
        return true;
    }

    get isServiceReportVisible() {
        if (this.serviceAppointment.division === 'MHE') {
            if (!this.serviceAppointment.isAdditionalResource) {
                return true;
            }
            return false;
        }
        return true;
    }

    get isSpareRequestVisible() {
        if (this.serviceAppointment.division === 'MHE') {
            return true;
        }
        return true;
    }

    get isServiceRequestVisible() {
        if (this.serviceAppointment.division === 'MHE') {
            if (['Installation & Commissioning', 'Warranty Breakdown', 'AMC Breakdown', 'CAMC Breakdown',].includes(this.serviceAppointment.caseSubType)) {
                return false;
            }
            return true;
        }
        return true;
    }







    checkVisibility(action) {
        const { division, caseType, caseSubType } = this.serviceAppointment;

        // Define visibility rules per division
        const visibilityRules = {
            'MHE': {
                'Installation': ['Installation & Commissioning'],
                'Preventive Maintenance': ['Warranty PM', 'AMC PM', 'CAMC PM', 'Health Checkup'],
                'Breakdown': ['Warranty Breakdown', 'AMC Breakdown', 'CAMC Breakdown', 'Chargeable Service'],
                'Courtesy': ['Courtesy Breakdown', 'Quote Negotiation', 'Payment Collection', 'AMC Business', 'Spare Business', 'DEMO', 'Spare installation'],   // AMC Business added by keshav
                'Re-Installation': ['Re-installation'],
                'Training': ['Training']
            },
            'Hanel': {
                'Installation': ['New Installation & Commissioning'],
                'Preventive Maintenance': ['Warranty PM', 'AMC PM', 'CAMC PM', 'Health Checkup'],
                'Breakdown': ['Warranty Breakdown', 'AMC Breakdown', 'CAMC Breakdown', 'Chargeable Service'],
                'Courtesy': ['Courtesy visit', 'Sales DEMO at existing HANEL place', 'Spare supply / Service invoice need to be handed over to customer plant', 'Spare installation'],
                'Re-Installation': ['Dismantling into CKD form', 'Packaging monitoring', 'Loading & Unloading', 'Re-installation as per HANEL standard'],
                'Training': ['Chargeable cum Refresh Training Cum usage awareness']
            },
            'CNPL': {
                'Installation': ['Installation & Commissioning'],
                'Preventive Maintenance': ['Warranty PM', 'AMC PM', 'CAMC PM', 'Health Checkup'],
                'Breakdown': ['Warranty Breakdown', 'AMC Breakdown', 'CAMC Breakdown', 'Chargeable Service'],
                'Courtesy': ['Courtesy', 'DEMO', 'Spare installation'],
                'Re-Installation': ['Re-installation'],
                'Training': ['Training']
            },
            'Printer': {
                'Installation': ['Own Asset', 'Dealer Asset'],
                'Preventive Maintenance': ['Own Asset', 'Dealer Asset'],
                'Breakdown': ['Own Asset', 'Dealer Asset'],
                'Courtesy': ['Spare installation'],
                'Re-Installation': [],
                'Training': [],
                'Demo': []
            }
        };

        // Action-wise visibility mapping (applicable for all divisions)
        const actionMapping = {
            'MHE': {
                'Add Contact': true,
                'Troubleshooting': !['Payment Collection', 'AMC Business'].includes(caseSubType),  // AMC Business added by keshav
                'Checklist': !['Payment Collection', 'AMC Business'].includes(caseSubType),      // AMC Business added by keshav
                'Asset History': true,
                'Installation report': ['Installation & Commissioning', 'Re-installation'].includes(caseSubType),
                'Service Report': true,
                'Spare request': true,
                'Service request': !['Installation & Commissioning', 'Warranty PM', 'AMC PM', 'CAMC PM', 'Warranty Breakdown', 'AMC Breakdown', 'CAMC Breakdown'].includes(caseSubType),
                'Close': true,
            },
            'Printer': {
                'Add Contact': true,
                'Troubleshooting': true,
                'Checklist': true,
                'Asset History': true,
                'Installation report': ['Installation', 'Re-Installation'].includes(caseType),
                'Service Report': true,
                'Spare request': true,
                'Service request': true,
                'Close': true,
            },
            'Hanel': {
                'Add Contact': true,
                'Troubleshooting': true,
                'Checklist': true,
                'Asset History': true,
                'Installation report': ['Installation & Commissioning', 'Re-installation'].includes(caseSubType),
                'Service Report': true,
                'Spare request': true,
                'Service request': true,
                'Close': true,
            },
            'CNPL': {
                'Add Contact': true,
                'Troubleshooting': true,
                'Checklist': true,
                'Asset History': true,
                'Installation report': true,
                'Service Report': true,
                'Spare request': true,
                'Service request': true,
                'Close': true,
            }
        };
        // Check if the division exists in rules
        if (visibilityRules[division]) {
            // Check if caseType exists in the division
            if (visibilityRules[division][caseType]) {
                // If caseSubType is in the allowed list, apply action visibility
                if (visibilityRules[division][caseType].includes(caseSubType)) {
                    return actionMapping[action] ?? false;
                }
            }
        }

        return false;
    }

    @track isTechSupportModalOpen = false;
    @track technicalSupportComments = '';
    @track charCount = 0;
    maxCharCount = 254;

    handleTechnicalSupportClick() {
        // this.isTechSupportModalOpen = true;
        updateTechSupport({ caseId: this.serviceAppointment.caseId })
            .then((res) => {
                if (res) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.serviceAppointment.caseId,
                            objectApiName: 'Case',
                            actionName: 'view'
                        },
                        state: {
                            // Opens the Chatter tab (Feed tab)
                            view: 'feed'
                        }
                    });
                } else {
                    showToast(this, 'Error', 'Something went wrong!', 'error');
                }
            })



    }

    closeTechSupportModal() {
        this.isTechSupportModalOpen = false;
    }

    handleTechSupportCommentChange(event) {
        // this.technicalSupportComments = event.target.value;
        // console.log('technicalSupportComments', this.technicalSupportComments);
        // this.charCount = this.technicalSupportComments.length;
        // console.log('charCount', this.charCount);
        let value = event.target.value;
        if (value.length > this.maxCharCount) {
            value = value.substring(0, this.maxCharCount);
        }
        this.technicalSupportComments = value;
        this.charCount = value.length;
    }

    // submitTechSupport() {
    //     console.log('Submitted Comments:', this.technicalSupportComments);
    //     // Add your server-side logic here if needed

    //     this.isTechSupportModalOpen = false;
    // }



    submitTechSupport() {
        console.log('submitTechSupport');
        // if (!this.technicalSupportComments || this.technicalSupportComments.trim() === '') {
        //     commentField.setCustomValidity('This field is required');
        //     commentField.reportValidity();
        //     return;
        // }

        // if (this.technicalSupportComments.length < 5) {
        //     commentField.setCustomValidity('Comment must be at least 5 characters');
        //     commentField.reportValidity();
        //     return;
        // }

        // if (this.technicalSupportComments.length > this.maxCharCount) {
        //     commentField.setCustomValidity(`Comment cannot exceed ${this.maxCharCount} characters`);
        //     commentField.reportValidity();
        //     return;
        // }

        // commentField.setCustomValidity('');
        // commentField.reportValidity();

        if (!this.technicalSupportComments) {
            const commentField = this.template.querySelector('.technical-support-comment');
            if (commentField) {
                commentField.setCustomValidity('This field is required');
                commentField.reportValidity();
            } else {
                showToast(this, 'Error', 'Comment is required for technical support.', 'error');
            }
        } else {
            this.showSpinner = true;
            console.log(
                this.serviceAppointment.caseId,
                this.technicalSupportComments
            );

            submitTechnicalSupport({
                caseId: this.serviceAppointment.caseId,
                comment: this.technicalSupportComments
            })
                .then(result => {
                    console.log('Technical Support submitted:', result);
                    this.technicalSupportComments = '';
                    this.charCount = 0;
                    showToast(this, 'Success', 'Technical Support submitted successfully.', 'success');
                    this.closeTechSupportModal();
                })
                .catch(error => {
                    console.error('Error submitting technical support:', error);
                    showToast(this, 'Error', 'Something went wrong', 'error', error);
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }
    }

    @track todaysDate = new Date();
    @track current_view_month = this.todaysDate.getMonth();
    @track current_view_year = this.todaysDate.getFullYear();
    @track current_view_day = this.todaysDate.getDate();

    @track today = `${this.todaysDate.getFullYear()}-${String(this.todaysDate.getMonth() + 1).padStart(2, '0')}-${String(this.todaysDate.getDate()).padStart(2, '0')}`;

    @track isRescheduleDate = false;
    @track rescheduleDate = '';
    handleReschedule() {
        this.isRescheduleDate = true;
    }

    handleChange(event) {
        this.rescheduleDate = event.target.value;
    }

    CancelClick() {
        this.isRescheduleDate = false;
    }

    updateReschedule() {
        const rescheduleDateElement = this.template.querySelector('lightning-input[data-name="Scheduled_Start__c"]');
        if (rescheduleDateElement.checkValidity() === false) {
            rescheduleDateElement.reportValidity();
            showToast(this, 'Error', 'Appointment date cannot be in the past', 'error');
            return;
        }

        this.showSpinner = true;
        updateRescheduleDate({ recordId: this.recordId, scheduleDate: this.rescheduleDate })
            .then(result => {
                console.log('result', result);
                this.isRescheduleDate = false;
                this.rescheduleDate = '';
                this.dispatchEvent(new CustomEvent('close'));
            })
            .catch(error => {
                console.log('Error updating reschedule date:', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

}