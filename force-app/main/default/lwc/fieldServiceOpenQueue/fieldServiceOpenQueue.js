import { LightningElement, wire, track, api } from 'lwc';
import getCasesForCurrentUser from '@salesforce/apex/FieldServiceOpenQueue.getCasesForCurrentUser';
import sendRejectionNotification from '@salesforce/apex/FieldServiceOpenQueue.sendRejectionNotification';
import acceptCase from '@salesforce/apex/FieldServiceOpenQueue.acceptCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCasesForQueue from '@salesforce/apex/FieldServiceOpenQueue.getCasesForQueue';
import { disablePullToRefresh } from 'c/utilJS';



export default class FieldServiceOpenQueue extends LightningElement {
    @track cases = [];
    @track casesToDisplay = [];
    @track isModalOpen = false; // Controls modal visibility
    @track modalData = {}; // Stores data for the selected case
    @track currentPage = 1;
    @track pageSize = 2; // Number of records per page
    queueName = 'Open Queue';
    isFirstPage = true; // For pagination
    isLastPage = false; // For pagination
    @api recordId;

    connectedCallback() {
        this.getCasesForCurrentUserJs();
        this.loadQueueCases();
        disablePullToRefresh(this);
    }

    get totalPages() {
        return Math.ceil(this.cases.length / this.pageSize);
    }

    get isFirstPage() {
        return this.currentPage === 1 && this.totalPages <= 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages || this.totalPages <= 1;
    }
    getCasesForCurrentUserJs() {
        getCasesForCurrentUser({ recordId: this.recordId })
            .then((res) => {

                this.cases = res;
                //this.updateCasesToDisplay();
            });


    }

    // @wire(getCasesForCurrentUser)
    // wiredCases({ error, data }) {
    //     if (data) {
    //         console.log('Cases: ', data);
    //         this.cases = data.map(caseRecord => ({
    //             Id: caseRecord.Id,
    //             CaseNumber: caseRecord.CaseNumber,
    //             Description: caseRecord.Description,
    //             clientName: caseRecord.Account?.Name || 'N/A'
    //         }));
    //         this.updateCasesToDisplay();
    //     } else if (error) {
    //         console.error('Error fetching cases: ', error);
    //     }
    // }
    @track currectCaseId = '';
    handleAccept(event) {
        const caseId = event.target.dataset.id;
        if (!caseId) {
            console.error('No case ID found for acceptance.');
            return;
        }
        console.log('Accept case with ID: ', caseId);
        this.currectCaseId = caseId;
        // Add logic to handle case acceptance here

        acceptCase({ caseId: this.currectCaseId })

            .then(() => {
                // Update the UI by removing the accepted case
                this.cases = this.cases.filter(c => c.Id !== caseId);
                this.updateCasesToDisplay();

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Case Accepted',
                        message: `Case #${caseId} has been successfully accepted.`,
                        variant: 'success',
                    })
                );

                this.closeModal(); // Close the modal after acceptance
            })
            .catch(error => {
                console.error('Error accepting case: ', error);

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: `Failed to accept Case #${caseId}.`,
                        variant: 'error',
                    })
                );
            });


    }

    // Handle Case Number click
    handleCaseClick(event) {
        const caseId = event.target.dataset.id;
        const selectedCase = this.cases.find(c => c.Id === caseId);
        if (selectedCase) {
            this.modalData = {
                Id: selectedCase.Id,
                clientName: selectedCase.clientName,
                clientEmail: selectedCase.clientEmail,
                clientPhone: selectedCase.clientPhone,
                description: selectedCase.Description,
            };
            this.isModalOpen = true;
        }
    }

    async handleReject() {
        try {
            console.log('Rejecting case:', this.modalData.Id);
            await sendRejectionNotification({ caseId: this.modalData.Id });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Rejection notification sent to the case owner.',
                    variant: 'success',
                })
            );
            this.closeModal();
        } catch (error) {
            console.error('Error sending rejection notification:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to send rejection notification.',
                    variant: 'error',
                })
            );
        }
    }
    //queue
    async loadQueueCases() {
        try {
            const cases = await getCasesForQueue({ queueName: this.queueName });
            console.log();

            this.casesToDisplay = cases.map((caseRecord) => ({
                Id: caseRecord.Id,
                CaseNumber: caseRecord.CaseNumber,
                Description: caseRecord.Description,
                clientName: caseRecord.Account?.Name || 'N/A' // Handle null account
            }));
            //this.updateCasesToDisplay();
        } catch (error) {
            console.error('Error fetching cases from queue: ', error);
            this.casesToDisplay = []; // Clear cases on error
        }
    }
    handleNextPage() {
        if (!this.isLastPage) {
            this.currentPage += 1;
            this.updateCasesToDisplay();
        }
    }

    handlePreviousPage() {
        if (!this.isFirstPage) {
            this.currentPage -= 1;
            this.updateCasesToDisplay();
        }
    }

    updateCasesToDisplay() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = this.currentPage * this.pageSize;
        this.casesToDisplay = this.cases.slice(startIndex, endIndex);
    }

    // Close the modal
    closeModal() {
        this.isModalOpen = false;
    }
}