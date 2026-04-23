import { LightningElement, track, api, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { createRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';
import { publish, MessageContext } from 'lightning/messageService';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh, publishRefreshEvent, closeQuickActionPopup } from 'c/utilJS';

import CASE_TEAM_OBJECT from '@salesforce/schema/Case_Team__c';
import CASE_TEAM_CASE_TEAM_ROLE from '@salesforce/schema/Case_Team__c.Case_Team_Role__c';
import CASE_TEAM_ACCESS_LEVEL from '@salesforce/schema/Case_Team__c.Access_Level__c';


import getCaseTeamRoles from '@salesforce/apex/CaseTeamLWCController.getCaseTeamRoles';



export default class CaseTeamLWC extends LightningElement {

    @track showSpinner;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        console.log('recordId', this._recordId);
    }

    @track caseTeamRecord = {
        existingCaseTeamRecords: [],

        caseTeamRolesOptions: [],
        caseTeamAccessLevelOptions: [],
    };





    connectedCallback() {
        console.log('connectedCallback from CaseTeamLWC');
        analyzeFormFactor(this);
        analyzeUserAgent(this);
        loadQuickActionPopupStyle(this, 35);
    }

    renderedCallback() {
        console.log('renderedCallback from CaseTeamLWC');
        analyzeFormFactor(this);
    }

    disconnectedCallback() {
        console.log('disconnectedCallback from CaseTeamLWC');
        unloadQuickActionPopupStyle(this);
    }



    handleChange(event) {
        const { name, value } = getNameAndValueOnChange(this, event);
        this.caseTeamRecord[name] = value;

        event.currentTarget.setCustomValidity('');
        event.currentTarget.reportValidity();

        if (name === 'Case_Team_Role__c') {
            this.caseTeamRecord.Access_Level__c = this.caseTeamRecord.caseTeamRolesOptions.find(row => row.value === value).accessLevel;
        }
    }



    handleCancel(event) {
        console.log('handleCancel from CaseTeamLWC');
        publishRefreshEvent(this);
        closeQuickActionPopup(this);
    }


    handleSave(event) {
        console.log('handleSave from CaseTeamLWC');
        if (!this.caseTeamRecord.Member__c) {
            const memberInput = this.template.querySelector('lightning-record-picker[data-name="Member__c"]');
            if (memberInput) {
                memberInput.setCustomValidity('Please select a member');
                memberInput.reportValidity();
            }
        }
        if (!this.caseTeamRecord.Case_Team_Role__c) {
            const caseTeamRoleInput = this.template.querySelector('lightning-combobox[data-name="Case_Team_Role__c"]');
            if (caseTeamRoleInput) {
                caseTeamRoleInput.setCustomValidity('Please select a case team role');
                caseTeamRoleInput.reportValidity();
            }
        }

        const fields = {
            Case__c: this.recordId,
            Member__c: this.caseTeamRecord.Member__c,
            Case_Team_Role__c: this.caseTeamRecord.caseTeamRolesOptions.find(row => row.value === this.caseTeamRecord.Case_Team_Role__c).label,
            Access_Level__c: this.caseTeamRecord.Access_Level__c,
        };

        this.showSpinner = true;
        createRecord({ apiName: CASE_TEAM_OBJECT.objectApiName, fields })
            .then(result => {
                showToast(this, 'Success', 'Case Team Member added successfully', 'success');
                this.caseTeamRecord.Member__c = '';
                this.caseTeamRecord.Case_Team_Role__c = '';
                this.caseTeamRecord.Access_Level__c = '';
                publishRefreshEvent(this);
                closeQuickActionPopup(this);
            })
            .catch(error => {
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }







    get memberFilter() {
        const criteria = [{ fieldPath: 'IsActive', operator: 'eq', value: true }];
        const existingRecords = this.caseTeamRecord?.existingCaseTeamRecords;

        if (existingRecords?.length > 0) {
            criteria.push({
                fieldPath: 'Id',
                operator: 'nin',
                value: existingRecords.map(row => row.fields.Member__c.value)
            });
        }

        return { criteria };
    }

    get memberDisplayInfo() {
        return {
            primaryField: 'Name',
            additionalFields: ['Email']
        };
    }

    get memberMatchingInfo() {
        return {
            primaryField: { fieldPath: 'Name' },
            additionalFields: [{ fieldPath: 'Email' }]
        };
    }




    @wire(MessageContext)
    messageContext;


    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Case_Teams__r',
        fields: ['Case_Team__c.Member__c']
    })
    wiredCaseTeamRecords({ error, data }) {
        if (data) {
            this.caseTeamRecord.existingCaseTeamRecords = data.records;
        } else if (error) {
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }


    @wire(getCaseTeamRoles)
    wiredCaseTeamRoles({ error, data }) {
        if (data) {
            this.caseTeamRecord.caseTeamRolesOptions = data.map(row => ({ label: row.Name, value: row.Id, accessLevel: row.AccessLevel }));
        } else if (error) {
            console.log('wiredCaseTeamRoles error', error, JSON.stringify(error));
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }



    @wire(getObjectInfo, { objectApiName: CASE_TEAM_OBJECT })
    wiredCaseTeamObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$wiredCaseTeamObjectInfo.data.defaultRecordTypeId', fieldApiName: CASE_TEAM_ACCESS_LEVEL })
    wiredCaseTeamAccessLevelOptions({ data, error }) {
        if (data) {
            this.caseTeamRecord.caseTeamAccessLevelOptions = data.values;
        } else if (error) {
            console.log('wiredCaseTeamAccessLevelOptions error', error, JSON.stringify(error));
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }

}