import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference, GenerateUrl } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue, createRecord } from 'lightning/uiRecordApi';
import LightningAlert from 'lightning/alert';

import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';

import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, scrollToTop, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh } from 'c/utilJS';

import Id from '@salesforce/user/Id';

import getUserDetails from '@salesforce/apex/UtilityCls.getUserDetails';

import addNewContactModal from 'c/fieldServiceCreateContact';


import CaseObject from '@salesforce/schema/Case';
import AssetObject from '@salesforce/schema/Asset';

import CaseField_Asset from '@salesforce/schema/Case.AssetId';
import CaseField_Account from '@salesforce/schema/Case.AccountId';
import CaseField_Contact from '@salesforce/schema/Case.ContactId';
import CaseField_Division from '@salesforce/schema/Case.Division__c';
import CaseField_CaseType from '@salesforce/schema/Case.Type';
import CaseField_CaseSubType from '@salesforce/schema/Case.Case_Sub_Type__c'
// import CaseField_Reason from '@salesforce/schema/Case.Case_Reason__c';
// import CaseField_CurrencyIsoCode from '@salesforce/schema/Case.CurrencyIsoCode';
import CaseField_CasePincode from '@salesforce/schema/Case.Case_Pincode__c';
import CaseField_CaseTerritory from '@salesforce/schema/Case.Case_Territory__c';
// import CaseField_AssignTo from '@salesforce/schema/Case.Assign_To__c';
// import CaseField_ReAssignTo from '@salesforce/schema/Case.Re_Assign_To__c';
import CaseField_Owner from '@salesforce/schema/Case.OwnerId';
import CaseField_CreatedDate from '@salesforce/schema/Case.CreatedDate';
import CaseField_CaseOrigin from '@salesforce/schema/Case.Origin';
import CaseField_CaseStatus from '@salesforce/schema/Case.Status';
import CaseField_CasePriority from '@salesforce/schema/Case.Priority';
// import CaseField_CaseSubject from '@salesforce/schema/Case.Subject';
import CaseField_CaseDescription from '@salesforce/schema/Case.Description';
// import CaseField_Comments from '@salesforce/schema/Case.Comments';
import CaseField_CaseNotifiedBy from '@salesforce/schema/Case.Case_Notified_By__c';
import CaseField_CaseRaiseByEngineer from '@salesforce/schema/Case.Case_Raise_By_Engineer__c';
// import CaseField_AssetCategory from '@salesforce/schema/Case.Asset_Category__c';

import AssetField_AssetCategory from '@salesforce/schema/Asset.Asset_Category__c';
import AssetField_AssetType from '@salesforce/schema/Asset.Type__c';
import AssetField_Account from '@salesforce/schema/Asset.AccountId';
import AssetField_Contact from '@salesforce/schema/Asset.ContactId';
import AssetField_BusinessVertical from '@salesforce/schema/Asset.Business_Vertical__c';
import AssetField_Pincode from '@salesforce/schema/Asset.Pin_Code_Master__c';
import AssetField_Territory from '@salesforce/schema/Asset.Territory_Master__c';

import AccountField_Street from '@salesforce/schema/Account.Street_House_Number__c';
import AccountField_Street1 from '@salesforce/schema/Account.Street1__c';
import AccountField_Street2 from '@salesforce/schema/Account.Street2__c';
import AccountField_City from '@salesforce/schema/Account.City__c';
import AccountField_State from '@salesforce/schema/Account.State__c';
import AccountField_Country from '@salesforce/schema/Account.Country__c';
import AccountField_Pincode from '@salesforce/schema/Account.Postal_code__c';
import AccountField_SAPCode from '@salesforce/schema/Account.SAP_Customer_code__c';

import getCasePriorities from '@salesforce/apex/FieldServiceCreateCaseController.getCasePriorities';

import getUserBusinessUnit from '@salesforce/apex/FieldServiceCreateCaseController.getUserBusinessUnit';

import getAssetsByCustomer from '@salesforce/apex/FieldServiceCreateCaseController.getAssetsByCustomer';

// import createCase from '@salesforce/apex/FieldServiceCreateCaseController.createCase';

import getAccountDetails from '@salesforce/apex/FieldServiceCreateCaseController.getAccountDetails';
import getAssetDetails from '@salesforce/apex/FieldServiceCreateCaseController.getAssetDetails';
import checkForExistingCase from '@salesforce/apex/FieldServiceCreateCaseController.checkForExistingCase';



export default class FieldServiceCreateCase extends NavigationMixin(LightningElement) {

    @track showSpinner = true;
    @api customerAddress = '';
    @api customerCode = '';
    @track caseDivision;
    @track caseType;

    userId = Id;


    getBusinessUnit() {
        getUserBusinessUnit()
            .then(result => {
                this.caseDivision = result;
                this.handleFieldChange({
                    target: {
                        name: CaseField_Division.fieldApiName,
                        value: this.caseDivision,
                        dataset: {}
                    },
                    currentTarget: {
                        dataset: {}
                    },
                    detail: {}
                });
            })
            .catch(error => {
                this.businessUnit = undefined;
                showToast(this, 'Error', 'Error retrieving Business Unit', 'error', error);
            });
    }

    @track caseRecord = {
        get isCustomerAssetsDropdownDisabled() {
            return !this.searchedByCustomer;
        }
    };
    @track fields = [];


    @track isMobile
    @track isTablet;
    @track isDesktop;



    @wire(CurrentPageReference)
    getStateParameters({ state }) {
        console.log('pageRef state:', state);
        const { c__caseDivision: caseDivision, c__caseType: caseType, c__caseSubType: caseSubType } = state || {};
        this.caseDivision = caseDivision;
        this.caseType = caseType;

        const currentDate = new Date().toISOString();
        const fieldUpdates = [
            { field: CaseField_Owner, value: Id },
            { field: CaseField_CreatedDate, value: currentDate },
            { field: CaseField_Division, value: this.caseDivision },
            { field: CaseField_CaseType, value: caseType },
            { field: CaseField_CaseSubType, value: caseSubType },
            { field: CaseField_CaseRaiseByEngineer, value: Id }
        ];

        this.fields = [];
        this.caseRecord = {
            get isCustomerAssetsDropdownDisabled() {
                return !this.searchedByCustomer;
            }
        };
        fieldUpdates.forEach(({ field, value }) => {
            this.caseRecord[field.fieldApiName] = value;
            const fieldObj = this.fields.find(f => f.fieldApiName === field.fieldApiName);
            if (fieldObj) {
                fieldObj.value = value;
            }
        });

        this.getBusinessUnit();
        this.setFieldsBasedOnDivision();

        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields?.forEach(field => {
            // if (![CaseField_Division.fieldApiName, CaseField_CaseType.fieldApiName].includes(field.fieldName)) {
            field.reset();
            // }
        });
    }


    @track userDetails;
    @track userRoleName;
    @track isSE;
    @track isRSM;
    @track isCoordinator;
    @track isServiceHead;

    @wire(getUserDetails)
    wiredUserDetails({ error, data }) {
        if (data) {
            this.userDetails = data;
            const userRoleName = this.userDetails?.UserRole?.Name?.toLowerCase() || '';
            this.isSE = userRoleName.includes('engineer');
            this.isRSM = userRoleName.includes('rsm');
            this.isCoordinator = userRoleName.includes('coordinator');
            this.isServiceHead = userRoleName.includes('head') || userRoleName === 'System Administrator';

            const notifiedByField = this.fields.find(f => f.fieldApiName === CaseField_CaseNotifiedBy.fieldApiName);
            if (notifiedByField) {
                notifiedByField.isHidden = this.isSE;
            }
        }
    }


    @wire(getCasePriorities)
    wiredCasePriorities({ error, data }) {
        if (data) {
            this.casePriorities = data;
        }
        else if (error) {
            console.log('wiredCasePriorities error', error, JSON.stringify(error));
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }



    initiatePageWithDefaults() {
        const currentDate = new Date().toISOString();
        const fieldUpdates = [
            { field: CaseField_Owner, value: Id },
            { field: CaseField_CreatedDate, value: currentDate },
            { field: CaseField_Division, value: this.caseDivision },
            { field: CaseField_CaseType, value: '' },
            { field: CaseField_CaseSubType, value: '' },
            { field: CaseField_CaseRaiseByEngineer, value: Id }
        ];

        this.caseType = null;
        this.caseSubType = null;

        this.fields = [];
        this.caseRecord = {
            get isCustomerAssetsDropdownDisabled() {
                return !this.searchedByCustomer;
            }
        };
        fieldUpdates.forEach(({ field, value }) => {
            this.caseRecord[field.fieldApiName] = value;
            const fieldObj = this.fields.find(f => f.fieldApiName === field.fieldApiName);
            if (fieldObj) {
                fieldObj.value = value;
            }
        });

        this.getBusinessUnit();
        this.setFieldsBasedOnDivision();

        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields?.forEach(field => {
            // if (![CaseField_Division.fieldApiName, CaseField_CaseType.fieldApiName].includes(field.fieldName)) {
            field.reset();
            // }
        });

        this.assetWarrantyDetails = undefined;
        this.assetAMCDetails = undefined;
        this.assetWarrantyAMCExpired = false;
    }



    connectedCallback() {
        console.log('connectedCallback from FieldServiceCreateCase');
        analyzeUserAgent(this);
        disablePullToRefresh(this);
    }

    renderedCallback() {
        console.log('renderedCallback from FieldServiceCreateCase');
        analyzeFormFactor(this);
    }


    handleCustomerSelect(event) {
        const { name, value } = getNameAndValueOnChange(this, event);

        if (!value) {
            this.caseRecord.searchedByCustomer = false;
            this.caseRecord.assetOption = null;
            this.caseRecord[CaseField_Asset.fieldApiName] = '';
            this.caseRecord[name] = '';
            this.caseRecord.SAPCustomerCode = '';
            this.caseRecord.customerAddress = '';
            this.caseRecord.assetOptions = null;
            this.caseRecord.contactOptions = null;
            return;
        }

        this.caseRecord[name] = value;
        this.caseRecord.searchedByCustomer = true;

        this.handleGetAccountDetails(this.caseRecord.AccountId);

        getAssetsByCustomer({ accountId: value })
            .then(result => {
                this.caseRecord.assetOptions = result?.map(asset => ({
                    label: asset.Invoice__r?.Name,
                    description1: asset.Name,
                    assetId: asset.Id,
                    invoiceId: asset.Invoice__c,
                    value: asset.Id
                }));
            })
            .catch(error => {
                console.log('Error fetching assets:', error);
            });
    }


    handleAssetSelect(event) {
        const asset = event.target;
        if (asset.value) {
            const assetOption = this.caseRecord.assetOptions.find(option => option.value === asset.value);
            this.caseRecord[CaseField_Asset.fieldApiName] = assetOption?.assetId;
            this.caseRecord.Invoice__c = assetOption?.invoiceId;
            this.assetId = asset.value;
            this.handleGetAssetDetails(asset.value);
        } else {
            this.caseRecord[CaseField_Asset.fieldApiName] = '';
            this.caseRecord.Invoice__c = '';
            this.caseRecord.assetOptions = null;
            this.caseRecord.contactOptions = null;
            this.assetId = '';
            this.handleGetAssetDetails('');
        }
    }


    handleContactSelect(event) {
        const contact = event.target;
        const { name } = event.currentTarget.dataset;
        const data = {
            target: { name: name, fieldName: name, value: contact.value, dataset: {} },
            currentTarget: { name: name, fieldName: name, value: contact.value, dataset: {} },
            detail: { recordId: contact.value }
        };
        this.handleFieldChange(data);
    }


    handleFieldChange(event) {
        const { name, value } = getNameAndValueOnChange(this, event);
        console.log('name', name, 'value', value);

        try {
            event.target.setCustomValidity('');
            event.target.reportValidity();
        } catch (error) {
            // console.log('Error setting custom validity:', error);
        }

        this.caseRecord[name] = value;
        const field = this.fields?.find(field => field.fieldApiName === name);
        if (field) {
            field.value = value;
        }

        if (name === CaseField_Asset.fieldApiName) {
            this.assetId = value;
            this.handleGetAssetDetails(value);
        }
        else if (name === CaseField_Division.fieldApiName) {
            this.caseDivision = value;
            this.setFieldsBasedOnDivision();
        }
        else if (name === CaseField_CaseType.fieldApiName) {
            this.caseType = value;
            this.caseRecord[CaseField_CaseSubType.fieldApiName] = '';
            this.setFieldsBasedOnDivision();
        }
        else if (name === CaseField_CaseStatus.fieldApiName) {
            if (field) {
                field.value = value;
            }
            this.caseRecord[CaseField_CaseStatus.fieldApiName] = 'New';
        }

        if (name === CaseField_CaseType.fieldApiName || name === CaseField_CaseSubType.fieldApiName) {
            const resetData = {
                target: { name: CaseField_CasePriority.fieldApiName, fieldName: CaseField_CasePriority.fieldApiName, value: '', dataset: {} },
                currentTarget: { name: CaseField_CasePriority.fieldApiName, fieldName: CaseField_CasePriority.fieldApiName, value: '', dataset: {} },
                detail: { recordId: '' }
            };
            this.handleFieldChange(resetData);

            const casePriority = this.casePriorities.find(p =>
                p.Business_Vertical__c === this.caseRecord[CaseField_Division.fieldApiName] &&
                p.Type__c === this.caseRecord[CaseField_CaseType.fieldApiName] &&
                p.Case_Sub_Type__c === this.caseRecord[CaseField_CaseSubType.fieldApiName]
            );
            if (casePriority) {
                this.caseRecord[CaseField_CasePriority.fieldApiName] = casePriority.Case_Priority__c;

                const priorityData = {
                    target: { name: CaseField_CasePriority.fieldApiName, fieldName: CaseField_CasePriority.fieldApiName, value: casePriority.Case_Priority__c, dataset: {} },
                    currentTarget: { name: CaseField_CasePriority.fieldApiName, fieldName: CaseField_CasePriority.fieldApiName, value: casePriority.Case_Priority__c, dataset: {} },
                    detail: { recordId: casePriority.Case_Priority__c }
                };
                this.handleFieldChange(priorityData);
            }
        }
    }


    handleAddNewContact(event) {
        const { parentFieldApiName } = event.currentTarget.dataset;
        openLightningModal(this, addNewContactModal, { accountId: this.caseRecord[CaseField_Account.fieldApiName], assetId: this.caseRecord[CaseField_Asset.fieldApiName] },
            (result) => {
                if (result) {
                    console.log('result', result, parentFieldApiName);
                    const data = {
                        target: { name: parentFieldApiName, fieldName: parentFieldApiName, value: result, dataset: {} },
                        currentTarget: { name: parentFieldApiName, fieldName: parentFieldApiName, value: result, dataset: {} },
                        detail: { recordId: result }
                    };
                    this.handleFieldChange(data);
                    this.handleGetAccountDetails(this.caseRecord[CaseField_Account.fieldApiName]);
                }
            });
    }


    handleCreateCaseLoad(event) {
        this.showSpinner = false;
    }


    handleCreateCaseCancel(event) {
        navigateToLWC(this, 'fieldServiceHome');
    }


    handleCreateCaseSubmit(event) {
        event.preventDefault();

        const fields = event.detail.fields;
        console.log('fields', fields[CaseField_Asset.fieldApiName], fields[CaseField_CaseType.fieldApiName], fields[CaseField_Division.fieldApiName]);
        fields[CaseField_Asset.fieldApiName] = this.caseRecord[CaseField_Asset.fieldApiName];
        fields[CaseField_Account.fieldApiName] = this.caseRecord[CaseField_Account.fieldApiName];
        fields[CaseField_CaseType.fieldApiName] = this.caseRecord[CaseField_CaseType.fieldApiName];
        fields[CaseField_Division.fieldApiName] = this.caseRecord[CaseField_Division.fieldApiName];
        fields[CaseField_CaseSubType.fieldApiName] = this.caseRecord[CaseField_CaseSubType.fieldApiName];

        fields[CaseField_Contact.fieldApiName] = this.caseRecord[CaseField_Contact.fieldApiName];
        fields[CaseField_CaseNotifiedBy.fieldApiName] = this.caseRecord[CaseField_CaseNotifiedBy.fieldApiName];

        fields[CaseField_CaseRaiseByEngineer.fieldApiName] = this.caseRecord[CaseField_CaseRaiseByEngineer.fieldApiName];

        let isValid = true;

        if (!this.caseRecord.AssetId) {
            const recordPicker = this.template.querySelector('lightning-record-picker[data-name="AssetId"]');
            if (recordPicker) {
                recordPicker.setCustomValidity('Required field.');
                recordPicker.reportValidity();
            } else {
                showToast(this, 'Error', 'Asset is required', 'error');
            }
            isValid = false;
        }

        if (this.caseRecord.isCustomerBlocked) {
            if (this.caseRecord[CaseField_Division.fieldApiName] === 'MHE' || this.caseRecord[CaseField_Division.fieldApiName] === 'CNPL' || this.caseRecord[CaseField_Division.fieldApiName] === 'Hanel') {
                const recordPicker = this.template.querySelector('lightning-record-picker[data-name="AccountId"]');
                if (recordPicker) {
                    recordPicker.setCustomValidity('Customer is blocked. Case cannot be created for this customer.');
                    recordPicker.reportValidity();
                }
                showToast(this, 'Error', 'Customer is blocked. Case cannot be created for this customer.', 'error');
                isValid = false;
            } else if (this.caseRecord[CaseField_Division.fieldApiName] === 'Printer') {
                // if (customerRecordPickerElement) {
                //     customerRecordPickerElement.setCustomValidity('Customer is blocked. Case cannot be worked on until customer is unblocked.');
                //     customerRecordPickerElement.reportValidity();
                // } else {
                showToast(this, 'Warning', 'Customer is blocked. Case cannot be worked on until customer is unblocked.', 'info');
                // }
            }
        }

        if (!this.caseRecord.AccountId) {
            const recordPicker = this.template.querySelector('lightning-record-picker[data-name="AccountId"]');
            if (recordPicker) {
                recordPicker.setCustomValidity('Required field.');
                recordPicker.reportValidity();
            } else {
                showToast(this, 'Error', 'Customer is required', 'error');
            }
            isValid = false;
        }

        if (!this.caseRecord.Type) {
            const caseTypeElement = this.template.querySelector('lightning-combobox[data-name="Type"]');
            if (caseTypeElement) {
                caseTypeElement.setCustomValidity('Required field.');
                caseTypeElement.reportValidity();
            } else {
                showToast(this, 'Error', 'Case Type is required', 'error');
            }
            isValid = false;
        }

        if (!this.caseRecord.Case_Sub_Type__c) {
            const caseSubTypeElement = this.template.querySelector('lightning-combobox[data-name="Case_Sub_Type__c"]');
            if (caseSubTypeElement) {
                caseSubTypeElement.setCustomValidity('Required field.');
                caseSubTypeElement.reportValidity();
            } else {
                showToast(this, 'Error', 'Case Sub Type is required', 'error');
            }
            isValid = false;
        }

        if (!this.caseRecord.ContactId) {
            const contactElement = this.template.querySelector('lightning-combobox[data-name="ContactId"]');
            if (contactElement) {
                contactElement.setCustomValidity('Required field.');
                contactElement.reportValidity();
            } else {
                showToast(this, 'Error', 'Contact Name is required', 'error');
            }
            isValid = false;
        }


        if (!isValid) {
            return;
        }

        console.log('fields', fields, JSON.stringify(fields), fields[CaseField_Asset.fieldApiName], fields[CaseField_CaseType.fieldApiName], fields[CaseField_Division.fieldApiName]);
        this.showSpinner = true;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }


    handleCreateCaseSuccess(event) {
        this.showSpinner = false;

        const { detail } = event || {};
        const { id, fields } = detail || {};
        const caseNumber = fields?.CaseNumber?.value;

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                actionName: 'view',
            },
        })
            .then((url) => {
                const toastEvent = new ShowToastEvent({
                    title: 'Success!',
                    message: 'Case ' + caseNumber + ' created successfully. {0}',
                    messageData: [
                        {
                            url: url,
                            label: 'Click here',
                        },
                    ],
                    variant: 'success'
                });
                this.dispatchEvent(toastEvent);
                this.initiatePageWithDefaults();
            })
            .catch((error) => {
                console.log('Error generating URL:', error);
                showToast(this, 'Error', 'Error generating URL', 'error', error);
            });
    }


    handleCreateCaseError(event) {
        this.showSpinner = false;
        showToast(this, 'Error', 'Something went wrong', 'error', event);
        console.log('error', JSON.stringify(event));
        console.log('error', JSON.stringify(event.message));
        console.log('error', JSON.stringify(event.detail));
        console.log('error', JSON.stringify(event.output));
    }





    @track assetWarrantyDetails;
    @track assetAMCDetails;
    @track assetWarrantyAMCExpired;
    @track assetType;

    handleGetAssetDetails(assetId) {
        const updateField = (field, value, takenFromAsset) => {
            console.log('field ->', field, 'value ->', value, 'takenFromAsset ->', takenFromAsset);
            this.caseRecord[field.fieldApiName] = value;
            const fieldItem = this.fields.find(f => f.fieldApiName === field.fieldApiName);
            this.fields.forEach(item => {
                console.log(item.fieldApiName, '===', field.fieldApiName);
            });
            if (fieldItem) {
                fieldItem.value = value;
            }
            this.caseRecord[field.fieldApiName + '_takenFromAsset'] = takenFromAsset;
        };

        if (assetId) {
            this.showSpinner = true;
            getAssetDetails({ assetId: assetId })
                .then(result => {
                    console.log('result', result);

                    const { asset, contacts } = result;
                    this.assetType = asset.Type__c;
                    console.log('this.assetType', this.assetType);

                    if (asset.Cases && asset.Cases.length > 0) {
                        const { Id, CaseNumber, Status, Owner: { Name: ownerName } = {} } = asset.Cases[0];
                        const message = `A case for the asset has already been created and is still open. Case Number: ${CaseNumber} Status: ${Status}. It is assigned to the "${ownerName}". Please contact your administrator for further assistance.`;
                        LightningAlert.open({
                            label: 'Case already exists',
                            message: message,
                            theme: 'error'
                        })
                            .then(result => {
                                this.initiatePageWithDefaults();
                            });
                        return;
                    }

                    this.caseRecord.contactOptions = contacts?.map(contact => ({ label: contact.Name, description1: contact.Email, description2: contact.MobilePhone, value: contact.Id }));

                    if (asset.Asset_Warranty__r && asset.Asset_Warranty__r.length > 0) {
                        this.assetWarrantyDetails = {
                            id: asset.Asset_Warranty__r[0].Id,
                            startDate: asset.Asset_Warranty__r[0].Warranty_Start_Date__c,
                            endDate: asset.Asset_Warranty__r[0].Warranty_End_Date__c,
                            status: asset.Asset_Warranty__r[0].Asset_Warranty_PO_Status__c
                        };
                        this.assetWarrantyAMCExpired = false;
                    }
                    else if (asset.Asset_AMCs__r && asset.Asset_AMCs__r.length > 0) {
                        this.assetAMCDetails = {
                            id: asset.Asset_AMCs__r[0].Id,
                            startDate: asset.Asset_AMCs__r[0].AMC_Start_Date__c,
                            endDate: asset.Asset_AMCs__r[0].AMC_End_Date__c,
                            status: asset.Asset_AMCs__r[0].Asset_AMC_PO_Status__c,
                            type: asset.Asset_AMCs__r[0].Product_Category_Type__c
                        };
                        this.assetWarrantyAMCExpired = false;
                    }
                    else {
                        this.assetWarrantyAMCExpired = true;
                    }

                    updateField(CaseField_Account, asset.End_Customer__c, !!asset.End_Customer__c);
                    updateField(CaseField_Contact, asset.ContactId, !!asset.ContactId);
                    updateField(CaseField_Division, asset.Business_Vertical__c, !!asset.Business_Vertical__c);
                    updateField(CaseField_CasePincode, asset.Pin_Code_Master__c, !!asset.Pin_Code_Master__c);
                    updateField(CaseField_CaseTerritory, asset.Territory_Master__c, !!asset.Territory_Master__c);

                    this.setFieldsBasedOnDivision();

                    if (asset.End_Customer__c) {
                        this.handleCustomerSelect({ detail: {}, target: { name: CaseField_Account.fieldApiName, value: this.caseRecord[CaseField_Account.fieldApiName], dataset: {} } });
                    }

                    if (this.caseRecord[CaseField_Division.fieldApiName] === 'Printer') {
                        this.caseRecord[CaseField_CaseSubType.fieldApiName] = asset.Asset_Category__c;
                    }

                    console.log('fields', this.fields, JSON.stringify(this.fields), 'caseRecord', this.caseRecord, JSON.stringify(this.caseRecord));
                })
                .catch(error => {
                    console.log('Error retrieving asset details:', error);
                    showToast(this, 'Error', 'Error retrieving asset details', 'error', error);
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        }
        else {
            [CaseField_Account, CaseField_Contact, CaseField_Division, CaseField_CasePincode, CaseField_CaseTerritory, CaseField_CaseSubType].forEach(field => {
                updateField(field, null, false);
            });
            this.assetWarrantyDetails = undefined;
            this.assetAMCDetails = undefined;
            this.assetWarrantyAMCExpired = false;
        }
    }

    handleGetAccountDetails(accountId) {
        if (!accountId) {
            this.caseRecord.SAPCustomerCode = null;
            this.caseRecord.customerAddress = null;
            this.caseRecord.isCustomerBlocked = false;
            return;
        }

        this.caseRecord.contactOptions = null;

        this.showSpinner = true;
        getAccountDetails({ accountId: accountId })
            .then(result => {
                console.log('result', result);

                const { account, contacts } = result;

                const addressParts = [
                    account.Street_House_Number__c,
                    account.Street1__c,
                    account.Street2__c,
                    account.City__c,
                    account.State__c,
                    account.Country__c,
                    account.Postal_code__c
                ].filter(Boolean);

                if (account.Customer_Blocked__c) {
                    const customerRecordPickerElement = this.template.querySelector('lightning-record-picker[data-name="AccountId"]');
                    if (this.caseRecord[CaseField_Division.fieldApiName] === 'MHE' || this.caseRecord[CaseField_Division.fieldApiName] === 'CNPL' || this.caseRecord[CaseField_Division.fieldApiName] === 'Hanel') {
                        if (customerRecordPickerElement) {
                            customerRecordPickerElement.setCustomValidity('Customer is blocked. Case cannot be created for this customer.');
                            customerRecordPickerElement.reportValidity();
                        } else {
                            showToast(this, 'Error', 'Customer is blocked. Case cannot be created for this customer.', 'error');
                        }
                    } else if (this.caseRecord[CaseField_Division.fieldApiName] === 'Printer') {
                        showToast(this, 'Warning', 'Customer is blocked. To work on this, approval from Vertical Head is required', 'info');
                    }
                }

                this.caseRecord.contactOptions = contacts?.map(contact => ({ label: contact.Name, description1: contact.Email, description2: contact.MobilePhone, value: contact.Id }));

                const contact = this.caseRecord.contactOptions.find(contact => contact.value === this.caseRecord[CaseField_Contact.fieldApiName]);
                if (!contact) {
                    delete this.caseRecord[CaseField_Contact.fieldApiName];
                    delete this.caseRecord.ContactId_takenFromAsset;
                }

                this.caseRecord.SAPCustomerCode = account.SAP_Customer_code__c;
                this.caseRecord.customerAddress = addressParts.join(' ');
                this.caseRecord.isCustomerBlocked = account.Customer_Blocked__c;
            })
            .catch(error => {
                console.log('Error retrieving the customer details', error);
                showToast(this, 'Error', 'Error retrieving customer details', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }







    setFieldsBasedOnDivision() {
        let division = this.caseRecord[CaseField_Division.fieldApiName];
        let type = this.caseRecord[CaseField_CaseType.fieldApiName];
        let caseSubType = this.caseRecord[CaseField_CaseSubType.fieldApiName];
        let assetType = this.assetType;

        console.log('division-->', division);
        console.log('assettype-->', assetType);


        let commonFields = [
            // { ...CaseField_Division, isDisabled: false },
            {
                ...CaseField_CaseType, isDisabled: false, label: 'Case Type', isCustom: true, required: true,
                get options() {
                    if (division === 'CNPL') {
                        const values = ['Preventive Maintenance', 'Breakdown', 'Courtesy', 'Re-Installation', 'Training'];
                        return values.map(value => ({ label: value, value: value }));
                    }
                    if (division === 'Hanel') {
                        const values = ['Preventive Maintenance', 'Breakdown', 'Courtesy', 'Re-Installation', 'Training'];
                        return values.map(value => ({ label: value, value: value }));
                    }
                    if (division === 'MHE') {
                        const values = [/* 'Preventive Maintenance', */ 'Breakdown', 'Courtesy', 'Re-Installation', 'Training'];
                        return values.map(value => ({ label: value, value: value }));
                    }
                    if (division === 'Printer') {
                        const values = [/*'Preventive Maintenance',*/ 'Breakdown', 'Courtesy', 'Re-Installation', 'Training', 'Demo'];
                        return values.map(value => ({ label: value, value: value }));
                    }
                }
            },
            {
                ...CaseField_CaseSubType, isDisabled: false, label: 'Case Sub Type', isCustom: true, required: true,
                get options() {
                    if (division === 'CNPL') {
                        if (type === 'Preventive Maintenance') {
                            const values = ['Warranty PM', 'AMC PM', 'CAMC PM', 'Health Checkup'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Breakdown') {
                            const values = ['Warranty Breakdown', 'AMC Breakdown', 'CAMC Breakdown', 'Chargeable Service'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Courtesy') {
                            const values = ['Courtesy', 'DEMO', 'Spare installation'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Re-Installation') {
                            const values = ['Re-installation'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Training') {
                            const values = ['Training'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                    }
                    else if (division === 'Hanel') {
                        if (type === 'Preventive Maintenance') {
                            const values = ['Warranty PM', 'AMC PM', 'CAMC PM', 'Health Checkup'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Breakdown') {
                            const values = ['Warranty Breakdown', 'AMC Breakdown', 'CAMC Breakdown', 'Chargeable Service'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Courtesy') {
                            const values = ['Courtesy visit', 'Sales DEMO at existing HANEL place', 'Spare supply / Service invoice need to handedover to customer plant', 'Spare installation'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Re-Installation') {
                            const values = ['Dismantling into CKD form', 'Packaging monitoring', 'Loading & Unloading', 'Re - installation as per HANEL standard'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Training') {
                            const values = ['Chargeable cum Refresh Training Cum usage awareness'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                    }
                    else if (division === 'MHE') {

                        console.log('AssetField_AssetType', assetType);
                        if (type === 'Preventive Maintenance') {
                            const values = ['Warranty PM', 'AMC PM', 'CAMC PM', 'Health Checkup'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Breakdown') {
                            let values = [];
                            if (assetType === 'Expired') {
                                values = ['Chargeable Service'];
                            } else if (assetType === 'Within Warranty') {
                                values = ['Warranty Breakdown', 'Chargeable Service'];
                            } else if (assetType === 'Within AMC') {
                                values = ['AMC Breakdown', 'Chargeable Service'];
                            } else if (assetType === 'Within CAMC') {
                                values = ['CAMC Breakdown', 'Chargeable Service'];
                            } else {
                                values = ['Warranty Breakdown', 'AMC Breakdown', 'CAMC Breakdown', 'Chargeable Service'];
                            }
                            // const values = ['Warranty Breakdown', 'AMC Breakdown', 'CAMC Breakdown', 'Chargeable Service'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Courtesy') {
                            const values = ['Courtesy Breakdown', 'Quote Negotiation', 'Payment Collection', 'Spare Business', 'DEMO', 'AMC Business', 'Spare installation'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Re-Installation') {
                            const values = ['Re-installation'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Training') {
                            const values = ['Training'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                    }
                    else if (division === 'Printer') {
                        // if (type === 'Preventive Maintenance') {
                        //     const values = ['Own Asset', 'Dealer Asset'];
                        //     return values.map(value => ({ label: value, value: value }));
                        // }
                        // else if (type === 'Breakdown') {
                        //     const values = ['Own Asset', 'Dealer Asset'];
                        //     return values.map(value => ({ label: value, value: value }));
                        // }
                        // else if (type === 'Courtesy') {
                        //     const values = ['Own Asset', 'Dealer Asset'];
                        //     return values.map(value => ({ label: value, value: value }));
                        // }
                        // else if (type === 'Re-Installation') {
                        //     const values = ['Own Asset', 'Dealer Asset'];
                        //     return values.map(value => ({ label: value, value: value }));
                        // }
                        // else if (type === 'Training') {
                        //     const values = ['Own Asset', 'Dealer Asset'];
                        //     return values.map(value => ({ label: value, value: value }));
                        // }
                        // else if (type === 'Demo') {
                        //     const values = ['Own Asset', 'Dealer Asset'];
                        //     return values.map(value => ({ label: value, value: value }));
                        // }
                        if (type === 'Preventive Maintenance') {
                            const values = ['Warranty PM', 'AMC PM', 'CAMC PM', 'Health Checkup'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Breakdown') {
                            const values = ['Warranty Breakdown', 'AMC Breakdown', 'CAMC Breakdown', 'Chargeable Service'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Courtesy') {
                            const values = ['Courtesy Breakdown', 'Quote Negotiation', 'Payment Collection', 'Spare Business', 'DEMO', 'AMC Business', 'Spare installation'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Re-Installation') {
                            const values = ['Re-installation'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                        else if (type === 'Training') {
                            const values = ['Training'];
                            return values.map(value => ({ label: value, value: value }));
                        }
                    }
                }
            },
            // {
            //     ...CaseField_Contact, isDisabled: false, label: 'Contact Name', isCustom: true, required: true
            // },
            { ...CaseField_Owner, isDisabled: false },
            // { ...CaseField_CreatedDate, isDisabled: true },
            // { ...CaseField_Account, isDisabled: false },
            { ...CaseField_Contact, isContactField: true }
        ];

        switch (division) {
            case 'Printer': {
                switch (type) {
                    case 'Installation': {
                        if (caseSubType === 'Own Asset' || !caseSubType) {
                            this.fields = [
                                ...commonFields,
                                // { ...CaseField_Reason, isDisabled: false },
                                // { ...CaseField_CurrencyIsoCode, isDisabled: false },
                                { ...CaseField_CasePincode, isDisabled: false },
                                // { ...CaseField_CaseTerritory, isDisabled: false },
                                // { ...CaseField_AssignTo, isDisabled: false },
                                // { ...CaseField_ReAssignTo, isDisabled: false },
                                { ...CaseField_CaseOrigin, required: true, isDisabled: false },
                                { ...CaseField_CaseStatus, isDisabled: true },
                                { ...CaseField_CasePriority, isDisabled: false },
                                // { ...CaseField_CaseSubject, isDisabled: false },
                                { ...CaseField_CaseDescription, required: true, isDisabled: false },
                                // { ...CaseField_Comments, isDisabled: false }
                            ];
                            break;
                        }
                        else if (caseSubType === 'Dealer asset') {
                            this.fields = [
                                ...commonFields,
                                // { ...CaseField_Reason, isDisabled: false },
                                // { ...CaseField_CurrencyIsoCode, isDisabled: false },
                                { ...CaseField_CasePincode, isDisabled: false },
                                // { ...CaseField_CaseTerritory, isDisabled: false },
                                // { ...CaseField_AssignTo, isDisabled: false },
                                // { ...CaseField_ReAssignTo, isDisabled: false },
                                { ...CaseField_CaseOrigin, required: true, isDisabled: false },
                                { ...CaseField_CaseRaiseByEngineer, isDisabled: false, isHidden: this.isSE },
                                { ...CaseField_CaseStatus, isDisabled: true },
                                { ...CaseField_CasePriority, isDisabled: false },
                                // { ...CaseField_CaseSubject, isDisabled: false },
                                { ...CaseField_CaseDescription, required: true, isDisabled: false },
                                // { ...CaseField_Comments, isDisabled: false }
                            ];
                            break;
                        }
                    }
                    case 'Preventive Maintenance': {
                        if (caseSubType === 'Own Asset' || !caseSubType) {
                            this.fields = [
                                ...commonFields,
                                // { ...CaseField_Reason, isDisabled: false },
                                // { ...CaseField_CurrencyIsoCode, isDisabled: false },
                                { ...CaseField_CasePincode, isDisabled: false },
                                // { ...CaseField_CaseTerritory, isDisabled: false },
                                // { ...CaseField_AssignTo, isDisabled: false },
                                // { ...CaseField_ReAssignTo, isDisabled: false },
                                { ...CaseField_CaseOrigin, required: true, isDisabled: false },
                                { ...CaseField_CaseStatus, isDisabled: true },
                                { ...CaseField_CasePriority, isDisabled: false },
                                // { ...CaseField_CaseSubject, isDisabled: false },
                                { ...CaseField_CaseDescription, required: true, isDisabled: false },
                                // { ...CaseField_Comments, isDisabled: false }
                            ];
                            break;
                        }
                        else if (caseSubType === 'Dealer asset') {
                            this.fields = [
                                ...commonFields,
                                // { ...CaseField_Reason, isDisabled: false },
                                // { ...CaseField_CurrencyIsoCode, isDisabled: false },
                                { ...CaseField_CasePincode, isDisabled: false },
                                // { ...CaseField_CaseTerritory, isDisabled: false },
                                // { ...CaseField_AssignTo, isDisabled: false },
                                // { ...CaseField_ReAssignTo, isDisabled: false },
                                { ...CaseField_CaseOrigin, required: true, isDisabled: false },
                                { ...CaseField_CaseRaiseByEngineer, isDisabled: false, isHidden: this.isSE },
                                { ...CaseField_CaseStatus, isDisabled: true },
                                { ...CaseField_CasePriority, isDisabled: false },
                                // { ...CaseField_CaseSubject, isDisabled: false },
                                { ...CaseField_CaseDescription, required: true, isDisabled: false },
                                // { ...CaseField_Comments, isDisabled: false }
                            ];
                            break;
                        }
                    }
                    case 'Breakdown': {
                        this.fields = [
                            ...commonFields,
                            // { ...CaseField_Reason, isDisabled: false },
                            // { ...CaseField_CurrencyIsoCode, isDisabled: false },
                            { ...CaseField_CasePincode, isDisabled: false },
                            // { ...CaseField_CaseTerritory, isDisabled: false },
                            // { ...CaseField_AssignTo, isDisabled: false },
                            // { ...CaseField_ReAssignTo, isDisabled: false },
                            { ...CaseField_CaseOrigin, required: true, isDisabled: false },
                            { ...CaseField_CaseRaiseByEngineer, isDisabled: false, isHidden: this.isSE },
                            { ...CaseField_CaseStatus, isDisabled: true },
                            { ...CaseField_CasePriority, isDisabled: false },
                            // { ...CaseField_CaseSubject, isDisabled: false },
                            { ...CaseField_CaseDescription, required: true, isDisabled: false },
                            // { ...CaseField_Comments, isDisabled: false }
                        ];
                        break;
                    }
                    case 'Courtesy':
                    case 'Re-Installation':
                    case 'Training': {
                        this.fields = [
                            ...commonFields,
                            // { ...CaseField_Reason, isDisabled: false },
                            // { ...CaseField_CurrencyIsoCode, isDisabled: false },
                            { ...CaseField_CasePincode, isDisabled: false },
                            // { ...CaseField_CaseTerritory, isDisabled: false },
                            // { ...CaseField_AssignTo, isDisabled: false },
                            // { ...CaseField_ReAssignTo, isDisabled: false },
                            { ...CaseField_CaseOrigin, required: true, isDisabled: false },
                            { ...CaseField_CaseRaiseByEngineer, isDisabled: false, isHidden: this.isSE },
                            { ...CaseField_CaseStatus, isDisabled: true },
                            { ...CaseField_CasePriority, isDisabled: false },
                            // { ...CaseField_CaseSubject, isDisabled: false },
                            { ...CaseField_CaseDescription, required: true, isDisabled: false },
                            // { ...CaseField_Comments, isDisabled: false }
                        ];
                        break;
                    }
                    case 'Demo': {
                        this.fields = [
                            ...commonFields,
                            // { ...CaseField_Reason, isDisabled: false },
                            // { ...CaseField_CurrencyIsoCode, isDisabled: false },
                            { ...CaseField_CasePincode, isDisabled: false },
                            // { ...CaseField_CaseTerritory, isDisabled: false },
                            // { ...CaseField_AssignTo, isDisabled: false },
                            // { ...CaseField_ReAssignTo, isDisabled: false },
                            { ...CaseField_CaseOrigin, required: true, isDisabled: false },
                            { ...CaseField_CaseRaiseByEngineer, isDisabled: false, isHidden: this.isSE },
                            { ...CaseField_CaseStatus, isDisabled: true },
                            { ...CaseField_CasePriority, isDisabled: false },
                            // { ...CaseField_CaseSubject, isDisabled: false },
                            { ...CaseField_CaseDescription, required: true, isDisabled: false },
                            // { ...CaseField_Comments, isDisabled: false }
                        ];
                        break;
                    }
                    default: {
                        this.fields = commonFields;
                    }
                }
                break;
            }

            case 'CNPL': {
                switch (type) {
                    case 'Installation':
                    case 'Preventive Maintenance':
                    case 'Breakdown':
                    case 'Courtesy':
                    case 'Re-Installation':
                    case 'Training': {
                        this.fields = [
                            ...commonFields,
                            // { ...CaseField_Reason, isDisabled: false },
                            // { ...CaseField_CurrencyIsoCode, isDisabled: false },
                            { ...CaseField_CaseNotifiedBy, isDisabled: false, isNotifiedByField: true },
                            { ...CaseField_CasePincode, isDisabled: false },
                            // { ...CaseField_CaseTerritory, isDisabled: false },
                            // { ...CaseField_AssignTo, isDisabled: false },
                            // { ...CaseField_ReAssignTo, isDisabled: false },
                            { ...CaseField_CaseOrigin, required: true, isDisabled: false },
                            { ...CaseField_CaseRaiseByEngineer, isDisabled: false, isHidden: this.isSE },
                            { ...CaseField_CaseStatus, isDisabled: true },
                            { ...CaseField_CasePriority, isDisabled: false },
                            // { ...CaseField_CaseSubject, isDisabled: false },
                            { ...CaseField_CaseDescription, required: true, isDisabled: false },
                            // { ...CaseField_Comments, isDisabled: false }
                        ];
                        break;
                    }
                    default: {
                        this.fields = commonFields;
                    }
                }
                break;
            }

            case 'Hanel': {
                switch (type) {
                    case 'Installation':
                    case 'Preventive Maintenance':
                    case 'Breakdown':
                    case 'Courtesy':
                    case 'Re-Installation':
                    case 'Training': {
                        this.fields = [
                            ...commonFields,
                            // { ...CaseField_Reason, isDisabled: false },
                            // { ...CaseField_CurrencyIsoCode, isDisabled: false },
                            { ...CaseField_CaseNotifiedBy, isDisabled: false, isNotifiedByField: true },
                            { ...CaseField_CasePincode, isDisabled: false },
                            // { ...CaseField_CaseTerritory, isDisabled: false },
                            // { ...CaseField_AssignTo, isDisabled: false },
                            // { ...CaseField_ReAssignTo, isDisabled: false },
                            { ...CaseField_CaseOrigin, required: true, isDisabled: false },
                            { ...CaseField_CaseRaiseByEngineer, isDisabled: false, isHidden: this.isSE },
                            { ...CaseField_CaseStatus, isDisabled: true },
                            { ...CaseField_CasePriority, isDisabled: false },
                            // { ...CaseField_CaseSubject, isDisabled: false },
                            { ...CaseField_CaseDescription, required: true, isDisabled: false },
                            // { ...CaseField_Comments, isDisabled: false }
                        ];
                        break;
                    }
                    default: {
                        this.fields = commonFields;
                    }
                }
                break;
            }

            case 'MHE': {
                switch (type) {
                    case 'Installation':
                    case 'Preventive Maintenance':
                    case 'Breakdown':
                    case 'Courtesy':
                    case 'Re-Installation':
                    case 'Training': {
                        this.fields = [
                            ...commonFields,
                            // { ...CaseField_Reason, isDisabled: false },
                            // { ...CaseField_CurrencyIsoCode, isDisabled: false },
                            { ...CaseField_CaseNotifiedBy, isDisabled: false, isNotifiedByField: true },
                            { ...CaseField_CasePincode, isDisabled: false },
                            // { ...CaseField_CaseTerritory, isDisabled: false },
                            // { ...CaseField_AssignTo, isDisabled: false },
                            // { ...CaseField_ReAssignTo, isDisabled: false },
                            { ...CaseField_CaseOrigin, required: true, isDisabled: false },
                            { ...CaseField_CaseRaiseByEngineer, isDisabled: false, isHidden: this.isSE },
                            { ...CaseField_CaseStatus, isDisabled: true },
                            { ...CaseField_CasePriority, isDisabled: false },
                            // { ...CaseField_CaseSubject, isDisabled: false },
                            { ...CaseField_CaseDescription, required: true, isDisabled: false },
                            // { ...CaseField_Comments, isDisabled: false }
                        ];
                        break;
                    }
                    default: {
                        this.fields = commonFields;
                    }
                }
                break;
            }

            default: {
                this.fields = [...commonFields];
                break;
            }
        }

        this.fields = this.fields.map(field => {
            console.log(field.fieldApiName, field.isDisabled, this.caseRecord[field.fieldApiName + '_takenFromAsset']);
            return {
                ...field,
                fieldApiName: field.fieldApiName,
                value: this.caseRecord[field.fieldApiName],
                isDisabled: field.isDisabled || this.caseRecord[field.fieldApiName + '_takenFromAsset']
            };
        });

        console.log('this.fields', this.fields, JSON.stringify(this.fields));

    }







    get accountByNameDisplayInfo() {
        return {
            primaryField: 'Name',
            additionalFields: ['Customer_Code_City__c']
        };
    }

    get accountByNameMatchingInfo() {
        return {
            primaryField: { fieldPath: 'Name' },
            additionalFields: [{ fieldPath: 'Customer_Code_City__c' }]
        };
    }


    get assetByInvNoDisplayInfo() {
        return {
            primaryField: 'Invoice_Number__c',
            additionalFields: ['Name']
        };
    }

    get assetByInvNoMatchingInfo() {
        return {
            primaryField: { fieldPath: 'Name' },
            additionalFields: [{ fieldPath: 'Invoice_Number__c' }]
        };
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


    get assetBySerialNoOrInvNoDisplayInfo() {
        return {
            primaryField: 'SerialNumber',
            additionalFields: ['Invoice_Number__c']
        };
    }

    get assetBySerialNoOrInvNoMatchingInfo() {
        return {
            primaryField: { fieldPath: 'Invoice_Number__c' },
            additionalFields: [{ fieldPath: 'SerialNumber' }]
        };
    }


    get isAddContactDisabled() {
        return this.caseRecord[CaseField_Asset.fieldApiName] && this.caseRecord[CaseField_Account.fieldApiName] ? false : true;
    }


}