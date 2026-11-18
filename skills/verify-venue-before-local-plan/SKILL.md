---
name: verify-venue-before-local-plan
description: >-
  Confirm the exact hotel, restaurant, or landmark before writing an itinerary, neighborhood walk, or must-eat list. Use when a local name can match a similarly named building, search hits a famous near-homophone, the user corrects the venue, or they add a constraint such as avoiding crowds. Do not use for price reconciliation, garbled CJK decoding, or a fetch that only returned site chrome.
metadata:
  cometline:
    origin: self-improvement
---

# Verify the venue before a local plan

A near-homophone plus the same neighborhood word is not the same place. District and street number are the identity. Planning four days from the wrong bank of a river wastes the whole answer.

## Confirm the anchor

1. Search the user's exact string in their language, then one English or romanized variant. Read the street and district in the snippets before opening pages.
2. Do not treat the first hotel-aggregator hit as the property. Aggregators glue "Bund", "treasure", and a famous old building onto a different door.
3. Fetch the official contact page and one booking page. Extract district, street, and street number from both. Nearby metro and landmarks on the booking page are useful only after the street number matches.
4. If the two pages disagree, or the hit is only a similar name, stop and ask which property. Do not write day plans from a guess.
5. Open the answer with the verified district, street, and street number so the user can catch a wrong building before reading the days.

## Rebuild after a correction

1. If the user corrects the name, discard the previous day plan. Distances, metro stops, and "walk from the hotel" notes from the old anchor are garbage.
2. Repeat the confirm steps for the new name. Cluster again: walkable first, short taxi second, a cross-town trip only when it is the point of that day.
3. State the new anchor in the first sentence again.

## Apply a later constraint

1. When the user adds a constraint such as no crowds, drop the famous checkpoints. Do not keep them as shorter stops.
2. Keep one iconic view only if it can be seen from the side or at an off-peak time, and say why it is still in the plan.
3. Prefer the neighborhood of the verified hotel over a first-visit checklist.

## Must-eat lists

1. Pick distinct dishes, not N copies of the same ranking listicle. Skip tourist-trap branches (temple-market restaurants, the queue at the scenic-area original) when a less crowded shop serves that dish.
2. For each shop, fetch a city tourism-bureau or official page and record street number and hours from that page. A listicle, encyclopedia, or guide page that 404s, 403s, or returns only navigation is not evidence the shop closed. Try the tourism page; if that also fails, omit the unverified detail.
3. A relocation headline is a warning that the old street is wrong. If the article body never loaded, say the shop moved and tell the user to recheck the map. Do not invent the new door number.
4. Hours on a tourism page can be stale. Cite them as what that page says, and tell the user to recheck before a timed stop (Monday closures, last entry).
5. Do not invent walking minutes. If map search only returned the map homepage, say taxi or "confirm on the map".

## Pitfalls

- Similar Chinese names in the same city (gem/treasure, Bund, old bank building) map to different districts. Street number beats brand words.
- Patching one corrected stop into an old itinerary leaves every other distance wrong. Rebuild.
- "Must-see" lists fight "I don't want crowds". Drop the checkpoints.
- Failed fetches are not closures. Empty guide pages and blocked encyclopedias only mean that source did not load.