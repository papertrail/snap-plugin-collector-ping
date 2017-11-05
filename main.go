package main

import (
	"github.com/intelsdi-x/snap-plugin-lib-go/v1/plugin"
	"github.com/raintank/snap-plugin-collector-ping/ping"
)

func main() {
	plugin.StartCollector(ping.New(), ping.Name, ping.Version, plugin.ConcurrencyCount(5000))
}
