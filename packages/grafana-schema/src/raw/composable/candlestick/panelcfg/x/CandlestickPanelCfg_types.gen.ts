// Code generated - EDITING IS FUTILE. DO NOT EDIT.
//
// Generated by:
//     public/app/plugins/gen.go
// Using jennies:
//     TSTypesJenny
//     PluginTsTypesJenny
//
// Run 'make gen-cue' from repository root to regenerate.

import * as common from '@grafana/schema';

export const pluginVersion = "11.0.6";

export enum VizDisplayMode {
  Candles = 'candles',
  CandlesVolume = 'candles+volume',
  Volume = 'volume',
}

export enum CandleStyle {
  Candles = 'candles',
  OHLCBars = 'ohlcbars',
}

export enum ColorStrategy {
  CloseClose = 'close-close',
  OpenClose = 'open-close',
}

export interface CandlestickFieldMap {
  /**
   * Corresponds to the final (end) value of the given period
   */
  close?: string;
  /**
   * Corresponds to the highest value of the given period
   */
  high?: string;
  /**
   * Corresponds to the lowest value of the given period
   */
  low?: string;
  /**
   * Corresponds to the starting value of the given period
   */
  open?: string;
  /**
   * Corresponds to the sample count in the given period. (e.g. number of trades)
   */
  volume?: string;
}

export interface CandlestickColors {
  down: string;
  flat: string;
  up: string;
}

export const defaultCandlestickColors: Partial<CandlestickColors> = {
  down: 'red',
  flat: 'gray',
  up: 'green',
};

export interface Options extends common.OptionsWithLegend, common.OptionsWithTooltip {
  /**
   * Sets the style of the candlesticks
   */
  candleStyle: CandleStyle;
  /**
   * Sets the color strategy for the candlesticks
   */
  colorStrategy: ColorStrategy;
  /**
   * Set which colors are used when the price movement is up or down
   */
  colors: CandlestickColors;
  /**
   * Map fields to appropriate dimension
   */
  fields: CandlestickFieldMap;
  /**
   * When enabled, all fields will be sent to the graph
   */
  includeAllFields?: boolean;
  /**
   * Sets which dimensions are used for the visualization
   */
  mode: VizDisplayMode;
}

export const defaultOptions: Partial<Options> = {
  candleStyle: CandleStyle.Candles,
  colorStrategy: ColorStrategy.OpenClose,
  colors: {
    down: 'red',
    up: 'green',
    flat: 'gray',
  },
  fields: {},
  includeAllFields: false,
  mode: VizDisplayMode.CandlesVolume,
};

export interface FieldConfig extends common.GraphFieldConfig {}
