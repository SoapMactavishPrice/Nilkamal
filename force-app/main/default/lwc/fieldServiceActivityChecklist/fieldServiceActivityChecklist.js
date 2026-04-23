import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToUrl, openLightningModal, scrollToTop, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh, navigateBackInHistory } from 'c/utilJS';


// import getChecklistData from '@salesforce/apex/FieldServiceCaptureInteraction.getChecklistData';
import getChecklistData from '@salesforce/apex/FieldServiceCaptureInteraction.getChecklistData';
import saveChecklistData from '@salesforce/apex/FieldServiceCaptureInteraction.saveChecklistData';





export default class FieldServiceActivityChecklist extends NavigationMixin(LightningElement) {
    @track checklistItems = [];
    @track showSpinner = false;


    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.workorderId = currentPageReference.state.c__id;
        this.serviceAppointmentId = currentPageReference.state.c__serviceAppointmentId;
        // console.log('this.workorderId', this.workorderId);
        // console.log('this.serviceAppointmentId', this.serviceAppointmentId);
    }


    connectedCallback() {
        this.loadChecklistData();
        disablePullToRefresh(this);
    }


    loadChecklistData() {
        this.showSpinner = true;
        getChecklistData({ workOrderId: this.workorderId })
            .then(result => {
                // console.log('getChecklistData', result);
                const groupedData = JSON.parse(JSON.stringify(result)).reduce((acc, item) => {
                    const category = item.Checklist_Category__c;
                    if (!acc[category]) {
                        acc[category] = [];
                    }
                    acc[category].push(item);
                    return acc;
                }, {});

                this.checklistItems = Object.entries(groupedData).map(([category, checkpoints]) => ({
                    Checklist_Category__c: category,
                    checkpoints: checkpoints
                }));
                // console.log('this.checklistItems', JSON.stringify(this.checklistItems), this.checklistItems);
            })
            .catch(error => {
                console.error('Error fetching checklist data', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }


    get observationOptions() {
        return [
            { label: 'Ok', value: 'Ok' },
            { label: 'Not Ok', value: 'Not Ok' },
            { label: 'Not Applicable', value: 'Not Applicable' }
        ];
    }


    handleChecklistChange(event) {
        const { name, value, dataset: { checklistCategory, checklistMasterId } } = event.target;

        const category = this.checklistItems.find(item => item.Checklist_Category__c === checklistCategory);
        if (category) {
            const checkpoint = category.checkpoints.find(checkpoint => checkpoint.Checklist_Master__c === checklistMasterId);
            if (checkpoint) {
                checkpoint.Observation__c = value;
            }
        }
    }



    submit() {
        // console.log('click button');
        this.showSpinner = true;

        const workOrderChecklist = [];
        this.checklistItems.forEach(category => {
            category.checkpoints.forEach(checkpoint => {
                workOrderChecklist.push(checkpoint);
            });
        })
        // console.log('workOrderChecklist', workOrderChecklist);

        saveChecklistData({ workOrderChecklist, serviceAppointmentId: this.serviceAppointmentId })
            .then(result => {
                showToast(this, 'Success', 'Checklist data saved successfully!', 'success');
                navigateBackInHistory(this);
            })
            .catch(error => {
                showToast(this, 'Error', 'There was an error saving the checklist data.', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }


}