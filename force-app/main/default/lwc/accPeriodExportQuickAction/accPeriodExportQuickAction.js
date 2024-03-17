import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { exportCSVFile } from 'c/fileExportUtils';
import getExportRows from '@salesforce/apex/AccPeriodExportController.getExportRows';
import NAME_FIELD from "@salesforce/schema/ssfs__Accounting_Period__c.Name";

/**
 * LWC for exporting accounting period data as a CSV file.
 * This component is designed to be used as a Quick Action, allowing users to export
 * summarized journal entry data related to a specific accounting period.
 */
export default class AccPeriodExportQuickAction extends LightningElement {
    @api recordId;
    exportRows = [];

    // Column headers for the CSV file
    columnHeaders = {
        rowDate: 'Effective Date',
        glCode: 'GL Code',
        debit: 'Debit', 
        credit: 'Credit',
        exportInformation: 'Export Information',
    }

    // Fetch the Accounting Period record to use its name in the export file name.
    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD] })
    accountingPeriod;

    get accountingPeriodName() {
        return getFieldValue(this.accountingPeriod.data, NAME_FIELD);
    }

    get exportFileName() {
        return `${this.accountingPeriodName} Export`;
    }

    isExecuting = false;

    /**
     * The invoke method is called by the Quick Action framework.
     * It initiates the data fetch and handles the export process.
     */
    @api invoke() {
        if (this.isExecuting) {
            return;
        }
        this.isExecuting = true;

        getExportRows({ accPeriodId: this.recordId })
            .then(result => {
                this.exportRows = result;
                this.handleExport();
            })
            .catch(error => {
                this.showError(error);
            })
            .finally(() => {
                this.isExecuting = false;
            });
    }

    /**
     * Initiates the CSV file export using the fetched data.
     */
    handleExport() {
        exportCSVFile(this.columnHeaders, this.exportRows, this.exportFileName);
    }

    /**
     * Utility method to display errors to the user.
     * @param {Error} error - The error to display.
     */
    showError(error) {
        console.error(error);
        // TODO user-friendly error handling here
    }

}