-- =====================================================================
-- Barcode Medication Scanning (BCMA) Compliance Analysis
-- Database: barcode_medication_scanning.db (SQLite)
-- ALL DATA IS SYNTHETIC. No real patients, staff, or hospital data.
--
-- Definitions used throughout:
--   Scan compliant = BOTH the patient wristband and the medication
--     barcode were scanned (scan_compliant = 1).
--   Denominator for every compliance rate = Given doses only. Held,
--     Refused, and Missed doses were never administered and carry NULL
--     scan fields by design.
--   Timing window: Early = more than 30 min before scheduled time,
--     On time = within 30 min either side, Late = more than 30 min after.
--   Shift (from scheduled time): day 07:00-18:59, night 19:00-06:59.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Q1: How big is this dataset?
-- Administrations, encounters, and units, one count per table.
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS administrations FROM medication_administrations;

SELECT COUNT(*) AS encounters FROM encounters;

SELECT COUNT(*) AS units FROM units;


-- ---------------------------------------------------------------------
-- Q2: What actually counts as a dose given?
-- Administrations broken down by status, with each status's share
-- of all scheduled doses.
-- ---------------------------------------------------------------------
SELECT
    administration_status,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM medication_administrations), 1) AS share_pct
FROM medication_administrations
GROUP BY administration_status
ORDER BY n DESC;


-- ---------------------------------------------------------------------
-- Q3: What is the overall scan compliance rate?
-- Given doses only. scan_compliant is a 1/0 flag, so SUM gives the
-- compliant count and the rate is that SUM over the filtered COUNT.
-- ---------------------------------------------------------------------
SELECT
    COUNT(*) AS given_doses,
    SUM(scan_compliant) AS compliant,
    ROUND(100.0 * SUM(scan_compliant) / COUNT(*), 1) AS compliance_pct
FROM medication_administrations
WHERE administration_status = 'Given';


-- ---------------------------------------------------------------------
-- Q4: Which scan gets missed more, the wristband or the medication?
-- Two flags, same denominator (Given doses). Misses = doses - scans.
-- ---------------------------------------------------------------------
SELECT
    COUNT(*) AS given_doses,
    SUM(patient_scanned) AS patient_scans,
    COUNT(*) - SUM(patient_scanned) AS patient_misses,
    ROUND(100.0 * SUM(patient_scanned) / COUNT(*), 1) AS patient_scan_pct,
    SUM(medication_scanned) AS medication_scans,
    COUNT(*) - SUM(medication_scanned) AS medication_misses,
    ROUND(100.0 * SUM(medication_scanned) / COUNT(*), 1) AS medication_scan_pct,
    SUM(CASE WHEN patient_scanned = 0 AND medication_scanned = 0 THEN 1 ELSE 0 END) AS both_missed,
    SUM(CASE WHEN scan_compliant = 0 THEN 1 ELSE 0 END) AS non_compliant_total
FROM medication_administrations
WHERE administration_status = 'Given';


-- ---------------------------------------------------------------------
-- Q5: Which unit scans best, and which unit needs help?
-- Compliance by unit, Given doses only, best first, with dose counts
-- shown next to every rate.
-- ---------------------------------------------------------------------
SELECT
    unit,
    COUNT(*) AS given_doses,
    SUM(scan_compliant) AS compliant,
    ROUND(100.0 * SUM(scan_compliant) / COUNT(*), 1) AS compliance_pct
FROM medication_administrations
WHERE administration_status = 'Given'
GROUP BY unit
ORDER BY compliance_pct DESC;


-- ---------------------------------------------------------------------
-- Q6: Do nights scan worse than days, and where?
-- Part A: compliance by shift overall.
-- Part B: compliance by unit and shift together, ordered so each
-- unit's day and night rows sit side by side.
-- ---------------------------------------------------------------------
SELECT
    shift,
    COUNT(*) AS given_doses,
    SUM(scan_compliant) AS compliant,
    ROUND(100.0 * SUM(scan_compliant) / COUNT(*), 1) AS compliance_pct
FROM medication_administrations
WHERE administration_status = 'Given'
GROUP BY shift
ORDER BY compliance_pct DESC;

SELECT
    unit,
    shift,
    COUNT(*) AS given_doses,
    SUM(scan_compliant) AS compliant,
    ROUND(100.0 * SUM(scan_compliant) / COUNT(*), 1) AS compliance_pct
FROM medication_administrations
WHERE administration_status = 'Given'
GROUP BY unit, shift
ORDER BY unit, shift;


-- ---------------------------------------------------------------------
-- Q7: When nurses override, why?
-- Overrides only exist inside the non-compliant Given subset.
-- Part A: how many non-compliant Given doses used an override, and
-- the override count against all Given doses.
-- Part B: override reasons ranked, with each reason's share of all
-- overridden doses. (Every override in this dataset sits inside the
-- non-compliant subset, so the reason counts are the same whether
-- the base is non-compliant doses or all Given doses.)
-- ---------------------------------------------------------------------
SELECT
    COUNT(*) AS non_compliant_given,
    SUM(override_used) AS overrides_used,
    ROUND(100.0 * SUM(override_used) / COUNT(*), 1) AS pct_of_non_compliant,
    ROUND(100.0 * SUM(override_used) / (SELECT COUNT(*) FROM medication_administrations
                                        WHERE administration_status = 'Given'), 1) AS pct_of_all_given
FROM medication_administrations
WHERE administration_status = 'Given'
  AND scan_compliant = 0;

SELECT
    override_reason,
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM medication_administrations
                              WHERE administration_status = 'Given'
                                AND scan_compliant = 0
                                AND override_used = 1), 1) AS share_of_overrides_pct
FROM medication_administrations
WHERE administration_status = 'Given'
  AND scan_compliant = 0
  AND override_reason IS NOT NULL
GROUP BY override_reason
ORDER BY n DESC;


-- ---------------------------------------------------------------------
-- Q8: Is late administration tangled up with missed scans?
-- Compliance inside each timing category, ordered in workflow order
-- (Early, On time, Late), not by rate. Association, not causation:
-- a late dose may be rushed and unscanned, or hunting for a working
-- scanner may be what made it late.
-- ---------------------------------------------------------------------
SELECT
    timing_category,
    COUNT(*) AS given_doses,
    SUM(scan_compliant) AS compliant,
    ROUND(100.0 * SUM(scan_compliant) / COUNT(*), 1) AS compliance_pct
FROM medication_administrations
WHERE administration_status = 'Given'
GROUP BY timing_category
ORDER BY CASE timing_category
             WHEN 'Early' THEN 1
             WHEN 'On time' THEN 2
             WHEN 'Late' THEN 3
         END;


-- ---------------------------------------------------------------------
-- Q9: Do high-alert medications get scanned more reliably?
-- Part A: compliance for high-alert vs all other medications.
-- Part B: compliance by medication class, ranked, with counts.
-- Part C: same ranking by route, to check whether the route story
-- and the class story agree.
-- ---------------------------------------------------------------------
SELECT
    high_alert_flag,
    COUNT(*) AS given_doses,
    SUM(scan_compliant) AS compliant,
    COUNT(*) - SUM(scan_compliant) AS non_compliant,
    ROUND(100.0 * SUM(scan_compliant) / COUNT(*), 1) AS compliance_pct
FROM medication_administrations
WHERE administration_status = 'Given'
GROUP BY high_alert_flag
ORDER BY compliance_pct DESC;

SELECT
    medication_class,
    COUNT(*) AS given_doses,
    SUM(scan_compliant) AS compliant,
    ROUND(100.0 * SUM(scan_compliant) / COUNT(*), 1) AS compliance_pct
FROM medication_administrations
WHERE administration_status = 'Given'
GROUP BY medication_class
ORDER BY compliance_pct DESC;

SELECT
    route,
    COUNT(*) AS given_doses,
    SUM(scan_compliant) AS compliant,
    ROUND(100.0 * SUM(scan_compliant) / COUNT(*), 1) AS compliance_pct
FROM medication_administrations
WHERE administration_status = 'Given'
GROUP BY route
ORDER BY compliance_pct DESC;


-- ---------------------------------------------------------------------
-- Q10: Is compliance drifting over the 30 days?
-- Part A: compliance by day (expect bounce; daily n is small).
-- Part B: weekly buckets by day of month (Sep 1-7, 8-14, 15-21,
-- 22-30) to smooth the noise and test for real drift.
-- ---------------------------------------------------------------------
SELECT
    strftime('%Y-%m-%d', scheduled_ts) AS day,
    COUNT(*) AS given_doses,
    SUM(scan_compliant) AS compliant,
    ROUND(100.0 * SUM(scan_compliant) / COUNT(*), 1) AS compliance_pct
FROM medication_administrations
WHERE administration_status = 'Given'
GROUP BY day
ORDER BY day;

SELECT
    CASE
        WHEN CAST(strftime('%d', scheduled_ts) AS INTEGER) BETWEEN 1 AND 7 THEN 'Week 1 (Sep 1-7)'
        WHEN CAST(strftime('%d', scheduled_ts) AS INTEGER) BETWEEN 8 AND 14 THEN 'Week 2 (Sep 8-14)'
        WHEN CAST(strftime('%d', scheduled_ts) AS INTEGER) BETWEEN 15 AND 21 THEN 'Week 3 (Sep 15-21)'
        ELSE 'Week 4 (Sep 22-30)'
    END AS week,
    COUNT(*) AS given_doses,
    SUM(scan_compliant) AS compliant,
    ROUND(100.0 * SUM(scan_compliant) / COUNT(*), 1) AS compliance_pct
FROM medication_administrations
WHERE administration_status = 'Given'
GROUP BY week
ORDER BY week;
