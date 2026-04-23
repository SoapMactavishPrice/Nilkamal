import { LightningElement, track, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getAssetDetails from '@salesforce/apex/CaseHistory.getAssetDetails';
import { CurrentPageReference } from 'lightning/navigation';





export default class CaseHistory extends LightningElement {

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.fetchAssetDetails();
    }
    @track assets = [];
    @track error;
    @track toggleRight = true;
    @track toggleDown = false;

    get isWarrantyAvailable() {
        return this.assets && this.assets.Warranties && this.assets.Warranties.length > 0;
        console.log('isWarrantyAvailable', isWarrantyAvailable);
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference?.state?.c__id) {
            this.recordId = currentPageReference?.state?.c__id || null;
        }
        console.log('this.recordId', this.recordId);
    }

    connectedCallback() {

    }

    fetchAssetDetails() {
        getAssetDetails({ caseId: this.recordId })
            .then((data) => {
                let newData = JSON.parse(JSON.stringify(data));
                console.log('newData-->', newData);
                console.log('data--->>', data);
                if (newData && newData.length > 0) {
                    newData[0].Tasks = newData[0].Tasks.map(caseItem => ({
                        ...caseItem,
                        showDetails: false,
                        iconName: 'utility:chevronright'
                    }));

                    if (newData[0].AMCs) {
                        newData[0].AMCs = newData[0].AMCs.map(amc => ({
                            ...amc,
                            status: this.isAMCActive(amc) ? 'Active' : 'Expired'
                        }));
                    }

                    if (newData[0].Warranties) {
                        newData[0].Warranties = newData[0].Warranties.map(warranty => ({
                            ...warranty,
                            status: this.isWarrantyActive(warranty) ? 'Active' : 'Expired',
                            isActive: this.isWarrantyActive(warranty)
                        }));

                    }
                    if (newData[0].Tasks && newData[0].Tasks.length === 0) {
                        this.showIllustrationForChild = true;
                        this.showIllustration = false;
                    } else {
                        this.showIllustrationForChild = false;
                        this.showIllustration = false;
                    }
                } else {
                    this.assets = [];
                    this.error = "No data available for this asset.";
                    this.showIllustration = true;
                    this.showIllustrationForChild = false;
                    return;
                }

                console.log('newData--->>', newData);
                let modifiedData = newData[0];
                console.log('modifiedData', modifiedData);



                // if (data[0].Cases && Array.isArray(data[0].Cases)) {
                //     data[0].Cases = data[0].Cases.map(element => ({
                //         ...element,
                //         showDetails: false
                //     }));
                // }


                // this.assets = data.map(asset => ({
                //     ...asset,
                //     showDetails: false
                // }));
                this.assets = newData[0];
                console.log('assets--->>', this.assets);
                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;
                this.assets = [];
                console.error('Error fetching assets: ', error);
            });
    }

    // isExpired(warranty) {
    //     console.log('Checking warranty status:', warranty.status);

    //     // return warranty.status.toLowerCase() === 'expired';
    //     const isExpired = warranty.status.toLowerCase() === 'expired';
    //     console.log('Is expired:', isExpired);
    //     return isExpired;
    // }

    isAMCActive(AMC) {
        const today = new Date();
        const amcEndDate = new Date(AMC.AMCEndDate);
        return amcEndDate > today;
    }

    isWarrantyActive(warranty) {
        const today = new Date();
        const warrantyEndDate = new Date(warranty.WarrantyEndDate);
        return warrantyEndDate > today;

    }


    // fetchAssetDetails() {
    //     getAssetDetails({ caseId: this.recordId })
    //         .then((data) => {
    //             console.log('data--->>', data);

    //             if (data && data[0] && Array.isArray(data[0].cases)) {
    //                 // Use the spread operator to add `showDetails` to each case
    //                 data[0].cases = data[0].cases.map(caseItem => ({
    //                     ...caseItem,         // Copy all properties of the case
    //                     showDetails: false   // Add the `showDetails` field
    //                 }));
    //             }


    //             // Set the modified data to this.assets
    //             this.assets = data;

    //             console.log('assets--->>', this.assets);
    //             this.error = undefined;
    //         })
    //         .catch((error) => {
    //             this.error = error;
    //             this.assets = [];
    //             console.error('Error fetching assets: ', error);
    //         });
    // }






    toggleDetails(event) {
        console.log('click');

        const caseId = event.currentTarget.dataset.id;
        const caseToToggle = this.assets.Tasks.find(task => task.Id === caseId);

        console.log('caseId', caseId);

        // Loop through each case in this.assets.Cases
        for (let i = 0; i < this.assets.Tasks.length; i++) {
            const caseItem = this.assets.Tasks[i];

            if (caseItem.Id === caseId) {
                console.log('caseItem.showDetails', caseItem.showDetails, caseItem);

                caseItem.showDetails = !caseItem.showDetails;
                caseToToggle.iconName = caseToToggle.showDetails ? 'utility:chevrondown' : 'utility:chevronright';
                if (!caseItem.showDetails) {
                    caseItem.iconName = 'utility:chevronright';
                }
            }
        }

        // After modification, we need to update the assets array
        console.log('this.assets-->>>', this.assets);
    }

}