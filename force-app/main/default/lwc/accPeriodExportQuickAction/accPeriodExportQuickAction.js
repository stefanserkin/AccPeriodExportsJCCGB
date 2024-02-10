import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { exportCSVFile } from 'c/fileExportUtils';
import getExportRows from '@salesforce/apex/AccPeriodExportController.getExportRows';
import NAME_FIELD from "@salesforce/schema/ssfs__Accounting_Period__c.Name";

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

    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD] })
    accountingPeriod;

    get accountingPeriodName() {
        return getFieldValue(this.accountingPeriod.data, NAME_FIELD);
    }

    @api invoke() {
        if (this.isExecuting) {
            return;
        }
        this.isExecuting = true;

        getExportRows({accPeriodId: this.recordId})
            .then(result => {
                this.exportRows = result;
                this.handleExport();
            })
            .catch(error => {
                console.error(error);
            });
    }

    handleExport() {
        exportCSVFile(this.columnHeaders, this.exportRows, this.exportFileName);
    }

    get exportFileName() {
        return `${this.accountingPeriodName} Export`;
    }

}