/**
 * AccPeriodExportService provides functionality to retrieve and assemble export rows 
 * for Journal Entries associated with a specific Accounting Period. It is designed for 
 * integration with ERP systems, formatting data to reflect net movements (debit or credit) 
 * within the period.
 * 
 * @date 2024
 */
public with sharing class AccPeriodExportService {

    private static final String TYPE_CREDIT = 'Credit';
    private static final String POSTING_STATUS_POSTED = 'Posted';
    private static final String AP_OBJ_KEY_PREFIX = ssfs__Accounting_Period__c.sObjectType.getDescribe().getKeyPrefix();
    @TestVisible
    private static final String INVALID_ID_MESSAGE = 'Invalid Id';
    
    private Id accPeriodId;
    private List<ExportRow> exportRows;

    /**
     * Constructor for AccPeriodExportService.
     * Validates the provided Accounting Period Id before initializing the service.
     * 
     * @param accPeriodId The Id of the Accounting Period to generate exports for.
     * @throws AccPeriodExportException if the provided Id is invalid.
     */
    public AccPeriodExportService(Id accPeriodId) {
        if (isValidId(accPeriodId)) {
            this.accPeriodId = accPeriodId;
        } else {
            throw new AccPeriodExportException(INVALID_ID_MESSAGE);
        }
    }

    /**
     * Retrieve the assembled list of ExportRow objects for the Accounting Period.
     * Ensures the export rows are only assembled once per service instance.
     * 
     * @return List of ExportRow objects representing the summarized journal entries.
     */
    public List<ExportRow> getExportRows() {
        if (exportRows == null) {
            exportRows = assembleExportRows();
        }
        return exportRows;
    }

    /**
     * Assemble export rows by aggregating journal entries from the database.
     * Each row summarizes net movement (debit or credit) for a GL Code on a specific date.
     * 
     * @return List of ExportRow objects with aggregated data.
     */
    private List<ExportRow> assembleExportRows() {
        List<ExportRow> lstExportRows = new List<ExportRow>();

        for (AggregateResult ar : getAggregatedEntries()) {
            ExportRow row = new ExportRow();

            row.glCode = (String) ar.get('ssfs__GL_Code__c');
            row.rowDate = Date.newInstance(
                (Integer) ar.get('year'), 
                (Integer) ar.get('month'), 
                (Integer) ar.get('day')
            );

            Decimal totalDebit = (Decimal) ar.get('totalDebit');
            Decimal totalCredit = (Decimal) ar.get('totalCredit');
            Decimal netCreditAmount = (totalCredit != null ? totalCredit : 0.00) - (totalDebit != null ? totalDebit : 0.00);

            // Determine if the net amount should be displayed as a debit or credit
            row.debit = 0.00;
            row.credit = 0.00;
            if (netCreditAmount > 0) {
                row.credit = netCreditAmount;
            } else if (netCreditAmount < 0) {
                row.debit = Math.abs(netCreditAmount);
            }

            // Set the export information string
            row.exportInformation = getExportInformation(row);
            lstExportRows.add(row);
        }

        return lstExportRows;
    }

    /**
     * Generate export information string for each ExportRow.
     * 
     * @param row The ExportRow object for which to generate the information.
     * @return A formatted string representing export information.
     */
    private static String getExportInformation(ExportRow row) {
        // 'NPSP240130' for 2024-01-30
        String baseString = 'NPSP';
        Datetime dt = Datetime.newInstance(row.rowDate.year(), row.rowDate.month(), row.rowDate.day());
        return baseString + dt.format('yyMMdd');
    }

    /**
     * Validate an Accounting Period Id.
     * 
     * @param recordId The Id to validate.
     * @return True if the Id is valid and belongs to an Accounting Period, False otherwise.
     */
    private static Boolean isValidId(String recordId) {
        return isAccountingPeriodId(recordId) && isValidIdLength(recordId);
    }

    /**
     * Check if the provided Id matches the key prefix for Accounting Period objects.
     * 
     * @param recordId The Id to check.
     * @return True if the Id starts with the Accounting Period object key prefix, False otherwise.
     */
    private static Boolean isAccountingPeriodId(String recordId) {
        return String.valueOf(recordId).startsWith(AP_OBJ_KEY_PREFIX);
    }

    /**
     * Validate the length of the provided Id.
     * 
     * @param recordId The Id to validate.
     * @return True if the Id length is valid (15 or 18 characters), False otherwise.
     */
    private static Boolean isValidIdLength(String recordId) {
        return (recordId.length() == 15 || recordId.length() == 18);
    }

    /**
     * Aggregate journal entries by GL Code and date.
     * 
     * @return List of AggregateResult representing summarized journal entries.
     */
    private List<AggregateResult> getAggregatedEntries() {
        return [
            SELECT ssfs__GL_Code__c, 
                   CALENDAR_YEAR(ssfs__Date__c) year, CALENDAR_MONTH(ssfs__Date__c) month, DAY_IN_MONTH(ssfs__Date__c) day, 
                   SUM(ssfs__Debit__c) totalDebit, SUM(ssfs__Credit__c) totalCredit
              FROM ssfs__Journal_Entry__c
             WHERE ssfs__Accounting_Period__c = :accPeriodId
               AND ssfs__Posting_Status__c != :POSTING_STATUS_POSTED
              WITH USER_MODE
             GROUP BY CALENDAR_YEAR(ssfs__Date__c), CALENDAR_MONTH(ssfs__Date__c), DAY_IN_MONTH(ssfs__Date__c), ssfs__GL_Code__c
        ];
    }

    /**
     * A row of data to be exported.
     */
    public class ExportRow {
        @AuraEnabled
        public String glCode {get; set;}
        @AuraEnabled
        public Decimal debit {get; set;}
        @AuraEnabled
        public Decimal credit {get; set;}
        @AuraEnabled
        public Date rowDate {get; set;}
        @AuraEnabled
        public String exportInformation {get; set;}
    }

    public class AccPeriodExportException extends Exception {}

}