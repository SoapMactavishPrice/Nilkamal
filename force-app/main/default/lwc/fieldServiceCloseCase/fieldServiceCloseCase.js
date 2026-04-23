import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from 'lightning/refresh';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, navigateBackInHistory, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh } from 'c/utilJS';

import CaseField_CaseClosureReason from '@salesforce/schema/Case.Case_Closure_Reason__c';

import getCaseDetails from '@salesforce/apex/FieldServiceCloseCaseController.getCaseDetails';
import closeCase from '@salesforce/apex/FieldServiceCloseCaseController.closeCase';

import getChecklistData from '@salesforce/apex/FieldServiceCloseCaseController.getChecklistData';
// import getCountOfActivitiesLogged from '@salesforce/apex/FieldServiceCloseCaseController.getCountOfActivitiesLogged';
import getSpareRequestsByStatus from '@salesforce/apex/FieldServiceCloseCaseController.getSpareRequestsByStatus';
import getReportGeneratedOrNot from '@salesforce/apex/FieldServiceCloseCaseController.getReportGeneratedOrNot';
import getServiceRequestCount from '@salesforce/apex/FieldServiceCloseCaseController.getServiceRequestCount';








export default class FieldServiceCloseCase extends NavigationMixin(LightningElement) {
    @track showSpinner = true;

    @track caseId;
    @track serviceAppointmentId;
    @track workOrderId;

    @track doCheckOutAlso;
    @track latitude;
    @track longitude;

    @track isMobile;
    @track isTablet;
    @track isDesktop;

    @api reason;
    @api comment;

    @track caseDetails;

    // @track caseChecklistAnalysis = { 'markedYes': 0, 'markedNo': 0, 'markedNA': 0, 'blank': 0, 'total': 0 };
    @track caseChecklistAnalysis = { 'markedYes': 0, 'markedNo': 0, 'markedNA': 0, 'total': 0 };
    @track countOfActivities = 0;
    @track caseSpareRequestAnalysis = { 'requested': 0, 'billed': 0, 'dispatched': 0, 'installed': 0, 'replacement': 0, 'blank': 0, 'total': 0 };
    @track countOfCaseReports = 0;
    @track isReportGenerated = 'No';

    @track reportIds = {};
    @track serviceRequestCount = 0;




    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        this.caseId = currentPageReference.state.c__id;
        this.serviceAppointmentId = currentPageReference.state.c__serviceAppointmentId;
        this.workOrderId = currentPageReference.state.c__workOrderId;

        // this.doCheckOutAlso = currentPageReference.state.c__doCheckOutAlso;
        // this.latitude = currentPageReference.state.c__latitude;
        // this.longitude = currentPageReference.state.c__longitude;

        console.log('this.caseId', this.caseId, 'this.serviceAppointmentId', this.serviceAppointmentId);

        this.caseChecklistAnalysis = { 'markedYes': 0, 'markedNo': 0, 'total': 0 };
        this.countOfActivities = 0;
        this.caseSpareRequestAnalysis = { 'requested': 0, 'billed': 0, 'dispatched': 0, 'installed': 0, 'replacement': 0, 'blank': 0, 'total': 0 };
        this.countOfCaseReports = 0;
        this.isReportGenerated = 'No';
        this.reportIds = {};

        this.comment = '';
        this.reason = '';

        if (this.caseId) {
            this.handleGetCaseDetails();
            this.handleGetChecklistData();
            // this.handleGetCountOfActivitiesLogged();
            this.handleGetSpareRequestsByStatus();
            this.handleGetReportGeneratedOrNot();
            this.handleGetServiceRequestCount();
        }
    }


    @track reasonOptions;

    @wire(getObjectInfo, { objectApiName: 'Case' })
    wiredCaseObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$wiredCaseObjectInfo.data.defaultRecordTypeId', fieldApiName: CaseField_CaseClosureReason })
    wiredCaseClosureReasonOptions({ data, error }) {
        if (data) {
            this.reasonOptions = data.values;
        }
        else if (error) {
            console.log('wiredCaseClosureReasonOptions error', error, JSON.stringify(error));
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }





    connectedCallback() {
        console.log('connectedCallback from FieldServiceCloseCase');
        analyzeFormFactor(this);
        disablePullToRefresh(this);
    }


    renderedCallback() {
        console.log('renderedCallback from FieldServiceCloseCase');
        analyzeFormFactor(this);
    }


    handleReasonChange(event) {
        this.reason = event.target.value;
    }


    handleCommentChange(event) {
        this.comment = event.target.value;
    }


    handleGetCaseDetails() {
        this.showSpinner = true;
        getCaseDetails({ caseId: this.caseId })
            .then((result) => {
                console.log('getCaseDetails', result, JSON.stringify(result));
                this.caseDetails = result;

                if (this.caseDetails.Status == 'Closed') {
                    showToast(this, 'Error', 'Case is already closed', 'error');
                    navigateBackInHistory(this);
                }

                // this.validateActivityChecklist();
            })
            .catch((error) => {
                console.log('Error fetching case details:', error);
                showToast(this, 'Error', 'Error fetching case details', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }


    handleGetChecklistData() {
        getChecklistData({ caseId: this.caseId })
            .then((data) => {
                const { result, reportId } = data;
                console.log('getChecklistData', result, JSON.stringify(result));

                this.caseChecklistAnalysis = result;
                this.reportIds.checklists = reportId;

                this.validateActivityChecklist();
            })
            .catch((error) => {
                console.log('Error fetching case details:', error);
                showToast(this, 'Error', 'Error fetching checklist data', 'error', error);
            });
    }


    validateActivityChecklist() {
        const { caseDetails, caseChecklistAnalysis } = this;
        if (!caseDetails || !caseChecklistAnalysis) return;

        const validTypes = ['Installation', 'Preventive Maintenance', 'Re-Installation'];
        const validSubTypes = ['Installation & Commissioning', 'Warranty PM', 'AMC PM', 'CAMC PM', 'Health Checkup', 'Re-installation'];

        if (
            caseDetails.Division__c === 'MHE' &&
            validTypes.includes(caseDetails.Type) &&
            validSubTypes.includes(caseDetails.Case_Sub_Type__c) &&
            (caseChecklistAnalysis.total > 0 && caseChecklistAnalysis.blank !== 0)
        ) {
            showToast(this, 'Error', `Activity checklist is required for "${caseDetails.Case_Sub_Type__c}".`, 'error');
            // navigateBackInHistory(this);
            return false;
        }

        return true;
    }


    /*
    handleGetCountOfActivitiesLogged() {
        getCountOfActivitiesLogged({ caseId: this.caseId })
            .then((result) => {
                const { count, reportId } = result;
                this.countOfActivities = count;
                this.reportIds.activities = reportId;
            })
            .catch((error) => {
                console.log('Error fetching case details:', error);
                showToast(this, 'Error', 'Error fetching count of activities logged', 'error', error);
            });
    }
    */


    handleGetSpareRequestsByStatus() {
        getSpareRequestsByStatus({ caseId: this.caseId })
            .then((result) => {
                console.log('result', result);

                const { spareRequests, reportId } = result;
                this.reportIds.spareRequests = reportId;

                this.caseSpareRequestAnalysis = {
                    total: 0,
                    focReturnable: 0,
                    focNonReturnable: 0,
                    chargeable: 0
                };

                if (spareRequests && Array.isArray(spareRequests) && spareRequests.length > 0) {
                    spareRequests.forEach(item => {
                        const billingType = item.Billing_Type__c;
                        const cnt = item.cnt;
                        this.caseSpareRequestAnalysis.total += cnt;

                        if (billingType === 'FOC and Returnable') {
                            this.caseSpareRequestAnalysis.focReturnable += cnt;
                        } else if (billingType === 'FOC and Non-Returnable') {
                            this.caseSpareRequestAnalysis.focNonReturnable += cnt;
                        } else if (billingType === 'Chargeable') {
                            this.caseSpareRequestAnalysis.chargeable += cnt;
                        }
                    });
                }
            })
            .catch((error) => {
                console.log('Error fetching case details:', error);
                showToast(this, 'Error', 'Error fetching spare requests', 'error', error);
            });
    }


    handleGetServiceRequestCount() {
        getServiceRequestCount({ caseId: this.caseId })
            .then(count => {
                console.log('getServiceRequestCount', count);
                this.serviceRequestCount = count;
            })
            .catch(error => {
                console.error('Error fetching service request count:', error);
                showToast(this, 'Error', 'Error fetching service requests', 'error', error);
            });
    }


    handleGetReportGeneratedOrNot() {
        getReportGeneratedOrNot({ caseId: this.caseId })
            .then((result) => {
                console.log('getReportGeneratedOrNot', result, JSON.stringify(result));
                this.countOfCaseReports = result;
                this.isReportGenerated = result > 0 ? 'Yes' : 'No';
            })
            .catch((error) => {
                console.log('Error fetching case details:', error);
                showToast(this, 'Error', 'Error fetching status of report', 'error', error);
            });
    }


    handleOpenReport(event) {
        if (true) {
            return;
        }
        const { name } = event.currentTarget.dataset;
        const reportId = this.reportIds[name];
        const alertMessage = 'Report is missing, Please get in touch with your administrator.';
        if (reportId) {
            let reportFilters;
            if (name === 'checklists') {
                reportFilters = JSON.stringify([{
                    value: this.caseDetails.CaseNumber,
                    operator: 'equals',
                    column: 'Work_Order__c.Case__c'
                }]);
            }
            else if (name === 'activities') {
                const activityNames = this.caseDetails?.Service_Appointment__r.map(item => item.Name) || [];
                reportFilters = JSON.stringify([{
                    value: [this.caseDetails.CaseNumber, ...activityNames].join(', '),
                    operator: 'equals',
                    column: 'WHAT_NAME'
                }]);
            }
            else if (name === 'spareRequests') {
                reportFilters = JSON.stringify([{
                    value: this.caseDetails.CaseNumber,
                    operator: 'equals',
                    column: 'Work_Order__c.Case__c'
                }])
            }

            if (reportFilters) {
                navigateToRecord(this, reportId, 'Report', { reportFilters });
            }
        }
        else {
            showLightningAlert(this, 'Stay tuned', alertMessage, 'header', 'default');
        }
    }


    handleActivityChecklistClick(event) {
        console.log('handleActivityChecklistClick');
        navigateToLWC(this, 'fieldServiceActivityChecklist', { c__id: this.workOrderId, c__serviceAppointmentId: this.serviceAppointmentId });
    }

    handleCloseCase() {
        if (!this.validateActivityChecklist()) return;

        const validateField = (field, selector, message) => {
            if (!field || field.trim() === '') {
                const element = this.template.querySelector(selector);
                if (element) {
                    element.focus();
                    element.reportValidity();
                } else {
                    showToast(this, 'Error', message, 'error');
                }
                return false;
            }
            return true;
        };

        const validations = [
            { field: this.reason, selector: '.close-case-reason', message: 'Please enter a reason before closing the case' },
            { field: this.comment, selector: '.close-case-comment', message: 'Please enter a comment before closing the case' }
        ];

        if (!validations.every(({ field, selector, message }) => validateField(field, selector, message))) return;

        this.showSpinner = true;
        closeCase({ caseId: this.caseId, caseCloseReason: this.reason, caseClosureComment: this.comment, serviceAppointmentId: this.serviceAppointmentId })
            .then((result) => {
                this.showSpinner = false;
                navigateBackInHistory(this);
            })
            .catch((error) => {
                this.showSpinner = false;
                console.log('Error closing case:', error);
                showToast(this, 'Error', 'Error closing case', 'error', error);
            });
    }


}