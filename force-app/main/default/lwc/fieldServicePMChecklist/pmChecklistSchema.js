/**
 * PM Checklist Schema — Quarterly Preventative Maintenance Check List
 * For CIJ (Continuous Inkjet) printers only.
 *
 * Row types:
 *   number   – decimal number input
 *   integer  – whole number input (no decimal)
 *   picklist – dropdown / combobox
 *   text     – free text
 *   date     – date picker
 *   image    – camera / file upload
 *   manual   – free-form entry (no specific validation)
 *
 * remarkMode:
 *   'auto'     – auto-generated, non-editable (OK / Out of Range)
 *   'autoNRC'  – auto-generated for Nozzle Range Calibration (3-tier)
 *   'open'     – user can edit, optional
 *   'hidden'   – no remark
 */

// ──────────────────────────────────────────────────────
//  VMS MATRIX — Loaded from Custom Metadata (VMS_Matrix__mdt)
//  The matrix is passed from Apex as Map<inkType, JSON string>
//  Each JSON string maps temperature (string) → VMS value
// ──────────────────────────────────────────────────────

/**
 * Looks up VMS Now reading from the matrix loaded from Custom Metadata.
 * @param {Object} vmsMatrix – Map from Apex: { '630': '{"0":48,"1":47,...}', ... }
 * @param {string} inkType – e.g. '630', 'B600+', '2741'
 * @param {number|string} inkTemp – integer temperature in °C
 * @returns {number|null} VMS value, or null if inputs don't match
 */
export function vmsLookup(vmsMatrix, inkType, inkTemp) {
    if (!vmsMatrix || !inkType || inkTemp === '' || inkTemp == null) return null;

    const typeStr = String(inkType).trim();
    const jsonStr = vmsMatrix[typeStr];
    if (!jsonStr) return null;

    const temp = parseInt(inkTemp, 10);
    if (isNaN(temp)) return null;

    try {
        const tempMap = typeof jsonStr === 'string' ? JSON.parse(jsonStr) : jsonStr;
        // Direct lookup by temp key
        const val = tempMap[String(temp)];
        if (val != null) return Number(val);

        // If temp 41 is missing, fall back to 42
        if (temp === 41) {
            const fallback = tempMap['42'];
            if (fallback != null) return Number(fallback);
        }

        return null;
    } catch (e) {
        return null;
    }
}

// ──────────────────────────────────────────────────────
//  SECTION 1 — Input AC Voltage
// ──────────────────────────────────────────────────────

const SEC_ELECTRICAL = {
    sectionKey: 'electrical',
    label: 'a) Electrical',
    optional: false,
    rows: [
        {
            id: 'el_line_neutral',
            title: 'Line-Neutral',
            rowOrdinal: 'i)',
            type: 'number',
            unit: 'V AC',
            specifiedRange: '220–230',
            allowDecimal: true,
            required: true,
            remarkMode: 'auto',
            defaultRemark: '',
            autoRemarkLogic: 'rangeCheck',
            autoRemarkRange: [220, 230],
            hasLastPM: true,
            irFieldKey: 'el_line_neutral'
        },
        {
            id: 'el_neutral_earth',
            title: 'Neutral-Earth',
            rowOrdinal: 'ii)',
            type: 'number',
            unit: 'V AC',
            specifiedRange: '0–5',
            allowDecimal: true,
            required: true,
            remarkMode: 'auto',
            defaultRemark: '',
            autoRemarkLogic: 'rangeCheck',
            autoRemarkRange: [0, 5],
            autoRemarkSuffix: ' (Increasing trend suggest chemical earthing)',
            hasLastPM: true,
            irFieldKey: 'el_neutral_earth'
        },
        {
            id: 'el_line_earth',
            title: 'Line-Earth',
            rowOrdinal: 'iii)',
            type: 'number',
            unit: 'V AC',
            specifiedRange: '(i) − 2 to 3',
            allowDecimal: true,
            required: true,
            remarkMode: 'auto',
            defaultRemark: '',
            autoRemarkLogic: 'dynamicRange',
            dynamicRef: 'el_line_neutral',
            dynamicOffsetLow: -2,
            dynamicOffsetHigh: 3,
            autoRemarkSuffix: ' (Should not be same as Line to Neutral)',
            hasLastPM: true,
            irFieldKey: 'el_line_earth'
        },
        {
            id: 'el_battery_voltage',
            title: 'Battery voltage',
            rowOrdinal: 'iv)',
            type: 'number',
            unit: 'V. DC',
            specifiedRange: '3–3.3',
            allowDecimal: true,
            required: true,
            remarkMode: 'auto',
            defaultRemark: '',
            autoRemarkLogic: 'rangeCheck',
            autoRemarkRange: [2.7, 3.3],
            autoRemarkSuffix: ' (Replace if below 2.6 VDC)',
            hasLastPM: true,
            irFieldKey: null
        }
    ]
};

const SEC_ENVIRONMENT = {
    sectionKey: 'environment',
    label: 'b) Environment',
    optional: false,
    rows: [
        {
            id: 'env_ink_temp',
            title: 'Ink temp',
            rowOrdinal: 'i)',
            type: 'integer',
            unit: '°C',
            specifiedRange: 'Below 45',
            maxDigits: 2,
            required: false,
            remarkMode: 'open',
            defaultRemark: '',
            hasLastPM: true,
            irFieldKey: 'env_ink_temp'
        },
        {
            id: 'env_cabinet_temp',
            title: 'Cabinet Temp',
            rowOrdinal: 'ii)',
            type: 'integer',
            unit: '°C',
            specifiedRange: 'Below 47',
            maxDigits: 2,
            required: false,
            remarkMode: 'open',
            defaultRemark: '',
            hasLastPM: true,
            irFieldKey: 'env_cabinet_temp'
        },
        {
            id: 'env_head_temp',
            title: 'Head Temp',
            rowOrdinal: 'iii)',
            type: 'picklist',
            unit: '°C',
            specifiedRange: '35–45',
            required: false,
            remarkMode: 'open',
            defaultRemark: '',
            picklistOptions: Array.from({ length: 11 }, (_, i) => ({
                label: String(35 + i),
                value: String(35 + i)
            })),
            hasLastPM: true,
            irFieldKey: 'env_head_temp'
        }
    ],
    imageRows: [
        {
            id: 'env_dust',
            title: 'Dust',
            rowOrdinal: 'iv)',
            type: 'image',
            imageSlots: [
                { key: 'dust_before', label: 'Insert Pic Before cleaning', maxSizeKB: 300 },
                { key: 'dust_after', label: 'Insert Pic After cleaning', maxSizeKB: 300 }
            ]
        }
    ]
};

// ──────────────────────────────────────────────────────
//  SECTION 2 — Diagnostics
// ──────────────────────────────────────────────────────

const DEBUG_VALVE_OPTIONS = [
    { label: 'ok', value: 'ok' },
    { label: 'not ok', value: 'not ok' },
    { label: 'clean ok*', value: 'clean ok*' }
];

const DEBUG_ITEMS = [
    'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8', 'V9', 'V11', 'V12', 'PUMP 1', 'PUMP 3'
];

const SEC_DEBUG = {
    sectionKey: 'debug',
    label: 'a) Debug',
    optional: false,
    hideRemarks: true,
    rows: DEBUG_ITEMS.map((name) => {
        const key = 'dbg_' + name.toLowerCase().replace(/\s+/g, '_');
        return {
            id: key,
            title: name,
            rowOrdinal: '',
            type: 'picklist',
            specifiedRange: 'OK',
            required: true,
            remarkMode: 'hidden',
            defaultRemark: '',
            picklistOptions: DEBUG_VALVE_OPTIONS,
            hasLastPM: true,
            irFieldKey: null
        };
    })
};

const SEC_FILTER_LIFE = {
    sectionKey: 'filter_life_test',
    label: 'b) Filter life test',
    optional: false,
    rows: [
        {
            id: 'flt_reach_500',
            title: 'Time to reach 500 Psi',
            rowOrdinal: '',
            type: 'integer',
            unit: 'Seconds',
            specifiedRange: '5',
            filterLifeSpec: 5,
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            remarkRequiredOnDeviation: true,
            deviationPercent: 5,
            hasLastPM: true
        },
        {
            id: 'flt_500_to_450',
            title: 'Time from 500 to 450 Psi',
            rowOrdinal: '',
            type: 'integer',
            unit: 'Seconds',
            specifiedRange: '30',
            filterLifeSpec: 30,
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            remarkRequiredOnDeviation: true,
            deviationPercent: 5,
            hasLastPM: true
        },
        {
            id: 'flt_reach_330',
            title: 'Time to reach 330 Psi',
            rowOrdinal: '',
            type: 'integer',
            unit: 'Seconds',
            specifiedRange: '3',
            filterLifeSpec: 3,
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            remarkRequiredOnDeviation: true,
            deviationPercent: 5,
            hasLastPM: true
        },
        {
            id: 'flt_settle_330',
            title: 'Time to settle to 330 Psi',
            rowOrdinal: '',
            type: 'integer',
            unit: 'Seconds',
            specifiedRange: '20',
            filterLifeSpec: 20,
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            remarkRequiredOnDeviation: true,
            deviationPercent: 5,
            hasLastPM: true
        }
    ]
};

const SEC_NOZZLE_RANGE = {
    sectionKey: 'nozzle_range_calibration',
    label: 'c) Nozzle Range Calibration',
    optional: false,
    rows: [
        {
            id: 'nrc_phase_profile',
            title: 'Phase profile 8 value',
            rowOrdinal: 'i)',
            type: 'integer',
            specifiedRange: '5–15',
            maxValue: 99,
            required: true,
            remarkMode: 'autoNRC',
            defaultRemark: '',
            nrcLogic: {
                okRange: [5, 15],
                limitsRanges: [[3, 4], [16, 25]]
            },
            hasLastPM: true
        },
        {
            id: 'nrc_first_drop',
            title: 'First drop Value',
            rowOrdinal: 'ii)',
            type: 'integer',
            specifiedRange: '(i) + 5',
            maxValue: 99,
            required: true,
            remarkMode: 'autoNRC',
            defaultRemark: '',
            nrcLogic: {
                refField: 'nrc_phase_profile',
                okOffset: [5, 5],
                limitsOffset: [6, 10]
            },
            hasLastPM: true
        },
        {
            id: 'nrc_satellites_first',
            title: 'Satellites at first drop',
            rowOrdinal: 'iii)',
            type: 'integer',
            specifiedRange: '2 or 3',
            maxValue: 99,
            required: true,
            remarkMode: 'autoNRC',
            defaultRemark: '',
            nrcLogic: {
                okValues: [2, 3],
                limitsValues: [1, 4, 5]
            },
            hasLastPM: true
        },
        {
            id: 'nrc_satellites_end',
            title: 'Satellites end Point',
            rowOrdinal: 'iv)',
            type: 'integer',
            specifiedRange: '(ii) + 15',
            maxValue: 99,
            required: true,
            remarkMode: 'autoNRC',
            defaultRemark: '',
            nrcLogic: {
                refField: 'nrc_first_drop',
                okOffset: [15, 17],
                limitsOffsetRanges: [[12, 14], [18, 22]]
            },
            hasLastPM: true
        },
        {
            id: 'nrc_physical_reverse',
            title: 'Physical Reverse point',
            rowOrdinal: 'v)',
            type: 'integer',
            specifiedRange: '(iv) + 15',
            maxValue: 99,
            required: true,
            remarkMode: 'autoNRC',
            defaultRemark: '',
            nrcLogic: {
                refField: 'nrc_satellites_end',
                okOffset: [15, 17],
                limitsOffsetRanges: [[10, 14], [18, 22]]
            },
            hasLastPM: true
        },
        {
            id: 'nrc_digital_reverse',
            title: 'Digital reverse Point',
            rowOrdinal: 'vi)',
            type: 'integer',
            specifiedRange: '(v) + 5',
            maxValue: 99,
            required: true,
            remarkMode: 'autoNRC',
            defaultRemark: '',
            nrcLogic: {
                refField: 'nrc_physical_reverse',
                okOffset: [5, 10],
                limitsValues: [3, 4, 11, 12],
                limitsUseRefOffset: true
            },
            hasLastPM: true
        }
    ]
};

const SEC_EHT = {
    sectionKey: 'eht_calibration',
    label: 'd) EHT Calibration',
    optional: false,
    hideRemarks: true,
    rows: [
        {
            id: 'eht_resistor',
            title: 'EHT Resistor value',
            rowOrdinal: 'i)',
            type: 'number',
            unit: 'M Ohm',
            specifiedRange: '22',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            validRange: [0, 30],
            blockSaveAbove: 30,
            blockSaveMessage: 'EHT Resistor value must not exceed 30 M Ohm.',
            hasLastPM: true
        },
        {
            id: 'eht_ground_charge',
            title: 'Ground & Charge Electrode',
            rowOrdinal: 'ii)',
            type: 'number',
            unit: 'mVDC',
            specifiedRange: '320–350',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            validRange: [100, 500],
            blockSaveAbove: 500,
            blockSaveMessage: 'Ground & Charge Electrode must not exceed 500 mVDC.',
            hasLastPM: true
        },
        {
            id: 'eht_gnd',
            title: 'EHT & GND',
            rowOrdinal: 'iii)',
            type: 'number',
            unit: 'M Ohm',
            specifiedRange: '150–160',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            validRange: [120, 230],
            blockSaveAbove: 230,
            blockSaveMessage: 'EHT & GND must not exceed 230 M Ohm.',
            hasLastPM: true
        },
        {
            id: 'eht_module_backplate',
            title: 'EHT Module back plate',
            rowOrdinal: 'iv)',
            type: 'picklist',
            specifiedRange: 'No black spots',
            required: true,
            remarkMode: 'hidden',
            defaultRemark: '',
            picklistOptions: [
                { label: 'Yes – No black spots or marks', value: 'Yes' },
                { label: 'No – Black spots or marks present', value: 'No' }
            ],
            hasLastPM: true
        }
    ]
};

const SEC_JET_ALIGNMENT = {
    sectionKey: 'jet_alignment',
    label: 'e) Jet alignment position',
    optional: false,
    hideRemarks: true,
    rows: [],
    imageRows: [
        {
            id: 'jet_alignment',
            title: 'Jet alignment position',
            rowOrdinal: '',
            type: 'image',
            imageSlots: [
                { key: 'jet_8020', label: '80:20 Pics', maxSizeKB: 300 },
                { key: 'jet_5050', label: '50:50 Pics', maxSizeKB: 300 }
            ]
        }
    ]
};

const SEC_FLUID_ADDITION = {
    sectionKey: 'fluid_addition',
    label: 'f) Fluid addition system',
    optional: false,
    rows: [
        {
            id: 'fa_makeup_cup',
            title: 'Time to fill make up cup',
            rowOrdinal: 'i)',
            type: 'number',
            unit: 'Sec',
            specifiedRange: '7',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            validRange: [5, 15],
            hasLastPM: true
        },
        {
            id: 'fa_ink_cup',
            title: 'Time to fill Ink cup',
            rowOrdinal: 'ii)',
            type: 'number',
            unit: 'Sec',
            specifiedRange: '18–20',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            validRange: [10, 30],
            hasLastPM: true
        },
        {
            id: 'fa_vms_fill',
            title: 'VMS fill time',
            rowOrdinal: 'iii)',
            type: 'number',
            unit: '',
            specifiedRange: '',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            validRange: [10, 30],
            hasLastPM: true
        },
        {
            id: 'fa_vms_empty',
            title: 'VMS empty time',
            rowOrdinal: 'iv)',
            type: 'number',
            unit: '',
            specifiedRange: '',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            validRange: [15, 45],
            hasLastPM: true
        },
        {
            id: 'fa_vms_now',
            title: 'VMS Now reading',
            rowOrdinal: 'v)',
            type: 'integer',
            unit: '',
            specifiedRange: '(from matrix)',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            hasLastPM: true,
            vmsSpecLookup: true
        },
        {
            id: 'fa_v1_leak',
            title: 'V1 leak test',
            rowOrdinal: 'vi)',
            type: 'picklist',
            specifiedRange: '',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            picklistOptions: [
                { label: 'leak', value: 'leak' },
                { label: 'not leak', value: 'not leak' }
            ],
            hasLastPM: true
        },
        {
            id: 'fa_v2_leak',
            title: 'V2 leak test',
            rowOrdinal: 'vii)',
            type: 'picklist',
            specifiedRange: '',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            picklistOptions: [
                { label: 'leak', value: 'leak' },
                { label: 'not leak', value: 'not leak' }
            ],
            hasLastPM: true
        },
        {
            id: 'fa_ink_buffer',
            title: 'Ink in buffer tank test',
            rowOrdinal: 'viii)',
            type: 'picklist',
            specifiedRange: '',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            picklistOptions: [
                { label: 'ink present', value: 'ink present' },
                { label: 'ink not present', value: 'ink not present' }
            ],
            hasLastPM: true
        }
    ]
};

const UMBILICAL_VIDEO_LINK = 'https://drive.google.com/drive/folders/1z81XgpNt1TEpbVzBzbW-p45N-Gb5UQ9d';

const SEC_UMBILICAL = {
    sectionKey: 'umbilical_fitness',
    label: 'g) Umbilical fitness test',
    optional: false,
    hideLastPM: true,
    referenceLink: UMBILICAL_VIDEO_LINK,
    referenceLinkLabel: 'Open reference video',
    rows: [
        {
            id: 'uf_video1',
            title: 'Video test 1',
            rowOrdinal: '',
            type: 'picklist',
            specifiedRange: 'pass',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            picklistOptions: [
                { label: 'pass', value: 'pass' },
                { label: 'failed', value: 'failed' }
            ],
            hasLastPM: false
        },
        {
            id: 'uf_video2',
            title: 'Video test 2',
            rowOrdinal: '',
            type: 'picklist',
            specifiedRange: 'pass',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            picklistOptions: [
                { label: 'pass', value: 'pass' },
                { label: 'failed', value: 'failed' }
            ],
            hasLastPM: false
        },
        {
            id: 'uf_video3',
            title: 'Video test 3',
            rowOrdinal: '',
            type: 'picklist',
            specifiedRange: 'pass',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            picklistOptions: [
                { label: 'pass', value: 'pass' },
                { label: 'failed', value: 'failed' }
            ],
            hasLastPM: false
        },
        {
            id: 'uf_video4',
            title: 'Video test 4',
            rowOrdinal: '',
            type: 'picklist',
            specifiedRange: 'pass',
            required: true,
            remarkMode: 'open',
            defaultRemark: '',
            picklistOptions: [
                { label: 'pass', value: 'pass' },
                { label: 'failed', value: 'failed' }
            ],
            hasLastPM: false
        }
    ]
};

// ──────────────────────────────────────────────────────
//  SECTION 3 — Physical Attributes
// ──────────────────────────────────────────────────────

const PHYSICAL_ITEMS = [
    { id: 'pa_cover_magnet', title: 'Cover magnet switch check', ordinal: 'i)' },
    { id: 'pa_sensor_connector', title: 'Sensor connector check', ordinal: 'ii)' },
    { id: 'pa_smps_pcb', title: 'SMPS & Main PCB condition', ordinal: 'iii)' },
    { id: 'pa_umbilical', title: 'Umbilical condition', ordinal: 'iv)' },
    { id: 'pa_ink_leakage', title: 'Ink leakages from core manifold', ordinal: 'v)' }
];

const SEC_PHYSICAL = {
    sectionKey: 'physical_attributes',
    label: 'Physical Attributes',
    optional: false,
    hideLastPM: true,
    rows: PHYSICAL_ITEMS.map((item) => ({
        id: item.id,
        title: item.title,
        rowOrdinal: item.ordinal,
        type: 'picklist',
        specifiedRange: 'Ok',
        required: true,
        remarkMode: 'open',
        defaultRemark: '',
        picklistOptions: [
            { label: 'okay', value: 'okay' },
            { label: 'not okay', value: 'not okay' }
        ],
        hasLastPM: false
    }))
};

// ──────────────────────────────────────────────────────
//  SECTION 4 — Ink Storage & Stock
// ──────────────────────────────────────────────────────

const SEC_INK_STORAGE = {
    sectionKey: 'ink_storage',
    label: 'Ink Storage & Stock',
    optional: false,
    rows: [
        {
            id: 'is_sunlight',
            title: 'Is ink storage in direct sunlight area?',
            rowOrdinal: 'i)',
            type: 'picklist',
            specifiedRange: 'No',
            required: true,
            remarkMode: 'autoSunlight',
            autoSunlightRemark: 'Ink end user properties and printer Stability is compromised, Recommend to change storage location',
            defaultRemark: '',
            picklistOptions: [
                { label: 'Yes', value: 'Yes' },
                { label: 'No', value: 'No' }
            ],
            hasLastPM: false
        }
    ],
    batchRows: [
        {
            id: 'is_ink_stock',
            title: 'Ink stock qty',
            rowOrdinal: 'ii)',
            batchFieldId: 'is_ink_stock_batch',
            expiryFieldId: 'is_ink_stock_expiry',
            required: false,
            remarkMode: 'open',
            hasLastPM: false
        },
        {
            id: 'is_makeup_stock',
            title: 'Make up stock qty',
            rowOrdinal: 'iii)',
            batchFieldId: 'is_makeup_stock_batch',
            expiryFieldId: 'is_makeup_stock_expiry',
            required: false,
            remarkMode: 'open',
            hasLastPM: false
        },
        {
            id: 'is_wash_stock',
            title: 'Wash stock qty',
            rowOrdinal: 'iv)',
            batchFieldId: 'is_wash_stock_batch',
            expiryFieldId: 'is_wash_stock_expiry',
            required: false,
            remarkMode: 'open',
            hasLastPM: false
        }
    ]
};

// ──────────────────────────────────────────────────────
//  Exported structure
// ──────────────────────────────────────────────────────

export const PM_CHECKLIST_STRUCTURE = [
    {
        groupKey: 'input_ac_voltage',
        groupLabel: '1. Input AC Voltage',
        sections: [SEC_ELECTRICAL, SEC_ENVIRONMENT]
    },
    {
        groupKey: 'diagnostics',
        groupLabel: '2. Diagnostics',
        sections: [
            SEC_DEBUG,
            SEC_FILTER_LIFE,
            SEC_NOZZLE_RANGE,
            SEC_EHT,
            SEC_JET_ALIGNMENT,
            SEC_FLUID_ADDITION,
            SEC_UMBILICAL
        ]
    },
    {
        groupKey: 'physical_attributes',
        groupLabel: '3. Physical Attributes',
        sections: [SEC_PHYSICAL]
    },
    {
        groupKey: 'ink_storage',
        groupLabel: '4. Ink Storage & Stock',
        sections: [SEC_INK_STORAGE]
    }
];


/**
 * Builds a flattened and keyed model from the PM_CHECKLIST_STRUCTURE.
 */
export function buildPmChecklistModel(structure) {
    const groups = [];
    const flatSections = [];
    const allRows = [];
    const rowMap = {};

    structure.forEach((grp, gi) => {
        const gKey = `pm-group-${gi}`;
        const secs = [];

        grp.sections.forEach((sec, si) => {
            const secId = `${gKey}-sec-${si}`;
            const combinedRows = [...(sec.rows || [])];
            combinedRows.forEach((r) => {
                allRows.push(r);
                rowMap[r.id] = r;
            });

            secs.push({
                sectionId: secId,
                sectionKey: sec.sectionKey,
                sectionAccordionLabel: sec.label,
                optional: !!sec.optional,
                hideRemarks: !!sec.hideRemarks,
                hideLastPM: !!sec.hideLastPM,
                rows: combinedRows,
                imageRows: sec.imageRows || [],
                batchRows: sec.batchRows || [],
                referenceLink: sec.referenceLink || null,
                referenceLinkLabel: sec.referenceLinkLabel || null
            });
            flatSections.push(secs[secs.length - 1]);
        });

        groups.push({
            key: gKey,
            groupKey: grp.groupKey,
            groupAccordionLabel: grp.groupLabel,
            sections: secs
        });
    });

    return { groups, flatSections, allRows, rowMap };
}


/**
 * Generates an auto-remark for Nozzle Range Calibration rows.
 * Returns one of: 'OK Within Range (...)', 'OK Within Limits (...)', 'Not ok - Out of bound'.
 */
export function generateNRCRemark(row, actualValue, allValues) {
    if (actualValue === '' || actualValue == null) return '';

    const val = parseInt(actualValue, 10);
    if (isNaN(val)) return '';

    const logic = row.nrcLogic;
    if (!logic) return '';

    // Static OK range (e.g., Phase profile: 5–15)
    if (logic.okRange) {
        const [lo, hi] = logic.okRange;
        if (val >= lo && val <= hi) {
            return `OK Within Range (${lo}–${hi})`;
        }
        // Check limits
        if (logic.limitsRanges) {
            for (const [lLo, lHi] of logic.limitsRanges) {
                if (val >= lLo && val <= lHi) {
                    return `OK Within Limits (${lLo} to ${lHi})`;
                }
            }
        }
        return 'Not ok - Out of bound';
    }

    // Static OK values (e.g., Satellites: 2 or 3)
    if (logic.okValues) {
        if (logic.okValues.includes(val)) {
            return `OK Within Range (${logic.okValues.join(' or ')})`;
        }
        if (logic.limitsValues && logic.limitsValues.includes(val)) {
            return `OK Within Limits (${logic.limitsValues.join(', ')})`;
        }
        return 'Not ok - Out of bound';
    }

    // Reference-based (e.g., First drop = Phase + 5)
    if (logic.refField) {
        const refCell = allValues[logic.refField];
        const refVal = refCell ? parseInt(refCell.actualReading, 10) : NaN;
        if (isNaN(refVal)) return 'Ref value missing';

        // OK offset: [minOff, maxOff] relative to ref
        if (logic.okOffset) {
            const okLo = refVal + logic.okOffset[0];
            const okHi = refVal + logic.okOffset[1];
            if (val >= okLo && val <= okHi) {
                return `OK Within Range (${okLo}–${okHi})`;
            }

            // Limits: either offset ranges or absolute offsets from ref
            if (logic.limitsOffsetRanges) {
                for (const [lLo, lHi] of logic.limitsOffsetRanges) {
                    const limLo = refVal + lLo;
                    const limHi = refVal + lHi;
                    if (val >= limLo && val <= limHi) {
                        return `OK Within Limits (${limLo} to ${limHi})`;
                    }
                }
            }
            if (logic.limitsOffset) {
                const limLo = refVal + logic.limitsOffset[0];
                const limHi = refVal + logic.limitsOffset[1];
                if (val >= limLo && val <= limHi) {
                    return `OK Within Limits (${limLo}–${limHi})`;
                }
            }
            if (logic.limitsValues && logic.limitsUseRefOffset) {
                for (const off of logic.limitsValues) {
                    if (val === refVal + off) {
                        return `OK Within Limits (${refVal + off})`;
                    }
                }
            }
            return 'Not ok - Out of bound';
        }
    }

    return '';
}


/**
 * Generates auto-remark for Electrical rows with fixed or dynamic ranges.
 */
export function generateElectricalRemark(row, actualValue, allValues) {
    if (actualValue === '' || actualValue == null) return '';

    const val = parseFloat(actualValue);
    if (isNaN(val)) return '';

    const suffix = row.autoRemarkSuffix || '';

    if (row.autoRemarkLogic === 'rangeCheck' && row.autoRemarkRange) {
        const [lo, hi] = row.autoRemarkRange;
        const status = (val >= lo && val <= hi) ? 'OK' : 'Out of Range';
        return status + suffix;
    }

    if (row.autoRemarkLogic === 'dynamicRange' && row.dynamicRef) {
        const refCell = allValues[row.dynamicRef];
        const refVal = refCell ? parseFloat(refCell.actualReading) : NaN;
        if (isNaN(refVal)) return 'Ref value missing';

        const lo = refVal + row.dynamicOffsetLow;
        const hi = refVal + row.dynamicOffsetHigh;
        const status = (val >= lo && val <= hi) ? 'OK' : 'Out of Range';
        return status + suffix;
    }

    return '';
}