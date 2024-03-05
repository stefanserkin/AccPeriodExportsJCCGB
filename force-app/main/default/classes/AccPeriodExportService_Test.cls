@IsTest
private class AccPeriodExportService_Test {

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

        // 5 GAUs
        List<npsp__General_Accounting_Unit__c> lstGAUs = new List<npsp__General_Accounting_Unit__c>();
        for (Integer i = 0; i < 5; i++) {
            String gauName = 'Test GAU ' + String.valueOf(i);
            lstGAUs.add(
                new npsp__General_Accounting_Unit__c(
                    Name = gauName,
                    JCC_GL_Name__c = gauName,
                    ssfs__GL_Code__c = String.valueOf(Math.random() * 12),
                    npsp__Active__c = true
                )
            );
        }
        insert lstGAUs;

        // 10 pairs of journal entries
        List<ssfs__Journal_Entry__c> lstJEs = new List<ssfs__Journal_Entry__c>();
        Integer debitIndex = 0;
        Integer creditIndex = 1;
        for (Integer i = 0; i < 10; i++) {
            Decimal jeAmount = 100 * (i+1); // Create varying amounts
            Date jeDate = Date.today();
            String postingStatus = 'Entered';
            String jeNotes = 'Manual adjustment';

            // Debit entry
            ssfs__Journal_Entry__c jeDebit = new ssfs__Journal_Entry__c();
            jeDebit.ssfs__Accounting_Period__c = ap.Id;
            jeDebit.ssfs__Manual_Adjustment__c = true;
            jeDebit.ssfs__Type__c = 'Debit';
            jeDebit.ssfs__Amount__c = jeAmount;
            jeDebit.ssfs__Date__c = jeDate;
            jeDebit.ssfs__GL_Account_Name__c = lstGAUs[debitIndex].Name;
            jeDebit.ssfs__GL_Code__c = lstGAUs[debitIndex].ssfs__GL_Code__c;
            jeDebit.ssfs__Posting_Status__c = postingStatus;
            jeDebit.ssfs__General_Accounting_Unit__c = lstGAUs[debitIndex].Id;
            jeDebit.ssfs__Notes__c = jeNotes;
            lstJEs.add(jeDebit);

            // Credit entry
            ssfs__Journal_Entry__c jeCredit = new ssfs__Journal_Entry__c();
            jeCredit.ssfs__Accounting_Period__c = ap.Id;
            jeCredit.ssfs__Manual_Adjustment__c = true;
            jeCredit.ssfs__Type__c = 'Credit';
            jeCredit.ssfs__Amount__c = jeAmount;
            jeCredit.ssfs__Date__c = jeDate;
            jeCredit.ssfs__GL_Account_Name__c = lstGAUs[creditIndex].Name;
            jeCredit.ssfs__GL_Code__c = lstGAUs[creditIndex].ssfs__GL_Code__c;
            jeCredit.ssfs__Posting_Status__c = postingStatus;
            jeCredit.ssfs__General_Accounting_Unit__c = lstGAUs[creditIndex].Id;
            jeCredit.ssfs__Notes__c = jeNotes;
            lstJEs.add(jeCredit);

            // Increment indexes to cycle through gl codes
            debitIndex = debitIndex == 4 ? 0 : debitIndex++;
            creditIndex = creditIndex == 4 ? 0 : creditIndex++;
        }
        insert lstJEs;
    }

    @IsTest
    static void testGetExportRows() {
        // Get the open accounting period
        ssfs__Accounting_Period__c ap = [SELECT Id FROM ssfs__Accounting_Period__c LIMIT 1];
        Test.startTest();
        AccPeriodExportService serv = new AccPeriodExportService(ap.Id);
        List<AccPeriodExportService.ExportRow> lstExportRows = serv.getExportRows();
        Test.stopTest();

        List<ssfs__Journal_Entry__c> lstJes = [
            SELECT ssfs__Amount__c, ssfs__Type__c 
              FROM ssfs__Journal_Entry__c 
             WHERE ssfs__Accounting_Period__c = :ap.Id
               AND ssfs__GL_Code__c = :lstExportRows[0].glCode
        ];

        Decimal expectedDebitAmount = 0.00;
        Decimal expectedCreditAmount = 0.00;
        for (ssfs__Journal_Entry__c je : lstJes) {
            if (je.ssfs__Type__c == 'Debit') {
                expectedDebitAmount += je.ssfs__Amount__c;
            } else if (je.ssfs__Type__c == 'Credit') {
                expectedCreditAmount += je.ssfs__Amount__c;
            }
        }
        
        Assert.areEqual(
            expectedDebitAmount, 
            lstExportRows[0].debit, 
            'Received incorrect net debit amount for journal entries for the first gl code'
        );
        Assert.areEqual(
            expectedCreditAmount, 
            lstExportRows[0].credit, 
            'Received incorrect net credit amount for journal entries for the first gl code'
        );
    }

}