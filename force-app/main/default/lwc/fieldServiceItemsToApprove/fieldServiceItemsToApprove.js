import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';

import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToRecordInNewTab, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh, navigateToFilePreview } from 'c/utilJS';


import getItemsToApprove from '@salesforce/apex/FieldServiceItemsToApproveController.getItemsToApprove';





export default class FieldServiceItemsToApprove extends NavigationMixin(LightningElement) {

    @track showSpinner = true;

    @track isMobile;
    @track isTablet;
    @track isDesktop;


    @track offset = 0;
    @track limit = 20;

    @track isLoading = false;
    @track hasMoreRecords;


    @track recordList;



    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        // this.hasMoreRecords = false;
        this.offset = 0;
        this.recordList = [];
        this.hasMoreRecords = false;
        this.handleGetItemsToApprove();

    }


    connectedCallback() {
        window.addEventListener('resize', this.calculateHeight.bind(this));
    }

    renderedCallback() {
        analyzeFormFactor(this);
        if (!this.availableHeight) {
            this.calculateHeight();
        }
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.calculateHeight.bind(this));
    }


    calculateHeight() {
        let parentElement;
        if (this.isDesktop) parentElement = this.template.querySelector('.datatable-container');
        else parentElement = this.template.querySelector('.mobile-scroll-container');
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


    handleGetItemsToApprove() {
        console.log('handleGetItemsToApprove', 'offset', this.offset, 'limit', this.limit, 'isLoading', this.isLoading);
        getItemsToApprove({ offset: this.offset, lmt: this.limit, sortBy: 'CreatedDate', sortDirection: 'DESC' })
            .then(data => {
                const { recordList = [], targetObjectLabelMap, processInstanceMap, quoteMap } = data;
                if (recordList.length) {
                    const newRecords = recordList.map(item => {
                        const {
                            Id: id,
                            ProcessInstance: {
                                TargetObjectId: relatedTo,
                                TargetObject: { Name: relatedToName } = {},
                            } = {},
                            ProcessInstanceId: processInstanceId,
                            CreatedDate: dateSubmitted
                        } = item;

                        const processInstance = processInstanceMap[processInstanceId]?.Steps?.[0] || {};
                        const { ActorId: mostRecentApprover, Actor: { Name: mostRecentApproverName } = {} } = processInstance;

                        const quote = quoteMap[relatedTo] || {};
                        const { Quote_Document_Type__c: documentType, Billing_Type__c: billingType } = quote;

                        return {
                            id,
                            relatedTo,
                            relatedToName,
                            type: targetObjectLabelMap?.[relatedTo.substring(0, 3)] || '',
                            documentType,
                            billingType,
                            mostRecentApprover,
                            mostRecentApproverName,
                            dateSubmitted,
                            processInstanceId,
                        };
                    });

                    this.recordList = this.offset === 0 ? newRecords : this.recordList.concat(newRecords);
                    console.log('recordList', this.recordList, this.recordList.length);
                    this.hasMoreRecords = true;
                }
                if (recordList.length < this.limit) {
                    this.hasMoreRecords = false;
                }
            })
            .catch(error => {
                console.error('Error fetching approval count:', error);
                showToast(this, 'Error', 'Error fetching asset count', 'error', error);
                this.recordList = undefined;
            })
            .finally(() => {
                const datatable = this.template.querySelector('lightning-datatable');
                if (datatable) {
                    datatable.isLoading = false;
                    this.isLoading = false;
                    // console.log('load data finished loading');
                }
            });
    }


    handleLoadMoreData(event) {
        if (!this.hasMoreRecords) {
            return;
        }

        let datatable = this.template.querySelector('lightning-datatable');
        if (datatable) {
            if (datatable.isLoading) {
                // console.log('load data already loading');
                return;
            }
            else {
                datatable.isLoading = true;
                this.isLoading = true;
                // console.log('load data started loading');
            }

            this.offset += this.limit;
            this.handleGetItemsToApprove();
        }
    }


    handleMobileScroll(event) {
        const container = event.target;
        // console.log('scrollTop', container.scrollTop, 'clientHeight', container.clientHeight, 'scrollHeight', container.scrollHeight);
        const bottomReached = container.scrollTop + container.clientHeight >= container.scrollHeight - 50;

        // console.log('bottomReached', bottomReached, 'isLoading', this.isLoading, 'hasMoreRecords', this.hasMoreRecords);
        if (bottomReached && !this.isLoading && this.hasMoreRecords) {
            this.isLoading = true;
            this.offset += this.limit;
            this.handleGetItemsToApprove();
        }
    }




    handleRowAction(event) {
        const row = event.detail.row;
        const recordId = event.detail.row.Id;

        const actionName = event.detail.action.name;

        if (actionName === 'relatedTo') {
            navigateToRecord(this, row.id, undefined, null);
        }
        if (actionName === 'mostRecentApprover') {
            navigateToRecord(this, row.mostRecentApprover, 'User', null);
        }

        if (actionName === 'accept') {

        }
        if (actionName === 'reject') {

        }
        if (actionName === 'reassign') {

        }
    }



    handleMobileCardClick(event) {
        const recordId = event.currentTarget.dataset.id;
        navigateToRecord(this, recordId, 'ProcessInstanceWorkitem', null);
    }







    get columns() {
        return [
            {
                label: 'Related To',
                fieldName: 'relatedTo',
                type: 'button',
                sortable: false,
                wrapText: false,
                cellAttributes: { alignment: 'left' },
                typeAttributes: { label: { fieldName: 'relatedToName' }, name: 'relatedTo', title: { fieldName: 'relatedToName' }, disabled: false, value: 'relatedTo', variant: 'base' },
                sortByName: 'ProcessInstance.TargetObject.Name',
            },
            /*
            {
                label: 'Type',
                fieldName: 'type',
                type: 'text',
                sortable: false,
                wrapText: false,
                cellAttributes: { alignment: 'left' },
                sortByName: 'Type__c'
            },
            */
            // Quote Document Type, Billing Type
            {
                label: 'Document Type',
                fieldName: 'documentType',
                type: 'text',
                sortable: false,
                wrapText: false,
                cellAttributes: { alignment: 'left' },
                sortByName: 'Quote_Document_Type__c'
            },
            {
                label: 'Billing Type',
                fieldName: 'billingType',
                type: 'text',
                sortable: false,
                wrapText: false,
                cellAttributes: { alignment: 'left' },
                sortByName: 'Billing_Type__c'
            },
            {
                label: 'Most Recent Approver',
                fieldName: 'mostRecentApprover',
                type: 'button',
                sortable: false,
                wrapText: false,
                cellAttributes: { alignment: 'left' },
                typeAttributes: { label: { fieldName: 'mostRecentApproverName' }, name: 'mostRecentApprover', title: { fieldName: 'mostRecentApproverName' }, disabled: false, value: 'mostRecentApprover', variant: 'base' },
                sortByName: 'ProcessInstance.LastActor.Name'
            },
            {
                label: 'Date Submitted',
                fieldName: 'dateSubmitted',
                type: 'date',
                sortable: false,
                wrapText: false,
                cellAttributes: { alignment: 'left' },
                typeAttributes: {
                    year: "numeric",
                    month: "2-digit",
                    day: "2-digit",
                    hour: "2-digit",
                    minute: "2-digit"
                },
                sortByName: 'CreatedDate'
            },
            /*
            {
                type: 'action',
                typeAttributes: {
                    rowActions: [
                        { label: 'Approve', name: 'approve' },
                        { label: 'Reject', name: 'reject' },
                        { label: 'Reassign', name: 'reassign' }
                    ],
                    // menuAlignment: 'auto'
                }
            }
            */
        ];
    }

}