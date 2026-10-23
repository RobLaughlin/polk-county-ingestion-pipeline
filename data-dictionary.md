# Data dictionary: Polk County residential sales

This describes the 80 columns of the Polk County Assessor's residential sales export, as loaded into the BigQuery `sales_raw` table. In `sales_raw` every column is a STRING; the types below are what each column should be cast to in staging.

- **Source data:** one CSV per year, 1990 to the present, from the [assessor's export folder][EXPORT].
- **Grain:** one row per recorded document (a deed or contract). `(book, pg)` is unique. `(dp, sale_date)` is not, because some parcels have several documents recorded on the same day (see [Data-quality notes](#data-quality-notes)).
- **Profile:** 403,264 rows, profiled 2026-10-22. **Nulls** is the share of rows where the raw value is NULL, meaning the CSV field was empty.
- **Ideal type** is the BigQuery type for the staged column. **Nullable** says whether the staged column should allow NULL. REQUIRED is only used for keys and core sale fields that have no nulls today.
- **Source** is the assessor's database dictionary page for the field. The CSV has no published layout, so its columns were matched to those fields by name and checked against one parcel's [web card][CARD]. "Label only" means the page names the field but doesn't define it. "Inferred from data" means no definition was found and the meaning comes from the values.

| Key | Assessor dictionary page |
|---|---|
| [RS] | Residential sale table (`rsale`) |
| [RES] | Residence table (`residence`) |
| [DIST] | Districts (`districts`) |
| [PAR] | Parcel (`parcel`) |
| [NB] | Neighborhoods (`nbhds`) |
| [XY] | Parcel coordinates (`xysall`) |
| [LND] | Land totals (`slandtotal`) |
| [PLT] | Plats (`plats`) |
| [LEG] | Legal descriptions (`legal`) |
| [CON] | Condo units (`condo_unit`) |
| [DET] | Detached structures (`detached`) |
| [FORM] | Residential sales search form |

The assessor's site says it is moving to a new site, so these links may stop working.

## Location and IDs

| # | Column | Meaning | Ideal type | Nullable | Nulls | Notes | Source |
|---|---|---|---|---|---|---|---|
| 1 | `jurisdiction` | City or township the parcel is in. | STRING | REQUIRED | 0% | 38 values, e.g. `ANKENY`, `ALLEN TWNSHP`. | [DIST] |
| 2 | `nbhd` | Assessor neighborhood code. | STRING | NULLABLE | <0.01% | 4 characters, e.g. `AK02`. 197 values. | [NB] (label only) |
| 3 | `pocket` | Sub-area of the neighborhood. `nbhd` and `pocket` together identify a neighborhood. | STRING | NULLABLE | <0.01% | 2 characters, e.g. `G3`. 241,487 rows have a trailing space (`A `); trim it. | [NB] (label only) |
| 4 | `dp` | District/Parcel number: the 14-digit property ID. The first 3 digits are the district. | STRING | REQUIRED | 0% | Keep as text, because leading zeros matter (`01000001000000`). | [RS] |
| 5 | `gp` | Geoparcel number. | STRING | NULLABLE | 0.42% | 12 digits, e.g. `802434255001`. | [XY] (label only) |
| 11 | `address` | Street address of the property sold. | STRING | NULLABLE | 0% | 4,634 rows (1.15%) are blank or only spaces; treat them as NULL. | [RS] |
| 12 | `zip` | Zip code of the property sold. | STRING | NULLABLE | 1.16% | 13 values aren't 5-digit Iowa zip codes (e.g. `55`). | [RS] |
| 21 | `dps` | Short form of `dp`: the district, then the parcel parts without leading zeros. | STRING | NULLABLE | 0% | `18101588000000` becomes `181/1588`. Multi-parcel sales list every parcel (up to 6,206 characters). | [RS] |
| 22 | `gps` | Every geoparcel in the sale. | STRING | NULLABLE | 0.42% | The same as `gp` for one-parcel sales, otherwise a comma-separated list (14,524 rows). | Inferred from data |
| 76 | `platname` | Name of the recorded plat (subdivision) the parcel is in. | STRING | NULLABLE | 0.31% | e.g. `WHITE BIRCH PLAT 1`. | [PLT] (label only) |
| 77 | `legal_all_parcels` | Legal description of every parcel in the sale. | STRING | NULLABLE | 0.42% | One `gp: description` entry per parcel, e.g. `282223251001: LT 8 EAST POLK PLAT 2`. Up to 18,740 characters. | Inferred from data; [LEG] has labels only |
| 78 | `school_district` | School district the parcel is in. | STRING | REQUIRED | 0% | 16 values, e.g. `Ankeny`. | [PAR] (label only) |

## Sale

| # | Column | Meaning | Ideal type | Nullable | Nulls | Notes | Source |
|---|---|---|---|---|---|---|---|
| 6 | `sale_date` | Date the parties signed the deed or contract, as entered from the Declaration of Value. | DATE | REQUIRED | 0% | `YYYY-MM-DD`. This is the signing date, not the recording date. | [RS] |
| 7 | `book` | Recorder's book number for the recorded document. | INT64 | REQUIRED | 0% | Rises over time: the median is 6,262 for 1990 sales and 20,196 for 2025. | [RS] |
| 8 | `pg` | Recorder's page number within the book. | INT64 | REQUIRED | 0% | `(book, pg)` is the table's primary key. | [RS] |
| 9 | `instrument` | Document type: `Deed` or `Contract`. | STRING | NULLABLE | 0.04% | Neither the assessor nor the Iowa Department of Revenue uses contract sales for analysis. | [RS] |
| 10 | `price` | Price paid for the real property only: the total paid minus any personal property. | INT64 | REQUIRED | 0% | Whole dollars, 0 to 22,827,240. Token prices such as 0, 1 or 10 are common on non-market transfers. | [RS] |
| 13 | `seller` | Seller (grantor). | STRING | NULLABLE | 0% | Up to 50 characters. 58,660 values have extra spaces at the start or end; trim them. | [RS] |
| 14 | `buyer` | Buyer (grantee). | STRING | NULLABLE | 0% | 49 values are blank; treat them as NULL. | [RS] |
| 79 | `initial_entry_date` | Probably the date the sale was first entered into the assessor's system. | DATE | NULLABLE | 9.20% | The median is 9 days after `sale_date`; 250 rows are earlier than it. The sales search form has a "Sale Entry Date" field, but no source ties it to this column. | Inferred from data |
| 80 | `yr` | Year of the sale. | INT64 | REQUIRED | 0% | Always equals the year of `sale_date`. | Inferred from data |

## Valuation

| # | Column | Meaning | Ideal type | Nullable | Nulls | Notes | Source |
|---|---|---|---|---|---|---|---|
| 15 | `land_full` | Full assessed value of the land at the time of sale, as of January 1 of that assessment year, including Board of Review changes. | INT64 | NULLABLE | <0.01% | Whole dollars. | [RS] |
| 16 | `bldg_full` | The same, for the buildings. | INT64 | NULLABLE | <0.01% | Whole dollars. | [RS] |
| 17 | `total_full` | The same, for land and buildings together. | INT64 | NULLABLE | <0.01% | Equals `land_full + bldg_full` except in 249 rows. | [RS] |

## Sale quality

| # | Column | Meaning | Ideal type | Nullable | Nulls | Notes | Source |
|---|---|---|---|---|---|---|---|
| 18 | `quality1` | First Iowa Department of Revenue sale condition code: the reason, if any, the sale isn't a normal market sale. | STRING | REQUIRED | 0% | Holds the code's name, not its number. `Arms Length` means no condition. See [Sale condition codes](#sale-condition-codes). | [RS] |
| 19 | `quality2` | Second sale condition code, for sales with two conditions. | STRING | REQUIRED | 0% | `No Code` means no second condition. | [RS] |
| 20 | `analysis_quality` | Whether the assessor uses the sale in its own market analysis, such as comparable sales and calibrating its cost models. | STRING | NULLABLE | <0.01% | `Good` means used and `Bad` means not used, so it could become a BOOL in staging. Matched by name to the sale table's "Analysis" field; the state's own Good/Bad flag isn't in the CSV. | [RS], [FORM] |

## Land

| # | Column | Meaning | Ideal type | Nullable | Nulls | Notes | Source |
|---|---|---|---|---|---|---|---|
| 23 | `land_sf` | Land area in square feet. | INT64 | NULLABLE | 1.76% | | [LND] (label only) |
| 24 | `land_acres` | Land area in acres. | NUMERIC | NULLABLE | 1.76% | 3 decimal places, 0 to 497.085. | [LND] (label only) |

## Building

All residence columns from here on are NULL for the roughly 55,400 rows that have no residence record. See [Data-quality notes](#data-quality-notes).

| # | Column | Meaning | Ideal type | Nullable | Nulls | Notes | Source |
|---|---|---|---|---|---|---|---|
| 25 | `occupancy` | Kind of dwelling. | STRING | NULLABLE | 13.80% | 6 values seen: Single Family, Townhouse, Condominium, Duplex, Bi-attached, Conversion. | [RES] |
| 26 | `residence_type` | Number of stories and type of attic. | STRING | NULLABLE | 13.80% | 13 values, e.g. 1 Story, 1.5 Stories, 2 Stories, Split Foyer. | [RES] |
| 27 | `bldg_style` | Architectural style. | STRING | NULLABLE | 24.33% | 39 values, e.g. Conventional, Ranch, Cape Cod, 3 Split. | [RES] |
| 28 | `exterior_wall_type` | Main exterior wall material. | STRING | NULLABLE | 14.70% | 16 values, e.g. Vinyl Siding, Brick, Wood Siding. | [RES] |
| 29 | `percent_brick` | Percent of the house exterior that is full-height brick. | INT64 | NULLABLE | 13.74% | 0 to 100. Brick on only the front wall goes in `veneer_area` instead. | [RES] |
| 30 | `roof_type` | Roof shape. | STRING | NULLABLE | 15.74% | Gable, Hip, Flat, Gambrel, Mansard, Shed or Other. | [RES] |
| 31 | `roof_material` | Roof covering. | STRING | NULLABLE | 14.40% | 10 values, e.g. Asphalt Shingle, Metal, Wood Shingle. | [RES] |
| 37 | `foundation` | Foundation material. | STRING | NULLABLE | 14.00% | 8 values, e.g. Poured Concrete, Concrete Block, Brick. | [RES] |
| 64 | `families` | Number of living units in the dwelling. | INT64 | NULLABLE | 19.82% | 1 by default; 2 or 3 means extra units. More than 3 is assessed as commercial. Values 0 to 9 appear. | [RES] |
| 70 | `heating` | Heating system. | STRING | NULLABLE | 14.46% | 8 values, e.g. Gas Forced Air, Heat Pump, Geo-Thermal. | [RES] |
| 71 | `air_conditioning` | Percent of the living area cooled by central air. | INT64 | NULLABLE | 13.74% | 0 to 100. | [RES] |
| 72 | `percent_complete` | How far along an unfinished dwelling is. | INT64 | NULLABLE | 98.17% | Construction stages include Framing (30) and Painting (90). NULL for finished homes. 5 rows are above 100, up to 133. | [RES] |
| 75 | `detached_structs` | Detached structures on the parcel, as `CODE/size` pairs. | STRING | NULLABLE | <0.01% | e.g. `BBK/1584 SHD/120`, a bank barn and a shed; the size is probably square feet. Blank in 254,060 rows, meaning none. Most common codes: GAR Garage, SHD Shed, PTC Concrete Patio, SWR Outdoor Pool, DEC Deck, UTS Metal Utility Building. | [DET] for the codes; the format is inferred from data |

## Areas

All areas are in square feet.

| # | Column | Meaning | Ideal type | Nullable | Nulls | Notes | Source |
|---|---|---|---|---|---|---|---|
| 32 | `main_living_area` | Finished living area on the main floor. | INT64 | NULLABLE | 13.74% | Measured from the building sketch. | [RES] |
| 33 | `upper_living_area` | Finished living area above the main floor. | INT64 | NULLABLE | 13.74% | | [RES] |
| 34 | `fin_attic_area` | Finished attic area. | INT64 | NULLABLE | 13.74% | | [RES] |
| 35 | `total_living_area` | Main floor, upper floors and finished attic together, measured on exterior dimensions to ANSI standards. | INT64 | NULLABLE | 13.74% | 403 rows don't equal the sum of the three columns. | [RES] |
| 36 | `unfin_attic_area` | Unfinished attic reached by stairs, used for storage. | INT64 | NULLABLE | 13.74% | | [RES] |
| 42 | `att_garage_area` | Attached garage. | INT64 | NULLABLE | 13.74% | | [RES] |
| 43 | `garage_brick` | Percent of the attached garage exterior that is brick. | INT64 | NULLABLE | 13.74% | A percent, not an area. 0 to 100. | [RES] |
| 44 | `open_porch_area` | Open or screened porch. | INT64 | NULLABLE | 13.74% | | [RES] |
| 45 | `enclose_porch_area` | Three-season porch or breezeway. | INT64 | NULLABLE | 13.74% | | [RES] |
| 46 | `patio_area` | Patio. | INT64 | NULLABLE | 13.74% | The assessor's guide sets a 50 sq ft minimum, but smaller values appear. | [RES] |
| 47 | `deck_area` | Wood deck. | INT64 | NULLABLE | 13.74% | The assessor's guide sets a 50 sq ft minimum, but smaller values appear. | [RES] |
| 48 | `canopy_area` | Metal canopy. | INT64 | NULLABLE | 13.74% | | [RES] |
| 49 | `veneer_area` | Brick on the front wall or part of a wall. | INT64 | NULLABLE | 13.74% | | [RES] |
| 50 | `carport_area` | Carport. | INT64 | NULLABLE | 13.74% | | [RES] |

## Basement

| # | Column | Meaning | Ideal type | Nullable | Nulls | Notes | Source |
|---|---|---|---|---|---|---|---|
| 38 | `basement_area` | Total basement area, finished or not, in square feet. | INT64 | NULLABLE | 13.74% | | [RES] |
| 39 | `fin_bsmt_area_tot` | Total finished basement area, in square feet. | INT64 | NULLABLE | 13.74% | Always equals `fin_bsmt_area1 + fin_bsmt_area2`. | Inferred from data |
| 40 | `bsmt_walkout` | Length of walkout (fully exposed) basement wall, in linear feet. | INT64 | NULLABLE | 13.74% | 0 to 550. | [RES] |
| 41 | `bsmt_gar_capacity` | Number of garage stalls in the basement. | INT64 | NULLABLE | 13.74% | 0 to 6. | [RES] |
| 51 | `fin_bsmt_area1` | First finished basement area, in square feet. | INT64 | NULLABLE | 13.74% | | [RES] |
| 52 | `fin_bsmt_qual1` | Finish quality of the first area. | STRING | NULLABLE | 70.10% | Living Quarters, Average Plus, Average or Low. NULL when there's no finished basement. | [RES] |
| 53 | `fin_bsmt_area2` | Second finished basement area, in square feet. | INT64 | NULLABLE | 13.74% | | [RES] |
| 54 | `fin_bsmt_qual2` | Finish quality of the second area. | STRING | NULLABLE | 99.78% | Same values as `fin_bsmt_qual1`. | [RES] |

## Fixtures and rooms

| # | Column | Meaning | Ideal type | Nullable | Nulls | Notes | Source |
|---|---|---|---|---|---|---|---|
| 55 | `bathrooms` | Full bathrooms. A three-quarter bath counts as full. | INT64 | NULLABLE | 13.74% | 0 to 9. | [RES] |
| 56 | `toilet_rooms` | Half baths (a toilet and sink). | INT64 | NULLABLE | 13.74% | 0 to 6. | [RES] |
| 57 | `extra_fixtures` | Plumbing fixtures beyond the standard ones. | INT64 | NULLABLE | 13.74% | 0 to 20. | [RES] |
| 58 | `whirlpools` | Built-in whirlpool tubs. | INT64 | NULLABLE | 13.74% | 0 to 4. | [RES] |
| 59 | `hottubs` | Built-in hot tubs. | INT64 | NULLABLE | 13.74% | 0 to 2. | [RES] |
| 60 | `saunas` | Built-in saunas. | INT64 | NULLABLE | 13.74% | 0 or 1. | [RES] |
| 61 | `fireplaces` | Wood or gas fireplaces. Stoves and electric fireplaces aren't counted. | INT64 | NULLABLE | 13.74% | 0 to 6. | [RES] |
| 62 | `bedrooms` | Bedrooms above the basement, each at least 80 sq ft with a closet. | INT64 | NULLABLE | 15.27% | 0 to 17. | [RES] |
| 63 | `rooms` | Total number of rooms. The assessor records it but doesn't use it in valuation. | INT64 | NULLABLE | 15.40% | 0 to 27. | [RES] |

## Age and condition

| # | Column | Meaning | Ideal type | Nullable | Nulls | Notes | Source |
|---|---|---|---|---|---|---|---|
| 65 | `year_built` | Year the house was originally built. | INT64 | NULLABLE | 13.84% | 1800 to 2026. | [RES] |
| 66 | `year_remodel` | Year of a major remodel. | INT64 | NULLABLE | 94.11% | NULL when there hasn't been one; 3 rows use `0` instead, which should become NULL. | [RES] |
| 67 | `eff_year_built` | Effective year built: the house's age adjusted for updates, from the appraiser's calculator. | INT64 | NULLABLE | 93.51% | 3 rows use `0`, which should become NULL. | [RES] |
| 68 | `condition` | Physical condition. | STRING | NULLABLE | 13.80% | See [Condition](#condition). | [RES] |
| 69 | `grade` | Construction quality grade and its adjustment. | STRING | NULLABLE | 13.74% | `4-05` is grade 4 (Average) with a −05 adjustment. 7 rows have no sign: `3`, `4`, `5`, `0100`, `0125`. See [Grade](#grade). | [RES] |

## Condo

| # | Column | Meaning | Ideal type | Nullable | Nulls | Notes | Source |
|---|---|---|---|---|---|---|---|
| 73 | `condo_fin_liv_area` | Finished living area of the condo unit, in square feet. | INT64 | NULLABLE | 97.73% | Only filled for condominium units. 1 row uses `0`. | [CON] (label only) |
| 74 | `condo_year_built` | Year the condo unit was built. | INT64 | NULLABLE | 97.73% | Only filled for condominium units. 1 row uses `0`, which should become NULL. | [CON] (label only) |

## Code lists

### Sale condition codes

`quality1` and `quality2` hold the names below, not the numbers. If neither column has a condition and the sale isn't a contract, both the Iowa Department of Revenue and the assessor use it. Source: [RS].

| Code | Name in the CSV | Meaning |
|---|---|---|
| 0 | `Arms Length` (`quality1`), `No Code` (`quality2`) | No condition. |
| 1 | Quit Claim | The seller transfers whatever interest they have by quit claim deed. |
| 2 | Government or Exempt | Sale to or by a government or tax-exempt body. |
| 4 | Partial Interest | Only part of the ownership changed hands. Usable if the separate declarations for every interest are added up. |
| 5 | Life Estate | |
| 7 | Corporate Merger or Reorganization | |
| 8 | Timeshares or COOPs | |
| 9 | Adjoining or Non-Res Adjacent Land | Purchase of adjoining land. |
| 10 | Assemblage | Two or more parcels combined. |
| 12 | Foreclosure, Forfeiture, Sheriff/Tax Sale, Default | |
| 13 | Utility or Railroad | |
| 14 | Exchange, Trade, Gift, Estate Transfer | Includes 1031 exchanges. |
| 15 | Change in Classification | |
| 16 | Prior Improvement or Disimprovement | The property changed by more than 20% between January 1 and the sale date, e.g. a house built since the assessment. |
| 17 | Family | Sale between related parties. |
| 18 | Court Order | |
| 21 | Unplatted | Lot still assessed as unplatted land. |
| 22 | Prior Year Contract | Fulfils a contract from a prior year. |
| 23 | Contract Assumption | |
| 24 | Auction | Non-agricultural auction. |
| 25 | Partial Assessment | New construction that wasn't finished on January 1. |
| 26 | Split | Parcel split or division. |
| 27 | Two Assessors | Property spans two assessing jurisdictions. |
| 28 | Dual Classification | |
| 29 | Landlord to Tenant | Includes sale-leasebacks. |
| 30 | Conveyance | Corrects or modifies an earlier conveyance. |
| 32 | Cemetery | |
| 34 | Vacant Lot | |
| 35 | Vacant Building | Vacant at least a year. Doesn't apply to residential. |
| 36 | Prior Year | The instrument's year is already closed for data entry. |
| 37 | Easements | |
| 38 | No Consideration | |
| 40 | Land without Leased Building | |
| 41 | Leased Building without Land | |
| 42 | Secure Debt | |
| 44 | Mobile Home no Real Estate Assmt | |
| 45 | Relocation | Sale involving a relocation company. |
| 46 | Under 10000 | Price of $10,000 or less. |
| 47 | Section 42 | Section 42 affordable housing. |
| 48 | Minimum Assmt=Assmt | Property under a minimum assessment agreement. |
| 50 | Other | Abnormal sale with no fitting code. |

### Grade

`grade` combines a base grade and an adjustment, e.g. `4-05` or `0+20`. The grades scale the replacement costs in the Iowa Real Property Appraisal Manual. Source: [RES].

| Grade | Meaning |
|---|---|
| 0 | Executive |
| 1 | Superior |
| 2 | High |
| 3 | Good |
| 4 | Average |
| 5 | Below Average |
| 6 | Sub-standard |

**Adjustments:**
- `+00` means no adjustment.
- Any grade can take `+05`, `+10`, `-05` or `-10`.
- Grade 0 can also go from `+20` up to `+200`.
- Grade 6 can also take `-15` to `-30`.

The combined `4-05` format matches the parcel web card, but no source page spells it out.

### Condition

Source: [RES].

| Value | Meaning |
|---|---|
| Excellent | Fully revitalized. |
| Very Good | Well maintained, with many components overhauled. |
| Above Normal | No obvious maintenance needed. |
| Normal | Minor deferred maintenance. |
| Below Normal | Badly worn. |
| Poor | Worn out. |
| Very Poor | Uninhabitable. |

### Analysis quality

`Good`: used by the assessor for internal market analysis. `Bad`: not used. Source: [RS].

## Data-quality notes

From the 2026-10-22 profile of `sales_raw`:

- **Rows with no residence record.** 55,414 rows (13.7%) are NULL in every residence column, and a few hundred more are missing individual fields such as `occupancy` or `year_built`. `bldg_style` is also missing for about 42,700 rows that do have a residence. 35,296 of the 55,655 rows without an `occupancy` are coded `Vacant Lot`.
- **Same-day documents for one parcel.** 2,058 `(dp, sale_date)` pairs have 2 to 4 rows, 4,144 rows in total. Most are chains such as a developer selling a lot to a builder followed by the builder selling the house, or a relocation company buying and reselling. Each document has its own price. Use `(book, pg)` as the key.
- **Spaces to trim.** `pocket` (241,487 rows) and `seller` (58,660 rows) have extra spaces.
- **Blanks that should be NULL.** `address` (4,634 rows), `buyer` (49) and `detached_structs` (254,060, meaning no structures).
- **`0` meaning "none".** A handful of rows in `year_remodel`, `eff_year_built`, `condo_year_built` and `condo_fin_liv_area`.
- **Totals that don't add up.** `total_living_area` (403 rows) and `total_full` (249 rows) don't equal the sum of their parts.
- **Out-of-range values.** 13 non-Iowa `zip` values, 5 `percent_complete` values over 100, and 250 rows with `initial_entry_date` before `sale_date`.
- **Multi-parcel sales.** `dps`, `gps` and `legal_all_parcels` list every parcel in the sale; `dp` and `gp` hold just one of them.

[EXPORT]: https://www.assess.co.polk.ia.us/info/web/exports/res/sales/polk/
[CARD]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=card/card&dp=18101588000000
[RS]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=info/help/tables/table_all&table=rsale
[RES]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=info/help/tables/table_all&table=residence
[DIST]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=info/help/tables/table_all&table=districts
[PAR]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=info/help/tables/table_all&table=parcel
[NB]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=info/help/tables/table_all&table=nbhds
[XY]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=info/help/tables/table_all&table=xysall
[LND]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=info/help/tables/table_all&table=slandtotal
[PLT]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=info/help/tables/table_all&table=plats
[LEG]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=info/help/tables/table_all&table=legal
[CON]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=info/help/tables/table_all&table=condo_unit
[DET]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/infoqry.cgi?tt=info/help/tables/table_all&table=detached
[FORM]: https://www.assess.co.polk.ia.us/cgi-bin/web/tt/form.cgi?tt=rsaleform
