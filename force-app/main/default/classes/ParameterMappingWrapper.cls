/**
 * @description Wrapper class to store hierarchical linkage between ParameterMapping__mdt,
 *              ParameterSelectedOptions__mdt, and ParameterSelectedType__mdt objects.
 *              Structure: ParameterMapping → ParameterSelectedOptions → ParameterSelectedType
 * @author Auto Generated
 */
public with sharing class ParameterMappingWrapper {
    
    /**
     * @description Wrapper for ParameterSelectedType__mdt (Grandchild/Leaf level)
     */
    public class ParameterSelectedTypeWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String selectionValueType { get; set; }
        @AuraEnabled public String parentOptionId { get; set; }
        
        public ParameterSelectedTypeWrapper() {}
        
        public ParameterSelectedTypeWrapper(ParameterSelectedType__mdt record) {
            this.id = record.Id;
            this.developerName = record.DeveloperName;
            this.label = record.Label;
            this.selectionValueType = record.SelectionValueType__c;
            this.parentOptionId = record.ParameterSelectedOption__c;
        }
    }
    
    /**
     * @description Wrapper for ParameterSelectedOptions__mdt (Child/Middle level)
     *              Contains list of child ParameterSelectedType records
     */
    public class ParameterSelectedOptionWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Boolean isMultiple { get; set; }
        @AuraEnabled public String parentMappingId { get; set; }
        @AuraEnabled public List<ParameterSelectedTypeWrapper> selectedTypes { get; set; }
        
        public ParameterSelectedOptionWrapper() {
            this.selectedTypes = new List<ParameterSelectedTypeWrapper>();
        }
        
        public ParameterSelectedOptionWrapper(ParameterSelectedOptions__mdt record) {
            this.id = record.Id;
            this.developerName = record.DeveloperName;
            this.label = record.Label;
            this.isMultiple = record.isMultiple__c;
            this.parentMappingId = record.ParameterMapping__c;
            this.selectedTypes = new List<ParameterSelectedTypeWrapper>();
        }
        
        /**
         * @description Add a child ParameterSelectedType to this option
         * @param typeWrapper The type wrapper to add
         */
        public void addSelectedType(ParameterSelectedTypeWrapper typeWrapper) {
            if (this.selectedTypes == null) {
                this.selectedTypes = new List<ParameterSelectedTypeWrapper>();
            }
            this.selectedTypes.add(typeWrapper);
        }
    }
    
    /**
     * @description Wrapper for ParameterMapping__mdt (Parent/Top level)
     *              Contains list of child ParameterSelectedOptions records
     */
    public class ParameterMappingRecordWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Boolean isMultiple { get; set; }
        @AuraEnabled public List<ParameterSelectedOptionWrapper> selectedOptions { get; set; }
        
        public ParameterMappingRecordWrapper() {
            this.selectedOptions = new List<ParameterSelectedOptionWrapper>();
        }
        
        public ParameterMappingRecordWrapper(ParameterMapping__mdt record) {
            this.id = record.Id;
            this.developerName = record.DeveloperName;
            this.label = record.Label;
            this.isMultiple = record.isMultiple__c;
            this.selectedOptions = new List<ParameterSelectedOptionWrapper>();
        }
        
        /**
         * @description Add a child ParameterSelectedOption to this mapping
         * @param optionWrapper The option wrapper to add
         */
        public void addSelectedOption(ParameterSelectedOptionWrapper optionWrapper) {
            if (this.selectedOptions == null) {
                this.selectedOptions = new List<ParameterSelectedOptionWrapper>();
            }
            this.selectedOptions.add(optionWrapper);
        }
    }
    
    /**
     * @description Build complete hierarchy of all Parameter Mappings with their children
     * @return List of ParameterMappingRecordWrapper with nested children
     */
    @AuraEnabled(cacheable=true)
    public static List<ParameterMappingRecordWrapper> buildCompleteHierarchy() {
        // Query all records from the three objects
        List<ParameterMapping__mdt> mappings = [
            SELECT Id, DeveloperName, Label, isMultiple__c , Display_Order__c
            FROM ParameterMapping__mdt
            ORDER BY Display_Order__c ASC
        ];
        
        List<ParameterSelectedOptions__mdt> options = [
            SELECT Id, DeveloperName, Label, isMultiple__c, ParameterMapping__c 
            FROM ParameterSelectedOptions__mdt
        ];
        
        List<ParameterSelectedType__mdt> types = [
            SELECT Id, DeveloperName, Label, SelectionValueType__c, ParameterSelectedOption__c 
            FROM ParameterSelectedType__mdt
        ];
        
        // Create map of ParameterSelectedOption Id to list of ParameterSelectedTypes
        Map<String, List<ParameterSelectedTypeWrapper>> optionToTypesMap = new Map<String, List<ParameterSelectedTypeWrapper>>();
        for (ParameterSelectedType__mdt typeRecord : types) {
            String optionId = typeRecord.ParameterSelectedOption__c;
            if (!optionToTypesMap.containsKey(optionId)) {
                optionToTypesMap.put(optionId, new List<ParameterSelectedTypeWrapper>());
            }
            optionToTypesMap.get(optionId).add(new ParameterSelectedTypeWrapper(typeRecord));
        }
        
        // Create map of ParameterMapping Id to list of ParameterSelectedOptions
        Map<String, List<ParameterSelectedOptionWrapper>> mappingToOptionsMap = new Map<String, List<ParameterSelectedOptionWrapper>>();
        for (ParameterSelectedOptions__mdt optionRecord : options) {
            String mappingId = optionRecord.ParameterMapping__c;
            if (!mappingToOptionsMap.containsKey(mappingId)) {
                mappingToOptionsMap.put(mappingId, new List<ParameterSelectedOptionWrapper>());
            }
            
            ParameterSelectedOptionWrapper optionWrapper = new ParameterSelectedOptionWrapper(optionRecord);
            
            // Add child types to this option
            if (optionToTypesMap.containsKey(optionRecord.Id)) {
                optionWrapper.selectedTypes = optionToTypesMap.get(optionRecord.Id);
            }
            
            mappingToOptionsMap.get(mappingId).add(optionWrapper);
        }
        
        // Build final hierarchy
        List<ParameterMappingRecordWrapper> result = new List<ParameterMappingRecordWrapper>();
        for (ParameterMapping__mdt mappingRecord : mappings) {
            ParameterMappingRecordWrapper mappingWrapper = new ParameterMappingRecordWrapper(mappingRecord);
            
            // Add child options to this mapping
            if (mappingToOptionsMap.containsKey(mappingRecord.Id)) {
                mappingWrapper.selectedOptions = mappingToOptionsMap.get(mappingRecord.Id);
            }
            
            result.add(mappingWrapper);
        }
        
        return result;
    }
    
    /**
     * @description Get hierarchy for a specific ParameterMapping by DeveloperName
     * @param developerName The DeveloperName of the ParameterMapping__mdt record
     * @return ParameterMappingRecordWrapper with nested children, or null if not found
     */
    @AuraEnabled(cacheable=true)
    public static ParameterMappingRecordWrapper getHierarchyByDeveloperName(String developerName) {
        // Query the specific mapping
        List<ParameterMapping__mdt> mappings = [
            SELECT Id, DeveloperName, Label, isMultiple__c 
            FROM ParameterMapping__mdt 
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];
        
        if (mappings.isEmpty()) {
            return null;
        }
        
        ParameterMapping__mdt mapping = mappings[0];
        ParameterMappingRecordWrapper mappingWrapper = new ParameterMappingRecordWrapper(mapping);
        
        // Query related options
        List<ParameterSelectedOptions__mdt> options = [
            SELECT Id, DeveloperName, Label, isMultiple__c, ParameterMapping__c 
            FROM ParameterSelectedOptions__mdt 
            WHERE ParameterMapping__c = :mapping.Id
        ];
        
        // Get all option IDs for querying types
        Set<Id> optionIds = new Set<Id>();
        for (ParameterSelectedOptions__mdt opt : options) {
            optionIds.add(opt.Id);
        }
        
        // Query related types
        List<ParameterSelectedType__mdt> types = [
            SELECT Id, DeveloperName, Label, SelectionValueType__c, ParameterSelectedOption__c 
            FROM ParameterSelectedType__mdt 
            WHERE ParameterSelectedOption__c IN :optionIds
        ];
        
        // Create map of option to types
        Map<Id, List<ParameterSelectedTypeWrapper>> optionToTypesMap = new Map<Id, List<ParameterSelectedTypeWrapper>>();
        for (ParameterSelectedType__mdt typeRecord : types) {
            Id optionId = typeRecord.ParameterSelectedOption__c;
            if (!optionToTypesMap.containsKey(optionId)) {
                optionToTypesMap.put(optionId, new List<ParameterSelectedTypeWrapper>());
            }
            optionToTypesMap.get(optionId).add(new ParameterSelectedTypeWrapper(typeRecord));
        }
        
        // Build options with their types
        for (ParameterSelectedOptions__mdt optionRecord : options) {
            ParameterSelectedOptionWrapper optionWrapper = new ParameterSelectedOptionWrapper(optionRecord);
            if (optionToTypesMap.containsKey(optionRecord.Id)) {
                optionWrapper.selectedTypes = optionToTypesMap.get(optionRecord.Id);
            }
            mappingWrapper.addSelectedOption(optionWrapper);
        }
        
        return mappingWrapper;
    }
}