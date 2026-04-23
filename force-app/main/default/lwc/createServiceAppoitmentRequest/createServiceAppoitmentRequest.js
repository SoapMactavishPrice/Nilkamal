import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, scrollToTop, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh } from 'c/utilJS';

import SERVICE_APPOINTMENT_OBJECT from '@salesforce/schema/Service_Appointment__c';
import SERVICE_APPOINTMENT_WO_TYPE from '@salesforce/schema/Service_Appointment__c.WO_Type__c';
import getCaseRecord from '@salesforce/apex/createServiceAppointmentCls.getCaseRecord';
import createVisit from '@salesforce/apex/FieldServiceCreateVisitController.createVisit';


export default class CreateServiceAppoitmentRequest extends LightningElement {
    @track recordId;
    @api objectApiName;
    @track todaysDate = new Date();
    @track today = `${this.todaysDate.getFullYear()}-${String(this.todaysDate.getMonth() + 1).padStart(2, '0')}-${String(this.todaysDate.getDate()).padStart(2, '0')}`;

    @track showSpinner = false;
    @track openCasesList = [];
    @track woTypeOptions = [];
    @track showWarning = false;
    @track warningMessage = '';
    @track visitRecord=null;

    @wire(getObjectInfo, { objectApiName: SERVICE_APPOINTMENT_OBJECT })
    serviceAppointmentObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$serviceAppointmentObjectInfo.data.defaultRecordTypeId', fieldApiName: SERVICE_APPOINTMENT_WO_TYPE })
    wiredWOTypeOptions({ data, error }) {
        if (data) {
            this.woTypeOptions = data.values;
        } else if (error) {
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.inContextOfRef) {
            let encodedContext = pageRef.state.inContextOfRef;

            try {
                // Salesforce sometimes prepends "1." to the base64 string
                if (encodedContext.startsWith('1.')) {
                    encodedContext = encodedContext.substring(2);
                }

                const decodedContext = atob(encodedContext); // base64 decode
                const contextObj = JSON.parse(decodedContext);

                const recordId = contextObj.attributes.recordId;
                console.log('Parent Record Id (Case Id):', recordId);
                this.recordId = recordId;

            } catch (e) {
                // eslint-disable-next-line no-console
                console.error('Error decoding inContextOfRef:', e);
            }
        } else {
            // eslint-disable-next-line no-console
            console.warn('inContextOfRef not found in pageReference.state');
        }
    }
    connectedCallback(){
        this.showSpinner = true;
        this.handleGetCaseRecord();
        // setTimeout(() => {
        //     console.log('this record ',this.recordId);
        // }, 2000);
    }

    handleGetCaseRecord() {
            getCaseRecord({ caseId: this.recordId })
                .then(result => {
                    console.log('getOpenCasesList', result);
                    this.openCasesList = result.map(itemData => {
                        const item = itemData.caseRecord;
                        const hasWarning = itemData.breakdownVisits >= itemData.breakdownVisitsAllowed;
                        return {
                            id: item.Id,
                            customerId: item.AccountId,
                            contactId: item.ContactId,
                            customerName: item.Account?.Name,
                            isCustomerBlocked: item.Account?.Customer_Blocked__c,
                            approvalStatus: item.Approval_Status__c,
                            caseNumber: item.CaseNumber,
                            division: item.Division__c,
                            serialNumber: item.Asset?.SerialNumber,
                            subject: item.Subject,
                            status: item.Status,
                            priority: item.Priority,
                            type: item.Type,
                            origin: item.Origin,
                            description: item.Description,
                            totalServiceAppointments: item?.Service_Appointment__r?.length ?? 0,
                            workOrder: item?.Work_Orders__r?.[0].Id,
                            assignedDateTime: item?.Assigned_Date_Time__c || item?.CreatedDate,
                            breakdownVisits: itemData.breakdownVisits,
                            breakdownVisitsAllowed: itemData.breakdownVisitsAllowed,
                            hasWarning: hasWarning,
                            warning: hasWarning
                                ? `Breakdown visits exceeded. Allowed: ${itemData.breakdownVisitsAllowed}, Used: ${itemData.breakdownVisits}`
                                : '',
    
                            get noOfDaysOpen() {
                                const assignedDateTime = new Date(item.CreatedDate);
                                const today = new Date();
                                const diffTime = Math.abs(today - assignedDateTime);
                                const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                                return diffDays;
                            }
                        };
                    });
                   
                    console.log('openCasesList-->', JSON.stringify(this.openCasesList));
                    this.selectedCase = this.openCasesList.find(item => item.id === this.recordId);
                    console.log('selectedCase', this.selectedCase);

                    this.visitRecord = {
                        Case__c: this.selectedCase.id,
                        Account__c: this.selectedCase.customerId,
                        Contact__c: this.selectedCase.contactId,
                        Work_Order__c: this.selectedCase.workOrder,
                        Status__c: 'Scheduled',
                        WO_Type__c: this.selectedCase.type,
                        Assigned_Date__c: this.selectedCase.assignedDateTime,
                        Scheduled_Start__c: new Date().getFullYear() + '-' + (new Date().getMonth() + 1).toString().padStart(2, '0') + '-' + new Date().getDate().toString().padStart(2, '0'),
                        Remote_Support__c: false,
                        Warning: this.selectedCase.warning,
                        hasWarning: this.selectedCase.hasWarning
                    };
    
                })
                .catch(error => {
                    console.log('getOpenCasesList', error);
                    showToast(this, 'Warning', 'Case is closed', 'warning', 'Case is closed!');
                    setTimeout(() => {   
                        window.location.href='/lightning/r/Case/'+this.recordId+'/view'
                    }, 1000);
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }

    handleCreateVisit(event) {
            console.log('handleCreateVisit', JSON.stringify(event.detail));
    
            const isValid = this.template.querySelector('lightning-input[data-name="Scheduled_Start__c"]').checkValidity();
            console.log('isValid', isValid);
            if (!isValid) {
                this.template.querySelector('lightning-input[data-name="Scheduled_Start__c"]').reportValidity();
                // focus
                this.template.querySelector('lightning-input[data-name="Scheduled_Start__c"]').focus();
                return;
            }
            console.log('handleCreateVisit', JSON.stringify(this.visitRecord));
    
            this.showSpinner = true;
            createVisit({ serviceAppointment: this.visitRecord })
                .then(result => {
                    console.log('createVisit', result);
                    showToast(this, 'Success', 'Visit created successfully', 'success');
                     // Fire event to Aura component
                    // const closeEvent = new CustomEvent('closepopup');
                    // this.dispatchEvent(closeEvent);    
                    setTimeout(() => {   
                        window.location.href='/lightning/cmp/c__fieldServiceCreateVisit'
                    }, 1000);
                })
                .catch(error => {
                    this.showWarning = false;
                    console.log('createVisit', error);
                    showToast(this, 'Error', 'Something went wrong', 'error', error);
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }

    handleChange(event) {
        const { name, value } = getNameAndValueOnChange(this, event);
        this.visitRecord[name] = value;
    }

    handleCheckboxChange(event) {
        this.visitRecord[event.target.dataset.name] = event.target.checked;
    }

    handleCloseCreateVisitModal(){
         window.location.href='/lightning/r/Case/'+this.recordId+'/view'
    }
}