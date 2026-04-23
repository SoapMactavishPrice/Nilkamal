import { LightningElement, wire, track,api } from 'lwc';
import getOutStanding from '@salesforce/apex/IntegrationHandler.getOutStanding';
import { NavigationMixin } from 'lightning/navigation';
export default class CustomerOutstandingReport extends LightningElement {
    @api recordId; // Auto-passed when placed on Account Page       
    @track data = [];
    @track showSpinner=true;

    connectedCallback() {

         setTimeout(() => {
                getOutStanding({accId:this.recordId})
                .then((res)=>{
                        console.log('wiredData  : ',JSON.stringify(res));
                        if (res.length >0) {
                        //this.data = res;
                        this.showSpinner=false;
                        this.openCustomTab();
                        
                    } else {
                        console.error('Error fetching data:');
                        this.showSpinner=false;
                        this.data=false;
                    }
                })
        }, 2000);
        
    }
    openCustomTab() {
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__navItemPage',
        //     attributes: {
        //         apiName: 'Customer_Outstanding_Report' // Replace with your tab's Developer Name
        //     },
        //     state: {
        //         c__accountId: this.recordId // Pass Account Id in URL
        //     }
        // });
        let accountId = this.recordId;
        let tabName = 'Customer_Outstanding_Report'; // Replace with your actual tab developer name

        let url = `/lightning/n/${tabName}?c__accountId=${accountId}`;
        window.open(url, '_blank');
        // window.openurl;
    }


}