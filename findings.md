# Barcode Medication Scanning (BCMA) Compliance: Findings (SYNTHETIC DATA)

Dataset: 3,833 synthetic medication administrations (3,667 Given) across 700 encounters on 5 units, scheduled Sep 1 to Sep 30, 2026. All data is synthetic. No real patients, staff, or hospital data.

## Headline numbers

- **Overall scan compliance: 90.4%** (3,315 of 3,667 Given doses had both the patient wristband and the medication barcode scanned)
- Patient-scan rate: 94.2% (3,453 of 3,667). Medication-scan rate: 94.3% (3,459 of 3,667). The wristband was missed slightly more often (214 vs 208 misses), effectively a tie.
- Day shift: 91.3% (2,036 of 2,231). Night shift: 89.1% (1,279 of 1,436).

## By unit (Given doses only)

| Unit | Given doses | Compliant | Compliance |
|------|-------------|-----------|------------|
| ICU | 655 | 622 | 95.0% |
| Telemetry | 897 | 846 | 94.3% |
| Stepdown | 770 | 707 | 91.8% |
| ED | 216 | 191 | 88.4% |
| Med-Surg | 1,129 | 949 | 84.1% |

Med-Surg had the lowest compliance while carrying the highest volume, and its 180 non-compliant doses were more than half of all 352 non-compliant doses in the dataset. Biggest day-to-night drop: ED, 91.0% to 85.1% (5.9 points). Med-Surg was low on both shifts (84.6% day, 83.2% night), so its problem is the unit, not the shift.

## Overrides

Overrides were used on 257 Given doses (7.0% of Given doses, 73.0% of the 352 non-compliant Given doses).

1. Scanner not working: 77 (30.0% of overrides)
2. Medication barcode unreadable or damaged: 60 (23.3%)
3. Emergency administration: 39 (15.2%)
4. Wristband missing or damaged: 35 (13.6%)
5. Patient off unit: 29 (11.3%)
6. System downtime: 17 (6.6%)

Scanner and barcode failures alone are 53.3% of overrides. Adding wristband condition and system downtime, about three quarters (73.5%) trace back to infrastructure, not nurse behavior.

## Timing

- Early: 93.5% (159 of 170)
- On time: 90.6% (2,211 of 2,440)
- Late: 89.4% (945 of 1,057)

Late doses scanned slightly worse than on-time doses, a gap too small for lateness to explain most missed scans. Both look like symptoms of a pressured med pass, associated, not proven causal.

## Medication patterns

High-alert medications: 92.4% (734 of 794). All other medications: 89.8% (2,581 of 2,873). Nurses scanned more reliably when the drug itself signaled danger, but 60 high-alert doses still missed a scan.

## Trend over the 30 days

Weekly compliance: 90.8%, 91.1%, 88.9%, 90.9%. No drift. The roughly 90% rate is a stable property of the system, not a trend in either direction.

## Data-quality notes

Held (67), Refused (43), and Missed (56) doses carry NULL scan fields by design and are excluded from every compliance rate. Denominator for all rates is Given doses only.

## Where to target improvement

1. Fix the equipment first: scanner availability and reliability, medication barcode label quality, and wristband reprints. That addresses the majority of overrides.
2. Focus workflow support on Med-Surg, the highest-volume and lowest-compliance unit, on both shifts, not only at night.
3. Keep the high-alert ritual, and close the remaining 60-dose gap, because careful most of the time is not the standard for high-alert medications.

## Methods

SQLite (DB Browser), hand-written queries in [analysis.sql](analysis.sql). Compliance means both scans completed. Denominator = Given doses only. Timing window is 30 minutes around the scheduled time. Shift is from scheduled time (day 07:00 to 18:59, night 19:00 to 06:59).
