package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
	"sigs.k8s.io/controller-runtime/pkg/metrics"
)

var (
	ReconcilesTotal = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "reconcile_total",
			Help: "Number of total reconcilation attmpts",
		},
	)
)

func init() {
	metrics.Registry.MustRegister(ReconcilesTotal)
}
