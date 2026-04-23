import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from 'lightning/refresh';
import FieldServiceAppResources from '@salesforce/resourceUrl/FieldServiceAppResources';
import { showToast, showLightningAlert, analyzeFormFactor, analyzeUserAgent, getNameAndValueOnChange, initCalendar, navigateToRecord, navigateToLWC, navigateToTab, navigateToObjectPage, navigateToFilePreview, navigateToUrl, openLightningModal, loadQuickActionPopupStyle, unloadQuickActionPopupStyle, disablePullToRefresh, enablePullToRefresh } from 'c/utilJS';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";

import getAssetData from '@salesforce/apex/FieldServiceAssetHistoryController.getAssetData';



export default class FieldServiceAssetHistory extends NavigationMixin(LightningElement) {

    @track showSpinner = false;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.handleGetAssetData();
    }


    @track isMobile;
    @track isTablet;
    @track isDesktop;


    @track assetData;



    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            const { state: { c__id } = {} } = currentPageReference;
            if (c__id && c__id !== this.recordId) {
                this.recordId = c__id;
            }
        }
    }



    handleGetAssetData() {
        this.showSpinner = true;
        getAssetData({ recordId: this.recordId })
            .then(result => {
                if (!result.asset) { return; }

                console.log('result', result);
                const asset = result.asset || {};
                const { Asset_Warranty__r: warrantyList = [], Asset_AMCs__r: amcList = [], Histories: historyList = [] } = asset;
                const caseList = result.caseList || [];
                const serviceAppointmentList = result.serviceAppointmentList || [];
                const installationReportList = result.installationReportList || [];
                const serviceReportList = result.serviceReportList || [];

                const getDateOnly = datetime => datetime.split('T')[0];

                const assetHistoryList = historyList.reduce((acc, hist) => {
                    let entry = acc.find(at => at.id === hist.Field + hist.CreatedDate);
                    if (!entry) {
                        entry = {
                            id: hist.Field + hist.CreatedDate,
                            date: hist.CreatedDate,
                            createdDate: hist.CreatedDate,
                            createdByName: hist.CreatedBy.Name,
                            get name() {
                                if (this.oldValue && this.newValue) {
                                    return `${this.transferType} changed from ${this.oldValue} to ${this.newValue} by ${this.createdByName} on`;
                                }
                                else if (this.newValue) {
                                    return `${this.transferType} changed to ${this.newValue} by ${this.createdByName} on`;
                                }
                                else if (this.oldValue) {
                                    return `${this.transferType} changed to blank from ${this.oldValue} by ${this.createdByName} on`;
                                }
                            }
                        };
                        acc.push(entry);
                    }

                    const updateEntry = (oldKey, newKey, oldValue, newValue) => {
                        entry[oldKey] = oldValue;
                        entry[newKey] = newValue;
                    };

                    if (['EntityId', 'Text'].includes(hist.DataType)) {
                        const fieldMap = {
                            'Account': ['oldId', 'newId', 'oldValue', 'newValue'],
                            'End_Customer__c': ['oldId', 'newId', 'oldValue', 'newValue']
                        };

                        const [oldIdKey, newIdKey, oldNameKey, newNameKey] = fieldMap[hist.Field] || [];

                        if (hist.Field === 'Account') entry.transferType = 'Bill To';
                        if (hist.Field === 'End_Customer__c') entry.transferType = 'Ship To';

                        if (hist.DataType === 'EntityId') {
                            updateEntry(oldIdKey, newIdKey, hist.OldValue, hist.NewValue);
                        } else if (hist.DataType === 'Text') {
                            updateEntry(oldNameKey, newNameKey, hist.OldValue, hist.NewValue);
                        }
                    }
                    return acc;
                }, []);

                this.assetData = {
                    serialNumber: asset.SerialNumber,
                    lastServiceEngineer: asset.Service_Resource__r?.Name,
                    warranty: { startDate: warrantyList?.[0]?.Warranty_Start_Date__c, endDate: warrantyList?.[0]?.Warranty_End_Date__c },
                    amcList: amcList.map(amc => ({
                        id: amc.Id,
                        startDate: amc.AMC_Start_Date__c,
                        endDate: amc.AMC_End_Date__c
                    })),
                    timeline: this.transformData(asset, caseList, amcList, warrantyList, assetHistoryList, serviceAppointmentList, serviceReportList, installationReportList),
                    get lastServiceDate() {
                        if (!this.timeline || this.timeline.length === 0) return null;
                        const firstTimeline = this.timeline[0];
                        if (firstTimeline.type === 'Standalone Case') return firstTimeline.date;
                        if (['AMC', 'Warranty'].includes(firstTimeline.type) && firstTimeline.timelineItems?.length > 0) {
                            return firstTimeline.timelineItems[0].date;
                        }
                        return null;
                    },
                    get isWarrantyAvailable() {
                        return this.warranty?.startDate && this.warranty?.endDate;
                    },
                    get warrantyStatus() {
                        const now = getDateOnly(new Date().toISOString());
                        return this.isWarrantyAvailable && now >= this.warranty.startDate && now <= this.warranty.endDate ? 'Active' : 'Inactive';
                    },
                    get isAmcAvailable() {
                        return this.amcList?.length > 0;
                    },
                    get amcStatus() {
                        const now = getDateOnly(new Date().toISOString());
                        return this.isAmcAvailable && this.amcList.some(amc => now >= amc.startDate && now <= amc.endDate) ? 'Active' : 'Inactive';
                    }
                };

                console.log('assetData', this.assetData, JSON.parse(JSON.stringify(this.assetData)));
            })
            .catch(error => {
                showToast(this, 'Error', 'Something went wrong', 'error', error);
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }



    handleToggleSection(event) {
        const { isStandAloneCase, timelineId, caseId, serviceAppointmentId, serviceReportId, installationReportId } = event.currentTarget.dataset;

        const toggleExpansion = (item) => {
            if (item) {
                item.isExpanded = !item.isExpanded;
            }
        };

        if (timelineId) {
            const timeline = this.assetData.timeline.find(t => t.id === timelineId);

            if (isStandAloneCase) {
                if (serviceAppointmentId) {
                    const serviceAppointment = timeline?.serviceAppointments.find(sa => sa.id === serviceAppointmentId);
                    if (serviceReportId) {
                        toggleExpansion(serviceAppointment?.serviceReport);
                    } else {
                        toggleExpansion(serviceAppointment);
                    }
                } else if (installationReportId) {
                    toggleExpansion(timeline?.installationReport);
                } else {
                    toggleExpansion(timeline);
                }
            } else {
                const caseItem = timeline?.timelineItems.find(c => c.id === caseId);
                if (caseItem) {
                    if (serviceAppointmentId) {
                        const serviceAppointment = caseItem.serviceAppointments.find(sa => sa.id === serviceAppointmentId);
                        if (serviceReportId) {
                            toggleExpansion(serviceAppointment?.serviceReport);
                        } else {
                            toggleExpansion(serviceAppointment);
                        }
                    } else if (installationReportId) {
                        toggleExpansion(caseItem.installationReport);
                    } else {
                        toggleExpansion(caseItem);
                    }
                } else {
                    toggleExpansion(timeline);
                }
            }
        }
    }


    handleToggleDescription(event) {
        const textElement = event.target;

        if (textElement.classList.contains('truncate')) {
            textElement.classList.remove('truncate');
            textElement.classList.add('expanded');
        } else {
            textElement.classList.remove('expanded');
            textElement.classList.add('truncate');
        }
    }


    handleNavigateToFilePreview(event) {
        event.preventDefault();
        const { id } = event.currentTarget.dataset;
        navigateToFilePreview(this, id);
    }



    transformData(asset, caseList, amcList, warrantyList, assetHistoryList, serviceAppointmentList, serviceReportList, installationReportList) {
        const timeline = [];

        const getDateOnly = datetime => datetime?.split('T')?.[0];

        const filterByDateRange = (list, startDate, endDate, dateKey) =>
            list
                .map(item => ({ ...item, date: getDateOnly(item[dateKey]) }))
                .filter(item => item.date >= startDate && item.date <= endDate)
                .sort((a, b) => new Date(b[dateKey]) - new Date(a[dateKey])) || null;

        const previewableTypes = ['image'];
        const fileTypeMap = { pdf: 'doctype:pdf', image: ['png', 'jpg', 'jpeg', 'gif'], video: ['mp4', 'mov', 'avi', 'flv', 'mkv'], audio: ['mp3', 'wav', 'wma', 'aac', 'flac'], word: ['doc', 'docx'], excel: ['xls', 'xlsx', 'xlsm', 'xlsb', 'xltx', 'xltm'], powerpoint: ['ppt', 'pptx', 'pptm', 'potx', 'potm', 'ppam', 'ppsx', 'ppsm'], zip: ['zip', 'rar', '7z', 'tar', 'gz', 'gzip', 'tgz'], text: ['txt', 'log', 'md', 'rtf'], html: ['html', 'htm', 'mhtml'], xml: ['xml'], json: ['json'], csv: ['csv', 'tsv'], psd: ['psd'] };

        const extractDocuments = docLinks => docLinks?.map(doc => {
            const { LatestPublishedVersion: latestVersion } = doc.ContentDocument;
            const { Id: id, Title: title, FileType: fileType, FileExtension: fileExtension, ContentSize: contentSize, VersionDataUrl: versionDataUrl } = latestVersion;

            const iconName = Object.entries(fileTypeMap).find(([type, exts]) =>
                type === fileType || exts.includes(fileExtension)
            )?.[0] || 'unknown';

            return {
                id, title, fileType, fileExtension, contentSize, versionDataUrl: versionDataUrl + '?thumb=THUMB240BY180', iconName: `doctype:${iconName}`,
                contentDocumentId: doc.ContentDocumentId,
                get isPreviewAvailable() {
                    return previewableTypes.includes(iconName);
                },
            };
        });


        const getServiceReportForCase = saId =>
            serviceReportList
                .filter(sr => sr.Service_Appointment__c === saId)
                .map(sr => ({
                    id: sr.Id, name: sr.Name, date: sr.CreatedDate, documents: extractDocuments(sr.ContentDocumentLinks), isExpanded: true,
                    get icon() {
                        return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
                    }
                }))[0] || null;

        const getAppointmentsForCase = caseId =>
            serviceAppointmentList
                .filter(sa => sa.Case__c === caseId)
                .map(sa => ({
                    id: sa.Id, name: sa.Name, date: sa.CreatedDate, serviceReport: getServiceReportForCase(sa.Id), isExpanded: true,
                    get icon() {
                        return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
                    }
                }))
                .sort((a, b) => new Date(b.date) - new Date(a.date)) || null;

        const getInstallationReportForCase = (caseId, caseType) => {
            const report = installationReportList.find(ir => ir.Case__c === caseId);
            return report ? {
                id: report.Id, name: report.Name, date: report.CreatedDate, documents: extractDocuments(report.ContentDocumentLinks), isExpanded: true,
                get icon() {
                    return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
                }
            } : null;
        };

        const processTimeline = (list, type, startDateKey, endDateKey) => {
            list?.forEach(item => {
                const cases = filterByDateRange(caseList, item[startDateKey], item[endDateKey], 'CreatedDate');
                const assetHistories = filterByDateRange(assetHistoryList, item[startDateKey], item[endDateKey], 'date');

                const timelineRow = {
                    type, id: item.Id, name: item.Name,
                    startDate: item[startDateKey], endDate: item[endDateKey],
                    timelineItems: [
                        ...cases?.map(c => ({
                            ...c,
                            id: c.Id, name: c.CaseNumber, date: c.CreatedDate, ownerName: c.Owner?.Name,
                            serviceAppointments: getAppointmentsForCase(c.Id),
                            installationReport: getInstallationReportForCase(c.Id, c.Type),
                            isExpanded: false,
                            isCase: true,
                            get icon() {
                                return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
                            }
                        })),
                        ...assetHistories?.map(hist => ({
                            ...hist,
                            isAssetHistory: true,
                            get icon() {
                                return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
                            }
                        }))
                    ],
                    get isAMC() { return this.type === 'AMC'; },
                    get isWarranty() { return this.type === 'Warranty'; },
                    get isCase() { return this.type === 'Case'; },
                    get isStandAloneCase() { return this.type === 'Standalone Case'; },
                    isExpanded: true,
                    get icon() {
                        return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
                    }
                };
                timelineRow.timelineItems.sort((a, b) => new Date(b.date) - new Date(a.date));
                timeline.push(timelineRow);
            });
        };

        processTimeline(amcList, "AMC", 'AMC_Start_Date__c', 'AMC_End_Date__c');
        processTimeline(warrantyList, "Warranty", 'Warranty_Start_Date__c', 'Warranty_End_Date__c');

        const isStandalone = (itemDate, list, startKey, endKey) =>
            !list.some(item => itemDate >= item[startKey] && itemDate <= item[endKey]);

        const standaloneCases = caseList.filter(c => {
            const caseDate = getDateOnly(c.CreatedDate);
            return isStandalone(caseDate, amcList, 'AMC_Start_Date__c', 'AMC_End_Date__c') &&
                isStandalone(caseDate, warrantyList, 'Warranty_Start_Date__c', 'Warranty_End_Date__c');
        });

        standaloneCases.forEach(c => {
            timeline.push({
                ...c,
                type: "Standalone Case",
                id: c.Id,
                name: c.CaseNumber,
                ownerName: c.Owner?.Name,
                date: c.CreatedDate,
                serviceAppointments: getAppointmentsForCase(c.Id),
                installationReport: getInstallationReportForCase(c.Id, c.Type),
                isStandAloneCase: true,
                isExpanded: false,
                get icon() {
                    return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
                }
            });
        });

        const standaloneAssetHistories = assetHistoryList.filter(ah => {
            const dt = getDateOnly(ah.date);
            return isStandalone(dt, amcList, 'AMC_Start_Date__c', 'AMC_End_Date__c') &&
                isStandalone(dt, warrantyList, 'Warranty_Start_Date__c', 'Warranty_End_Date__c');
        });

        standaloneAssetHistories.forEach(hist => {
            timeline.push({
                ...hist,
                isAssetHistory: true,
                isExpanded: false,
                get icon() {
                    return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
                }
            });
        });

        timeline.sort((a, b) => {
            const getDate = item => new Date(item.timelineItems?.[0]?.date || item.startDate || item.date);
            return getDate(b) - getDate(a);
        });

        return timeline;
    }


    handleNavigateToCase(event) {
        event.stopPropagation();
        const caseId = event.currentTarget.dataset.id;
        navigateToRecord(this, caseId, 'Case');
    }


}