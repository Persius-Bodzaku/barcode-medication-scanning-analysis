# Barcode Medication Scanning (BCMA) Compliance Analysis

A SQL analysis of 3,833 synthetic medication administrations in SQLite, asking why barcode scans get missed and where a hospital should intervene first.

Headline finding: overall compliance was 90.4%, but the misses were not mainly a nurse behavior problem. About three quarters of scan overrides traced back to equipment and infrastructure, and one unit, Med-Surg, accounted for more than half of all non-compliant doses while carrying the highest volume.

Questions covered: dataset size and status mix, overall compliance, which scan is missed more, compliance by unit, by shift, override reasons, timing, high-alert medications, and trend over 30 days.

Files: analysis.sql (the ten queries), findings.md (full results and methods). All data is synthetic.
