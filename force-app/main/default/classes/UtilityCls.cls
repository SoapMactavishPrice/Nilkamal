/**
 * @author Aditya Zagade
 * @since  1 Dec 2024
 *
 * @group Utility
 */
public class UtilityCls {

    /**
     * @description Method to get all fields
     * @param sObjectName
     * @return  `Map<String, String>`
     * @example
     * Map<String, String> fields = getAllFields('Account');
     */
    public static Map<String, String> getAllFields(String sObjectName) {
        if (!Schema.getGlobalDescribe().containsKey(sObjectName)) {
            Map<String, String> tempMap = new Map<String, String>();
            tempMap.put('Exception', 'Invalid object name');
            return tempMap;
        }

        Map<String,Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();

        String allFields = '';
        for (Schema.SObjectField field: fields.values()) {
            if (field.getDescribe().isAccessible()) {
                allFields += field.getDescribe().getName() + ', ';
            }
        }
        system.debug('allFields'+allFields);
        allFields = allFields.subString(0, allFields.length() - 2);
        system.debug('allFields'+allFields);
        Map<String, String> tempMap = new Map<String, String>{sObjectName => allFields};
        return tempMap;
    }



    /**
     * @description Method to get all picklist values
     * @param objectName
     * @param fieldName
     * @return  `Map<String,String>`
     * @example
     * Map<String,String> picklistValues = UtilityCls.getPickList('Account', 'Type');
     */
    public static Map<String,String> getPickList(String objectName, String fieldName) {
        Map<String,String> fieldLabelAndValueMap = new Map<String,String>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            // System.debug(pickListVal.getLabel() +' '+pickListVal.getValue());
            fieldLabelAndValueMap.put(pickListVal.getLabel(), pickListVal.getValue());
        }
        return  fieldLabelAndValueMap;
    }



    /**
     * @description Method to get filter values
     * @param objectApiName
     * @param fieldNames
     * @param filter
     * @return  `Object`
     * @exception Throws an AuraHandledException
     * @example
     * Object filterValues = UtilityCls.getFilterValues('Account', new List<String>{'Name'}, 'Name = \'Test\'');
     */
    @AuraEnabled(cacheable=true)
    public static Object getFilterValues(String objectApiName, List<String> fieldNames, String filter) {
        try {
            List<Object> filterList = new List<Object>();

            for (String fieldName : fieldNames) {
                Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
                Schema.DescribeFieldResult fieldDescribe;
                String baseObjectApiName = objectApiName;

                if (fieldName.contains('.')) {
                    List<String> parts = fieldName.split('\\.');
                    for (Integer i = 0; i < parts.size() - 1; i++) {
                        String relationshipField = parts[i];
                        String relationshipKey = fieldMap.containsKey(relationshipField + 'Id') ? relationshipField + 'Id' : relationshipField.replace('__r', '__c');
                        System.debug('relationshipKey: ' + relationshipKey);

                        if (fieldMap.containsKey(relationshipKey) && fieldMap.get(relationshipKey).getDescribe().getType() == Schema.DisplayType.REFERENCE) {
                            Schema.SObjectType relatedObjectType = fieldMap.get(relationshipKey).getDescribe().getReferenceTo()[0];
                            fieldMap = relatedObjectType.getDescribe().fields.getMap();
                            baseObjectApiName = relatedObjectType.getDescribe().getName();
                        } else {
                            throw new CustomException('Invalid relationship field: ' + relationshipKey + ' - ' + fieldName + ' in ' + baseObjectApiName);
                        }
                    }

                    String finalField = parts[parts.size() - 1];
                    if (fieldMap.containsKey(finalField)) {
                        fieldDescribe = fieldMap.get(finalField).getDescribe();
                    } else {
                        throw new CustomException('Field ' + finalField + ' does not exist on ' + baseObjectApiName);
                    }
                } else {
                    if (fieldMap.containsKey(fieldName)) {
                        fieldDescribe = fieldMap.get(fieldName).getDescribe();
                    } else {
                        throw new CustomException('Field ' + fieldName + ' does not exist on ' + objectApiName);
                    }
                }


                if (fieldDescribe != null) {
                    Map<String, Object> customFieldMap = new Map<String, Object>();
                    customFieldMap.put('label', fieldDescribe.getLabel());
                    customFieldMap.put('apiName', fieldName);

                    List<Object> filterOptions = new List<Object>();
                    filterOptions.add(new Map<String, Object> {'label' => '--None--', 'value' => ''});


                    if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST) {
                        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
                        for (Schema.PicklistEntry picklistValue : picklistValues) {
                            Map<String, Object> picklistValueMap = new Map<String, Object> {
                                'label' => picklistValue.getLabel(),
                                'value' => picklistValue.getValue()
                            };
                            filterOptions.add(picklistValueMap);
                        }
                    }
                    else if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                        String relatedObjectName = fieldDescribe.getReferenceTo()[0].getDescribe().getName();
                        String query = 'SELECT Id, Name FROM ' + relatedObjectName + ' WHERE Name != null ' + (String.isBlank(filter) ? '' : ' AND ' + filter) +' ORDER BY Name';
                        for (SObject result : Database.query(query)) {
                            Map<String, Object> picklistValueMap = new Map<String, Object> {
                                'label' => result.get('Name'),
                                'value' => result.get('Id')
                            };
                            filterOptions.add(picklistValueMap);
                        }
                    }
                    else if (fieldDescribe.getType() == Schema.DisplayType.DATE || fieldDescribe.getType() == Schema.DisplayType.DATETIME) {
                        String aggregateQuery = 'SELECT DAY_ONLY(' + fieldName + ') dt FROM ' + objectApiName + ' WHERE ' + fieldName + ' != null ' +
                                                (String.isBlank(filter) ? '' : ' AND ' + filter) +
                                                ' GROUP BY DAY_ONLY(' + fieldName + ')';
                        for (AggregateResult result : Database.query(aggregateQuery)) {
                            Map<String, Object> picklistValueMap = new Map<String, Object> {
                                'label' => result.get('dt'),
                                'value' => result.get('dt')
                            };
                            filterOptions.add(picklistValueMap);
                        }
                    }
                    else if (fieldDescribe.getType() == Schema.DisplayType.STRING || fieldDescribe.getType() == Schema.DisplayType.TEXTAREA || fieldDescribe.getType() == Schema.DisplayType.DOUBLE || fieldDescribe.getType() == Schema.DisplayType.INTEGER || fieldDescribe.getType() == Schema.DisplayType.LONG || fieldDescribe.getType() == Schema.DisplayType.PERCENT) {
                        String aggregateQuery = 'SELECT ' + fieldName + ' field FROM ' + objectApiName + + ' WHERE ' + fieldName + ' != null ' +
                                                (String.isBlank(filter) ? '' : ' AND ' + filter) + ' GROUP BY ' + fieldName;
                        for (AggregateResult result : Database.query(aggregateQuery)) {
                            Map<String, Object> picklistValueMap = new Map<String, Object> {
                                'label' => result.get('field'),
                                'value' => result.get('field')
                            };
                            filterOptions.add(picklistValueMap);
                        }
                    }
                    else if (fieldDescribe.getType() == Schema.DisplayType.BOOLEAN) {
                        filterOptions.add(new Map<String, Object> { 'label' => 'Yes', 'value' => 'true' });
                        filterOptions.add(new Map<String, Object> { 'label' => 'No', 'value' => 'false' });
                    }

                    customFieldMap.put('values', filterOptions);
                    filterList.add(customFieldMap);
                }
            }

            return filterList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }





    /**
     * @description Method to get user ids reporting to me
     * @param userId Id of the user
     * @return Set<Id>
     * @example
     * Set<Id> userIds = UtilityCls.getUserIdsReportingToMe();
     */
    public static Set<Id> getUserIdsReportingToMe() {
        Set<Id> userIds = new Set<Id>();
        Id userId = UserInfo.getUserId();
        for(User u : [
            SELECT Id
            FROM User
            WHERE ManagerId = :userId OR
            Manager.ManagerId = :userId OR
            Manager.Manager.ManagerId = :userId OR
            Manager.Manager.Manager.ManagerId = :userId OR
            Manager.Manager.Manager.Manager.ManagerId = :userId OR
            Manager.Manager.Manager.Manager.Manager.ManagerId = :userId OR
            Manager.Manager.Manager.Manager.Manager.Manager.ManagerId = :userId
        ])
        {
            userIds.add(u.Id);
        }
        userIds.add(userId);

        return userIds;
    }



    /**
     * @description Method to get current fiscal year start and end date and name
     * @return Map<String, Object>
     * @example
     * Map<String, Object> currentFYStartEndDate = UtilityCls.getCurrentFYDetails();
     */
    public static Map<String, Object> getCurrentFYDetails() {
        Map<String, Object> currentFYStartEndDate = new Map<String, Object>();
        Date today = System.today();
        if(today >= Date.newInstance(today.year(), 4, 1)) {
            currentFYStartEndDate.put('start', Date.newInstance(today.year(), 4, 1));
            currentFYStartEndDate.put('end', Date.newInstance(today.year() + 1, 3, 31));
            currentFYStartEndDate.put('fyName', 'FY ' + today.year() + '-' + (today.year() + 1));
        } else {
            currentFYStartEndDate.put('start', Date.newInstance(today.year() - 1, 4, 1));
            currentFYStartEndDate.put('end', Date.newInstance(today.year(), 3, 31));
            currentFYStartEndDate.put('fyName', 'FY ' + (today.year() - 1) + '-' + today.year());
        }
        return currentFYStartEndDate;
    }



    /**
     * @description Method to get Start Date and End Date from FY Name
     * @return Map<String, Object>
     * @example
     * Map<String, Date> startEndDate = UtilityCls.getStartEndDateFromFYName('FY 2023-2024');
     */
    public static Map<String, Date> getStartEndDateFromFYName(String fyName) {
        Map<String, Date> startEndDate = new Map<String, Date>();
        String fyYear = fyName.split(' ')[1];
        startEndDate.put('start', Date.newInstance(Integer.valueOf(fyYear.split('-')[0]), 4, 1));
        startEndDate.put('end', Date.newInstance(Integer.valueOf('20' + fyYear.split('-')[1]), 3, 31));
        return startEndDate;
    }



    /**
     * @description Method to list of pincode where I am assigned
     * @return Set<Id>
     * @example
     * Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();
     */
    public static Set<Id> getPincodeListAssignedToMe() {
        Set<Id> usersReportingToMe = getUserIdsReportingToMe();
        Set<Id> pincodeIds = new Set<Id>();
        for(AggregateResult result : [
            SELECT Pin_Code_Master__c
            FROM Service_Resource_Pincode__c
            WHERE Service_Resource__r.User__c IN :usersReportingToMe
            GROUP BY Pin_Code_Master__c
        ]) {
            pincodeIds.add((Id)result.get('Pin_Code_Master__c'));
        }
        return pincodeIds;
    }



    /**
     * @description Method to get list of pincode RSM wise
     * @return Map<Id, Set<Id>>
     * @example
     * Map<Id, Set<Id>> rsmWisePincodeIds = UtilityCls.getRSMWisePincodeList();
     */
    public static Map<Id, Set<Id>> getRSMWisePincodeList() {
        Set<Id> usersReportingToMe = getUserIdsReportingToMe();
        Set<Id> rsmRoleIds = new Set<Id>();
        for(UserRole ur : [
            SELECT Id
            FROM UserRole
            WHERE Name LIKE '%RSM%'
        ]) {
            rsmRoleIds.add(ur.Id);
        }

        Map<Id, Set<Id>> rsmWisePincodeIds = new Map<Id, Set<Id>>();
        for(AggregateResult result : [
            SELECT Service_Resource__r.User__r.ManagerId rsmId, Pin_Code_Master__c
            FROM Service_Resource_Pincode__c
            WHERE Service_Resource__r.User__r.Manager.UserRoleId IN :rsmRoleIds AND Service_Resource__r.User__c IN :usersReportingToMe
            GROUP BY Service_Resource__r.User__r.ManagerId, Pin_Code_Master__c
        ]) {
            if(!rsmWisePincodeIds.containsKey((Id) result.get('rsmId'))) {
                rsmWisePincodeIds.put((Id)result.get('rsmId'), new Set<Id>());
            }
            rsmWisePincodeIds.get((Id)result.get('rsmId')).add((Id)result.get('Pin_Code_Master__c'));
        }

        return rsmWisePincodeIds;
    }





    /**
     * @description Method to get user details
     * @param userId
     * @return User
     * @example
     * User user = UtilityCls.getUserDetails('0055g00000Ie2PfAAL');
     */
    @AuraEnabled(cacheable=true)
    public static User getUserDetails() {
        return [SELECT Id, Name, Email, UserRoleId, UserRole.Name, ProfileId, Profile.Name
                FROM User
                WHERE Id = :UserInfo.getUserId()];
    }





    private static List<String> one = new List<String>();
    private static List<String> ten = new List<String>();
    /**
     * @description Method to get number in words up to Crore in INR
     * @param n
     * @return  `String`
     * @example
     * String numberInWords = UtilityCls.getNumberToWordsINR(100000);
     */
    public static String getNumberToWordsINR(Decimal n) {
        one.add('');
        one.add('One ');
        one.add('Two ');
        one.add('Three ');
        one.add('Four ');
        one.add('Five ');
        one.add('Six ');
        one.add('Seven ');
        one.add('Eight ');
        one.add('Nine ');
        one.add('Ten ');
        one.add('Eleven ');
        one.add('Twelve ');
        one.add('Thirteen ');
        one.add('Fourteen ');
        one.add('Fifteen ');
        one.add('Sixteen ');
        one.add('Seventeen ');
        one.add('Eighteen ');
        one.add('Nineteen ');

        ten.add('');
        ten.add('');
        ten.add('Twenty ');
        ten.add('Thirty ');
        ten.add('Forty ');
        ten.add('Fifty ');
        ten.add('Sixty ');
        ten.add('Seventy ');
        ten.add('Eighty ');
        ten.add('Ninety ');

        String out = '';

        out += numToWords((Integer)(n / 10000000), 'Crore ');
        out += numToWords((Integer)(math.mod((Integer)(n / 100000), 100)), 'Lakh ');
        out += numToWords((Integer)(math.mod((Integer)(n / 1000), 100)), 'Thousand ');
        out += numToWords((Integer)(math.mod((Integer)(n / 100), 10)), 'Hundred ');
        if (n > 100 && math.mod((Integer)n, 100) > 0) {
            out += 'And ';
        }
        out += numToWords((Integer)(math.mod((Integer)n, 100)), '');
        out += ' Rupees';
        return out;
    }

    private static String numToWords(Integer n, String s) {
        String str = '';
        if (n > 19) {
            str += ten[n / 10] + one[math.mod(n, 10)];
        } else {
            str += one[n];
        }

        if (n != 0) {
            str += s;
        }
        return str;
    }





    private static final String zero = 'Zero';
    private static List<String> oneToNine = new List<String>();
    private static List<String> tenToNineteen = new List<String>();
    private static List<String> dozens = new List<String>();
    private static Boolean isFirstTime = true;
    /**
     * @description Method to get number in words up to Padma in INR
     * @author Aditya Zagade
     * @param num
     * @return  `String`
     * @example
     * String numberInWords = UtilityCls.getNumberToWordsLongNumberINR(100000);
     */
    public static String getNumberToWordsLongNumberINR(Decimal num) {
        if(isFirstTime) {
            isFirstTime = !isFirstTime;

            oneToNine.add('One ');
            oneToNine.add('Two ');
            oneToNine.add('Three ');
            oneToNine.add('Four ');
            oneToNine.add('Five ');
            oneToNine.add('Six ');
            oneToNine.add('Seven ');
            oneToNine.add('Eight ');
            oneToNine.add('Nine ');

            tenToNineteen.add('Ten ');
            tenToNineteen.add('Eleven ');
            tenToNineteen.add('Twelve ');
            tenToNineteen.add('Thirteen ');
            tenToNineteen.add('Fourteen ');
            tenToNineteen.add('Fifteen ');
            tenToNineteen.add('Sixteen ');
            tenToNineteen.add('Seventeen ');
            tenToNineteen.add('Eighteen ');
            tenToNineteen.add('Nineteen ');

            dozens.add('Ten ');
            dozens.add('Twenty ');
            dozens.add('Thirty ');
            dozens.add('Forty ');
            dozens.add('Fifty ');
            dozens.add('Sixty ');
            dozens.add('Seventy ');
            dozens.add('Eighty ');
            dozens.add('Ninety ');
        }

        if(num >= 1000000000000000L) {
            return getNumberToWordsLongNumberINR(num / 1000000000000000L) + ' Padma ' + getNumberToWordsLongNumberINR(Math.mod((Long)num, 1000000000000000L));
        } else if(num >= 10000000000000L) {
            return getNumberToWordsLongNumberINR(num / 10000000000000L) + ' Neel ' + getNumberToWordsLongNumberINR(Math.mod((Long)num, 10000000000000L));
        } else if(num >= 100000000000L) {
            return getNumberToWordsLongNumberINR(num / 100000000000L) + ' Kharab ' + getNumberToWordsLongNumberINR(Math.mod((Long)num, 100000000000L));
        } else if(num >= 1000000000) {
            return getNumberToWordsLongNumberINR(num / 1000000000) + ' Arab ' + getNumberToWordsLongNumberINR(Math.mod((Long)num, 1000000000));
        } else if(num >= 10000000) {
            return getNumberToWordsLongNumberINR(num / 10000000) + ' Crore ' + getNumberToWordsLongNumberINR(Math.mod((Long)num, 10000000));
        } else if(num >= 100000) {
            return getNumberToWordsLongNumberINR(num / 100000) + ' Lakh ' + getNumberToWordsLongNumberINR(Math.mod((Long)num, 100000));
        } else if(num >= 1000) {
            return getNumberToWordsLongNumberINR(num / 1000) + ' Thousand ' + getNumberToWordsLongNumberINR(Math.mod((Long)num, 1000));
        } else if(num >= 100) {
            return getNumberToWordsLongNumberINR(num / 100) + ' Hundred ' + getNumberToWordsLongNumberINR(Math.mod((Long)num, 100));
        }

        return generate1To99((Integer)num);
    }

    private static String generate1To99(Integer num) {
        if (num == 0)
            return '';

        if (num <= 9)
            return oneToNine[num - 1];
        else if (num <= 19)
            return tenToNineteen[Math.mod(num, 10)];
        else
            return dozens[num / 10 - 1] + ' ' + generate1To99(Math.mod(num, 10));
    }

}