/**
 * Exports JSON data to a CSV file.
 * 
 * @param {Object} headers - The CSV headers with object keys as properties and display names as values.
 * @param {Array} totalData - The array of objects to be converted to CSV.
 * @param {string} fileTitle - The title for the generated file. If not provided, defaults to 'export.csv'.
 * @returns {null|undefined} - Returns early if no data is provided.
 */
export function exportCSVFile(headers, totalData, fileTitle) {
    // Check if there's data to export, return if not
    if (!totalData || !totalData.length) {
        return null;
    }

    // Convert the data to a JSON string
    const jsonObject = JSON.stringify(totalData);

    // Convert JSON to CSV format
    const result = convertToCSV(jsonObject, headers);
    // Return if conversion fails
    if (result === null) return;

    // Create a Blob with the CSV data
    const blob = new Blob([result]);

    // Set the exported file name
    const exportedFilename = fileTitle ? fileTitle + '.csv' : 'export.csv';

    // Use msSaveBlob for IE11 and Edge
    if (navigator.msSaveBlob) {
        navigator.msSaveBlob(blob, exportedFilename);
    } else {
        // Create a link for other browsers
        const link = window.document.createElement('a');
        link.href = 'data:text/csv;charset=utf-8,' + encodeURI(result);
        link.target = "_blank";
        link.download = exportedFilename;

        // Programmatically click the link to trigger the download
        link.click();
    }
}

/**
 * Converts an array of objects to a CSV string.
 * 
 * @param {string|Object} objArray - The JSON object array or string to convert.
 * @param {Object} headers - The object mapping keys in the objects to column headers.
 * @returns {string} - The CSV string.
 */
function convertToCSV(objArray, headers) {
    const columnDelimiter = ',';
    const lineDelimiter = '\r\n';

    // Extract the actual keys to use from the headers object
    const actualHeaderKey = Object.keys(headers);
    // Extract the display names for the CSV header
    const headerToShow = Object.values(headers);

    // Initialize the CSV string and add the header row
    let str = '';
    str += headerToShow.join(columnDelimiter);
    str += lineDelimiter;

    // Parse objArray if it's a JSON string, otherwise use it directly
    const data = typeof objArray !== 'object' ? JSON.parse(objArray) : objArray;

    // Add each row to the CSV string
    data.forEach(obj => {
        let line = '';
        actualHeaderKey.forEach(key => {
            if(line != '') {
                line += columnDelimiter;
            }
            // Convert the item to string and remove commas to prevent breaking the CSV format
            let strItem = obj[key] + '';
            line += strItem ? strItem.replace(/,/g, '') : strItem;
        })
        // Add the completed line to the CSV string
        str += line + lineDelimiter;
    });
    
    return str;
}