@IsTest
private class AccPeriodExportController_Test {

    private static final Decimal JE_AMOUNT = 100.00;

    @TestSetup
    static void makeData() {
        // 1 open accounting period
        ssfs__Accounting_Period__c ap = new ssfs__Accounting_Period__c(
            Name = 'Test Open Accounting Period', 
            ssfs__Start_Date__c = Date.today(),
            ssfs__End_Date__c = Date.today(),
            ssfs__Status__c = 'Open'
        );
        insert ap;

        // 2 GAUs
        List<npsp__General_Accounting_Unit__c> lstGAUs = new List<npsp__General_Accounting_Unit__c>();
        for (Integer i = 0; i < 5; i++) {
            String name = 'Test GAU ' + String.valueOf(i);
            lstGAUs.add(
                new npsp__General_Accounting_Unit__c(
                    Name = name,
                    ssfs__GL_Code__c = String.valueOf(Math.random() * 12),
                    npsp__Active__c = true
                )
            );
        }
        insert lstGAUs;

        // 1 pair of journal entries
        List<ssfs__Journal_Entry__c> lstJEs = new List<ssfs__Journal_Entry__c>();
        Date jeDate = Date.today();
        String postingStatus = 'Entered';
        String jeNotes = 'Manual adjustment';

        // Debit entry
        ssfs__Journal_Entry__c jeDebit = new ssfs__Journal_Entry__c();
        jeDebit.ssfs__Accounting_Period__c = ap.Id;
        jeDebit.ssfs__Manual_Adjustment__c = true;
        jeDebit.ssfs__Type__c = 'Debit';
        jeDebit.ssfs__Amount__c = JE_AMOUNT;
        jeDebit.ssfs__Date__c = jeDate;
        jeDebit.ssfs__GL_Account_Name__c = lstGAUs[0].Name;
        jeDebit.ssfs__GL_Code__c = lstGAUs[0].ssfs__GL_Code__c;
        jeDebit.ssfs__Posting_Status__c = postingStatus;
        jeDebit.ssfs__General_Accounting_Unit__c = lstGAUs[0].Id;
        jeDebit.ssfs__Notes__c = jeNotes;
        lstJEs.add(jeDebit);

        // Credit entry
        ssfs__Journal_Entry__c jeCredit = new ssfs__Journal_Entry__c();
        jeCredit.ssfs__Accounting_Period__c = ap.Id;
        jeCredit.ssfs__Manual_Adjustment__c = true;
        jeCredit.ssfs__Type__c = 'Credit';
        jeCredit.ssfs__Amount__c = JE_AMOUNT;
        jeCredit.ssfs__Date__c = jeDate;
        jeCredit.ssfs__GL_Account_Name__c = lstGAUs[1].Name;
        jeCredit.ssfs__GL_Code__c = lstGAUs[1].ssfs__GL_Code__c;
        jeCredit.ssfs__Posting_Status__c = postingStatus;
        jeCredit.ssfs__General_Accounting_Unit__c = lstGAUs[1].Id;
        jeCredit.ssfs__Notes__c = jeNotes;
        lstJEs.add(jeCredit);

        insert lstJEs;
    }
    
    @IsTest
    static void testGetExportRows() {
        ssfs__Accounting_Period__c ap = [SELECT Id FROM ssfs__Accounting_Period__c LIMIT 1];
        List<AccPeriodExportService.ExportRow> lstExportRows;
        Test.startTest();
        lstExportRows = AccPeriodExportController.getExportRows(ap.Id);
        Test.stopTest();
        Assert.areEqual(2, lstExportRows.size(), 'Should have received an export row for both gl codes');
        // Get absolute value of first export row
        Decimal absValue = Math.abs(lstExportRows[0].credit - lstExportRows[0].debit);
        Assert.areEqual(JE_AMOUNT, absValue, 'Should have received the original je amount');
    }

    @IsTest
    static void testGetExportRowsWithException() {
        String badId = '123';
        Boolean hasException = false;
        List<AccPeriodExportService.ExportRow> lstExportRows;
        Test.startTest();
        try {
            lstExportRows = AccPeriodExportController.getExportRows(badId);
        } catch (Exception e) {
            hasException = true;
        }
        Test.stopTest();
        Assert.isTrue(hasException, 'Should have received an exception for querying with an invalid record id');
    }

}