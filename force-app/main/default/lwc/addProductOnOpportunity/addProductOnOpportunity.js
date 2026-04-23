import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent } from 'c/utilJS';
import { navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage } from 'c/utilJS';
import { loadQuickActionPopupStyle, unloadQuickActionPopupStyle } from 'c/utilJS';

import getFilter from '@salesforce/apex/UtilityCls.getFilterValues';

import getProductList from '@salesforce/apex/AddProductOnOpportunityController.getProductList';




export default class AddProductOnOpportunity extends NavigationMixin(LightningElement) {

    @api get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.handleGetProductList([]);
    }
    @api objectApiName;


    @track showSpinner;

    @track isMobile;
    @track isTablet;
    @track isDesktop;


    @track filterItems;

    @track searchTerm;


    @track isProductListVisible = true;

    @track isFilterModalOpen = false;
    @track isPreviewProductModalOpen = false;

    @track previewProductId;



    @track productList;
    @track offset = 0;
    @track lmt = 20;

    @track productRows;

    get noOfProductInRow() {
        if (this.isMobile) {
            return 1;
        }
        else {
            return 4;
        }
    }

    get columnWidth() {
        if (this.isMobile) {
            return '100%';
        }
        else {
            return '25%';
        }
    }







    connectedCallback() {
        loadQuickActionPopupStyle(this, 80);
        analyzeUserAgent(this);
    }

    renderedCallback() {
        analyzeFormFactor(this);
    }

    disconnectedCallback() {
        unloadQuickActionPopupStyle(this);
    }

    errorCallback(error, stack) {
        console.log('errorCallback', error);
        console.log('errorCallback', stack);
    }

    @wire(getFilter, { objectApiName: 'PricebookEntry', fieldNames: ['Product2.Name', 'Product2.Base_UOM__r.Name', 'Product2.Item_Group__r.Name'] })
    wiredFilters({ data, error }) {
        if (data || error) {
            this.showSpinner = false;
        }

        if (data) {
            console.log('wiredFilters data', data);
            this.filterItems = JSON.parse(JSON.stringify(data));
            // insert at 0
            this.filterItems.unshift({ label: 'Page Size', apiName: 'lmt', values: [{ label: '10', value: '10' }, { label: '20', value: '20' }, { label: '30', value: '30' }, { label: '40', value: '40' }, { label: '50', value: '50' }, { label: '100', value: '100' }], value: this.lmt });
            this.filterItems.forEach(filter => {
                filter.placeholder = `Select ${filter.label}`
            });
        }
        else if (error) {
            console.log('wiredFilters error', error);
            showToast(this, 'Error', error, 'error', error);
        }
    }




    get getFilterModalContainerStyle() {
        if (this.isMobile) {
            return 'width: 90% !important; margin: auto';
        } else {
            return 'width: 70% !important; margin: auto';
        }
    }

    handleOpenFilterModal(event) {
        this.isFilterModalOpen = true;
    }

    handleCloseFilterModal(event) {
        this.isFilterModalOpen = false;
    }

    handleFilterChange(event) {
        const { name, value } = event.target;
        if (name === 'searchTerm') {
            this.searchTerm = value;
        } else {
            const filter = this.filterItems.find(item => item.apiName === name);
            if (filter) {
                filter.value = value;
            }
        }
    }

    handleSaveFilterModal(event) {
        const filtersSelected = this.filterItems
            .filter(({ value }) => value)
            .map(({ apiName, value }) => ({ field: apiName, value }));
        if (this.searchTerm) {
            filtersSelected.push({ field: 'searchTerm', value: this.searchTerm });
        }
        console.log('filtersSelected', filtersSelected);

        this.offset = 0;
        this.handleGetProductList(filtersSelected);
    }

    handleGetProductList(filtersSelected) {
        this.showSpinner = true;

        getProductList({ recordId: this.recordId, filtersSelected, offset: this.offset, lmt: this.lmt })
            .then(data => {
                this.productList = data.map(product => {
                    const imageMatch = product.Product2.Image__c?.match(/<img\s+[^>]*src="([^"]*)"[^>]*alt="([^"]*)"[^>]*>/) ||
                        product.Product2.Image__c?.match(/<img\s+[^>]*alt="([^"]*)"[^>]*src="([^"]*)"[^>]*>/) ||
                        product.Product2.Image__c?.match(/<img\s+[^>]*src="([^"]*)"/) || [];
                    const [, imageSrc, imageAlt] = imageMatch;
                    return {
                        ...product,
                        selected: false,
                        imageSrc: imageSrc?.replace(/&amp;/g, '&') || null,
                        imageAlt: imageAlt || null,
                        get classList() {
                            return this.selected ? 'product-container product-selected' : 'product-container';
                        }
                    };
                });

                // Organize products into rows based on noOfProductInRow
                this.productRows = this.productList.reduce((rows, product, index) => {
                    if (index % this.noOfProductInRow === 0) {
                        rows.push({ index: rows.length, products: [] });
                    }
                    rows[rows.length - 1].products.push(product);
                    return rows;
                }, []);
                console.log('productRows', this.productRows);
            })
            .catch(error => {
                console.log('error', error);
                showToast(this, 'Error', error, 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleProductClick(event) {
        event.preventDefault();
        const id = event.currentTarget.dataset.id;
        const product = this.productList.find(product => product.Id === id);
        if (product) {
            console.log('handleProductClick product.selected', product.selected, event.currentTarget.dataset.key);
            product.selected = !product.selected;
        }
    }



    handlePreviewProductClick(event) {
        const id = event.currentTarget.dataset.id;
        this.previewProductId = this.productList.find(product => product.Id === id).Product2Id;
        this.isPreviewProductModalOpen = true;
    }

    handleClosePreviewProductModal(event) {
        this.isPreviewProductModalOpen = false;
    }



}