
clear all
set more off
*Add your directory here
cd ""


* Both cost figures ($3B total, $932M Union loop) treated as 2025 CAD. PPP rate = 0.84, matching World Bank Price Level Ratio for Canada: 0.840 in 2024 (most recent available; used as 2025 proxy).
* Source: https://data.worldbank.org/indicator/PA.NUS.PPPC.RF?locations=CA
local total_per_km  = (3000 * 0.84) / 3.8
local bypass_per_km = (932  * 0.84) / 3.8
local base_per_km   = `total_per_km' - `bypass_per_km'

import delimited "Merged Costs (1.4) - Sheet1.csv", rowrange(2) varnames(2) bindquote(strict) encoding("utf-8") clear

rename costkm2025dollars cost_km_2025
rename tunnelper tunnel_pct

destring cost_km_2025 tunnel_pct year rr startyear endyear, ignore(", %") replace force
replace line = "Eglinton West Ext" if line == "Eglinton Crosstown" & year == 2022
assert tunnel_pct >= 0 & tunnel_pct <= 100 if !missing(tunnel_pct)

save "cleaned_data.dta", replace

* FIGURE 1: Toronto Dumbbell Plot

use "cleaned_data.dta", clear
keep if city == "Toronto"
keep line cost_km_2025 tunnel_pct year ppprate source2 reference

gen cost_start = cost_km_2025
gen cost_end = cost_km_2025

set obs `=_N + 1'
replace line = "Waterfront LRT (Proposed)" in L
replace cost_start = `base_per_km' in L
replace cost_end = `total_per_km' in L
replace tunnel_pct = 0 in L

gsort cost_end
gen y = _n
local y_labels ""
forvalues i = 1/`=_N' {
    local lab = line[`i']
    local y_labels `"`y_labels' `i' "`lab'""'
}

twoway (rspike cost_start cost_end y, horizontal lcolor(gs12) lwidth(vthin)) ///
       (scatter y cost_start if line != "Waterfront LRT (Proposed)", mcolor("26 44 77") msize(medium)) ///
       (scatter y cost_start if line == "Waterfront LRT (Proposed)", mcolor("26 44 77") msize(large)) ///
       (scatter y cost_end if line == "Waterfront LRT (Proposed)", mcolor("179 27 27") msize(large)), ///
    ytitle("") ylabel(`y_labels', angle(0) noticks nogrid labsize(vsmall)) ///
    xlabel(0(500)2500) xtitle("Cost per km (Millions, 2025 USD PPP)") ///
    title("Waterfront LRT: The Union Loop Premium", color("26 44 77")) ///
    legend(off) scheme(s2color) graphregion(color(white) margin(l=10 r=10))
graph export "output/fig1_toronto_dumbbell.png", replace width(1600)


* FIGURE 2: Global LRT Lollipop

use "cleaned_data.dta", clear
keep if rr == 0 & year >= 2010 & inlist(country, "US", "CA")
keep if tunnel_pct < 25

gen keep_proj = 0
replace keep_proj = 1 if city == "Honolulu" & line == "HART"
replace keep_proj = 1 if city == "Mississauga" & strpos(line, "Hazel")
replace keep_proj = 1 if city == "Edmonton" & strpos(line, "Valley Line Ext")
replace keep_proj = 1 if city == "Montreal" & line == "PSE"
replace keep_proj = 1 if city == "Hamilton"
replace keep_proj = 1 if city == "Calgary" & strpos(line, "Green Line")
replace keep_proj = 1 if city == "Ottawa" & strpos(line, "Confederation") & id=="7117"
keep if keep_proj == 1

set obs `=_N + 1'
replace city = "Toronto" in L
replace line = "Waterfront LRT" in L
replace cost_km_2025 = `total_per_km' in L
replace tunnel_pct = 0 in L

gen plot_label = city + ": " + line
gsort cost_km_2025
gen y = _n
local y_labels2 ""
forvalues i = 1/`=_N' {
    local lab = plot_label[`i']
    local y_labels2 `"`y_labels2' `i' "`lab'""'
}

twoway (dropline cost_km_2025 y, horizontal lcolor(gs13)) ///
       (scatter y cost_km_2025 if city != "Toronto", mcolor("26 44 77") msize(medium)) ///
       (scatter y cost_km_2025 if city == "Toronto", mcolor("179 27 27") msize(large) mlabel(cost_km_2025) mlabpos(3) mlabcolor("179 27 27") mlabformat(%9.0f) mlabsize(vsmall)), ///
    ytitle("") ylabel(`y_labels2', angle(0) noticks nogrid labsize(vsmall)) ///
    xlabel(0(200)1000) xtitle("Cost per km (Millions, 2025 USD PPP)") ///
    title("Waterfront LRT vs. LRT Peers", color("26 44 77")) ///
    legend(off) scheme(s2color) graphregion(color(white) margin(l=10 r=10))
graph export "output/fig2_lrt_lollipop.png", replace width(1600)



* FIGURE 3: Subway Lollipop

use "cleaned_data.dta", clear
keep if rr == 0

gen keep_fig3 = 0
replace keep_fig3 = 1 if tunnel_pct > 80 & inlist(country, "US", "CA", "DE", "FR")
replace keep_fig3 = 1 if city == "Toronto" & inlist(line, "Eglinton Crosstown", "Finch West LRT")

* Narrow down to specific peers used in original
keep if keep_fig3 == 1
gen select = 0
replace select = 1 if city == "Los Angeles" & line == "Purple Line" & cost_km_2025 > 600 & cost_km_2025 < 700
replace select = 1 if city == "Vancouver" & line == "Millennium"
replace select = 1 if city == "Paris" & line == "Line 14"
replace select = 1 if city == "Seattle" & line == "U-Link"
replace select = 1 if city == "Berlin" & strpos(line, "U5-U55")
replace select = 1 if line == "Eglinton Crosstown" & cost_km_2025 > 700
replace select = 1 if line == "Finch West LRT"
keep if select == 1

set obs `=_N + 1'
replace city = "Toronto" in L
replace line = "Waterfront LRT" in L
replace cost_km_2025 = `total_per_km' in L
replace tunnel_pct = 0 in L

gen plot_label_sub = city + ": " + line
replace plot_label_sub = "Vancouver: Millennium (Broadway)" if city == "Vancouver"
replace plot_label_sub = "LA: Purple Line (Phase 2)" if city == "Los Angeles"

gsort cost_km_2025
gen y = _n
local y_labels3 ""
forvalues i = 1/`=_N' {
    local lab = plot_label_sub[`i']
    local y_labels3 `"`y_labels3' `i' "`lab'""'
}

twoway (dropline cost_km_2025 y, horizontal lcolor(gs13)) ///
       (scatter y cost_km_2025 if line != "Waterfront LRT", mcolor("26 44 77") msize(medium)) ///
       (scatter y cost_km_2025 if line == "Waterfront LRT", mcolor("179 27 27") msize(large) mlabel(cost_km_2025) mlabpos(3) mlabcolor("179 27 27") mlabformat(%9.0f) mlabsize(vsmall)), ///
    ytitle("") ylabel(`y_labels3', angle(0) noticks nogrid labsize(vsmall)) ///
    xlabel(0(200)1000) xtitle("Cost per km (Millions, 2025 USD PPP)") ///
    title("LRT at Subway Prices: International Comparison", color("26 44 77")) ///
    legend(off) scheme(s2color) graphregion(color(white) margin(l=10 r=10))
graph export "output/fig3_subway_lollipop.png", replace width(1600)


* FIGURE 4: Toronto Scatter

* Note: cost_end here refers to the total cost (with loop)
gen mpos4 = 3
replace mpos4 = 11 if inlist(line, "YUS/YNSE", "Sheppard")
replace mpos4 = 5 if line == "Bloor/SSE"
replace mpos4 = 9 if inlist(line, "YUS", "Eglinton West Ext")

twoway (scatter cost_end tunnel_pct if line != "Waterfront LRT (Proposed)", mcolor("26 44 77") msize(medium) mlabel(line) mlabsize(vsmall) mlabv(mpos4) mlabcolor("26 44 77")) ///
       (scatter cost_end tunnel_pct if line == "Waterfront LRT (Proposed)", mcolor("179 27 27") msize(large) mlabel(line) mlabsize(small) mlabpos(3) mlabcolor("179 27 27")), ///
    ytitle("Cost per km (Millions, 2025 USD PPP)") xtitle("Proportion Underground (%)") ///
    title("Toronto Transit: Complexity vs. Cost", color("26 44 77")) ///
    xlabel(0(20)100) legend(off) scheme(s2color) graphregion(color(white) margin(l=10 r=10))
graph export "output/fig4_toronto_scatter.png", replace width(1600)


* FIGURE 5: Global LRT Scatter

gen mpos5 = 3
replace mpos5 = 3 if city == "Honolulu"
replace mpos5 = 5 if city == "Mississauga"
replace mpos5 = 5 if city == "Hamilton"

twoway (scatter cost_km_2025 tunnel_pct if city != "Toronto", mcolor("26 44 77") msize(medium) mlabel(plot_label) mlabsize(vsmall) mlabv(mpos5) mlabcolor("26 44 77")) ///
       (scatter cost_km_2025 tunnel_pct if city == "Toronto", mcolor("179 27 27") msize(large) mlabel(plot_label) mlabsize(small) mlabpos(3) mlabcolor("179 27 27")), ///
    ytitle("Cost per km (Millions, 2025 USD PPP)") xtitle("Proportion Underground (%)") ///
    title("International Surface Transit Comparison", color("26 44 77")) ///
    xlabel(0(20)100) legend(off) scheme(s2color) graphregion(color(white) margin(l=10 r=10))
graph export "output/fig5_lrt_global_scatter.png", replace width(1600)


* FIGURE 6: Subway Comparison Scatter (Fixed overlaps)

gen mpos6 = 3
replace mpos6 = 9 if tunnel_pct > 80
replace mpos6 = 11 if line == "U-Link"
replace mpos6 = 3 if line == "Waterfront LRT"

twoway (scatter cost_km_2025 tunnel_pct if line != "Waterfront LRT", mcolor("26 44 77") msize(medium) mlabel(plot_label_sub) mlabsize(vsmall) mlabv(mpos6) mlabcolor("26 44 77")) ///
       (scatter cost_km_2025 tunnel_pct if line == "Waterfront LRT", mcolor("179 27 27") msize(large) mlabel(plot_label_sub) mlabsize(small) mlabpos(3) mlabcolor("179 27 27")), ///
    ytitle("Cost per km (Millions, 2025 USD PPP)") xtitle("Proportion Underground (%)") ///
    title("Surface Rail vs. Underground Subway Costs", color("26 44 77")) ///
    xlabel(0(20)100) legend(off) scheme(s2color) graphregion(color(white) margin(l=10 r=10))
graph export "output/fig6_subway_scatter.png", replace width(1600)


* FIGURE 7: Full Database Scatter

use "cleaned_data.dta", clear
keep if rr == 0 & year >= 2006 & !missing(cost_km_2025) & !missing(tunnel_pct)

set obs `=_N + 1'
replace line = "Waterfront LRT" in L
replace cost_km_2025 = `total_per_km' in L
replace tunnel_pct = 0 in L

gen is_wf = (line == "Waterfront LRT")

twoway (scatter cost_km_2025 tunnel_pct if is_wf == 0, mcolor("180 180 180%50") msize(small)) ///
       (scatter cost_km_2025 tunnel_pct if is_wf == 1, mcolor("179 27 27") msize(large) mlabel(line) mlabsize(small) mlabpos(3) mlabcolor("179 27 27")), ///
    ytitle("Cost per km (Millions, 2025 USD PPP)", size(small)) xtitle("Proportion Underground (%)") ///
    title("Waterfront LRT in Global Context", size(medium) color("26 44 77")) ///
    xlabel(0(20)100) ylabel(0(500)3000, labsize(small)) ///
    legend(off) scheme(s2color) graphregion(color(white) margin(l=12 r=10))
graph export "output/fig7_full_scatter.png", replace width(1600)


* FIGURE 8: Histogram

use "cleaned_data.dta", clear
keep if rr == 0 & year >= 2006 & !missing(cost_km_2025)

count if cost_km_2025 <= `total_per_km'
local pctile = round(100 * r(N) / _N, 1)

twoway (histogram cost_km_2025, width(50) frequency fcolor("200 200 210%70") lcolor(white) lwidth(vthin)), ///
    xline(`total_per_km', lcolor("179 27 27") lwidth(medthick) lpattern(dash)) ///
    text(120 `=`total_per_km' + 20' "Waterfront LRT" "(`pctile'th percentile)", color("179 27 27") placement(e) size(small)) ///
    xtitle("Cost per km (Millions, 2025 USD PPP)") ytitle("Number of Projects") ///
    title("Where Waterfront LRT Sits Globally", size(medium) color("26 44 77")) ///
    xlabel(0(250)3000) legend(off) scheme(s2color) graphregion(color(white) margin(l=12 r=10))
graph export "output/fig8_histogram.png", replace width(1600)

* FIGURE 9: Loop Decomposition

use "cleaned_data.dta", clear
keep if rr == 0 & year >= 2006 & !missing(cost_km_2025) & !missing(tunnel_pct)

twoway (scatter cost_km_2025 tunnel_pct, mcolor("180 180 180%50") msize(small)) ///
    (pci `base_per_km' 0 `total_per_km' 0, lcolor("179 27 27") lwidth(medthick)) ///
    (scatteri `total_per_km' 0, mcolor("179 27 27") msize(large) msymbol(circle)) ///
    (scatteri `base_per_km' 0, mcolor("179 27 27") msize(large) msymbol(circle_hollow)), ///
    text(`total_per_km' 2.5 "With loop ($663M)", placement(e) color("179 27 27") size(vsmall)) ///
    text(`base_per_km' 2.5 "Without loop ($457M)", placement(e) color("179 27 27") size(vsmall)) ///
    ytitle("Cost per km (Millions, 2025 USD PPP)", size(small)) xtitle("Proportion Underground (%)") ///
    title("Waterfront LRT in Global Context", size(medium) color("26 44 77")) ///
    xlabel(0(20)100) ylabel(0(500)3000, labsize(small)) ///
    legend(off) scheme(s2color) graphregion(color(white) margin(l=12 r=10))
graph export "output/fig9_scatter_bypass.png", replace width(1600)


* FIGURE 10: Histogram Decomposition

use "cleaned_data.dta", clear
keep if rr == 0 & year >= 2006 & !missing(cost_km_2025)

count if cost_km_2025 <= `total_per_km'
local pctile_total = round(100 * r(N) / _N, 1)
count if cost_km_2025 <= `base_per_km'
local pctile_base = round(100 * r(N) / _N, 1)

twoway (histogram cost_km_2025, width(50) frequency fcolor("200 200 210%90") lcolor(white) lwidth(vthin)), ///
    xline(`total_per_km', lcolor("179 27 27") lwidth(medthick) lpattern(dash)) ///
    xline(`base_per_km', lcolor("179 27 27") lwidth(thin) lpattern(shortdash)) ///
    text(155 `=`total_per_km' + 20' "With loop" "(`pctile_total'th pctile)", color("179 27 27") placement(e) size(vsmall)) ///
    text(175 `=`base_per_km' - 20' "Without loop" "(`pctile_base'th pctile)", color("150 27 27") placement(w) size(vsmall)) ///
    xtitle("Cost per km (Millions, 2025 USD PPP)") ytitle("Number of Projects") ///
    title("Where Waterfront LRT Sits Globally", size(medium) color("26 44 77")) ///
    xlabel(0(500)3000) legend(off) scheme(s2color) graphregion(color(white) margin(l=12 r=10))
graph export "output/fig10_histogram_bypass.png", replace width(1600)
