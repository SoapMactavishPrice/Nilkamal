import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, scrollToTop, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh } from 'c/utilJS';

import searchForErrorCode from '@salesforce/apex/FieldServiceTroubleshootingController.searchForErrorCode';


export default class FieldServiceTroubleshooting extends NavigationMixin(LightningElement) {

    @track showSpinner;

    @track searchTerm;
    @track searchTimeout;


    @track errorCodesList; // = [{ categoryName: 'Category 1', errorItems: [{ id: 'a0jF3000003kFL7' }] }];



    @wire(CurrentPageReference)
    currentPageReference({ state }) {
        const { c__id } = state;
        if (c__id) this.workOrderId = c__id;
    }


    connectedCallback() {
        console.log('connectedCallback from FieldServiceTroubleshooting');
        analyzeUserAgent(this);
        this.showSpinner = false;
    }

    renderedCallback() {
        console.log('renderedCallback from FieldServiceTroubleshooting');
        analyzeFormFactor(this);
    }





    handleFilterChange(event) {
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
            this.searchTimeout = null;
        }

        const { value } = getNameAndValueOnChange(this, event);
        this.searchTimeout = setTimeout(() => {
            this.searchTerm = value;
        }, 1000);
    }


    handleToggleAccordionSection(event) {
        const { categoryName } = event.currentTarget.dataset;

        const category = this.errorCodesList.find(item => item.categoryName === categoryName);
        if (category) {
            category.isActive = !category.isActive;
            category.iconName = category.isActive ? 'utility:chevrondown' : 'utility:chevronright';
            category.sectionClassList = category.isActive ? 'slds-accordion__section slds-is-open' : 'slds-accordion__section';
        }
    }





    @wire(getRecord, { recordId: '$workOrderId', fields: ['Work_Order__c.Case__r.Asset.Product2.Name'] })
    wiredWorkOrder({ error, data }) {
        if (data) {
            // this.searchTerm = data.fields.Case__r.value.fields.Asset.value.fields.Product2.value.fields.Name.value;
        }
        else if (error) {
            console.error('Error:', error);
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }


    @wire(searchForErrorCode, { searchTerm: '$searchTerm' })
    wiredSearchForErrorCode({ error, data }) {
        if (data) {
            let index = 0;
            this.errorCodesList = data.length ? data.reduce((acc, current) => {
                const categoryName = current.Product_Name__c;
                const errorItem = {
                    id: current.Id,
                    index: index
                };
                index += 1;
                const category = acc.find(item => item.categoryName === categoryName);
                if (category) {
                    category.errorItems.push(errorItem);
                } else {
                    acc.push({
                        index: index,
                        categoryName: categoryName,
                        iconName: 'utility:chevronright',
                        sectionClassList: 'slds-accordion__section',
                        errorItems: [errorItem]
                    });
                    index++;
                }
                return acc;
            }, []) : null;

            if (this.errorCodesList && this.errorCodesList.length > 0) {
                this.errorCodesList[0].isActive = true;
                this.errorCodesList[0].iconName = 'utility:chevrondown';
                this.errorCodesList[0].sectionClassList = 'slds-accordion__section slds-is-open';
            }

        }
        else if (error) {
            console.error('Error:', error);
            showToast(this, 'Error', 'Something went wrong', 'error', error);
        }
    }


}