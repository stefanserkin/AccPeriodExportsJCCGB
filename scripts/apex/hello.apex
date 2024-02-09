// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

String accPeriodId = 'a0tHo000007smPMIAY';
List<AggregateResult> results = [
    SELECT ssfs__GL_Code__c, CALENDAR_YEAR(ssfs__Date__c) year, CALENDAR_MONTH(ssfs__Date__c) month, DAY_IN_MONTH(ssfs__Date__c) day, 
            SUM(ssfs__Debit__c) totalDebit, SUM(ssfs__Credit__c) totalCredit
        FROM ssfs__Journal_Entry__c
        WHERE ssfs__Accounting_Period__c = :accPeriodId
        WITH SYSTEM_MODE
        GROUP BY ssfs__GL_Code__c, CALENDAR_YEAR(ssfs__Date__c), CALENDAR_MONTH(ssfs__Date__c), DAY_IN_MONTH(ssfs__Date__c)
];
List<ExportRow> exportRows = new List<ExportRow>();

for (AggregateResult ar : results) {
    ExportRow row = new ExportRow();
    row.rowDate = Date.newInstance((Integer)ar.get('year'), (Integer)ar.get('month'), (Integer)ar.get('day'));
    row.glCode = (String)ar.get('ssfs__GL_Code__c');
    Decimal totalDebit = (Decimal)ar.get('totalDebit');
    Decimal totalCredit = (Decimal)ar.get('totalCredit');
    Decimal netAmount = totalCredit - totalDebit;
    if (netAmount > )

    System.debug(row);
    exportRows.add(row);
}