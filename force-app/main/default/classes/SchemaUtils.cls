/**
 * Created By       :   Girikon(Sachin Chaudhary)
 * Created On       :   18/12/2019
 * @description     :   This class provides following functionalities:          
 *                      Allow to get schema of a field like picklist options, field label,helptext, isaccessible,is updateable and iscreatedtable
 *                      
 * Helper Class     :   N/A
 * Test Class       :   OppActionButtonController_Test(100%)
 **/
public with sharing class SchemaUtils {

    public static Map<String, FieldDto> describeSobjects(Set<String> p_objectFieldOrder) {

        Set<String> typeSets = new Set<String>();

        for (String objectField : p_objectFieldOrder) {
            List<String> objField = objectField.split('\\.');
            String objectType = objField.get(0);
            String fieldName = objField.get(1);
            typeSets.add(objectType);
        }
    List<String> types = new List<String>();
        types.addAll(typeSets);
        // Make the describe call
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);

        System.debug('Got describe information for ' + results.size() + ' sObjects.');

        Map<String, Map<String, SObjectField>> objectFields = new Map<String, Map<String, SObjectField>>();
        // For each returned result, get some info
        for(Schema.DescribeSobjectResult res : results) {
            objectFields.put(res.getName(), res.fields.getMap());
        }

        Map<String, FieldDto> fields = new Map<String, FieldDto>();
        for (String objectField : p_objectFieldOrder) {
            List<String> objField = objectField.split('\\.');
            String objectType = objField.get(0);
            String fieldName = objField.get(1);


            if (objectFields.containsKey(objectType)) {
                Map<String, SObjectField> fieldsMap = objectFields.get(objectType);

                if (fieldsMap.containsKey(fieldName)) {
                    fields.put(objectField, new FieldDto(fieldsMap.get(fieldName)));
                }
            }
        }
        return fields;
    }

    public static List<SelectOptionDto> picklistEntryToDto(List<Schema.PicklistEntry> p_entries) {
        List<SelectOptionDto> options = new List<SelectOptionDto>();

        for (Schema.PicklistEntry entry : p_entries) {
            options.add(new SelectOptionDto(entry));
        }

        return options;
    }

    public class SelectOptionDto {
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public String label { get; set; }

        public SelectOptionDto(Schema.PicklistEntry p_picklistEntry) {
            this.value = p_picklistEntry.getValue();
            this.label = p_picklistEntry.getLabel();
        }
    }
    public class FieldDto {
        @AuraEnabled
        public String FieldLabel { get; set; }
        @AuraEnabled
        public String FieldType { get; set; }
        @AuraEnabled
        public String FieldName { get; set; }
        @AuraEnabled
        public String FieldRelationshipName { get; set; }

        @AuraEnabled
        public List<SelectOptionDto> FieldPicklist { get; set; }
        @AuraEnabled
        public Boolean IsUpdateable { get; set; }
        @AuraEnabled
        public Boolean IsAccessible { get; set; }
        @AuraEnabled
        public Boolean FieldRequired { get; set; }
        @AuraEnabled
        public String FieldHelpText { get; set; }
        @AuraEnabled
        public Integer Scale { get; set; }

        public FieldDto(Schema.SObjectField p_field) {
            Schema.DescribeFieldResult dfr = p_field.getDescribe();
            this.FieldLabel = dfr.getLabel();
            this.FieldName = dfr.getName();
            this.FieldType = String.valueOf(dfr.getType());
            this.FieldRelationshipName = dfr.getRelationshipName();
            this.FieldPicklist = SchemaUtils.picklistEntryToDto(dfr.getPicklistValues());
            this.IsAccessible = dfr.isAccessible();
            this.IsUpdateable = dfr.isUpdateable();
            this.FieldRequired = !dfr.isNillable();
            this.FieldHelpText = String.isEmpty(dfr.getInlineHelpText()) ? this.FieldLabel : dfr.getInlineHelpText();
            this.Scale = dfr.getScale();
        }
    }
}