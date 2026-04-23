import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, scrollToTop, loadQuickActionPopupStyle, unloadQuickActionPopupStyle } from 'c/utilJS';

import getServiceAppointmentList from '@salesforce/apex/FieldServiceServiceAppointmentListCont.getServiceAppointmentList';
import { disablePullToRefresh } from 'c/utilJS';




export default class FieldServiceServiceAppointmentList extends NavigationMixin(LightningElement) {

    @track showSpinner = false;

    @track target;

    @track isMobile;
    @track isTablet;
    @track isDesktop;

    @track todaysDate = new Date();
    @track current_view_month = this.todaysDate.getMonth();
    @track current_view_year = this.todaysDate.getFullYear();
    @track current_view_day = this.todaysDate.getDate();

    @track activeDay;
    @track isCalenderPopulated = false;

    @track serviceAppointmentsList = {};
    @track visibleServiceAppointmentsList = [];


    get selectedDate() {
        const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        return `${this.current_view_day} ${MONTHS[this.current_view_month]} ${this.current_view_year}`;
    }


    @wire(CurrentPageReference)
    currentPageReference({ state }) {
        if (state.c__target) {
            this.target = state.c__target;
        }
    }


    connectedCallback() {
        console.log('connectedCallback from FieldServiceServiceAppointmentList');
        analyzeFormFactor(this);
        disablePullToRefresh(this);
    }

    renderedCallback() {
        console.log('renderedCallback from FieldServiceServiceAppointmentList');
        analyzeFormFactor(this);

        if (!this.isCalenderPopulated) {
            if (this.isMobile) {
                this.handleGetServiceAppointments({ year: this.current_view_year, month: this.current_view_month });
            } else {
                initCalendar(this);
                this.handleGetServiceAppointments({ year: this.current_view_year, month: this.current_view_month });
            }
            this.isCalenderPopulated = true;
        }
    }


    disconnectedCallback() {

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
        return `calendar-overlay material-card-with-shadow ${this.showCalendarOverlay ? 'show' : ''}`;
    }

    handleCalendarDayClick(event) {
        console.log("handleCalendarDayClick", JSON.stringify(event.currentTarget.dataset));
        this.visibleServiceAppointmentsList = this.serviceAppointmentsList?.[this.current_view_day] || [];
        this.handleCloseCalendar();
    }

    handlePreviousMonthClick() {
        this.current_view_month = (this.current_view_month - 1 + 12) % 12;
        if (this.current_view_month === 11) this.current_view_year--;
        this.updateCalendarAndAppointments();
    }

    handleNextMonthClick() {
        this.current_view_month = (this.current_view_month + 1) % 12;
        if (this.current_view_month === 0) this.current_view_year++;
        this.updateCalendarAndAppointments();
    }

    handlePreviousDayClick() {
        if (this.current_view_day > 1) {
            this.current_view_day--;
        } else {
            this.handleMonthTransition(-1);
        }
        this.selectDayElement();
    }

    handleNextDayClick() {
        const monthEnd = new Date(this.current_view_year, this.current_view_month + 1, 0).getDate();
        if (this.current_view_day < monthEnd) {
            this.current_view_day++;
        } else {
            this.handleMonthTransition(1);
        }
        this.selectDayElement();
    }

    handleMonthTransition(direction) {
        this.current_view_month = (this.current_view_month + direction + 12) % 12;
        if (direction === -1 && this.current_view_month === 11) this.current_view_year--;
        if (direction === 1 && this.current_view_month === 0) this.current_view_year++;
        const monthEnd = new Date(this.current_view_year, this.current_view_month + 1, 0).getDate();
        this.current_view_day = direction === -1 ? monthEnd : 1;
        this.updateCalendarAndAppointments();
    }

    updateCalendarAndAppointments() {
        this.visibleServiceAppointmentsList = [];
        initCalendar(this);
        this.handleGetServiceAppointments({ year: this.current_view_year, month: this.current_view_month });
    }

    selectDayElement() {
        const selectedElement = this.template.querySelector(`.calendar-day-container[data-calendar-container="${this.current_view_day}"]`);
        if (selectedElement) {
            selectedElement.click();
        } else {
            this.visibleServiceAppointmentsList = this.serviceAppointmentsList?.[this.current_view_day] || [];
        }
    }
    /************************************************************ Calendar Functions end ************************************************************/


    handleGetServiceAppointments(params) {
        this.showSpinner = true;
        getServiceAppointmentList({ params: params })
            .then(result => {
                this.serviceAppointmentsList = {};

                if (Array.isArray(result) && result.length > 0) {
                    result.forEach(row => {
                        const contact = row.Contact__r || row.Case__r?.Contact || {};
                        const obj = {
                            id: row.Id,
                            Id: row.Id,
                            name: row.Name,
                            woId: row.Work_Order__c,
                            woType: row.WO_Type__c,
                            planDate: row.Scheduled_Start__c,
                            custName: row.Case__r?.Account?.Name || '',
                            contactName: contact.Name,
                            serialNumber: row.Case__r?.Asset?.SerialNumber,
                            caseId: row.Case__c,
                            caseNumber: row.Case__r?.CaseNumber || '',
                            status: row.Status__c,
                            priority: row.Priority__c
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
                    } else if (firstDayElement) {
                        firstDayElement.click();
                    } else {
                        this.visibleServiceAppointmentsList = this.serviceAppointmentsList?.[this.current_view_day] || [];
                    }
                }

                Object.keys(this.serviceAppointmentsList).forEach(key => {
                    this.serviceAppointmentsList[key].forEach((item, index) => {
                        item.srNo = index + 1;
                    });
                });

                console.log('serviceAppointmentsList', this.serviceAppointmentsList);
                console.log('visibleServiceAppointmentsList', this.visibleServiceAppointmentsList);
            })
            .catch(error => {
                console.error('getServiceAppointments', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }



    handleServiceAppointmentClick(event) {
        const serviceAppointment = this.visibleServiceAppointmentsList.find(item => item.id === event.currentTarget.dataset.id);
        let targetLWC;
        switch (this.target) {
            case 'SpareRequest':
                targetLWC = 'fieldServiceSpareRequest';
                break;
            case 'SpareReturn':
                targetLWC = 'FieldServiceSpareReturn';
                break;
            case 'CaptureInteraction':
                targetLWC = 'fieldServiceCaptureInteraction';
                break;
        }
        navigateToLWC(this, targetLWC, { c__id: serviceAppointment.woId, c__serviceAppointmentId: serviceAppointment.Id });
    }


}