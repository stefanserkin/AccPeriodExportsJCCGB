public with sharing class AccPeriodExportService {

    private static final String TYPE_CREDIT = 'Credit';
    private static final String AP_OBJ_KEY_PREFIX = ssfs__Accounting_Period__c.sObjectType.getDescribe().getKeyPrefix();

    @TestVisible
    private static final String INVALID_ID_MESSAGE = 'Invalid Id';
    
    private Id accPeriodId;

    private List<ExportRow> exportRows;
    private List<ssfs__Journal_Entry__c> journalEntries;

    public AccPeriodExportService(Id accPeriodId) {
        if (isValidId(accPeriodId)) {
            this.accPeriodId = accPeriodId;
        } else {
            throw new AccPeriodExportException(INVALID_ID_MESSAGE);
        }
    }

    public List<ExportRow> getExportRows() {
        if (exportRows == null) {
            // lstExportRows = convertJesToExportRows( getJournalEntries() );
            exportRows = assembleExportRows();
        }
        return exportRows;
    }

    private List<ExportRow> assembleExportRows() {
        List<ExportRow> lstExportRows = new List<ExportRow>();

        for (AggregateResult ar : getAggregateEntries()) {
            ExportRow row = new ExportRow();

            row.glCode = (String) ar.get('ssfs__GL_Code__c');
            row.rowDate = Date.newInstance(
                (Integer) ar.get('year'), 
                (Integer) ar.get('month'), 
                (Integer) ar.get('day')
            );

            Decimal totalDebit = (Decimal) ar.get('totalDebit');
            Decimal totalCredit = (Decimal) ar.get('totalCredit');
            Decimal netAmount = (totalCredit != null ? totalCredit : 0.00) - (totalDebit != null ? totalDebit : 0.00);

            // Set only the column with a positive net amount (rather than total debit and credit)
            row.debit = 0.00;
            row.credit = 0.00;
            if (netAmount > 0) {
                row.credit = netAmount;
            } else if (netAmount < 0) {
                row.debit = Math.abs(netAmount);
            }

            row.exportInformation = getExportInformation(row);

            System.debug(row);
            lstExportRows.add(row);
        }
        return lstExportRows;
    }

    private List<AggregateResult> getAggregateEntries() {
        return [
            SELECT ssfs__GL_Code__c, 
                   CALENDAR_YEAR(ssfs__Date__c) year, CALENDAR_MONTH(ssfs__Date__c) month, DAY_IN_MONTH(ssfs__Date__c) day, 
                   SUM(ssfs__Debit__c) totalDebit, SUM(ssfs__Credit__c) totalCredit
              FROM ssfs__Journal_Entry__c
             WHERE ssfs__Accounting_Period__c = :accPeriodId
              WITH SYSTEM_MODE
             GROUP BY ssfs__GL_Code__c, CALENDAR_YEAR(ssfs__Date__c), CALENDAR_MONTH(ssfs__Date__c), DAY_IN_MONTH(ssfs__Date__c)
        ];
    }

    private static String getExportInformation(ExportRow row) {
        // 'NPSP240130' for 2024-01-30
        String baseString = 'NPSP';
        Datetime dt = Datetime.newInstance(row.rowDate.year(), row.rowDate.month(), row.rowDate.day());
        return baseString + dt.format('yyMMdd');
    }
/*
    private List<ssfs__Journal_Entry__c> getJournalEntries() {
        if (journalEntries == null) {
            journalEntries = [
                SELECT Id, ssfs__Amount__c, ssfs__Type__c, ssfs__GL_Code__c, ssfs__GL_Account_Name__c
                  FROM ssfs__Journal_Entry__c
                 WHERE ssfs__Accounting_Period__c = :accPeriodId
                  WITH USER_MODE
            ];
        }
        return journalEntries;
    }

    private List<ExportRow> convertJesToExportRows(
        List<ssfs__Journal_Entry__c> lstJournalEntries
    ) {
        Map<String, Decimal> mapGlNameToNetCredit = new Map<String, Decimal>();
        for (ssfs__Journal_Entry__c je : lstJournalEntries) {
            if (!mapGlNameToNetCredit.containsKey(je.ssfs__GL_Code__c)) {
                mapGlNameToNetCredit.put(je.ssfs__GL_Code__c, 0.00);
            }
            Decimal netCreditAmount = je.ssfs__Type__c == TYPE_CREDIT ? je.ssfs__Amount__c : (je.ssfs__Amount__c * -1);
            mapGlNameToNetCredit.put(
                je.ssfs__GL_Code__c, 
                (mapGlNameToNetCredit.get(je.ssfs__GL_Code__c) + netCreditAmount)
            );
        }
        List<ExportRow> lstRowsToReturn = new List<ExportRow>();
        for (String glCode : mapGlNameToNetCredit.keySet()) {
            Decimal netCreditAmount = mapGlNameToNetCredit.get(glCode);
            ExportRow row = new ExportRow();
            row.glCode = glCode;
            row.credit = netCreditAmount > 0.00 ? netCreditAmount : 0.00;
            row.debit  = netCreditAmount < 0.00 ? Math.abs(netCreditAmount) : 0.00;
            lstRowsToReturn.add(row);
        }
        return lstRowsToReturn;
    }
    */

    private static Boolean isValidId(String recordId) {
        return isAccountingPeriodId(recordId) && isValidIdLength(recordId);
    }

    private static Boolean isAccountingPeriodId(String recordId) {
        return String.valueOf(recordId).startsWith(AP_OBJ_KEY_PREFIX);
    }

    private static Boolean isValidIdLength(String recordId) {
        return (recordId.length() == 15 || recordId.length() == 18);
    }

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