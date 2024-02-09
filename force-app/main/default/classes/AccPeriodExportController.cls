public with sharing class AccPeriodExportController {
    
    @AuraEnabled(cacheable=true)
    public static List<AccPeriodExportService.ExportRow> getExportRows(
        Id accPeriodId
    ) {
        try {
            AccPeriodExportService serv = new AccPeriodExportService(accPeriodId);
            return serv.getExportRows();
        } catch (AccPeriodExportService.AccPeriodExportException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}