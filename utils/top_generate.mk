all: OK

OK: generate.ok
	touch OK

# Some projects have hard coded top.v, others are generated
top.v.ok:
	if [ -f ${FUZDIR}/top.py ] ; then python3 ${FUZDIR}/top.py >top.v; fi
	touch top.v.ok

vivado.ok: top.v.ok ${FUZDIR}/generate.tcl
	${XRAY_VIVADO} -mode batch -source ${FUZDIR}/generate.tcl
	test -z "$(fgrep CRITICAL vivado.log)"
	touch vivado.ok

design_bits.ok: vivado.ok
	\
        for x in design*.bit; do \
            ${XRAY_BITREAD} -F ${XRAY_ROI_FRAMES} -o $${x}s -z -y $$x ; \
        done
	touch design_bits.ok

generate.ok: design_bits.ok ${FUZDIR}/generate.py
	python3 ${FUZDIR}/generate.py ${GENERATE_FLAGS}
	touch generate.ok

