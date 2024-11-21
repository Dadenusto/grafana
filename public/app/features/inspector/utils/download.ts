import saveAs from 'file-saver';
import * as XLSX from 'xlsx';

import {
  CSVConfig,
  DataFrame,
  DataTransformerID,
  dateTimeFormat,
  LogsModel,
  MutableDataFrame,
  toCSV,
} from '@grafana/data';
import { transformToOTLP } from '@grafana-plugins/tempo/resultTransformer';

import { transformToJaeger } from '../../../plugins/datasource/jaeger/responseTransform';
import { transformToZipkin } from '../../../plugins/datasource/zipkin/utils/transforms';

/**
 * Downloads a DataFrame as a TXT file.
 *
 * @param {(Pick<LogsModel, 'meta' | 'rows'>)} logsModel
 * @param {string} title
 */
export function downloadLogsModelAsTxt(logsModel: Pick<LogsModel, 'meta' | 'rows'>, title: string) {
  let textToDownload = '';

  logsModel.meta?.forEach((metaItem) => {
    const string = `${metaItem.label}: ${JSON.stringify(metaItem.value)}\n`;
    textToDownload = textToDownload + string;
  });
  textToDownload = textToDownload + '\n\n';

  logsModel.rows.forEach((row) => {
    const newRow = row.timeEpochMs + '\t' + row.entry + '\n';
    textToDownload = textToDownload + newRow;
  });

  const blob = new Blob([textToDownload], {
    type: 'text/plain;charset=utf-8',
  });

  const fileName = `${title}-logs-${dateTimeFormat(new Date())}.txt`;
  saveAs(blob, fileName);
}

/**
 * Exports a DataFrame as a CSV file.
 *
 * @param {DataFrame} dataFrame
 * @param {string} title
 * @param {CSVConfig} [csvConfig]
 * @param {DataTransformerID} [transformId=DataTransformerID.noop]
 */
export function downloadDataFrameAsCsv(
  dataFrame: DataFrame,
  title: string,
  csvConfig?: CSVConfig,
  transformId: DataTransformerID = DataTransformerID.noop
) {
  const dataFrameCsv = toCSV([dataFrame], csvConfig);
  const bomChar = csvConfig?.useExcelHeader ? String.fromCharCode(0xfeff) : '';

  const blob = new Blob([bomChar, dataFrameCsv], {
    type: 'text/csv;charset=windows-1251;',
  });

  const transformation = transformId !== DataTransformerID.noop ? '-as-' + transformId.toLocaleLowerCase() : '';
  const fileName = `${title}-data${transformation}-${dateTimeFormat(new Date())}.csv`;
  saveAs(blob, fileName);
}

/**
 * Exports a DataFrame as a XLSX file.
 *
 * @param {DataFrame} dataFrame
 * @param {string} title
 * @param {CSVConfig} [csvConfig]
 * @param {DataTransformerID} [transformId=DataTransformerID.noop]
 */
export function downloadDataFrameAsXlsx(
  dataFrame: DataFrame,
  title: string,
  csvConfig?: CSVConfig,
  transformId: DataTransformerID = DataTransformerID.noop
) {
  const dataFrameCsv = toCSV([dataFrame], csvConfig, true)
    .replaceAll('"', '')
    .replaceAll(/(?<=[0-9])( )(?=[0-9])/g, '');

  const rows = dataFrameCsv.split('\r\n').map((row, rowIndex) => {
    const columns = row.split(';');
    return columns.map((col) => {
      // Преобразуем в число, если это возможно
      const num = Number(col.replaceAll(/(?<=[0-9]),(?=[0-9])/g, '.'));
      return isNaN(num) ? String(col) : num; // Если не число, возвращаем оригинальное значение
    });
  });

  // Создаем рабочую книгу и лист
  const worksheet = XLSX.utils.aoa_to_sheet(rows);
  const workbook = XLSX.utils.book_new();

  // Добавляем лист в рабочую книгу
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');
  const transformation = transformId !== DataTransformerID.noop ? '-as-' + transformId.toLocaleLowerCase() : '';
  const fileName = `${title}-data${transformation}-${dateTimeFormat(new Date())}.xlsx`;

  // Сохраняем рабочую книгу в файл
  XLSX.writeFile(workbook, `${fileName}.xlsx`);
}

/**
 * Downloads any object as JSON file.
 *
 * @param {unknown} json
 * @param {string} title
 */
export function downloadAsJson(json: unknown, title: string) {
  const blob = new Blob([JSON.stringify(json)], {
    type: 'application/json',
  });

  const fileName = `${title}-${dateTimeFormat(new Date())}.json`;
  saveAs(blob, fileName);
}

/**
 * Downloads a trace as json, based on the DataFrame format or OTLP as a default
 *
 * @param {DataFrame} frame
 * @param {string} title
 */
export function downloadTraceAsJson(frame: DataFrame, title: string): string {
  let traceFormat = 'otlp';
  switch (frame.meta?.custom?.traceFormat) {
    case 'jaeger': {
      let res = transformToJaeger(new MutableDataFrame(frame));
      downloadAsJson(res, title);
      traceFormat = 'jaeger';
      break;
    }
    case 'zipkin': {
      let res = transformToZipkin(new MutableDataFrame(frame));
      downloadAsJson(res, title);
      traceFormat = 'zipkin';
      break;
    }
    case 'otlp':
    default: {
      let res = transformToOTLP(new MutableDataFrame(frame));
      downloadAsJson(res, title);
      break;
    }
  }
  return traceFormat;
}
