import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';

import { showToast, analyzeFormFactor, analyzeUserAgent, navigateToRecord, navigateToLWC, navigateToObjectPage, initCalendar, disablePullToRefresh } from 'c/utilJS';

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];


import getScheduleList from '@salesforce/apex/FieldServiceInProgressScheduleController.getScheduleList';




export default class FieldServiceInProgressSchedule extends NavigationMixin(LightningElement) {

    @track showSpinner = true;

    @track isMobile;
    @track isTablet;
    @track isDesktop;



    @track todaysDate = new Date();
    @track current_view_month = this.todaysDate.getMonth();
    @track current_view_year = this.todaysDate.getFullYear();
    @track current_view_day = this.todaysDate.getDate();

    @track activeDay;
    @track isCalenderPopulated = false;


    @track scheduleList;
    @track scheduleVisibleList;

    @track selectedSchedule;


    @track showScheduleModal = false;



    connectedCallback() {
        console.log('connectedCallback from FieldServiceInProgressSchedule');
        analyzeUserAgent(this);
        this.showSpinner = false;
        disablePullToRefresh(this);
    }

    renderedCallback() {
        analyzeFormFactor(this);

        if (!this.isCalenderPopulated) {
            initCalendar(this);
            this.handleGetScheduleList(this.current_view_year, this.current_view_month);
            this.isCalenderPopulated = true;
        }
    }



    /************************************************************ Calendar Hooks STARTS ************************************************************/
    /*
    initCalendar() {
        const daysContainer = this.template.querySelector(".calendar-days-container");
        if (!daysContainer) return;

        daysContainer.innerHTML = '';

        const calendarMonthLabelElement = this.template.querySelector(".calendar-month-label");
        if (calendarMonthLabelElement) {
            calendarMonthLabelElement.textContent = `${MONTHS[this.current_view_month].substring(0, 3)} ${this.current_view_year}`;
        }

        const firstDay = new Date(this.current_view_year, this.current_view_month, 1);
        const lastDay = new Date(this.current_view_year, this.current_view_month + 1, 0);
        const prevLastDay = new Date(this.current_view_year, this.current_view_month, 0);
        const prevDays = prevLastDay.getDate();
        const lastDate = lastDay.getDate();

        const adjustedDay = firstDay.getDay() || 7; // Correct Sunday to 7
        const prevDaysToAdd = adjustedDay - 1;
        const nextDays = 7 - lastDay.getDay();
        const firstWeekDay = (firstDay.getDay() === 0 ? 7 : firstDay.getDay()) - 1;

        const isToday = (day) => {
            const today = new Date();
            return (
                day === today.getDate() &&
                this.current_view_year === today.getFullYear() &&
                this.current_view_month === today.getMonth()
            );
        };

        const addEventListeners = (dayElement) => {
            dayElement.addEventListener("click", this.handleCalendarDayClick.bind(this));
        };

        const createDayElement = (day, additionalClass, isCurrentMonth = false) => {
            const dayElement = document.createElement("div");
            dayElement.className = `calendar-day-container ${additionalClass}`;

            const spanElement = document.createElement("span");
            spanElement.className = "calendar-day-date";
            if (isCurrentMonth) {
                spanElement.setAttribute("data-calendar-date", day);
            }
            spanElement.textContent = day;
            dayElement.appendChild(spanElement);

            if (isCurrentMonth) {
                dayElement.classList.add("calendar-active-date");
                dayElement.setAttribute("data-calendar-container", day);

                const eventCountElement = document.createElement("span");
                eventCountElement.className = "calendar-day-event-count";
                dayElement.appendChild(eventCountElement);

                if (isToday(day)) {
                    spanElement.classList.add("calendar-day-today");
                }
                addEventListeners(dayElement);
            }
            return dayElement;
        };

        const renderDays = (start, end, additionalClass, isCurrentMonth = false) => {
            for (let day = start; day <= end; day++) {
                const dayElement = createDayElement(day, additionalClass, isCurrentMonth);
                daysContainer.appendChild(dayElement);
            }
        };

        renderDays(prevDays - firstWeekDay + 1, prevDays, 'calendar-prev-month-date calendar-disabled-date');
        renderDays(1, lastDate, 'calendar-active-date', true);
        renderDays(1, nextDays, 'calendar-next-month-date calendar-disabled-date');
    }
    */

    handlePreviousMonthClick(event) {
        this.current_view_day = undefined;
        this.current_view_month--;
        if (this.current_view_month < 0) {
            this.current_view_month = 11;
            this.current_view_year--;
        }
        this.cpScheduleVisibleList = null;
        initCalendar(this);
        this.handleGetScheduleList(this.current_view_year, this.current_view_month);
    }

    handleNextMonthClick(event) {
        this.current_view_day = undefined;
        this.current_view_month++;
        if (this.current_view_month > 11) {
            this.current_view_month = 0;
            this.current_view_year++;
        }
        this.cpScheduleVisibleList = null;
        initCalendar(this);
        this.handleGetScheduleList(this.current_view_year, this.current_view_month);
    }

    handleCalendarDayClick(event) {
        console.log("handleCalendarDayClick", JSON.stringify(event.currentTarget.dataset));

        this.scheduleVisibleList = this.scheduleList?.[this.current_view_day] || null;
    }
    /************************************************************ Calendar Hooks ENDS ************************************************************/



    handleGetScheduleList(year, month) {
        getScheduleList({ year: year, month: month })
            .then(result => {
                this.scheduleList = {};

                if (Array.isArray(result) && result.length > 0) {
                    result.forEach((row, i) => {
                        const addressInfo = row.Partner_Function_Address_Information__r || {};
                        const addressLines = [
                            addressInfo.Address_line_1__c,
                            addressInfo.Address_line_2__c,
                            addressInfo.Address_line_3__c
                        ].filter(Boolean).join(' ');
                        const contact = row.Case__r?.Contact || {};

                        const obj = {
                            srNo: i,
                            id: row.Id,
                            Id: row.Id,
                            name: row.Name,
                            woType: row.WO_Type__c,
                            planDate: row.Scheduled_Start__c,
                            custName: row.Case__r?.Account?.Name || '',
                            caseId: row.Case__c,
                            caseNumber: row.Case__r?.CaseNumber || '',
                            status: row.Status__c,
                            priority: row.Priority__c,
                            contact: {
                                id: row.Case__r?.ContactId,
                                firstName: contact.FirstName,
                                lastName: contact.LastName,
                                salutation: contact.Salutation,
                                email: contact.Email,
                                mobilePhone: contact.MobilePhone
                            },
                            addressString: [
                                addressLines,
                                addressInfo.City__c,
                                addressInfo.State__c,
                                addressInfo.Country__c,
                                addressInfo.Pin_Code__c
                            ].filter(Boolean).join(' '),
                            address: {
                                street: addressLines,
                                city: addressInfo.City__c || '',
                                state: addressInfo.State__c || '',
                                country: addressInfo.Country__c || '',
                                postalCode: addressInfo.Pin_Code__c || '',
                                latitude: addressInfo.GeoLocation__Latitude__s || '',
                                longitude: addressInfo.GeoLocation__Longitude__s || ''
                            }
                        };

                        const day = parseInt(obj.planDate.split('-')[2], 10);
                        this.scheduleList[day] = this.scheduleList[day] || [];
                        this.scheduleList[day].push(obj);
                    });
                }

                const todayElement = this.template.querySelector('.calendar-day-today');
                const selectedElement = this.template.querySelector('.calendar-day-selected');
                const firstDayElement = this.template.querySelector('.calendar-day-container[data-calendar-container="1"]');

                if (todayElement || selectedElement) {
                    this.scheduleVisibleList = this.scheduleList?.[this.current_view_day] || null;
                }
                else if (firstDayElement) {
                    firstDayElement.click();
                }

                console.log('scheduleList', this.scheduleList);
                console.log('scheduleVisibleList', this.scheduleVisibleList);
            })
            .catch(error => {
                console.log('Error fetching schedule list:', error);
                showToast(this, 'Error', error, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }



    handleCustomerClick(event) {
        console.log("handleCustomerClick", JSON.stringify(event.currentTarget.dataset));
        this.showScheduleModal = true;
        this.selectedSchedule = this.scheduleVisibleList.find(item => item.id === event.currentTarget.dataset.id);
    }


    handleCloseScheduleModal() {
        this.showScheduleModal = false;
        this.selectedSchedule = null;
    }



}