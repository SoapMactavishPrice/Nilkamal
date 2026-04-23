import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';

import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, scrollToTop, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh } from 'c/utilJS';

import SERVICE_APPOINTMENT_OBJECT from '@salesforce/schema/Service_Appointment__c';
import SERVICE_APPOINTMENT_WO_TYPE from '@salesforce/schema/Service_Appointment__c.WO_Type__c';

import SERVICE_APPOINTMENT_ACTIVITY from '@salesforce/schema/Service_Appointment__c.Activity__c';
import SERVICE_APPOINTMENT_STATUS from '@salesforce/schema/Service_Appointment__c.Status__c';
import SERVICE_APPOINTMENT_TERRITORY from '@salesforce/schema/Service_Appointment__c.Territory__c';

import getOpenCasesList from '@salesforce/apex/FieldServiceCreateVisitController.getOpenCasesList';
import getServiceAppointments from '@salesforce/apex/FieldServiceCreateVisitController.getServiceAppointments';
import createVisit from '@salesforce/apex/FieldServiceCreateVisitController.createVisit';
// import getCasesExceedingVisitLimits from '@salesforce/apex/FieldServiceCreateVisitController.getCasesExceedingVisitLimits';


export default class FieldServiceCreateVisit extends NavigationMixin(LightningElement) {

    @api recordId;
    @api objectApiName;

    @track showSpinner = false;

    @track isMobile;
    @track isTablet;
    @track isDesktop;


    @track todaysDate = new Date();
    @track current_view_month = this.todaysDate.getMonth();
    @track current_view_year = this.todaysDate.getFullYear();
    @track current_view_day = this.todaysDate.getDate();

    @track today = `${this.todaysDate.getFullYear()}-${String(this.todaysDate.getMonth() + 1).padStart(2, '0')}-${String(this.todaysDate.getDate()).padStart(2, '0')}`;

    @track activeDay;
    @track isCalenderPopulated = false;



    @track openCasesList = [];
    @track serviceAppointmentsList = {};
    @track visibleServiceAppointmentsList = [];




    @track woTypeOptions = [];
    @track activityOptions = [];
    @track statusOptions = [{ label: 'Scheduled', value: 'Scheduled' }];
    @track territoryOptions = [];

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
    @wire(getPicklistValues, { recordTypeId: '$serviceAppointmentObjectInfo.data.defaultRecordTypeId', fieldApiName: SERVICE_APPOINTMENT_ACTIVITY })
    wiredActivityOptions({ data, error }) {
        if (data) {
            this.activityOptions = data.values;
        } else if (error) {
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }
    // @wire(getPicklistValues, { recordTypeId: '$serviceAppointmentObjectInfo.data.defaultRecordTypeId', fieldApiName: SERVICE_APPOINTMENT_STATUS })
    // wiredStatusOptions({ data, error }) {
    //     if (data) {
    //         this.statusOptions = data.values;
    //     } else if (error) {
    //         showToast(this, 'Error', 'Something went wrong', 'error', error);
    //     }
    // }
    @wire(getPicklistValues, { recordTypeId: '$serviceAppointmentObjectInfo.data.defaultRecordTypeId', fieldApiName: SERVICE_APPOINTMENT_TERRITORY })
    wiredTerritoryOptions({ data, error }) {
        if (data) {
            this.territoryOptions = data.values;
        } else if (error) {
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }


    @wire(CurrentPageReference)
    currentPageReference({ state }) {
        // this.current_view_month = this.todaysDate.getMonth();
        // this.current_view_year = this.todaysDate.getFullYear();
        // this.current_view_day = this.todaysDate.getDate();

        this.visibleServiceAppointmentsList = null;
        initCalendar(this);
        this.handleGetOpenCasesList();
        this.handleGetServiceAppointments();

        this.handleCloseCreateVisitModal();

        if (this.showServiceAppointmentInfoModal) {
            if (this.isTablet || this.isDesktop) {
                loadQuickActionPopupStyle(this, 65);
            }
        }
        // this.handleCloseServiceAppointmentInfoModal();
    }



    connectedCallback() {
        console.log('connectedCallback from FieldServiceCreateVisit');
        analyzeFormFactor(this);
        // this.handleGetOpenCasesList();
        // this.handleGetServiceAppointments();
        disablePullToRefresh(this);
    }

    renderedCallback() {
        console.log('renderedCallback from FieldServiceCreateVisit');
        analyzeFormFactor(this);

        if (!this.isCalenderPopulated) {
            initCalendar(this);
            this.handleGetOpenCasesList();
            this.handleGetServiceAppointments();
            this.isCalenderPopulated = true;
        }
    }





    /************************************************************ Calendar Functions start ************************************************************/
    @track showCalendarOverlay = false;

    handleDateClick() {
        this.showCalendarOverlay = true;
        setTimeout(() => initCalendar(this), 0);
    }

    handleCloseCalendar() {
        this.showCalendarOverlay = false;
    }

    get calendarOverlayClass() {
        return `calendar-overlay material-card-with-shadow ${this.showCalendarOverlay ? 'show' : ''}`.trim();
    }

    handleCalendarDayClick(event) {
        console.log("handleCalendarDayClick", JSON.stringify(event.currentTarget.dataset));
        this.visibleServiceAppointmentsList = this.serviceAppointmentsList?.[this.current_view_day] || [];
        // this.handleCloseCalendar();
    }

    handlePreviousMonthClick() {
        this.current_view_day = undefined;
        this.current_view_month = (this.current_view_month - 1 + 12) % 12;
        if (this.current_view_month === 11) this.current_view_year--;
        this.updateCalendar();
    }

    handleNextMonthClick() {
        this.current_view_day = undefined;
        this.current_view_month = (this.current_view_month + 1) % 12;
        if (this.current_view_month === 0) this.current_view_year++;
        this.updateCalendar();
    }

    handlePreviousDayClick() {
        if (this.current_view_day > 1) {
            this.current_view_day--;
        } else {
            this.adjustToPreviousMonth();
        }
        this.selectDay();
    }

    handleNextDayClick() {
        const monthEnd = new Date(this.current_view_year, this.current_view_month + 1, 0);
        if (this.current_view_day < monthEnd.getDate()) {
            this.current_view_day++;
        } else {
            this.adjustToNextMonth();
        }
        this.selectDay();
    }

    updateCalendar() {
        this.visibleServiceAppointmentsList = null;
        initCalendar(this);
        this.handleGetOpenCasesList();
        this.handleGetServiceAppointments();
        this.selectFirstDay();
    }

    adjustToPreviousMonth() {
        this.current_view_month = (this.current_view_month - 1 + 12) % 12;
        if (this.current_view_month === 11) this.current_view_year--;
        const monthEnd = new Date(this.current_view_year, this.current_view_month + 1, 0);
        this.current_view_day = monthEnd.getDate();
        this.updateCalendar();
    }

    adjustToNextMonth() {
        this.current_view_month = (this.current_view_month + 1) % 12;
        if (this.current_view_month === 0) this.current_view_year++;
        this.current_view_day = 1;
        this.updateCalendar();
    }

    selectDay() {
        const selectedElement = this.template.querySelector(`.calendar-day-container[data-calendar-container="${this.current_view_day}"]`);
        if (selectedElement) {
            selectedElement.click();
        } else {
            this.visibleServiceAppointmentsList = this.serviceAppointmentsList?.[this.current_view_day] || [];
        }
    }

    selectFirstDay() {
        const firstDayElement = this.template.querySelector('.calendar-day-container[data-calendar-container="1"]');
        if (firstDayElement) firstDayElement.click();
    }
    /************************************************************ Calendar Functions end ************************************************************/





    handleGetOpenCasesList() {
        this.showSpinner = true;
        getOpenCasesList({ year: this.current_view_year, month: this.current_view_month })
            .then(result => {
                // console.log('getOpenCasesList', result);
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
                this.openCasesList = this.sortData(this.openCasesList, 'noOfDaysOpen', 'desc');
                // console.log('openCasesList-->', this.openCasesList);

            })
            .catch(error => {
                console.log('getOpenCasesList', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }


    handleGetServiceAppointments() {
        this.showSpinner = true;
        getServiceAppointments({ year: this.current_view_year, month: this.current_view_month })
            .then(result => {
                this.serviceAppointmentsList = {};

                if (Array.isArray(result) && result.length > 0) {
                    result.forEach(row => {
                        const contact = row.Contact__r || row.Case__r?.Contact || {};

                        const obj = {
                            id: row.Id,
                            Id: row.Id,
                            name: row.Name,
                            caseNumber: row.Case__r?.CaseNumber || '',
                            woType: row.Case__r?.Type || '',
                            remoteSupport: row.Remote_Support__c,
                            isAdditionalResource: row.Is_Additional_Resource__c,
                            planDate: row.Scheduled_Start__c,
                            custName: row.Case__r?.Account?.Name || '',
                            caseId: row.Case__c,
                            status: row.Status__c,
                            priority: row.Priority__c,
                            serialNumber: row.Case__r?.Asset?.SerialNumber || '',
                            contact: {
                                id: row.Case__r?.ContactId,
                                name: contact.Name,
                                email: contact.Email,
                                mobilePhone: contact.MobilePhone
                            },
                            checkInsAndOuts: row.Service_Appointment_Check_Ins_and_Outs__r,

                            get isCheckedIn() {
                                const [checkIn] = this.checkInsAndOuts || [];
                                if (checkIn) {
                                    const { Check_In_Date_Time__c, IsCheckedOut__c } = checkIn;
                                    return Boolean(Check_In_Date_Time__c && !IsCheckedOut__c);
                                }
                                return false;
                            }
                        };

                        const day = parseInt(obj.planDate.split('-')[2], 10);
                        this.serviceAppointmentsList[day] = this.serviceAppointmentsList[day] || [];
                        this.serviceAppointmentsList[day].push(obj);
                    });

                    const todayElement = this.template.querySelector('.calendar-day-today');
                    const selectedElement = this.template.querySelector('.calendar-day-selected');
                    const firstDayElement = this.template.querySelector('.calendar-day-container[data-calendar-container="1"]');

                    if (todayElement || selectedElement) {
                        this.visibleServiceAppointmentsList = this.serviceAppointmentsList?.[this.current_view_day] || [];
                    }
                    else if (firstDayElement) {
                        firstDayElement.click();
                    } else {
                        this.visibleServiceAppointmentsList = this.serviceAppointmentsList?.[this.current_view_day] || [];
                    }
                }

                const calendarDayEventCountElements = this.template.querySelectorAll('.calendar-day-event-count');
                if (calendarDayEventCountElements && calendarDayEventCountElements.length > 0) {
                    calendarDayEventCountElements.forEach(element => {
                        const day = element.dataset.calendarDate;
                        if (this.serviceAppointmentsList[day]) {
                            element.textContent = this.serviceAppointmentsList[day].length;
                        }
                        else {
                            element.textContent = '';
                        }
                    });
                }

                Object.keys(this.serviceAppointmentsList).forEach(key => {
                    this.serviceAppointmentsList[key].forEach((item, index) => {
                        item.srNo = index + 1;
                    });
                });

                // console.log('serviceAppointmentsList', this.serviceAppointmentsList);
                // console.log('visibleServiceAppointmentsList', JSON.stringify(this.visibleServiceAppointmentsList));
            })
            .catch(error => {
                console.log('getServiceAppointments', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }





    @track showCreateVisitModal;
    @track selectedCase;
    @track visitRecord;

    handleCaseCreateVisitClick(event) {
        console.log('handleCaseCreateVisitClick', JSON.stringify(event.currentTarget.dataset));
        this.selectedCase = this.openCasesList.find(item => item.id === event.currentTarget.dataset.id);
        console.log('selectedCase', this.selectedCase);


        if (this.selectedCase.division === 'MHE' || this.selectedCase.division === 'CNPL' || this.selectedCase.division === 'Hanel') {
            if (this.selectedCase.isCustomerBlocked) {
                showToast(this, 'Error', 'Customer is blocked, please contact your manager.', 'error');
                this.handleCloseCreateVisitModal();
                return;
            }
        }
        else if (this.selectedCase.division === 'Printer') {
            if (this.selectedCase.isCustomerBlocked) {
                if (this.selectedCase.approvalStatus === 'Submitted') {
                    showToast(this, 'Error', 'Customer is blocked. Case is already submitted to Vertical Head for approval.', 'error');
                    this.handleCloseCreateVisitModal();
                    return;
                }
                else if (this.selectedCase.approvalStatus === 'Rejected') {
                    showToast(this, 'Error', 'Customer is blocked. Case is already rejected by Vertical Head.', 'error');
                    this.handleCloseCreateVisitModal();
                    return;
                }
            }
        }

        if (this.isTablet || this.isDesktop) {
            // loadQuickActionPopupStyle(this, 65);
        }
        this.showCreateVisitModal = true;
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
        scrollToTop(this);
    }

    handleCloseCreateVisitModal(event) {
        unloadQuickActionPopupStyle(this);
        this.showCreateVisitModal = false;
        this.selectedCase = null;
        this.visitRecord = null;
    }

    get workOrderFilter() {
        if (this.selectedCase) {
            return { criteria: [{ fieldPath: 'Case__c', operator: 'eq', value: this.selectedCase.id }] };
        }
    }

    handleChange(event) {
        const { name, value } = getNameAndValueOnChange(this, event);
        this.visitRecord[name] = value;
    }

    handleCheckboxChange(event) {
        this.visitRecord[event.target.dataset.name] = event.target.checked;
    }
    @track showWarning = false;
    @track warningMessage = '';


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
                // if (result.limitExceeded) {
                //     showToast(
                //         this,
                //         'Warning',
                //         result.warning + ' Visit was still created.',
                //         'warning'
                //     );
                // }
                // if (result.hasWarning) {
                //     this.showWarning = true;
                //     this.warningMessage = result.warning;
                // } else {
                //     this.showWarning = false;
                // }

                this.handleCloseCreateVisitModal();
                this.handleGetOpenCasesList();
                this.handleGetServiceAppointments();
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










    @track showServiceAppointmentInfoModal;
    @track selectedServiceAppointment;

    handleServiceAppointmentPreviewClick(event) {
        console.log('handleServiceAppointmentPreviewClick', JSON.stringify(event.currentTarget.dataset));
        this.selectedServiceAppointment = this.visibleServiceAppointmentsList.find(item => item.id === event.currentTarget.dataset.id);
        if (this.isTablet || this.isDesktop) {
            loadQuickActionPopupStyle(this, 65);
        }
        this.showServiceAppointmentInfoModal = true;
        scrollToTop(this);
    }

    handleCloseServiceAppointmentInfoModal(event) {
        this.showServiceAppointmentInfoModal = false;
        this.handleGetOpenCasesList();
        this.handleGetServiceAppointments();
        this.selectedServiceAppointment = null;
        unloadQuickActionPopupStyle(this);
    }



    handleOpenRecord(event) {
        const { id } = event.currentTarget.dataset;
        navigateToRecord(this, id);
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





    @track openCasesColumns = {
        caseNumber: {
            isAsc: false,
            isDesc: false
        },
        priority: {
            isAsc: false,
            isDesc: false
        },
        type: {
            isAsc: false,
            isDesc: false
        },
        assignedDateTime: {
            isAsc: false,
            isDesc: false
        },
        noOfDaysOpen: {
            isAsc: false,
            isDesc: true
        },
        totalServiceAppointments: {
            isAsc: false,
            isDesc: false
        },

    };
    /*
    [
        {
            label: 'Case Number', fieldName: 'caseNumber', type: 'button', wrapText: false, sortable: true, hideDefaultActions: true,
            typeAttributes: { label: { fieldName: 'caseNumber' }, title: { fieldName: 'caseNumber' }, variant: 'base' }, initialWidth: 100
        },
        { label: 'Customer', fieldName: 'customerName', type: 'text', wrapText: true, hideDefaultActions: true },
        { label: 'Serial No', fieldName: 'serialNumber', type: 'text', wrapText: true, hideDefaultActions: true },
        { label: 'Type', fieldName: 'type', type: 'text', sortable: true, hideDefaultActions: true },
        { label: 'Date', fieldName: 'assignedDateTime', type: 'date', wrapText: true, hideDefaultActions: true },
        { label: 'No of days open', fieldName: 'noOfDaysOpen', type: 'text', sortable: true, wrapText: true, hideDefaultActions: true },
        { type: 'button-icon', typeAttributes: { iconName: 'utility:add' } }
    ];
    */


    handleOpenCasesRowAction(event) {
        const id = event.detail.row.id;
        const index = this.openCasesList.findIndex(item => item.id === id);
        this.handleCaseCreateVisitClick({ target: { dataset: { id, index } }, currentTarget: { dataset: { id, index } } });
    }

    handleOpenCasesSort(event) {
        const { field } = event.currentTarget.dataset;
        const col = this.openCasesColumns[field];
        // default both are going to be false
        if (!col.isAsc && !col.isDesc) {
            col.isAsc = true;
        }
        else if (col.isAsc) {
            col.isAsc = false;
            col.isDesc = true;
        }
        else {
            col.isAsc = true;
            col.isDesc = false;
        }

        for (const key in this.openCasesColumns) {
            if (key !== field) {
                this.openCasesColumns[key].isAsc = false;
                this.openCasesColumns[key].isDesc = false;
            }
        }

        this.openCasesList = this.sortData(this.openCasesList, field, col.isAsc ? 'asc' : 'desc');
    }

    handleOpenCasesHandleSort(event) {
        let fieldName = event.detail.fieldName;
        let sortDirection = event.detail.sortDirection;
        this.openCasesSortBy = fieldName;
        this.openCasesSortDirection = sortDirection;
        this.openCasesList = this.sortData(this.openCasesList, fieldName, sortDirection);
    }










    sortData(data, fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(data));
        let keyValue = (a) => {
            return a[fieldname];
        };

        let isReverse = direction === 'asc' ? 1 : -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });

        const customerNames = data.map(item => item.customerName);
        // console.log('customerNames', customerNames);

        return parseData;
    }


    get selectedDate() {
        const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        return `${this.current_view_day} ${MONTHS[this.current_view_month]} ${this.current_view_year}`;
    }

    // @wire(getCasesExceedingVisitLimits)
    // wiredCases({ data, error }) {
    //     console.log('getCasesExceedingVisitLimits', data);

    //     if (data && data.length > 0) {
    //         console.log('getCasesExceedingVisitLimits data-->', data);

    //         // this.showWarningToast(data);
    //     } else if (error) {
    //         console.error('Error checking visit limits:', error);
    //     }
    // }

}