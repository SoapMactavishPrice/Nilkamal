import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';

//import { navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage } from 'c/utilJS';
//import { getNameAndValueOnChange } from 'c/utilJS';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import CASE_TYPE from '@salesforce/schema/Case.Type';
import getServiceAppointmentId from '@salesforce/apex/FieldServiceCaptureInteraction.getServiceAppointmentsByServiceAppointmentId';
import getChecklistData from '@salesforce/apex/FieldServiceCaptureInteraction.getChecklistData';
import saveChecklistData from '@salesforce/apex/FieldServiceCaptureInteraction.saveChecklistData';
import { CurrentPageReference } from 'lightning/navigation';
import getServiceAppointment from '@salesforce/apex/FieldServiceCaptureInteraction.getServiceAppointment';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, scrollToTop, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh } from 'c/utilJS';








export default class FieldServiceCaptureInteraction extends NavigationMixin(LightningElement) {

    @api workorderId;
    @api recordId;
    @api objectApiName;

    @track showSpinner = false;

    @track caseId;
    @track meetingId;

    @track caseTypeOptions = [];

    @track record = {};
    @track serviceAppointmentId;
    serviceAppointments = [];

    get contactFilter() {
        if (this.record.Account__c && this.caseId) {
            return {
                criteria: [
                    {
                        fieldPath: 'AccountId',
                        operator: 'eq',
                        value: this.record.Account__c,
                    },
                    {
                        fieldPath: 'AccountId',
                        operator: 'eq',
                        value: this.caseId,
                    }
                ],
                filterLogic: '1 OR 2',
            }
        }
        else if (this.record.Account__c) {
            return {
                criteria: [
                    {
                        fieldPath: 'AccountId',
                        operator: 'eq',
                        value: this.record.Account__c
                    }
                ]
            };
        }
        else if (this.caseId) {
            return {
                criteria: [
                    {
                        fieldPath: 'AccountId',
                        operator: 'eq',
                        value: this.caseId
                    }
                ]
            };
        }
        return undefined;
    }


    get checkInOptions() { return [{ label: 'Customer Office', value: 'Customer Office' }, { label: 'Customer Plant', value: 'Customer Plant' }, { label: 'End Customer', value: 'End Customer' }]; }
    get isCheckInCustomerOffice() { return this.record.Check_In__c === 'Customer Office'; }
    get isCheckInCustomerPlant() { return this.record.Check_In__c === 'Customer Plant'; }
    get isCheckInEndCustomer() { return this.record.Check_In__c === 'End Customer'; }


    @wire(getObjectInfo, { objectApiName: 'Case' })
    wireCaseInfo;

    @wire(getPicklistValues, { recordTypeId: '$wireCaseInfo.data.defaultRecordTypeId', fieldApiName: CASE_TYPE })
    wireCaseTypeOptions({ data, error }) {
        if (data) { this.caseTypeOptions = data.values; }
        else if (error) { showToast(this, 'Error', 'Something went wrong', 'error', error); }
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.workorderId = currentPageReference.state.c__id;
        this.recordId = currentPageReference.state.c__serviceAppointmentId;
        // console.log('this.recordId', this.recordId);
        this.fetchServiceAppointments();
        this.loadChecklistData();
        this.fetchServiceAppointmentData();
    }

    @track isReadOnly;

    fetchServiceAppointmentData() {
        getServiceAppointment({ recordId: this.recordId })
            .then(result => {
                this.record = result;
                if (this.record.Status__c == 'Completed' || this.record.Case__r.Status == 'Closed') {
                    this.isReadOnly = true;
                }
                else {
                    this.isReadOnly = false;
                }
            })
            .catch(error => {
                console.error('Error fetching Service Appointment:', error);
            });
    }


    connectedCallback() {
        analyzeUserAgent(this);
        disablePullToRefresh(this);
    }

    renderedCallback() {
        analyzeFormFactor(this);
    }



    handleRecordChange(event) {
        const { name, value } = getNameAndValueOnChange(this, event);
        this.record[name] = value;
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
            }
        }
    }


    handleMeetingClick(event) {
        const { id: recordId, workOrderId } = event.currentTarget.dataset;
        this.navigateToLWC(workOrderId, recordId);
    }

    fetchServiceAppointments() {
        getServiceAppointmentId({ serviceAppointmentId: this.recordId })
            .then(result => {
                this.serviceAppointments = result;
                console.log('serviceAppointments--length', result.length);

                console.log('serviceAppointments', this.serviceAppointments);

                let recs = [];
                for (let i = 0; i < this.serviceAppointments.length; i++) {
                    let opp = Object.assign({}, JSON.parse(JSON.stringify(this.serviceAppointments[i])));

                    if (opp.Scheduled_End__c) {
                        opp.formattedScheduledEnd = this.formatDate(opp.Scheduled_End__c);
                    } else {
                        opp.formattedScheduledEnd = '01-01-2011';
                    }
                    recs.push(opp);
                }
                console.log('recs--------------', recs);
                this.serviceAppointments = recs;


                const matchedServiceAppointment = this.findServiceAppointmentByAccountId(this.recordId);

                if (matchedServiceAppointment) {
                    this.caseId = matchedServiceAppointment.Case__r.AccountId;
                } else {
                    this.caseId = null;
                }

            })
            .catch(error => {
                console.log('Error fetching Service Appointments:', error);
                this.error = error.body.message;
            });
    }

    formatDate(scheduledEndDate) {
        const date = new Date(scheduledEndDate);
        const day = String(date.getDate()).padStart(2, '0');
        const month = date.toLocaleString('en-US', { month: 'short' });  // Get the short month name (e.g., "May")
        const year = date.getFullYear();
        return `${day} ${month} ${year}`;
    }


    findServiceAppointmentByAccountId(recordId) {
        for (let i = 0; i < this.serviceAppointments.length; i++) {
            const appointment = this.serviceAppointments[i];
            if (appointment.Id === recordId) {
                return appointment;
            }
        }
        return null;
    }

    @track checklistItems = [];

    loadChecklistData() {
        getChecklistData({ workOrderId: this.workorderId })
            .then(result => {
                const groupedData = JSON.parse(JSON.stringify(result)).reduce((acc, item) => {
                    const category = item.Checklist_Category__c;

                    if (item.Observation__c) {
                        if (!acc.withObservation) {
                            acc.withObservation = {};
                        }
                        if (!acc.withObservation[category]) {
                            acc.withObservation[category] = [];
                        }
                        acc.withObservation[category].push(item);
                    }

                    if (!acc.allCheckpoints) {
                        acc.allCheckpoints = {};
                    }
                    if (!acc.allCheckpoints[category]) {
                        acc.allCheckpoints[category] = [];
                    }
                    acc.allCheckpoints[category].push(item);

                    return acc;
                }, {});

                this.checklistItemsWithObservation = Object.entries(groupedData.withObservation || {}).map(([category, checkpoints]) => ({
                    Checklist_Category__c: category,
                    checkpoints: checkpoints
                }));

                this.checklistItemsAll = Object.entries(groupedData.allCheckpoints || {}).map(([category, checkpoints]) => ({
                    Checklist_Category__c: category,
                    checkpoints: checkpoints
                }));

                console.log('With Observation:', this.checklistItemsWithObservation);
                console.log('All Checkpoints:', this.checklistItemsAll);
            })
            .catch(error => {
                console.error('Error fetching checklist data', error);
            });


    }

    organizeChecklistData(data) {

    }



    handleSubmit() {
        const formData = {
            recordId: this.recordId,
            Check_In__c: this.record.Check_In__c,
            Account__c: this.record.Account__c,
            Contact__c: this.record.Contact__c,
            Type: this.record.Type,
            Additional_Information__c: this.record.Additional_Information__c,
            workOrderId: this.workorderId
        };

        const workOrderChecklist = [];
        this.checklistItems.forEach(category => {
            category.checkpoints.forEach(checkpoint => {
                if (checkpoint.Observation__c) {
                    workOrderChecklist.push(checkpoint);
                }
            });
        })

        this.showSpinner = true;
        saveChecklistData({ formData, workOrderChecklist })
            .then(result => {
                showToast(this, 'Success', 'Checklist saved successfully', 'success');
                navigateToLWC(this, 'fieldServiceServiceAppointmentList');
            })
            .catch(error => {
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            });

    }

    navigateToLWC(workorderId, recordId) {
        navigateToLWC(this, 'fieldServiceCaptureInteraction', { c__id: workorderId, c__serviceAppointmentId: recordId });
    }




}