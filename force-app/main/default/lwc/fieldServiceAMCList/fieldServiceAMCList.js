import { LightningElement } from 'lwc';
import getAssets from '@salesforce/apex/AMCListDataController.getAssetRecords';

export default class FieldServiceAMCList extends LightningElement {
    allAssets = [];
    displayedAssets = [];
    currentPage = 1;
    pageSize = 10;

    connectedCallback() {
        this.fetchAssets();
    }

    fetchAssets() {
        getAssets()
            .then((data) => {
                console.log('Data from Apex:', data);

                const parsedData = JSON.parse(data);
                this.allAssets = parsedData.map((asset, index) => ({
                    ...asset,
                    index: index + 1,
                    expiryDate: this.getExpiryDate(asset),
                    recordLink: `/lightning/r/Asset/${asset.asset.Id}/view`
                }));
                this.updateDisplayedAssets();
            })
            .catch((error) => {
                console.error('Error fetching assets:', error);
            });
    }

    updateDisplayedAssets() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = this.currentPage * this.pageSize;
        this.displayedAssets = this.allAssets.slice(start, end);
    }

    getExpiryDate(asset) {
        if (asset.amcs && asset.amcs.length > 0) {
            return asset.amcs[0].AMC_End_Date__c;
        } else if (asset.warranties && asset.warranties.length > 0) {
            return asset.warranties[0].Warranty_End_Date__c;
        }
        return null;
    }

    handleNext() {
        if (this.currentPage < Math.ceil(this.allAssets.length / this.pageSize)) {
            this.currentPage++;
            this.updateDisplayedAssets();
        }
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updateDisplayedAssets();
        }
    }

    get disablePrevious() {
        return this.currentPage === 1;
    }

    get disableNext() {
        return this.currentPage >= Math.ceil(this.allAssets.length / this.pageSize);
    }
}