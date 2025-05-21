
if {![file exists work]} {
    vlib work
}

vlog cbb/reg.v
vlog cbb/barrel_shifter.v
vlog cbb/rege.v
vlog cbb/bin2onehot.v
vlog cbb/count_ones.v
vlog cbb/mux.v

