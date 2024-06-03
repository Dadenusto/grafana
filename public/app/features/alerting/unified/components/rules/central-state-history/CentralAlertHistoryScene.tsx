import React from 'react';

import { getDataSourceSrv } from '@grafana/runtime';
import {
  EmbeddedScene,
  PanelBuilders,
  SceneControlsSpacer,
  SceneFlexItem,
  SceneFlexLayout,
  SceneQueryRunner,
  SceneReactObject,
  SceneRefreshPicker,
  SceneTimePicker,
} from '@grafana/scenes';
import {
  GraphDrawStyle,
  GraphGradientMode,
  LegendDisplayMode,
  LineInterpolation,
  ScaleDistribution,
  StackingMode,
  TooltipDisplayMode,
  VisibilityMode,
} from '@grafana/schema/dist/esm/index';

import { DataSourceInformation, PANEL_STYLES } from '../../../home/Insights';
import { InsightsRatingModal } from '../../../insights/RatingModal';
import { SectionSubheader } from '../../../insights/SectionSubheader';

import { HistoryEventsListObjectRenderer } from './CentralAlertHistory';

export const CentralAlertHistoryScene = () => {
  const dataSourceSrv = getDataSourceSrv();
  const ashDs: DataSourceInformation = {
    type: 'loki',
    uid: 'grafanacloud-alert-state-history',
    settings: undefined,
  };

  ashDs.settings = dataSourceSrv.getInstanceSettings(ashDs.uid);

  const scene = new EmbeddedScene({
    controls: [new SceneControlsSpacer(), new SceneTimePicker({}), new SceneRefreshPicker({})],
    body: new SceneFlexLayout({
      direction: 'column',
      children: [
        new SceneFlexItem({
          ySizing: 'content',
          body: getEventsSceneObject(ashDs),
        }),
        new SceneFlexItem({
          body: new SceneReactObject({
            component: HistoryEventsListObjectRenderer,
          }),
        }),
      ],
    }),
  });

  return <scene.Component model={scene} />;
};

function getEventsSceneObject(ashDs: DataSourceInformation) {
  return new EmbeddedScene({
    controls: [
      new SceneReactObject({
        component: SectionSubheader,
      }),
    ],
    body: new SceneFlexLayout({
      direction: 'column',
      children: [
        new SceneFlexItem({
          ySizing: 'content',
          body: new SceneFlexLayout({
            children: [getEventsScenesFlexItem(ashDs)],
          }),
        }),
      ],
    }),
  });
}

export function getEventsScenesFlexItem(datasource: DataSourceInformation) {
  const query = new SceneQueryRunner({
    datasource,
    queries: [
      {
        refId: 'A',
        expr: 'count_over_time({from="state-history"} |= `` [$__auto])',
        queryType: 'range',
        step: '10s',
      },
    ],
  });

  return new SceneFlexItem({
    ...PANEL_STYLES,
    body: PanelBuilders.timeseries()
      .setTitle('Events')
      .setDescription('Alert events during the period of time.')
      .setData(query)
      .setColor({ mode: 'continuous-BlPu' })
      .setCustomFieldConfig('fillOpacity', 100)
      .setCustomFieldConfig('drawStyle', GraphDrawStyle.Bars)
      .setCustomFieldConfig('lineInterpolation', LineInterpolation.Linear)
      .setCustomFieldConfig('lineWidth', 1)
      .setCustomFieldConfig('barAlignment', 0)
      .setCustomFieldConfig('spanNulls', false)
      .setCustomFieldConfig('insertNulls', false)
      .setCustomFieldConfig('showPoints', VisibilityMode.Auto)
      .setCustomFieldConfig('pointSize', 5)
      .setCustomFieldConfig('stacking', { mode: StackingMode.None, group: 'A' })
      .setCustomFieldConfig('gradientMode', GraphGradientMode.Hue)
      .setCustomFieldConfig('scaleDistribution', { type: ScaleDistribution.Linear })
      .setOption('legend', { showLegend: false, displayMode: LegendDisplayMode.Hidden })
      .setOption('tooltip', { mode: TooltipDisplayMode.Single })

      .setNoValue('No events found')
      .setHeaderActions(<InsightsRatingModal panel={'Events'} />)
      .build(),
  });
}