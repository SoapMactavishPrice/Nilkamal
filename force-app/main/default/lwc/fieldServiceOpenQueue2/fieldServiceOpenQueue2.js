import { LightningElement, wire, track, api } from 'lwc';
//import getCasesForCurrentUser from '@salesforce/apex/FieldServiceOpenQueue2.getCasesForCurrentUser';
//import sendRejectionNotification from '@salesforce/apex/FieldServiceOpenQueue2.sendRejectionNotification';
//import acceptCase from '@salesforce/apex/FieldServiceOpenQueue2.acceptCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpenQueueCases from '@salesforce/apex/FieldServiceOpenQueue2.getOpenQueueCases';
import getUsersByTerritoryFromCases from '@salesforce/apex/FieldServiceOpenQueue2.getUsersByTerritoryFromCases';
import saveCaseWithNewOwner from '@salesforce/apex/FieldServiceOpenQueue2.saveCaseWithNewOwner';
import saveCaseTeamRecords from '@salesforce/apex/FieldServiceOpenQueue2.saveCaseTeamRecords';
import updateCaseAndSendCaseOwnerNotification from '@salesforce/apex/FieldServiceOpenQueue2.updateCaseAndSendCaseOwnerNotification';
import handleReAssignRequest from '@salesforce/apex/FieldServiceOpenQueue2.handleReAssignRequest';

import { updateRecord } from 'lightning/uiRecordApi';
//
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { createRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';
import { publish, MessageContext } from 'lightning/messageService';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, publishRefreshEvent, closeQuickActionPopup, disablePullToRefresh, navigateToRecordInNewTab } from 'c/utilJS';


import CASE_TEAM_OBJECT from '@salesforce/schema/Case_Team__c';
import CASE_TEAM_CASE_TEAM_ROLE from '@salesforce/schema/Case_Team__c.Case_Team_Role__c';
import CASE_TEAM_ACCESS_LEVEL from '@salesforce/schema/Case_Team__c.Access_Level__c';


import getCaseTeamRoles from '@salesforce/apex/CaseTeamLWCController.getCaseTeamRoles';




export default class FieldServiceOpenQueue2 extends NavigationMixin(LightningElement) {
    @track showSpinner = false;

    @track cases = [];
    @track casesToDisplay = [];
    @track isModalOpen = false;
    @track modalData = {};

    // @track activeTab = 'Reassigned';
    @track activeTab = 'Non-Reassigned';
    Queue = 'Open Queue';
    @track userOptions = [];

    @track allReassignedCases = [];
    @track allNonReassignedCases = [];
    @track allAdditionalResourceCases = [];

    @track reassignedCases = [];
    @track nonReassignedCases = [];
    @track additionalResourceCases = [];


    @track isMobile;
    @track isTablet;
    @track isDesktop;


    // Pagination variables for reassigned cases
    @track currentPageReassigned = 1;
    @track itemsPerPageReassigned = 10;

    calculateTotalPages(cases, itemsPerPage, currentPageKey) {
        const len = cases ? cases.length : 0;
        const totalPages = Math.ceil(len / itemsPerPage);
        if (this[currentPageKey] > totalPages) {
            this[currentPageKey] = totalPages || 1;
        }
        return totalPages;
    }

    get totalPagesReassigned() {
        return this.calculateTotalPages(this.reassignedCases, this.itemsPerPageReassigned, 'currentPageReassigned');
    }

    get totalPagesNonReassigned() {
        return this.calculateTotalPages(this.nonReassignedCases, this.itemsPerPageNonReassigned, 'currentPageNonReassigned');
    }

    get totalPagesAdditionalResource() {
        return this.calculateTotalPages(this.additionalResourceCases, this.itemsPerPageAdditionalResource, 'currentPageAdditionalResource');
    }



    // Pagination variables for non-reassigned cases
    @track currentPageNonReassigned = 1;
    @track itemsPerPageNonReassigned = 10;

    @track currentPageAdditionalResource = 1;
    @track itemsPerPageAdditionalResource = 10;

    // @track totalPagesNonReassigned = 1;
    // @track totalPagesAdditionalResource = 1;

    @track today;

    connectedCallback() {
        console.log('connectedCallback from CaseTeamLWC');
        analyzeFormFactor(this);
        analyzeUserAgent(this);
        this.loadQueueCases();
        // loadQuickActionPopupStyle(this, 35);
        disablePullToRefresh(this);

        const now = new Date();
        now.setHours(0, 0, 0, 0); // Remove time
        this.today = now.toISOString().split('T')[0];
    }

    renderedCallback() {
        analyzeFormFactor(this);
    }



    get showSaveButton() {
        return this.activeTab === 'Reassigned Cases' || this.activeTab === 'Non-Reassigned Cases';
    }


    handleCaseClick(event) {
        const caseId = event.target.dataset.id;
        if (caseId) {
            if (this.isMobile) {
                navigateToRecord(this, caseId, 'Case');
            } else {
                navigateToRecordInNewTab(this, caseId, 'Case');
            }
        }
    }


    @track processedCases = [];
    @track modifyAdditionalResourceCases = [];


    loadQueueCases() {
        getOpenQueueCases({ Queue: this.Queue })
            .then(cases => {
                console.log('cases', cases);

                const reassignedCases = [];
                const nonReassignedCases = [];
                const additionalResourceCases = [];

                this.casesToDisplay = cases.map(caseRecord => {
                    const existingRecord = this.casesToDisplay.find(c => c.Id === caseRecord.Id);
                    const mappedCase = {
                        Id: caseRecord.Id,
                        CaseNumber: caseRecord.CaseNumber,
                        Subject: caseRecord.Subject,
                        Description: caseRecord.Description,
                        ownerName: caseRecord.Owner?.Name,
                        pincode: caseRecord.Case_Pincode__r?.Name,
                        clientName: caseRecord.Account?.Name || 'N/A',
                        serialNumber: caseRecord.Asset?.Name,
                        TerritoryId: caseRecord.Account?.Pin_Code__c,
                        Division: caseRecord.Division__c,
                        selectedUserId: existingRecord ? existingRecord.selectedUserId : null,
                        isButtonVisible: true,
                        acceptedDate: caseRecord.Additional_Resource_Req_Proposed_Date__c,
                        comment: caseRecord.Reassignment_Request__c
                            ? caseRecord.Reassignment_Request_Comment__c
                            : caseRecord.Additional_Resource_Request__c
                                ? caseRecord.Additional_Resource_Request_Comment__c
                                : ''
                    };

                    if (caseRecord.Reassignment_Request__c === 'Requested' || caseRecord.Additional_Resource_Request__c === 'Requested') {
                        if (caseRecord.Reassignment_Request__c === 'Requested') {
                            reassignedCases.push(mappedCase);
                        }
                        if (caseRecord.Additional_Resource_Request__c === 'Requested') {
                            additionalResourceCases.push(mappedCase);
                        }
                    }
                    else {
                        nonReassignedCases.push(mappedCase);
                    }

                    return mappedCase;

                });
                this.modifyAdditionalResourceCases = additionalResourceCases.map((caseRecord) => {
                    return {
                        ...caseRecord,
                        get isAdditionalResourceCommentVisible() {
                            return this.caseTeamRecords.some(ct => ct.Member__c) || this.isAdditionalResourceStatusRejected;
                        },
                        get isAdditionalResourceStatusAccepted() {
                            return this.additionalResourceStatus === 'Approved';
                        },
                        get isAdditionalResourceStatusRejected() {
                            return this.additionalResourceStatus === 'Rejected';
                        },
                        caseTeamRecords: [
                            {
                                id: this.generateUniqueId(),
                                Member__c: null,
                                Case_Team_Role__c: null,
                                Access_Level__c: null,
                                //acceptedDate:null
                            },
                        ],
                    };
                });
                console.log('modifyAdditionalResourceCases', this.modifyAdditionalResourceCases);

                this.reassignedCases = reassignedCases;
                this.nonReassignedCases = nonReassignedCases;
                this.additionalResourceCases = this.modifyAdditionalResourceCases;

                this.allReassignedCases = reassignedCases;
                this.allNonReassignedCases = nonReassignedCases;
                this.allAdditionalResourceCases = this.modifyAdditionalResourceCases;


                const territoryIdsSet = new Set();
                const reassignedTerritoryIdsSet = new Set();
                const nonReassignedTerritoryIdsSet = new Set();
                this.casesToDisplay.forEach(c => {
                    if (c.TerritoryId) {
                        territoryIdsSet.add(c.TerritoryId);
                    }
                });
                this.reassignedCases.forEach(c => {
                    if (c.TerritoryId) {
                        reassignedTerritoryIdsSet.add(c.TerritoryId);
                    }
                });

                this.nonReassignedCases.forEach(c => {
                    if (c.TerritoryId) {
                        nonReassignedTerritoryIdsSet.add(c.TerritoryId);
                    }
                });
                const territoryIds = [...territoryIdsSet];
                const reassignedTerritoryIds = [...reassignedTerritoryIdsSet];
                const nonReassignedTerritoryIds = [...nonReassignedTerritoryIdsSet];


                let caseIds = [...this.reassignedCases.map(caseObj => caseObj.Id),
                ...this.nonReassignedCases.map(caseObj => caseObj.Id)];

                getUsersByTerritoryFromCases()
                    .then(result => {
                        this.userOptions = result.map(user => ({ label: user.Name, value: user.Id }));
                        const caseWiseUserMap = this.reassignedCases.map(caseItem => ({
                            CaseId: caseItem.Id, Users: result.map(user => ({ Id: user.Id, Name: user.Name }))
                        }));
                        this.mergeCaseUsers(this.reassignedCases, this.nonReassignedCases, caseWiseUserMap);
                    })
                    .catch(error => {
                        console.error('Error fetching pin codes:', error);
                    });
            })
            .catch(error => {
                console.error('Error fetching cases from queue: ', error);
            });
    }


    mergeCaseUsers(reassignedCases, nonReassignedCases, userCaseData) {
        let updatedReassignedCases = reassignedCases.map(caseItem => {
            let matchingCase = userCaseData.find(userCase => userCase.CaseId === caseItem.Id);
            if (matchingCase) {
                return { ...caseItem, Users: matchingCase.Users };
            }
            return caseItem;
        });

        let updatedNonReassignedCases = nonReassignedCases.map(caseItem => {
            let matchingCase = userCaseData.find(userCase => userCase.CaseId === caseItem.Id);
            if (matchingCase) {
                return { ...caseItem, Users: matchingCase.Users };
            }
            return caseItem;
        });

        updatedReassignedCases.forEach(caseRecord => {
            caseRecord.userOptions = caseRecord.Users
                ? caseRecord.Users.map(user => ({
                    label: user.Name,
                    value: user.Id
                }))
                : [];
        });

        updatedNonReassignedCases.forEach(caseRecord => {
            caseRecord.userOptions = caseRecord.Users
                ? caseRecord.Users.map(user => ({
                    label: user.Name,
                    value: user.Id
                }))
                : [];
        });

        console.log('Updated Reassigned Cases:', updatedReassignedCases);
        console.log('Updated Non-Reassigned Cases:', updatedNonReassignedCases);

        this.reassignedCases = [...updatedReassignedCases];
        this.nonReassignedCases = [...updatedNonReassignedCases];
    }



    handlePreviousPageReassigned() {
        if (this.currentPageReassigned > 1) {
            this.currentPageReassigned--;
        }
    }

    handleNextPageReassigned() {
        if (this.currentPageReassigned < this.totalPagesReassigned) {
            this.currentPageReassigned++;
        }
    }

    handlePreviousPageNonReassigned() {
        if (this.currentPageNonReassigned > 1) {
            this.currentPageNonReassigned--;
        }
    }

    handleNextPageNonReassigned() {
        if (this.currentPageNonReassigned < this.totalPagesNonReassigned) {
            this.currentPageNonReassigned++;
        }
    }

    handlePreviousPageAdditionalResource() {
        if (this.currentPageAdditionalResource > 1) {
            this.currentPageAdditionalResource--;
        }
    }

    handleNextPageAdditionalResource() {
        if (this.currentPageAdditionalResource < this.totalPagesAdditionalResource) {
            this.currentPageAdditionalResource++;
        }
    }

    get paginatedReassignedCases() {
        console.log('paginatedReassignedCases', this.currentPageReassigned, this.itemsPerPageReassigned, this.reassignedCases);
        const start = (this.currentPageReassigned - 1) * this.itemsPerPageReassigned;
        const end = start + this.itemsPerPageReassigned;
        console.log('paginatedReassignedCases', this.currentPageReassigned, this.itemsPerPageReassigned, start, end, this.reassignedCases);
        return this.reassignedCases.slice(start, end);
    }

    get paginatedNonReassignedCases() {
        const start = (this.currentPageNonReassigned - 1) * this.itemsPerPageNonReassigned;
        const end = start + this.itemsPerPageNonReassigned;
        return this.nonReassignedCases.slice(start, end);
    }

    get paginatedAdditionalResourceCases() {
        const start = (this.currentPageAdditionalResource - 1) * this.itemsPerPageAdditionalResource;
        const end = start + this.itemsPerPageAdditionalResource;
        return this.additionalResourceCases.slice(start, end);
    }

    get isFirstPageReassigned() {
        return this.currentPageReassigned === 1;
    }

    get isLastPageReassigned() {
        return this.currentPageReassigned === this.totalPagesReassigned;
    }

    get isFirstPageNonReassigned() {
        return this.currentPageNonReassigned === 1;
    }

    get isLastPageNonReassigned() {
        return this.currentPageNonReassigned === this.totalPagesNonReassigned;
    }

    get isFirstPageAdditionalResource() {
        return this.currentPageAdditionalResource === 1;
    }

    get isLastPageAdditionalResource() {
        return this.currentPageAdditionalResource === this.totalPagesAdditionalResource;
    }



    handleTabChange(event) {
        console.log(event.target.label);
        if (event.target.label == 'Reassign Request') {
            this.activeTab = 'Reassigned';
        } else if (event.target.label == 'Assign Cases') {
            this.activeTab = 'Non-Reassigned';
        } else {
            this.activeTab = 'AdditionalRes';
        }
        if (this.activeTab === 'Reassigned') {
            this.currentPageReassigned = 1;
            this.currentPageNonReassigned = 0;
            this.currentPageAdditionalResource = 0;
        } else if (this.activeTab == 'Non-Reassigned') {
            this.currentPageNonReassigned = 1;
            this.currentPageReassigned = 0;
            this.currentPageAdditionalResource = 0;
        } else {
            this.currentPageNonReassigned = 0;
            this.currentPageReassigned = 0;
            this.currentPageAdditionalResource = 1;
        }
    }

    closeModal() {
        this.isModalOpen = false;
        this.modalData = {};
    }


    handleUserSelection(event) {
        // Get the selected User ID from the combobox
        const selectedUserId = event.detail.value;

        // Get the Case ID from the dataset attribute
        const caseId = event.target.dataset.id;

        console.log('Selected User ID:', selectedUserId);
        console.log('Case ID:', caseId);

        event.target.setCustomValidity('');
        event.target.reportValidity();

        // Find the case in the paginatedReassignedCases array and update selectedUserId
        this.reassignedCases = this.reassignedCases.map(caseRecord => {
            if (caseRecord.Id === caseId) {
                return { ...caseRecord, selectedUserId };
            }
            return caseRecord;
        });

        console.log('Updated Case Records:', this.reassignedCases);
        this.nonReassignedCases = this.nonReassignedCases.map(caseRecord => {
            if (caseRecord.Id === caseId) {
                return { ...caseRecord, selectedUserId };
            }
            return caseRecord;
        });
    }





    handleSave() {
        const caseIdToOwnerMap = {};
        console.log('nonRes', this.nonReassignedCases);
        console.log(this.activeTab);
        const activeCases = this.currentPageReassigned ? this.reassignedCases : this.nonReassignedCases;
        console.log('activeCases:', activeCases);
        activeCases.forEach(caseRecord => {
            const comboboxElement = this.template.querySelector(`lightning-combobox[data-id="${caseRecord.Id}"]`);
            if (comboboxElement) {
                const selectedUserId = comboboxElement.value;
                if (selectedUserId) {
                    caseIdToOwnerMap[caseRecord.Id] = selectedUserId;
                }
            }
        });

        if (Object.keys(caseIdToOwnerMap).length === 0) {
            this.showToast('Error', 'Please select owner for at least one case.', 'error');
            return;
        }

        this.showSpinner = true;
        saveCaseWithNewOwner({ caseIdToOwnerMap })
            .then(() => {
                this.showToast('Success', 'Cases updated successfully.', 'success');
                // remove updated cases from the list
                this.allNonReassignedCases = this.allNonReassignedCases.filter(caseItem => !caseIdToOwnerMap[caseItem.Id]);
                this.nonReassignedCases = this.nonReassignedCases.filter(caseItem => !caseIdToOwnerMap[caseItem.Id]);
            })
            .catch(error => {
                console.log('Error saving cases:', error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleReject(event) {
        const caseId = event.target.dataset.id;
        updateCaseAndSendCaseOwnerNotification({ caseId })
            .then(() => {
                this.showToast('Success', 'Notification sent to case owner!', 'success');
                this.dispatchEvent(new CustomEvent('refresh'));
            })
            .catch(error => {
                console.error('Error sending notification:', error);
                this.showToast('Error', 'Failed to send notification', 'error');
            });
        location.reload();
    }


    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        console.log('recordId', this._recordId);
    }


    handleChange(event) {
        const { name, value, dataset: { id, case: caseId } } = event.target;
        const { recordId } = event.detail;

        const caseRecord = this.paginatedAdditionalResourceCases.find(record => record.Id === caseId);
        if (!caseRecord) return;

        const caseTeamRecord = caseRecord.caseTeamRecords.find(record => record.id === id);
        if (!caseTeamRecord) return;

        caseTeamRecord[name] = value;

        if (name === 'Case_Team_Role__c') {
            const selectedRole = this.caseTeamRolesOptions.find(option => option.value === value);
            if (selectedRole) {
                caseTeamRecord.Access_Level__c = selectedRole.accessLevel;
            }
        } else if (name === 'Member__c') {
            caseTeamRecord.Member__c = value;
        }
    }


    handleCommentChangeAdditionResource(event) {
        const caseId = event.target.dataset.id;
        event.target.setCustomValidity('');
        event.target.reportValidity();

        const updateComment = (caseRecord) => {
            if (caseRecord) {
                caseRecord.Additional_Resource_Request_RSM_Comment__c = event.target.value;
            }
        };
        updateComment(this.additionalResourceCases.find(record => record.Id === caseId));
        // updateComment(this.paginatedAdditionalResourceCases.find(record => record.Id === caseId));
    }


    handleAcceptedDate(event) {
        const { name, value, dataset: { id, case: caseId } } = event.target;
        const { recordId } = event.detail;

        const selectedDate = new Date(value);
        const today = new Date();
        today.setHours(0, 0, 0, 0); // Set time to midnight for accurate comparison

        const targetRecord = this.additionalResourceCases.find(record => record.Id === caseId);

        if (selectedDate < today) {
            // Set custom error message and optionally clear the comment
            event.target.setCustomValidity('Selected date cannot be earlier than today.');
            event.target.reportValidity();

            if (targetRecord) {
                targetRecord.acceptedDate = null;
            }
        } else {
            // Clear previous error and update the comment
            event.target.setCustomValidity('');
            event.target.reportValidity();

            if (targetRecord) {
                targetRecord.acceptedDate = value;
            }
        }
    }






    get memberFilter() {
        const criteria = [{ fieldPath: 'IsActive', operator: 'eq', value: true }];
        const existingRecords = this.caseTeamRecord?.existingCaseTeamRecords;

        if (existingRecords?.length > 0) {
            criteria.push({
                fieldPath: 'Id',
                operator: 'nin',
                value: existingRecords.map(row => row.fields.Member__c.value)
            });
        }

        return { criteria };
    }

    get memberDisplayInfo() {
        return {
            primaryField: 'Name',
            additionalFields: ['Email']
        };
    }

    get memberMatchingInfo() {
        return {
            primaryField: { fieldPath: 'Name' },
            additionalFields: [{ fieldPath: 'Email' }]
        };
    }




    @wire(MessageContext)
    messageContext;


    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Case_Teams__r',
        fields: ['Case_Team__c.Member__c']
    })
    wiredCaseTeamRecords({ error, data }) {
        if (data) {
            this.caseTeamRecord.existingCaseTeamRecords = data.records;
        } else if (error) {
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }

    @track caseTeamRolesOptions = [];
    @wire(getCaseTeamRoles)
    wiredCaseTeamRoles({ error, data }) {
        if (data) {
            console.log('wiredCaseTeamRoles-->', data);
            this.caseTeamRolesOptions = data.map(row => ({ label: row.Name, value: row.Id, accessLevel: row.AccessLevel }));
            console.log('caseTeamRolesOptions', this.caseTeamRolesOptions);
            // this.caseTeamRecord.caseTeamRolesOptions = data.map(row => ({ label: row.Name, value: row.Id, accessLevel: row.AccessLevel }));
        } else if (error) {
            console.log('wiredCaseTeamRoles error', error, JSON.stringify(error));
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }

    @track caseTeamAccessLevelOptions = [];
    @wire(getObjectInfo, { objectApiName: CASE_TEAM_OBJECT })
    wiredCaseTeamObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$wiredCaseTeamObjectInfo.data.defaultRecordTypeId', fieldApiName: CASE_TEAM_ACCESS_LEVEL })
    wiredCaseTeamAccessLevelOptions({ data, error }) {
        if (data) {
            console.log('Picklist values:', data.values);

            if (!this.caseTeamRecord) {
                this.caseTeamRecord = {};
            }

            this.caseTeamRecord.caseTeamAccessLevelOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
            this.caseTeamAccessLevelOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
            console.log('caseTeamAccessLevelOptions', this.caseTeamAccessLevelOptions);

            console.log('Updated caseTeamRecord:', this.caseTeamRecord);
        } else if (error) {
            console.error('Error fetching picklist values:', error);
            showToast(this, 'Error', 'Something went wrong', 'error');
        }
    }


    @track caseTeamRecords = [
        {
            id: this.generateUniqueId(),
            Member__c: null,
            Case_Team_Role__c: null,
            Access_Level__c: null,
        },
    ];

    generateUniqueId() {
        return Math.random().toString(36).substring(2, 15);
    }


    handleAddFields(event) {
        const caseId = event.target.dataset.id; // Get the case ID
        const caseRecord = this.paginatedAdditionalResourceCases.find((record) => record.Id === caseId);

        if (caseRecord) {
            caseRecord.caseTeamRecords.push({
                id: this.generateUniqueId(),
                Member__c: null,
                Case_Team_Role__c: null,
                Access_Level__c: null,
                acceptedDate: null,

            });
        }

        console.log('Added new caseTeamRecord for case:', caseId);
    }


    handleRemoveFields(event) {
        const idToRemove = event.target.dataset.id;
        const caseId = event.target.dataset.case;
        const caseRecord = this.paginatedAdditionalResourceCases.find((record) => record.Id === caseId);

        if (caseRecord) {
            if (caseRecord.caseTeamRecords.length > 1) {
                caseRecord.caseTeamRecords = caseRecord.caseTeamRecords.filter((record) => record.id !== idToRemove);
            }
            else {
                console.error('At least one case team record must be present.');
                this.showToast('Error', 'At least one case team record must be present.', 'error');
            }
        }
    }




    handleSave2(event) {
        const caseId = event.target.dataset.id;
        const caseRecord = this.paginatedAdditionalResourceCases.find((record) => record.Id === caseId);

        if (caseRecord) {
            let recordsToSave;
            if (caseRecord.isAdditionalResourceStatusAccepted) {
                recordsToSave = caseRecord.caseTeamRecords
                    .filter((record) => record.Member__c)
                    .map((record) => {
                        return {
                            caseId: caseId,
                            memberId: record.Member__c,
                            accessLevel: 'Edit',
                            // acceptedDate: record.acceptedDate
                        };
                    });
            }
            else if (caseRecord.isAdditionalResourceStatusRejected) {
                if (!caseRecord.Additional_Resource_Request_RSM_Comment__c) {
                    const element = this.template.querySelector('.additional-resource-request-comment[data-id="' + caseId + '"]');
                    if (element) {
                        element.setCustomValidity('Please enter a comment.');
                        element.reportValidity();
                    } else {
                        showToast(this, 'Error', 'Please enter a comment.', 'error');
                    }
                    return;
                }
            }

            if (caseRecord.isAdditionalResourceStatusAccepted) {
                if (!caseRecord.acceptedDate) {
                    const element = this.template.querySelector('.accepted-date[data-id="' + caseId + '"]');
                    if (element) {
                        element.setCustomValidity('Please enter valid Date.');
                        element.reportValidity();
                    } else {
                        showToast(this, 'Error', 'Please enter valid Date.', 'error');
                    }
                    return;
                }
            }

            if (caseRecord.isAdditionalResourceStatusRejected || recordsToSave.length > 0) {
                this.showSpinner = true;
                console.log('recordsToSave-->', JSON.stringify(caseRecord));

                saveCaseTeamRecords({ records: recordsToSave, caseId: caseId, status: caseRecord.additionalResourceStatus, comment: caseRecord.Additional_Resource_Request_RSM_Comment__c, acceptedDate: caseRecord.acceptedDate })
                    .then(() => {
                        this.showToast('Success', 'Records saved successfully!', 'success');
                        this.allAdditionalResourceCases = this.allAdditionalResourceCases.filter((record) => record.Id !== caseId);
                        this.additionalResourceCases = this.additionalResourceCases.filter((record) => record.Id !== caseId);
                    })
                    .catch((error) => {
                        this.showToast('Error', 'Error saving records: ' + error.body.message, 'error');
                    })
                    .finally(() => {
                        this.showSpinner = false;
                    });
            } else {
                this.showToast('Error', 'No records to save for this case.', 'error');
            }
        }
    }

    validateRecords() {
        return this.caseTeamRecords.every(record =>
            record.Member__c && record.Case_Team_Role__c && record.Access_Level__c
        );
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
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





    handleReassignAction(event) {
        const { id, action } = event.target.dataset;
        const updateCaseRecord = (caseRecord) => {
            if (caseRecord) {
                caseRecord.reassignStatus = action === 'accept' ? 'Approved' : 'Rejected';
                caseRecord.isReassignRequestApproved = caseRecord.reassignStatus === 'Approved';
                caseRecord.isReAssignRequestRejected = caseRecord.reassignStatus === 'Rejected';
                caseRecord.isButtonVisible = false;
            }
        };
        updateCaseRecord(this.reassignedCases.find(record => record.Id === id));
        // updateCaseRecord(this.paginatedReassignedCases.find(record => record.Id === id));
    }

    handleAdditionalResourceAction(event) {
        const { id, action } = event.target.dataset;
        const updateCaseRecord = (caseRecord) => {
            if (caseRecord) {
                caseRecord.additionalResourceStatus = action === 'accept' ? 'Approved' : 'Rejected';
                caseRecord.isButtonVisible = false;
            }
        };
        updateCaseRecord(this.additionalResourceCases.find(record => record.Id === id));
        // updateCaseRecord(this.paginatedAdditionalResourceCases.find(record => record.Id === id));
    }

    handleReassignSave(event) {
        const { id } = event.currentTarget.dataset;
        const caseRecord = this.reassignedCases.find(record => record.Id === id);
        if (caseRecord) {
            if (!caseRecord.newOwnerId && caseRecord.isReassignRequestApproved) {
                const comboboxElement = this.template.querySelector(`lightning-combobox[data-id="${id}"]`);
                if (comboboxElement) {
                    comboboxElement.setCustomValidity('Please select an owner.');
                    comboboxElement.reportValidity();
                } else {
                    showToast('Error', 'Please select an owner.', 'error');
                }
                return;
            }
            else if (!caseRecord.Reassignment_Request_RSM_Comment__c && caseRecord.isReAssignRequestRejected) {
                const textAreaElement = this.template.querySelector(`lightning-textarea[data-id="${id}"]`);
                if (textAreaElement) {
                    textAreaElement.setCustomValidity('Please enter a comment.');
                    textAreaElement.reportValidity();
                } else {
                    showToast('Error', 'Please enter a comment.', 'error');
                }
                return;
            }

            this.showSpinner = true;
            handleReAssignRequest({
                caseId: id,
                status: caseRecord.reassignStatus,
                comment: caseRecord.Reassignment_Request_RSM_Comment__c,
                newOwnerId: caseRecord.newOwnerId
            })
                .then(() => {
                    if (caseRecord.isReassignRequestApproved) {
                        showToast(this, 'Success', 'Case ' + caseRecord.CaseNumber + ' is reassigned successfully to ' + this.userOptions.find(user => user.value === caseRecord.newOwnerId).label, 'success');
                    } else if (caseRecord.isReAssignRequestRejected) {
                        showToast(this, 'Success', 'Reassignment request for case ' + caseRecord.CaseNumber + ' is rejected successfully', 'success');
                    }
                    this.allReassignedCases = this.allReassignedCases.filter(record => record.Id !== id);
                    this.reassignedCases = this.reassignedCases.filter(record => record.Id !== id);
                })
                .catch((error) => {
                    showToast(this, 'Error', 'Error saving reassignment request', 'error', error);
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }
    }

    handleReassignCancel(event) {
        const { id } = event.currentTarget.dataset;
        const caseRecord = this.reassignedCases.find(record => record.Id === id);
        if (caseRecord) {
            delete caseRecord.reassignStatus;
            delete caseRecord.Reassignment_Request_RSM_Comment__c;
            caseRecord.isButtonVisible = true;
        }
    }

    handleAdditionalResourceCancel(event) {
        const { id } = event.currentTarget.dataset;
        const caseRecord = this.additionalResourceCases.find(record => record.Id === id);
        if (caseRecord) {
            delete caseRecord.additionalResourceStatus;
            delete caseRecord.Additional_Resource_Request_RSM_Comment__c;
            caseRecord.caseTeamRecords = [{}];
            caseRecord.isButtonVisible = true;
        }
    }

    handleReassignUserSelect(event) {
        const { id } = event.currentTarget.dataset;
        const { value } = event.target;
        event.target.setCustomValidity('');
        event.target.reportValidity();

        const caseRecord = this.reassignedCases.find(record => record.Id === id);
        if (caseRecord) {
            caseRecord.newOwnerId = value;
        }
    }

    handleCommentChange(event) {
        const caseId = event.target.dataset.id;
        event.target.setCustomValidity('');
        event.target.reportValidity();

        const updateComment = (caseRecord) => {
            if (caseRecord) {
                caseRecord.Reassignment_Request_RSM_Comment__c = event.target.value;
            }
        };
        updateComment(this.reassignedCases.find(record => record.Id === caseId));
        // updateComment(this.paginatedReassignedCases.find(record => record.Id === caseId));
    }






    handleCommentChangeAdditionResource(event) {
        const caseId = event.target.dataset.id;
        event.target.setCustomValidity('');
        event.target.reportValidity();

        const updateComment = (caseRecord) => {
            if (caseRecord) {
                caseRecord.Additional_Resource_Request_RSM_Comment__c = event.target.value;
            }
        };
        updateComment(this.additionalResourceCases.find(record => record.Id === caseId));
        // updateComment(this.paginatedAdditionalResourceCases.find(record => record.Id === caseId));
    }














    @track searchTimeout;
    @track isSearching;
    handleSearch(event) {
        const value = event.target.value;
        const { type } = event.currentTarget.dataset;
        clearTimeout(this.searchTimeout);

        this.isSearching = true;

        this.searchTimeout = setTimeout(() => {
            if (type === 'reassignedCases') {
                this.reassignedCases = this.allReassignedCases.filter(caseItem =>
                    caseItem.CaseNumber?.toLowerCase().includes(value)
                ) || this.allReassignedCases;
                this.currentPageReassigned = 1;
            }
            else if (type === 'nonReassignedCases') {
                this.nonReassignedCases = this.allNonReassignedCases.filter(caseItem =>
                    caseItem.CaseNumber?.toLowerCase().includes(value)
                ) || this.allNonReassignedCases;
                this.currentPageNonReassigned = 1;
            }
            else if (type === 'additionalResourceCases') {
                this.additionalResourceCases = this.allAdditionalResourceCases.filter(caseItem =>
                    caseItem.CaseNumber?.toLowerCase().includes(value)
                ) || this.allAdditionalResourceCases;
                this.currentPageAdditionalResource = 1;
            }
            this.isSearching = false;
        }, 500);
    }





}