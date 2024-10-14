// SPDX-License-Identifier: GPL-3.0-only

use serde::Deserialize;

pub mod app;
pub mod core;

#[derive(Debug, Deserialize)]
struct Location {
    city: String,
    region: String,
    country: String,
    loc: String, // Format: "latitude,longitude"
    timezone: String,
}

#[derive(Debug, Deserialize)]
struct Data {
    timings: PrayerTimes,
}

#[derive(Debug, Deserialize)]
struct ApiResponse {
    code: u16,
    status: String,
    data: Data,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "PascalCase")]
pub struct PrayerTimes {
    fajr: String,
    sunrise: String,
    dhuhr: String,
    asr: String,
    maghrib: String,
    isha: String,
}

impl PrayerTimes {
    fn new() -> Result<Self, ureq::Error> {
        let response: Location = ureq::get("https://ipinfo.io/json").call()?.into_json()?;
        let time = chrono::Local::now();
        let date = time.format("DD-MM-YYYY");
        let (lat, long) = response.loc.split_once(",").unwrap();
        let response: ApiResponse = ureq::get(&format!(
            "http://api.aladhan.com/v1/timings/{date}?latitude={lat}&longitude={long}",
        ))
        .call()?
        .into_json()?;
        Ok(response.data.timings)
    }
}
