/**
 * @author Aditya Zagade
 * @since 25 Feb 2025 Created
 *
 * @group Field Service
 */
public with sharing class FieldServiceSEDashboardController {

    /**
     * @description Method to get Type Wise Open Case Count
     * @description Type - 0-2, 3-4, 5+
     * @return `Object`
     * @exception Throws an AuraHandledException
     * @example
     * Object typeWiseOpenCaseCount = FieldServiceSEDashboardController.getTypeWiseOpenCaseCount();
     */
    @AuraEnabled(cacheable=true) // 1 - Table for OPEN Cases
    public static Object getTypeWiseOpenCaseCount() {
        try {
            Map<String, Map<String, Integer>> result = new Map<String, Map<String, Integer>>();

            Map<String, String> typeMap = UtilityCls.getPickList('Case', 'Type');

            List<String> buckets = new List<String>{'0-2', 'zeroToTwo', '3-4', 'threeToFour', '5+', 'fivePlus'};
            Map<String, Integer> defaultBucketMap = new Map<String, Integer>();
            for (String bucket : buckets) {
                defaultBucketMap.put(bucket, 0);
            }


            result.put('Other', new Map<String, Integer>(defaultBucketMap));

            List<String> keySet = new List<String>(typeMap.keySet());
            for(Integer i = keySet.size() - 1; i >= 0; i--) {
                String type = keySet[i];
                String mappedType = typeMap.get(type);
                result.put(mappedType, new Map<String, Integer>(defaultBucketMap));
            }

            for(AggregateResult ar : [
                SELECT Type, DAY_ONLY(CreatedDate) createdDate, COUNT(Id) caseCount
                FROM Case
                WHERE Status != 'Closed' AND OwnerId = :UserInfo.getUserId()
                GROUP BY Type, DAY_ONLY(CreatedDate)
                ORDER BY Type, DAY_ONLY(CreatedDate)
            ]) {
                String rawType = (String) ar.get('Type');
                String typeKey = String.isBlank(rawType) ? 'Other' : rawType;
                String mappedType = typeMap.containsKey(typeKey) ? typeMap.get(typeKey) : 'Other';
                Date createdDate = (Date) ar.get('createdDate');
                Integer caseCount = (Integer) ar.get('caseCount');

                Integer daysBetween = createdDate.daysBetween(System.today());

                if(daysBetween <= 2) {
                    result.get(mappedType).put('0-2', result.get(mappedType).get('0-2') + caseCount);
                    result.get(mappedType).put('zeroToTwo', result.get(mappedType).get('zeroToTwo') + caseCount);
                } else if(daysBetween <= 4) {
                    result.get(mappedType).put('3-4', result.get(mappedType).get('3-4') + caseCount);
                    result.get(mappedType).put('threeToFour', result.get(mappedType).get('threeToFour') + caseCount);
                } else {
                    result.get(mappedType).put('5+', result.get(mappedType).get('5+') + caseCount);
                    result.get(mappedType).put('fivePlus', result.get(mappedType).get('fivePlus') + caseCount);
                }
            }
            System.debug('Type Wise Open Case Count: ' + JSON.serialize(result));
            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getTypeWiseOpenCaseCount: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description Method to get Spare & Service GOAL Vs ACHIEVE separately
     * @return  `Object`
     * @exception Throws an AuraHandledException
     * @example
     * Object spareAndServiceGoalVsAchieve = FieldServiceSEDashboardController.getSpareAndServiceGoalVsAchieve();
     */
    @AuraEnabled(cacheable=true) // 2 - Spare & Service GOAL Vs ACHIEVE separately
    public static Object getSpareAndServiceGoalVsAchieve() {
        try {
            List<Service_Goal__c> serviceGoals = [SELECT Id, Name, Sales_Goal__c, Teams_Goal__c, Service_Resource__c, Service_Resource__r.Name, Financial_Year__c,
                                                Teams_Achievement__c, Sales_Achievement__c
                                                FROM Service_Goal__c
                                                WHERE Service_Resource__r.User__c = :UserInfo.getUserId()];

            Date today = System.today();
            Integer currentYear = today.year();
            String financialYear;
            if(today >= Date.newInstance(currentYear, 4, 1)) {
                financialYear = 'FY ' + String.valueOf(currentYear) + '-' + String.valueOf(currentYear + 1);
            } else {
                financialYear = 'FY ' + String.valueOf(currentYear - 1) + '-' + String.valueOf(currentYear);
            }

            Service_Goal__c currentFyGoal;
            for(Service_Goal__c sg : serviceGoals) {
                if(sg.Financial_Year__c == financialYear) {
                    currentFyGoal = sg;
                    break;
                }
            }

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            if (currentFyGoal != null) {
                result.add(new Map<String, Object> {
                    'id' => currentFyGoal.Id,
                    'name' => currentFyGoal.Service_Resource__r.Name,
                    'financialYear' => currentFyGoal.Financial_Year__c,
                    'salesGoal' => currentFyGoal.Sales_Goal__c,
                    'salesAchievement' => currentFyGoal.Sales_Achievement__c
                });
            }
            for(Service_Goal__c sg : serviceGoals) {
                if(sg.Financial_Year__c != financialYear) {
                    result.add(new Map<String, Object> {
                        'id' => sg.Id,
                        'name' => sg.Service_Resource__r.Name,
                        'financialYear' => sg.Financial_Year__c,
                        'salesGoal' => sg.Sales_Goal__c,
                        'salesAchievement' => sg.Sales_Achievement__c,
                        'teamsGoal' => sg.Teams_Goal__c,
                        'teamsAchievement' => sg.Teams_Achievement__c
                    });
                }
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getSpareAndServiceGoalVsAchieve: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    //added by shashank
    @AuraEnabled(cacheable=true) // 2 - Spare & Service GOAL Vs ACHIEVE separately
    public static Object getServiceGoalVsAchieve() {
        try {
            List<Service_Goal__c> serviceGoals = [SELECT Id, Name, Service_Goal__c, Teams_Goal__c, Service_Resource__c, Service_Resource__r.Name, Financial_Year__c,
                                                Teams_Achievement__c, Service_Achievement__c,Service_Achievement_Percentage__c
                                                FROM Service_Goal__c
                                                WHERE Service_Resource__r.User__c = :UserInfo.getUserId()];

            Date today = System.today();
            Integer currentYear = today.year();
            String financialYear;
            if(today >= Date.newInstance(currentYear, 4, 1)) {
                financialYear = 'FY ' + String.valueOf(currentYear) + '-' + String.valueOf(currentYear + 1);
            } else {
                financialYear = 'FY ' + String.valueOf(currentYear - 1) + '-' + String.valueOf(currentYear);
            }

            Service_Goal__c currentFyGoal;
            for(Service_Goal__c sg : serviceGoals) {
                if(sg.Financial_Year__c == financialYear) {
                    currentFyGoal = sg;
                    break;
                }
            }

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            if (currentFyGoal != null) {
                result.add(new Map<String, Object> {
                    'id' => currentFyGoal.Id,
                    'name' => currentFyGoal.Service_Resource__r.Name,
                    'financialYear' => currentFyGoal.Financial_Year__c,
                    'serviceGoal' => currentFyGoal.Service_Goal__c,
                    'serviceAchievement' => currentFyGoal.Service_Achievement__c
                });
            }
            for(Service_Goal__c sg : serviceGoals) {
                if(sg.Financial_Year__c != financialYear) {
                    result.add(new Map<String, Object> {
                        'id' => sg.Id,
                        'name' => sg.Service_Resource__r.Name,
                        'financialYear' => sg.Financial_Year__c,
                        'serviceGoal' => sg.Service_Goal__c,
                        'serviceAchievement' => sg.Service_Achievement__c,
                        'teamsGoal' => sg.Teams_Goal__c,
                        'teamsAchievement' => sg.Teams_Achievement__c
                    });
                }
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getSpareAndServiceGoalVsAchieve: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description Method to get AMC & Warranty Population Chart
     * @return Object
     * @example
     * Object result = FieldServiceSEDashboardController.getAMCAndWarrantyPopulationChart();
     */
    @AuraEnabled(cacheable=true) // 3 - AMC & Warranty Population Chart
    public static Object getAMCAndWarrantyPopulationChart() {
        try {
            Date todayPlus60Days = System.today().addDays(60);

            Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

            AggregateResult totalAssetResult = [
                SELECT COUNT(Id) totalCount
                FROM Asset
                WHERE Pin_Code_Master__c IN :pincodeIds
            ];

            // Count assets with an active warranty where Warranty_End_Date__c is today or later
            AggregateResult activeWarrantyResult = [
                SELECT COUNT(Id) totalCount
                FROM Asset_Warranty__c
                WHERE Asset__r.Type__c IN ('Within Warranty') AND Warranty_Start_Date__c <= TODAY AND Warranty_End_Date__c >= TODAY
                AND Asset__r.Pin_Code_Master__c IN :pincodeIds
            ];

            // Count assets with an active AMC where AMC_End_Date__c is today or later
            AggregateResult activeAMCResult = [
                SELECT COUNT(Id) totalCount
                FROM Asset_AMC__c
                WHERE Asset__r.Type__c IN ('Within AMC', 'Within CAMC') AND AMC_Start_Date__c <= TODAY AND AMC_End_Date__c >= TODAY
                AND Asset__r.Pin_Code_Master__c IN :pincodeIds
            ];

            // Count assets where amc is expiring in next 60 days
            List<Asset_AMC__c> expiringAMCRecords = [SELECT Asset__c FROM Asset_AMC__c WHERE AMC_End_Date__c >= TODAY AND AMC_End_Date__c <= :todayPlus60Days AND Asset__r.Pin_Code_Master__c IN :pincodeIds];
            Set<Id> assetsIds = new Set<Id>();
            for(Asset_AMC__c aa : expiringAMCRecords) {
                assetsIds.add(aa.Asset__c);
            }
            AggregateResult expiringAMCResult = [
                SELECT COUNT(Id) totalCount
                FROM Asset
                WHERE Pin_Code_Master__c IN :pincodeIds
                AND Id IN :assetsIds
            ];

            // Count assets where warranty is expiring in next 60 days
            List<Asset_Warranty__c> expiringWarrantyRecords = [SELECT Asset__c FROM Asset_Warranty__c WHERE Warranty_End_Date__c >= TODAY AND Warranty_End_Date__c <= :todayPlus60Days AND Asset__r.Pin_Code_Master__c IN :pincodeIds];
            assetsIds = new Set<Id>();
            for(Asset_Warranty__c aw : expiringWarrantyRecords) {
                assetsIds.add(aw.Asset__c);
            }
            AggregateResult expiringWarrantyResult = [
                SELECT COUNT(Id) totalCount
                FROM Asset
                WHERE Pin_Code_Master__c IN :pincodeIds
                AND Id IN :assetsIds
            ];

            return new Map<String, Integer>{
                'totalAssets' => (Integer) totalAssetResult.get('totalCount'),
                'assetsWithActiveWarranty' => (Integer) activeWarrantyResult.get('totalCount'),
                'assetsWithActiveAMC' => (Integer) activeAMCResult.get('totalCount'),
                'expiringAMCResult' => (Integer) expiringAMCResult.get('totalCount'),
                'expiringWarrantyResult' => (Integer) expiringWarrantyResult.get('totalCount')
            };
        }
        catch (Exception e) {
            System.debug('❌ Error in getAMCAndWarrantyPopulationChart: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description Method to get AMC Business Chart
     * @return `Object`
     * @exception Throws an AuraHandledException
     * @example
     * Object amcBusinessChart = FieldServiceSEDashboardController.getAMCBusinessChart();
     */
    //@AuraEnabled(cacheable=true) // 4 - AMC Business Chart
    // public static Object getAMCBusinessChart() {
    //     try {
    //         Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

    //         Map<String, Object> fyDetails = UtilityCls.getCurrentFYDetails();
    //         Date fyStartDate = (Date) fyDetails.get('start');
    //         Date fyEndDate = (Date) fyDetails.get('end');

    //         Date x90DaysBefore = System.today().addDays(-90);


    //         Decimal totalNewAMCBusiness = 0;
    //         Decimal totalRenewedAMCBusiness = 0;
    //         Decimal totalNewAfterWarrantyBusinessWithin90daysFromWarrantyExpiry = 0;

    //         for(Asset asset : [
    //             SELECT Id,
    //             (
    //                 SELECT Id, Name, Warranty_Start_Date__c, Warranty_End_Date__c, Invoice__c, Invoice__r.Net_Invoice_Amount__c
    //                 FROM Asset_Warranty__r
    //             ),
    //             (
    //                 SELECT Id, Name, AMC_Start_Date__c, AMC_End_Date__c, Invoice__c, AMC_PO_Value__c
    //                 FROM Asset_AMCs__r
    //             )
    //             FROM Asset
    //             WHERE Pin_Code_Master__c IN :pincodeIds
    //         ]) {
    //             if(asset.Asset_AMCs__r.size() > 0) {
    //                 System.debug('Asset: ' + JSON.serialize(asset));
    //                 if(asset.Asset_AMCs__r.size() == 1 && asset.Asset_Warranty__r.size() == 0) {
    //                     for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
    //                         System.debug(amc.AMC_Start_Date__c + ' >= ' + fyStartDate + ' && ' + amc.AMC_Start_Date__c + ' <= ' + fyEndDate);
    //                         if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
    //                             if(amc.AMC_PO_Value__c != null) {
    //                                 totalNewAMCBusiness += amc.AMC_PO_Value__c;
    //                             }
    //                         }
    //                     }
    //                 }
    //                 else if(asset.Asset_AMCs__r.size() > 1) {
    //                     for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
    //                         System.debug(amc.AMC_Start_Date__c + ' >= ' + fyStartDate + ' && ' + amc.AMC_Start_Date__c + ' <= ' + fyEndDate);
    //                         if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
    //                             if(amc.AMC_PO_Value__c != null) {
    //                                 totalRenewedAMCBusiness += amc.AMC_PO_Value__c;
    //                             }
    //                         }
    //                     }
    //                 }
    //                 else if(asset.Asset_Warranty__r.size() > 0 && asset.Asset_AMCs__r.size() == 1) {
    //                     Asset_Warranty__c warranty = asset.Asset_Warranty__r[0];
    //                     Boolean isWarrantyExpiredWithinLast90Days = warranty.Warranty_End_Date__c >= x90DaysBefore;
    //                     System.debug(isWarrantyExpiredWithinLast90Days);
    //                     if(isWarrantyExpiredWithinLast90Days) {
    //                         for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
    //                             System.debug(amc.AMC_Start_Date__c + ' >= ' + fyStartDate + ' && ' + amc.AMC_Start_Date__c + ' <= ' + fyEndDate);
    //                             if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
    //                                 if(amc.AMC_PO_Value__c != null) {
    //                                     totalNewAfterWarrantyBusinessWithin90daysFromWarrantyExpiry += amc.AMC_PO_Value__c;
    //                                 }
    //                             }
    //                         }
    //                     }
    //                 }
    //             }
    //         }

    //         return new Map<String, Object>{
    //             'totalNewAMCBusiness' => totalNewAMCBusiness,
    //             'totalRenewedAMCBusiness' => totalRenewedAMCBusiness,
    //             'totalNewAfterWarrantyBusinessWithin90daysFromWarrantyExpiry' => totalNewAfterWarrantyBusinessWithin90daysFromWarrantyExpiry
    //         };
    //     }
    //     catch (Exception e) {
    //         System.debug('❌ Error in getAMCBusinessChart: ' + e.getLineNumber() + ' - ' + e.getMessage());
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    @AuraEnabled(cacheable=true) // 4 - AMC Business Chart
public static Object getAMCBusinessChart() {
    try {
        Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

        Map<String, Object> fyDetails = UtilityCls.getCurrentFYDetails();
        Date fyStartDate = (Date) fyDetails.get('start');
        Date fyEndDate = (Date) fyDetails.get('end');

        Date x90DaysBefore = System.today().addDays(-90);

        Decimal totalNewAMCBusiness = 0;
        Integer newAMCCount = 0;

        Decimal totalRenewedAMCBusiness = 0;
        Integer renewedAMCCount = 0;

        Decimal totalNewAfterWarrantyBusinessWithin90daysFromWarrantyExpiry = 0;
        Integer newAfterWarrantyCount = 0;

        for(Asset asset : [
            SELECT Id,
            (
                SELECT Id, Name, Warranty_Start_Date__c, Warranty_End_Date__c, Invoice__c, Invoice__r.Net_Invoice_Amount__c
                FROM Asset_Warranty__r
                WHERE Invoice__r.Net_Invoice_Amount__c != null AND Warranty_Start_Date__c != null AND Warranty_End_Date__c != null
            ),
            (
                SELECT Id, Name, AMC_Start_Date__c, AMC_End_Date__c, Invoice__c, AMC_PO_Value__c
                FROM Asset_AMCs__r
                WHERE AMC_PO_Value__c != null AND AMC_Start_Date__c != null AND AMC_End_Date__c != null AND SE_Name__c = :Userinfo.getUserId()
                ORDER BY SE_Name__r.Name
            )
            FROM Asset 
            WHERE Pin_Code_Master__c IN :pincodeIds AND Type__c IN ('Within AMC', 'Within CAMC')
        ]) {
            if(asset.Asset_AMCs__r.size() > 0) {
                if(asset.Asset_AMCs__r.size() == 1 && asset.Asset_Warranty__r.size() == 0) {
                    for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
                        if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
                            if(amc.AMC_PO_Value__c != null) {
                                totalNewAMCBusiness += amc.AMC_PO_Value__c;
                                newAMCCount++;
                            }
                        }
                    }
                }
                else if(asset.Asset_AMCs__r.size() > 1) {
                    for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
                        if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
                            if(amc.AMC_PO_Value__c != null) {
                                totalRenewedAMCBusiness += amc.AMC_PO_Value__c;
                                renewedAMCCount++;
                            }
                        }
                    }
                }
                else if(asset.Asset_Warranty__r.size() > 0 && asset.Asset_AMCs__r.size() == 1) {
                    Asset_Warranty__c warranty = asset.Asset_Warranty__r[0];
                    Boolean isWarrantyExpiredWithinLast90Days = warranty.Warranty_End_Date__c >= x90DaysBefore;
                    if(isWarrantyExpiredWithinLast90Days) {
                        for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
                            if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
                                if(amc.AMC_PO_Value__c != null) {
                                    totalNewAfterWarrantyBusinessWithin90daysFromWarrantyExpiry += amc.AMC_PO_Value__c;
                                    newAfterWarrantyCount++;
                                }
                            }
                        }
                    }
                }
            }
        }

        return new Map<String, Object>{
            'totalNewAMCBusiness' => totalNewAMCBusiness,
            'newAMCCount' => newAMCCount,
            'totalRenewedAMCBusiness' => totalRenewedAMCBusiness,
            'renewedAMCCount' => renewedAMCCount,
            'totalNewAfterWarrantyBusinessWithin90daysFromWarrantyExpiry' => totalNewAfterWarrantyBusinessWithin90daysFromWarrantyExpiry,
            'newAfterWarrantyCount' => newAfterWarrantyCount
        };
    }
    catch (Exception e) {
        System.debug('❌ Error in getAMCBusinessChart: ' + e.getLineNumber() + ' - ' + e.getMessage());
        throw new AuraHandledException(e.getMessage());
    }
}


    /**
     * @description Method to get Last 07 Days Case History
     * @return `Object`
     * @exception Throws an AuraHandledException
     * @example
     * Object last7DaysCaseHistory = FieldServiceSEDashboardController.getLast7DaysCaseHistory();
     */
    @AuraEnabled(cacheable=true) // 5 - Last 07 Days Case History
    public static Object getLast7DaysCaseHistory() {
        try {
            String currentUserId = UserInfo.getUserId();
            Date today = System.today();
            Date last7Days = today.addDays(-7);

            AggregateResult casesAssignedInLast7Days = [
                SELECT COUNT(Id) totalCases
                FROM Case
                WHERE Assigned_Date_Time__c >= :last7Days AND Assigned_Date_Time__c <= :today AND OwnerId = :currentUserId
            ];

            AggregateResult casesAttendedInLast7Days = [
                SELECT COUNT(Case__c) totalCases
                FROM Service_Appointment__c
                WHERE Assigned_Date__c >= :last7Days AND Assigned_Date__c <= :today AND OwnerId = :currentUserId
            ];

            AggregateResult casesClosedInLast7Days = [
                SELECT COUNT(Id) totalCases
                FROM Case
                WHERE ClosedDate >= :last7Days AND ClosedDate <= :today AND OwnerId = :currentUserId
            ];

            AggregateResult openCasesAsOnToday = [
                SELECT COUNT(Id) totalCases
                FROM Case
                WHERE OwnerId = :currentUserId AND IsClosed = false
            ];

            return new Map<String, Object>{
                'casesAssignedInLast7Days' => casesAssignedInLast7Days.get('totalCases'),
                'casesAttendedInLast7Days' => casesAttendedInLast7Days.get('totalCases'),
                'casesClosedInLast7Days' => casesClosedInLast7Days.get('totalCases'),
                'openCasesAsOnToday' => openCasesAsOnToday.get('totalCases')
            };
        }
        catch (Exception e) {
            System.debug('❌ Error in getLast7DaysCaseHistory: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description Method to get List of OPEN Cases for Reason other than "WAITING FOR CUSTOMER PO"
     * @return `Object`
     * @exception Throws an AuraHandledException
     * @example
     * Object listOfOpenCases = FieldServiceSEDashboardController.getListOfOpenCases();
     */
    @AuraEnabled(cacheable=true) // 6 - List of OPEN Cases for Reason other than "WAITING FOR CUSTOMER PO"
    public static Object getListOfOpenCases() {
        try {
            String currentUserId = UserInfo.getUserId();

            List<Case> casesAssignedToMe = [
                SELECT Id
                FROM Case
                WHERE OwnerId = :currentUserId AND IsClosed = false
            ];

            Set<Id> caseIdsWhereQuoteIsAccepted = new Set<Id>();
            for(Quote q : [
                SELECT Id, Opportunity.Case__c
                FROM Quote
                WHERE Opportunity.Case__c IN :casesAssignedToMe AND Status IN ('Presented', 'Negotiation')
            ]) {
                caseIdsWhereQuoteIsAccepted.add(q.Opportunity.Case__c);
            }

            List<Case> listOfOpenCaseWhereQuoteIsNotAccepted = [
                SELECT Id, CaseNumber, AccountId, Account.Name, CreatedDate, Assigned_Date_Time__c,Priority,Subject,Status,Case_Sub_Type__c
                FROM Case
                WHERE OwnerId = :currentUserId AND IsClosed = false AND Id NOT IN :caseIdsWhereQuoteIsAccepted
            ];

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for(Case c : listOfOpenCaseWhereQuoteIsNotAccepted) {
                result.add(new Map<String, Object> {
                    'id' => c.Id,
                    'caseNumber' => c.CaseNumber,
                    'accountId' => c.AccountId,
                    'accountName' => c.Account.Name,
                    'createdDate' => c.CreatedDate,
                    'assignedDateTime' => c.Assigned_Date_Time__c,
                    'priority' => c.Priority,
                    'subject' => c.Subject,
                    'status' => c.Status,
                    'caseSubType' => c.Case_Sub_Type__c
                });
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getListOfOpenCases: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description get list of Returnable Sample Quotes
     * @return `List<Quote>`
     * @exception Throws an AuraHandledException
     * @example
     * List<QuoteLineItem> listOfReturnableSampleQuotes = FieldServiceSEDashboardController.getListOfReturnableSampleQuoteLineItems();
     */
    @AuraEnabled(cacheable=true) // 7 - List of Returnable Sample Quote Line Items
    public static Object getListOfReturnableSampleQuoteLineItems() {
        try {
            return [
                SELECT Id, Quantity, Grand_Price__c, Product2Id, Product2.Name, Product2.Description,
                Quote.Document_No_1__c, Quote.Quote_Start_Date__c, Quote.Expected_Close_Date__c,
                Quote.AccountId, Quote.Account.Name, Quote.Opportunity.Owner.Name
                FROM QuoteLineItem
                WHERE Quote.Status IN ('PO Received', 'Order Created') AND Quote.Returnable_Received__c = FALSE AND Quote.Billing_Type__c = 'FOC and Returnable'
                ORDER BY Quote.Opportunity.Owner.Name ASC, Quote.Expected_Close_Date__c ASC, Quote.Account.Name ASC
            ];
        }
        catch (Exception e) {
            System.debug('❌ Error in getListOfReturnableSampleQuotes: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


}