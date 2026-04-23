import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';

import { showToast, analyzeFormFactor, analyzeUserAgent, navigateToLWC, navigateToObjectPage } from 'c/utilJS';

import getSummarizedData from '@salesforce/apex/FieldServiceHomeController.getSummarizedData';

// import getCaseSummary from '@salesforce/apex/FieldServiceHomeController.getCaseSummary';
// import getEventsList from '@salesforce/apex/FieldServiceHomeController.getEventsList';
// import getCountOfAssets from '@salesforce/apex/FieldServiceAssetListController.getCountOfAssets';
// import getUserDetails from '@salesforce/apex/UtilityCls.getUserDetails';

// import getDashboardId from '@salesforce/apex/FieldServiceHomeController.getDashboardId';
// import getApprovalItemsWithCount from '@salesforce/apex/FieldServiceAssetListController.getApprovalItemsWithCount';
// import getNewCaseCountForRSM from '@salesforce/apex/FieldServiceHomeController.getNewCaseCountForRSM';
// import getCountOfCasesAndFeedItems from '@salesforce/apex/FieldServiceHomeController.getCountOfCasesAndFeedItems';





export default class FieldServiceHome extends NavigationMixin(LightningElement) {

    @track showSpinner = false;

    @track isMobile;
    @track isTablet;
    @track isDesktop;

    @track isSE = true;
    @track isRSM = false;
    @track isCoordinator = false;
    @track isServiceHead = false;
    @track isTechSupport = false;
    @track isRSMPrinter = false;


    caseData = {
        NewCases: 0,
        MissedCases: 0,
        TodaysActions: 0,
        OpenCases: 0
    };



    @track openEvents;
    @track missedEvents;
    @track upcomingEvents;


    @track isOpenEventsVisible = true;
    @track isMissedEventsVisible = false;
    @track isUpcomingEventsVisible = false;


    @track eventsInView = this.openEvents;


    @track approvalItems = [];
    @track totalApprovals = 0;

    @track caseCount;


    @track eventsList = [
        { label: 'Open', events: this.openEvents },
        { label: 'Missed', events: this.missedEvents },
        { label: 'Upcoming', events: this.upcomingEvents }
    ];


    @track sectionList = [
        {
            label: 'My Schedule',
            items: [
                {
                    label: 'Create Visit',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/create_visit.svg`,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceCreateVisit'),
                    isVisible: true
                },
                {
                    label: 'Open Appointments',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/open_appointments.svg`,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceOpenAppointments'),
                    isVisible: true
                },
                {
                    label: 'Items to Approve',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/items_to_approve.svg`,
                    pendingTasksCount: 0,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceItemsToApprove'),
                    get isPendingTasksCountAvailable() {
                        console.log('Items to Approve', this.pendingTasksCount != null);
                        return this.pendingTasksCount != null;
                    },
                    isVisible: false
                },
                {
                    label: 'Items for Action',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/items_to_approve.svg`,
                    pendingTasksCount: 0,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceTagItemsForAction'),
                    get isPendingTasksCountAvailable() { return this.pendingTasksCount != null; },
                    isVisible: false
                }
            ]
        },
        {
            label: 'Action',
            items: [
                {
                    label: 'Create Case',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/create_case.svg`,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceCreateCase'),
                    isVisible: true
                },
                {
                    label: 'Assigned Cases',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/open_case.svg`,
                    pendingTasksCount: 0,
                    clickHandler: () => navigateToObjectPage(this, 'Case', 'list', { filterName: 'MyOpenCases' }),
                    get isPendingTasksCountAvailable() { return this.pendingTasksCount != null; },
                    isVisible: true
                },
                {
                    label: 'Open Cases',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/open_queue.svg`,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceQueue'),
                    isVisible: true
                },
                {
                    label: 'Case Assignment',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/open_case.svg`,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceOpenQueue2'),
                    isVisible: false
                }
                /*
                {
                    label: 'Dashboard',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/dashboard.svg`,
                    clickHandler: () => {
                        const section = this.sectionList.find(section => section.label === 'Action');
                        const sectionItem = section?.items.find(item => item.label === 'Dashboard');
                        navigateToRecord(this, sectionItem.dashboardId);
                    },
                    isVisible: false
                }
                */
            ]
        },
        {
            label: 'Request',
            items: [
                {
                    label: 'Open Spare Quotes',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/spares_quote.svg`,
                    clickHandler: () => navigateToLWC(this, 'openSpareRequest'),
                    isVisible: true
                },
                {
                    label: 'Assets under Warranty',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/assets_under_warranty.svg`,
                    pendingTasksCount: 0,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceAssetList', { c__target: 'AssetsUnderWarranty' }),
                    get isPendingTasksCountAvailable() { return this.pendingTasksCount != null; },
                    isVisible: true
                },
                {
                    label: 'Assets under AMC',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/assets_under_amc.svg`,
                    pendingTasksCount: 0,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceAssetList', { c__target: 'AssetsUnderAMC' }),
                    get isPendingTasksCountAvailable() { return this.pendingTasksCount != null; },
                    isVisible: true
                },
                {
                    label: 'All Assets',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/total_assets.svg`,
                    pendingTasksCount: 0,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceAssetList', { c__target: 'TotalAsset' }),
                    get isPendingTasksCountAvailable() { return this.pendingTasksCount != null; },
                    isVisible: true
                },
                {
                    label: 'Mark Leave',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/mark_leave.svg`,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceMarkLeave'),
                    isVisible: true
                },
                {
                    label: 'Transfer Asset',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/transfer_asset.svg`,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceTransferAsset'),
                    isVisible: false
                },
                {
                    label: 'Rental Assets',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/assets_under_warranty.svg`,
                    pendingTasksCount: 0,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceAssetList', { c__target: 'RentalAssets' }),
                    get isPendingTasksCountAvailable() { return this.pendingTasksCount != null; },
                    isVisible: true
                },
                {
                    label: 'Expired Assets',
                    imageUrl: `${FieldServiceAppResources}/fieldservicehome/icons/assets_under_warranty.svg`,
                    pendingTasksCount: 0,
                    clickHandler: () => navigateToLWC(this, 'fieldServiceAssetList', { c__target: 'ExpiredAssets' }),
                    get isPendingTasksCountAvailable() { return this.pendingTasksCount != null; },
                    isVisible: true
                },

            ]
        }
    ];






    @track refreshNeeded = false;
    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        console.log('currentPageReference');
        this.refreshNeeded = true;
        setTimeout(() => {
            this.refreshNeeded = false;
            this.initializeData();
        }, 100);
    }


    connectedCallback() {
        console.log('connectedCallback from FieldServiceHome');
        analyzeUserAgent(this);
        analyzeFormFactor(this);
    }


    renderedCallback() {
        console.log('renderedCallback from FieldServiceHome');
        analyzeFormFactor(this);
        if (this.refreshNeeded) {
            setTimeout(() => {
                this.refreshNeeded = false;
                this.initializeData(true);
            }, 100);
        }
    }



    async initializeData(isRefresh = false) {
        // if (!isRefresh) this.showSpinner = true;

        const findSectionItem = (sectionLabel, itemLabel) => {
            const section = this.sectionList?.find(s => s.label === sectionLabel);
            return section?.items?.find(i => i.label === itemLabel);
        };

        const requireSectionItem = (sectionLabel, itemLabel) => {
            const item = findSectionItem(sectionLabel, itemLabel);
            if (!item) throw new Error(`Missing section/item: ${sectionLabel} -> ${itemLabel}`);
            return item;
        };

        const setPending = (sectionLabel, itemLabel, count) => {
            requireSectionItem(sectionLabel, itemLabel).pendingTasksCount = count;
        };

        const withErrorToast = (toastMsg, fn, logPrefix = toastMsg) => {
            try {
                fn();
            } catch (error) {
                console.log(`${logPrefix}`, error);
                showToast(this, 'Error', toastMsg, 'error', error);
            }
        };

        const formatAddress = asset =>
            [asset?.Ship_to_Address__c, asset?.Ship_To_City__c, asset?.Ship_To_Region__c, asset?.Ship_to_Country__c, asset?.Ship_to_Pin__c]
                .filter(Boolean)
                .join(' ');

        const mapEvent = (event, index) => {
            const { Work_Order__r, Account__r, Id, Name } = event || {};
            const { Case__r } = Work_Order__r || {};
            const { Asset, CaseNumber, CreatedDate } = Case__r || {};
            const { SerialNumber } = Asset || {};
            const customerName = Account__r?.Name || Case__r?.Account?.Name || Case__r?.SuppliedEmail;

            return { srNo: index + 1, id: Id, name: Name, caseNumber: CaseNumber, customerName, serialNumber: SerialNumber, address: formatAddress(Asset), createdDate: CreatedDate };
        };

        getSummarizedData({})
            .then(result => {
                const { caseSummary, eventsList, countOfAssets, userDetails, dashboardId, approvalItemsWithCount, newCaseCountForRSM, countOfCasesAndFeedItems } = result;

                // Case summary
                withErrorToast('Error fetching case summary', () => {
                    const { newCases, missedCases, todaysActions, openCases } = caseSummary || {};
                    this.caseData = { newCases, missedCases, todaysActions, openCases };
                }, 'Error fetching case summary:');

                // Events mapping
                withErrorToast('Error mapping events', () => {
                    this.openEvents = (eventsList?.openEvents || []).map(mapEvent);
                    this.missedEvents = (eventsList?.missedEvents || []).map(mapEvent);
                    this.upcomingEvents = (eventsList?.upcomingEvents || []).map(mapEvent);

                    this.eventsInView = this.openEvents;
                }, 'Error mapping events:');

                // Asset counts
                withErrorToast('Error setting asset counts', () => {
                    const { warrantyCount, amcCount, assetCount, rentalAssetCount, expiredAssetCount } = countOfAssets || {};
                    setPending('Request', 'Assets under Warranty', warrantyCount);
                    setPending('Request', 'Assets under AMC', amcCount);
                    setPending('Request', 'All Assets', assetCount);
                    setPending('Request', 'Rental Assets', rentalAssetCount);
                    setPending('Request', 'Expired Assets', expiredAssetCount);
                }, 'Error setting asset counts:');

                // User details and visibility
                withErrorToast('Error in userDetails', () => {
                    this.userDetails = userDetails;
                    const userRoleName = this.userDetails?.UserRole?.Name?.toLowerCase() || '';
                    const profileName = this.userDetails?.Profile?.Name?.toLowerCase() || '';
                    this.isSE = userRoleName.includes('engineer');
                    this.isRSM = userRoleName.includes('rsm');
                    this.isCoordinator = userRoleName.includes('coordinator');
                    this.isServiceHead = userRoleName.includes('service head') || userRoleName === 'system administrator' || profileName === 'system administrator';
                    this.isTechSupport = userRoleName.includes('technical') || profileName === 'system administrator';
                    this.isRSMPrinter = userRoleName.includes('rsm printer');
                    const updateVisibility = (sectionLabel, itemLabel) => {
                        const item = findSectionItem(sectionLabel, itemLabel);
                        if (item) item.isVisible = true;
                    };

                    if (this.isRSM || this.isCoordinator || this.isServiceHead) {
                        updateVisibility('My Schedule', 'Items to Approve');
                        updateVisibility('Action', 'Case Assignment');
                    }
                    if (this.isCoordinator || this.isServiceHead || this.isRSMPrinter) {
                        updateVisibility('Request', 'Transfer Asset');
                    }
                    if (this.isTechSupport) {
                        updateVisibility('My Schedule', 'Items for Action');
                        setPending('My Schedule', 'Items for Action', countOfCasesAndFeedItems);
                    }
                }, 'Error in userDetails:');

                // Dashboard id
                /*
                withErrorToast('Error getting dashboard id', () => {
                    if (dashboardId) {
                        requireSectionItem('Action', 'Dashboard').dashboardId = dashboardId;
                        console.log('dashboardId', dashboardId);
                    }
                }, 'Error getting dashboard id:');
                */

                // approval item count
                withErrorToast('Error getting approval count', () => {
                    this.approvalItems = approvalItemsWithCount?.items;
                    this.totalApprovals = approvalItemsWithCount?.count;
                    setPending('My Schedule', 'Items to Approve', this.totalApprovals);
                }, 'Error getting approval count:');

                // new case count
                withErrorToast('Error getting approval count', () => {
                    console.log('getNewCaseCountForRSM', newCaseCountForRSM);
                    this.caseCount = newCaseCountForRSM;
                    setPending('Action', 'Assigned Cases', this.caseCount);
                }, 'Error getting approval count:');
            })
            .catch(error => {
                console.log('Error loading data:', error);
                showToast(this, 'Error', 'Error loading data', 'error', error);
            });
    }


    updateEventView(events, openVisible, missedVisible, upcomingVisible) {
        this.eventsInView = events;
        this.isOpenEventsVisible = openVisible;
        this.isMissedEventsVisible = missedVisible;
        this.isUpcomingEventsVisible = upcomingVisible;
    }

    handleOpenEventsClick() {
        this.updateEventView(this.openEvents, true, false, false);
    }

    handleMissedEventsClick() {
        this.updateEventView(this.missedEvents, false, true, false);
    }

    handleUpcomingEventsClick() {
        this.updateEventView(this.upcomingEvents, false, false, true);
    }


    handlePreviousNextClick(event) {
        const { dataset: { action } } = event.target;
        const element = this.template.querySelector(`[data-current="${action}"]`);
        element?.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
    }


    handleSummaryClick(event) {
        const { id } = event.currentTarget.dataset;
        if (this.isMobile) {
            if (id === 'newCases') {
                navigateToObjectPage(this, 'Case', 'list', { filterName: 'New_Cases_Dashboard' });
            }
            else if (id === 'missedCases') {
                navigateToObjectPage(this, 'Case', 'list', { filterName: 'Missed_Cases_Dashboard' });
            }
            else if (id === 'todaysActions') {
                const parentElement = this.template.querySelector('.events-table-container');
                const upcomingCasesElement = parentElement.querySelector(`[data-id="upcomingCases"]`);
                parentElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
                setTimeout(() => {
                    upcomingCasesElement?.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }, 300);
            }
            else if (id === 'openCases') {
                navigateToObjectPage(this, 'Case', 'list', { filterName: 'Open_Cases_Dashboard' });
            }
        }
        else {
            if (id === 'newCases') {
                navigateToObjectPage(this, 'Case', 'list', { filterName: 'New_Cases_Dashboard' });
            }
            else if (id === 'missedCases') {
                navigateToObjectPage(this, 'Case', 'list', { filterName: 'Missed_Cases_Dashboard' });
            }
            else if (id === 'todaysActions') {
                this.updateEventView(this.openEvents, true, false, false);
            }
            else if (id === 'openCases') {
                navigateToObjectPage(this, 'Case', 'list', { filterName: 'Open_Cases_Dashboard' });
            }
        }
    }


    handleToggleDescription(event) {
        const textElement = event.target;

        if (textElement.classList.contains('truncate')) {
            textElement.classList.remove('truncate');
            textElement.classList.add('expanded');
        } else {
            textElement.classList.remove('expanded');
            textElement.classList.add('truncate');
        }
    }

}