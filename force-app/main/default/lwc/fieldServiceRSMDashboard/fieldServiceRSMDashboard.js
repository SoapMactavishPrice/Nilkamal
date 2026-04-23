import { LightningElement, track, wire } from 'lwc';
import getListOfAssetsWhoseWarrantyInNearingExpire from '@salesforce/apex/FieldServiceRSMDashboardController.getListOfAssetsWhoseWarrantyInNearingExpire';
import getListAssetsWhoseAMCInNearingExpire from '@salesforce/apex/FieldServiceRSMDashboardController.getListAssetsWhoseAMCInNearingExpire';
import getListOfAssetsWhoseAmcExpiredButNotRenewed from '@salesforce/apex/FieldServiceRSMDashboardController.getListOfAssetsWhoseAmcExpiredButNotRenewed';
import getListOfAssetsWhoseWarrantyExpiredButAMCNotRenewed from '@salesforce/apex/FieldServiceRSMDashboardController.getListOfAssetsWhoseWarrantyExpiredButAMCNotRenewed';
import getNonActiveCustomers from '@salesforce/apex/FieldServiceRSMDashboardController.getNonActiveCustomers';
import getTeamAttendance from '@salesforce/apex/FieldServiceRSMDashboardController.getTeamAttendance';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartLibraries from '@salesforce/resourceUrl/ChartLibraries';
import { renderChartJs, renderApexChart } from 'c/utilJS';
import getPinCodeWiseNonActiveAssets from '@salesforce/apex/FieldServiceRSMDashboardController.getPinCodeWiseNonActiveAssets';
import getQuoteCountStatusWise from '@salesforce/apex/FieldServiceRSMDashboardController.getQuoteCountStatusWise';
import getBusinessRevenue from '@salesforce/apex/FieldServiceRSMDashboardController.getBusinessRevenue';
import getLast7DaysCaseHistory from '@salesforce/apex/FieldServiceRSMDashboardController.getLast7DaysCaseHistory';
// import getNonActiveCustomers from '@salesforce/apex/FieldServiceRSMDashboardController.getNonActiveCustomers';
import getListOfAssetsWhoseAMCDueEvenAfterPMVisit from '@salesforce/apex/FieldServiceRSMDashboardController.getListOfAssetsWhoseAMCDueEvenAfterPMVisit';
import { getDataConnectorSourceObjects } from 'lightning/analyticsWaveApi';
import getAMCBusinessChart from '@salesforce/apex/FieldServiceRSMDashboardController.getAMCBusinessChart';
import getOpenCasesOlderThan4Days from '@salesforce/apex/FieldServiceRSMDashboardController.getOpenCasesOlderThan4Days';
import getListOfOpenCases from '@salesforce/apex/FieldServiceRSMDashboardController.getListOfOpenCases';
import getPendingOrders from '@salesforce/apex/FieldServiceRSMDashboardController.getPendingOrders';
import getListOfReturnableSampleQuoteLineItemsRSMWise from '@salesforce/apex/FieldServiceRSMDashboardController.getListOfReturnableSampleQuoteLineItemsRSMWise';









export default class FieldServiceRSMDashboard extends LightningElement {
    @track chartJS;
    @track apexChart;
    @track showSpinner = true;


    chartJsInitialized = false;
    apexChartInitialized = false;


    pinCodeData = [];
    pinCodeLabels = [];



    @track assets = [];
    @track hasNoAssets = false;


    @wire(getListOfAssetsWhoseWarrantyInNearingExpire)
    wiredAssets({ error, data }) {
        if (data) {
            console.log('Fetched Data:', JSON.stringify(data));
            this.assets = data.map(asset => ({
                assetId: asset.assetId,
                serialNumber: asset.serialNumber,
                accountId: asset.accountId,
                accountName: asset.accountName,
                pinCodeId: asset.pinCodeId,
                pinCodeName: asset.pinCodeName,
                warrantyId: asset.warrantyId,
                warrantyStartDate: asset.warrantyStartDate,
                warrantyEndDate: asset.warrantyEndDate
            }));
            this.showSpinner = false;
            this.hasNoAssets = this.assets.length === 0;
        } else if (error) {
            console.error('Error fetching assets:', error);
            this.showSpinner = false;
            this.hasNoAssets = true;
        }
    }
    //


    @track amcAssets = [];
    @track hasNoAmcRenewalDue = false;
    // get amcRenewalDueData() {
    //     return this.amcRenewalDue || [];
    // }

    @track amcAssetsColumns = {
        accountName: { isAsc: false, isDesc: false },
        serialNumber: { isAsc: false, isDesc: false },
        productDescription: { isAsc: false, isDesc: false },
        amcStartDate: { isAsc: false, isDesc: false },
        amcEndDate: { isAsc: false, isDesc: false },
        seName: { isAsc: false, isDesc: false }
    };

    @wire(getListAssetsWhoseAMCInNearingExpire)
    wiredAMCAssets({ error, data }) {
        if (data) {
            console.log('Fetched AMC Assets Data:', JSON.stringify(data));
            this.amcAssets = data.map(amcAsset => ({
                assetId: amcAsset.assetId,
                serialNumber: amcAsset.serialNumber,
                // accountId: amcAsset.accountId,
                accountName: amcAsset.accountName,
                productDescription: amcAsset.productDescription,
                amcId: amcAsset.amcId,
                amcName: amcAsset.amcName,
                amcStartDate: amcAsset.amcStartDate,
                amcEndDate: amcAsset.amcEndDate,
                seName: amcAsset.seName
            }));
            this.showSpinner = false;
            this.hasNoAmcRenewalDue = this.amcAssets.length === 0;
            console.log('hasNoAmcRenewalDue', this.hasNoAmcRenewalDue);
        } else if (error) {
            console.error('Error fetching AMC assets:', error);
            this.showSpinner = false;
            this.hasNoAmcRenewalDue = true;
        }
    }





    @track amcExpiredAssets = [];
    @track hasNoAmcExpiredAssets = false;

    @track amcExpiredAssetsColumns = {
        accountName: { isAsc: false, isDesc: false },
        serialNumber: { isAsc: false, isDesc: false },
        productDescription: { isAsc: false, isDesc: false },
        amcStartDate: { isAsc: false, isDesc: false },
        amcEndDate: { isAsc: false, isDesc: false },
        seName: { isAsc: false, isDesc: false }
    };

    @wire(getListOfAssetsWhoseAmcExpiredButNotRenewed)
    wiredAMCExpiredAssets({ error, data }) {
        if (data) {
            console.log('Fetched AMC Expired Assets Data:', JSON.stringify(data));
            this.amcExpiredAssets = data.map(asset => ({
                assetId: asset.assetId,
                serialNumber: asset.serialNumber,
                accountId: asset.accountId,
                accountName: asset.accountName,
                productDescription: asset.productDescription,
                amcId: asset.amcId,
                amcName: asset.amcName,
                amcStartDate: asset.amcStartDate,
                amcEndDate: asset.amcEndDate,
                seName: asset.seName
            }));
            this.showSpinner = false;
            this.hasNoAmcExpiredAssets = this.amcExpiredAssets.length === 0;
        } else if (error) {
            console.error('Error fetching AMC expired assets:', error);
            this.showSpinner = false;
            this.hasNoAmcExpiredAssets = true;

        }
    }

    @track warrantyExpiredAssets = [];
    @track hasNoWarrantyExpiredAssets = false;


    @track warrantyExpiredAssetsColumns = {
        accountName: { isAsc: false, isDesc: false },
        serialNumber: { isAsc: false, isDesc: false },
        productDescription: { isAsc: false, isDesc: false },
        warrantyStartDate: { isAsc: false, isDesc: false },
        warrantyEndDate: { isAsc: false, isDesc: false },
        seName: { isAsc: false, isDesc: false }
    };

    @wire(getListOfAssetsWhoseWarrantyExpiredButAMCNotRenewed)
    wiredWarrantyExpiredAssets({ error, data }) {
        if (data) {
            console.log('Fetched Warranty Expired Assets Data:', JSON.stringify(data));
            this.warrantyExpiredAssets = data.map(asset => ({
                assetId: asset.assetId,
                serialNumber: asset.serialNumber,
                accountId: asset.accountId,
                accountName: asset.accountName,
                productDescription: asset.productDescription,
                pinCodeId: asset.pinCode,
                pinCodeName: asset.pinCodeName,
                warrantyStartDate: asset.warrantyStartDate || 'N/A',
                warrantyEndDate: asset.warrantyEndDate || 'N/A',
                seName: asset.seName
            }));
            this.showSpinner = false;
            this.hasNoWarrantyExpiredAssets = this.warrantyExpiredAssets.length === 0;
        } else if (error) {
            console.error('Error fetching warranty expired assets:', error);
            this.showSpinner = false;
            this.hasNoWarrantyExpiredAssets = true;
        }
    }

    // @track nonActiveCustomers = [];
    // @wire(getNonActiveCustomers)
    // wiredNonActiveCustomers({ error, data }) {
    //     if (data) {
    //         console.log('Fetched Non-Active Customers Data:', JSON.stringify(data));
    //         if (Array.isArray(data)) {
    //             this.nonActiveCustomers = data.map(asset => ({
    //                 assetId: asset.assetId,
    //                 serialNumber: asset.serialNumber,
    //                 accountId: asset.accountId,
    //                 accountName: asset.accountName,
    //                 pinCodeId: asset.pinCode,
    //                 pinCodeName: asset.pinCodeName,
    //                 warrantyId: asset.warrantyId || 'N/A',
    //                 warrantyStartDate: asset.warrantyStartDate || 'N/A',
    //                 warrantyEndDate: asset.warrantyEndDate || 'N/A',
    //                 amcId: asset.amcId || 'N/A',
    //                 amcStartDate: asset.amcStartDate || 'N/A',
    //                 amcEndDate: asset.amcEndDate || 'N/A'
    //             }));
    //         } else {
    //             console.error('Expected an array but received:', data);
    //         }
    //     } else if (error) {
    //         console.error('Error fetching non-active customers:', error);
    //     }
    // }

    // @track pincodeWiseNonActiveAssets = [];
    // @track hasNoPinCodeWiseNonActiveAssets = false;

    // @track pincodeWiseNonActiveAssetsColumns = {
    //     pinCode: { isAsc: false, isDesc: false },
    //     serviceEngineerName: { isAsc: false, isDesc: false },
    //     x90days: { isAsc: false, isDesc: false },
    //     x180days: { isAsc: false, isDesc: false }
    // }

    // @wire(getPinCodeWiseNonActiveAssets)
    // PinCodeWiseNonActiveAssets({ error, data }) {
    //     console.log('getPinCodeWiseNonActiveAssets');
    //     if (data) {
    //         console.log('getPinCodeWiseNonActiveAssets Fetched Data:', data);

    //         this.pincodeWiseNonActiveAssets = [];

    //         for (const [key, assets] of Object.entries(data)) {
    //             for (const asset of assets) {
    //                 const { pinCodeName, serviceEngineerName } = asset;
    //                 let entry = this.pincodeWiseNonActiveAssets.find(e => e.pinCode === pinCodeName && e.serviceEngineerName === serviceEngineerName);

    //                 if (!entry) {
    //                     entry = { pinCode: pinCodeName, serviceEngineerName, [key]: 0, id: pinCodeName + '-' + serviceEngineerName };
    //                     this.pincodeWiseNonActiveAssets.push(entry);
    //                 }

    //                 entry[key] = (entry[key] || 0) + 1;
    //             }
    //         }

    //         this.hasNoPinCodeWiseNonActiveAssets = this.pincodeWiseNonActiveAssets.length === 0;

    //         console.log('getPinCodeWiseNonActiveAssets this.pincodeWiseNonActiveAssets', this.pincodeWiseNonActiveAssets);

    @track pincodeWiseNonActiveAssets = [];
    @track hasNoPinCodeWiseNonActiveAssets = false;

    @track pincodeWiseNonActiveAssetsColumns = {
        pinCode: { isAsc: false, isDesc: false },
        serviceEngineerName: { isAsc: false, isDesc: false },
        x90days: { isAsc: false, isDesc: false },
        x180days: { isAsc: false, isDesc: false }
    };

    @wire(getPinCodeWiseNonActiveAssets)
    PinCodeWiseNonActiveAssets({ error, data }) {
        if (data) {
            console.log('Fetched Data:', data);

            this.pincodeWiseNonActiveAssets = [];

            // Loop through the data and process each asset
            for (const [durationKey, assets] of Object.entries(data)) {
                for (const asset of assets) {
                    if (!asset) continue;

                    const { pinCodeName, serviceEngineerName, accountId, accountName } = asset;

                    let entry = this.pincodeWiseNonActiveAssets.find(e =>
                        e.pinCode === pinCodeName && e.serviceEngineerName === serviceEngineerName
                    );

                    if (!entry) {
                        entry = {
                            pinCode: pinCodeName,
                            serviceEngineerName,
                            accountId,
                            accountName,
                            id: `${pinCodeName}-${serviceEngineerName}`
                        };
                        this.pincodeWiseNonActiveAssets.push(entry);
                    }

                    // Initialize asset count for the durationKey if not already present
                    entry[durationKey] = (entry[durationKey] || 0) + 1;

                    // Initialize account set if not present
                    const accountSetKey = `${durationKey}_accountSet`;
                    if (!entry[accountSetKey]) {
                        entry[accountSetKey] = new Set();
                    }

                    entry[accountSetKey].add(accountId);
                }
            }


            // Convert account Sets to counts and remove raw Set
            this.pincodeWiseNonActiveAssets = this.pincodeWiseNonActiveAssets.map(entry => {
                const cleaned = { ...entry };
                for (const key in entry) {
                    if (key.endsWith('_accountSet')) {
                        // Replace Set with count of unique accounts
                        const countKey = key.replace('_accountSet', '_accounts');
                        cleaned[countKey] = entry[key].size;
                        delete cleaned[key]; // Remove the raw Set
                    }
                }
                return cleaned;
            });

            // Check if there is any data
            this.hasNoPinCodeWiseNonActiveAssets = this.pincodeWiseNonActiveAssets.length === 0;

            console.log('Processed pincodeWiseNonActiveAssets:', this.pincodeWiseNonActiveAssets);
            // } else if (error) {
            //     console.error('Error fetching Pin Code Wise Non Active Assets:', error);
            //     this.hasNoPinCodeWiseNonActiveAssets = true;






            /*
            this.pinCodeLabels = Object.keys(data);
            this.pinCodeData = Object.values(data);

            const barChartConfiguration = {
                type: 'bar',
                data: {
                    // labels: this.pinCodeLabels,
                    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                    datasets: [{
                        label: 'Non-Active Assets Count',
                        // data: this.pinCodeData,
                        data: [65, 59, 80, 81, 56, 55],
                        backgroundColor: [
                            'rgba(255, 99, 132, 0.2)',
                            'rgba(255, 159, 64, 0.2)',
                            'rgba(255, 205, 86, 0.2)',
                            'rgba(75, 192, 192, 0.2)',
                            'rgba(54, 162, 235, 0.2)',
                            'rgba(153, 102, 255, 0.2)'
                        ],
                        borderColor: [
                            'rgb(255, 99, 132)',
                            'rgb(255, 159, 64)',
                            'rgb(255, 205, 86)',
                            'rgb(75, 192, 192)',
                            'rgb(54, 162, 235)',
                            'rgb(153, 102, 255)'
                        ],
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'top' },
                        tooltip: { enabled: true }
                    },
                    scales: {
                        y: { beginAtZero: true }
                    }
                }
            };

            try {
                const startTime = Date.now();
                renderChartJs(this, this.chart4, this.template.querySelector('.bar-chart-js-canvas2'), barChartConfiguration);
                const endTime = Date.now();
                console.log('Time taken to render Bar Chart:', endTime - startTime);
            } catch (error) {
                console.error('Error rendering Bar Chart:', error);
            }
            */

        } else if (error) {
            console.error('Error fetching Pin Code data:', error);
        }
    }

    @track teamAttendance = [];
    @track hasNoTeamAttendance = false;

    @wire(getTeamAttendance)
    wiredTeamAttendance({ error, data }) {
        if (data) {
            console.log('Fetched Team Attendance Data:', JSON.stringify(data));
            this.teamAttendance = data.map(attendance => ({
                id: attendance.id,
                serviceResourceId: attendance.serviceResourceId,
                userName: attendance.userName,
                startDate: attendance.startDate,
                endDate: attendance.endDate
            }));
            this.showSpinner = false;
            this.hasNoTeamAttendance = this.teamAttendance.length === 0;
        } else if (error) {
            console.error('Error fetching team attendance:', error);
            this.showSpinner = false;
            this.hasNoTeamAttendance = true;
        }
    }

    statusLabels = [];
    quoteCounts = [];
    @track selectedDateFilter = 'THIS_MONTH';
    @track dateFilterOptions = [
        { label: 'Today', value: 'TODAY' },
        { label: 'Yesterday', value: 'YESTERDAY' },
        { label: 'Last 7 Days', value: 'LAST_N_DAYS:7' },
        { label: 'Last 30 Days', value: 'LAST_N_DAYS:30' },
        { label: 'Last 60 Days', value: 'LAST_N_DAYS:60' },
        { label: 'Last 90 Days', value: 'LAST_90_DAYS' },
        { label: 'This Month', value: 'THIS_MONTH' },
        { label: 'Last Month', value: 'LAST_MONTH' },
        { label: 'This Year', value: 'THIS_YEAR' },
        { label: 'Last Year', value: 'LAST_YEAR' }
    ];
    // @wire(getQuoteCountStatusWise)
    // wiredQuoteCountStatusData({ error, data }) {
    //     if (data) {
    //         console.log('getQuoteCountStatusWise Fetched Data:', data);
    //         this.statusLabels = Object.keys(data);
    //         this.quoteCounts = Object.values(data);

    //         const pieChartConfiguration = {
    //             type: 'bar',
    //             data: {
    //                 labels: this.statusLabels,
    //                 // labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    //                 datasets: [{
    //                     label: 'Quote Status Count',
    //                     data: this.quoteCounts,
    //                     backgroundColor: [
    //                         'rgba(255, 99, 132, 0.2)',
    //                         'rgba(255, 159, 64, 0.2)',
    //                         'rgba(255, 205, 86, 0.2)',
    //                         'rgba(75, 192, 192, 0.2)',
    //                         'rgba(54, 162, 235, 0.2)',
    //                         'rgba(153, 102, 255, 0.2)',
    //                         'rgba(201, 203, 207, 0.2)',
    //                         'rgba(255, 206, 86, 0.2)',
    //                         'rgba(75, 192, 192, 0.2)',
    //                         'rgba(54, 162, 235, 0.2)',
    //                     ],
    //                     borderColor: [
    //                         'rgb(255, 99, 132)',
    //                         'rgb(255, 159, 64)',
    //                         'rgb(255, 205, 86)',
    //                         'rgb(75, 192, 192)',
    //                         'rgb(54, 162, 235)',
    //                         'rgb(153, 102, 255)',
    //                         'rgb(201, 203, 207)',
    //                         'rgb(255, 206, 86)',
    //                         'rgb(75, 192, 192)',
    //                         'rgb(54, 162, 235)',
    //                     ],
    //                     borderWidth: 1
    //                 }]
    //             }
    //             // options: {
    //             //     responsive: true,
    //             //     maintainAspectRatio: false,
    //             //     plugins: {
    //             //         legend: { position: 'top' },
    //             //         tooltip: { enabled: true }
    //             //     },
    //             //     scales: {
    //             //         y: { beginAtZero: true }
    //             //     }
    //             // }

    //         };

    //         try {
    //             const startTime = Date.now();
    //             renderChartJs(this, this.chart4, this.template.querySelector('.pie-chart-js-canvas'), pieChartConfiguration);
    //             const endTime = Date.now();
    //             console.log('Time taken to render Pie Chart:', endTime - startTime);
    //         } catch (error) {
    //             console.error('Error rendering Pie Chart:', error);
    //         }

    //     } else if (error) {
    //         console.error('Error fetching data:', error);
    //     }
    // }

    handleDateFilterChange(event) {
        this.selectedDateFilter = event.detail.value;
    }

    @wire(getQuoteCountStatusWise, { dateFilter: '$selectedDateFilter' })
    wiredQuoteCountStatusData({ error, data }) {
        if (data) {
            console.log('getQuoteCountStatusWise Fetched Data:', data);
            this.statusLabels = Object.keys(data);
            this.quoteCounts = Object.values(data);

            const colorsArray = [
                '#FF6384', // Red
                '#FF9F40', // Orange
                '#FFCD56', // Yellow
                '#4BC0C0', // Teal
                '#36A2EB', // Blue
                '#9966FF', // Purple
                '#C9CBCF', // Grey
                '#FFD700', // Gold
                '#00FA9A', // MediumSpringGreen
                '#8A2BE2'  // BlueViolet
            ];

            const barChartConfig = {
                chart: {
                    type: 'bar',
                    height: 350
                },
                series: [{
                    name: 'Quote Status Count',
                    data: this.quoteCounts
                }],
                xaxis: {
                    categories: this.statusLabels
                },
                dataLabels: {
                    enabled: true,
                    style: {
                        fontSize: '14px'
                    }
                },
                plotOptions: {
                    // bar: {
                    //     horizontal: false,
                    //     columnWidth: '60%',
                    //     dataLabels: {
                    //         position: 'top'
                    //     }
                    // }
                    bar: {
                        distributed: true,
                        dataLabels: {
                            position: 'top'
                        }
                    }

                },
                colors: colorsArray,
                tooltip: {
                    enabled: true
                }
            };

            try {
                const chartElement = this.template.querySelector('.pie-chart-js-canvas');

                // Clear previous chart if it exists
                if (this.chart4) {
                    // Different ways to destroy based on chart library
                    if (typeof this.chart4.destroy === 'function') {
                        this.chart4.destroy();
                    } else if (typeof this.chart4.destroyChart === 'function') {
                        this.chart4.destroyChart();
                    } else if (this.chart4.dispose) {
                        this.chart4.dispose();
                    }
                    this.chart4 = null;
                }

                // Clear the container
                chartElement.innerHTML = '';

                const startTime = Date.now();
                this.chart4 = renderApexChart(this, this.chart4, chartElement, barChartConfig);
                this.chart4.render();

                // renderApexChart(this, this.chart4, this.template.querySelector('.pie-chart-js-canvas'), barChartConfig);
                const endTime = Date.now();
                console.log('Time taken to render Apex Bar Chart:', endTime - startTime);
            } catch (err) {
                console.error('Error rendering ApexChart:', err);
            }

        } else if (error) {
            console.error('Error fetching data:', error);
            if (this.chart4) {
                try {
                    this.chart4.destroy();
                } catch (e) {
                    console.warn('Error destroying chart:', e);
                }
                this.chart4 = null;
            }
        }
    }




    //

    // @wire(getAMCBusinessChart)
    // wiredAMCData({ error, data }) {
    //     this.isLoading = false;
    //     if (data) {
    //         console.log('getAMCBusinessChart data', data);
    //         this.chartData = data;
    //         // this.error = undefined;
    //         // this.initializeChartJs();
    //         const pieChartConfiguration = {
    //             type: 'doughnut',
    //             data: {
    //                 labels: ['New AMCs', 'Renewed AMCs', 'Post-Warranty AMCs'],
    //                 // labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    //                 datasets: [{
    //                     // label: 'Quote Status Count',
    //                     // data: this.quoteCounts,
    //                     data: [
    //                         this.chartData.invoiceAmountOfNewAMCs,
    //                         this.chartData.invoiceAmountOfRenewedAMCs,
    //                         this.chartData.invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry
    //                     ],
    //                     backgroundColor: [
    //                         '#4BC0C0',
    //                         '#36A2EB',
    //                         '#FF9F40'
    //                     ],
    //                     hoverBackgroundColor: [
    //                         '#3DA8A8',
    //                         '#2E8BCC',
    //                         '#E68A36'
    //                     ]
    //                 }]
    //             }
    //         };

    //         try {
    //             const startTime = Date.now();
    //             renderChartJs(this, this.chart4, this.template.querySelector('.doughnut'), pieChartConfiguration);
    //             const endTime = Date.now();
    //             console.log('Time taken to render doughnut Chart:', endTime - startTime);
    //         } catch (error) {
    //             console.error('Error rendering doughnut Chart:', error);
    //         }


    //     } else if (error) {
    //         // this.error = error.body?.message || 'Unknown error';
    //         this.chartData = undefined;
    //         console.error('Error fetching AMC data:', error);
    //     }
    // }

    // @track amcData = [];
    // @track showSpinner = true;

    // @wire(getAMCBusinessChart)
    // wiredData({ error, data }) {
    //     this.showSpinner = false;

    //     if (data) {
    //         const totalRow = data.find(d => d.seName === 'Total');
    //         const filteredData = data.filter(d => d.seName !== 'Total');

    //         filteredData.sort((a, b) => {
    //             return a.seName.toLowerCase().localeCompare(b.seName.toLowerCase());
    //         });

    //         this.amcData = [...filteredData, totalRow];
    //     } else if (error) {
    //         console.error('Error loading AMC data:', error);
    //     }
    // }

    // get isAmcDataEmpty() {
    //     return this.amcData.length === 0;
    // }

    // get hasAmcData() {
    //     return this.amcData.length > 0;
    // }

    // get sortedAmcData() {
    //     return this.amcData;
    // }

    // processAmcData(rawData) {
    //     this.sortedAmcData = rawData.map(record => {
    //         let rowStyle = '';

    //         if (record.seName === 'Total') {
    //             rowStyle = 'font-weight: bold; background-color: #f2f2f2;';
    //         }

    //         return {
    //             ...record,
    //             rowStyle
    //         };
    //     });
    // }


    sortedAmcData = [];
    showSpinner = true;
    noDataFound = false;

    @wire(getAMCBusinessChart)
    wiredData({ error, data }) {
        if (data) {
            console.log('getAMCBusinessChart data-->', data);
            this.showSpinner = false;
            if (data.length === 0) {
                this.noDataFound = true;
            } else {
                this.noDataFound = false;
                this.sortedAmcData = data.map((record) => {
                    const rowStyle = record.seName === 'Total' ? 'font-weight: bold; background-color: #f1f1f1;' : '';
                    return { ...record, rowStyle }; // Create a new object with the 'rowStyle' property
                });
            }
        } else if (error) {
            this.showSpinner = false;
            this.noDataFound = true;
            console.error(error);
        }
    }
    //


    //
    @track businessRevenueData = [];
    @track hasNoData = false;

    @track businessRevenueDataColumns = {
        // serviceEngineerName, spareGoal, spareAchieve, serviceGoal, serviceAchieve, totalGoal, totalAchieve, totalPercentage
        serviceEngineerName: { isAsc: false, isDesc: false },
        spareGoal: { isAsc: false, isDesc: false },
        spareAchieve: { isAsc: false, isDesc: false },
        serviceGoal: { isAsc: false, isDesc: false },
        serviceAchieve: { isAsc: false, isDesc: false },
        totalGoal: { isAsc: false, isDesc: false },
        totalAchieve: { isAsc: false, isDesc: false },
        totalPercentage: { isAsc: false, isDesc: false }
    };

    @wire(getBusinessRevenue)
    wiredBusinessRevenue({ error, data }) {
        if (data) {
            console.log('getBusinessRevenue Fetched Business Revenue Data:', data);
            this.businessRevenueData = data;

            this.showSpinner = false;
            this.hasNoData = this.businessRevenueData.length === 0;
        } else if (error) {
            // console.error('Error fetching business revenue:', error);
            this.showSpinner = false;
            this.hasNoData = true;
            // this.dispatchEvent(
            //     new ShowToastEvent({
            //         title: 'Error loading business revenue',
            //         message: error.body.message,
            //         variant: 'error'
            //     })
            // );
        }
    }

    // Format currency with INR symbol
    formatCurrency(value) {
        return new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value);
    }

    // Calculate percentage achievement
    calculatePercentage(achievement, goal) {
        if (goal === 0 || goal === null) return 0;
        return ((achievement / goal) * 100).toFixed(2);
    }

    // Get style for percentage based on achievement
    getPercentageStyle(achievement, goal) {
        if (goal === 0 || goal === null) return '';
        const percentage = achievement / goal;
        return percentage >= 1 ? 'color: green; font-weight: bold;' : 'color: red;';
    }

    //
    @track caseHistoryData;
    @track hasNoCaseHistoryData = false;

    // @wire(getLast7DaysCaseHistory)
    // wiredCaseHistory({ error, data }) {
    //     if (data) {
    //         console.log('Fetched Case History Data:', JSON.stringify(data));
    //         this.caseHistoryData = {
    //             casesAssignedInLast7Days: data.casesAssignedInLast7Days || 0,
    //             casesAttendedInLast7Days: data.casesAttendedInLast7Days || 0,
    //             casesClosedInLast7Days: data.casesClosedInLast7Days || 0,
    //             openCasesAsOnToday: data.openCasesAsOnToday || 0
    //         };
    //         this.showSpinner = false;
    //         this.hasNoCaseHistoryData = false;
    //     } else if (error) {
    //         this.showSpinner = false;
    //         this.hasNoCaseHistoryData = true;
    //     }
    // }

    @wire(getLast7DaysCaseHistory)
    wiredCaseHistory({ error, data }) {
        if (data) {
            console.log('Fetched Case History Data:', JSON.stringify(data));
            this.caseHistoryData = data.map(item => ({
                ownerName: item.ownerName || 'Blank',
                assigned: item.assigned || 0,
                attended: item.attended || 0,
                closed: item.closed || 0,
                open: item.open || 0
            }));
            this.hasNoCaseHistoryData = false;
            this.showSpinner = false;
        } else if (error) {
            this.showSpinner = false;
            // console.error('⚠️ Error fetching case summary:', error);
        }
    }

    // get hasNoCaseHistoryData() {
    //     return !this.showSpinner && (!this.caseHistoryData || this.caseHistoryData.length === 0);
    // }


    //
    @track nonActiveCustomers;
    @track hasNonActiveCustomersData = false;

    // @track nonActiveCustomersColumns = {
    //     serviceEngineerName: { isAsc: false, isDesc: false },
    //     x90days: { isAsc: false, isDesc: false },
    //     x180days: { isAsc: false, isDesc: false }
    // }
    @track nonActiveCustomersColumns = {
        serviceEngineerName: { label: 'Service Engineer', isAsc: false, isDesc: false },
        x90days_assets: { label: 'Assets (90 Days)', isAsc: false, isDesc: false },
        x90days_accounts: { label: 'Accounts (90 Days)', isAsc: false, isDesc: false },
        x180days_assets: { label: 'Assets (180 Days)', isAsc: false, isDesc: false },
        x180days_accounts: { label: 'Accounts (180 Days)', isAsc: false, isDesc: false }
    };


    // @wire(getNonActiveCustomers)
    // wiredNonActiveCustomers({ error, data }) {
    //     if (data) {
    //         console.log('getNonActiveCustomers Fetched Non-Active Customers Data:', data);

    //         this.nonActiveCustomers = [];

    //         for (const [key, assets] of Object.entries(data)) {
    //             for (const asset of assets) {
    //                 const { serviceEngineerName } = asset;
    //                 let entry = this.nonActiveCustomers.find(e => e.serviceEngineerName === serviceEngineerName);

    //                 if (!entry) {
    //                     entry = { serviceEngineerName, [key]: 0, id: serviceEngineerName };
    //                     this.nonActiveCustomers.push(entry);
    //                 }

    //                 entry[key] = (entry[key] || 0) + 1;
    //             }
    //         }

    //         console.log('getNonActiveCustomers this.nonActiveCustomers', this.nonActiveCustomers);
    //         this.showSpinner = false;
    //         this.hasNonActiveCustomersData = this.nonActiveCustomers.length === 0;
    //     } else if (error) {
    //         this.showSpinner = false;
    //         this.hasNonActiveCustomersData = true;
    //     }
    // }

    @wire(getNonActiveCustomers)
    wiredNonActiveCustomers({ error, data }) {
        if (data) {
            console.log('Fetched Data:', data);

            this.nonActiveCustomers = [];

            for (const [durationKey, records] of Object.entries(data)) {
                for (const record of records) {
                    if (!record) continue; // Skip undefined/null records

                    const serviceEngineerName = record.serviceEngineerName || '';
                    const accountId = record.accountId || '';

                    // if (!serviceEngineerName) continue;

                    // Check if this engineer already exists in the result
                    let entry = this.nonActiveCustomers.find(e => e.serviceEngineerName === serviceEngineerName);
                    if (!entry) {
                        entry = {
                            serviceEngineerName,
                            id: serviceEngineerName
                        };
                        this.nonActiveCustomers.push(entry);
                    }

                    // Count assets for this duration
                    const assetKey = `${durationKey}_assets`;
                    entry[assetKey] = (entry[assetKey] || 0) + 1;

                    // Track unique accounts for this duration using a Set
                    const accountSetKey = `${durationKey}_accountSet`;
                    if (!entry[accountSetKey]) {
                        entry[accountSetKey] = new Set();
                    }
                    entry[accountSetKey].add(accountId);
                }
            }

            // Convert account Sets to counts and remove raw Set
            this.nonActiveCustomers = this.nonActiveCustomers.map(entry => {
                const cleaned = { ...entry };
                for (const key in entry) {
                    if (key.endsWith('_accountSet')) {
                        const countKey = key.replace('_accountSet', '_accounts');
                        cleaned[countKey] = entry[key].size;
                        delete cleaned[key];
                    }
                }
                return cleaned;
            });

            console.log('Processed nonActiveCustomers:', this.nonActiveCustomers);

            this.showSpinner = false;
            this.hasNonActiveCustomersData = this.nonActiveCustomers.length === 0;
        } else if (error) {
            this.showSpinner = false;
            this.hasNonActiveCustomersData = true;
        }
    }



    //
    // @track assetList = [];
    // @track hasNoAssetListData = false;

    // @wire(getListOfAssetsWhoseAMCDueEvenAfterPMVisit)
    // wiredAssetsList({ data, error }) {
    //     this.showSpinner = false;
    //     if (data) {
    //         console.log('PM visit data:', data);

    //         this.assetList = data;
    //         this.hasNoAssetListData = data.length === 0;
    //     } else if (error) {
    //         console.error('Error fetching AMC due data:', error);
    //         this.hasNoAssetListData = true;
    //     }
    // }
    @track data;
    @track error;
    @track isLoading = true;

    @wire(getListOfAssetsWhoseAMCDueEvenAfterPMVisit)
    wiredAssetsList({ error, data }) {
        this.isLoading = false;
        if (data) {
            // Process your data here if needed
            console.log('PM visit data:', data);
            this.data = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || 'Unknown error';
            this.data = undefined;
        }
    }

    @track caseList;
    @track hasNoCaseList = false;

    @wire(getOpenCasesOlderThan4Days)
    wiredCaseList({ data, error }) {
        this.showSpinner = false;

        if (data) {
            this.caseList = data;
            this.hasNoCaseList = data.length === 0;
            // this.errorMessage = undefined;
        } else if (error) {
            // this.errorMessage = error.body ? error.body.message : error.message;
            this.caseList = undefined;
            this.hasNoCaseList = false;
        }
    }









    handleColumnSort(event) {
        const { field, columns, data } = event.currentTarget.dataset;
        const col = this[columns][field];
        if (!col.isAsc && !col.isDesc) {
            col.isAsc = true;
        }
        else if (col.isAsc) {
            col.isAsc = false;
            col.isDesc = true;
        }
        else {
            col.isAsc = true;
            col.isDesc = false;
        }

        for (const key in this[columns]) {
            if (key !== field) {
                this[columns][key].isAsc = false;
                this[columns][key].isDesc = false;
            }
        }

        this[data] = this.sortData(this[data], field, col.isAsc ? 'asc' : 'desc');
    }


    sortData(data, fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(data));
        let keyValue = (a) => {
            return a[fieldname];
        };

        let isReverse = direction === 'asc' ? 1 : -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });

        const customerNames = data.map(item => item.customerName);
        console.log('customerNames', customerNames);

        return parseData;
    }


    @track openCasesForAction = [];
    @track hasNoCases = false;

    // @wire(getListOfOpenCases)
    // wiredCases({ error, data }) {
    //     console.log('openCasesForAction', data);
    //     this.showSpinner = false;
    //     if (data) {
    //         this.openCasesForAction = data;
    //         this.hasNoCases = data.length === 0;
    //     } else if (error) {
    //         console.error('Error loading cases', error);
    //         this.hasNoCases = true;
    //     }
    // }
    @wire(getListOfOpenCases)
    wiredCases({ error, data }) {
        console.log('openCasesForAction', data);

        this.showSpinner = false;
        if (data) {
            // Process data to ensure no undefined values
            this.openCasesForAction = data.map(caseItem => ({
                id: caseItem.id || '',
                caseNumber: caseItem.caseNumber || 'N/A',
                accountId: caseItem.accountId || '',
                accountName: caseItem.accountName || 'No Account',
                createdDate: caseItem.createdDate || null,
                status: caseItem.status || 'N/A',
                assignedDateTime: caseItem.assignedDateTime || null,
                ownerId: caseItem.ownerId || '',
                ownerName: caseItem.ownerName || 'No Owner'
            }));
            this.hasNoCases = this.openCasesForAction.length === 0;
        } else if (error) {
            // this.error = error;
            this.hasNoCases = true;
            console.error('Error loading cases:', error);
            // this.dispatchEvent(
            //     new ShowToastEvent({
            //         title: 'Error loading cases',
            //         message: error.body?.message || 'Unknown error',
            //         variant: 'error'
            //     })
            // );
        }
    }

    // Format dates properly for display
    // formatDate(dateValue) {
    //     if (!dateValue) return 'N/A';
    //     try {
    //         return new Date(dateValue).toLocaleDateString();
    //     } catch (e) {
    //         return 'Invalid Date';
    //     }
    // }

    formatDate(dateValue) {
        if (!dateValue) return 'N/A';
        try {
            return new Intl.DateTimeFormat('en-GB', {
                day: '2-digit',
                month: 'short',
                year: 'numeric'
            }).format(new Date(dateValue));
        } catch (e) {
            return 'Invalid Date';
        }
    }





    @track pendingOrders = [];
    @track hasNoOrders = false;

    @wire(getPendingOrders)
    wiredOrders({ error, data }) {
        this.showSpinner = false;
        if (data) {
            console.log('orders', data);
            this.pendingOrders = data.map(order => ({
                id: order.Id,
                name: order.Name,
                saleOrderNumber: order.Sale_Order_Number__c,
                customerPurchaseOrderDate: this.formatDate(order.Customer_Purchase_Order_Date__c),
                // customerPurchaseOrderDate: order.Customer_Purchase_Order_Date__c,
                customerId: order.Customer_Name__c,
                customerName: order.Customer_Name__r?.Name,
                conditionValue: order.Conditon_value__c,
                deliveryStatus: order.Delivery_Status__c,
                documentAmount: order.Document_Amount__c
            }));
            this.hasNoOrders = this.pendingOrders.length === 0;
        } else if (error) {
            this.showSpinner = false;
            this.error = error;
            this.hasNoOrders = true;
            // this.showToast('Error', error.body?.message || 'Failed to load pending orders', 'error');
        }
    }

    @track returnableQuoteLines = [];
    @track hasNoReturnableQuoteLines = true;
    @wire(getListOfReturnableSampleQuoteLineItemsRSMWise)
    wiredReturnableQuoteLines({ error, data }) {
        if (data) {
            console.log('getListOfReturnableSampleQuoteLineItemsRSMWise data-->', data);
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