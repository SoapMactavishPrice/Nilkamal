import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';

import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToRecordInNewTab, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh, navigateToFilePreview } from 'c/utilJS';


import getListOfCasesAndFeedItems from '@salesforce/apex/FieldServiceTechItemsToActionController.getListOfCasesAndFeedItems';
export default class FieldServiceTagItemsForAction extends NavigationMixin(LightningElement) {
    @track showSpinner = true;

    @track isMobile;
    @track isTablet;
    @track isDesktop;


    @track offset = 0;
    @track limit = 50;

    @track isLoading = false;
    @track hasMoreRecords;


    @track recordList;



    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        // this.hasMoreRecords = false;
        this.offset = 0;
        this.recordList = [];
        this.hasMoreRecords = false;
        this.handleGetItemsForAction();

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




    handleGetItemsForAction() {
        console.log('handleGetItemsForAction', 'offset', this.offset, 'limit', this.limit, 'isLoading', this.isLoading);
        getListOfCasesAndFeedItems({ offset: this.offset, lmt: this.limit })
            .then(data => {
                console.log('handleGetItemsForAction', 'data', data);
                const { caseList, feedItemList } = data;
                if (this.offset === 0) {
                    this.recordList = [];
                }

                const caseMap = {};
                caseList.forEach(item => {
                    caseMap[item.Id] = item;
                });
                console.log('caseMap', caseMap);

                function formatDate(dateStr) {
                    if (!dateStr) return '';
                    return new Date(dateStr).toLocaleString('en-IN', {
                        timeZone: 'Asia/Kolkata',
                        year: 'numeric',
                        month: 'short',
                        day: '2-digit',
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: true
                    });
                }

                const newRecords = feedItemList.map(item => {
                    const caseRecord = caseMap[item.ParentId] || {};
                    const latestComment = item.FeedComments ? item.FeedComments[item.FeedComments.length - 1] : {};

                    return {
                        caseId: item?.ParentId,
                        caseLink: `/lightning/r/Case/${item.ParentId}/view`,
                        caseNumber: caseRecord?.CaseNumber,
                        caseOwnerId: caseRecord?.OwnerId,
                        caseOwnerName: caseRecord?.Owner?.Name,
                        firstCommentBody: item.Body,
                        firstCommentBy: item.CreatedBy?.Name,
                        firstCommentDate: item.CreatedDate,
                        latestCommentBody: latestComment.CommentBody,
                        latestCommentBy: latestComment.CreatedBy?.Name,
                        latestCommentDate: latestComment.CreatedDate,



                        get firstCommentByText() {
                            return this.firstCommentBy + '<br/>' + formatDate(this.firstCommentDate);
                        },
                        get latestCommentByText() {
                            if (!this.latestCommentBy) return '';
                            return this.latestCommentBy + '<br/>' + formatDate(this.latestCommentDate);
                        },
                    };
                })

                this.recordList = this.offset === 0 ? newRecords : this.recordList.concat(newRecords);
                console.log('recordList', this.recordList);

                if (this.recordList.length == 0) {
                    this.recordList = undefined;
                }


                if (caseList.length < this.limit) {
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
                console.log('load data already loading');
                return;
            }
            else {
                datatable.isLoading = true;
                this.isLoading = true;
                console.log('load data started loading');
            }

            this.offset += this.limit;
            this.handleGetItemsForAction();
        }
    }


    handleMobileScroll(event) {
        const container = event.target;

        const bottomReached = container.scrollTop + container.clientHeight >= container.scrollHeight - 50;

        if (bottomReached && !this.isLoading && this.hasMoreRecords) {
            this.isLoading = true;
            this.offset += this.limit;
            this.handleGetItemsForAction();
        }
    }




    handleRowAction(event) {
        const row = event.detail.row;
        console.log('handleRowAction', 'row', row);

        const recordId = event.detail.row.Id;
        console.log('recordId', recordId);

        const actionName = event.detail.action.name;
        console.log('handleRowAction', 'actionName', actionName);


        if (actionName === 'caseNumber') {
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
        console.log('handleMobileCardClick', 'event', event);
        console.log('handleMobileCardClick', 'event.target', event.target);
        console.log('handleMobileCardClick', 'event.target.dataset.id', event.target.dataset.id);
        let recordId = event.currentTarget.dataset.id;
        console.log('recordId', recordId);
        navigateToRecord(this, recordId, 'ProcessInstanceWorkitem', null);
    }

    get columns() {
        return [
            // {
            //     label: 'Related To',
            //     fieldName: 'relatedTo',
            //     type: 'button',
            //     sortable: false,
            //     wrapText: false,
            //     cellAttributes: { alignment: 'left' },
            //     typeAttributes: { label: { fieldName: 'relatedToName' }, name: 'relatedTo', title: { fieldName: 'relatedToName' }, disabled: false, value: 'relatedTo', variant: 'base' },
            //     sortByName: 'ProcessInstance.TargetObject.Name',
            // },
            {
                label: 'Case Number',
                fieldName: 'caseLink',
                type: 'url',
                sortable: false,
                wrapText: false,
                cellAttributes: { alignment: 'left' },
                typeAttributes: {
                    label: { fieldName: 'caseNumber' },
                    target: '_blank'
                }
            },
            {
                label: 'Case Owner',
                fieldName: 'caseOwnerName',
                type: 'text',
                sortable: false,
                wrapText: true,
                cellAttributes: { alignment: 'left' }
            },
            {
                label: 'First Comment',
                fieldName: 'firstCommentBody',
                type: 'richText',
                sortable: false,
                wrapText: true,
                cellAttributes: { alignment: 'left' }
            },
            {
                label: 'First Comment By',
                fieldName: 'firstCommentByText',
                type: 'richText',
                sortable: false,
                wrapText: true,
                cellAttributes: { alignment: 'left' }
            },
            {
                label: 'Last Comment',
                fieldName: 'latestCommentBody',
                type: 'richText',
                sortable: false,
                wrapText: true,
                cellAttributes: { alignment: 'left' },
                sortByName: 'Quote_Document_Type__c'
            },
            {
                label: 'Last Comment By',
                fieldName: 'latestCommentByText',
                type: 'richText',
                sortable: false,
                wrapText: true,
                cellAttributes: { alignment: 'left' },
                sortByName: 'Quote_Document_Type__c'
            },
            // {
            //     label: 'Billing Type',
            //     fieldName: 'billingType',
            //     type: 'text',
            //     sortable: false,
            //     wrapText: false,
            //     cellAttributes: { alignment: 'left' },
            //     sortByName: 'Billing_Type__c'
            // },
            // {
            //     label: 'Most Recent Approver',
            //     fieldName: 'mostRecentApprover',
            //     type: 'button',
            //     sortable: false,
            //     wrapText: false,
            //     cellAttributes: { alignment: 'left' },
            //     typeAttributes: { label: { fieldName: 'mostRecentApproverName' }, name: 'mostRecentApprover', title: { fieldName: 'mostRecentApproverName' }, disabled: false, value: 'mostRecentApprover', variant: 'base' },
            //     sortByName: 'ProcessInstance.LastActor.Name'
            // },
            // {
            //     label: 'Date Submitted',
            //     fieldName: 'dateSubmitted',
            //     type: 'date',
            //     sortable: false,
            //     wrapText: false,
            //     cellAttributes: { alignment: 'left' },
            //     typeAttributes: {
            //         year: "numeric",
            //         month: "2-digit",
            //         day: "2-digit",
            //         hour: "2-digit",
            //         minute: "2-digit"
            //     },
            //     sortByName: 'CreatedDate'
            // },

        ];
    }
}