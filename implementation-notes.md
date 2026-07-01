# Implementation Notes: Langkawi Travel Planner & Accommodation Map

## Project Overview
This project delivers a comprehensive, interactive travel planner and accommodation map for a 4-day trip to Kuala Lumpur (1 night) and Langkawi (2 nights) from July 17 to July 20, 2026. It combines rich local recommendations for activities and dining with an interactive geographic map and a detailed day-by-day itinerary.

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

### 3. Trip Itinerary (July 17 - July 20, 2026 - KL & Langkawi)
- **Structure**: Day-based tab navigation with structured time-sequenced timeline cards.
- Includes estimated times, local dining recommendations, and travel advisories.

## Update Log & Changes
- **Mobile Responsive Enhancements**: Added comprehensive media queries for screen sizes <= 768px. Adjusted map height to 280px, scaled headers, removed internal scrollbars in panels (which caused nested scroll frustrations on mobile), and stacked checklist columns vertically.
- **Transportation Adjustment**: Replaced all mentions of rental cars with Grab (ride-sharing). Day 1 arrival, Day 4 departure, general tips, and pre-travel checklists were updated to align with the new transit strategy (e.g., advising pre-installation and credit card linking in the Grab app).
- **Section Repositioning**: Moved the 3박 4일 itinerary section immediately below the map/explorer section, shifting the recommended hotel cards grid further down. This allows the user to see their day-by-day itinerary directly after interacting with the map, improving the primary user flow.
- **Interactive Route Overlays**: Plotted sequential, dashed, color-coded polyline paths (Teal, Amber, Blue, Pink) on both the Leaflet Map and the SVG fallback map. Users can toggle specific days or view all days simultaneously. Switching days in the itinerary automatically triggers the matching route overlay on the map.
- **Lodging Recommendation Removal**: Removed all recommended accommodation cards, tabs, and quiz panels at the user's request. The map, lists, and SVG fallbacks now focus purely on active tourist attractions, activities, and dining places. Daily route overlays were updated to connect attractions directly (bypassing lodging coordinates) to maintain a clean travel layout until a hotel is decided.
- **Accommodation Integration (RIYAZ Lavanya)**: Set **The Riyaz Lavanya Langkawi** (`6.2861, 99.7282`) as the basecamp resort in Pantai Tengah. Re-routed all daily travel paths to start and end at the hotel (represented by a distinctive Teal pin on the map) and customized Day 1 check-in descriptions.
- **Directional Route Arrows**: Added custom, dynamically rotated arrow indicators (`➤`) along Leaflet map routes at segment midpoints, and implemented SVG marker definitions (`marker-mid` and `marker-end`) on the offline fallback map to clarify travel directions.
- **Geographic Route Optimization**: Swapped Day 2 and Day 3 itineraries to eliminate redundant cross-island travel. Day 2 (Saturday) now clusters all East/North-East activities (Kilim Mangrove, Tanjung Rhu, Kuah Town Eagle Square, Sunset Cruise, and Saturday Night Market) into one loop. Day 3 (Sunday) clusters all West/South-West activities (SkyCab, SkyBridge, Seven Wells, Telaga Harbour Marina, Pantai Tengah sunset, and Pantai Cenang seafood dinner), keeping all evening travel local.
- **Tanjung Rhu Beach Exclusion**: Completely removed Tanjung Rhu Beach and the Tanjung Rhu Seafood lunch (Scarborough Fish & Chips) from the Day 2 active travel routes and timeline. Replaced it with a route directly connecting Kilim Mangrove to Kuah Town, adding a local seafood lunch stop (Wonderland Food Store) and cafe break in Kuah Town. This saves the traveler from driving to the far north end of the island, further streamlining the schedule.
- **Tanjung Rhu Attraction List Removal**: Deleted Tanjung Rhu Beach from the `locations` array and `selectZone()` mapping. It no longer appears as a recommended attraction card in the sidebar or as a pin on the map.
- **Schedule Restructuring (KL 1박 + 랑카위 2박)**: Updated the plan to spend July 17 in Kuala Lumpur (arriving at 14:00 local time) and July 18-20 in Langkawi. Restructured the 4-day itinerary: Day 1 (KL arrival & city tour), Day 2 (domestic flight to Langkawi, West/South-West attractions), Day 3 (Langkawi East/South-East attractions & Sunset Cruise), Day 4 (Cenang shopping & departure). Adjusted Javascript coordinates and SVG fallback polyline coordinates accordingly.
- **Langkawi Departure Optimization (Day 4 / July 20th)**: Adjusted the final day's itinerary so the user remains in Langkawi until 16:00, enjoying beach cafes (e.g., Hidden Langkawi) rather than leaving early. After flying back to KL at 17:00, the user now heads to the downtown Petronas Twin Towers (Double Towers) area in KLCC to enjoy the stunning night towers view and a rooftop bar (e.g., WET Deck or Marini's on 57) for their final evening.

