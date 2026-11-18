---
name: conflicting-pricing-pages
description: Reconcile conflicting SaaS or AI subscription prices when the marketing page, help docs, and third-party roundups disagree. Use when the user asks current plans, a refund, or a switch between products that may have merged, and official pages list different tiers or names.
metadata:
  cometline:
    origin: self-improvement
---

# Conflicting pricing pages

Treat a price as current only after the page that owns billing agrees with the page that owns the product. Marketing fetches, help docs, and blogs often describe different generations of the same brand at the same time.

## 1. Fetch the claimed official URLs first

1. `web_search` the product plus `pricing` and `refund`, then `web_fetch` the vendor domains that appear, not the aggregator that ranked first.
2. Fetch both the marketing pricing URL and the docs/help pricing URL. A 403 on one host is not proof the page is gone; try the docs host and a sibling product host.
3. Read the page identity, not only the numbers: copyright, company name, plan names, and whether Cursor/Grok/X-style products share one pool.
4. If those two official surfaces disagree, do not average them and do not pick the roundup that matches your memory.

## 2. Find the page that explains the disagreement

1. `web_search` `site:` the docs host for the new plan name plus `refund`, `switch`, `unify`, or `existing plans`.
2. Open the billing doc that says what happens to the old subscription. That page is the tie-break, not a blog dated the same month.
3. Keep both ladders when the vendor says existing plans continue and switching is optional. Report:
   - new self-serve ladder (price, usage multiple, what the pool covers)
   - old ladder that still bills (plan name the user already pays for)
   - which surface is marketing vs help, and the docs "last updated" line
4. Say third-party tables are stale when they still list the pre-merge names after the official switch doc exists.

## 3. Separate cancel, refund, and switch

1. Identify the merchant from the charge descriptor before naming a form: direct web, Apple, Google Play, or a bundled social plan.
2. Cancel stops renewal. It does not by itself reverse the current period.
3. A switch/unify flow can cancel eligible direct-billed plans and prorate unused time back to the original payment method. Read the switch doc for exceptions: App Store charges the vendor cannot cancel, Google Play subscriptions that may keep renewing, and accounts not included in the switch.
4. A discretionary refund form is a review, not a promise. Quote the official window only for approved refunds, and name who decides (vendor vs Apple vs the bundled product).

## Pitfalls

- A live marketing fetch can be a merged bundle while help docs still list the pre-merge SKUs. Quoting either page alone misstates what the user can buy today and what they already pay.
- Aggregators copy each other and invent price hikes. Prefer the vendor page that states list prices and the vendor page that states refund mechanics.
- "Highest tier" is not stable across a rebrand. Map the user's old plan name before comparing it to the new top tier.
- Prorated credit on an in-product upgrade is not the same rule as a prorated cash refund on a cross-product switch. Read the sentence that names the action.