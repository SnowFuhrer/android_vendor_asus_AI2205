/*
  Copyright (c) 2022 Qualcomm Technologies, Inc.
  All Rights Reserved.
  Confidential and Proprietary - Qualcomm Technologies, Inc.
*/

CREATE TABLE IF NOT EXISTS qcril_properties_table (property TEXT PRIMARY KEY NOT NULL, def_val TEXT, value TEXT);
INSERT OR REPLACE INTO qcril_properties_table(property, def_val) VALUES('qcrildb_version',95.0);
UPDATE qcril_properties_table SET def_val="1" WHERE property="persist.vendor.radio.always_send_plmn";
UPDATE qcril_properties_table SET def_val="true" WHERE property="persist.vendor.radio.force_on_dc";
UPDATE qcril_properties_table SET def_val="1" WHERE property="persist.vendor.radio.add_power_save";
UPDATE qcril_properties_table SET def_val="" WHERE property="persist.vendor.radio.sglte.eons_domain";
UPDATE qcril_properties_table SET def_val="" WHERE property="persist.vendor.radio.sglte.eons_roam";
UPDATE qcril_properties_table SET def_val="1" WHERE property="persist.vendor.radio.data_ltd_sys_ind";
INSERT OR REPLACE INTO qcril_properties_table(property, def_val) VALUES("persist.vendor.radio.custom_nw_ecc", "1");
