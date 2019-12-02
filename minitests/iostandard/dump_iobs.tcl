proc dump_iobs {file_name} {

    set fp [open $file_name w]
    puts $fp "tile,site_name,site_type,clock_region,bank,is_bonded,is_clock,is_global_clock,is_vref"

    foreach tile [get_tiles *IOB33*] {
        foreach site [get_sites -of_objects $tile] {
            set site_type [get_property SITE_TYPE $site]
            set clock_region [get_property CLOCK_REGION $site]
            set is_bonded [get_property IS_BONDED $site]

            set pin [get_package_pins -of_objects $site]
            set bank [get_property BANK $pin]
            set pkg_pin [get_property NAME $pin]
            set is_clock [get_property IS_CLK_CAPABLE $pin]
            set is_global_clock [get_property IS_GLOBAL_CLK $pin]
            set is_vref [get_property IS_VREF $pin]

            puts $fp "$tile,$site,$site_type,$clock_region,$bank,$pkg_pin,$is_bonded,$is_clock,$is_global_clock,$is_vref"
        }
    }

    close $fp
}

create_project -force -in_memory -name dump_iobs -part $::env(VIVADO_PART)
set_property design_mode PinPlanning [current_fileset]
open_io_design -name io_1

dump_iobs "iobs-$::env(VIVADO_PART).csv"
