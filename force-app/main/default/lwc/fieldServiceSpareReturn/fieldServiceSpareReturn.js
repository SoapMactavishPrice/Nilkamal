import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { CurrentPageReference } from 'lightning/navigation';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

import GliderImageCarousel from '@salesforce/resourceUrl/GliderImageCarousel';

import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh } from 'c/utilJS';

import getWorkOrderData from '@salesforce/apex/fieldServiceSpareReturn.getWorkOrderData';
import getSpareRequests from '@salesforce/apex/fieldServiceSpareReturn.getSpareRequests';
import createSpareReturns from '@salesforce/apex/fieldServiceSpareReturn.createSpareReturns';


export default class FieldServiceSpareReturn extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    @api recordId;
    @api spareid;
    @track caseType = '';
    @track workOrderData = {};
    @track error;
    @track isCheckboxChecked = false;
    @track currentPage = 1;
    @track pageSize = 10;
    @track isFirstPage = true;
    @track isLastPage = false;
    @track isMobileView = false;    //for mobile view
    @track caseType = '';
    @track spareParts = [];
    @track searchKey = '';
    @track error;
    @track allData = [];
    @track allFilteredData = [];
    @track tempSpareParts = [];
    clientFilterQuery;

    @track isImageCarouselVisible;
    @track selectedSpare;
    @track isFlickityLoaded = false;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        console.log('OUTPUT : ', this.currentPageReference);
        if (this.currentPageReference) {
            this.recordId = this.currentPageReference.state.c__id;
            console.log('this.recordId', this.recordId);
        }
    }



    connectedCallback() {
        console.log('Test');
        console.log('Record ID:', this.recordId);
        this.fetchCaseAndAssetDetails();
        this.fetchSpareRequests();
        const mediaQuery = window.matchMedia('(max-width: 768px)');
        this.isMobileView = mediaQuery.matches;

        mediaQuery.addEventListener('change', (event) => {
            this.isMobileView = event.matches;
        });

        Promise.all([loadStyle(this, GliderImageCarousel + '/glider.min.css'), loadScript(this, GliderImageCarousel + '/glider.min.js')])
            .then(() => {
                console.log('Scripts loaded successfully');
                this.isFlickityLoaded = true;
            })
            .catch(error => {
                console.log('Error loading scripts', error);
                showToast(this, 'Error', error, 'error');
            });
    }

    renderedCallback() {
        const gliderElement = this.template.querySelector('.glider');
        if (gliderElement && this.isImageCarouselVisible && this.isFlickityLoaded) {
            new Glider(gliderElement, {
                slidesToShow: 1,
                dots: this.template.querySelector('.dots'),
                draggable: true,
                scrollLock: true,
                scrollLockDelay: 0
            });
        }
    }

    handleImageClick(event) {
        const id = event.currentTarget.dataset.id;
        const spare = this.spareParts.find(part => part.Id === id);
        if (spare && this.isFlickityLoaded) {
            this.selectedSpare = spare;
            this.selectedSpare.imageUrls?.forEach(url => url.includes('?THUMB') == false ? url += '?THUMB720BY480' : url);
            this.isImageCarouselVisible = true;
            // loadQuickActionPopupStyle(this, 60, 60);
        }
    }

    handleCloseImageCarousel() {
        this.isImageCarouselVisible = false;
        this.selectedSpare = null;
        unloadQuickActionPopupStyle(this);
    }



    fetchCaseAndAssetDetails() {
        console.log('fetchCaseAndAssetDetails');
        getWorkOrderData({ woid: this.recordId })
            .then((data) => {
                let newData = JSON.parse(JSON.stringify(data));
                console.log('newData-->', newData);
                let FinalNewData = newData[0];
                this.caseType = FinalNewData.Case__r.Type;
                this.caseNum = FinalNewData.Case__r.CaseNumber;
                this.AccountName = FinalNewData.Case__r.Account.Name;
                this.date = this.getDate(FinalNewData.Case__r.CreatedDate);
                this.SerialNo = FinalNewData.Case__r.Asset.SerialNumber;
                this.MaterialCode = FinalNewData.Case__r.Asset.ProductCode;
            })
    }

    getDate(date) {
        let dateTimeStr = date;
        let dateObj = new Date(dateTimeStr);

        // Extract the day, month, and year
        let day = dateObj.getDate().toString().padStart(2, '0'); // Add leading zero if needed
        let month = (dateObj.getMonth() + 1).toString().padStart(2, '0'); // Months are zero-indexed, so add 1
        let year = dateObj.getFullYear();

        // Return the formatted date as DD-MM-YYYY
        return `${day}-${month}-${year}`;
    }



    fetchSpareRequests() {
        getSpareRequests({ workOrderId: this.recordId })
            .then((result) => {
                console.log('result--->>', result);
                this.spareParts = result.map((part) => {
                    const imageCount = part.imageUrls?.length || 0;
                    return {
                        ...part,
                        checked: false,
                        quantity: 1,
                        imageUrls: part.imageUrls || [],
                        imageUrl: part.imageUrls && part.imageUrls.length > 0 ? part.imageUrls[0] + '?THUMB240BY180' : '',
                        imageCount: imageCount
                    };
                });
                this.allData = result;
                this.allData = this.spareParts;
                this.updatePaginationStatus();
                this.allFilteredData = this.spareParts;
                console.log('spareParts:', this.spareParts);
                console.log('spareParts: ', this.spareParts);
            })
            .catch((error) => {
                this.error = error.body.message;
                this.spareParts = [];
            });
    }



    handleSearchChange(event) {
        this.allFilteredData = this.allData;
        console.log('search', this.allFilteredData)
        this.clientFilterQuery = event.target.value;
        var __FOUND = this.allFilteredData.filter((cli, index) => {
            if (cli.modelName.toUpperCase().includes(this.clientFilterQuery.toUpperCase()) || cli.prodName.toUpperCase().includes(this.clientFilterQuery.toUpperCase()))
                return true;
        });
        console.log('__FOUND up', __FOUND);
        if (__FOUND == undefined || __FOUND == []) {

            console.log('__FOUND', __FOUND);
            this.spareParts = this.allData;
        } else {
            console.log('__FOUND found', __FOUND);
            this.spareParts = __FOUND;
        }
        this.spareParts.forEach(each => {
            this.tempSpareParts.forEach(eachTemp => {
                if (each.Id == eachTemp.Id) {
                    each.Id = eachTemp.Id;
                    each.quantity = eachTemp.quantity;
                    each.checkbox = eachTemp.checkbox;
                    each.prodName = eachTemp.prodName;
                    each.modelName = eachTemp.modelName;
                    each.modelDesc = eachTemp.modelDesc;
                    each.price = eachTemp.price;
                    each.pricebookEntryId = eachTemp.pricebookEntryId;
                    each.quantityReq = eachTemp.quantityReq;
                    each.currency = eachTemp.currency;
                }
            })
        })

        this.searchKey = event.target.value;

    }



    //spare return save start here
    handleSave() {
        this.showSpinner = true;
        const selectedParts = this.spareParts
            .filter(part => part.checkbox && part.quantity > 0)
            .map(part => ({
                Id: part.Id,
                quantity: part.quantity,
                checkbox: part.checkbox,
                prodName: part.prodName,
                modelName: part.modelName,
                modelDesc: part.modelDesc,
                price: part.price,
                pricebookEntryId: part.pricebookEntryId,
                quantityReq: part.quantityReq,
                currency: part.currency,

            }));

        const invalidParts = selectedParts.filter(part => {
            return !part.quantity || part.quantity <= 0; // Quantity is either null, blank, or <= 0
        });

        // If there are invalid parts, prompt the user and stop the save
        if (invalidParts.length > 0) {
            this.showToast('Error', 'Please enter a valid quantity greater than 0 for all selected spare parts.', 'error');
            this.showSpinner = false;
            return;
        }

        if (selectedParts.length === 0) {
            this.showToast('Warning', 'Please select at least one spare part and enter a valid quantity.', 'warning');
            return;
        }

        createSpareReturns({ workOrderId: this.recordId, spareParts: selectedParts })
            .then(() => {
                this.showToast('Success', 'Spare Return created successfully!', 'success');
                this.fetchSpareRequests(); // Refresh the list if needed
                this.navigateToLWC();
            })
            .catch(error => {
                console.error('Error creating spare requests:', error);
                this.showToast('Error', 'An error occurred while creating spare requests.', 'error');
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    // Utility method to show toast messages
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
    //ended here

    handleQuantityChange(event) {
        const partId = event.target.dataset.id;
        let newValue = event.target.value;
        const inputField = event.target; // Access the input field directly
        const index = this.spareParts.findIndex(part => part.Id === partId);

        // Allow only numeric values greater than or equal to 1
        if (newValue === "" || isNaN(newValue) || parseInt(newValue, 10) < 1) {
            // Set custom validity message
            inputField.setCustomValidity('Please enter a quantity greater than or equal to 1');
        } else {
            // Clear error if valid
            inputField.setCustomValidity('');
            if (index !== -1) {
                this.spareParts[index].quantity = parseInt(newValue, 10);
            }
        }

        // Prevent the user from entering negative or less than 1 values
        if (parseInt(newValue, 10) < 1) {
            event.preventDefault(); // Prevent the invalid value
            inputField.value = '';  // Optionally, clear the input
        }

        // Display validation message
        inputField.reportValidity();
        this.tempSpareParts = JSON.parse(JSON.stringify(this.spareParts));
    }

    handleCheckboxChange(event) {
        const partId = event.target.dataset.id;
        const isChecked = event.target.checked;

        this.spareParts = this.spareParts.map((part) => {
            if (part.Id === partId) {
                // Reset quantity to default (1) when checkbox is unchecked
                return { ...part, checkbox: isChecked, quantity: isChecked ? part.quantity : 1 };
            }
            return part;
        });
        this.tempSpareParts = JSON.parse(JSON.stringify(this.spareParts));
    }

    get paginatedCases() {
        if (!this.spareParts) return [];

        const startIdx = (this.currentPage - 1) * this.pageSize;
        const endIdx = this.currentPage * this.pageSize;
        this.isFirstPage = this.currentPage === 1;
        this.isLastPage = this.currentPage === this.totalPages;

        this.spareParts = this.spareParts.map(spare => {
            let parsedImageUrls = [];

            if (Array.isArray(spare.imageUrls)) {
                parsedImageUrls = spare.imageUrls; // Already an array, use as is
            } else if (typeof spare.imageUrls === 'string' && spare.imageUrls.trim() !== '') {
                const trimmedString = spare.imageUrls.trim();

                // Validate if it's a properly formatted JSON array before parsing
                if (trimmedString.startsWith('[') && trimmedString.endsWith(']')) {
                    try {
                        parsedImageUrls = JSON.parse(trimmedString);
                        console.log('parsedImageUrls', parsedImageUrls);
                    } catch (error) {
                        console.error('Error parsing imageUrls:', error);
                        parsedImageUrls = []; // Assign an empty array if parsing fails
                    }
                } else {
                    // If it's a single URL string, wrap it in an array
                    parsedImageUrls = [trimmedString];
                }
            }

            return { ...spare, imageUrls: parsedImageUrls };
        });

        return this.spareParts.slice(startIdx, endIdx);
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
        this.fetchSpareRequests();
        this.currentPage = 1;
    }

    updatePaginationStatus() {
        const totalCases = this.spareParts.length;
        this.totalPages = Math.ceil(totalCases / this.pageSize);
        this.isFirstPage = this.currentPage === 1;
        this.isLastPage = this.currentPage === this.totalPages;
    }
    navigateToLWC() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__fieldServiceHome'
            }
        });

    }
    // get hasMultipleImages() {
    //     return this.spareParts.some(spare => spare.imageUrls.length > 1);
    // }

    // get isSingleImage() {
    //     return this.spareParts.some(spare => spare.imageUrls.length === 1);
    // }
    // get carouselStyle() {
    //     const imageCount = this.spareParts.length && this.spareParts[0].imageUrls ? this.spareParts[0].imageUrls.length : 1;
    //     return imageCount > 1 ? `animation: slide ${imageCount * 2}s infinite linear;` : '';
    // }

}