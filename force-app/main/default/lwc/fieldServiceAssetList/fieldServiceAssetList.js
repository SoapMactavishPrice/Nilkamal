import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh, navigateToFilePreview } from 'c/utilJS';

import getAssetsUnderWarrantyOrAMCList from '@salesforce/apex/FieldServiceAssetListController.getAssetsUnderWarrantyOrAMCList';
// import getAssetsUnderAMCList from '@salesforce/apex/FieldServiceAssetListController.getAssetsUnderAMCList';
import getTotalRentalAssets from '@salesforce/apex/FieldServiceAssetListController.getTotalRentalAssets';
import getTotalAssetList from '@salesforce/apex/FieldServiceAssetListController.getTotalAssetList';
import getExpiredAssetList from '@salesforce/apex/FieldServiceAssetListController.getExpiredAssetList';


export default class FieldServiceAssetList extends LightningElement {

    @track isMobile;
    @track isTablet;
    @track isDesktop;


    @track target;


    @track searchString;

    @track datatableData = [];

    @track datatableOffset;
    @track datatableLimit;

    @track datatableSortBy;
    @track datatableSortDirection = 'asc';

    @track datatableIsLoading = false;
    @track datatableHasMoreRecords;



    @track datatableSearchTimeout;




    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.target = currentPageReference.state.c__target;

            if (this.target === 'AssetsUnderWarranty' || this.target === 'AssetsUnderAMC') {
                this.datatableOffset = 0;
                this.datatableLimit = 50;
                this.datatableSortBy = 'name';
                this.datatableSortDirection = 'asc';
                this.datatableHasMoreRecords = true;
                this.handleLoadAssetData(this.searchString, this.datatableOffset, this.datatableLimit, this.datatableSortBy, this.datatableSortDirection);
            }
            else if (this.target === 'RentalAssets') {
                this.datatableOffset = 0;
                this.datatableLimit = 50;
                this.datatableSortBy = 'name';
                this.datatableSortDirection = 'asc';
                this.datatableHasMoreRecords = true;
                this.handleLoadAssetData(this.searchString, this.datatableOffset, this.datatableLimit, this.datatableSortBy, this.datatableSortDirection);
            }
            else if (this.target === 'TotalAsset') {
                this.datatableOffset = 0;
                this.datatableLimit = 50;
                this.datatableSortBy = 'name';
                this.datatableSortDirection = 'asc';
                this.datatableHasMoreRecords = true;
                this.handleLoadAssetData(this.searchString, this.datatableOffset, this.datatableLimit, this.datatableSortBy, this.datatableSortDirection);
            }
            else if (this.target === 'ExpiredAssets') {
                this.datatableOffset = 0;
                this.datatableLimit = 50;
                this.datatableSortBy = 'name';
                this.datatableSortDirection = 'asc';
                this.datatableHasMoreRecords = true;
                this.handleLoadAssetData(this.searchString, this.datatableOffset, this.datatableLimit, this.datatableSortBy, this.datatableSortDirection);
            }
        }
    }



    connectedCallback() {
        analyzeFormFactor(this);
        window.addEventListener('resize', this.calculateHeight.bind(this));
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.calculateHeight.bind(this));
    }

    renderedCallback() {
        analyzeFormFactor(this);
        if (!this.availableHeight) {
            this.calculateHeight();
        }
    }

    calculateHeight() {
        const parentElement = this.template.querySelector('.datatable-container');
        if (!parentElement) return;

        const rect = parentElement.getBoundingClientRect();
        const availableSpace = Math.max(window.innerHeight - rect.top - 20, 300);

        if (this.availableHeight !== availableSpace) {
            this.availableHeight = availableSpace;
            if (this.isMobile) {
                // parentElement.style.height = `${this.availableHeight + 15}px`;
            } else {
                parentElement.style.height = `${this.availableHeight - 5}px`;
            }
            console.log('Updated availableHeight:', this.availableHeight);
        }
    }





    get datatableColumns() {
        if (this.target === 'AssetsUnderWarranty' || this.target === 'AssetsUnderAMC') {
            return [
                { label: 'Serial Number', fieldName: 'assetRecordLink', type: 'url', sortable: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' } }, sortByName: 'Asset__r.Name' },
                { label: 'Customer', fieldName: 'customerRecordList', type: 'url', sortable: true, wrapText: true, typeAttributes: { label: { fieldName: 'accountName' } }, initialWidth: 150, sortByName: 'Asset__r.Account.Name' },
                { label: 'Pincode', fieldName: 'pincode', type: 'text', sortable: false, wrapText: true, sortByName: 'Asset__r.Pin_Code_Master__r.Name' },
                { label: 'Start Date', fieldName: 'startDate', type: 'date', sortable: false, wrapText: true, sortByName: this.target === 'AssetsUnderWarranty' ? 'Warranty_Start_Date__c' : 'AMC_Start_Date__c' },
                { label: 'End Date', fieldName: 'endDate', type: 'date', sortable: false, wrapText: true, sortByName: this.target === 'AssetsUnderWarranty' ? 'Warranty_End_Date__c' : 'AMC_End_Date__c' }
            ];
        }
        else if (this.target === 'RentalAssets') {
            return [
                { label: 'Serial Number', fieldName: 'assetRecordLink', type: 'url', sortable: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' } }, sortByName: 'Asset.Name' },
                // { label: 'Serial Number', fieldName: 'name', type: 'text', sortable: false, wrapText: true, sortByName: 'Asset.Name' },
                { label: 'Customer', fieldName: 'customerRecordList', type: 'url', sortable: true, wrapText: true, typeAttributes: { label: { fieldName: 'accountName' } }, initialWidth: 150, sortByName: 'Asset.Account.Name' },
                { label: 'Pincode', fieldName: 'pincode', type: 'text', sortable: false, wrapText: true, sortByName: 'Asset.Pin_Code_Master__r.Name' }
            ];
        }
        else if (this.target === 'TotalAsset') {
            return [
                { label: 'Serial Number', fieldName: 'assetRecordLink', type: 'url', sortable: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' } }, initialWidth: 100, sortByName: 'Name' },
                { label: 'Customer', fieldName: 'customerRecordList', type: 'url', sortable: true, wrapText: true, typeAttributes: { label: { fieldName: 'accountName' } }, initialWidth: 150, sortByName: 'Account.Name' },
                { label: 'Status', fieldName: 'status', type: 'text', sortable: true, wrapText: true, sortByName: 'Type__c' },
                { label: 'Pincode', fieldName: 'pincode', type: 'text', sortable: true, wrapText: true, sortByName: 'Pin_Code_Master__r.Name' },
                { label: 'Warranty Start Date', fieldName: 'warrantyStartDate', type: 'date', sortable: false, wrapText: true, sortByName: 'Warranty_Start_Date__c' },
                { label: 'Warranty End Date', fieldName: 'warrantyEndDate', type: 'date', sortable: false, wrapText: true, sortByName: 'Warranty_End_Date__c' },
                { label: 'AMC Start Date', fieldName: 'amcStartDate', type: 'date', sortable: false, wrapText: true, sortByName: 'AMC_Start_Date__c' },
                { label: 'AMC End Date', fieldName: 'amcEndDate', type: 'date', sortable: false, wrapText: true, sortByName: 'AMC_End_Date__c' }
            ];
        }
        else if (this.target === 'ExpiredAssets') {
            return [
                { label: 'Serial Number', fieldName: 'assetRecordLink', type: 'url', sortable: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' } }, initialWidth: 100, sortByName: 'Name' },
                { label: 'Customer', fieldName: 'customerRecordList', type: 'url', sortable: true, wrapText: true, typeAttributes: { label: { fieldName: 'accountName' } }, initialWidth: 150, sortByName: 'Account.Name' },
                { label: 'Status', fieldName: 'status', type: 'text', sortable: true, wrapText: true, sortByName: 'Type__c' },
                { label: 'Pincode', fieldName: 'pincode', type: 'text', sortable: true, wrapText: true, sortByName: 'Pin_Code_Master__r.Name' },
                { label: 'Warranty Start Date', fieldName: 'warrantyStartDate', type: 'date', sortable: false, wrapText: true, sortByName: 'Warranty_Start_Date__c' },
                { label: 'Warranty End Date', fieldName: 'warrantyEndDate', type: 'date', sortable: false, wrapText: true, sortByName: 'Warranty_End_Date__c' },
                { label: 'AMC Start Date', fieldName: 'amcStartDate', type: 'date', sortable: false, wrapText: true, sortByName: 'AMC_Start_Date__c' },
                { label: 'AMC End Date', fieldName: 'amcEndDate', type: 'date', sortable: false, wrapText: true, sortByName: 'AMC_End_Date__c' }
            ];
        }
    }



    handleLoadMoreData(event) {
        if (!this.datatableHasMoreRecords) {
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
                console.log('load data started loading');
            }
        }
        this.datatableIsLoading = true;

        this.datatableOffset += this.datatableLimit;
        this.handleLoadAssetData(this.searchString, this.datatableOffset, this.datatableLimit, this.datatableSortBy, this.datatableSortDirection);
    }



    handleLoadAssetData(searchString, offset = 0, lmt = this.datatableLimit, sortBy, sortDirection = 'asc') {
        sortBy = sortBy ? this.datatableColumns.find(column => column.fieldName === sortBy || column?.typeAttributes?.label?.fieldName === sortBy)?.sortByName : 'Asset.Name';
        this.datatableIsLoading = true;

        const handleData = (data, mapFunction) => {
            this.datatableHasMoreRecords = data.length >= lmt;
            const mappedDataList = data.map(mapFunction);
            console.log('mappedDataList', mappedDataList);
            this.datatableData = offset === 0 ? mappedDataList : [...this.datatableData, ...mappedDataList];
        };

        const handleError = (error) => {
            console.log(error);
            showToast(this, 'Error', 'Error occurred while fetching assets', 'error', error);
        };

        const finalizeLoading = () => {
            const datatable = this.template.querySelector('lightning-datatable');
            if (datatable) datatable.isLoading = false;
            this.datatableIsLoading = false;
        };

        if (this.target === 'AssetsUnderWarranty' || this.target === 'AssetsUnderAMC') {
            getAssetsUnderWarrantyOrAMCList({ searchString, target: this.target, offset, lmt, sortBy, sortDirection })
                .then(data => handleData(data, assetWarrantyOrAMC => {
                    const { Asset__r: asset } = assetWarrantyOrAMC;
                    return {
                        id: assetWarrantyOrAMC.Id,
                        name: asset?.Name,
                        assetId: assetWarrantyOrAMC?.Asset__c,
                        accountId: asset?.AccountId,
                        accountName: asset?.Account?.Name,
                        startDate: this.target === 'AssetsUnderWarranty' ? assetWarrantyOrAMC?.Warranty_Start_Date__c : assetWarrantyOrAMC?.AMC_Start_Date__c,
                        endDate: this.target === 'AssetsUnderWarranty' ? assetWarrantyOrAMC?.Warranty_End_Date__c : assetWarrantyOrAMC?.AMC_End_Date__c,
                        pincode: asset?.Pin_Code_Master__r?.Name,
                        assetRecordLink: assetWarrantyOrAMC?.Asset__c ? `/lightning/r/${assetWarrantyOrAMC?.Asset__c}/view` : '',
                        customerRecordList: asset?.AccountId ? `/lightning/r/${asset?.AccountId}/view` : ''
                    };
                }))
                .catch(handleError)
                .finally(finalizeLoading);
        }
        else if (this.target === 'RentalAssets') {
            getTotalRentalAssets({ searchString, target: this.target, offset, lmt, sortBy, sortDirection })
                .then(data => handleData(data, asset => {
                    console.log('data', data);
                    console.log('asset', asset.Name);
                    return {
                        id: asset?.Id,
                        name: asset?.Name,
                        assetId: asset?.Asset__c,
                        accountId: asset?.AccountId,
                        accountName: asset?.Account?.Name,
                        pincode: asset?.Pin_Code_Master__r?.Name,
                        assetRecordLink: asset?.Id ? `/lightning/r/${asset?.Id}/view` : '',
                        customerRecordList: asset?.AccountId ? `/lightning/r/${asset?.AccountId}/view` : ''
                    };

                }))
                .catch(handleError)
                .finally(finalizeLoading);
        }
        else if (this.target === 'TotalAsset') {
            getTotalAssetList({ searchString, offset, lmt, sortBy, sortDirection })
                .then(data => handleData(data, asset => {
                    const { Asset_Warranty__r: assetWarranty = {}, Asset_AMCs__r: assetAMC = {} } = asset;
                    const warranty = Array.isArray(assetWarranty) && assetWarranty.length ? assetWarranty[0] : assetWarranty;
                    const amc = Array.isArray(assetAMC) && assetAMC.length ? assetAMC[0] : assetAMC;
                    return {
                        id: asset?.Id,
                        name: asset?.Name,
                        status: asset?.Type__c,
                        accountId: asset?.AccountId,
                        accountName: asset?.Account?.Name,
                        pincode: asset?.Pin_Code_Master__r?.Name,
                        warrantyStartDate: warranty?.Warranty_Start_Date__c,
                        warrantyEndDate: warranty?.Warranty_End_Date__c,
                        amcStartDate: amc?.AMC_Start_Date__c,
                        amcEndDate: amc?.AMC_End_Date__c,
                        assetRecordLink: asset?.Id ? `/lightning/r/${asset?.Id}/view` : '',
                        customerRecordList: asset?.AccountId ? `/lightning/r/${asset?.AccountId}/view` : ''
                    };
                }))
                .catch(handleError)
                .finally(finalizeLoading);
        }
        else if (this.target === 'ExpiredAssets') {
            getExpiredAssetList({ searchString, offset, lmt, sortBy, sortDirection })
                .then(data => handleData(data, asset => {
                    const { Asset_Warranty__r: assetWarranty = {}, Asset_AMCs__r: assetAMC = {} } = asset;
                    const warranty = Array.isArray(assetWarranty) && assetWarranty.length ? assetWarranty[0] : assetWarranty;
                    const amc = Array.isArray(assetAMC) && assetAMC.length ? assetAMC[0] : assetAMC;
                    console.log('handleData', data);
                    return {
                        id: asset?.Id,
                        name: asset?.Name,
                        status: asset?.Type__c,
                        accountId: asset?.AccountId,
                        accountName: asset?.Account?.Name,
                        pincode: asset?.Pin_Code_Master__r?.Name,
                        warrantyStartDate: warranty?.Warranty_Start_Date__c,
                        warrantyEndDate: warranty?.Warranty_End_Date__c,
                        amcStartDate: amc?.AMC_Start_Date__c,
                        amcEndDate: amc?.AMC_End_Date__c,
                        assetRecordLink: asset?.Id ? `/lightning/r/${asset?.Id}/view` : '',
                        customerRecordList: asset?.AccountId ? `/lightning/r/${asset?.AccountId}/view` : ''
                    };
                }))
                .catch(handleError)
                .finally(finalizeLoading);
        }
    }





    datatableHandleSort(event) {
        this.datatableSortBy = event.detail.fieldName;
        this.datatableSortDirection = event.detail.sortDirection;
        this.datatableOffset = 0;
        this.datatableHasMoreRecords = true;
        const datatable = this.template.querySelector('lightning-datatable');
        if (datatable) {
            datatable.isLoading = true;
        }
        this.datatableIsLoading = true;
        this.handleLoadAssetData(this.searchString, this.datatableOffset, this.datatableLimit, this.datatableSortBy, this.datatableSortDirection);
    }



    handleDatatableSearch(event) {
        this.searchString = event.detail.value;
        if (this.datatableSearchTimeout) {
            clearTimeout(this.datatableSearchTimeout);
            this.datatableSearchTimeout = null;
        }
        this.datatableSearchTimeout = setTimeout(() => {
            this.datatableOffset = 0;
            this.datatableHasMoreRecords = true;
            const datatable = this.template.querySelector('lightning-datatable');
            if (datatable) {
                datatable.isLoading = true;
            }
            this.datatableIsLoading = true;
            this.handleLoadAssetData(this.searchString, this.datatableOffset, this.datatableLimit, this.datatableSortBy, this.datatableSortDirection);
        }, 300);
    }



}