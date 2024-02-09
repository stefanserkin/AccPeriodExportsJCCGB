import { LightningElement, api, track, wire } from 'lwc';
import getExportRows from '@salesforce/apex/AccPeriodExportController.getExportRows';

const COLS = ['GL Code','Debit', 'Credit'];

export default class AccPeriodExporter extends LightningElement {
    @api recordId;
    isLoading = false;
    isExecuting = false;
    error;
    columnHeaders = COLS;
    @track exportRows;
    wiredExportRows = [];

    @api invoke() {
        console.log("Hi, I'm an action.");
        if (this.isExecuting) {
            return;
        }

        this.isExecuting = true;


    }

    @wire(getExportRows, {accPeriodId: '$recordId'})
    wiredData(result) {
        this.isLoading = true;
        this.wiredExportRows = result;
        if (result.data) {
            console.table(result.data);
            this.exportRows = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.exportRows = undefined;
            this.error = result.error;
            console.error(this.error);
        }
    }

    handleExport() {
        console.log('preparing export...');

        // Prepare a html table
        let doc = '<table>';
        // Add styles for the table
        doc += '<style>';
        doc += 'table, th, td {';
        doc += '    border: 1px solid black;';
        doc += '    border-collapse: collapse;';
        doc += '}';          
        doc += '</style>';
        // Add all the Table Headers
        doc += '<tr>';
        this.columnHeaders.forEach(element => {            
            doc += '<th>'+ element +'</th>'           
        });
        doc += '</tr>';
        // Add the data rows
        this.exportRows.forEach(record => {
            doc += '<tr>';
            doc += '<th>'+record.glCode+'</th>'; 
            doc += '<th>'+record.debit+'</th>';
            doc += '<th>'+record.credit+'</th>'; 
            doc += '</tr>';
        });
        doc += '</table>';
        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Accounting Period Export.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }

}