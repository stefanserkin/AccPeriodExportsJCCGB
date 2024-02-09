export function exportCSVFile(headers, totalData, fileTitle) {
    if (!totalData || !totalData.length) {
        return null;
    }
    const jsonObject = JSON.stringify(totalData);
    const result = convertToCSV(jsonObject, headers);
    if (result === null) return;
    const blob = new Blob([result]);
    const exportedFilename = fileTitle ? fileTitle+'.csv' :'export.csv';
    if (navigator.msSaveBlob) {
        console.log('is ms save blob');
        navigator.msSaveBlob(blob, exportedFilename);
    } else {
        const link = window.document.createElement('a');
        link.href = 'data:text/csv;charset=utf-8,' + encodeURI(result);
        link.target = "_blank";
        link.download = exportedFilename;
        link.click();
    }
}

function convertToCSV(objArray, headers) {
    const columnDelimiter = ',';
    const lineDelimiter = '\r\n';
    const actualHeaderKey = Object.keys(headers);
    const headerToShow = Object.values(headers);
    let str = '';
    str += headerToShow.join(columnDelimiter);
    str += lineDelimiter;
    const data = typeof objArray !== 'object' ? JSON.parse(objArray) : objArray;

    data.forEach(obj => {
        let line = '';
        actualHeaderKey.forEach(key => {
            if(line != '') {
                line += columnDelimiter;
            }
            let strItem = obj[key] + '';
            line += strItem ? strItem.replace(/,/g, '') : strItem;
        })
        str += line + lineDelimiter;
    });
    console.log("str", str);
    return str;
}