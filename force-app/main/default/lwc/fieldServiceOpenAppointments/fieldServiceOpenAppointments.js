import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, scrollToTop, scrollToHeight, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh } from 'c/utilJS';

import getServiceAppointments from '@salesforce/apex/FieldServiceOpenAppointmentsController.getServiceAppointments';





export default class FieldServiceOpenAppointments extends NavigationMixin(LightningElement) {

    @api recordId;
    @api objectApiName;

    @track showSpinner = true;

    @track isMobile;
    @track isTablet;
    @track isDesktop;


    @track pageSize = 50;
    @track offset = 0;
    @track isLoading = false;
    @track hasMoreRecords = true;


    @track serviceAppointmentsList = null;


    @wire(CurrentPageReference)
    currentPageReference({ state }) {
        this.serviceAppointmentsList = null;

        const sortedColumn = this.columns.find(column => column.sortDir);
        this.handleGetServiceAppointments(
            this.offset,
            this.pageSize,
            sortedColumn?.name,
            sortedColumn?.sortDir
        );

        if (this.showServiceAppointmentInfoModal) {
            if (this.isTablet || this.isDesktop) {
                loadQuickActionPopupStyle(this, 65);
            }
        }
    }


    connectedCallback() {
        console.log('connectedCallback from FieldServiceCreateVisit');
        analyzeFormFactor(this);
        disablePullToRefresh(this);
        window.addEventListener('resize', this.calculateHeight.bind(this));
    }


    renderedCallback() {
        console.log('renderedCallback from FieldServiceCreateVisit');
        analyzeFormFactor(this);
        if (!this.availableHeight) {
            this.calculateHeight();
        }
    }


    disconnectedCallback() {
        unloadQuickActionPopupStyle(this);
        window.removeEventListener('resize', this.calculateHeight.bind(this));
    }


    calculateHeight() {
        const parentElement = this.template.querySelector('.scrollable');

        if (!parentElement) return;

        const rect = parentElement.getBoundingClientRect();
        const availableSpace = Math.max(window.innerHeight - rect.top - 20, 300);

        if (this.availableHeight !== availableSpace) {
            this.availableHeight = availableSpace;
            if (this.isDesktop) {
                parentElement.style.height = `${this.availableHeight - 5}px`;
            }
            else {
                parentElement.style.height = `${this.availableHeight + 15}px`;
            }
            console.log('Updated availableHeight:', this.availableHeight);
        }
    }


    handleGetServiceAppointments(offset, pageSize, sortBy, sortDirection) {
        this.isLoading = true;

        console.log('handleGetServiceAppointments', offset, pageSize, sortBy, sortDirection);
        getServiceAppointments({
            ofst: offset,
            lmt: pageSize,
            sortBy: sortBy,
            sortDirection: sortDirection
        })
            .then(result => {
                this.hasMoreRecords = result.length >= this.pageSize;

                if (Array.isArray(result) && result.length > 0) {
                    if (this.offset === 0) {
                        this.serviceAppointmentsList = [];
                    }

                    console.log('before', this.serviceAppointmentsList.map(item => item.id));

                    result.forEach((row, index) => {
                        const contact = row.Case__r?.Contact || {};
                        const caseDetails = row.Case__r || {};
                        const account = caseDetails.Account || {};
                        const asset = caseDetails.Asset || {};

                        const obj = {
                            id: row.Id,
                            // Id: row.Id,
                            name: row.Name,
                            caseNumber: caseDetails.CaseNumber || '',
                            caseType: caseDetails.Type || '',
                            caseSubType: caseDetails.Case_Sub_Type__c || '',
                            remoteSupport: row.Remote_Support__c,
                            isAdditionalResource: row.Is_Additional_Resource__c,
                            planDate: row.Scheduled_Start__c,
                            custName: account.Name || '',
                            caseId: row.Case__c,
                            status: row.Status__c,
                            priority: row.Priority__c,
                            serialNumber: asset.SerialNumber || '',
                            contact: {
                                id: caseDetails.ContactId,
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

                        const existingIndex = this.serviceAppointmentsList.findIndex(item => item.id === obj.id);
                        if (existingIndex === -1) {
                            this.serviceAppointmentsList.push(obj);
                        }
                        else {
                            const updateIndex = offset === 0 ? index : existingIndex;
                            console.log('updateIndex', updateIndex, 'offset', offset, 'index', index, 'existingIndex', existingIndex);
                            this.serviceAppointmentsList[updateIndex] = obj;
                        }

                    });

                    this.serviceAppointmentsList.forEach((item, index) => {
                        item.index = index + 1;
                    })

                    console.log('after', this.serviceAppointmentsList.map(item => item.id));
                }

                console.log('serviceAppointmentsList', this.serviceAppointmentsList);
            })
            .catch(error => {
                console.log('getServiceAppointments', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
                this.isLoading = false;
            });
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


    handleScroll() {
        const buffer = 50;
        const scrollableContainer = this.template.querySelector(".scrollable");

        if (!scrollableContainer) return;

        const { scrollTop, scrollHeight, clientHeight } = scrollableContainer;

        if (scrollHeight - scrollTop - clientHeight < buffer && !this.isLoading && this.hasMoreRecords) {
            this.offset += this.pageSize;

            const sortedColumn = this.columns.find(column => column.sortDir);
            this.handleGetServiceAppointments(
                this.offset,
                this.pageSize,
                sortedColumn?.name,
                sortedColumn?.sortDir
            );
        }
    }


    handleSort(event) {
        const { fieldName: sortedBy, sortDirection, sortable } = event.currentTarget.dataset;

        if (sortable !== 'true') return;

        this.columns.forEach(column => {
            column.sortDir = column.name === sortedBy ? (sortDirection === 'ASC' ? 'DESC' : 'ASC') : '';
        });

        this.offset = 0;
        this.serviceAppointmentsList = [];

        const sortedColumn = this.columns.find(column => column.sortDir);
        this.handleGetServiceAppointments(
            this.offset,
            this.pageSize,
            sortedColumn?.name,
            sortedColumn?.sortDir
        );
    }





    @track showServiceAppointmentInfoModal;
    @track selectedServiceAppointment;

    handleServiceAppointmentPreviewClick(event) {
        console.log('handleServiceAppointmentPreviewClick', JSON.stringify(event.currentTarget.dataset));
        this.selectedServiceAppointment = this.serviceAppointmentsList.find(item => item.id === event.currentTarget.dataset.id);
        if (this.isTablet || this.isDesktop) {
            loadQuickActionPopupStyle(this, 65);
        }
        this.showServiceAppointmentInfoModal = true;
    }


    handleOpenRecord(event) {
        const { id } = event.currentTarget.dataset;
        navigateToRecord(this, id);
    }


    handleCloseServiceAppointmentInfoModal() {
        this.showServiceAppointmentInfoModal = false;
        this.selectedServiceAppointment = null;
        unloadQuickActionPopupStyle(this);
        const sortedColumn = this.columns.find(column => column.sortDir);
        this.handleGetServiceAppointments(
            0,
            this.serviceAppointmentsList.length,
            sortedColumn?.name,
            sortedColumn?.sortDir
        );
    }





    @track columns = [
        { name: 'index', label: '', isSortable: false },
        { name: 'Scheduled_Start__c', label: 'Date', isSortable: true, sortDir: 'ASC', get isAsc() { return this.sortDir === 'ASC'; }, get isDesc() { return this.sortDir === 'DESC'; } },
        { name: 'caseNo', label: 'Case No', isSortable: false },
        { name: 'Case__r.Account.Name', label: 'Customer', isSortable: true, sortDir: '', get isAsc() { return this.sortDir === 'ASC'; }, get isDesc() { return this.sortDir === 'DESC'; } },
        { name: 'Case__r.Asset.Name', label: 'Serial Number', isSortable: true, sortDir: '', get isAsc() { return this.sortDir === 'ASC'; }, get isDesc() { return this.sortDir === 'DESC'; } },
        { name: 'Case__r.Type', label: 'Type', isSortable: true, sortDir: '', get isAsc() { return this.sortDir === 'ASC'; }, get isDesc() { return this.sortDir === 'DESC'; } },
        { name: 'Case__r.Case_Sub_Type__c', label: 'Sub Type', isSortable: true, sortDir: '', get isAsc() { return this.sortDir === 'ASC'; }, get isDesc() { return this.sortDir === 'DESC'; } },
    ];


}