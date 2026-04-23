import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import saveActivities from '@salesforce/apex/ActivityLoggingController.saveActivities';
import getTaskPicklistValues from '@salesforce/apex/ActivityLoggingController.getTaskPicklistValues';
import getCurrentUser from '@salesforce/apex/ActivityLoggingController.getCurrentUser';
import getServiceAppointmentName from '@salesforce/apex/ActivityLoggingController.getServiceAppointmentName';
import searchContacts from '@salesforce/apex/ActivityLoggingController.searchContacts';
import { getNameAndValueOnChange } from 'c/utilJS';
import { NavigationMixin } from 'lightning/navigation';
import { showToast, disablePullToRefresh } from 'c/utilJS';
export default class ActivityLogging extends NavigationMixin(LightningElement) {
    @api recordId;
    isNewTask = false;
    isLogACall = false;
    @track relatedToName;
    @track subjectOptions = [];
    @track taskSubtypeOptions = [];
    @track activities = [];
    @track showActionPopup = true;
    @track selectedAction = null;
    @track AssignedToId = '';
    @track contactVisible = false;
    @track contacts = [];

    handleClose() {
        history.go(-1);
    }
    handleActionSelection(event) {
        const action = event.target.dataset.action;
        this.showActionPopup = false;

        if (action === 'New Task') {
            this.isNewTask = true;
        } else if (action === 'Log a Call') {
            this.isLogACall = true;
        }
    }


    handleGoBack() {
        this.selectedAction = null;
        this.showActionPopup = true;
    }


    connectedCallback() {
        this.loadPicklistValues();
        this.fetchCurrentUser();
        disablePullToRefresh(this);
    }

    loadPicklistValues() {
        getTaskPicklistValues()
            .then((data) => {
                console.log('picklistdata', data);
                const parsedData = JSON.parse(data);
                this.subjectOptions = parsedData.Subject;
                this.taskSubtypeOptions = parsedData.TaskSubtype;
            })
            .catch((error) => {
                console.error('Error fetching picklist values:', error);
            });
    }

    fetchCurrentUser() {
        getCurrentUser()
            .then((user) => {
                this.currentUser = user;
                this.AssignedToId = user.Id;
            })
            .catch((error) => {
                console.error('Error fetching current user:', error);
            });
    }
    @track caseAccountId;
    fetchRelatedToName() {
        getServiceAppointmentName({ recordId: this.recordId })
            .then((result) => {
                console.log('result', result);
                this.serviceAppointment = result;
                console.log('Service Appointment Data:', this.serviceAppointment);
                this.relatedToName = result.Name;
                this.caseAccountId = result.Case__r.AccountId
                console.log('Related To Name:', this.relatedToName);
                console.log('caseAccountId:', this.caseAccountId);

            })
            .catch((error) => {
                console.error('Error fetching Related To Name:', error);
                this.relatedToName = 'Unknown';
            });
    }

    updateContactFilters() {
        if (this.recordId) {
            this.contactFilters = {
                criteria: [
                    {
                        fieldPath: 'AccountId',
                        operator: 'eq',
                        value: this.caseAccountId,
                    }]
            };
        }
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.recordId = currentPageReference?.state?.c__serviceAppointmentId || null;
        console.log('this.recordId', this.recordId);
        if (this.recordId) {
            this.fetchRelatedToName();
            setTimeout(() => {
                this.updateContactFilters();
            }, 1000);
        }
    }



    handleNewTask() {
        this.isNewTask = true;
        this.isLogACall = false;
    }

    handleLogACall() {
        this.isLogACall = true;
        this.isNewTask = false;
    }
    @track selectedRecordId;
    handleChange(event) {
        const fieldName = event.target.label;
        let value = event.target.value;
        if (fieldName === 'Name') {
            value = event.detail.recordId;
        }
        console.log('Field Name:', fieldName);
        console.log('Field Value:', value);

        const type = this.isNewTask ? 'New Task' : 'Log a Call';


        let activity = this.activities.find((act) => act.type === type);
        if (!activity) {
            activity = { type, fields: {}, recordId: this.recordId };
            this.activities.push(activity);
        }

        activity.fields[fieldName] = value;
        if (this.AssignedToId) {
            activity.fields['Assigned To'] = this.AssignedToId;
        }

        if (fieldName == 'Name') {
            const value = event.detail.recordId;
            if (value) {
                this.searchContacts(value);
            } else {
                this.contacts = [];
            }
        }
    }

    saveActivities() {
        console.log('this.activities', this.activities);
        saveActivities({ activityData: this.activities })
            .then(() => {
                // alert('Activities saved successfully!');
                showToast(this, 'Success', 'Activities saved successfully.', 'success');
                this.activities = [];
                this.isNewTask = false;
                this.isLogACall = false;
            })
            .catch((error) => {
                console.error('Error saving activities:', error);
                // alert('Failed to save activities.');
                showToast(this, 'Error', 'Failed to save activities.', 'error', error);

            });
    }

    searchContacts(searchKey) {
        searchContacts({ searchKey })
            .then((result) => {
                this.contacts = result;
            })
            .catch((error) => {
                console.error('Error fetching contacts:', error);
                this.contacts = [];
            });
    }

    selectContact(event) {
        const selectedContactId = event.target.dataset.id;
        const selectedContactName = event.target.dataset.name;
        console.log('Selected Contact Name:', selectedContactName);
        this.selectedContactId = selectedContactId;
        this.selectedContactName = selectedContactName;
        this.contacts = [];
        const type = this.isNewTask ? 'New Task' : 'Log a Call';

        let activity = this.activities.find((act) => act.type === type);
        if (!activity) {
            activity = { type, fields: {}, recordId: this.recordId };
            this.activities.push(activity);
        }

        activity.fields['Name'] = selectedContactId;
    }

    handleCancel() {
        this.navigateToLWC();
        this.isNewTask = false;
        this.isLogACall = false;
        this.showActionPopup = true;
    }

    navigateToLWC() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__fieldServiceCreateVisit'
            }
        });
    }
}