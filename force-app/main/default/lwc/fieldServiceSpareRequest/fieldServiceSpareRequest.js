import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

import GliderImageCarousel from '@salesforce/resourceUrl/GliderImageCarousel';
import raiseOppAndQuote from '@salesforce/apex/RaiseOppAndQuoteController.raiseOppAndQuote';

import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh, navigateBackInHistory, scrollToTop } from 'c/utilJS';

import getQuoteRecordDetails from '@salesforce/apex/FieldsServiceSpareRequest.getQuoteRecordDetails';
import getWorkOrderData from '@salesforce/apex/FieldsServiceSpareRequest.getWorkOrderData';
import getAssetDetails from '@salesforce/apex/FieldsServiceSpareRequest.getAssetDetails';
import getSparePartsByName from '@salesforce/apex/FieldsServiceSpareRequest.getSparePartsByName';
import getAllSpares from '@salesforce/apex/FieldsServiceSpareRequest.getAllSpares';
import getAllSparesDetails from '@salesforce/apex/FieldsServiceSpareRequest.getAllSparesDetails';
import getAssetCategory from '@salesforce/apex/FieldsServiceSpareRequest.getAssetCategory_v1';
import createSpareRequests from '@salesforce/apex/FieldsServiceSpareRequest.createSpareRequests';
import fetchInventory from '@salesforce/apex/FieldsServiceSpareRequest.fetchInventory';
import IsUnreadByOwner from '@salesforce/schema/Lead.IsUnreadByOwner';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import SERVICE_REQUEST_OBJECT from '@salesforce/schema/Spare_Request__c';
import WARRANTY_FIELD from '@salesforce/schema/Spare_Request__c.Warranty_Period__c';


export default class FieldServiceSpareRequest extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    @api recordId;
    @api quoteId;
    @api caseId;
    @api serviceAppointmentId;
    @api assetId;

    @track itemMasterId;
    @track workOrderData = {};
    @track error;
    @track isCheckboxChecked = false;
    @track currentPage = 1;
    @track pageSize = 10;
    @track isFirstPage = true;
    @track isLastPage = false;
    @track isModalOpen = true;

    @track isMobileView = false;    //for mobile view

    @track caseType = '';

    @track spareParts = [];
    @track searchKey = '';
    @track error;
    @track allData = [];
    @track allFilteredData = [];
    clientFilterQuery;

    @track isImageCarouselVisible;
    @track selectedSpare;
    @track isFlickityLoaded = false;
    @track selectedParts = null;
    @track flag = 0;
    @track tempSpareParts = [];
    @track warrantyOptions = [];

    @track businessvertical = '';
    // Fetch object info to get the default record type ID
    @wire(getObjectInfo, { objectApiName: SERVICE_REQUEST_OBJECT })
    objectInfo;

    // Fetch picklist values using defaultRecordTypeId
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: WARRANTY_FIELD
    })
    wiredWarrantyOptions({ data, error }) {
        if (data) {
            this.warrantyOptions = data.values.map(opt => ({
                label: opt.label,
                value: opt.value
            }));
        } else if (error) {
            console.error('Error loading warranty picklist values:', error);
        }
    }



    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        // console.log('OUTPUT : ', this.currentPageReference);
        if (this.currentPageReference) {
            this.recordId = this.currentPageReference.state.c__id;
            this.serviceAppointmentId = this.currentPageReference.state.c__serviceAppointmentId;
            this.caseId = this.currentPageReference.state.c__caseId;
            this.quoteId = this.currentPageReference.state.c__quoteId;
            this.assetId = this.currentPageReference.state.c__assetId;
            // console.log('this.recordId', this.recordId);
            // console.log('serviceAppointmentId', this.serviceAppointmentId);
        }
        if (this.recordId) {
            this.fetchCaseAndAssetDetails();
            //this.fetchSpareParts();
        }
        else if (this.quoteId) {
            getQuoteRecordDetails({ quoteId: this.quoteId })
                .then((data) => {
                    this.recordId = data.Work_Order__c;
                    this.caseId = data.Case__c;
                    this.assetId = data.Asset_Serial_Number__c;
                    this.fetchCaseAndAssetDetails();
                })
        }

    }



    connectedCallback() {
        // console.log('Test');
        // console.log('Record ID:', this.recordId);
        // this.fetchCaseAndAssetDetails();
        //this.fetchSpareParts();
        const mediaQuery = window.matchMedia('(max-width: 768px)');
        this.isMobileView = mediaQuery.matches;

        disablePullToRefresh(this);

        mediaQuery.addEventListener('change', (event) => {
            this.isMobileView = event.matches;
        });

        Promise.all([loadStyle(this, GliderImageCarousel + '/glider.min.css'), loadScript(this, GliderImageCarousel + '/glider.min.js')])
            .then(() => {
                // console.log('Scripts loaded successfully');
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

    disconnectedCallback() {
        enablePullToRefresh(this);
    }



    handleImageClick(event) {
        const id = event.currentTarget.dataset.id;
        const spare = this.spareParts.find(part => part.Id === id);
        if (spare && this.isFlickityLoaded) {
            this.selectedSpare = spare;
            this.selectedSpare.imageUrls?.forEach(url => url.includes('?THUMB') == false ? url += '?thumb=THUMB720BY480' : url);
            scrollToTop(this);
            this.isImageCarouselVisible = true;
            // loadQuickActionPopupStyle(this, 60, 60);
        }
    }

    handleCloseImageCarousel() {
        this.isImageCarouselVisible = false;
        this.selectedSpare = null;
        unloadQuickActionPopupStyle(this);
    }




    @track searchTimeout;
    handleSearchChange(event) {
        // console.log('SPARE PARTS');
        // console.log(this.spareParts);
        this.mobileSearchKey = '';
        this.allFilteredData = this.allData;
        // console.log('search', JSON.stringify(this.allFilteredData))
        this.clientFilterQuery = event.target.value;
        this.currentPage = 1;

        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
            this.searchTimeout = null;
        }

        this.searchTimeout = setTimeout(() => {
            var __FOUND = this.allFilteredData.filter((cli, index) => {
                if (cli.modelName && cli.modelName.toLowerCase().includes(this.clientFilterQuery.toLowerCase()) ||
                    cli.prodName && cli.prodName.toLowerCase().includes(this.clientFilterQuery.toLowerCase()) ||
                    cli.modelDesc && cli.modelDesc.toLowerCase().includes(this.clientFilterQuery.toLowerCase())) {
                    return true;
                }
            });
            // console.log('__FOUND up', __FOUND);
            if (__FOUND == undefined || __FOUND == []) {

                // console.log('__FOUND', __FOUND);
                this.spareParts = this.allData;
            } else {
                // console.log('__FOUND found', __FOUND);
                this.spareParts = __FOUND;
            }
            // this.spareParts.forEach((each, index) => {
            //     const match =this.tempSpareParts.forEach(eachTemp => {
            //         if (each.Id == eachTemp.Id) {
            //             each.quantity = eachTemp.quantity;
            //             each.checkbox = eachTemp.checkbox;
            //             each.prodId = eachTemp.prodId;
            //             each.prodName = eachTemp.prodName;
            //             each.modelName = eachTemp.modelName;
            //             each.modelDesc = eachTemp.modelDesc;
            //             each.price = eachTemp.price;
            //             each.calculatedPrice = eachTemp.calculatedPrice;
            //             each.pricebookEntryId = eachTemp.pricebookEntryId;
            //             each.currencyCode = eachTemp.currencyCode;
            //             each.returnableNonReturnable = eachTemp.returnableNonReturnable;
            //             each.chargeableNonChargeable = eachTemp.chargeableNonChargeable;
            //             each.billingType = eachTemp.billingType;
            //             each.rowIndex = index;
            //             each.isWarranty = eachTemp.isWarranty;
            //             each.warranty = eachTemp.warranty;

            //         }
            //     });
            // });
            let curIndex = 0;
            this.spareParts.forEach((each) => {
                each.rowIndex = curIndex;
                curIndex = curIndex + 1;
            });

            this.updatePaginationStatus();
        }, 500);

        this.searchKey = event.target.value;

    }

    fetchCaseAndAssetDetails() {
        this.showAll = false;
        this.isFastMovingChecked = false;
        this.isCriticalChecked = false;
        this.isConsumablesChecked = false;
        this.clientFilterQuery = '';
        this.mobileSearchKey = '';
        // console.log('fetchCaseAndAssetDetails');
        getWorkOrderData({ woId: this.recordId })
            .then((data) => {
                let newData = JSON.parse(JSON.stringify(data));
                console.log('newData-->', newData);
                let FinalNewData = newData[0];
                this.caseType = FinalNewData?.Case__r?.Type;
                this.caseNum = FinalNewData?.Case__r?.CaseNumber;
                this.AccountName = FinalNewData?.Case__r?.Account?.Name;
                if (FinalNewData?.Case__r?.CreatedDate) {
                    this.date = this.getDate(FinalNewData?.Case__r?.CreatedDate);
                }
                this.SerialNo = FinalNewData?.Case__r?.Asset?.Name;
                this.MaterialCode = FinalNewData?.Case__r?.Asset?.ProductCode;
                this.itemMasterId = FinalNewData?.Case__r?.Asset?.Product2Id;
                this.InvoiceNumber = FinalNewData?.Case__r?.Asset?.Invoice_Number__c;
                this.materialCommissionDate = FinalNewData?.Case__r?.Asset?.InstallDate;
                this.assetStatus = FinalNewData?.Case__r?.Asset.Type__c;
                this.businessvertical = FinalNewData?.Case__r?.Division__c;
                if (this.itemMasterId) {
                    this.fetchSpareParts();
                }
            })
            .catch((error) => {
                console.log('error-->', error);
                showToast(this, 'Error', error, 'error');
            });
    }

    get isPrinter() {
    return this.businessvertical === 'Printer';
    }

    get isNotPrinter() {
        return this.businessvertical !== 'Printer';
    }


    fetchSpareParts() {
        // console.log('Fetching spare parts for itemMasterId:', this.itemMasterId)
        this.showSpinner = true;
        getSparePartsByName({ productId: this.itemMasterId, woId: this.recordId, showAll: false })
            .then((result) => {
                try {
                    console.log('json result:', JSON.parse(result));
                    const parsedData = JSON.parse(result);
                    this.spareParts = parsedData.map((item, index) => {

                        const imageCount = item.imageUrls?.length || 0;
                        return {
                            ...item,
                            calculatedPrice: item.calculatedPrice != '' ? item.calculatedPrice : item.price,
                            checked: item.quantity == 0 ? false : true,
                            checkbox: item.quantity == 0 ? false : true,
                            // billingType: item.quantity != 0 ? 'Chargeable' : '',
                            billingType: item.billingType,
                            quantity: item.quantity,
                            isWarranty: item.quantity != 0 && item.warranty == 'Y' ? true : false,
                            imageUrls: item.imageUrls || [],
                            imageUrl: item.imageUrls && item.imageUrls.length > 0 ? item.imageUrls[0] + '?thumb=THUMB240BY180' : '',
                            imageCount: imageCount,
                            totalStock: item.totalStock,
                            rowIndex: index
                        };
                    });
                    this.currentPage = 1;
                    this.allData = this.spareParts;
                    this.updatePaginationStatus();
                    this.allFilteredData = this.spareParts;
                    // console.log('spareParts result:', JSON.stringify(this.spareParts));
                    this.showSpinner = false;
                } catch (parseError) {
                    console.error('Error parsing spare parts JSON:', parseError);
                    this.error = parseError;
                    this.showSpinner = false;
                }
            })
            .catch((error) => {
                this.error = error;
                console.error('Error fetching spare parts:', JSON.stringify(error));
                this.showSpinner = false;
                //this.showToast('Error', 'Failed to fetch spare parts: ' + (error.body ? error.body.message : error), 'error');
                showToast(this, 'Error', 'Failed to fetch spare parts:', 'error', error);
            });
    }

    @track category = '';
    @track isFastMovingChecked = false;
    @track isCriticalChecked = false;
    @track isConsumablesChecked = false;
    handleAssetCategoryChange(event) {
        // console.log('event.target.value ', event.target.value);
        // console.log('event.target.value ', event.target.checked);
        // console.log('event.target.value ', event.target.dataset.name);
        // this.showSpinner = true;
        this.category = event.target.check;
        if (event.target.dataset.name == 'FastMoving') {
            this.isFastMovingChecked = event.target.checked;
        }

        if (event.target.dataset.name == 'Critical') {
            this.isCriticalChecked = event.target.checked;
        }

        if (event.target.dataset.name == 'Consumables') {
            this.isConsumablesChecked = event.target.checked;
        }

        if (event.target.dataset.name == 'Mapped Spares') {
            this.isMappedSparesChecked = event.target.checked;
        }
        this.showSpinner = true;
        this.showAll = false;
        this.clientFilterQuery = '';

        setTimeout(() => {
            this.fetchAssetCategorySpareParts();
        }, 2000);
    }


    fetchAssetCategorySpareParts() {

        // console.log('Fetching spare parts for itemMasterId:', this.itemMasterId)
        console.log('this.isMappedSparesChecked ', this.isMappedSparesChecked);
        getAssetCategory({ productId: this.itemMasterId, woId: this.recordId, fastMoving: this.isFastMovingChecked, critical: this.isCriticalChecked, consumables: this.isConsumablesChecked, mappedSpares: this.isMappedSparesChecked })
            .then((result) => {
                try {
                    this.showSpinner = false;
                    // console.log('json result:', JSON.parse(result));
                    const parsedData = JSON.parse(result);
                    this.spareParts = parsedData
                        .sort((a, b) => {
                            // Sort in descending order of quantity (non-zero first)
                            return (b.quantity || 0) - (a.quantity || 0);
                        })
                        .map((item, index) => {
                            const imageCount = item.imageUrls?.length || 0;
                            return {
                                ...item,
                                calculatedPrice: item.calculatedPrice != '' ? item.calculatedPrice : item.price,
                                checked: item.quantity == 0 ? false : true,
                                checkbox: item.quantity == 0 ? false : true,
                                billingType: item.billingType != '' ? item.billingType : item.quantity != 0 ? 'Chargeable' : '',
                                quantity: item.quantity,
                                isWarranty: item.quantity != 0 && item.warranty == 'Y' ? true : false,
                                imageUrls: item.imageUrls || [],
                                imageUrl: item.imageUrls && item.imageUrls.length > 0 ? item.imageUrls[0] + '?thumb=THUMB240BY180' : '',
                                imageCount: imageCount,
                                rowIndex: index
                            };
                        });
                    this.currentPage = 1;
                    this.allData = this.spareParts;
                    this.updatePaginationStatus();
                    this.allFilteredData = this.spareParts;
                    // console.log('spareParts result:', JSON.stringify(this.spareParts));
                } catch (parseError) {
                    console.error('Error parsing spare parts JSON:', parseError);
                    this.error = parseError;
                }
            })
            .catch((error) => {
                this.error = error;
                this.showSpinner = false;
                console.error('Error fetching spare parts:', JSON.stringify(error));
                //this.showToast('Error', 'Failed to fetch spare parts: ' + (error.body ? error.body.message : error), 'error');
                showToast(this, 'Error', 'Failed to fetch spare parts:', 'error', error);

            })

    }


    handleCheckbox1Change(event) {
        const partId = event.target.dataset.id;
        const isChecked = event.target.checked;

        this.spareParts = this.spareParts.map((part) => {
            if (part.Id === partId) {
                return { ...part, returnableNonReturnable: isChecked };
            }
            return part;
        });
    }

    handleCheckbox2Change(event) {
        const partId = event.target.dataset.id;
        const isChecked = event.target.checked;

        this.spareParts = this.spareParts.map((part) => {
            if (part.Id === partId) {
                return { ...part, chargeableNonChargeable: isChecked };
            }
            return part;
        });
    }


    handleSave() {
        // console.log('Below Spare Part');
        const selectedPartss = this.spareParts
            .filter(part => part.checkbox && part.quantity > 0)
            .map(part => ({
                Id: part.Id,
                quantity: part.quantity,
                checkbox: part.checkbox,
                prodId: part.prodId,
                prodName: part.prodName,
                modelName: part.modelName,
                modelDesc: part.modelDesc,
                price: part.calculatedPrice,
                pricebookEntryId: part.pricebookEntryId,
                warrantyperiod: part.warrantyperiod,
                noofpmvisit: part.noofpmvisit,
                noofbreakdownvisit: part.noofbreakdownvisit,
                currencyCode: part.currencyCode,
                returnableNonReturnable: part.returnableNonReturnable,
                chargeableNonChargeable: part.chargeableNonChargeable,
                billingType: part.billingType,
                totalStock: part.totalStock,
                category: part.category
            }));

        if (selectedPartss.length === 0) {
            this.showToast('Error', 'Please select at least one spare part and enter a valid quantity.', 'warn');
            showToast(this, 'Error', 'Please select at least one spare part and enter a valid quantity.', 'warn');
            return;
        }

        const invalidQuantity = selectedPartss.filter(part => !part.quantity || part.quantity <= 0);
        if (invalidQuantity.length > 0) {
            this.showToast('Error', 'Please enter a valid quantity greater than 0 for all selected spare parts.', 'error');
            return;
        }

        const invalidPrice = selectedPartss.filter(part => part.quantity > 0 && (part.price == '0' || part.price == '0.00' || part.price == '' || part.price == undefined || part.price == null));
        if (invalidPrice.length > 0) {
            this.showToast('Error', 'Price is invalid for selected spare parts.', 'warn');
            return;
        }

        const invalidBillingType = selectedPartss.filter(part => !part.billingType);
        if (invalidBillingType.length > 0) {
            this.showToast('Error', 'Please select a billing type for all selected spare parts.', 'error');
            return;
        }


        this.showSpinner = true;
        // console.log('serviceAppointmentId---', this.serviceAppointmentId);
        createSpareRequests({ workOrderId: this.recordId, quoteId: this.quoteId, spareParts: selectedPartss, serviceAppointmentId: this.serviceAppointmentId })
            .then(() => {
                this.showToast('Success', 'Added to cart', 'success');
                // this.fetchSpareParts(); // Refresh the list if needed
                //this.spareParts = null; //commented by shashank on 2 april
                // navigateBackInHistory(this); //commented by shashank on 2 april
                if (this.quoteId) {
                    navigateBackInHistory(this);
                }
            })
            .catch(error => {
                console.error('Error creating spare requests:', error);
                //this.showToast('Error', 'An error occurred while creating spare requests.', 'error');
                showToast(this, 'Error', 'An error occurred while creating spare requests.', 'error', error);

            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }


    handleQuantityChange(event) {
        const partId = event.target.dataset.id;
        let newValue = event.target.value;
        const inputField = event.target; // Access the input field directly
        const index = this.spareParts.findIndex(part => part.Id === partId);

        // Allow only numeric values greater than or equal to 1
        if (newValue === "" || isNaN(newValue) || parseInt(newValue, 10) < 1) {
            // Set custom validity message
            // inputField.setCustomValidity('Please enter a quantity greater than or equal to 1');
        } else {
            // Clear error if valid
            // inputField.setCustomValidity('');
        }
        if (index !== -1) {
            this.spareParts[index].quantity = parseInt(newValue, 10);
            this.spareParts[index].checkbox = true;
        } else {
            this.spareParts[index].checkbox = false;
        }

        // Prevent the user from entering negative or less than 1 values
        if (parseInt(newValue, 10) < 1) {
            this.spareParts[index].billingType = '';
        }

        // Display validation message
        inputField.reportValidity();
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
        this.fetchSpareParts();
        this.currentPage = 1;
    }

    updatePaginationStatus() {
        // console.log(this.currentPage);

        const totalCases = this.spareParts.length;
        this.totalPages = Math.ceil(totalCases / this.pageSize);
        this.isFirstPage = this.currentPage === 1;
        this.isLastPage = this.currentPage === this.totalPages;
    }


    handleCheckboxChange(event) {
        const partId = event.target.dataset.id;
        const isChecked = event.target.checked;
        if (this.spareParts != null) {
            this.spareParts = this.spareParts.map((part) => {
                if (part.Id === partId) {
                    // Reset quantity to default (1) when checkbox is unchecked
                    const billingType = this.assetUnderWarrantyOrAMC == false ? 'Chargeable' : 'FOC and Returnable';
                    return {
                        ...part,
                        checkbox: isChecked,
                        billingType: billingType,
                        quantity: isChecked ? part.quantity : 0,
                        calculatedPrice: isChecked ? (this.assetUnderWarrantyOrAMC && billingType != 'Chargeable' ? 0 : part.price) : part.price
                    };
                }
                return part;
            });
        }
        this.tempSpareParts = JSON.parse(JSON.stringify(this.spareParts));
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


    columns = [
        { label: 'Spare', fieldName: 'Material', hideDefaultActions: 'true', wrapText: true, },
        { label: 'Plant', fieldName: 'Plant', hideDefaultActions: 'true', wrapText: true, },
        //{ label: 'Plant Name', fieldName: 'PlantName' },
        //{ label: 'Unrestricted Stock', fieldName: 'UnrestrictedStock' },
        { label: 'Total Stock', fieldName: 'TotalStock', hideDefaultActions: 'true' },
        // { label: 'Stock In Transit', fieldName: 'StockInTransit' },
        //{ label: 'Manufacturing Part No', fieldName: 'ManufacturingPartNo' }
    ];

    @track isModalOpen = false;
    @track error = false;

    handleCheckStock(event) {
        // console.log(' event.target.dataset', event.target.data);
        // console.log(' event.target.dataset', event.target.dataset.materialcode);
        // console.log(' event.target.dataset', event.target.dataset.proname);
        const index = event.target.dataset.index;
        const materialCode = event.target.dataset.proname;
        const plantName = event.target.dataset.plantname;
        // console.log('materialCode', materialCode, 'plantName', plantName);

        this.showSpinner = true;
        fetchInventory({ material: materialCode, plant: plantName })
            //fetchInventory({ material: 'NC-04202090017', plant: '1455' })
            .then(result => {
                if (result && Array.isArray(result) && result.length > 0) {
                    this.inventoryData = result;
                    //this.isModalOpen = true;
                    //scrollToTop(this);
                    // console.log('inventory result:', JSON.stringify(this.inventoryData));
                    this.spareParts[index].totalStock = this.inventoryData[0].TotalStock;
                } else {
                    showToast(this, 'Note', 'No inventory found for the selected material and plant.', 'info');
                }
            })
            .catch(error => {
                //this.error=true;
                console.log('Error fetching inventory:', error);
                showToast(this, 'Error', 'Error fetching inventory', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }


    closeModal() {
        this.isModalOpen = false;
        // Redirects to the previous page
    }







    get billingTypeOptions() {
        // if (this.assetUnderWarrantyOrAMC) {
        return [
            { label: 'FOC and Returnable', value: 'FOC and Returnable' },
            { label: 'FOC and Non-Returnable', value: 'FOC and Non-Returnable' },
            { label: 'Chargeable', value: 'Chargeable' }
        ];
        // }
        // else {
        // return [
        // { label: 'Chargeable', value: 'Chargeable' }
        // ];
        // }
    }

    get AssetCategoryOptions() {
        return [
            { label: 'None', value: 'None' },
            { label: 'Consumables', value: 'Consumables' },
            { label: 'Critical', value: 'Critical' },
            { label: 'Fast Moving', value: 'Fast Moving' }
        ];

    }


    @track assetDetails;
    @track assetUnderWarrantyOrAMC = false;

    @wire(getAssetDetails, { woId: '$recordId' })
    wiredAssetDetails({ error, data }) {
        if (data) {
            this.assetDetails = data;
            const isCurrentDateInRange = (start, end) => {
                const currentDate = new Date();
                currentDate.setHours(0, 0, 0, 0);
                const startDate = new Date(start);
                const endDate = new Date(end);
                startDate.setHours(0, 0, 0, 0);
                endDate.setHours(0, 0, 0, 0);

                return startDate <= currentDate && endDate >= currentDate;
            };

            const checkActivePeriod = (items, startKey, endKey) =>
                items.some(item => isCurrentDateInRange(item[startKey], item[endKey]));

            const warranties = this.assetDetails.Asset_Warranty__r || [];
            const amcs = this.assetDetails.Asset_AMCs__r || [];

            this.assetUnderWarrantyOrAMC = checkActivePeriod(warranties, 'Warranty_Start_Date__c', 'Warranty_End_Date__c') ||
                checkActivePeriod(amcs, 'AMC_Start_Date__c', 'AMC_End_Date__c');

            // console.log('Asset Under Warranty or AMC:', this.assetUnderWarrantyOrAMC);
        }
        else if (error) {
            this.error = error;
            console.log('Error fetching asset details:', error);
        }
    }

    handleBillingTypeChange(event) {
        const { value: billingType, dataset: { id: partId } } = event.target;
        // console.log();

        if (billingType == 'Chargeable' && this.spareParts[event.target.dataset.index].warranty == 'Y') {
            this.spareParts[event.target.dataset.index].warrantyperiod = '0';
            this.spareParts[event.target.dataset.index].isWarranty = true;
        } else {
            this.spareParts[event.target.dataset.index].warrantyperiod = '';
            this.spareParts[event.target.dataset.index].isWarranty = false;
        }

        this.spareParts = this.spareParts.map((part) => {
            if (part.Id === partId) {
                return {
                    ...part,
                    billingType: billingType,
                    //calculatedPrice: this.assetUnderWarrantyOrAMC && billingType != 'Chargeable' ? 0 : part.price
                }
            }
            return part;
        });
        this.tempSpareParts = JSON.parse(JSON.stringify(this.spareParts));
        // console.log('tempSpareParts ', JSON.stringify(this.tempSpareParts));



    }



    handleCartClick(event) {

        navigateToLWC(this, 'fieldServiceEditSpareRequest', { c__workOrderId: this.recordId, c__caseId: this.caseId, c__serviceAppointmentId: this.serviceAppointmentId });
        this.isConsumablesChecked = false;
        this.isCriticalChecked = false;
        this.isFastMovingChecked = false;
    }

    handleCreateQuoteClick(event) {
        //navigateToLWC(this, 'raiseOppAndQuote', { c__recordId: this.recordId, c__type: 'spare' });
        this.showSpinner = true;
        raiseOppAndQuote({
            recordId: this.recordId,
            serviceAppointmentId: this.serviceAppointmentId,
            type: 'spare'
        })
            .then(result => {
                // console.log(result);
                if (result && Array.isArray(result)) {
                    navigateToObjectPageWithoutHistory(this, 'Quote', 'home'); // , { filterName: 'Recent' });
                } else {
                    navigateToRecordWithoutHistory(this, result);
                }
            })
            .catch(error => {
                console.log(error);
                showToast(this, 'Error', 'Something went wrong', 'error', error);
                navigateBackInHistory(this);
                // this.dispatchEvent(new CloseActionScreenEvent());
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleNewMaterialCodeClick(event) {
        navigateToLWC(this, 'fieldServiceCreateMaterialCodeRequest', { c__caseId: this.caseId, c__materialCode: this.MaterialCode, c__serialNo: this.SerialNo });
    }

    increaseQuantity(event) {
        const index = event.target.dataset.index;
        const id = event.target.dataset.id;
        // console.log('index ', index);
        // console.log('id ', id);
        // console.log(this.spareParts[index].quantity);
        // console.log('index ', index);
        this.spareParts[index].quantity = (this.spareParts[index].quantity || 0) + 1;
        // console.log('this.spareParts[id].quantity', this.spareParts[index].quantity);

        // console.log(this.spareParts[index].quantity);
        this.spareParts[index].checkbox = true;
        if (this.spareParts[index].billingType == '') {
            this.spareParts[index].billingType = 'Chargeable';
        }

        if (this.spareParts[index].quantity == 0) {
            this.spareParts[index].warrantyperiod = '';
            this.spareParts[index].noofpmvisit = '';
            this.spareParts[index].noofbreakdownvisit = '';
            this.spareParts[event.target.dataset.index].isWarranty = false;
        } else {
            if (this.spareParts[index].warranty == 'Y') {
                this.spareParts[event.target.dataset.index].isWarranty = true;
            }
        }
        // this.tempSpareParts = JSON.parse(JSON.stringify(this.spareParts));
    }

    decreaseQuantity(event) {
        const index = event.target.dataset.index;
        const id = event.target.dataset.id;
        // console.log('index ', index);
        // console.log('id ', id);

        if (this.spareParts[index].quantity >= 1) {
            this.spareParts[index].quantity -= 1;
            // this.spareParts[index].billingType = 'Chargeable';
        }
        if (this.spareParts[index].quantity == 0) {
            this.spareParts[index].checkbox = false;
            this.spareParts[index].billingType = '';
        }
        if (this.spareParts[index].quantity == 0) {
            this.spareParts[index].warrantyperiod = '';
            this.spareParts[index].noofpmvisit = '';
            this.spareParts[index].noofbreakdownvisit = '';
            this.spareParts[event.target.dataset.index].isWarranty = false;
        } else {
            if (this.spareParts[index].warranty == 'Y') {
                this.spareParts[event.target.dataset.index].isWarranty = true;
            }
        }
        // this.tempSpareParts = JSON.parse(JSON.stringify(this.spareParts));
    }
    handleChange(event) {
        const index = event.target.dataset.index;
        this.spareParts[index].warrantyperiod = event.detail.value;
        // console.log(JSON.stringify(this.spareParts));

    }
    handlePmChange(event) {
        const index = event.target.dataset.index;
        this.spareParts[index].noofpmvisit = event.target.value;
        // console.log(JSON.stringify(this.spareParts));

    }
    handlebreakChange(event) {
        const index = event.target.dataset.index;
        this.spareParts[index].noofbreakdownvisit = event.target.value;
        // console.log(JSON.stringify(this.spareParts));

    }

    handleKeyDown(event) {
        // Prevent negative numbers and non-numeric characters
        if (!/^\d$/.test(event.key) && !['Backspace', 'Tab', 'ArrowLeft', 'ArrowRight'].includes(event.key)) {
            event.preventDefault();
        }
    }

    @track showAll = false;
    handleAllSpares(event) {
        this.mobileSearchKey = '';
        this.showSpinner = true;
        // console.log('this.showAll ', this.showAll);
        this.showAll = event.target.checked;
        this.isFastMovingChecked = false;
        this.isCriticalChecked = false;
        this.isConsumablesChecked = false;
        this.clientFilterQuery = '';
        if (this.showAll) {
            this.getAllSparesJs();
        } else {
            this.fetchSpareParts();
        }
    }

    handleMobileSearchChange(event) {
        this.mobileSearchKey = event.target.value;
        if (this.mobileSearchKey == '') {
            this.getAllSparesJs();
        }
    }
    handleMobileSearch() {
        this.getAllSparesJs();
    }

    @track mobileSearchKey = '';
    getAllSparesJs() {
        // console.log('Fetching spare parts for itemMasterId:', this.itemMasterId)
        // console.log('OUTPUT : ',this.isMobileView);
        // console.log('OUTPUT : ',this.mobileSearchKey);
        this.showSpinner = true;
        if (this.isMobileView) {
            getAllSpares({ productId: this.itemMasterId, woId: this.recordId, isMobile: this.isMobileView, searchKey: this.mobileSearchKey })
                .then((result) => {
                    console.log('getAllSpares result ', JSON.stringify(result));

                    var pricebookList = result;
                    let productIdSet = new Set();
                    let productIdMap = {};

                    pricebookList.forEach(eq => {
                        productIdSet.add(eq.Product2Id);
                        productIdMap[eq.Product2Id] = {
                            unitPrice: eq.UnitPrice,
                            pricebookEntryId: eq.Id,
                            CurrencyIsoCode: eq.CurrencyIsoCode
                        };
                    });
                    // Convert JS Set to Array (because Apex only accepts List)
                    let productIdList = Array.from(productIdSet);
                    this.showSpinner = true;
                    // console.log('productIdList ', JSON.stringify(productIdList));
                    // console.log('productIdMap ', JSON.stringify(productIdMap));
                    // console.log('getAllSpares result ', JSON.stringify(result));

                    getAllSparesDetails({
                        productId: this.itemMasterId,
                        woId: this.recordId,
                        setNamelstJson: JSON.stringify(productIdList)
                    }).then((resultStr) => {
                        try {
                            console.log('resultStr ', resultStr);

                            const result = JSON.parse(JSON.stringify(resultStr));

                            // Build Equipment Map
                            const equipmentMap = {};
                            (result.eqList || []).forEach(eq => {
                                equipmentMap[eq.SAP_Material_Code_Spare__c] = eq;
                            });

                            // Build Inventory Map
                            const inventoryMap = {};
                            (result.inventory || []).forEach(item => {
                                const key = `${item.Material__c}_${item.Plant_Master__r?.Plant_Code__c}`;
                                inventoryMap[key] = item.Quantity__c;
                            });

                            // Build Image Map
                            const productImageMap = {};
                            (result.contentLinks || []).forEach(link => {
                                const id = link.LinkedEntityId;
                                const url = link.ContentDocument?.LatestPublishedVersion?.VersionDataUrl;
                                if (!productImageMap[id]) productImageMap[id] = [];
                                if (url) productImageMap[id].push(url);
                            });

                            // Build Spare Request Map
                            const spareRequestMap = {};
                            (result.spareList || []).forEach(item => {
                                spareRequestMap[item.Item_Master__c] = item;
                            });

                            // Build Warranty Asset Map
                            const warrantyAssetsMap = {};
                            (result.assetList || []).forEach(asset => {
                                if (asset.Type__c === 'Within Warranty') {
                                    warrantyAssetsMap[asset.Product2Id] = true;
                                }
                            });

                            // Map all into spareParts
                            this.spareParts = pricebookList.map((item, index) => {
                                const pricebookDetails = productIdMap[item.Product2Id];
                                if (!pricebookDetails) return null;

                                const equipment = equipmentMap[item.Product2Id];
                                const spareReq = spareRequestMap[item.Product2Id];
                                const plantCode = equipment?.SAP_Material_Code_Spare__r?.Plant_Master__r?.Plant_Code__c || '';
                                const invKey = `${item.Product2Id}_${plantCode}`;

                                const imageUrls = productImageMap[item.Product2Id] || [];

                                return {
                                    ...item,
                                    Id: item.Product2Id,
                                    prodName: item.Product2.Name,
                                    prodId: item.Product2Id,
                                    modelName: equipment?.Vendor_Material_Code_part_code__c || '',
                                    modelDesc: item.Product2.Description,
                                    hsncode: item.Product2.HSN_Code__r?.Name || '',
                                    returnableNonReturnable: equipment?.Returnable_NonReturnable__c || 'false',
                                    chargeableNonChargeable: equipment?.Chargeable_NonChargeable__c || 'false',
                                    materialCode: item.Product2.ProductCode,
                                    plantName: item.Product2.Plant_Master__r?.Plant_Code__c,
                                    price: item.UnitPrice,
                                    pricebookEntryId: item.Id,
                                    currencyCode: item.CurrencyIsoCode,
                                    imageUrls: imageUrls,
                                    quantity: parseInt((spareReq?.Quantity_Required__c || 0).toFixed(0)),
                                    withinWarenty: warrantyAssetsMap[item.Product2Id],
                                    warranty: item.Product2.Warranty__c != null ? item.Product2.Warranty__c : 'N',
                                    warrantyperiod: '',
                                    noofpmvisit: '',
                                    noofbreakdownvisit: '',
                                    billingType: spareReq?.Billing_Type__c || '',
                                    calculatedPrice: spareReq?.Billed_Value__c || pricebookDetails.unitPrice,
                                    checked: (spareRequestMap[item.Product2Id]?.Quantity_Required__c || 0) == 0 ? false : true,
                                    checkbox: (spareRequestMap[item.Product2Id]?.Quantity_Required__c || 0) == 0 ? false : true,
                                    isWarranty: (spareRequestMap[item.Product2Id]?.Quantity_Required__c || 0) != 0 && (item.Product2.Warranty__c != null ? item.Product2.Warranty__c : 'N') == 'Y' ? true : false,
                                    imageUrl: imageUrls.length > 0 ? `${imageUrls[0]}?thumb=THUMB240BY180` : '',
                                    imageCount: imageUrls.length,

                                    totalStock: inventoryMap[invKey] || 0,
                                    rowIndex: index
                                };
                            }).filter(item => item !== null); // filter out nulls

                            this.allData = [...this.spareParts];
                            this.allFilteredData = [...this.spareParts];
                            this.updatePaginationStatus();
                            this.showSpinner = false;

                            // console.log('spareParts:', JSON.stringify(this.spareParts));
                        } catch (err) {
                            //console.error('Parsing error:', err);
                            //this.error = err;
                            this.showSpinner = false;
                        }
                    }).catch((error) => {
                        //this.error = error;
                        //console.error('Apex error:', error);
                        this.showSpinner = false;
                        //this.showToast('Error', 'Failed to fetch spare details: ' + (error.body?.message || error), 'error');
                        showToast(this, 'Error', 'Failed to fetch spare parts:', 'error', error);

                    });
                })
                .catch((error) => {
                    //this.error = error;
                    console.error('Error fetching getAllSpares parts:', JSON.stringify(error));
                    this.showSpinner = false;
                    //this.showToast('Error', 'Failed to fetch getAllSpares parts: ' + (error.body ? error.body.message : error), 'error');
                    showToast(this, 'Error', 'Failed to fetch getAllSpares parts: ', 'error', error);
                });
        } else {
            getAllSpares({ productId: this.itemMasterId, woId: this.recordId, isMobile: false, searchKey: '' })
                .then((result) => {
                    var pricebookList = result;
                    let productIdSet = new Set();
                    let productIdMap = {};

                    pricebookList.forEach(eq => {
                        productIdSet.add(eq.Product2Id);
                        productIdMap[eq.Product2Id] = {
                            unitPrice: eq.UnitPrice,
                            pricebookEntryId: eq.Id,
                            CurrencyIsoCode: eq.CurrencyIsoCode
                        };
                    });
                    // Convert JS Set to Array (because Apex only accepts List)
                    let productIdList = Array.from(productIdSet);
                    this.showSpinner = true;
                    // console.log('productIdList ', JSON.stringify(productIdList));
                    // console.log('productIdMap ', JSON.stringify(productIdMap));
                    // console.log('getAllSpares result ', JSON.stringify(result));

                    getAllSparesDetails({
                        productId: this.itemMasterId,
                        woId: this.recordId,
                        setNamelstJson: JSON.stringify(productIdList)
                    }).then((resultStr) => {
                        try {
                            // console.log('resultStr ', resultStr);

                            const result = JSON.parse(JSON.stringify(resultStr));

                            // Build Equipment Map
                            const equipmentMap = {};
                            (result.eqList || []).forEach(eq => {
                                equipmentMap[eq.SAP_Material_Code_Spare__c] = eq;
                            });

                            // Build Inventory Map
                            const inventoryMap = {};
                            (result.inventory || []).forEach(item => {
                                const key = `${item.Material__c}_${item.Plant_Master__r?.Plant_Code__c}`;
                                inventoryMap[key] = item.Quantity__c;
                            });

                            // Build Image Map
                            const productImageMap = {};
                            (result.contentLinks || []).forEach(link => {
                                const id = link.LinkedEntityId;
                                const url = link.ContentDocument?.LatestPublishedVersion?.VersionDataUrl;
                                if (!productImageMap[id]) productImageMap[id] = [];
                                if (url) productImageMap[id].push(url);
                            });

                            // Build Spare Request Map
                            const spareRequestMap = {};
                            (result.spareList || []).forEach(item => {
                                spareRequestMap[item.Item_Master__c] = item;
                            });

                            // Build Warranty Asset Map
                            const warrantyAssetsMap = {};
                            (result.assetList || []).forEach(asset => {
                                if (asset.Type__c === 'Within Warranty') {
                                    warrantyAssetsMap[asset.Product2Id] = true;
                                }
                            });

                            // Map all into spareParts
                            this.spareParts = pricebookList.map((item, index) => {
                                const pricebookDetails = productIdMap[item.Product2Id];
                                if (!pricebookDetails) return null;

                                const equipment = equipmentMap[item.Product2Id];
                                const spareReq = spareRequestMap[item.Product2Id];
                                const plantCode = equipment?.SAP_Material_Code_Spare__r?.Plant_Master__r?.Plant_Code__c || '';
                                const invKey = `${item.Product2Id}_${plantCode}`;

                                const imageUrls = productImageMap[item.Product2Id] || [];

                                return {
                                    ...item,
                                    Id: item.Product2Id,
                                    prodName: item.Product2.Name,
                                    prodId: item.Product2Id,
                                    modelName: equipment?.Vendor_Material_Code_part_code__c || '',
                                    modelDesc: item.Product2.Description,
                                    hsncode: item.Product2.HSN_Code__r?.Name || '',
                                    returnableNonReturnable: equipment?.Returnable_NonReturnable__c || 'false',
                                    chargeableNonChargeable: equipment?.Chargeable_NonChargeable__c || 'false',
                                    materialCode: item.Product2.ProductCode,
                                    plantName: item.Product2.Plant_Master__r?.Plant_Code__c,
                                    price: item.UnitPrice,
                                    pricebookEntryId: item.Id,
                                    currencyCode: item.CurrencyIsoCode,
                                    imageUrls: imageUrls,
                                    quantity: parseInt((spareReq?.Quantity_Required__c || 0).toFixed(0)),
                                    withinWarenty: warrantyAssetsMap[item.Product2Id],
                                    warranty: item.Product2.Warranty__c != null ? item.Product2.Warranty__c : 'N',
                                    warrantyperiod: '',
                                    noofpmvisit: '',
                                    noofbreakdownvisit: '',
                                    billingType: spareReq?.Billing_Type__c || '',
                                    calculatedPrice: spareReq?.Billed_Value__c || pricebookDetails.unitPrice,
                                    checked: (spareRequestMap[item.Product2Id]?.Quantity_Required__c || 0) == 0 ? false : true,
                                    checkbox: (spareRequestMap[item.Product2Id]?.Quantity_Required__c || 0) == 0 ? false : true,
                                    isWarranty: (spareRequestMap[item.Product2Id]?.Quantity_Required__c || 0) != 0 && (item.Product2.Warranty__c != null ? item.Product2.Warranty__c : 'N') == 'Y' ? true : false,
                                    imageUrl: imageUrls.length > 0 ? `${imageUrls[0]}?thumb=THUMB240BY180` : '',
                                    imageCount: imageUrls.length,

                                    totalStock: inventoryMap[invKey] || 0,
                                    rowIndex: index
                                };
                            }).filter(item => item !== null); // filter out nulls

                            this.allData = [...this.spareParts];
                            this.allFilteredData = [...this.spareParts];
                            this.updatePaginationStatus();
                            this.showSpinner = false;

                            // console.log('spareParts:', JSON.stringify(this.spareParts));
                        } catch (err) {
                            console.error('Parsing error:', err);
                            this.error = err;
                            this.showSpinner = false;
                        }
                    }).catch((error) => {
                        this.error = error;
                        console.error('Apex error:', error);
                        this.showSpinner = false;
                        //this.showToast('Error', 'Failed to fetch spare details: ' + (error.body?.message || error), 'error');
                        showToast(this, 'Error', 'Failed to fetch spare parts:', 'error', error);

                    });
                })
                .catch((error) => {
                    this.error = error;
                    console.error('Error fetching getAllSpares parts:', JSON.stringify(error));
                    this.showSpinner = false;
                    //this.showToast('Error', 'Failed to fetch getAllSpares parts: ' + (error.body ? error.body.message : error), 'error');
                    showToast(this, 'Error', 'Failed to fetch getAllSpares parts: ', 'error', error);
                });
        }
    }

}