import { LightningElement, track, api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
// import { getNameAndValueOnChange } from 'c/utilJS';
// import { showToast } from 'c/utilJS';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, scrollToTop, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh } from 'c/utilJS';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import CaseObject from '@salesforce/schema/Case';
import CaseField_CaseDivision from '@salesforce/schema/Case.Division__c';
import CaseField_CaseType from '@salesforce/schema/Case.Type';


export default class FieldServiceCreateCasePre extends LightningModal {

    @track divisionOptions = [];
    @track caseTypeOptions = [];

    @track division;
    @track caseType;


    @wire(getObjectInfo, { objectApiName: CaseObject })
    caseObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$caseObjectInfo.data.defaultRecordTypeId', fieldApiName: CaseField_CaseDivision })
    wiredDivision({ data, error }) {
        if (data) {
            this.divisionOptions = data.values;
        } else if (error) {
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$caseObjectInfo.data.defaultRecordTypeId', fieldApiName: CaseField_CaseType })
    wireCaseTypeOptions({ data, error }) {
        if (data) {
            this.caseTypeOptions = data.values;
        } else if (error) {
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }


    connectedCallback() {
        disablePullToRefresh(this);
    }

    renderedCallback() { }

    handleChange(event) {
        const { name, value } = getNameAndValueOnChange(this, event);
        this[name] = value;
    }

    handleCancel() {
        this.close();
    }

    handleOkay() {
        if (this.division && this.caseType) {
            this.close({ division: this.division, caseType: this.caseType });
            return;
        } else {
            showToast(this, 'Error', 'Please select a case division', 'error');
        }
    }

}