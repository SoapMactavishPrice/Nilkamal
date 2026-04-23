import { LightningElement, wire, track,api } from 'lwc';
import getOutStanding from '@salesforce/apex/IntegrationHandler.getOutStanding';
import getAccountNameById from '@salesforce/apex/IntegrationHandler.getAccountNameById';
import { CurrentPageReference } from 'lightning/navigation';
const columns = [
    // { label: 'Customer Number', fieldName: 'Kunnr' },
    // { label: 'Customer Name', fieldName: 'Text4' },
    { label: 'Po Number', fieldName: 'Bstkd' },
    { label: 'Po Date', fieldName: 'Bstdk' },
    { label: 'Document Number', fieldName: 'Belnr' },
    { label: 'Document Date', fieldName: 'Bldat' },
    { label: 'Amount', fieldName: 'Dmbtr', type: 'currency' },
    { label: 'Outstanding Amount', fieldName: 'Colum7' , type: 'currency' },
    { label: 'Days', fieldName: 'Noday' }
    // { label: 'Division', fieldName: 'Spart' },
    // { label: 'On Account', fieldName: 'Colum6' },
    // { label: 'Sales Office', fieldName: 'Vkbur' },
    // { label: 'Sales Office Name', fieldName: 'Text1' },
    // { label: 'Sales Group', fieldName: 'Vkgrp' },
    // { label: 'Sales Office Desc.', fieldName: 'Text2' },
    // { label: 'Location', fieldName: 'Ort01' },
    // { label: 'Cash Discount', fieldName: 'Zbd1t' },
    // { label: 'Sale Org', fieldName: 'Vkorg' },
    // { label: 'Company Code', fieldName: 'Bukrs' },
    // { label: 'Cust No.', fieldName: 'Kunnr1' },
    // { label: 'MG2_NEW', fieldName: 'Text10' }
];
export default class CustomerOutstandingReportData extends LightningElement {
      
    @track data = [];
    columns = columns;
    @track showSpinner=true;

    @track accountId;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && currentPageReference.state) {
            this.accountId = currentPageReference.state.c__accountId;
        }
    }

    
    @track accName=''
    connectedCallback() {

         setTimeout(() => {
                getOutStanding({accId:this.accountId})
                .then((res)=>{
                        if (res) {
                        console.log('wiredData  : ',JSON.stringify(res));
                        var rec=[];
                        res.forEach(element => {
                            if(element.Colum7 >0){
                                rec.push(element);
                            }
                        });
                        this.data = rec;
                        if(this.data.length>0){
                            this.showSpinner=false;
                        }
                    } else if (error) {
                        console.error('Error fetching data:', error);
                        this.showSpinner=false;
                    }
                })

                getAccountNameById({accId:this.accountId})
                .then((res)=>{
                        if (res) {
                        console.log('wiredData  : ',JSON.stringify(res));
                        this.accName='Outstanding of '+res
                        } else if (error) {
                        
                        }
                })

                
        }, 2000);
        
    }


}