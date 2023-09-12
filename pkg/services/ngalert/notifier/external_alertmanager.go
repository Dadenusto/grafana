package notifier

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"net/url"

	httptransport "github.com/go-openapi/runtime/client"
	"github.com/go-openapi/strfmt"
	"github.com/grafana/grafana/pkg/infra/log"
	apimodels "github.com/grafana/grafana/pkg/services/ngalert/api/tooling/definitions"
	"github.com/grafana/grafana/pkg/services/ngalert/models"
	amclient "github.com/prometheus/alertmanager/api/v2/client"
	"github.com/prometheus/alertmanager/api/v2/client/alert"
	"github.com/prometheus/alertmanager/api/v2/client/alertgroup"
	"github.com/prometheus/alertmanager/api/v2/client/general"
	"github.com/prometheus/alertmanager/api/v2/client/receiver"
	"github.com/prometheus/alertmanager/api/v2/client/silence"
	"gopkg.in/yaml.v2"
)

type configStore interface {
	GetLatestAlertmanagerConfiguration(ctx context.Context, query *models.GetLatestAlertmanagerConfigurationQuery) (*models.AlertConfiguration, error)
}

type externalAlertmanager struct {
	log           log.Logger
	url           string
	tenantID      string
	orgID         int64
	amClient      *amclient.AlertmanagerAPI
	httpClient    *http.Client
	defaultConfig string
}

type ExternalAlertmanagerConfig struct {
	URL               string
	TenantID          string
	BasicAuthPassword string
	DefaultConfig     string
}

func newExternalAlertmanager(cfg ExternalAlertmanagerConfig, orgID int64) (*externalAlertmanager, error) {
	client := http.Client{
		Transport: &roundTripper{
			tenantID:          cfg.TenantID,
			basicAuthPassword: cfg.BasicAuthPassword,
			next:              http.DefaultTransport,
		},
	}

	u, err := url.Parse(cfg.URL)
	if err != nil {
		return nil, err
	}

	transport := httptransport.NewWithClient(u.Host, amclient.DefaultBasePath, []string{u.Scheme}, &client)

	return &externalAlertmanager{
		amClient:      amclient.New(transport, nil),
		httpClient:    &client,
		log:           log.New("ngalert.notifier.external.alertmanager"),
		url:           cfg.URL,
		tenantID:      cfg.TenantID,
		orgID:         orgID,
		defaultConfig: cfg.DefaultConfig,
	}, nil
}

func (am *externalAlertmanager) SaveAndApplyConfig(ctx context.Context, config *apimodels.PostableUserConfig) error {
	data, err := yaml.Marshal(config)
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, am.url, bytes.NewReader(data))
	if err != nil {
		return fmt.Errorf("error creating request: %v", err)
	}

	res, err := am.httpClient.Do(req)
	if err != nil {
		return err
	}

	if res.StatusCode == http.StatusNotFound {
		return fmt.Errorf("config not found")
	}

	defer func() {
		if err := res.Body.Close(); err != nil {
			am.log.Warn("Failed to close response body", "err", err)
		}
	}()

	resBody, err := io.ReadAll(res.Body)
	if err != nil {
		return fmt.Errorf("error reading request response: %w", err)
	}

	if res.StatusCode != http.StatusCreated {
		return fmt.Errorf("setting config failed with status code %d and error %v", res.StatusCode, string(resBody))
	}
	return nil
}

func (am *externalAlertmanager) SaveAndApplyDefaultConfig(ctx context.Context) error {
	cfg, err := Load([]byte(am.defaultConfig))
	if err != nil {
		return err
	}
	return am.SaveAndApplyConfig(ctx, cfg)
}

func (am *externalAlertmanager) GetStatus() (apimodels.GettableStatus, error) {
	params := general.NewGetStatusParams()
	res, err := am.amClient.General.GetStatus(params)
	if err != nil {
		return apimodels.GettableStatus{}, err
	}

	status := res.Payload
	if err != nil {
		return apimodels.GettableStatus{}, err
	}
	grafanaStatus := apimodels.GettableStatus{
		Cluster: status.Cluster,
		Config:  &apimodels.PostableApiAlertingConfig{
			// TODO: parse config.
		},
		Uptime:      status.Uptime,
		VersionInfo: status.VersionInfo,
	}

	return grafanaStatus, nil
}

// Silences
func (am *externalAlertmanager) CreateSilence(*apimodels.PostableSilence) (string, error) {
	// TODO: silenceS? General?
	params := silence.NewPostSilencesParams()
	res, err := am.amClient.Silence.PostSilences(params)
	if err != nil {
		return "", err
	}

	return res.Payload.SilenceID, nil
}

func (am *externalAlertmanager) DeleteSilence(string) error {
	params := silence.NewDeleteSilenceParams()
	_, err := am.amClient.Silence.DeleteSilence(params)
	return err
}

func (am *externalAlertmanager) GetSilence(silenceID string) (apimodels.GettableSilence, error) {
	params := silence.NewGetSilenceParams()
	params.SilenceID = strfmt.UUID(silenceID)

	res, err := am.amClient.Silence.GetSilence(params)
	if err != nil {
		return apimodels.GettableSilence{}, err
	}

	return apimodels.GettableSilence{
		ID:        res.Payload.ID,
		Status:    res.Payload.Status,
		UpdatedAt: res.Payload.UpdatedAt,
		Silence:   res.Payload.Silence,
	}, nil
}

func (am *externalAlertmanager) ListSilences([]string) (apimodels.GettableSilences, error) {
	params := silence.NewGetSilencesParams()
	res, err := am.amClient.Silence.GetSilences(params)
	if err != nil {
		return apimodels.GettableSilences{}, err
	}

	return res.Payload, err
}

// Alerts
func (am *externalAlertmanager) GetAlerts(active, silenced, inhibited bool, filter []string, receiver string) (apimodels.GettableAlerts, error) {
	params := alert.NewGetAlertsParams()
	res, err := am.amClient.Alert.GetAlerts(params)
	if err != nil {
		return nil, err
	}

	return res.Payload, nil
}

func (am *externalAlertmanager) GetAlertGroups(active, silenced, inhibited bool, filter []string, receiver string) (apimodels.AlertGroups, error) {
	params := alertgroup.NewGetAlertGroupsParams()
	res, err := am.amClient.Alertgroup.GetAlertGroups(params)
	if err != nil {
		return nil, err
	}

	return res.Payload, nil
}

func (am *externalAlertmanager) PutAlerts(postableAlerts apimodels.PostableAlerts) error {
	params := alert.NewPostAlertsParams()
	_, err := am.amClient.Alert.PostAlerts(params)
	return err
}

// Receivers
func (am *externalAlertmanager) GetReceivers(ctx context.Context) ([]apimodels.Receiver, error) {
	params := receiver.NewGetReceiversParams()
	res, err := am.amClient.Receiver.GetReceivers(params)
	if err != nil {
		return []apimodels.Receiver{}, err
	}

	// TODO: turn into receiver...
	rcvs := res.Payload
	grafanaRcvs := make([]apimodels.Receiver, 0, len(rcvs))
	for _, rcv := range rcvs {
		grafanaRcvs = append(grafanaRcvs, apimodels.Receiver{
			Active:       rcv.Active,
			Integrations: rcv.Integrations,
			Name:         rcv.Name,
		})
	}

	return grafanaRcvs, nil
}

// TODO: implement!
func (am *externalAlertmanager) TestReceivers(ctx context.Context, c apimodels.TestReceiversConfigBodyParams) (*TestReceiversResult, error) {
	return nil, fmt.Errorf("Testing of receivers not implemented")
}

// TODO: implement!
func (am *externalAlertmanager) TestTemplate(ctx context.Context, c apimodels.TestTemplatesConfigBodyParams) (*TestTemplatesResults, error) {
	return nil, fmt.Errorf("Testing of templates not implemented")
}

// TODO: implement!
func (am *externalAlertmanager) ApplyConfig(context.Context, *models.AlertConfiguration) error {
	return fmt.Errorf("Applying configuration not implemented")
}

// State
// TODO: implement!
func (am *externalAlertmanager) StopAndWait() {
}

// TODO: implement!
func (am *externalAlertmanager) Ready() bool {
	return false
}

// TODO: implement!
func (am *externalAlertmanager) FileStore() *FileStore {
	return &FileStore{}
}

func (am *externalAlertmanager) OrgID() int64 {
	return am.orgID
}

// TODO: implement!
func (am *externalAlertmanager) ConfigHash() [16]byte {
	return [16]byte{}
}

type roundTripper struct {
	tenantID          string
	basicAuthPassword string
	next              http.RoundTripper
}

// RoundTrip implements the http.RoundTripper interface
// while adding the `X-Scope-OrgID` header and basic auth credentials.
func (r *roundTripper) RoundTrip(req *http.Request) (*http.Response, error) {
	req.Header.Set("X-Scope-OrgID", r.tenantID)
	if r.tenantID != "" && r.basicAuthPassword != "" {
		req.SetBasicAuth(r.tenantID, r.basicAuthPassword)
	}

	return r.next.RoundTrip(req)
}
