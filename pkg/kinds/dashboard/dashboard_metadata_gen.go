package dashboard

import (
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/grafana/grafana/pkg/kinds"
)

// Resource is the kubernetes style representation of Dashboard. (TODO be better)
type K8sResource = kinds.GrafanaResource[Dashboard, Status]

// NewResource creates a new instance of the resource with a given name (UID)
func NewK8sResource(name string, s *Dashboard) K8sResource {
	return K8sResource{
		TypeMeta: v1.TypeMeta{
			Kind:       "Dashboard",
			APIVersion: "v0-0-alpha",
		},
		ObjectMeta: v1.ObjectMeta{
			Name:        name,
			Annotations: make(map[string]string),
			Labels:      make(map[string]string),
		},
		Spec: s,
	}
}

// Resource is the wire representation of Dashboard.
// It currently will soon be merged into the k8s flavor (TODO be better)
type Resource struct {
	Metadata Metadata  `json:"metadata"`
	Spec     Dashboard `json:"spec"`
	Status   Status    `json:"status"`
}
