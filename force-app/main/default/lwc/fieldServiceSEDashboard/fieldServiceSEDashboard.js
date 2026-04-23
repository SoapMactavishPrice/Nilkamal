import { LightningElement, track, wire } from 'lwc';
import getTypeWiseOpenCaseCount from '@salesforce/apex/FieldServiceSEDashboardController.getTypeWiseOpenCaseCount';
import getSpareAndServiceGoalVsAchieve from '@salesforce/apex/FieldServiceSEDashboardController.getSpareAndServiceGoalVsAchieve';
import getServiceGoalVsAchieve from '@salesforce/apex/FieldServiceSEDashboardController.getServiceGoalVsAchieve';
import getAMCAndWarrantyPopulationChart from '@salesforce/apex/FieldServiceSEDashboardController.getAMCAndWarrantyPopulationChart';
import getAMCBusinessChart from '@salesforce/apex/FieldServiceSEDashboardController.getAMCBusinessChart';
import getLast7DaysCaseHistory from '@salesforce/apex/FieldServiceSEDashboardController.getLast7DaysCaseHistory';
import getListOfOpenCases from '@salesforce/apex/FieldServiceSEDashboardController.getListOfOpenCases';
import getListOfReturnableSampleQuoteLineItems from '@salesforce/apex/FieldServiceSEDashboardController.getListOfReturnableSampleQuoteLineItems';

export default class FieldServiceSEDashboard extends LightningElement {

    @track caseData = [];
    @track goalData = [];
    @track servicegoalData = [];
    @track amcData = [];

    connectedCallback() {
        // this.fetchCaseData();
        // this.fetchGoalData();
        // this.fetchAMCData();
    }

    fetchCaseData() {
        getTypeWiseOpenCaseCount()
            .then((result) => {
                console.log('result-->', result);
                this.caseData = this.formatCaseData(result);
            })
            .catch((error) => {
                console.error('Error fetching data: ', error);
            });
    }

    formatCaseData(data) {
        return Object.keys(data).map((key) => ({
            type: key,
            zeroToTwo: data[key]['0-2'],
            threeToFour: data[key]['3-4'],
            fivePlus: data[key]['5+']
        }));
    }



    @wire(getTypeWiseOpenCaseCount)
    wiredCaseData({ error, data }) {
        if (data) {
            console.log('Fetched Open Case Data:', JSON.stringify(data), Object.keys(data));
            this.caseData = Object.keys(data).reverse().map(type => ({
                type,
                zeroToTwo: data[type].zeroToTwo,
                threeToFour: data[type].threeToFour,
                fivePlus: data[type].fivePlus
            }));
            this.showSpinner = false;
            this.hasNoCaseData = this.caseData.length === 0;
        } else if (error) {
            console.error('Error fetching open case data:', error);
            this.showSpinner = false;
            this.hasNoCaseData = true;
        }
    }

    fetchGoalData() {
        getSpareAndServiceGoalVsAchieve()
            .then((result) => {
                this.goalData = result.map(item => ({
                    ...item,
                    salesAchievement: item.salesAchievement || 0,
                    percentageAchieved: this.calculateAchievementPercentage(item.salesAchievement, item.salesGoal)
                }));
            })
            .catch((error) => {
                console.error('Error fetching Spare and Service Goal data:', error);
            });
    }

    fetchServiceGoalData() {
        getServiceGoalVsAchieve()
            .then((result) => {
                this.servicegoalData = result.map(item => ({
                    ...item,
                    serviceAchievement: item.serviceAchievement || 0,
                    percentageAchieved: this.calculateAchievementPercentage(item.serviceAchievement, item.serviceGoal)
                }));
            })
            .catch((error) => {
                console.error('Error fetching Spare and Service Goal data:', error);
            });
    }

    calculateAchievementPercentage(achievement, goal) {
        return goal ? ((achievement || 0) / goal * 100).toFixed(2) : '0.00';
    }

    @track hasNoGoalData = true;
    @track hasServiceNoGoalData = true;

    // @wire(getSpareAndServiceGoalVsAchieve)
    // wiredGoalData({ error, data }) {
    //     if (data) {
    //         console.log('Fetched Goal Data:', JSON.stringify(data));
    //         this.goalData = data.map(goal => ({
    //             id: goal.Id,
    //             name: goal.Name,
    //             financialYear: goal.Financial_Year__c,
    //             salesGoal: goal.Sales_Goal__c,
    //             salesAchievement: goal.Sales_Achievement__c,
    //             percentageAchieved: ((goal.Sales_Achievement__c / goal.Sales_Goal__c) * 100).toFixed(2)
    //         }));
    //         this.showSpinner = false;
    //         this.hasNoGoalData = this.goalData.length === 0;
    //     } else if (error) {
    //         console.error('Error fetching goal data:', error);
    //         this.showSpinner = false;
    //         this.hasNoGoalData = true;
    //     }
    // }

    @wire(getSpareAndServiceGoalVsAchieve)
    wiredGoalData({ error, data }) {
        if (data) {
            console.log('Fetched Goal Data:', JSON.stringify(data));
            this.goalData = data.map(goal => ({
                id: goal.id,
                name: goal.name,
                financialYear: goal.financialYear,
                salesGoal: goal.salesGoal,
                salesAchievement: goal.salesAchievement,
                percentageAchieved: goal.salesAchievement && goal.salesGoal ? ((goal.salesAchievement / goal.salesGoal) * 100).toFixed(2) : '0.00'
            }));
            this.showSpinner = false;
            this.hasNoGoalData = this.goalData.length === 0;
        } else if (error) {
            console.error('Error fetching goal data:', error);
            this.showSpinner = false;
            this.hasNoGoalData = true;
        }
    }


    @wire(getServiceGoalVsAchieve)
    wiredServiceGoalData({ error, data }) {
        if (data) {
            console.log('wired Service Goal Data:', JSON.stringify(data));
            this.servicegoalData = data.map(goal => ({
                id: goal.id,
                name: goal.name,
                financialYear: goal.financialYear,
                serviceGoal: goal.serviceGoal,
                serviceAchievement: goal.serviceAchievement,
                percentageAchieved: goal.serviceAchievement && goal.serviceGoal ? ((goal.serviceAchievement / goal.serviceGoal) * 100).toFixed(2) : '0.00'
            }));
            this.showSpinner = false;
            this.hasServiceNoGoalData = this.servicegoalData.length === 0;
        } else if (error) {
            console.error('Error fetching goal data:', error);
            this.showSpinner = false;
            this.hasServiceNoGoalData = true;
        }
    }


    fetchAMCData() {
        getAMCAndWarrantyPopulationChart()
            .then((result) => {
                console.log('resuktss-->', result);

                let data = Array.isArray(result) ? result : [result];

                this.amcData = data.map(record => ({
                    name: record.name,
                    totalAssets: record.totalAssets,
                    assetsWithActiveAMC: record.assetsWithActiveAMC,
                    assetsWithActiveWarranty: record.assetsWithActiveWarranty,
                    assetsWithOutOfWarrantyAndNoAMC: record.assetsWithOutOfWarrantyAndNoAMC,
                    amcCoverage: ((record.assetsWithActiveAMC / record.totalAssets) * 100).toFixed(2) // Calculate AMC %
                }));
            })
            .catch((error) => {
                console.error('Error fetching AMC data:', error);
            });
    }

    @track hasNoAmcData = true;

    @wire(getAMCAndWarrantyPopulationChart)
    wiredAmcData({ error, data }) {
        if (data) {
            console.log('Fetched AMC & Warranty Data:', JSON.stringify(data));

            this.amcData = data;

            this.showSpinner = false;
            this.hasNoAmcData = this.amcData.length === 0;
        } else if (error) {
            console.error('Error fetching AMC & Warranty data:', error);
            this.showSpinner = false;
            this.hasNoAmcData = true;
        }
    }





    @track amcBusinessData = [];
    @track hasNoAmcBusinessData = true;

    @wire(getAMCBusinessChart)
    wiredAMCBusinessData({ error, data }) {
        if (data) {
            console.log('getAMCBusinessChart data-->', data);
            this.amcBusinessData = data;
            this.showSpinner = false;
            this.hasNoAmcBusinessData = !data || Object.keys(data).length === 0;
        } else if (error) {
            console.error('Error fetching AMC business data', error);
            this.showSpinner = false;
            this.hasNoAmcBusinessData = true;
        }
    }


    // @wire(getAMCBusinessChart)
    // wiredAmcBusinessData({ error, data }) {
    //     if (data) {
    //         console.log('Fetched AMC Business Data:', JSON.stringify(data));
    //         this.amcBusinessData = data;
    //         this.showSpinner = false;
    //         this.hasNoAmcBusinessData = !data || Object.keys(data).length === 0;
    //     } else if (error) {
    //         console.error('Error fetching AMC Business data:', error);
    //         this.showSpinner = false;
    //         this.hasNoAmcBusinessData = true;
    //     }
    // }


    @track caseHistoryData = [];
    @wire(getLast7DaysCaseHistory)
    getLast7DaysCaseHistory({ error, data }) {
        if (data) {
            console.log('data-->', data);
            this.caseHistoryData = data;
        } else if (error) {
            console.error('Error fetching case history data', error);
        }
    }


    @track cases = [];
    @track hasNoCases = true;
    error;
    @wire(getListOfOpenCases)
    wiredCases({ error, data }) {
        if (data) {
            console.log('cases data-->', data);
            this.cases = data.map(caseItem => {
                return {
                    ...caseItem,
                    createdDate: this.formatDate(caseItem.createdDate),
                    assignedDateTime: this.formatDate(caseItem.assignedDateTime)
                };
            });
            console.log('this.cases-->', this.cases);
            this.error = undefined;
            this.showSpinner = false;
            this.hasNoCases = this.cases.length === 0;
        } else if (error) {
            this.error = error;
            this.cases = undefined;
            this.showSpinner = false;
            this.hasNoCases = true;
        }
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        const day = String(date.getUTCDate()).padStart(2, '0');
        const month = date.toLocaleString('default', { month: 'short' });
        const year = date.getUTCFullYear();
        return `${day}-${month}-${year}`;
    }


    // @wire(getListOfOpenCases)
    // wiredCases({ error, data }) {
    //     if (data) {
    //         console.log('Fetched Open Cases Data:', JSON.stringify(data));
    //         this.cases = data.map(caseItem => ({
    //             id: caseItem.Id,
    //             caseNumber: caseItem.CaseNumber,
    //             accountName: caseItem.Account.Name,
    //             createdDate: new Date(caseItem.CreatedDate).toLocaleDateString(),
    //             assignedDateTime: caseItem.Assigned_Date_Time__c ? new Date(caseItem.Assigned_Date_Time__c).toLocaleString() : 'N/A'
    //         }));
    //         this.showSpinner = false;
    //         this.hasNoCases = this.cases.length === 0;
    //     } else if (error) {
    //         console.error('Error fetching open cases:', error);
    //         this.showSpinner = false;
    //         this.hasNoCases = true;
    //     }
    // }




    @track returnableQuoteLines = [];
    @track hasNoReturnableQuoteLines = true;
    @wire(getListOfReturnableSampleQuoteLineItems)
    wiredReturnableQuoteLines({ error, data }) {
        if (data) {
            console.log('getListOfReturnableSampleQuoteLineItems data-->', data);
            this.returnableQuoteLines = data.map(returnableQuoteLine => ({
                customerName: returnableQuoteLine?.Quote?.Account?.Name,
                materialCode: returnableQuoteLine?.Product2?.Name,
                materialDescription: returnableQuoteLine?.Product2?.Description,
                quantity: returnableQuoteLine?.Quantity,
                amount: returnableQuoteLine?.Grand_Price__c,
                ownerName: returnableQuoteLine?.Quote?.Opportunity?.Owner?.Name
            }))
            this.showSpinner = false;
            this.hasNoReturnableQuoteLines = !data || Object.keys(data).length === 0;
        } else if (error) {
            console.error('Error fetching returnable quote lines:', error);
            this.showSpinner = false;
            this.hasNoReturnableQuoteLines = true;
        }
    }


}