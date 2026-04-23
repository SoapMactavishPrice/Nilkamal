import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { disablePullToRefresh, showToast, navigateToRecord, scrollToTop, analyzeFormFactor } from 'c/utilJS';


import getCasesForQueue from '@salesforce/apex/FieldServiceOpenQueue2.getCasesForQueue';

import reassignCase from '@salesforce/apex/FieldServiceOpenQueue2.reassignCase';
import updateCaseResource from '@salesforce/apex/FieldServiceOpenQueue2.updateCaseResource';



export default class FieldServiceQueue extends NavigationMixin(LightningElement) {

    @track showSpinner = false;
    @track allCases = [];
    @track casesToDisplay = [];
    @track currentPage = 1;
    @track pageSize = 10;
    @track isModalOpen = false;
    @track modalData = {};
    @track isFirstPage = true;
    @track isLastPage = false;
    queueName = 'Open Queue';
    @track minDate = new Date().toISOString().split('T')[0];
    // @track maxDate = new Date(new Date().setFullYear(new Date().getFullYear() + 1)).toISOString().split('T')[0];



    @track isMobile;
    @track isTablet;
    @track isDesktop;

    @track additionalResourceCommentOptions = [
        { label: 'Critical PM, Installation OR Maintenance to be carried out', value: 'Critical PM, Installation OR Maintenance to be carried out' },
        { label: 'On field Technical Support require', value: 'On field Technical Support require' }
    ];

    commentOptions = [
        { label: 'Leave', value: 'Leave' },
        { label: 'Busy with pre-committed customers', value: 'Busy with pre-committed customers' },
        { label: 'Not compatible with this product', value: 'Not compatible with this product' },
        { label: 'Not belongs to my territory', value: 'Not belongs to my territory' }
    ];

    connectedCallback() {
        disablePullToRefresh(this);
        this.fetchCases();
        analyzeFormFactor(this);
    }

    fetchCases() {
        getCasesForQueue()
            .then(data => {
                this.allCases = data.map(caseItem => {
                    return {
                        ...caseItem,
                        get isAdditionalResourceRequestAlreadySubmitted() {
                            // return !this.Additional_Resource_Request__c || this.Additional_Resource_Request__c === 'Requested';
                            return this.Additional_Resource_Request__c === 'Requested';
                        },
                        get isPreviousAdditionalResourceRequestAvailable() {
                            return this.Additional_Resource_Request__c;
                        },
                        get isReAssignmentRequestAlreadySubmitted() {
                            // return !this.Reassignment_Request__c || this.Reassignment_Request__c === 'Requested';
                            return this.Reassignment_Request__c === 'Requested';
                        },
                        get isPreviousReAssignmentRequestAvailable() {
                            return this.Reassignment_Request__c;
                        }
                    };
                });

                this.casesToDisplay = this.allCases;
                console.log('casesToDisplay:', this.casesToDisplay);
                this.updatePaginationStatus();
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load cases', 'error');
                console.error('Error fetching cases:', error);
            });
    }

    get paginatedCases() {
        if (!this.casesToDisplay) return [];

        const startIdx = (this.currentPage - 1) * this.pageSize;
        const endIdx = this.currentPage * this.pageSize;
        this.isFirstPage = this.currentPage === 1;
        this.isLastPage = this.currentPage === this.totalPages;

        return this.casesToDisplay.slice(startIdx, endIdx);
    }


    @track searchTimeout;
    @track isSearching = false;
    handleSearch(event) {
        const searchTerm = event.target.value;
        clearTimeout(this.searchTimeout);
        this.isSearching = true;

        this.searchTimeout = setTimeout(() => {
            this.casesToDisplay = this.allCases.filter(caseItem =>
                caseItem.CaseNumber?.toLowerCase().includes(searchTerm)
            ) || this.allCases;

            this.updatePaginationStatus();
            this.isSearching = false;
        }, 500);
    }

    handleCaseClick(event) {
        const caseId = event.target.dataset.id;

        navigateToRecord(this, caseId);

        /*
        const caseRecord = this.casesToDisplay.find(caseItem => caseItem.Id === caseId);

        if (caseRecord) {
            this.modalData = {
                ...caseRecord,
                clientName: caseRecord.Account?.Name || '',
                clientEmail: caseRecord.Contact?.Email || '',
                clientPhone: caseRecord.Contact?.Phone || '',
                openDate: caseRecord.CreatedDate ? new Date(caseRecord.CreatedDate).toLocaleDateString('en-GB') : '',
                casePriority: caseRecord.Priority || '',
                caseType: caseRecord.Type || '',
                caseDivision: caseRecord.Division__c || ''
            };
            this.isModalOpen = true;
        }
        */
    }

    closeModal() {
        this.isModalOpen = false;
        this.modalData = {};
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginationStatus();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginationStatus();
        }
    }

    refreshCases() {
        this.fetchCases();
        this.currentPage = 1;
    }

    updatePaginationStatus() {
        const totalCases = this.casesToDisplay.length;
        this.totalPages = Math.ceil(totalCases / this.pageSize);
        this.isFirstPage = this.currentPage === 1;
        this.isLastPage = this.currentPage === this.totalPages;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }







    handleRequestAdditionalResource(event) {
        const id = event.currentTarget.dataset.id;
        const caseItem = this.casesToDisplay.find(c => c.Id === id);
        if (caseItem) {
            if (caseItem.isReAssignmentRequestAlreadySubmitted) {
                showToast(this, 'Error', 'Case already has re-assignment request pending, cannot raise additional resource request', 'error');
                return;
            }
            caseItem.isRequestAdditionalResourceEditCommentVisible = true;
            caseItem.isReAssignmentEditCommentVisible = false;
        }
    }

    handleAdditionalResourceRequestCommentChange(event) {
        const id = event.currentTarget.dataset.id;
        const comment = event.target.value;
        const caseItem = this.casesToDisplay.find(c => c.Id === id);
        if (caseItem) {
            caseItem.Additional_Resource_Request_Comment__c = comment;
            event.target.setCustomValidity('');
            event.target.reportValidity();
        }
    }

    handleProposedDateChange(event) {
        const id = event.currentTarget.dataset.id;
        const proposedDate = event.target.value;
        const caseItem = this.casesToDisplay.find(c => c.Id === id);

        // if (caseItem) {
        //     caseItem.proposedDate = proposedDate;

        //     event.target.setCustomValidity('');
        //     event.target.reportValidity();

        //     if (new Date(proposedDate) < new Date()) {
        //         event.target.setCustomValidity('Proposed date cannot be in the past');
        //         event.target.reportValidity();
        //         return;
        //     }
        // }
        if (caseItem) {
            caseItem.proposedDate = proposedDate;

            event.target.setCustomValidity('');
            event.target.reportValidity();

            const selectedDate = new Date(proposedDate);
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            selectedDate.setHours(0, 0, 0, 0);

            if (selectedDate < today) {
                event.target.setCustomValidity('Proposed date cannot be in the past');
                event.target.reportValidity();
                return;
            }
        }
    }

    handleAdditionalResourceRequestSubmit(event) {
        const id = event.currentTarget.dataset.id;
        const caseItem = this.casesToDisplay.find(c => c.Id === id);

        if (!caseItem.Additional_Resource_Request_Comment__c) {
            const element = this.template.querySelector('.additional-resource-request-comment[data-id="' + id + '"]');
            if (element) {
                element.setCustomValidity('This field is required');
                element.reportValidity();
            } else {
                showToast(this, 'Error', 'Comment is required to request additional resource.', 'error');
                console.log('Comment is required to request additional resource.');
            }
            return;
        }

        // if (!caseItem.proposedDate) {
        //     const dateElement = this.template.querySelector('lightning-input[data-id="' + id + '"][name="proposedDate"]');
        //     if (dateElement) {
        //         dateElement.setCustomValidity('Proposed date is required');
        //         dateElement.reportValidity();
        //     } else {
        //         showToast(this, 'Error', 'Proposed date is required', 'error');
        //     }
        //     return;
        // }

        const proposedDate = new Date(caseItem.proposedDate);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const dateElement = this.template.querySelector('.proposed-date[data-id="' + id + '"]');


        if (proposedDate) {
            if (proposedDate < today) {
                if (dateElement) {
                    dateElement.setCustomValidity('Proposed date cannot be in the past');
                    dateElement.reportValidity();
                }
                showToast(this, 'Error', 'Proposed date cannot be in the past', 'error');
                return;
            } else if (dateElement) {
                dateElement.setCustomValidity('');
                dateElement.reportValidity();
            }
        }


        this.showSpinner = true;
        updateCaseResource({
            caseId: caseItem.Id, comment: caseItem.Additional_Resource_Request_Comment__c, proposedDate: caseItem.proposedDate
        })
            .then(() => {
                showToast(this, 'Success', 'Additional resource request submitted successfully', 'success');
                caseItem.isRequestAdditionalResourceEditCommentVisible = false;
                caseItem.Additional_Resource_Request__c = 'Requested';
                caseItem.Proposed_Resource_Date__c = caseItem.proposedDate
            })
            .catch(error => {
                showToast(this, 'Error', 'Failed to submit additional resource request', 'error', error);
                console.log('Error submitting additional resource request:', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }



    handleCloseModal(event) {
        const id = event.currentTarget.dataset.id;
        const action = event.currentTarget.dataset.action;

        const caseItem = this.casesToDisplay.find(c => c.Id === id);
        if (caseItem) {
            if (action === 'additionalResource') {
                caseItem.isRequestAdditionalResourceEditCommentVisible = false;
                caseItem.Additional_Resource_Request_Comment__c = '';
            }
            if (action === 'reassign') {
                caseItem.isReAssignmentEditCommentVisible = false;
                caseItem.Reassignment_Request_Comment__c = '';
            }
        }
    }



    handleRequestReassign(event) {
        const id = event.currentTarget.dataset.id;
        const caseItem = this.casesToDisplay.find(c => c.Id === id);
        if (caseItem) {
            if (caseItem.isAdditionalResourceRequestAlreadySubmitted) {
                showToast(this, 'Error', 'Case already has additional resource request pending, cannot raise re-assignment request', 'error');
                return;
            }
            caseItem.isReAssignmentEditCommentVisible = true;
            caseItem.isRequestAdditionalResourceEditCommentVisible = false;
        }
    }

    handleRequestReAssignmentCommentChange(event) {
        const id = event.currentTarget.dataset.id;
        const comment = event.target.value;
        const caseItem = this.casesToDisplay.find(c => c.Id === id);
        if (caseItem) {
            caseItem.Reassignment_Request_Comment__c = comment;
            event.target.setCustomValidity('');
            event.target.reportValidity();
        }
    }

    handleRequestReAssignmentSubmit(event) {
        const id = event.currentTarget.dataset.id;
        const caseItem = this.casesToDisplay.find(c => c.Id === id);

        if (!caseItem.Reassignment_Request_Comment__c) {
            const element = this.template.querySelector('.request-re-assignment-comment[data-id="' + id + '"]');
            if (element) {
                element.setCustomValidity('This field is required');
                element.reportValidity();
            } else {
                showToast(this, 'Error', 'Comment is required to request re-assignment.', 'error');
                console.log('Comment is required to request re-assignment.');
            }
            return;
        }

        this.showSpinner = true;
        reassignCase({ caseId: caseItem.Id, comment: caseItem.Reassignment_Request_Comment__c })
            .then(() => {
                showToast(this, 'Success', 'Re-assignment request submitted successfully', 'success');
                caseItem.isReAssignmentEditCommentVisible = false;
                caseItem.Reassignment_Request__c = 'Requested';
            })
            .catch(error => {
                showToast(this, 'Error', 'Failed to submit re-assignment request', 'error', error);
                console.log('Error submitting re-assignment request:', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

















    updateCaseResourceInDB(caseRecord) {
        updateCaseResource({ caseId: caseRecord.Id })
            .then(result => {
                console.log('Resource request updated:', result);
                const paginatedCaseRecord = this.paginatedCases.find(c => c.Id === caseRecord.Id);
                if (paginatedCaseRecord) {
                    paginatedCaseRecord.Additional_Resource_Request__c = true;
                }
                const globalCaseRecord = this.casesToDisplay.find(c => c.Id === caseRecord.Id);
                if (globalCaseRecord) {
                    globalCaseRecord.Additional_Resource_Request__c = true;
                }
            })
            .catch(error => {
                console.error('Error updating resource request:', error);
            });
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