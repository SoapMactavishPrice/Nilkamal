import { LightningElement, wire, track } from 'lwc';
import getQuoteRecords from '@salesforce/apex/OpenSpareRequestController.getQuoteRecords';
export default class OpenSpareRequest extends LightningElement {
    @track quotes = [];
    @track currentPage = 1;
    @track totalPages = 0;
    @track pageSize = 10;

    connectedCallback() {
        this.fetchQuotes();
    }

    fetchQuotes() {
        getQuoteRecords()
            .then(result => {
                console.log('result', result);
                console.log('result', JSON.parse(result));
                // this.quotes = result ? JSON.parse(result) : [];
                const parsedQuotes = result ? JSON.parse(result) : [];
                this.quotes = parsedQuotes.map(quote => ({
                    ...quote,
                    recordLink: `/lightning/r/Quote/${quote.Id}/view` // Salesforce Record Link
                }));

                this.totalPages = Math.ceil(this.quotes.length / this.pageSize);
            })
            .catch(error => {
                console.error('Error fetching quotes:', error);
            });
    }

    get paginatedQuotes() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.quotes.slice(start, end);
    }

    get disablePrevious() {
        return this.currentPage === 1;
    }

    get disableNext() {
        return this.currentPage >= this.totalPages;
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }
}