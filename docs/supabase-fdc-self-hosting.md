# Moved: Self-hosting the Supabase food database

This document described the FDC-only Supabase schema (`fdc_food`, `fdc_nutrients`, `fdc_portions`) used up to OpenNutriTracker 1.x. Version 2.0 replaced it with a multi-source food backend (USDA FDC, BLS, and more) served through the `food_summary` materialized view.

- App-side documentation: [`docs/supabase-self-hosting.md`](supabase-self-hosting.md)
- Schema, import pipeline, and translation tooling: [OpenNutriTracker-Backend](https://github.com/simonoppowa/OpenNutriTracker-Backend)
