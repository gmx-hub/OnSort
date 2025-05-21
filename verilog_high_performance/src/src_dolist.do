
if {![file exists work]} {
    vlib work
}

vlog define/sort_define.v

vlog src/sort_agu.v
vlog src/sort_tlb.v
vlog src/sort_ctrl.v
vlog src/sort_cnt_mem.v
vlog src/sort_cnt_unit.v
vlog src/sort_read_unit_fsm.v
vlog src/sort_read_unit.v