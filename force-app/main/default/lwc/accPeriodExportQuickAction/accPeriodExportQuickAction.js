import { LightningElement, api } from 'lwc';
import { exportCSVFile } from 'c/fileExportUtils';
import getExportRows from '@salesforce/apex/AccPeriodExportController.getExportRows';

export default class AccPeriodExportQuickAction extends LightningElement {
    @api recordId;
    exportRows = [];

    columnHeaders = {
        rowDate: 'Effective Datetime',
        glCode: 'GL Code',
        debit: 'Debit', 
        credit: 'Credit',
        exportInformation: 'Export Information',
    }

    @api invoke() {
        if (this.isExecuting) {
            return;
        }

        this.isExecuting = true;
        console.log('::::: recordId --> ', this.recordId);

        getExportRows({accPeriodId: this.recordId})
            .then(result => {
                console.table(result);
                this.exportRows = result;
                this.handleExport();
            })
            .catch(error => {
                console.error(error);
            });
    }

    handleExport() {
        console.log('preparing export...');
        exportCSVFile(this.columnHeaders, this.exportRows, 'Accounting Period Export');
    }

}