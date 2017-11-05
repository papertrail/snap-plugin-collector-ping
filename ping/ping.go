package ping

import (
	"fmt"
	"time"

	"github.com/intelsdi-x/snap-plugin-lib-go/v1/plugin"
)

const (
	// Name of plugin
	Name = "ping"
	// Version of plugin
	Version = 1
)

var (
	metricNames = []string{
		"avg",
		"min",
		"max",
		"median",
		"mdev",
		"loss",
	}
)

type Ping struct {
}

func New() *Ping {
	return &Ping{}
}

// CollectMetrics collects metrics for testing
func (p *Ping) CollectMetrics(mts []plugin.Metric) ([]plugin.Metric, error) {
	var err error

	cfg := mts[0].Config

	name, err := cfg.GetString("name")
	if err != nil || name == "" {
		return nil, fmt.Errorf("metric name required")
	}

	hostname, err := cfg.GetString("hostname")
	if err != nil || hostname == "" {
		return nil, fmt.Errorf("hostname missing from config, %v", cfg)
	}

	timeout, err := cfg.GetFloat("timeout")
	if err != nil || timeout == 0 {
		timeout = 10.0
	}

	count, err := cfg.GetInt("count")
	maxIntVal := int64((^uint(0)) >> 1)
	if err == nil && count > maxIntVal {
		return nil, fmt.Errorf("count exceeds %v", maxIntVal)
	}
	if err != nil || count == 0 {
		count = 5
	}

	metrics, err := ping(name, hostname, int(count), timeout, mts)
	if err != nil {
		return nil, err
	}

	return metrics, nil
}

func ping(name string, host string, count int, timeout float64, mts []plugin.Metric) ([]plugin.Metric, error) {
	check, err := NewRaintankPingProbe(host, count, timeout)
	if err != nil {
		return nil, err
	}
	runTime := time.Now()
	result, err := check.Run()
	if err != nil {
		return nil, err
	}
	stats := make(map[string]float64)
	if result.Avg != nil {
		stats["avg"] = *result.Avg
	}
	if result.Min != nil {
		stats["min"] = *result.Min
	}
	if result.Max != nil {
		stats["max"] = *result.Max
	}
	if result.Median != nil {
		stats["median"] = *result.Median
	}
	if result.Mdev != nil {
		stats["mdev"] = *result.Mdev
	}
	if result.Loss != nil {
		stats["loss"] = *result.Loss
	}

	metrics := make([]plugin.Metric, 0, len(stats))
	for i, m := range mts {
		stat := m.Namespace[3].Value
		if value, ok := stats[stat]; ok {
			ns := plugin.CopyNamespace(m.Namespace)
			ns[2].Value = name

			mts[i].Data = value
			mts[i].Timestamp = runTime
			mts[i].Namespace = ns

			metrics = append(metrics, mts[i])
		}
	}

	return metrics, nil
}

//GetMetricTypes returns metric types for testing
func (p *Ping) GetMetricTypes(cfg plugin.Config) ([]plugin.Metric, error) {
	mts := []plugin.Metric{}
	for _, metricName := range metricNames {
		mts = append(mts, plugin.Metric{
			Namespace: plugin.NewNamespace("raintank", "ping", "endpoint_name", metricName),
		})
	}
	return mts, nil
}

//GetConfigPolicy returns a ConfigPolicyTree for testing
func (p *Ping) GetConfigPolicy() (plugin.ConfigPolicy, error) {
	policy := plugin.NewConfigPolicy()
	policy.AddNewStringRule([]string{"raintank", "ping"}, "hostname", true)
	policy.AddNewFloatRule([]string{"raintank", "ping"}, "timeout", false, plugin.SetMaxFloat(10.0), plugin.SetMinFloat(0.0))
	policy.AddNewIntRule([]string{"raintank", "ping"}, "count", false, plugin.SetMaxInt(5), plugin.SetMinInt(0))

	return *policy, nil
}
