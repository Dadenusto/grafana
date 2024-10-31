DashboardV2: {
  kind: "Dashboard"
  spec: DashboardSpec
}

DashboardSpec: {
  // Unique numeric identifier for the dashboard.
  // `id` is internal to a specific Grafana instance. `uid` should be used to identify a dashboard across Grafana instances.
  id?: int64

  // Title of dashboard.
  title?: string

  // Description of dashboard.
  description?: string

  // Configuration of dashboard cursor sync behavior.
  // Accepted values are 0 (sync turned off), 1 (shared crosshair), 2 (shared crosshair and tooltip).
  cursorSync?: DashboardCursorSync

  // When set to true, the dashboard will redraw panels at an interval matching the pixel width.
  // This will keep data "moving left" regardless of the query refresh rate. This setting helps
  // avoid dashboards presenting stale live data.
  liveNow?: bool

  // When set to true, the dashboard will load all panels in the dashboard when it's loaded.
  preload: bool

  // Whether a dashboard is editable or not.
  editable?: bool | *true

  // Links with references to other dashboards or external websites.
  links: [...DashboardLink]

  // Tags associated with dashboard.
  tags?: [...string]

  timeSettings: TimeSettingsSpec

  // Configured template variables.
  variables: [...QueryVariableKind | TextVariableKind]

  elements: [ElementReferenceKind.spec.id]: PanelKind // |* more element types in the future

  annotations: [...AnnotationQueryKind]

  layout: GridLayoutKind

  // version: will rely on k8s resource versioning, via metadata.resorceVersion

  // revision?: int // for plugins only
  // gnetId?: string // ??? Wat is this used for?
}


AnnotationPanelFilter: {
  // Should the specified panels be included or excluded
  exclude?: bool | *false

  // Panel IDs that should be included or excluded
  ids: [...uint8]
}

// 0 for no shared crosshair or tooltip (default).
// 1 for shared crosshair.
// 2 for shared crosshair AND shared tooltip.
// memberNames="Off|Crosshair|Tooltip"
DashboardCursorSync: *0 | 1 | 2 @cog(kind="enum",memberNames="Off|Crosshair|Tooltip")

// Links with references to other dashboards or external resources
DashboardLink: {
  // Title to display with the link
  title: string
  // Link type. Accepted values are dashboards (to refer to another dashboard) and link (to refer to an external resource)
  type: DashboardLinkType
  // Icon name to be displayed with the link
  icon: string
  // Tooltip to display when the user hovers their mouse over it
  tooltip: string
  // Link URL. Only required/valid if the type is link
  url?: string
  // List of tags to limit the linked dashboards. If empty, all dashboards will be displayed. Only valid if the type is dashboards
  tags: [...string]
  // If true, all dashboards links will be displayed in a dropdown. If false, all dashboards links will be displayed side by side. Only valid if the type is dashboards
  asDropdown: bool | *false
  // If true, the link will be opened in a new tab
  targetBlank: bool | *false
  // If true, includes current template variables values in the link as query params
  includeVars: bool | *false
  // If true, includes current time range in the link as query params
  keepTime: bool | *false
}

DataSourceRef: {
  // The plugin type-id
  type?: string

  // Specific datasource instance
  uid?: string
}

// Transformations allow to manipulate data returned by a query before the system applies a visualization.
// Using transformations you can: rename fields, join time series data, perform mathematical operations across queries,
// use the output of one transformation as the input to another transformation, etc.
DataTransformerConfig: {
  // Unique identifier of transformer
  id: string
  // Disabled transformations are skipped
  disabled?: bool
  // Optional frame matcher. When missing it will be applied to all results
  filter?: MatcherConfig
  // Where to pull DataFrames from as input to transformation
  topic?: "series" | "annotations" | "alertStates" // replaced with common.DataTopic
  // Options to be passed to the transformer
  // Valid options depend on the transformer id
  options: _
}

// The data model used in Grafana, namely the data frame, is a columnar-oriented table structure that unifies both time series and table query results.
// Each column within this structure is called a field. A field can represent a single time series or table column.
// Field options allow you to change how the data is displayed in your visualizations.
FieldConfigSource: {
  // Defaults are the options applied to all fields.
  defaults: FieldConfig
  // Overrides are the options applied to specific fields overriding the defaults.
  overrides: [...{
    matcher: MatcherConfig
    properties: [...DynamicConfigValue]
  }]
}

// The data model used in Grafana, namely the data frame, is a columnar-oriented table structure that unifies both time series and table query results.
// Each column within this structure is called a field. A field can represent a single time series or table column.
// Field options allow you to change how the data is displayed in your visualizations.
FieldConfig: {
  // The display value for this field.  This supports template variables blank is auto
  displayName?: string

  // This can be used by data sources that return and explicit naming structure for values and labels
  // When this property is configured, this value is used rather than the default naming strategy.
  displayNameFromDS?: string

  // Human readable field metadata
  description?: string

  // An explicit path to the field in the datasource.  When the frame meta includes a path,
  // This will default to `${frame.meta.path}/${field.name}
  //
  // When defined, this value can be used as an identifier within the datasource scope, and
  // may be used to update the results
  path?: string

  // True if data source can write a value to the path. Auth/authz are supported separately
  writeable?: bool

  // True if data source field supports ad-hoc filters
  filterable?: bool

  // Unit a field should use. The unit you select is applied to all fields except time.
  // You can use the units ID availables in Grafana or a custom unit.
  // Available units in Grafana: https://github.com/grafana/grafana/blob/main/packages/grafana-data/src/valueFormats/categories.ts
  // As custom unit, you can use the following formats:
  // `suffix:<suffix>` for custom unit that should go after value.
  // `prefix:<prefix>` for custom unit that should go before value.
  // `time:<format>` For custom date time formats type for example `time:YYYY-MM-DD`.
  // `si:<base scale><unit characters>` for custom SI units. For example: `si: mF`. This one is a bit more advanced as you can specify both a unit and the source data scale. So if your source data is represented as milli (thousands of) something prefix the unit with that SI scale character.
  // `count:<unit>` for a custom count unit.
  // `currency:<unit>` for custom a currency unit.
  unit?: string

  // Specify the number of decimals Grafana includes in the rendered value.
  // If you leave this field blank, Grafana automatically truncates the number of decimals based on the value.
  // For example 1.1234 will display as 1.12 and 100.456 will display as 100.
  // To display all decimals, set the unit to `String`.
  decimals?: number

  // The minimum value used in percentage threshold calculations. Leave blank for auto calculation based on all series and fields.
  min?: number
  // The maximum value used in percentage threshold calculations. Leave blank for auto calculation based on all series and fields.
  max?: number

  // Convert input values into a display string
  mappings?: [...ValueMapping]

  // Map numeric values to states
  thresholds?: ThresholdsConfig

  // Panel color configuration
  color?: FieldColor

  // The behavior when clicking on a result
  links?: [...]

  // Alternative to empty string
  noValue?: string

  // custom is specified by the FieldConfig field
  // in panel plugin schemas.
  custom?: {...}
}

DynamicConfigValue: {
  id: string | *""
  value?: _
}

// Matcher is a predicate configuration. Based on the config a set of field(s) or values is filtered in order to apply override / transformation.
// It comes with in id ( to resolve implementation from registry) and a configuration that’s specific to a particular matcher type.
MatcherConfig: {
  // The matcher id. This is used to find the matcher implementation from registry.
  id: string | *""
  // The matcher options. This is specific to the matcher implementation.
  options?: _
}

Threshold: {
  value: number | null
  color: string
}

ThresholdsMode: "absolute" | "percentage"

ThresholdsConfig: {
  mode: ThresholdsMode
  steps: [...Threshold]
}

ValueMapping: ValueMap | RangeMap | RegexMap | SpecialValueMap

// Supported value mapping types
// `value`: Maps text values to a color or different display text and color. For example, you can configure a value mapping so that all instances of the value 10 appear as Perfection! rather than the number.
// `range`: Maps numerical ranges to a display text and color. For example, if a value is within a certain range, you can configure a range value mapping to display Low or High rather than the number.
// `regex`: Maps regular expressions to replacement text and a color. For example, if a value is www.example.com, you can configure a regex value mapping so that Grafana displays www and truncates the domain.
// `special`: Maps special values like Null, NaN (not a number), and boolean values like true and false to a display text and color. See SpecialValueMatch to see the list of special values. For example, you can configure a special value mapping so that null values appear as N/A.
MappingType: "value" | "range" | "regex" | "special"

// Maps text values to a color or different display text and color.
// For example, you can configure a value mapping so that all instances of the value 10 appear as Perfection! rather than the number.
ValueMap: {
  type: MappingType & "value"
  // Map with <value_to_match>: ValueMappingResult. For example: { "10": { text: "Perfection!", color: "green" } }
  options: [string]: ValueMappingResult
}

// Maps numerical ranges to a display text and color.
// For example, if a value is within a certain range, you can configure a range value mapping to display Low or High rather than the number.
RangeMap: {
  type: MappingType & "range"
  // Range to match against and the result to apply when the value is within the range
  options: {
    // Min value of the range. It can be null which means -Infinity
    from: float64 | null
    // Max value of the range. It can be null which means +Infinity
    to: float64 | null
    // Config to apply when the value is within the range
    result: ValueMappingResult
  }
}

// Maps regular expressions to replacement text and a color.
// For example, if a value is www.example.com, you can configure a regex value mapping so that Grafana displays www and truncates the domain.
RegexMap: {
  type: MappingType & "regex"
  // Regular expression to match against and the result to apply when the value matches the regex
  options: {
    // Regular expression to match against
    pattern: string
    // Config to apply when the value matches the regex
    result: ValueMappingResult
  }
}

// Maps special values like Null, NaN (not a number), and boolean values like true and false to a display text and color.
// See SpecialValueMatch to see the list of special values.
// For example, you can configure a special value mapping so that null values appear as N/A.
SpecialValueMap: {
  type: MappingType & "special"
  options: {
    // Special value to match against
    match: SpecialValueMatch
    // Config to apply when the value matches the special value
    result: ValueMappingResult
  }
}

// Special value types supported by the `SpecialValueMap`
SpecialValueMatch: "true" | "false" | "null" | "nan" | "null+nan" | "empty"

// Result used as replacement with text and color when the value matches
ValueMappingResult: {
  // Text to display when the value matches
  text?: string
  // Text to use when the value matches
  color?: string
  // Icon to display when the value matches. Only specific visualizations.
  icon?: string
  // Position in the mapping array. Only used internally.
  index?: int32
}

// Color mode for a field. You can specify a single color, or select a continuous (gradient) color schemes, based on a value.
// Continuous color interpolates a color using the percentage of a value relative to min and max.
// Accepted values are:
// `thresholds`: From thresholds. Informs Grafana to take the color from the matching threshold
// `palette-classic`: Classic palette. Grafana will assign color by looking up a color in a palette by series index. Useful for Graphs and pie charts and other categorical data visualizations
// `palette-classic-by-name`: Classic palette (by name). Grafana will assign color by looking up a color in a palette by series name. Useful for Graphs and pie charts and other categorical data visualizations
// `continuous-GrYlRd`: ontinuous Green-Yellow-Red palette mode
// `continuous-RdYlGr`: Continuous Red-Yellow-Green palette mode
// `continuous-BlYlRd`: Continuous Blue-Yellow-Red palette mode
// `continuous-YlRd`: Continuous Yellow-Red palette mode
// `continuous-BlPu`: Continuous Blue-Purple palette mode
// `continuous-YlBl`: Continuous Yellow-Blue palette mode
// `continuous-blues`: Continuous Blue palette mode
// `continuous-reds`: Continuous Red palette mode
// `continuous-greens`: Continuous Green palette mode
// `continuous-purples`: Continuous Purple palette mode
// `shades`: Shades of a single color. Specify a single color, useful in an override rule.
// `fixed`: Fixed color mode. Specify a single color, useful in an override rule.
FieldColorModeId: "thresholds" | "palette-classic" | "palette-classic-by-name" | "continuous-GrYlRd" | "continuous-RdYlGr" | "continuous-BlYlRd" | "continuous-YlRd" | "continuous-BlPu" | "continuous-YlBl" | "continuous-blues" | "continuous-reds" | "continuous-greens" | "continuous-purples" | "fixed" | "shades" @cuetsy(kind="enum",memberNames="Thresholds|PaletteClassic|PaletteClassicByName|ContinuousGrYlRd|ContinuousRdYlGr|ContinuousBlYlRd|ContinuousYlRd|ContinuousBlPu|ContinuousYlBl|ContinuousBlues|ContinuousReds|ContinuousGreens|ContinuousPurples|Fixed|Shades")

// Defines how to assign a series color from "by value" color schemes. For example for an aggregated data points like a timeseries, the color can be assigned by the min, max or last value.
FieldColorSeriesByMode: "min" | "max" | "last"

// Map a field to a color.
FieldColor: {
    // The main color scheme mode.
    mode: FieldColorModeId
    // The fixed color value for fixed or shades color modes.
    fixedColor?: string
    // Some visualizations need to know how to assign a series color from by value color schemes.
    seriesBy?: FieldColorSeriesByMode
}

// Dashboard Link type. Accepted values are dashboards (to refer to another dashboard) and link (to refer to an external resource)
DashboardLinkType: "link" | "dashboards"

// --- Common types ---
Kind: {
    kind: string,
    spec: _
    metadata?: _
}

// --- Kinds ---
VizConfigSpec: {
  pluginVersion: string
  options: [string]: _
  fieldConfig: FieldConfigSource
}

VizConfigKind: {
  kind: string
  spec: VizConfigSpec
}

AnnotationQuerySpec: {
  datasource: DataSourceRef
  query: DataQueryKind

  // TODO: Should be figured out based on datasource (Grafana ds)
  // builtIn?: int
  // Below are currently existing options for annotation queries
  enable: bool
  filter: AnnotationPanelFilter
  hide: bool
  iconColor: string
  name: string
}

AnnotationQueryKind: {
  kind: "AnnotationQuery"
  spec: AnnotationQuerySpec
}

QueryOptionsSpec: {
  timeFrom?: string
  maxDataPoints?: int
  timeShift?: string
  queryCachingTTL?: int
  interval?: string
  cacheTimeout?: string
}

DataQueryKind: {
  kind: string
  spec: [string]: _
}

PanelQuerySpec: {
  query: DataQueryKind
  datasource: DataSourceRef

  refId: string
  hidden: bool
}

PanelQueryKind: {
  kind: "PanelQuery"
  spec: PanelQuerySpec
}

TransformationKind: {
  kind: string
  spec: DataTransformerConfig
}

QueryGroupSpec: {
  queries: [...PanelQueryKind]
  transformations: [...TransformationKind]
  queryOptions: QueryOptionsSpec
}

QueryGroupKind: {
  kind: "QueryGroup"
  spec: QueryGroupSpec
}

QueryVariableSpec: {}
QueryVariableKind: {
  kind: "QueryVariable"
  spec: QueryVariableSpec
}

TextVariableSpec: {}
TextVariableKind: {
  kind: "TextVariable"
  spec: TextVariableSpec
}

// Time configuration
// It defines the default time config for the time picker, the refresh picker for the specific dashboard.
TimeSettingsSpec: {
  // Timezone of dashboard. Accepted values are IANA TZDB zone ID or "browser" or "utc".
  timezone?: string | *"browser"
  // Start time range for dashboard.
  // Accepted values are relative time strings like 'now-6h' or absolute time strings like '2020-07-10T08:00:00.000Z'.
  from: string | *"now-6h"
  // End time range for dashboard.
  // Accepted values are relative time strings like 'now-6h' or absolute time strings like '2020-07-10T08:00:00.000Z'.
  to: string | *"now"
  // Refresh rate of dashboard. Represented via interval string, e.g. "5s", "1m", "1h", "1d".
  autoRefresh: string // v1: refresh
  // Interval options available in the refresh picker dropdown.
  autoRefreshIntervals: [...string] | *["5s", "10s", "30s", "1m", "5m", "15m", "30m", "1h", "2h", "1d"] // v1: timepicker.refresh_intervals
  // Selectable options available in the time picker dropdown. Has no effect on provisioned dashboard.
  quickRanges: [...string] | *["5m", "15m", "1h", "6h", "12h", "24h", "2d", "7d", "30d"] // v1: timepicker.time_options , not exposed in the UI
  // Whether timepicker is visible or not.
  hideTimepicker: bool // v1: timepicker.hidden
  // Day when the week starts. Expressed by the name of the day in lowercase, e.g. "monday".
  weekStart: string
  // The month that the fiscal year starts on. 0 = January, 11 = December
  fiscalYearStartMonth: int
  // Override the now time by entering a time delay. Use this option to accommodate known delays in data aggregation to avoid null values.
  nowDelay?: string // v1: timepicker.nowDelay
}

GridLayoutItemSpec: {
  x: int
  y: int
  width: int
  height: int
  element: ElementReferenceKind // reference to a PanelKind from dashboard.spec.elements Expressed as JSON Schema reference
}

GridLayoutItemKind: {
  kind: "GridLayoutItem"
  spec: GridLayoutItemSpec
}

GridLayoutSpec: {
  items: [...GridLayoutItemKind]
}

GridLayoutKind: {
  kind: "GridLayout"
  spec: GridLayoutSpec
}

PanelSpec: {
  uid: string
  title: string
  description: string
  links: [...DashboardLink]
  data: QueryGroupKind
  vizConfig: VizConfigKind
}

PanelKind: {
  kind: "Panel"
  spec: PanelSpec
}

ElementReferenceKind: {
  kind: "ElementReference"
  spec: ElementReferenceSpec
}

ElementReferenceSpec: {
  id: string
}
