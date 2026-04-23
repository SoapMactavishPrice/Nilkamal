import { LightningElement, track, wire } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

import ASSET_OBJECT from '@salesforce/schema/Asset';
import CUSTOMER_FIELD from '@salesforce/schema/Asset.AccountId';
import SHIP_TO_FIELD from '@salesforce/schema/Asset.End_Customer__c';

import { showToast, getNameAndValueOnChange, analyzeFormFactor, analyzeUserAgent, enablePullToRefresh, disablePullToRefresh, navigateToRecord } from 'c/utilJS';


import getAssetDetails from '@salesforce/apex/fieldServiceTransferAssetController.getAssetDetails';
import getCustomerDetails from '@salesforce/apex/fieldServiceTransferAssetController.getCustomerDetails';
import getContactDetails from '@salesforce/apex/fieldServiceTransferAssetController.getContactDetails';
import getAccContactDetails from '@salesforce/apex/fieldServiceTransferAssetController.getAccContactDetails';

import updateAsset from '@salesforce/apex/fieldServiceTransferAssetController.updateAsset';



export default class FieldServiceTransferAsset extends NavigationMixin(LightningElement) {
    @track showSpinner;


    @track AssetId;

    @track AccountId;
    @track End_Customer__c;

    @track New_AccountId;
    @track New_End_Customer__c;

    @track New_ContactId;


    @track addressDetails = {
        AccountId: null,
        End_Customer__c: null,
        New_AccountId: null,
        New_End_Customer__c: null,
        New_ContactId: null
    };



    /*
    @track BillToSAPCustomerCode = '';
    @track BillToAddress = '';
    @track BillToCity = '';
    @track BillToRegion = '';
    @track BillToPin = '';
    @track BillToCountry = '';

    @track ShipToSAPCustomerCode = '';
    @track ShipToAddress = '';
    @track ShipToCity = '';
    @track ShipToRegion = '';
    @track ShipToPin = '';
    @track ShipToCountry = '';


    @track BillToTransferSAPCustomerCode = '';
    @track BillToTransferAddress = '';
    @track BillToTransferCity = '';
    @track BillToTransferRegion = '';
    @track BillToTransferPin = '';
    @track BillToTransferCountry = '';

    @track ShipToTransferSAPCustomerCode = '';
    @track ShipToTransferAddress = '';
    @track ShipToTransferCity = '';
    @track ShipToTransferRegion = '';
    @track ShipToTransferPin = '';
    @track ShipToTransferCountry = '';
    */



    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.AssetId = null;
            this.AccountId = null;
            this.End_Customer__c = null;
            this.ContactId = null;
            this.New_AccountId = null;
            this.New_End_Customer__c = null;
            this.New_ContactId = null;

            const RecordPickers = this.template.querySelectorAll('lightning-record-picker');
            for (const recordPicker of RecordPickers) {
                recordPicker.value = null;
            }
            this.addressDetails = {
                AccountId: null,
                End_Customer__c: null,
                New_AccountId: null,
                New_End_Customer__c: null
            };

            this.AssetId = currentPageReference.state.c__assetId;
            this.handleGetAssetDetails();
        }
    }

    connectedCallback() {
        analyzeFormFactor(this);
        analyzeUserAgent(this);
        enablePullToRefresh(this);
    }

    disconnectedCallback() {
        disablePullToRefresh();
    }


    handleFieldChange(event) {
        const { name, value } = getNameAndValueOnChange(this, event);
        this[name] = value;

        try {
            event.target.checkValidity();
            event.target.reportValidity();
        } catch (error) {
            console.log('Validation error:', error);
        }

        switch (name) {
            case 'AssetId':
                this.resetAccountAndCustomerDetails();
                this.handleGetAssetDetails();
                break;
            case 'New_AccountId':
                this.resetNewAccountDetails();
                this.handleGetCustomerDetails(value);
                break;
            case 'New_End_Customer__c':
                this.addressDetails.New_End_Customer__c = {};
                this.handleGetCustomerDetails(value);
                break;
            case 'New_ContactId':
                this.addressDetails.New_ContactId = {};
                this.handleGetContactDetails(value);
                break;
        }
    }

    resetAccountAndCustomerDetails() {
        this.AccountId = null;
        this.End_Customer__c = null;
        this.ContactId = null;

        this.New_AccountId = null;
        this.New_End_Customer__c = null;
        this.New_ContactId = null;

        this.addressDetails.AccountId = null;
        this.addressDetails.End_Customer__c = null;
        this.addressDetails.New_ContactId = null;
        this.addressDetails.New_AccountId = null;
        this.addressDetails.New_End_Customer__c = null;
        this.addressDetails.New_ContactId = null;
    }

    resetNewAccountDetails() {
        this.addressDetails.New_AccountId = {};
        this.New_ContactId = null;
        this.addressDetails.New_ContactId = null;
    }


    handleGetAssetDetails() {
        if (!this.AssetId) return;

        getAssetDetails({ assetId: this.AssetId })
            .then(result => {
                if (!result) return;

                console.log('Asset Details:', result);

                this.AccountId = result.AccountId;
                this.End_Customer__c = result.End_Customer__c;
                this.ContactId = result.ContactId;

                this.addressDetails.AccountId = {};
                this.addressDetails.AccountId.customerCode = result.Bill_to_Customer_Code__c;
                this.addressDetails.AccountId.address = result.Bill_to_Address__c;
                this.addressDetails.AccountId.city = result.Bill_to_City__c;
                this.addressDetails.AccountId.region = result.Bill_to_Region__c;
                this.addressDetails.AccountId.pinCode = result.Bill_to_Pin__c;
                this.addressDetails.AccountId.country = result.Bill_to_Country__c;

                this.addressDetails.End_Customer__c = {};
                this.addressDetails.End_Customer__c.customerCode = result.Ship_to_Customer_Code__c;
                this.addressDetails.End_Customer__c.address = result.Ship_to_Address__c;
                this.addressDetails.End_Customer__c.city = result.Ship_to_City__c;
                this.addressDetails.End_Customer__c.region = result.Ship_to_Region__c;
                this.addressDetails.End_Customer__c.pinCode = result.Ship_to_Pin__c;
                this.addressDetails.End_Customer__c.country = result.Ship_to_Country__c;

                this.addressDetails.ContactId = {};
                this.addressDetails.ContactId.mobilePhone = result.Contact?.MobilePhone;
                this.addressDetails.ContactId.email = result.Contact?.Email;
            })
            .catch((error) => {
                console.log('Error fetching Asset details:', error);
                showToast(this, 'Error', 'Failed to fetch Asset details.', 'error', error);
            });
    }


    handleGetCustomerDetails(accountId) {
        if (!accountId) return;

        getCustomerDetails({ accountId })
            .then(result => {
                console.log('Customer Details:', result);
                const { Id, Name, SAP_Customer_code__c, Street_House_Number__c, Street1__c, Street2__c, City__c, State__c, Postal_code__c, Country__c } = result;
                if (this.New_AccountId === Id) {
                    this.addressDetails.New_AccountId = {};
                    this.addressDetails.New_AccountId.customerCode = SAP_Customer_code__c;
                    this.addressDetails.New_AccountId.address = Street_House_Number__c + ' ' + Street1__c + ' ' + Street2__c;
                    this.addressDetails.New_AccountId.city = City__c;
                    this.addressDetails.New_AccountId.region = State__c;
                    this.addressDetails.New_AccountId.pinCode = Postal_code__c;
                    this.addressDetails.New_AccountId.country = Country__c;
                    console.log('Acc:', Name);
                    this.handleAccountGetContactDetails(Id);
                }
                if (this.New_End_Customer__c === Id) {
                    this.addressDetails.New_End_Customer__c = {};
                    this.addressDetails.New_End_Customer__c.customerCode = SAP_Customer_code__c;
                    this.addressDetails.New_End_Customer__c.address = Street_House_Number__c + ' ' + Street1__c + ' ' + Street2__c;
                    this.addressDetails.New_End_Customer__c.city = City__c;
                    this.addressDetails.New_End_Customer__c.region = State__c;
                    this.addressDetails.New_End_Customer__c.pinCode = Postal_code__c;
                    this.addressDetails.New_End_Customer__c.country = Country__c;
                }
            })
            .catch((error) => {
                console.log('Error fetching Customer details:', error);
                showToast(this, 'Error', 'Failed to fetch Customer details.', 'error', error);
            });
    }


    handleGetContactDetails(contactId) {
        if (!contactId) return;

        getContactDetails({ contactId })
            .then(result => {
                console.log('Contact Details:', result);
                const { MobilePhone, Email } = result;
                this.addressDetails.New_ContactId = {};
                this.addressDetails.New_ContactId.mobilePhone = MobilePhone;
                this.addressDetails.New_ContactId.email = Email;
            })
            .catch((error) => {
                console.log('Error fetching Contact details:', error);
                showToast(this, 'Error', 'Failed to fetch Contact details.', 'error', error);
            });
    }

    handleAccountGetContactDetails(accId) {
        if (!accId) return;

        console.log('Acc Id', accId);
        getAccContactDetails({ accId })
            .then(result => {
                console.log('Contact Details:', result);
                const { Id, MobilePhone, Email } = result;
                this.addressDetails.New_ContactId = {};
                this.New_ContactId=Id;
                this.addressDetails.New_ContactId.mobilePhone = MobilePhone;
                this.addressDetails.New_ContactId.email = Email;
            })
            .catch((error) => {
                console.log('Error fetching Contact details:', error);
                console.log('Error 2:', error.body.message);
                if(error.body.message=='List has no rows for assignment to SObject')
                {
                    showToast(this, 'Error', 'Failed to fetch Contact details.', 'error', 'Customer has no contact');
                }
                else{
                    showToast(this, 'Error', 'Failed to fetch Contact details.', 'error', error);
                }                
            });
    }


    handleSave(event) {
        const validateField = (fieldName, errorMessage) => {
            const field = this.template.querySelector(`lightning-record-picker[data-name="${fieldName}"]`);
            if (!this[fieldName]) {
                if (field) {
                    field.checkValidity();
                    field.reportValidity();
                } else {
                    showToast(this, 'Error', errorMessage, 'error');
                }
                return false;
            }
            return true;
        };

        const isValid = [
            validateField('AssetId', 'Please select an Asset.'),
            validateField('New_AccountId', 'Please select a Customer.'),
            validateField('New_End_Customer__c', 'Please select a Ship To.'),
            validateField('New_ContactId', 'Please select a Contact.')
        ].every(Boolean);

        if (!isValid) return;


        const assetRecord = {
            Id: this.AssetId,
            AccountId: this.New_AccountId,
            End_Customer__c: this.New_End_Customer__c,
            ContactId: this.New_ContactId,

            Bill_to_Customer_Code__c: this.addressDetails.New_AccountId.customerCode ? this.addressDetails.New_AccountId.customerCode : '',
            Bill_to_Address__c: this.addressDetails.New_AccountId.address ? this.addressDetails.New_AccountId.address : '',
            Bill_to_City__c: this.addressDetails.New_AccountId.city ? this.addressDetails.New_AccountId.city : '',
            Bill_to_Region__c: this.addressDetails.New_AccountId.region ? this.addressDetails.New_AccountId.region : '',
            Bill_to_Pin__c: this.addressDetails.New_AccountId.pinCode ? this.addressDetails.New_AccountId.pinCode : '',
            Bill_to_Country__c: this.addressDetails.New_AccountId.country ? this.addressDetails.New_AccountId.country : '',

            Ship_to_Customer_Code__c: this.addressDetails.New_End_Customer__c.customerCode ? this.addressDetails.New_End_Customer__c.customerCode : '',
            Ship_to_Address__c: this.addressDetails.New_End_Customer__c.address ? this.addressDetails.New_End_Customer__c.address : '',
            Ship_to_City__c: this.addressDetails.New_End_Customer__c.city ? this.addressDetails.New_End_Customer__c.city : '',
            Ship_to_Region__c: this.addressDetails.New_End_Customer__c.region ? this.addressDetails.New_End_Customer__c.region : '',
            Ship_to_Pin__c: this.addressDetails.New_End_Customer__c.pinCode ? this.addressDetails.New_End_Customer__c.pinCode : '',
            Ship_to_Country__c: this.addressDetails.New_End_Customer__c.country ? this.addressDetails.New_End_Customer__c.country : ''
        };

        this.showSpinner = true;
        updateAsset({ assetRecord: assetRecord })
            .then(() => {
                showToast(this, 'Success', 'Asset transfer completed successfully.', 'success');

                navigateToRecord(this, this.AssetId);
            })
            .catch((error) => {
                console.log('Error updating Asset:', JSON.stringify(error));
                showToast(this, 'Error', 'Failed to transfer Asset.', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }









    get assetBySerialDisplayInfo() {
        return {
            primaryField: 'SerialNumber',
            additionalFields: ['Invoice_Number__c']
        };
    }

    get assetBySerialMatchingInfo() {
        return {
            primaryField: { fieldPath: 'SerialNumber' },
            additionalFields: [{ fieldPath: 'Invoice_Number__c' }]
        };
    }



    get accountDisplayInfo() {
        return {
            primaryField: 'Name',
            additionalFields: ['Customer_Code_City__c']
        };
    }

    get accountMatchingInfo() {
        return {
            primaryField: { fieldPath: 'Name' },
            additionalFields: [{ fieldPath: 'Customer_Code_City__c' }]
        };
    }



    get contactDisplayInfo() {
        return {
            primaryField: 'Name',
            additionalFields: ['Email']
        };
    }

    get contactMatchingInfo() {
        return {
            primaryField: { fieldPath: 'Name' },
            additionalFields: [{ fieldPath: 'Email' }]
        };
    }

    get contactFilterInfo() {
        return {
            criteria: [
                {
                    fieldPath: 'AccountId',
                    operator: 'eq',
                    value: this.New_AccountId
                }
            ]
        };
    }

}