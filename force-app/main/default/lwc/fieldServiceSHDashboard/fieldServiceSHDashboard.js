import { LightningElement, track, wire } from 'lwc';
import getWarrantyToOutOfWarranty from '@salesforce/apex/FieldServiceSHDashboardController.getWarrantyToOutOfWarranty';
import getAMCRenewalDueIn60DaysRSMWise from '@salesforce/apex/FieldServiceSHDashboardController.getAMCRenewalDueIn60DaysRSMWise';
import getAMCNotRenewedInLast90DaysRSMWise from '@salesforce/apex/FieldServiceSHDashboardController.getAMCNotRenewedInLast90DaysRSMWise';
import getNonConversionOfWarrantyToAMC from '@salesforce/apex/FieldServiceSHDashboardController.getNonConversionOfWarrantyToAMC';
import getBusinessRevenue from '@salesforce/apex/FieldServiceSHDashboardController.getBusinessRevenue';
import getAMCBusinessChart from '@salesforce/apex/FieldServiceSHDashboardController.getAMCBusinessChart';
import getListOfReturnableSampleQuoteLineItemsSHWise from '@salesforce/apex/FieldServiceSHDashboardController.getListOfReturnableSampleQuoteLineItemsSHWise';







export default class FieldServiceSHDashboard extends LightningElement {

    @track warrantyList = [];
    @track showSpinner = true;
    @track noWarrantyRecords = false;

    @wire(getWarrantyToOutOfWarranty)
    wiredWarrantyInfo({ error, data }) {
        this.showSpinner = false;
        if (data) {
            console.log('Fetched Warranty Data:', JSON.stringify(data));
            // this.warrantyList = data;
            this.warrantyList = data.map(record => ({
                ...record,
                assets: record.assets.map(asset => ({
                    ...asset,
                    warrantyStartDate: this.formatDate(asset.warrantyStartDate),
                    warrantyEndDate: this.formatDate(asset.warrantyEndDate)
                }))
            }));
            this.noWarrantyRecords = data.length === 0;
        } else if (error) {
            // console.error('❌ Error loading warranty data:', error);
            this.noWarrantyRecords = true;
        }
    }

    @track shWiseAssets = [];
    // error;

    @wire(getAMCRenewalDueIn60DaysRSMWise)
    wiredAMCData({ error, data }) {
        if (data) {
            console.log('Fetched AMC Data:', JSON.stringify(data));
            this.shWiseAssets = data.map(rsm => ({
                rsmId: rsm.rsmId,
                rsmName: rsm.rsmName,
                assets: (rsm.assets || []).map(asset => ({
                    assetId: asset.assetId,
                    serialNumber: asset.serialNumber,
                    accountName: asset.accountName,
                    pinCodeName: asset.pinCodeName,
                    amcStartDate: this.formatDate(asset.amcStartDate),
                    amcEndDate: this.formatDate(asset.amcEndDate)
                }))
            }));
            this.showSpinner = false;
            // this.error = undefined;
        } else if (error) {
            // this.error = error;
            this.shWiseAssets = [];
            this.showSpinner = false;
        }
    }

    get hasNoShWiseAssets() {
        return this.shWiseAssets.length === 0;
    }

    formatDate(dateTime) {
        if (!dateTime) return '';
        const date = new Date(dateTime);
        const options = { day: '2-digit', month: 'short', year: 'numeric' };
        return date.toLocaleDateString('en-GB', options);
    }


    @track amcNotRenewedData;
    // @track fetchError;
    hasNoAMCData = false;

    @wire(getAMCNotRenewedInLast90DaysRSMWise)
    wiredNotRenewedAMC({ error, data }) {
        this.showSpinner = false;

        if (data) {
            console.log('Fetched AMC Data:', JSON.stringify(data));
            this.amcNotRenewedData = data.map(record => ({
                ...record,
                assets: record.assets.map(asset => ({
                    ...asset,
                    amcStartDate: this.formatDate(asset.amcStartDate),
                    amcEndDate: this.formatDate(asset.amcEndDate)
                }))
            }));
            // this.amcNotRenewedData = data;
            this.hasNoAMCData = data.length === 0;
            // this.fetchError = undefined;
        } else if (error) {
            // this.fetchError = error.body ? error.body.message : error.message;
            this.hasNoAMCData = false;
            this.amcNotRenewedData = undefined;
        }
    }

    @track rsmWarrantyList;
    @track noWarrantyConversionData = false;

    @wire(getNonConversionOfWarrantyToAMC)
    wiredWarrantyData({ data, error }) {
        this.showSpinner = false;
        if (data) {
            // this.rsmWarrantyList = data;
            this.rsmWarrantyList = data.map(rsm => ({
                ...rsm,
                assets: (rsm.assets || []).map(asset => ({
                    ...asset,
                    warrantyStartDate: this.formatDate(asset.warrantyStartDate),
                    warrantyEndDate: this.formatDate(asset.warrantyEndDate)
                }))
            }));
            this.noWarrantyConversionData = data.length === 0;
        } else if (error) {
            console.error('Error fetching non-converted warranty data:', error);
            this.noWarrantyConversionData = true;
        }
    }

    @track rsmRevenueList = [];
    @track noRevenueData = false;

    @wire(getBusinessRevenue)
    wiredRevenue({ error, data }) {
        this.showSpinner = false;
        if (data) {
            console.log('getBusinessRevenue data-->', data);

            this.rsmRevenueList = data;
            this.noRevenueData = data.length === 0;
        } else if (error) {
            console.error('❌ Error in @wire:', error);
            this.noRevenueData = true;
        }
    }

    @track amcBusinessData = [];
    @track isDataAvailable = false;

    @wire(getAMCBusinessChart)
    wiredData({ error, data }) {
        this.showSpinner = false;

        if (data) {
            console.log('getAMCBusinessChart data-->', data);

            this.amcBusinessData = data;
            this.isDataAvailable = data.length === 0;
        } else if (error) {
            // console.error('Error fetching AMC Business data:', error);
            this.isDataAvailable = true;
        }
    }

    @track returnableQuoteLines = [];
    @track hasNoReturnableQuoteLines = true;
    @wire(getListOfReturnableSampleQuoteLineItemsSHWise)
    wiredReturnableQuoteLines({ error, data }) {
        if (data) {
            console.log('getListOfReturnableSampleQuoteLineItemsSHWise data-->', data);
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