package rolebinding

import (
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/grafana/grafana/pkg/kinds"
)

// Resource is the kubernetes style representation of RoleBinding. (TODO be better)
type K8sResource = kinds.GrafanaResource[RoleBinding, Status]

// NewResource creates a new instance of the resource with a given name (UID)
func NewK8sResource(name string, s *RoleBinding) K8sResource {
	return K8sResource{
		TypeMeta: v1.TypeMeta{
			Kind:       "RoleBinding",
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

// Resource is the wire representation of RoleBinding.
// It currently will soon be merged into the k8s flavor (TODO be better)
type Resource struct {
	Metadata Metadata    `json:"metadata"`
	Spec     RoleBinding `json:"spec"`
	Status   Status      `json:"status"`
}
