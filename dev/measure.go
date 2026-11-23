// Build inside the pinned WoWSims module with the with_db tag (see README).
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"

	"github.com/wowsims/forever/sim"
	"github.com/wowsims/forever/sim/core"
	"github.com/wowsims/forever/sim/core/proto"
	"google.golang.org/protobuf/encoding/protojson"
)

type Measurement struct {
	Stats      []float64 `json:"stats"`
	Pseudo     []float64 `json:"pseudo"`
	Sets       []string  `json:"sets"`
	Mean       float64   `json:"mean"`
	SD         float64   `json:"sd"`
	Iterations int32     `json:"iterations"`
}

func main() {
	sim.RegisterAll()
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Buffer(make([]byte, 65536), 4<<20)
	encoder := json.NewEncoder(os.Stdout)
	for scanner.Scan() {
		req := &proto.RaidSimRequest{}
		if err := protojson.Unmarshal(scanner.Bytes(), req); err != nil {
			panic(err)
		}
		sheet := core.ComputeStats(&proto.ComputeStatsRequest{Raid: req.Raid, Encounter: req.Encounter, SkipRotation: true})
		p := sheet.RaidStats.Parties[0].Players[0]
		m := Measurement{Stats: p.FinalStats.Stats, Pseudo: p.FinalStats.PseudoStats, Sets: p.Sets}
		if req.SimOptions.Iterations > 0 {
			result := core.RunRaidSim(req)
			if result.Error != nil {
				panic(result.Error.Message)
			}
			metrics := result.RaidMetrics.Parties[0].Players[0]
			m.Mean, m.SD, m.Iterations = metrics.Dps.Avg, metrics.Dps.Stdev, result.IterationsDone
			if m.Mean <= 0 || m.Iterations != req.SimOptions.Iterations {
				panic("incomplete damage simulation")
			}
		}
		if err := encoder.Encode(m); err != nil {
			panic(err)
		}
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
