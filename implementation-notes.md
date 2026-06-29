# Implementation Notes: Langkawi Travel Planner & Accommodation Map

## Project Overview
This project delivers a comprehensive, interactive travel planner and accommodation map for a 4-day trip to Langkawi, Malaysia (July 17 - July 20, 2026). It combines rich local recommendations for accommodations and activities with an interactive geographic map and a detailed day-by-day itinerary.

## Technical Requirements & Constraints
- **Format**: Single self-contained HTML file (`index.html`) containing all structure (HTML), styling (CSS), and logic (JS).
- **Styling**: Vanilla CSS, adhering to rich, premium aesthetics (curated colors, smooth transitions, dark/light theme, modern typography).
- **Accessibility & SEO**: Semantic HTML5 elements, correct title/meta tags, single `<h1>` heading, and responsive layouts.
- **Line Length Safety**: All written code lines must remain under 150 characters (excluding natural text wrapping in markdown files).

## Architecture & Design Decisions
### 1. Interactive Geographic Map
- **Engine**: Leaflet.js (loaded via CDN) to render an interactive map with customized Map markers.
- **Fallback**: Robust fallback to a responsive, styled SVG map representing Langkawi's key zones if Leaflet fails to load (e.g., due to network issues).
- **Categories**: Pins are categorized into "Accommodations" (lodging icon) and "Activities" (camera/star icon) with reactive filtering.

### 2. Premium Design Tokens
- **Font**: Google Fonts - 'Outfit' (for headers, Latin text) and 'Noto Sans KR' (for general Korean typography).
- **Color Palette**:
  - Light Theme: Emerald Teal primary (`#0d9488`), Golden Sunset secondary (`#f59e0b`), warm sand background (`#fafaf5`).
  - Dark Theme: Deep marine midnight background (`#0a0f1d`), Slate-gray borders (`#1e293b`), vibrant cyan/yellow accents.
- **Micro-interactions**: Scale-ups on hover, smooth scroll, tab transitions, day timeline expanders, and instant theme toggling.

### 3. Trip Itinerary (July 17 - July 20, 2026)
- **Structure**: Day-based tab navigation with structured time-sequenced timeline cards.
- Includes estimated times, local dining recommendations, and travel advisories.

## Update Log & Changes
- **Mobile Responsive Enhancements**: Added comprehensive media queries for screen sizes <= 768px. Adjusted map height to 280px, scaled headers, removed internal scrollbars in panels (which caused nested scroll frustrations on mobile), and stacked checklist columns vertically.
- **Transportation Adjustment**: Replaced all mentions of rental cars with Grab (ride-sharing). Day 1 arrival, Day 4 departure, general tips, and pre-travel checklists were updated to align with the new transit strategy (e.g., advising pre-installation and credit card linking in the Grab app).
- **Section Repositioning**: Moved the 3박 4일 itinerary section immediately below the map/explorer section, shifting the recommended hotel cards grid further down. This allows the user to see their day-by-day itinerary directly after interacting with the map, improving the primary user flow.
