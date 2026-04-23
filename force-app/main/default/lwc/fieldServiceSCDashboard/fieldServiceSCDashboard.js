import { LightningElement, wire, track } from 'lwc';
import getNewCaseToAssign from '@salesforce/apex/FieldServiceSCDashboardController.getNewCaseToAssign';
import getReassignCaseIfEngineerIsOnLeave from '@salesforce/apex/FieldServiceSCDashboardController.getReassignCaseIfEngineerIsOnLeave';
import getWarrantyToOutOfWarrantyRSMWise from '@salesforce/apex/FieldServiceSCDashboardController.getWarrantyToOutOfWarrantyRSMWise';
import getAMCRenewalRSMWiseInNext60Days from '@salesforce/apex/FieldServiceSCDashboardController.getAMCRenewalRSMWiseInNext60Days';
import getOpenCasesForMoreThan4Days from '@salesforce/apex/FieldServiceSCDashboardController.getOpenCasesForMoreThan4Days';
import getLast7DaysCaseHistory from '@salesforce/apex/FieldServiceSCDashboardController.getLast7DaysCaseHistory';
import getReassignedRequestCases from '@salesforce/apex/FieldServiceSCDashboardController.getReassignedRequestCases';
import getProductsWithMissingLeadTime from '@salesforce/apex/FieldServiceSCDashboardController.getProductsWithMissingLeadTime';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import PRODUCT_OBJECT from '@salesforce/schema/Product2';
import BUSINESS_VERTICAL_FIELD from '@salesforce/schema/Product2.Business_Vertical__c';
import getPendingOrders from '@salesforce/apex/FieldServiceSCDashboardController.getPendingOrders';
import getListOfReturnableSampleQuoteLineItemsSCWise from '@salesforce/apex/FieldServiceSCDashboardController.getListOfReturnableSampleQuoteLineItemsSCWise';




export default class FieldServiceSCDashboard extends LightningElement {
    @track showSpinner = true;


    @track newCases = [];

    @wire(getNewCaseToAssign)
    wiredNewCases({ error, data }) {
        if (data) {
            console.log('Fetched New Case to Assign Data:', JSON.stringify(data));
            this.newCases = data.map(caseData => ({
                id: caseData.id,
                caseNumber: caseData.caseNumber,
                accountName: caseData.accountName,
                createdDate: new Date(caseData.createdDate).toLocaleDateString(),
                pincode: caseData.pincode,
                pincodeName: caseData.pincodeName,
                type: caseData.type
            }));
            this.showSpinner = false;
        } else if (error) {
            console.error('Error fetching new cases to assign:', error);
            this.showSpinner = false;
        }
    }
    @track casesToReassign = [];

    @wire(getReassignCaseIfEngineerIsOnLeave)
    wiredCasesToReassign({ error, data }) {
        if (data) {
            console.log('Fetched Cases to Reassign Data:', JSON.stringify(data));
            this.casesToReassign = data.map(caseData => ({
                id: caseData.id,
                caseNumber: caseData.caseNumber,
                ownerName: caseData.ownerName,
                pincode: caseData.pincode,
                pincodeName: caseData.pincodeName
            }));
            this.showSpinner = false;
        } else if (error) {
            console.error('Error fetching cases to reassign:', error);
            this.showSpinner = false;
        }
    }

    // @track warrantyToOutOfWarrantyRSMWise = [];
    // @wire(getWarrantyToOutOfWarrantyRSMWise)
    // wiredWarrantyToOutOfWarrantyRSMWise({ error, data }) {
    //     if (data) {
    //         console.log('Fetched Cases to Out of Warranty Data:', JSON.stringify(data));
    //         this.warrantyToOutOfWarrantyRSMWise = data.map(caseData => ({
    //             id: caseData.id,
    //             caseNumber: caseData.caseNumber,
    //             ownerName: caseData.ownerName,
    //             pincode: caseData.pincode,    
    //             pincodeName: caseData.pincodeName
    //         }));
    //     } else if (error) {
    //         console.error('Error fetching cases to Out of Warranty:', error);
    //     }
    // }

    @track rsmWiseAssetsWarranty = [];

    @wire(getWarrantyToOutOfWarrantyRSMWise)
    wiredWarrantyData({ error, data }) {
        if (data) {
            console.log('Fetched Warranty to Out of Warranty Data:', JSON.stringify(data));
            this.rsmWiseAssetsWarranty = data.map(rsm => ({
                rsmId: rsm.rsmId,
                rsmName: rsm.rsmName,
                assets: rsm.assets.map(asset => ({
                    assetId: asset.assetId,
                    serialNumber: asset.serialNumber,
                    accountName: asset.accountName,
                    pinCodeName: asset.pinCodeName,
                    serviceResourceName: asset.serviceResourceName,
                    warrantyStartDate: this.formatDateTime(asset.warrantyStartDate),
                    warrantyEndDate: this.formatDateTime(asset.warrantyEndDate)
                }))
            }));
            this.showSpinner = false;
        } else if (error) {
            console.error('Error fetching warranty to out of warranty data:', error);
            this.showSpinner = false;
        }
    }

    @track rsmWiseAssets = [];
    error;

    @wire(getAMCRenewalRSMWiseInNext60Days)
    wiredData({ error, data }) {
        if (data) {
            console.log('Fetched AMC to Out of AMC Data:', JSON.stringify(data));
            this.rsmWiseAssets = data.map(rsm => ({
                rsmId: rsm.rsmId,
                rsmName: rsm.rsmName,
                assets: rsm.assets.map(asset => ({
                    assetId: asset.assetId,
                    serialNumber: asset.serialNumber,
                    accountName: asset.accountName,
                    pinCodeName: asset.pinCodeName,
                    amcStartDate: this.formatDateTime(asset.amcStartDate),
                    amcEndDate: this.formatDateTime(asset.amcEndDate)
                }))
            }));
            this.showSpinner = false;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.rsmWiseAssets = [];
            this.showSpinner = false;
        }
    }

    formatDate(date) {
        if (!date) return '';
        return new Date(date).toLocaleDateString();
    }

    @track cases = [];

    @wire(getOpenCasesForMoreThan4Days)
    wiredCases({ error, data }) {
        if (data) {
            console.log('Fetched Cases Data:', JSON.stringify(data));
            this.cases = data.map(caseData => ({
                id: caseData.id,
                caseNumber: caseData.caseNumber,
                accountName: caseData.accountName,
                serialNumber: caseData.serialNumber,
                pinCodeName: caseData.pinCodeName,
                createdDate: this.formatDateTime(caseData.createdDate),
                assignedToName: caseData.assignedToName,
                assignedDateTime: this.formatDateTime(caseData.assignedDateTime)
            }));
            this.error = undefined;
            this.showSpinner = false;
        } else if (error) {
            this.error = error;
            this.cases = [];
            this.showSpinner = false;
        }
    }

    // formatDate(date) {
    //     if (!date) return '';
    //     return new Date(date).toLocaleDateString();
    // }

    formatDateTime(dateTime) {
        // if (!dateTime) return '';
        // return new Date(dateTime).toLocaleString();
        if (!dateTime) return '';
        const date = new Date(dateTime);
        const options = { day: '2-digit', month: 'short', year: 'numeric' };
        return date.toLocaleDateString('en-GB', options);
    }

    @track caseHistory;


    @wire(getLast7DaysCaseHistory)
    wiredCaseHistory({ error, data }) {
        console.log('getLast7DaysCaseHistory', data);
        if (data) {
            this.caseHistory = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.caseHistory = undefined;
        }
    }

    get hasNoNewCases() {
        return !this.newCases || this.newCases.length === 0;
    }

    get hasNoCasesToReassign() {
        return !this.casesToReassign || this.casesToReassign.length === 0;
    }

    get hasNoRsmWiseAssetsWarranty() {
        return this.rsmWiseAssetsWarranty.length === 0;
    }

    get hasNoRsmWiseAssets() {
        return this.rsmWiseAssets.length === 0;
    }
    get hasNoCases() {
        return this.cases.length === 0;
    }


    @track reassignedRequests = [];
    // @track showSpinner = true;
    @track hasNoRequests = false;
    // @track url = window.location.origin + '/';

    @wire(getReassignedRequestCases)
    wiredReassignedRequests({ error, data }) {
        this.showSpinner = false;
        if (data) {
            this.reassignedRequests = data;
            this.hasNoRequests = data.length === 0;
        } else if (error) {
            console.error('Error loading reassigned requests:', error);
            this.hasNoRequests = true;
        }
    }


    @track products = [];
    @track hasNoProducts = false;
    // @track selectedBusinessVertical = '';
    // @track businessVerticalOptions = [];

    // @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT })
    // productObjectInfo;

    // @wire(getPicklistValues, {
    //     recordTypeId: '$productObjectInfo.data.defaultRecordTypeId',
    //     fieldApiName: BUSINESS_VERTICAL_FIELD
    // })
    // loadBusinessVerticalPicklist({ data, error }) {
    //     if (data) {
    //         this.businessVerticalOptions = data.values.map(item => ({
    //             label: item.label,
    //             value: item.value
    //         }));
    //         this.businessVerticalOptions.unshift({ label: 'All Business Verticals', value: '' });
    //     } else if (error) {
    //         console.error('Error loading business vertical picklist:', error);
    //     }
    // }

    @wire(getProductsWithMissingLeadTime)
    wiredProducts({ error, data }) {
        this.showSpinner = false;
        if (data) {
            console.log('Fetched Products Data:', JSON.stringify(data));
            this.products = data;
            this.hasNoProducts = data.length === 0;
            if (data.length > 0) {
                this.userBusinessUnit = data[0].businessVertical;
            }
        } else if (error) {
            console.error('Error loading products:', error);
            this.hasNoProducts = true;
            // this.dispatchEvent(
            //     new ShowToastEvent({
            //         title: 'Error loading products',
            //         message: error.body.message,
            //         variant: 'error'
            //     })
            // );
        }
    }

    // handleBusinessVerticalChange(event) {
    //     this.showSpinner = true;
    //     this.selectedBusinessVertical = event.detail.value;
    // }


    @track pendingOrders = [];
    @track hasNoOrders = false;

    @wire(getPendingOrders)
    wiredOrders({ error, data }) {
        this.showSpinner = false;
        if (data) {
            console.log('orders', data);
            this.pendingOrders = data.map(order => ({
                id: order.Id,
                name: order.Name,
                saleOrderNumber: order.Sale_Order_Number__c,
                customerPurchaseOrderDate: order.Customer_Purchase_Order_Date__c,
                customerId: order.Customer_Name__c,
                customerName: order.Customer_Name__r?.Name,
                conditionValue: order.Conditon_value__c,
                deliveryStatus: order.Delivery_Status__c
            }));
            this.hasNoOrders = this.pendingOrders.length === 0;
        } else if (error) {
            this.error = error;
            this.hasNoOrders = true;
            // this.showToast('Error', error.body?.message || 'Failed to load pending orders', 'error');
        }
    }


    @track returnableQuoteLines = [];
    @track hasNoReturnableQuoteLines = true;
    @wire(getListOfReturnableSampleQuoteLineItemsSCWise)
    wiredReturnableQuoteLines({ error, data }) {
        if (data) {
            console.log('getListOfReturnableSampleQuoteLineItemsSCWise data-->', data);
            this.returnableQuoteLines = data.map(returnableQuoteLine => ({
                customerName: returnableQuoteLine?.Quote?.Account?.Name,
                materialCode: returnableQuoteLine?.Product2?.Name,
                materialDescription: returnableQuoteLine?.Product2?.Description,
                quantity: returnableQuoteLine?.Quantity,
                amount: returnableQuoteLine?.Grand_Price__c,
                ownerName: returnableQuoteLine?.Quote?.Opportunity?.Owner?.Name
            }))
            this.showSpinner = false;
            this.hasNoReturnableQuoteLines = !data || Object.keys(data).length === 0;
        } else if (error) {
            console.error('Error fetching returnable quote lines:', error);
            this.showSpinner = false;
            this.hasNoReturnableQuoteLines = true;
        }
    }



}